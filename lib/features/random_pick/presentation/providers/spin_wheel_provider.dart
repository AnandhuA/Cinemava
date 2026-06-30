import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../movies/domain/entities/movie.dart';

class SpinWheelProvider extends ChangeNotifier {
  static const minMovies = 2;
  static const maxMovies = 5;
  static const _moviesKey = 'movies';

  SpinWheelProvider(this._box) {
    _movies.addAll(_readSavedMovies());
  }

  final Box<dynamic>? _box;
  final List<Movie> _movies = [];
  final _random = math.Random();

  List<Movie> get movies => List.unmodifiable(_movies);
  bool get canSpin => _movies.length >= minMovies;
  bool get isFull => _movies.length >= maxMovies;

  bool contains(int movieId) {
    return _movies.any((movie) => movie.id == movieId);
  }

  bool addMovie(Movie movie) {
    if (!movie.isReleased) return false;
    if (isFull || contains(movie.id)) return false;
    _movies.add(movie);
    _save();
    notifyListeners();
    return true;
  }

  bool addPriorityMovie(Movie movie) {
    if (!movie.isReleased) return false;
    if (contains(movie.id)) return false;
    if (isFull) _movies.removeAt(0);
    _movies.add(movie);
    _save();
    notifyListeners();
    return true;
  }

  void removeMovie(int movieId) {
    _movies.removeWhere((movie) => movie.id == movieId);
    _save();
    notifyListeners();
  }

  void seed(List<Movie> movies) {
    if (_movies.isNotEmpty) return;
    for (final movie in movies) {
      if (_movies.length == 3) break;
      if (movie.isReleased && !contains(movie.id)) _movies.add(movie);
    }
    _save();
    if (_movies.isNotEmpty) notifyListeners();
  }

  List<Movie> refreshRandomMovies(List<Movie> source) {
    final pool = _uniqueMovies(source.where((movie) => movie.isReleased));
    pool.shuffle(_random);

    _movies
      ..clear()
      ..addAll(pool.take(maxMovies));
    _save();
    notifyListeners();
    return movies;
  }

  List<Movie> _uniqueMovies(Iterable<Movie> source) {
    final byId = <int, Movie>{};
    for (final movie in source) {
      byId[movie.id] = movie;
    }
    return byId.values.toList();
  }

  List<Movie> _readSavedMovies() {
    final saved = _box?.get(_moviesKey);
    if (saved is! List) return const [];

    return saved
        .whereType<Map>()
        .map(_movieFromMap)
        .where((movie) => movie.isReleased)
        .take(maxMovies)
        .toList();
  }

  Movie _movieFromMap(Map<dynamic, dynamic> map) {
    return Movie(
      id: map['id'] as int? ?? 0,
      title: map['title'] as String? ?? 'Untitled',
      year: map['year'] as int? ?? DateTime.now().year,
      runtime: map['runtime'] as String? ?? '-',
      genres: ((map['genres'] as List?) ?? const []).cast<String>(),
      language: map['language'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      overview: map['overview'] as String? ?? '',
      posterUrl: map['posterUrl'] as String? ?? '',
      backdropUrl: map['backdropUrl'] as String? ?? '',
      cast: ((map['cast'] as List?) ?? const []).cast<String>(),
      isReleased: map['isReleased'] as bool? ?? true,
    );
  }

  Future<void> _save() async {
    await _box?.put(
      _moviesKey,
      _movies.map((movie) {
        return {
          'id': movie.id,
          'title': movie.title,
          'year': movie.year,
          'runtime': movie.runtime,
          'genres': movie.genres,
          'language': movie.language,
          'rating': movie.rating,
          'overview': movie.overview,
          'posterUrl': movie.posterUrl,
          'backdropUrl': movie.backdropUrl,
          'cast': movie.cast,
          'isReleased': movie.isReleased,
        };
      }).toList(),
    );
  }
}
