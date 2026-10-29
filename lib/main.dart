import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'core/router.dart';
import 'core/api_client.dart';
import 'repositories/auth_api.dart';
import 'state/auth_notifier.dart';
import 'repositories/book_repository.dart';
import 'state/book_list_notifier.dart';
import 'repositories/author_repository.dart';
import 'state/author_list_notifier.dart';
import 'repositories/publisher_repository.dart';
import 'state/publisher_list_notifier.dart';
import 'repositories/genre_repository.dart';
import 'state/genre_list_notifier.dart';
import 'repositories/reader_repository.dart';
import 'state/reader_list_notifier.dart';
import 'state/reference_data_notifier.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_author_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_reader_repository.dart';
import 'widgets/inactivity_watcher.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  
  final prefs = await SharedPreferences.getInstance();
  final dio = buildDio();
  final authApi = AuthApi(dio);
  final authNotifier = AuthNotifier(prefs, authApi);
  await authNotifier.restore();

  onTokenRefresh = () async {
    try {
      await authNotifier.refreshTokens();
      return authNotifier.accessToken;
    } catch (e) {
      return null;
    }
  };
  
  onAuthFailed = () {
    authNotifier.logout();
  };

  final appRouter = buildRouter(authNotifier);

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        Provider<AuthApi>.value(value: authApi),
        ProxyProvider<Dio, BookRepository>(
          update: (_, dio, __) => ApiBookRepository(dio),
        ),
        ChangeNotifierProvider(
          create: (context) => BookListNotifier(context.read<BookRepository>())..load(),
        ),
        ProxyProvider<Dio, AuthorRepository>(
          update: (_, dio, __) => ApiAuthorRepository(dio),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthorListNotifier(context.read<AuthorRepository>())..load(),
        ),
        ProxyProvider<Dio, PublisherRepository>(
          update: (_, dio, __) => ApiPublisherRepository(dio),
        ),
        ChangeNotifierProvider(
          create: (context) => PublisherListNotifier(context.read<PublisherRepository>())..load(),
        ),
        ProxyProvider<Dio, GenreRepository>(
          update: (_, dio, __) => ApiGenreRepository(dio),
        ),
        ChangeNotifierProvider(
          create: (context) => GenreListNotifier(context.read<GenreRepository>())..load(),
        ),
        ProxyProvider<Dio, ReaderRepository>(
          update: (_, dio, __) => ApiReaderRepository(dio),
        ),
        ChangeNotifierProvider(
          create: (context) => ReaderListNotifier(context.read<ReaderRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => ReferenceDataNotifier(
            context.read<AuthorRepository>(),
            context.read<GenreRepository>(),
            context.read<PublisherRepository>(),
          ),
        ),
      ],
      child: LibraryApp(router: appRouter),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  final GoRouter router;
  const LibraryApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Библиотека',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) {
        if (!auth.isAuthenticated) {
          return child!;
        }
        return InactivityWatcher(
          timeout: const Duration(minutes: 3),
          warningTime: const Duration(seconds: 30),
          onTimeout: () async {
            await context.read<AuthNotifier>().logout();
          },
          child: child!,
        );
      },
    );
  }
}