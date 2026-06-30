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
  final Map<String, List<Movie>> _moviesByLanguage = {};
  final Map<int, MovieDetails> _detailsByMovieId = {};
  final Set<int> _watchlistIds = {};
  final Set<int> _watchedIds = {};
  final Set<String> _loadingLanguages = {};
  String _query = '';
  int _searchRequestId = 0;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  String? _searchErrorMessage;
  int? _loadingDetailsMovieId;
  String? _detailsErrorMessage;

  List<Movie> get movies => List.unmodifiable(_trending);
  List<Movie> get trending => List.unmodifiable(_trending);
  List<Movie> get popular => List.unmodifiable(_popular);
  List<Movie> get topRated => List.unmodifiable(_topRated);
  List<Movie> get upcoming => List.unmodifiable(_upcoming);
  List<Movie> get availableMovies => List.unmodifiable(_allMovies);
  Map<String, List<Movie>> get moviesByLanguage => Map.unmodifiable(
    _moviesByLanguage.map(
      (language, movies) => MapEntry(language, List.unmodifiable(movies)),
    ),
  );
  Set<int> get watchlistIds => Set.unmodifiable(_watchlistIds);
  Set<int> get watchedIds => Set.unmodifiable(_watchedIds);
  String get query => _query;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  String? get searchErrorMessage => _searchErrorMessage;
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
      ..._moviesByLanguage.values.expand((movies) => movies),
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

    final matches = source.where((movie) {
      final genreMatch = genres.isEmpty || movie.genres.any(genres.contains);
      final languageMatch =
          languages.isEmpty || languages.contains(movie.language);
      return genreMatch && languageMatch;
    }).toList();

    final scored =
        (matches.isEmpty ? source : matches).map((movie) {
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

    Object? latestError;
    latestError = await _loadSection(() => _repository.trending(), (movies) {
      _trending = movies;
    });
    latestError = await _loadSection(() => _repository.cachedPopular(), (
      movies,
    ) {
      _popular = movies;
    }, fallbackError: latestError);
    latestError = await _loadSection(() => _repository.cachedTopRated(), (
      movies,
    ) {
      _topRated = movies;
    }, fallbackError: latestError);
    latestError = await _loadSection(() => _repository.cachedUpcoming(), (
      movies,
    ) {
      _upcoming = movies;
    }, fallbackError: latestError);

    if (_allMovies.isEmpty && latestError != null) {
      _errorMessage = latestError.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setQuery(String value) async {
    _query = value;
    _searchErrorMessage = null;
    final normalized = _query.trim();
    if (normalized.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    final requestId = ++_searchRequestId;
    _isSearching = true;
    notifyListeners();

    try {
      final results = await _repository.search(normalized);
      if (requestId != _searchRequestId) return;
      _searchResults = results;
    } catch (error) {
      if (requestId != _searchRequestId) return;
      final localResults = _localSearch(normalized);
      _searchResults = localResults;
      if (localResults.isEmpty) {
        _searchErrorMessage = error.toString();
      }
    }

    if (requestId != _searchRequestId) return;
    _isSearching = false;
    notifyListeners();
  }

  Future<void> loadLanguageMovies(Iterable<String> languages) async {
    for (final language in languages) {
      if (_moviesByLanguage.containsKey(language) ||
          _loadingLanguages.contains(language)) {
        continue;
      }

      _loadingLanguages.add(language);
      notifyListeners();

      try {
        _moviesByLanguage[language] = await _repository.moviesByLanguage(
          language,
        );
      } catch (_) {
        _moviesByLanguage[language] = _allMovies
            .where((movie) => movie.language == language)
            .toList();
      } finally {
        _loadingLanguages.remove(language);
        notifyListeners();
      }
    }
  }

  List<Movie> moviesForLanguage(String language) {
    return List.unmodifiable(_moviesByLanguage[language] ?? const []);
  }

  bool isLoadingLanguage(String language) =>
      _loadingLanguages.contains(language);

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
      _detailsErrorMessage = error is TmdbNetworkException
          ? error.message
          : 'Extra movie details are temporarily unavailable.';
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

  Future<Object?> _loadSection(
    Future<List<Movie>> Function() load,
    void Function(List<Movie>) save, {
    Object? fallbackError,
  }) async {
    try {
      save(await load());
      notifyListeners();
      return null;
    } catch (error) {
      return fallbackError ?? error;
    }
  }

  List<Movie> _localSearch(String query) {
    final normalized = query.toLowerCase();
    return _allMovies.where((movie) {
      final titleMatch = movie.title.toLowerCase().contains(normalized);
      final languageMatch = movie.language.toLowerCase().contains(normalized);
      final genreMatch = movie.genres.any(
        (genre) => genre.toLowerCase().contains(normalized),
      );
      return titleMatch || languageMatch || genreMatch;
    }).toList();
  }
}

class _MovieScore {
  const _MovieScore(this.movie, this.score);

  final Movie movie;
  final int score;
}
