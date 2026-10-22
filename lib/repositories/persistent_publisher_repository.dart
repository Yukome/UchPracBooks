import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../models/page_result.dart';
import '../models/book_query.dart';
import 'publisher_repository.dart';
import 'book_repository.dart';

class PersistentPublisherRepository implements PublisherRepository {
  static const _key = 'publishers_v1';
  final SharedPreferences _prefs;
  final BookRepository _bookRepository;
  List<Publisher> _publishers = [];
  int _nextId = 1;
  static bool dataWasReset = false;

  PersistentPublisherRepository(this._prefs, this._bookRepository) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _publishers = [
        const Publisher(id: 1, name: 'АСТ', city: 'Москва', foundedYear: 1990),
        const Publisher(id: 2, name: 'Эксмо', city: 'Москва', foundedYear: 1991),
        const Publisher(id: 3, name: 'Азбука', city: 'Санкт-Петербург', foundedYear: 1995),
        const Publisher(id: 4, name: 'Питер', city: 'Санкт-Петербург', foundedYear: 1991),
      ];
      _nextId = 5;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _publishers = list.map((e) => Publisher.fromJson(e as Map<String, dynamic>)).toList();
      _nextId = _publishers.isEmpty ? 1 : _publishers.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (e) {
      _publishers = [];
      _nextId = 1;
      _persist();
      dataWasReset = true;
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_publishers.map((p) => p.toJson()).toList()));
  }

  @override
  Future<PageResult<Publisher>> find(PublisherQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var rows = _publishers.where((p) => q.includeDeleted || !p.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((p) =>
        p.name.toLowerCase().contains(needle) ||
        p.city.toLowerCase().contains(needle)).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'city' => a.city.compareTo(b.city),
        'foundedYear' => (a.foundedYear ?? 0).compareTo(b.foundedYear ?? 0),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Publisher>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Publisher?> findById(int id) async {
    final index = _publishers.indexWhere((p) => p.id == id);
    return index != -1 ? _publishers[index] : null;
  }

  @override
  Future<Publisher> create(Publisher publisher) async {
    final newPublisher = Publisher(
      id: _nextId++,
      name: publisher.name,
      city: publisher.city,
      foundedYear: publisher.foundedYear,
    );
    _publishers.add(newPublisher);
    await _persist();
    return newPublisher;
  }

  @override
  Future<Publisher> update(Publisher publisher) async {
    final index = _publishers.indexWhere((p) => p.id == publisher.id);
    if (index == -1) throw StateError('Издательство ${publisher.id} не найдено');
    _publishers[index] = publisher;
    await _persist();
    return publisher;
  }

  @override
  Future<void> softDelete(int id) async {
    final books = await _bookRepository.find(BookQuery(publisherId: id, size: 1));
    if (books.total > 0) {
      throw StateError('Невозможно удалить издательство. На него ссылаются ${books.total} книг(и).');
    }

    final i = _publishers.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Издательство $id не найдено');
    _publishers[i] = _publishers[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    final books = await _bookRepository.find(BookQuery(publisherId: id, size: 1));
    if (books.total > 0) {
      throw StateError('Невозможно удалить издательство. На него ссылаются ${books.total} книг(и).');
    }
    _publishers.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _publishers.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Издательство $id не найдено');
    _publishers[i] = _publishers[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _publishers.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _publishers[i] = _publishers[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}