import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reader.dart';
import '../core/validators.dart';
import '../core/phone_input_formatter.dart';
import '../repositories/reader_repository.dart';
import '../widgets/entity_form.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? id;
  const ReaderFormScreen({super.key, this.id});
  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  bool _hasCard = false;
  bool _isLoading = true;
  bool get isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _loadReader();
    else _isLoading = false;
    
    _cardNumberController.addListener(() => setState(() {}));
  }

  Future<void> _loadReader() async {
    final repo = context.read<ReaderRepository>();
    final reader = await repo.findById(widget.id!);
    if (reader != null && mounted) {
      _nameController.text = reader.fullName;
      _emailController.text = reader.email;
      _phoneController.text = reader.phone;
      if (reader.card != null) {
        _hasCard = true;
        _cardNumberController.text = reader.card!.number;
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    LibraryCard? card;
    if (_hasCard) {
      final repo = context.read<ReaderRepository>();
      Reader? existingReader;
      if (isEditing) existingReader = await repo.findById(widget.id!);
      
      card = LibraryCard(
        id: existingReader?.card?.id ?? 0,
        number: _cardNumberController.text.trim(),
        issuedAt: existingReader?.card?.issuedAt ?? DateTime.now(),
        expiresAt: existingReader?.card?.expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      );
    }

    final reader = Reader(
      id: widget.id ?? 0,
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      card: card,
    );

    final repo = context.read<ReaderRepository>();
    if (isEditing) await repo.update(reader);
    else await repo.create(reader);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return EntityForm(
      title: isEditing ? 'Редактирование читателя' : 'Новый читатель',
      isEditing: isEditing,
      backPath: '/readers',
      onSubmit: _submit,
      fields: [
        FormFieldSpec(
          label: 'ФИО',
          controller: _nameController,
          validator: (val) => Validators.length(val, 2, 100),
        ),
        FormFieldSpec(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (val) => Validators.email(val),
        ),
        FormFieldSpec(
          label: 'Телефон',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          hint: '+7 900 000-00-00',
          validator: (val) => Validators.phone(val),
          inputFormatters: [PhoneInputFormatter()],
        ),
      ],
      customContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Divider(),
          SwitchListTile(
            title: const Text('Есть читательский билет'),
            value: _hasCard,
            onChanged: (val) => setState(() => _hasCard = val),
          ),
          if (_hasCard) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(labelText: 'Номер билета (например, RC-000001)', border: OutlineInputBorder()),
              validator: (val) => _hasCard ? Validators.required(val) : null,
            ),
          ],
          const Divider(),
        ],
      ),
    );
  }
}