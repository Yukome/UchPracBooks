import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import '../lib/core/api_client.dart';
import '../lib/core/api_exceptions.dart';
import '../lib/models/book.dart';
import '../lib/models/book_query.dart';
import '../lib/repositories/api_book_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late ApiBookRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080/api',
      validateStatus: (status) => status != null && status < 500,
    ));
    addInterceptors(dio); 
    dioAdapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = dioAdapter;
    repository = ApiBookRepository(dio);
  });

  test('find() возвращает PageResult при 200 OK', () async {
    final responseJson = {
      'items': [
        {
          'id': 1,
          'title': 'Война и мир',
          'isbn': '978-5-17-118366-4',
          'year': 1869,
          'pages': 1300,
          'publisherId': 1,
          'authorIds': [1],
          'genreIds': [1, 3],
          'copiesTotal': 4,
          'copiesAvailable': 4,
        }
      ],
      'page': 1,
      'size': 10,
      'total': 1,
    };

    dioAdapter.onGet(
      '/books',
      (server) => server.reply(200, responseJson),
      queryParameters: {
        'sort': 'title,asc',
        'page': 1,
        'size': 10,
      },
    );

    final result = await repository.find(const BookQuery());

    expect(result.items.length, 1);
    expect(result.items.first.title, 'Война и мир');
    expect(result.total, 1);
  });

  test('create() выбрасывает ValidationException при 422', () async {
    final errorJson = {
      'message': 'Ошибка валидации',
      'errors': {
        'isbn': 'Книга с таким ISBN уже существует',
      },
    };

    dioAdapter.onPost(
      '/books',
      (server) => server.reply(422, errorJson),
      data: Matchers.any, 
    );

    final book = Book(
      id: 0, title: 'Тест', isbn: '123', year: 2000, pages: 100,
      publisherId: 1, authorIds: [], genreIds: [], copiesTotal: 1, copiesAvailable: 1,
    );

    expect(
      () => repository.create(book),
      throwsA(isA<ValidationException>().having(
        (e) => e.errors['isbn'], 
        'сообщение об ошибке', 
        'Книга с таким ISBN уже существует'
      )),
    );
  });

  test('find() выбрасывает NetworkException при отсутствии соединения', () async {
    dioAdapter.onGet(
      '/books',
      (server) => server.throws(
        0, 
        DioException(
          requestOptions: RequestOptions(path: '/books'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );

    expect(
      () => repository.find(const BookQuery()),
      throwsA(isA<NetworkException>()),
    );
  });

  test('create() выбрасывает ConflictException при 409', () async {
    dioAdapter.onPost(
      '/books',
      (server) => server.reply(409, {'message': 'Книга выдана и не может быть удалена'}),
      data: Matchers.any,
    );

    final book = Book(
      id: 0, title: 'Тест', isbn: '123', year: 2000, pages: 100,
      publisherId: 1, authorIds: [], genreIds: [], copiesTotal: 1, copiesAvailable: 1,
    );

    expect(
      () => repository.create(book),
      throwsA(isA<ConflictException>()),
    );
  });

  test('findById() выбрасывает NotFoundException при 404', () async {
    dioAdapter.onGet(
      '/books/99',
      (server) => server.reply(404, {'message': 'Объект не найден'}),
    );

    expect(
      () => repository.findById(99),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('find() выбрасывает ServerException при 500', () async {
    dioAdapter.onGet(
      '/books',
      (server) => server.reply(500, {'message': 'Внутренняя ошибка'}),
    );

    expect(
      () => repository.find(const BookQuery()),
      throwsA(isA<ServerException>()),
    );
  });
}