import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

class ApiAuthorRepository implements AuthorRepository {
  final Dio _dio;
  ApiAuthorRepository(this._dio);

  @override
  Future<PageResult<Author>> find(AuthorQuery q, {CancelToken? cancelToken}) => guard(() async {
        final response = await _dio.get('/authors', queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.yearFrom != null) 'yearFrom': q.yearFrom,
          if (q.yearTo != null) 'yearTo': q.yearTo,
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
          if (q.includeDeleted) 'includeDeleted': true,
        }, cancelToken: cancelToken);

        final data = response.data as Map<String, dynamic>;
        return PageResult(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Author.fromJson)
              .toList(),
          page: data['page'] as int? ?? 1,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      });

  @override
  Future<Author?> findById(int id) => guard(() async {
        final response = await _dio.get('/authors/$id');
        return Author.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Author> create(Author author) => guard(() async {
        final response = await _dio.post('/authors', data: {
          'fullName': author.fullName,
          'birthYear': author.birthYear,
          'country': author.country,
        });
        return Author.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Author> update(Author author) => guard(() async {
        final response = await _dio.put('/authors/${author.id}', data: {
          'fullName': author.fullName,
          'birthYear': author.birthYear,
          'country': author.country,
        });
        return Author.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/authors/$id'));

  @override
  Future<void> hardDelete(int id) => guard(() => _dio.delete('/authors/$id', queryParameters: {'hard': true}));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post('/authors/bulk-delete', data: {'ids': ids});
        return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/authors/$id/restore'));
}