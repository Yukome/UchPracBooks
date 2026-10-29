import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../state/auth_notifier.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотека'),
        actions: [
          Center(child: Text('${user?.fullName} (${user?.role.name})')),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await context.read<AuthNotifier>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (auth.user?.role == Role.reader)
                _buildCard(context, 'Мои выдачи', Icons.list_alt, '/my-loans'),
              _buildCard(context, 'Книги', Icons.book, '/books'),
              if (auth.user?.role == Role.librarian) ...[
                _buildCard(context, 'Выдать книгу', Icons.add_card, '/issue-loan'),
                _buildCard(context, 'Управление выдачами', Icons.assignment_return, '/loans-management'),
              ],
              if (auth.has(Role.librarian)) ...[
                _buildCard(context, 'Авторы', Icons.person, '/authors'),
                _buildCard(context, 'Издательства', Icons.business, '/publishers'),
                _buildCard(context, 'Жанры', Icons.category, '/genres'),
                _buildCard(context, 'Читатели', Icons.group, '/readers'),
              ],
              if (auth.has(Role.admin)) ... [
                _buildCard(context, 'Статистика', Icons.analytics, '/admin/stats'),
                _buildCard(context, 'Пользователи', Icons.manage_accounts, '/admin/users'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, String path) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(path),
      ),
    );
  }
}