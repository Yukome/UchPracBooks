import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'core/router.dart';
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
import 'core/api_client.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_author_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_reader_repository.dart';
import 'state/reference_data_notifier.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final dio = buildDio();

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
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
      child: const LibraryApp(),
    ),
  );

  unawaited(autoLogin(dio));
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