import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import 'genre_repository.dart';

class ApiGenreRepository implements GenreRepository {
  final Dio _dio;
  ApiGenreRepository(this._dio);

  @override
  Future<PageResult<Genre>> find(GenreQuery q, {CancelToken? cancelToken}) => guard(() async {
        final response = await _dio.get('/genres', queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
          if (q.includeDeleted) 'includeDeleted': true,
        }, cancelToken: cancelToken);

        final data = response.data as Map<String, dynamic>;
        return PageResult(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Genre.fromJson)
              .toList(),
          page: data['page'] as int? ?? 1,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      });

  @override
  Future<Genre?> findById(int id) => guard(() async {
        final response = await _dio.get('/genres/$id');
        return Genre.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Genre> create(Genre genre) => guard(() async {
        final response = await _dio.post('/genres', data: {
          'name': genre.name,
          'description': genre.description,
        });
        return Genre.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Genre> update(Genre genre) => guard(() async {
        final response = await _dio.put('/genres/${genre.id}', data: {
          'name': genre.name,
          'description': genre.description,
        });
        return Genre.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/genres/$id'));

  @override
  Future<void> hardDelete(int id) => guard(() => _dio.delete('/genres/$id', queryParameters: {'hard': true}));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post('/genres/bulk-delete', data: {'ids': ids});
        return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/genres/$id/restore'));
}