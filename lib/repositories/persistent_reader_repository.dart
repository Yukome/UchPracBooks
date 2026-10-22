import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../models/page_result.dart';
import 'reader_repository.dart';

class PersistentReaderRepository implements ReaderRepository {
  static const _key = 'readers_v1';
  final SharedPreferences _prefs;
  List<Reader> _readers = [];
  int _nextId = 1;
  int _nextCardId = 1;
  static bool dataWasReset = false;

  PersistentReaderRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _readers = [
        Reader(
          id: 1,
          fullName: 'Смирнов П. А.',
          email: 'smirnov@example.com',
          phone: '+7 900 100-10-01',
          card: LibraryCard(
            id: 1,
            number: 'RC-000001',
            issuedAt: DateTime(2026, 1, 15),
            expiresAt: DateTime(2027, 1, 15),
          ),
        ),
      ];
      _nextId = 2;
      _nextCardId = 2;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _readers = list.map((e) => Reader.fromJson(e as Map<String, dynamic>)).toList();
      _nextId = _readers.isEmpty ? 1 : _readers.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
      final cardIds = _readers.where((r) => r.card != null).map((r) => r.card!.id).toList();
      _nextCardId = cardIds.isEmpty ? 1 : cardIds.reduce((a, b) => a > b ? a : b) + 1;
    } catch (e) {
      _readers = [];
      _nextId = 1;
      _nextCardId = 1;
      _persist();
      dataWasReset = true;
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_readers.map((r) => r.toJson()).toList()));
  }

  @override
  Future<PageResult<Reader>> find(ReaderQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var rows = _readers.where((r) => q.includeDeleted || !r.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((r) =>
        r.fullName.toLowerCase().contains(needle) ||
        r.email.toLowerCase().contains(needle)).toList();
    }

    rows.sort((a, b) {
      final result = a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Reader>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Reader?> findById(int id) async {
    final index = _readers.indexWhere((r) => r.id == id);
    return index != -1 ? _readers[index] : null;
  }

  @override
  Future<Reader> create(Reader reader) async {
    final newReader = Reader(
      id: _nextId++,
      fullName: reader.fullName,
      email: reader.email,
      phone: reader.phone,
      card: reader.card != null 
          ? LibraryCard(
              id: _nextCardId++,
              number: reader.card!.number,
              issuedAt: reader.card!.issuedAt,
              expiresAt: reader.card!.expiresAt,
            )
          : null,
    );
    _readers.add(newReader);
    await _persist();
    return newReader;
  }

  @override
  Future<Reader> update(Reader reader) async {
    final index = _readers.indexWhere((r) => r.id == reader.id);
    if (index == -1) throw StateError('Читатель ${reader.id} не найден');
    _readers[index] = reader;
    await _persist();
    return reader;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Читатель $id не найден');
    _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _readers.removeWhere((r) => r.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Читатель $id не найден');
    _readers[i] = _readers[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _readers.indexWhere((r) => r.id == id && !r.isDeleted);
      if (i != -1) {
        _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}