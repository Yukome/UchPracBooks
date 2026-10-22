import 'package:go_router/go_router.dart';
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
import '../main.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  observers: [routeObserver],
  routes: [
    GoRoute(
      path: '/books',
      builder: (context, state) => const BookListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const BookFormScreen(),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => BookFormScreen(
            id: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/authors',
      builder: (context, state) => const AuthorListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const AuthorFormScreen(),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => AuthorFormScreen(
            id: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/publishers',
      builder: (context, state) => const PublisherListScreen(),
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
      routes: [
        GoRoute(path: 'new', builder: (context, state) => const ReaderFormScreen()),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => ReaderFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
        ),
      ],
    ),
  ],
);