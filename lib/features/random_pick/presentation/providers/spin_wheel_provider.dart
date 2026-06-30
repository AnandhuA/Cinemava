import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../movies/domain/entities/movie.dart';

class SpinWheelProvider extends ChangeNotifier {
  static const minMovies = 2;
  static const maxMovies = 5;

  final List<Movie> _movies = [];
  final _random = math.Random();

  List<Movie> get movies => List.unmodifiable(_movies);
  bool get canSpin => _movies.length >= minMovies;
  bool get isFull => _movies.length >= maxMovies;

  bool contains(int movieId) {
    return _movies.any((movie) => movie.id == movieId);
  }

  bool addMovie(Movie movie) {
    if (isFull || contains(movie.id)) return false;
    _movies.add(movie);
    notifyListeners();
    return true;
  }

  bool addPriorityMovie(Movie movie) {
    if (contains(movie.id)) return false;
    if (isFull) _movies.removeAt(0);
    _movies.add(movie);
    notifyListeners();
    return true;
  }

  void removeMovie(int movieId) {
    _movies.removeWhere((movie) => movie.id == movieId);
    notifyListeners();
  }

  void seed(List<Movie> movies) {
    if (_movies.isNotEmpty) return;
    for (final movie in movies) {
      if (_movies.length == minMovies) break;
      if (!contains(movie.id)) _movies.add(movie);
    }
    if (_movies.isNotEmpty) notifyListeners();
  }

  List<Movie> refreshRandomMovies(List<Movie> source) {
    final pool = _uniqueMovies(source);
    pool.shuffle(_random);

    _movies
      ..clear()
      ..addAll(pool.take(maxMovies));
    notifyListeners();
    return movies;
  }

  List<Movie> _uniqueMovies(List<Movie> source) {
    final byId = <int, Movie>{};
    for (final movie in source) {
      byId[movie.id] = movie;
    }
    return byId.values.toList();
  }
}
