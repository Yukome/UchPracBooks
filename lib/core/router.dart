import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_notifier.dart';
import '../models/app_user.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/author_list_screen.dart';
import '../screens/book_form_screen.dart';
import '../screens/author_form_screen.dart';
import '../screens/publisher_list_screen.dart';
import '../screens/publisher_form_screen.dart';
import '../screens/genre_list_screen.dart';
import '../screens/genre_form_screen.dart';
import '../screens/reader_list_screen.dart';
import '../screens/reader_form_screen.dart';
import '../screens/my_loans_screen.dart';
import '../screens/issue_loan_screen.dart';
import '../screens/admin_users_screen.dart';
import '../screens/admin_stats_screen.dart';
import '../screens/loans_management_screen.dart';
import '../main.dart';

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    observers: [routeObserver],
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/', builder: (c, s) => const DashboardScreen()),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      GoRoute(
        path: '/my-loans',
        builder: (c, s) => const MyLoansScreen(),
      ),
      GoRoute(
        path: '/issue-loan',
        builder: (c, s) => const IssueLoanScreen(),
        redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
      ),
      GoRoute(
        path: '/loans-management',
        builder: (c, s) => const LoansManagementScreen(),
        redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
      ),
      GoRoute(
        path: '/admin/users',
        builder: (c, s) => const AdminUsersScreen(),
        redirect: (context, state) => auth.has(Role.admin) ? null : '/forbidden',
      ),
      GoRoute(
        path: '/admin/stats',
        builder: (c, s) => const AdminStatsScreen(),
        redirect: (context, state) => auth.has(Role.admin) ? null : '/forbidden',
      ),
      GoRoute(
        path: '/books',
        builder: (context, state) => const BookListScreen(),
        routes: [
          GoRoute(
            path: 'new', 
            builder: (context, state) => const BookFormScreen(),
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) => BookFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
          ),
        ],
      ),

      GoRoute(
        path: '/authors',
        builder: (context, state) => const AuthorListScreen(),
        redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
        routes: [
          GoRoute(path: 'new', builder: (context, state) => const AuthorFormScreen()),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) => AuthorFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
        ],
      ),

      GoRoute(
        path: '/publishers',
        builder: (context, state) => const PublisherListScreen(),
        redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
        routes: [
          GoRoute(path: 'new', builder: (context, state) => const PublisherFormScreen()),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) => PublisherFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
        ],
      ),

      GoRoute(
        path: '/genres',
        builder: (context, state) => const GenreListScreen(),
        redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
        routes: [
          GoRoute(path: 'new', builder: (context, state) => const GenreFormScreen()),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) => GenreFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
        ],
      ),

      GoRoute(
        path: '/readers',
        builder: (context, state) => const ReaderListScreen(),
        redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
        routes: [
          GoRoute(path: 'new', builder: (context, state) => const ReaderFormScreen()),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) => ReaderFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
        ],
      ),
    ],
    errorBuilder: (c, s) => NotFoundScreen(location: s.uri.toString()),
  );
}

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещён')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'У вас нет прав для просмотра этой страницы',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  final String location;
  const NotFoundScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404')),
      body: Center(
        child: Text('Страница не найдена: $location', textAlign: TextAlign.center),
      ),
    );
  }
}