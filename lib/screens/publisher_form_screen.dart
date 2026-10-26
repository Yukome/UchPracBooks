import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/publisher.dart';
import '../core/validators.dart';
import '../repositories/publisher_repository.dart';
import '../widgets/entity_form.dart';

class PublisherFormScreen extends StatefulWidget {
  final int? id;
  const PublisherFormScreen({super.key, this.id});
  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _yearController = TextEditingController();
  bool _isLoading = true;
  bool get isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _loadPublisher();
    else _isLoading = false;
  }

  Future<void> _loadPublisher() async {
    final repo = context.read<PublisherRepository>();
    final publisher = await repo.findById(widget.id!);
    if (publisher != null && mounted) {
      _nameController.text = publisher.name;
      _cityController.text = publisher.city;
      _yearController.text = publisher.foundedYear?.toString() ?? '';
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final publisher = Publisher(
      id: widget.id ?? 0,
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      foundedYear: int.tryParse(_yearController.text),
    );
    final repo = context.read<PublisherRepository>();
    if (isEditing) await repo.update(publisher);
    else await repo.create(publisher);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return EntityForm(
      title: isEditing ? 'Редактирование издательства' : 'Новое издательство',
      isEditing: isEditing,
      backPath: '/publishers',
      onSubmit: _submit,
      fields: [
        FormFieldSpec(
          label: 'Название',
          controller: _nameController,
          validator: (val) => Validators.length(val, 2, 100),
          fieldKey: 'name',
        ),
        FormFieldSpec(
          label: 'Город',
          controller: _cityController,
          validator: (val) => Validators.required(val),
          fieldKey: 'city',
        ),
        FormFieldSpec(
          label: 'Год основания (опционально)',
          controller: _yearController,
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.isEmpty) return null;
            return Validators.number(val, min: 1400, max: 2026);
          },
          fieldKey: 'foundedYear',
        ),
      ],
    );
  }
}