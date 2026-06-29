import 'package:flutter/foundation.dart';

import '../../data/repositories/tmdb_movie_repository.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_details.dart';

class MovieLibraryProvider extends ChangeNotifier {
  MovieLibraryProvider(this._repository);

  final TmdbMovieRepository _repository;
  List<Movie> _trending = [];
  List<Movie> _popular = [];
  List<Movie> _topRated = [];
  List<Movie> _upcoming = [];
  List<Movie> _searchResults = [];
  final Map<int, MovieDetails> _detailsByMovieId = {};
  final Set<int> _watchlistIds = {};
  final Set<int> _watchedIds = {};
  String _query = '';
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  int? _loadingDetailsMovieId;
  String? _detailsErrorMessage;

  List<Movie> get movies => List.unmodifiable(_trending);
  List<Movie> get trending => List.unmodifiable(_trending);
  List<Movie> get popular => List.unmodifiable(_popular);
  List<Movie> get topRated => List.unmodifiable(_topRated);
  List<Movie> get upcoming => List.unmodifiable(_upcoming);
  Set<int> get watchlistIds => Set.unmodifiable(_watchlistIds);
  Set<int> get watchedIds => Set.unmodifiable(_watchedIds);
  String get query => _query;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  int? get loadingDetailsMovieId => _loadingDetailsMovieId;
  String? get detailsErrorMessage => _detailsErrorMessage;

  List<Movie> get _allMovies {
    final map = <int, Movie>{};
    for (final movie in [
      ..._trending,
      ..._popular,
      ..._topRated,
      ..._upcoming,
      ..._searchResults,
      ..._detailsByMovieId.values.expand((details) => details.recommendations),
    ]) {
      map[movie.id] = movie;
    }
    return map.values.toList();
  }

  List<Movie> get watchlist =>
      _allMovies.where((movie) => _watchlistIds.contains(movie.id)).toList();

  List<Movie> get watched =>
      _allMovies.where((movie) => _watchedIds.contains(movie.id)).toList();

  List<Movie> get searchResults {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) return _trending;
    return _searchResults;
  }

  List<Movie> recommendedMovies({
    required Set<String> genres,
    required Set<String> languages,
  }) {
    final source = _allMovies;
    if (genres.isEmpty && languages.isEmpty) return source;

    final scored =
        source.map((movie) {
          final genreScore = movie.genres
              .where((genre) => genres.contains(genre))
              .length;
          final languageScore = languages.contains(movie.language) ? 2 : 0;
          return _MovieScore(movie, genreScore + languageScore);
        }).toList()..sort((a, b) {
          final scoreCompare = b.score.compareTo(a.score);
          if (scoreCompare != 0) return scoreCompare;
          return b.movie.rating.compareTo(a.movie.rating);
        });

    return scored.map((item) => item.movie).toList();
  }

  Movie? movieById(int id) {
    for (final movie in _allMovies) {
      if (movie.id == id) return movie;
    }
    return null;
  }

  MovieDetails? detailsByMovieId(int id) => _detailsByMovieId[id];

  bool isInWatchlist(int id) => _watchlistIds.contains(id);
  bool isWatched(int id) => _watchedIds.contains(id);

  Future<void> loadInitialMovies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _trending = await _repository.trending();
      notifyListeners();
      _popular = await _repository.popular();
      notifyListeners();
      _topRated = await _repository.topRated();
      notifyListeners();
      _upcoming = await _repository.upcoming();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setQuery(String value) async {
    _query = value;
    final normalized = _query.trim();
    if (normalized.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _repository.search(normalized);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> loadMovieDetails(int id) async {
    if (_detailsByMovieId.containsKey(id) || _loadingDetailsMovieId == id) {
      return;
    }

    final movie = movieById(id);
    if (movie == null) return;

    _loadingDetailsMovieId = id;
    _detailsErrorMessage = null;
    notifyListeners();

    try {
      final details = await _repository.movieDetails(movie);
      _detailsByMovieId[id] = details;
    } catch (error) {
      _detailsErrorMessage = error.toString();
    } finally {
      _loadingDetailsMovieId = null;
      notifyListeners();
    }
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

class _MovieScore {
  const _MovieScore(this.movie, this.score);

  final Movie movie;
  final int score;
}
