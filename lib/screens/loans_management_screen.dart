import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

class LoansManagementScreen extends StatefulWidget {
  const LoansManagementScreen({super.key});
  @override
  State<LoansManagementScreen> createState() => _LoansManagementScreenState();
}

class _LoansManagementScreenState extends State<LoansManagementScreen> {
  List<dynamic> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = context.read<Dio>();
      final res = await dio.get('/loans');
      if (mounted) {
        setState(() {
          _loans = (res.data as Map<String, dynamic>)['items'] as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _returnBook(int loanId) async {
    try {
      final dio = context.read<Dio>();
      await dio.post('/loans/$loanId/return');
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Книга возвращена!')));
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
        title: const Text('Управление выдачами'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _loans.length,
              itemBuilder: (context, i) {
                final loan = _loans[i];
                final isActive = loan['status'] == 'active' || loan['status'] == 'overdue';
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(loan['book']?['title'] ?? 'Книга'),
                    subtitle: Text('Читатель: ${loan['reader']?['fullName'] ?? ''}\nСтатус: ${loan['status']}'),
                    isThreeLine: true,
                    trailing: isActive 
                        ? ElevatedButton(
                            onPressed: () => _returnBook(loan['id']),
                            child: const Text('Вернуть'),
                          )
                        : const Text('Возвращена', style: TextStyle(color: Colors.green)),
                  ),
                );
              },
            ),
    );
  }
}