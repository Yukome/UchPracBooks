import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/foundation.dart';
import '../core/api_exceptions.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../models/page_result.dart';
import '../repositories/publisher_repository.dart';

enum PublisherLoadStatus { idle, loading, success, error }

class PublisherListNotifier extends ChangeNotifier {
  final PublisherRepository _repository;
  PublisherListNotifier(this._repository);

  PublisherQuery _query = const PublisherQuery();
  PageResult<Publisher> _result = PageResult.empty();
  PublisherLoadStatus _status = PublisherLoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  bool _disposed = false;
  CancelToken? _cancelToken;

  PublisherQuery get query => _query;
  PageResult<Publisher> get result => _result;
  PublisherLoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  @override
  void dispose() {
    _disposed = true;
    _cancelToken?.cancel('dispose');
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    _cancelToken?.cancel('superseded');
    final token = _cancelToken = CancelToken();

    _status = PublisherLoadStatus.loading;
    _error = null;
    _safeNotify();

    try {
      final result = await _repository.find(_query, cancelToken: token);
      if (token.isCancelled) return;
      _result = result;
      _status = PublisherLoadStatus.success;
    } on CancelledException {
      return;
    } catch (e) {
      if (token.isCancelled) return;
      _error = e.toString();
      _status = PublisherLoadStatus.error;
    }
    _safeNotify();
  }

  Future<void> applyQuery(PublisherQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    _safeNotify();
  }

  void clearSelection() {
    _selected.clear();
    _safeNotify();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> deleteOne(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDeleteOne(int id) async {
    await _repository.hardDelete(id);
    await load();
  }

  Future<void> restoreOne(int id) async {
    await _repository.restore(id);
    await load();
  }
}