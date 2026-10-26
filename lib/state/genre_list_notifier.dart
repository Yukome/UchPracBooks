import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/foundation.dart';
import '../core/api_exceptions.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import '../repositories/genre_repository.dart';

enum GenreLoadStatus { idle, loading, success, error }

class GenreListNotifier extends ChangeNotifier {
  final GenreRepository _repository;
  GenreListNotifier(this._repository);

  GenreQuery _query = const GenreQuery();
  PageResult<Genre> _result = PageResult.empty();
  GenreLoadStatus _status = GenreLoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  bool _disposed = false;
  CancelToken? _cancelToken;

  GenreQuery get query => _query;
  PageResult<Genre> get result => _result;
  GenreLoadStatus get status => _status;
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

    _status = GenreLoadStatus.loading;
    _error = null;
    _safeNotify();

    try {
      final result = await _repository.find(_query, cancelToken: token);
      if (token.isCancelled) return;
      _result = result;
      _status = GenreLoadStatus.success;
    } on CancelledException {
      return;
    } catch (e) {
      if (token.isCancelled) return;
      _error = e.toString();
      _status = GenreLoadStatus.error;
    }
    _safeNotify();
  }

  Future<void> applyQuery(GenreQuery next) async {
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