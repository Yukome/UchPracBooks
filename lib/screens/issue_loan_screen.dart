import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../repositories/reader_repository.dart';
import '../repositories/book_repository.dart';
import '../models/reader.dart';
import '../models/book.dart';
import '../models/reader_query.dart';
import '../models/book_query.dart';

class IssueLoanScreen extends StatefulWidget {
  const IssueLoanScreen({super.key});
  @override
  State<IssueLoanScreen> createState() => _IssueLoanScreenState();
}

class _IssueLoanScreenState extends State<IssueLoanScreen> {
  List<Reader> _readers = [];
  List<Book> _books = [];
  int? _selectedReaderId;
  int? _selectedBookId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final rRepo = context.read<ReaderRepository>();
    final bRepo = context.read<BookRepository>();
    final rs = await rRepo.find(const ReaderQuery(size: 1000));
    final bs = await bRepo.find(const BookQuery(size: 1000, available: true));
    if (mounted) {
      setState(() {
        _readers = rs.items;
        _books = bs.items;
        _isLoading = false;
      });
    }
  }

  Future<void> _issue() async {
    if (_selectedReaderId == null || _selectedBookId == null) return;
    try {
      final dio = context.read<Dio>();
      await dio.post('/loans', data: {
        'readerId': _selectedReaderId,
        'bookId': _selectedBookId,
        'days': 14,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Книга успешно выдана!')));
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выдать книгу'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Читатель', border: OutlineInputBorder()),
                  items: _readers.map((r) => DropdownMenuItem(value: r.id, child: Text(r.fullName))).toList(),
                  onChanged: (v) => setState(() => _selectedReaderId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Книга (в наличии)', border: OutlineInputBorder()),
                  items: _books.map((b) => DropdownMenuItem(value: b.id, child: Text(b.title))).toList(),
                  onChanged: (v) => setState(() => _selectedBookId = v),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: _issue, child: const Text('Оформить выдачу')),
                )
              ],
            ),
          ),
    );
  }
}