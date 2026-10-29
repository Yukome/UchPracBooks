import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({super.key});
  @override
  State<MyLoansScreen> createState() => _MyLoansScreenState();
}

class _MyLoansScreenState extends State<MyLoansScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои выдачи'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
              ? const Center(child: Text('У вас нет активных выдач'))
              : ListView.builder(
                  itemCount: _loans.length,
                  itemBuilder: (context, i) {
                    final loan = _loans[i];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(loan['book']?['title'] ?? 'Книга'),
                        subtitle: Text('Статус: ${loan['status']}'),
                        trailing: loan['status'] == 'active' 
                            ? TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Срок продлен на 14 дней!')));
                                }, 
                                child: const Text('Продлить')
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}