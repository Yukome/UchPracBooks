import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_uchprac2/core/validators.dart';
import 'package:flutter_uchprac2/models/book.dart';

void main() {
  group('Валидаторы (Validators)', () {
    test('Проверка обязательного поля', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required('Текст'), isNull);
    });

    test('Проверка длины строки', () {
      expect(Validators.length('a', 2, 10), isNotNull);
      expect(Validators.length('abcdefghijk', 2, 10), isNotNull);
      expect(Validators.length('Норма', 2, 10), isNull);
    });

    test('Проверка ISBN', () {
      expect(Validators.isbn('123'), isNotNull);
      expect(Validators.isbn('978-5-17-118366-4'), isNull);
    });

    test('Проверка пароля', () {
      expect(Validators.password('123'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('Passw0rd!'), isNull);
    });
  });

  group('Разбор моделей', () {
    test('Book.fromJson корректно разбирает данные', () {
      final json = {
        'id': 1,
        'title': 'Книга',
        'isbn': '1234567890',
        'year': 2000,
        'pages': 100,
        'publisherId': 5,
        'authorIds': [1, 2],
        'genreIds': [3],
        'copiesTotal': 10,
        'copiesAvailable': 5,
      };
      final book = Book.fromJson(json);
      expect(book.id, 1);
      expect(book.title, 'Книга');
      expect(book.authorIds, [1, 2]);
    });

    test('Book.fromJson не падает при отсутствии полей', () {
      final json = {'id': 2};
      final book = Book.fromJson(json);
      expect(book.title, '');
      expect(book.copiesTotal, 0);
      expect(book.authorIds, isEmpty);
    });
  });
}