import 'package:flutter/foundation.dart';
import '../models/author.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../models/author_query.dart';
import '../models/genre_query.dart';
import '../models/publisher_query.dart';
import '../repositories/author_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';

class ReferenceDataNotifier extends ChangeNotifier {
  final AuthorRepository _authorRepository;
  final GenreRepository _genreRepository;
  final PublisherRepository _publisherRepository;

  ReferenceDataNotifier(
    this._authorRepository,
    this._genreRepository,
    this._publisherRepository,
  );

  bool _isLoaded = false;
  bool _isLoading = false;
  String? _error;

  List<Author> authors = [];
  List<Genre> genres = [];
  List<Publisher> publishers = [];

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> ensureLoaded() async {
    if (_isLoaded || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _authorRepository.find(const AuthorQuery(size: 1000)),
        _genreRepository.find(const GenreQuery(size: 1000)),
        _publisherRepository.find(const PublisherQuery(size: 1000)),
      ]);

      authors = (results[0] as dynamic).items;
      genres = (results[1] as dynamic).items;
      publishers = (results[2] as dynamic).items;

      _isLoaded = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}