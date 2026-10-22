import 'package:flutter/foundation.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../models/page_result.dart';
import '../repositories/reader_repository.dart';

enum ReaderLoadStatus { idle, loading, success, error }

class ReaderListNotifier extends ChangeNotifier {
  final ReaderRepository _repository;
  ReaderListNotifier(this._repository);

  ReaderQuery _query = const ReaderQuery();
  PageResult<Reader> _result = PageResult.empty();
  ReaderLoadStatus _status = ReaderLoadStatus.idle;
  final Set<int> _selected = {};

  ReaderQuery get query => _query;
  PageResult<Reader> get result => _result;
  ReaderLoadStatus get status => _status;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = ReaderLoadStatus.loading;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = ReaderLoadStatus.success;
    } catch (e) {
      _status = ReaderLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(ReaderQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
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