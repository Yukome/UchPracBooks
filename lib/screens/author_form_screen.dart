import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/author.dart';
import '../core/validators.dart';
import '../repositories/author_repository.dart';
import '../widgets/entity_form.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? id;
  const AuthorFormScreen({super.key, this.id});
  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isLoading = true;
  bool get isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _loadAuthor();
    else _isLoading = false;
  }

  Future<void> _loadAuthor() async {
    final repo = context.read<AuthorRepository>();
    final author = await repo.findById(widget.id!);
    if (author != null && mounted) {
      _nameController.text = author.fullName;
      _yearController.text = author.birthYear?.toString() ?? '';
      _countryController.text = author.country;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final author = Author(
      id: widget.id ?? 0,
      fullName: _nameController.text.trim(),
      birthYear: int.tryParse(_yearController.text),
      country: _countryController.text.trim(),
    );
    final repo = context.read<AuthorRepository>();
    if (isEditing) await repo.update(author);
    else await repo.create(author);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return EntityForm(
      title: isEditing ? 'Редактирование автора' : 'Новый автор',
      isEditing: isEditing,
      backPath: '/authors',
      onSubmit: _submit,
      fields: [
        FormFieldSpec(
          label: 'ФИО',
          controller: _nameController,
          validator: (val) => Validators.length(val, 2, 100),
          fieldKey: 'fullName',
        ),
        FormFieldSpec(
          label: 'Год рождения (опционально)',
          controller: _yearController,
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.isEmpty) return null;
            return Validators.number(val, min: 1000, max: 2026);
          },
          fieldKey: 'birthYear',
        ),
        FormFieldSpec(
          label: 'Страна',
          controller: _countryController,
          validator: (val) => Validators.required(val),
          fieldKey: 'country',
        ),
      ],
    );
  }
}