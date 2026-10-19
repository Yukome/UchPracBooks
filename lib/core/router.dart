import 'package:go_router/go_router.dart';
import '../screens/book_list_screen.dart';
import '../screens/author_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/books',
      builder: (context, state) => const BookListScreen(),
    ),
    GoRoute(
      path: '/authors',
      builder: (context, state) => const AuthorListScreen(),
    ),
  ],
);