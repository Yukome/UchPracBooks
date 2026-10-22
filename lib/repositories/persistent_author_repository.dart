import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

class PersistentAuthorRepository implements AuthorRepository {
  static const _key = 'authors_v1';
  final SharedPreferences _prefs;
  List<Author> _authors = [];
  int _nextId = 1;
  static bool dataWasReset = false;

  PersistentAuthorRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _authors = _getSeedAuthors();
      _nextId = _authors.isEmpty ? 1 : _authors.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _authors = list.map((e) => Author.fromJson(e as Map<String, dynamic>)).toList();
      _nextId = _authors.isEmpty ? 1 : _authors.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (e) {
      _authors = _getSeedAuthors();
      _nextId = _authors.isEmpty ? 1 : _authors.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
      dataWasReset = true;
    }
  }

  List<Author> _getSeedAuthors() {
    return [
      const Author(id: 1, fullName: 'Толстой Л. Н.', birthYear: 1828, country: 'Россия'),
      const Author(id: 2, fullName: 'Достоевский Ф. М.', birthYear: 1821, country: 'Россия'),
      const Author(id: 3, fullName: 'Булгаков М. А.', birthYear: 1891, country: 'Россия'),
      const Author(id: 4, fullName: 'Стругацкий А. Н.', birthYear: 1925, country: 'СССР'),
      const Author(id: 5, fullName: 'Стругацкий Б. Н.', birthYear: 1933, country: 'СССР'),
      const Author(id: 6, fullName: 'Оруэлл Дж.', birthYear: 1903, country: 'Великобритания'),
      const Author(id: 7, fullName: 'Брэдбери Р.', birthYear: 1920, country: 'США'),
      const Author(id: 8, fullName: 'Ремарк Э. М.', birthYear: 1898, country: 'Германия'),
    ];
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_authors.map((a) => a.toJson()).toList()));
  }

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    
    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();
    
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((a) =>
        a.fullName.toLowerCase().contains(needle) ||
        a.country.toLowerCase().contains(needle)).toList();
    }

    if (q.yearFrom != null) rows = rows.where((a) => (a.birthYear ?? 0) >= q.yearFrom!).toList();
    if (q.yearTo != null) rows = rows.where((a) => (a.birthYear ?? 0) <= q.yearTo!).toList();
    
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'birthYear' => (a.birthYear ?? 0).compareTo(b.birthYear ?? 0),
        'country' => a.country.compareTo(b.country),
        _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);
    
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    final index = _authors.indexWhere((a) => a.id == id);
    if (index == -1) return null;
    return _authors[index];
  }

  @override
  Future<Author> create(Author author) async {
    final newAuthor = Author(
      id: _nextId,
      fullName: author.fullName,
      birthYear: author.birthYear,
      country: author.country,
    );
    _nextId++;
    _authors.add(newAuthor);
    await _persist();
    return newAuthor;
  }

  @override
  Future<Author> update(Author author) async {
    final index = _authors.indexWhere((a) => a.id == author.id);
    if (index == -1) throw StateError('Автор ${author.id} не найден');
    _authors[index] = author;
    await _persist();
    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}