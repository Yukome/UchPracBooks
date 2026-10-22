import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../models/filter_data.dart';
import '../core/validators.dart';
import '../repositories/book_repository.dart';
import '../repositories/publisher_repository.dart';
import '../widgets/entity_form.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;
  const BookFormScreen({super.key, this.id});
  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();
  final _pagesController = TextEditingController();
  final _copiesController = TextEditingController();
  
  int? _publisherId;
  List<int> _genreIds = [];
  List<int> _authorIds = [];
  List<Publisher> _publishers = [];
  List<int> _availableGenreIds = [];
  List<int> _availableAuthorIds = [];
  
  bool get isEditing => widget.id != null;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

    Future<void> _initData() async {
    final pubRepo = context.read<PublisherRepository>();
    final pubsResult = await pubRepo.find(const PublisherQuery(size: 1000));
    
    if (mounted) setState(() => _publishers = pubsResult.items);

    if (isEditing) {
      final repo = context.read<BookRepository>();
      final book = await repo.findById(widget.id!);
      if (book != null && mounted) {
        _titleController.text = book.title;
        _isbnController.text = book.isbn;
        _yearController.text = book.year.toString();
        _pagesController.text = book.pages.toString();
        _copiesController.text = book.copiesTotal.toString();
        _publisherId = book.publisherId;
        _genreIds = book.genreIds;
        _authorIds = book.authorIds;
        _availableGenreIds = genres.keys.toList();
        _availableAuthorIds = authorsMap.keys.toList();
      }
    } else {
      _availableGenreIds = genres.keys.toList();
      _availableAuthorIds = authorsMap.keys.toList();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateAvailableRelations(int? publisherId) async {
    if (publisherId == null) {
      setState(() {
        _availableGenreIds = genres.keys.toList();
        _availableAuthorIds = authorsMap.keys.toList();
      });
      return;
    }

    final repo = context.read<BookRepository>();
    final result = await repo.find(BookQuery(publisherId: publisherId, size: 10000));
    final genreIds = <int>{};
    final authorIds = <int>{};
    
    for (final book in result.items) {
      genreIds.addAll(book.genreIds);
      authorIds.addAll(book.authorIds);
    }

    if (mounted) {
      setState(() {
        _availableGenreIds = genreIds.toList();
        _availableAuthorIds = authorIds.toList();
        _genreIds.removeWhere((id) => !_availableGenreIds.contains(id));
        _authorIds.removeWhere((id) => !_availableAuthorIds.contains(id));
      });
    }
  }

  Future<void> _submit() async {
    final repo = context.read<BookRepository>();
    final isbn = _isbnController.text.trim();
    final allBooks = await repo.find(const BookQuery(size: 10000)); 
    final isDuplicate = allBooks.items.any((b) => b.isbn == isbn && b.id != widget.id);

    if (isDuplicate) throw Exception('Книга с таким ISBN уже существует!');

    final book = Book(
      id: widget.id ?? 0,
      title: _titleController.text.trim(),
      isbn: isbn,
      year: int.parse(_yearController.text),
      pages: int.parse(_pagesController.text),
      publisherId: _publisherId!,
      authorIds: _authorIds,
      genreIds: _genreIds,
      copiesTotal: int.parse(_copiesController.text),
      copiesAvailable: isEditing 
          ? (await repo.findById(widget.id!))!.copiesAvailable 
          : int.parse(_copiesController.text),
    );
    
    if (isEditing) await repo.update(book);
    else await repo.create(book);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return EntityForm(
      title: isEditing ? 'Редактирование книги' : 'Новая книга',
      isEditing: isEditing,
      backPath: '/books',
      onSubmit: _submit,
      fields: [
        FormFieldSpec(label: 'Название', controller: _titleController, validator: (v) => Validators.length(v, 2, 200)),
        FormFieldSpec(
          label: 'ISBN', 
          controller: _isbnController, 
          keyboardType: TextInputType.number,
          hint: '978-5-17-118366-4',
          validator: (v) => Validators.isbn(v),
        ),
        FormFieldSpec(label: 'Год', controller: _yearController, keyboardType: TextInputType.number, validator: (v) => Validators.number(v, min: 1450, max: 2026)),
        FormFieldSpec(label: 'Страниц', controller: _pagesController, keyboardType: TextInputType.number, validator: (v) => Validators.number(v, min: 1)),
        FormFieldSpec(label: 'Экземпляров', controller: _copiesController, keyboardType: TextInputType.number, validator: (v) => Validators.number(v, min: 0)),
      ],
      customContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            value: _publisherId,
            decoration: const InputDecoration(labelText: 'Издательство', border: OutlineInputBorder()),
            items: _publishers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (val) {
              setState(() => _publisherId = val);
              _updateAvailableRelations(val);
            },
            validator: (val) => val == null ? 'Выберите издательство' : null,
          ),
          const SizedBox(height: 24),
          const Text('Авторы', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FormField<List<int>>(
            initialValue: _authorIds,
            validator: (value) => (value == null || value.isEmpty) ? 'Выберите хотя бы одного автора' : null,
            builder: (field) {
              return InputDecorator(
                decoration: InputDecoration(border: const OutlineInputBorder(), errorText: field.errorText),
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: authorsMap.entries
                      .where((e) => _availableAuthorIds.contains(e.key))
                      .map((e) {
                    final selected = field.value!.contains(e.key);
                    return FilterChip(
                      label: Text(e.value),
                      selected: selected,
                      onSelected: (_) {
                        final next = [...field.value!];
                        selected ? next.remove(e.key) : next.add(e.key);
                        field.didChange(next);
                        setState(() => _authorIds = next);
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Жанры', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FormField<List<int>>(
            initialValue: _genreIds,
            validator: (value) => (value == null || value.isEmpty) ? 'Выберите хотя бы один жанр' : null,
            builder: (field) {
              return InputDecorator(
                decoration: InputDecoration(border: const OutlineInputBorder(), errorText: field.errorText),
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: genres.entries
                      .where((e) => _availableGenreIds.contains(e.key))
                      .map((e) {
                    final selected = field.value!.contains(e.key);
                    return FilterChip(
                      label: Text(e.value),
                      selected: selected,
                      onSelected: (_) {
                        final next = [...field.value!];
                        selected ? next.remove(e.key) : next.add(e.key);
                        field.didChange(next);
                        setState(() => _genreIds = next);
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}