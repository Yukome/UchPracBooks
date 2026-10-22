import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router.dart';
import 'repositories/book_repository.dart';
import 'repositories/persistent_book_repository.dart';
import 'state/book_list_notifier.dart';
import 'repositories/author_repository.dart';
import 'repositories/persistent_author_repository.dart';
import 'state/author_list_notifier.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/persistent_publisher_repository.dart';
import 'state/publisher_list_notifier.dart';
import 'repositories/genre_repository.dart';
import 'repositories/persistent_genre_repository.dart';
import 'state/genre_list_notifier.dart';
import 'repositories/reader_repository.dart';
import 'repositories/persistent_reader_repository.dart';
import 'state/reader_list_notifier.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>(create: (_) => PersistentBookRepository(prefs)),
        ChangeNotifierProvider(
          create: (context) => BookListNotifier(context.read<BookRepository>())..load(),
        ),
        Provider<AuthorRepository>(create: (_) => PersistentAuthorRepository(prefs)),
        ChangeNotifierProvider(
          create: (context) => AuthorListNotifier(context.read<AuthorRepository>())..load(),
        ),
        Provider<PublisherRepository>(
          create: (context) => PersistentPublisherRepository(prefs, context.read<BookRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => PublisherListNotifier(context.read<PublisherRepository>())..load(),
        ),
        Provider<GenreRepository>(create: (_) => PersistentGenreRepository(prefs)),
        ChangeNotifierProvider(
          create: (context) => GenreListNotifier(context.read<GenreRepository>())..load(),
        ),
        Provider<ReaderRepository>(create: (_) => PersistentReaderRepository(prefs)),
        ChangeNotifierProvider(
          create: (context) => ReaderListNotifier(context.read<ReaderRepository>())..load(),
        ),
      ],
      child: const LibraryApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (PersistentBookRepository.dataWasReset ||
        PersistentAuthorRepository.dataWasReset ||
        PersistentPublisherRepository.dataWasReset ||
        PersistentGenreRepository.dataWasReset ||
        PersistentReaderRepository.dataWasReset) {
      
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Данные были сброшены из-за изменения формата хранилища.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  });
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Библиотека',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}