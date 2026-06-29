import 'package:flutter/foundation.dart';

import '../../data/mock_movies.dart';
import '../../domain/entities/movie.dart';

class MovieLibraryProvider extends ChangeNotifier {
  final List<Movie> _movies = List<Movie>.from(mockMovies);
  final Set<int> _watchlistIds = {};
  final Set<int> _watchedIds = {};
  String _query = '';

  List<Movie> get movies => List.unmodifiable(_movies);
  Set<int> get watchlistIds => Set.unmodifiable(_watchlistIds);
  Set<int> get watchedIds => Set.unmodifiable(_watchedIds);
  String get query => _query;

  List<Movie> get watchlist =>
      _movies.where((movie) => _watchlistIds.contains(movie.id)).toList();

  List<Movie> get watched =>
      _movies.where((movie) => _watchedIds.contains(movie.id)).toList();

  List<Movie> get searchResults {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) return _movies;
    return _movies
        .where(
          (movie) =>
              movie.title.toLowerCase().contains(normalized) ||
              movie.genres.any(
                (genre) => genre.toLowerCase().contains(normalized),
              ),
        )
        .toList();
  }

  Movie movieById(int id) => _movies.firstWhere((movie) => movie.id == id);

  bool isInWatchlist(int id) => _watchlistIds.contains(id);
  bool isWatched(int id) => _watchedIds.contains(id);

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void toggleWatchlist(int id) {
    if (!_watchlistIds.add(id)) {
      _watchlistIds.remove(id);
    }
    notifyListeners();
  }

  void toggleWatched(int id) {
    if (!_watchedIds.add(id)) {
      _watchedIds.remove(id);
    }
    notifyListeners();
  }
}
