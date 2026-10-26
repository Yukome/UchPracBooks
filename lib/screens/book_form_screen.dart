import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../core/validators.dart';
import '../repositories/book_repository.dart';
import '../state/reference_data_notifier.dart';
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
  
  bool get isEditing => widget.id != null;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await context.read<ReferenceDataNotifier>().ensureLoaded();

    if (!mounted) return;
    final refData = context.read<ReferenceDataNotifier>();
    
    if (refData.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки справочников: ${refData.error}'), backgroundColor: Colors.red),
      );
      return;
    }

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
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    final repo = context.read<BookRepository>();
    final isbn = _isbnController.text.trim();

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
    final refData = context.watch<ReferenceDataNotifier>();

    return EntityForm(
      title: isEditing ? 'Редактирование книги' : 'Новая книга',
      isEditing: isEditing,
      backPath: '/books',
      onSubmit: _submit,
      fields: [
        FormFieldSpec(label: 'Название', controller: _titleController, validator: (v) => Validators.length(v, 2, 200), fieldKey: 'title'),
        FormFieldSpec(
          label: 'ISBN', 
          controller: _isbnController, 
          keyboardType: TextInputType.number,
          hint: '978-5-17-118366-4',
          validator: (v) => Validators.isbn(v),
          fieldKey: 'isbn',
        ),
        FormFieldSpec(label: 'Год', controller: _yearController, keyboardType: TextInputType.number, validator: (v) => Validators.number(v, min: 1450, max: 2026), fieldKey: 'year'),
        FormFieldSpec(label: 'Страниц', controller: _pagesController, keyboardType: TextInputType.number, validator: (v) => Validators.number(v, min: 1), fieldKey: 'pages'),
        FormFieldSpec(label: 'Экземпляров', controller: _copiesController, keyboardType: TextInputType.number, validator: (v) => Validators.number(v, min: 0), fieldKey: 'copiesTotal'),
      ],
      customContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            value: _publisherId,
            decoration: const InputDecoration(labelText: 'Издательство', border: OutlineInputBorder()),
            items: refData.publishers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (val) => setState(() => _publisherId = val),
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
                  children: refData.authors.map((a) {
                    final selected = field.value!.contains(a.id);
                    return FilterChip(
                      label: Text(a.fullName),
                      selected: selected,
                      onSelected: (_) {
                        final next = [...field.value!];
                        selected ? next.remove(a.id) : next.add(a.id);
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
                  children: refData.genres.map((g) {
                    final selected = field.value!.contains(g.id);
                    return FilterChip(
                      label: Text(g.name),
                      selected: selected,
                      onSelected: (_) {
                        final next = [...field.value!];
                        selected ? next.remove(g.id) : next.add(g.id);
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