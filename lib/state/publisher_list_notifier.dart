import 'package:flutter/foundation.dart';
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
  final Set<int> _selected = {};

  PublisherQuery get query => _query;
  PageResult<Publisher> get result => _result;
  PublisherLoadStatus get status => _status;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = PublisherLoadStatus.loading;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = PublisherLoadStatus.success;
    } catch (e) {
      _status = PublisherLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(PublisherQuery next) async {
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
    try {
      await _repository.deleteMany(_selected.toList());
      _selected.clear();
      await load();
    } catch (e) {
      rethrow;
    }
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