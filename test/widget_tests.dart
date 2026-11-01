import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_uchprac2/models/book.dart';
import 'package:flutter_uchprac2/models/page_result.dart';
import 'package:flutter_uchprac2/models/app_user.dart';
import 'package:flutter_uchprac2/state/auth_notifier.dart';
import 'package:flutter_uchprac2/state/book_list_notifier.dart';
import 'package:flutter_uchprac2/repositories/book_repository.dart';
import 'package:flutter_uchprac2/screens/book_list_screen.dart';
import 'package:flutter_uchprac2/screens/author_form_screen.dart';
import 'package:flutter_uchprac2/repositories/author_repository.dart';

class FakeBookRepository implements BookRepository {
  final PageResult<Book> result;
  final Exception? error;
  final int delayMs;

  FakeBookRepository({required this.result, this.error, this.delayMs = 0});

  @override
  Future<PageResult<Book>> find(dynamic query, {dynamic cancelToken}) async {
    if (delayMs > 0) await Future.delayed(Duration(milliseconds: delayMs));
    if (error != null) throw error!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthorRepository implements AuthorRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthNotifier extends AuthNotifier {
  final Role _role;
  FakeAuthNotifier(this._role) : super(null as dynamic, null as dynamic);

  @override
  AppUser? get user => AppUser(id: 1, username: 'test', fullName: 'Test User', email: 'test@test.com', role: _role);
  @override
  bool has(Role r) => _role.level >= r.level;
}

Widget buildTestApp(Widget child, {BookRepository? bookRepo, Role role = Role.admin}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: FakeAuthNotifier(role)),
      if (bookRepo != null) ChangeNotifierProvider(create: (_) => BookListNotifier(bookRepo)..load()),
      Provider<AuthorRepository>(create: (_) => FakeAuthorRepository()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('Отображается индикатор загрузки', (tester) async {
    final fakeRepo = FakeBookRepository(result: PageResult.empty(), delayMs: 1000);
    await tester.pumpWidget(buildTestApp(const BookListScreen(), bookRepo: fakeRepo));
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('Показывается сообщение при пустом результате', (tester) async {
    final fakeRepo = FakeBookRepository(result: PageResult(items: [], page: 1, size: 10, total: 0));
    await tester.pumpWidget(buildTestApp(const BookListScreen(), bookRepo: fakeRepo));
    await tester.pumpAndSettle();

    expect(find.text('Книг не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Показывается ошибка и кнопка Повторить', (tester) async {
    final fakeRepo = FakeBookRepository(result: PageResult.empty(), error: Exception('Network Error'));
    await tester.pumpWidget(buildTestApp(const BookListScreen(), bookRepo: fakeRepo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Network Error'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('Кнопка "Добавить" скрыта для читателя', (tester) async {
    final fakeRepo = FakeBookRepository(result: PageResult.empty());
    await tester.pumpWidget(buildTestApp(
      const BookListScreen(), 
      bookRepo: fakeRepo, 
      role: Role.reader,
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('Валидация формы не пропускает пустые поля', (tester) async {
    await tester.pumpWidget(buildTestApp(const AuthorFormScreen()));
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();
    expect(find.text('Обязательное поле'), findsWidgets);
  });
}