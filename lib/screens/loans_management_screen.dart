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
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final dio = context.read<Dio>();
      final res = await dio.get('/loans', queryParameters: {
        'size': 1000,
        if (_statusFilter != null) 'status': _statusFilter,
      });
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

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return 'На руках';
      case 'returned': return 'Возвращена';
      case 'overdue': return 'Просрочена';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.blue;
      case 'returned': return Colors.green;
      case 'overdue': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double maxCardWidth = screenWidth < 600 ? 280 : 320;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление выдачами', overflow: TextOverflow.ellipsis),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: DropdownButton<String?>(
                value: _statusFilter,
                hint: const Text('Все выдачи', style: TextStyle(fontSize: 14)),
                underline: const SizedBox(),
                isDense: true,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Все', style: TextStyle(fontSize: 14))),
                  DropdownMenuItem(value: 'active', child: Text('Активные', style: TextStyle(fontSize: 14))),
                  DropdownMenuItem(value: 'overdue', child: Text('Просроченные', style: TextStyle(fontSize: 14))),
                  DropdownMenuItem(value: 'returned', child: Text('Возвращенные', style: TextStyle(fontSize: 14))),
                ],
                onChanged: (val) {
                  setState(() => _statusFilter = val);
                  _load();
                },
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
              ? const Center(child: Text('Нет выдач', style: TextStyle(fontSize: 18)))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxCardWidth,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 260,
                      ),
                      itemCount: _loans.length,
                      itemBuilder: (context, i) {
                        final loan = _loans[i];
                        final isActive = loan['status'] == 'active' || loan['status'] == 'overdue';
                        
                        final issuedAt = loan['issuedAt'] != null ? _formatDate(loan['issuedAt']) : '—';
                        final dueAt = loan['dueAt'] != null ? _formatDate(loan['dueAt']) : '—';
                        final returnedAt = loan['returnedAt'] != null ? _formatDate(loan['returnedAt']) : null;

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loan['book']?['title'] ?? 'Неизвестная книга',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Читатель: ${loan['reader']?['fullName'] ?? '—'}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Divider(height: 16),
                                
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(loan['status']).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _getStatusColor(loan['status'])),
                                  ),
                                  child: Text(
                                    _getStatusText(loan['status']),
                                    style: TextStyle(
                                      color: _getStatusColor(loan['status']),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text('Выдана: $issuedAt', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                
                                if (isActive)
                                  Row(
                                    children: [
                                      const Icon(Icons.event_busy, size: 14, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text('Сдать до: $dueAt', style: const TextStyle(fontSize: 12, color: Colors.red), overflow: TextOverflow.ellipsis)),
                                    ],
                                  )
                                else if (returnedAt != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text('Возвращена: $returnedAt', style: const TextStyle(fontSize: 12, color: Colors.green), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),

                                const Spacer(),

                                if (isActive)
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () => _returnBook(loan['id']),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      child: const Text('Вернуть книгу', style: TextStyle(fontSize: 13)),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}