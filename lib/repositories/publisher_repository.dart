import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../models/page_result.dart';

abstract interface class PublisherRepository {
  Future<PageResult<Publisher>> find(PublisherQuery query);
  Future<Publisher?> findById(int id);
  Future<Publisher> create(Publisher publisher);
  Future<Publisher> update(Publisher publisher);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}