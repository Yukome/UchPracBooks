import 'package:flutter/foundation.dart';
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
  final Set<int> _selected = {};

  GenreQuery get query => _query;
  PageResult<Genre> get result => _result;
  GenreLoadStatus get status => _status;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = GenreLoadStatus.loading;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = GenreLoadStatus.success;
    } catch (e) {
      _status = GenreLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(GenreQuery next) async {
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