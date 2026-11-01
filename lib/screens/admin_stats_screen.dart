import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});
  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool _isLoading = true;

  int _booksCount = 0;
  int _readersCount = 0;
  int _activeLoansCount = 0;
  int _overdueLoansCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dio = context.read<Dio>();
      final results = await Future.wait([
        dio.get('/books', queryParameters: {'size': 1}),
        dio.get('/readers', queryParameters: {'size': 1}),
        dio.get('/loans', queryParameters: {'size': 1000}),
      ]);
      final booksData = results[0].data as Map<String, dynamic>;
      final readersData = results[1].data as Map<String, dynamic>;
      final loansData = results[2].data as Map<String, dynamic>;

      final loansList = loansData['items'] as List;
      int active = 0;
      int overdue = 0;

      for (var loan in loansList) {
        if (loan['status'] == 'active') active++;
        if (loan['status'] == 'overdue') overdue++;
      }

      if (mounted) {
        setState(() {
          _booksCount = booksData['total'] as int? ?? 0;
          _readersCount = readersData['total'] as int? ?? 0;
          _activeLoansCount = active;
          _overdueLoansCount = overdue;
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
        title: const Text('Статистика системы'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Обзор библиотеки',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: MediaQuery.sizeOf(context).width > 600
                          ? 2
                          : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                      children: [
                        _buildStatCard(
                          'Всего книг',
                          _booksCount.toString(),
                          Icons.library_books,
                          Colors.indigo,
                        ),
                        _buildStatCard(
                          'Читателей',
                          _readersCount.toString(),
                          Icons.people,
                          Colors.teal,
                        ),
                        _buildStatCard(
                          'Книг на руках',
                          _activeLoansCount.toString(),
                          Icons.book_online,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Просрочено',
                          _overdueLoansCount.toString(),
                          Icons.warning,
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
