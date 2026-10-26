import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/foundation.dart';
import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import '../repositories/book_repository.dart';

enum LoadStatus { idle, loading, success, error }

class BookListNotifier extends ChangeNotifier {
  final BookRepository _repository;
  BookListNotifier(this._repository);

  BookQuery _query = const BookQuery();
  PageResult<Book> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  bool _disposed = false;
  CancelToken? _cancelToken;

  BookQuery get query => _query;
  PageResult<Book> get result => _result;
  LoadStatus get status => _status;
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

    _status = LoadStatus.loading;
    _error = null;
    _safeNotify();

    try {
      final result = await _repository.find(_query, cancelToken: token);
      if (token.isCancelled) return;
      _result = result;
      _status = LoadStatus.success;
    } on CancelledException {
      return;
    } catch (e) {
      if (token.isCancelled) return;
      _error = e.toString();
      _status = LoadStatus.error;
    }
    _safeNotify();
  }

  Future<void> applyQuery(BookQuery next) async {
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