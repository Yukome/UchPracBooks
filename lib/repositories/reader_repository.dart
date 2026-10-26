import 'package:dio/dio.dart' show CancelToken;
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../models/page_result.dart';

abstract interface class ReaderRepository {
  Future<PageResult<Reader>> find(ReaderQuery query, {CancelToken? cancelToken});
  Future<Reader?> findById(int id);
  Future<Reader> create(Reader reader);
  Future<Reader> update(Reader reader);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}