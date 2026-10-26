import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/genre.dart';
import '../core/validators.dart';
import '../repositories/genre_repository.dart';
import '../widgets/entity_form.dart';

class GenreFormScreen extends StatefulWidget {
  final int? id;
  const GenreFormScreen({super.key, this.id});
  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = true;
  bool get isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _loadGenre();
    else _isLoading = false;
  }

  Future<void> _loadGenre() async {
    final repo = context.read<GenreRepository>();
    final genre = await repo.findById(widget.id!);
    if (genre != null && mounted) {
      _nameController.text = genre.name;
      _descriptionController.text = genre.description;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final genre = Genre(
      id: widget.id ?? 0,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );
    final repo = context.read<GenreRepository>();
    if (isEditing) await repo.update(genre);
    else await repo.create(genre);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return EntityForm(
      title: isEditing ? 'Редактирование жанра' : 'Новый жанр',
      isEditing: isEditing,
      backPath: '/genres',
      onSubmit: _submit,
      fields: [
        FormFieldSpec(
          label: 'Название',
          controller: _nameController,
          validator: (val) => Validators.length(val, 2, 100),
          fieldKey: 'name',
        ),
        FormFieldSpec(
          label: 'Описание',
          controller: _descriptionController,
          validator: (val) => Validators.length(val, 2, 500),
          maxLines: 3,
          fieldKey: 'description',
        ),
      ],
    );
  }
}