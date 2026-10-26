import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../models/page_result.dart';
import 'publisher_repository.dart';

class ApiPublisherRepository implements PublisherRepository {
  final Dio _dio;
  ApiPublisherRepository(this._dio);

  @override
  Future<PageResult<Publisher>> find(PublisherQuery q, {CancelToken? cancelToken}) => guard(() async {
        final response = await _dio.get('/publishers', queryParameters: {
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
              .map(Publisher.fromJson)
              .toList(),
          page: data['page'] as int? ?? 1,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      });

  @override
  Future<Publisher?> findById(int id) => guard(() async {
        final response = await _dio.get('/publishers/$id');
        return Publisher.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Publisher> create(Publisher publisher) => guard(() async {
        final response = await _dio.post('/publishers', data: {
          'name': publisher.name,
          'city': publisher.city,
          'foundedYear': publisher.foundedYear,
        });
        return Publisher.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Publisher> update(Publisher publisher) => guard(() async {
        final response = await _dio.put('/publishers/${publisher.id}', data: {
          'name': publisher.name,
          'city': publisher.city,
          'foundedYear': publisher.foundedYear,
        });
        return Publisher.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/publishers/$id'));

  @override
  Future<void> hardDelete(int id) => guard(() => _dio.delete('/publishers/$id', queryParameters: {'hard': true}));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post('/publishers/bulk-delete', data: {'ids': ids});
        return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/publishers/$id/restore'));
}