import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class FormFieldSpec {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final String? hint;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;

  const FormFieldSpec({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.hint,
    this.inputFormatters,
    this.maxLines,
  });
}

class EntityForm extends StatefulWidget {
  final String title;
  final bool isEditing;
  final List<FormFieldSpec> fields;
  final Widget? customContent;
  final Future<void> Function() onSubmit;
  final String backPath;

  const EntityForm({
    super.key,
    required this.title,
    required this.isEditing,
    required this.fields,
    required this.onSubmit,
    required this.backPath,
    this.customContent,
  });

  @override
  State<EntityForm> createState() => _EntityFormState();
}

class _EntityFormState extends State<EntityForm> {
  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      field.controller.addListener(_markChanged);
    }
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    for (final field in widget.fields) {
      field.controller.removeListener(_markChanged);
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      await widget.onSubmit();
      if (mounted) {
        _hasChanges = false;
        context.go(widget.backPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    if (!_hasChanges) {
      if (mounted) context.go(widget.backPath);
      return;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Вы уверены, что хотите уйти? Все введённые данные будут потеряны.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Остаться'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Уйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldPop == true && mounted) {
      _hasChanges = false;
      context.go(widget.backPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onPopInvoked(false, null),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final field in widget.fields) ...[
                      TextFormField(
                        controller: field.controller,
                        decoration: InputDecoration(
                          labelText: field.label,
                          hintText: field.hint,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: field.keyboardType,
                        validator: field.validator,
                        inputFormatters: field.inputFormatters,
                        maxLines: field.maxLines,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    if (widget.customContent != null) widget.customContent!,
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _handleSubmit,
                        child: _isSaving 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(widget.isEditing ? 'Сохранить' : 'Создать'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}