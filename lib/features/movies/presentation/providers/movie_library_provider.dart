import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../data/repositories/tmdb_movie_repository.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_details.dart';
import '../../domain/entities/person_profile.dart';

class MovieLibraryProvider extends ChangeNotifier {
  static const _watchlistKey = 'watchlistIds';
  static const _watchedKey = 'watchedIds';
  static const _savedMoviesKey = 'savedMovies';

  MovieLibraryProvider(this._repository, [this._box]) {
    _registeredMovies.addAll(_readSavedMovies());
    _watchlistIds.addAll(_readIdSet(_watchlistKey));
    _watchedIds.addAll(_readIdSet(_watchedKey));
  }

  final TmdbMovieRepository _repository;
  final Box<dynamic>? _box;
  List<Movie> _trending = [];
  List<Movie> _popular = [];
  List<Movie> _topRated = [];
  List<Movie> _upcoming = [];
  List<Movie> _searchResults = [];
  final Map<int, Movie> _registeredMovies = {};
  final Map<String, List<Movie>> _marathonMovies = {};
  final Set<String> _loadingMarathons = {};
  final Map<String, String> _marathonErrors = {};
  final Map<int, List<Movie>> _personMovies = {};
  final Map<int, PersonProfile> _personProfiles = {};
  final Set<int> _loadingPeople = {};
  final Map<int, String> _personErrors = {};
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

  List<Movie> get movies =>
      List.unmodifiable(_trending.isNotEmpty ? _trending : _allMovies);
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
  Map<String, List<Movie>> get marathonMovies => Map.unmodifiable(
    _marathonMovies.map(
      (id, movies) => MapEntry(id, List.unmodifiable(movies)),
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
      ..._registeredMovies.values,
      ..._marathonMovies.values.expand((movies) => movies),
      ..._personMovies.values.expand((movies) => movies),
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

  Future<Movie> ensureMovie(Movie fallback) async {
    final existing = movieById(fallback.id);
    if (existing != null && existing.posterUrl.isNotEmpty) return existing;

    try {
      final movie = await _repository.movie(fallback.id);
      if (movie.id != 0) {
        _registeredMovies[movie.id] = movie;
        notifyListeners();
        return movie;
      }
    } catch (_) {
      // Keep navigation working with the marathon metadata when TMDb is offline.
    }

    _registeredMovies[fallback.id] = fallback;
    notifyListeners();
    return fallback;
  }

  MovieDetails? detailsByMovieId(int id) => _detailsByMovieId[id];

  bool isInWatchlist(int id) => _watchlistIds.contains(id);
  bool isWatched(int id) => _watchedIds.contains(id);

  List<Movie> moviesForMarathon(String id) {
    return List.unmodifiable(_marathonMovies[id] ?? const []);
  }

  bool isLoadingMarathon(String id) => _loadingMarathons.contains(id);

  String? marathonError(String id) => _marathonErrors[id];

  Future<void> loadMarathonMovies({
    required String id,
    required List<String> collectionQueries,
    bool force = false,
  }) async {
    if (!force &&
        (_marathonMovies.containsKey(id) || _loadingMarathons.contains(id))) {
      return;
    }

    _loadingMarathons.add(id);
    _marathonErrors.remove(id);
    notifyListeners();

    try {
      final movies = await _repository.collectionMovies(collectionQueries);
      _marathonMovies[id] = movies;
    } catch (error) {
      _marathonErrors[id] = error is TmdbNetworkException
          ? error.message
          : 'Could not load this marathon from TMDb.';
    } finally {
      _loadingMarathons.remove(id);
      notifyListeners();
    }
  }

  List<Movie> moviesForPerson(int personId) {
    return List.unmodifiable(_personMovies[personId] ?? const []);
  }

  bool isLoadingPerson(int personId) => _loadingPeople.contains(personId);

  String? personError(int personId) => _personErrors[personId];

  PersonProfile? personProfile(int personId) => _personProfiles[personId];

  Future<void> loadPersonMovies(int personId, {bool force = false}) async {
    if (personId == 0) return;
    if (!force &&
        (_personMovies.containsKey(personId) ||
            _loadingPeople.contains(personId))) {
      return;
    }

    _loadingPeople.add(personId);
    _personErrors.remove(personId);
    notifyListeners();

    try {
      try {
        final profile = await _repository.personProfile(personId);
        if (profile.id != 0) _personProfiles[personId] = profile;
      } catch (_) {
        // Movie credits are still useful when TMDb profile details are missing.
      }

      final movies = await _repository.personMovies(personId);
      _personMovies[personId] = movies;
    } catch (error) {
      _personErrors[personId] = error is TmdbNetworkException
          ? error.message
          : 'Could not load actor movies from TMDb.';
    } finally {
      _loadingPeople.remove(personId);
      notifyListeners();
    }
  }

  Future<void> loadInitialMovies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    Object? latestError;
    latestError = await _loadSection(() => _repository.trending(), (movies) {
      _trending = movies;
    });
    latestError = await _loadSection(() => _repository.popular(), (movies) {
      _popular = movies;
    }, fallbackError: latestError);
    latestError = await _loadSection(() => _repository.topRated(), (movies) {
      _topRated = movies;
    }, fallbackError: latestError);
    latestError = await _loadSection(() => _repository.upcoming(), (movies) {
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
    _saveLibraryState();
    notifyListeners();
  }

  void toggleWatched(int id) {
    if (!_watchedIds.add(id)) {
      _watchedIds.remove(id);
    }
    _saveLibraryState();
    notifyListeners();
  }

  void markWatched(int id) {
    if (_watchedIds.add(id)) {
      _saveLibraryState();
      notifyListeners();
    }
  }

  Set<int> _readIdSet(String key) {
    final saved = _box?.get(key);
    if (saved is! List) return {};

    return saved
        .map((value) {
          if (value is int) return value;
          return int.tryParse(value.toString());
        })
        .whereType<int>()
        .toSet();
  }

  Future<void> _saveLibraryState() async {
    await _box?.put(_watchlistKey, _watchlistIds.toList()..sort());
    await _box?.put(_watchedKey, _watchedIds.toList()..sort());
    await _box?.put(
      _savedMoviesKey,
      _savedMovieSnapshots().map(_movieToMap).toList(),
    );
  }

  List<Movie> _savedMovieSnapshots() {
    final ids = {..._watchlistIds, ..._watchedIds};
    final movies = <Movie>[];
    for (final id in ids) {
      final movie = movieById(id);
      if (movie != null) movies.add(movie);
    }
    return movies;
  }

  Map<int, Movie> _readSavedMovies() {
    final saved = _box?.get(_savedMoviesKey);
    if (saved is! List) return {};

    final movies = <int, Movie>{};
    for (final map in saved.whereType<Map>()) {
      final movie = _movieFromMap(map);
      if (movie.id != 0) movies[movie.id] = movie;
    }
    return movies;
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

  Map<String, dynamic> _movieToMap(Movie movie) {
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
