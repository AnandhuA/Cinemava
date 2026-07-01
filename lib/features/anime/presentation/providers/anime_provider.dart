import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../data/repositories/jikan_anime_repository.dart';
import '../../domain/entities/anime.dart';
import '../../domain/entities/anime_details.dart';

class AnimeProvider extends ChangeNotifier {
  static const _wishlistKey = 'wishlistIds';
  static const _watchedKey = 'watchedIds';
  static const _savedAnimeKey = 'savedAnime';

  AnimeProvider(this._repository, [this._box]) {
    _animeById.addAll(_readSavedAnime());
    _wishlistIds.addAll(_readIdSet(_wishlistKey));
    _watchedIds.addAll(_readIdSet(_watchedKey));
  }

  final JikanAnimeRepository _repository;
  final Box<dynamic>? _box;

  List<Anime> _topAnime = [];
  List<Anime> _searchResults = [];
  final Map<int, AnimeDetails> _detailsByAnimeId = {};
  final Map<int, Anime> _animeById = {};
  final Set<int> _wishlistIds = {};
  final Set<int> _watchedIds = {};
  bool _isLoading = false;
  bool _isSearching = false;
  int? _loadingDetailsAnimeId;
  String _query = '';
  String? _errorMessage;
  String? _detailsErrorMessage;

  List<Anime> get topAnime => List.unmodifiable(_topAnime);
  List<Anime> get wishlist => _animeById.values
      .where((anime) => _wishlistIds.contains(anime.id))
      .toList();
  List<Anime> get watched => _animeById.values
      .where((anime) => _watchedIds.contains(anime.id))
      .toList();
  Set<int> get wishlistIds => Set.unmodifiable(_wishlistIds);
  Set<int> get watchedIds => Set.unmodifiable(_watchedIds);
  List<Anime> get anime => _query.trim().isEmpty
      ? List.unmodifiable(_topAnime)
      : List.unmodifiable(_searchResults);
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  int? get loadingDetailsAnimeId => _loadingDetailsAnimeId;
  String get query => _query;
  String? get errorMessage => _errorMessage;
  String? get detailsErrorMessage => _detailsErrorMessage;

  Anime? animeById(int id) => _animeById[id];
  AnimeDetails? detailsByAnimeId(int id) => _detailsByAnimeId[id];
  bool isInWishlist(int id) => _wishlistIds.contains(id);
  bool isWatched(int id) => _watchedIds.contains(id);

  Future<void> loadTopAnime() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _topAnime = await _repository.topAnime();
      _registerAnime(_topAnime);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setQuery(String value) async {
    _query = value;
    final normalized = value.trim();
    if (normalized.isEmpty) {
      _searchResults = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _repository.searchAnime(normalized);
      _registerAnime(_searchResults);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> loadAnimeDetails(Anime anime) async {
    _animeById[anime.id] = anime;
    if (_detailsByAnimeId.containsKey(anime.id) ||
        _loadingDetailsAnimeId == anime.id) {
      return;
    }

    _loadingDetailsAnimeId = anime.id;
    _detailsErrorMessage = null;
    notifyListeners();

    try {
      final details = await _repository.animeDetails(anime);
      _detailsByAnimeId[anime.id] = details;
      _animeById[details.anime.id] = details.anime;
      _registerAnime(details.recommendations);
    } catch (error) {
      _detailsErrorMessage = error.toString();
    } finally {
      _loadingDetailsAnimeId = null;
      notifyListeners();
    }
  }

  void _registerAnime(List<Anime> anime) {
    for (final item in anime) {
      _animeById[item.id] = item;
    }
  }

  void toggleWishlist(Anime anime) {
    _animeById[anime.id] = anime;
    if (!_wishlistIds.add(anime.id)) {
      _wishlistIds.remove(anime.id);
    }
    _saveLibraryState();
    notifyListeners();
  }

  void toggleWatched(Anime anime) {
    _animeById[anime.id] = anime;
    if (!_watchedIds.add(anime.id)) {
      _watchedIds.remove(anime.id);
    }
    _saveLibraryState();
    notifyListeners();
  }

  void markWatched(Anime anime) {
    _animeById[anime.id] = anime;
    if (_watchedIds.add(anime.id)) {
      _saveLibraryState();
      notifyListeners();
    }
  }

  Set<int> _readIdSet(String key) {
    final saved = _box?.get(key);
    if (saved is! List) return {};
    return saved
        .map((value) => value is int ? value : int.tryParse(value.toString()))
        .whereType<int>()
        .toSet();
  }

  Map<int, Anime> _readSavedAnime() {
    final saved = _box?.get(_savedAnimeKey);
    if (saved is! List) return {};

    final animeById = <int, Anime>{};
    for (final map in saved.whereType<Map>()) {
      final anime = _animeFromMap(map);
      if (anime.id != 0) animeById[anime.id] = anime;
    }
    return animeById;
  }

  Future<void> _saveLibraryState() async {
    await _box?.put(_wishlistKey, _wishlistIds.toList()..sort());
    await _box?.put(_watchedKey, _watchedIds.toList()..sort());
    await _box?.put(
      _savedAnimeKey,
      _savedAnimeSnapshots().map(_animeToMap).toList(),
    );
  }

  List<Anime> _savedAnimeSnapshots() {
    final ids = {..._wishlistIds, ..._watchedIds};
    return ids.map((id) => _animeById[id]).whereType<Anime>().toList();
  }

  Anime _animeFromMap(Map<dynamic, dynamic> map) {
    return Anime(
      id: map['id'] as int? ?? 0,
      title: map['title'] as String? ?? 'Untitled',
      imageUrl: map['imageUrl'] as String? ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0,
      year: map['year'] as int?,
      type: map['type'] as String? ?? '',
      episodes: map['episodes'] as int?,
      synopsis: map['synopsis'] as String? ?? '',
      genres: ((map['genres'] as List?) ?? const []).cast<String>(),
    );
  }

  Map<String, dynamic> _animeToMap(Anime anime) {
    return {
      'id': anime.id,
      'title': anime.title,
      'imageUrl': anime.imageUrl,
      'score': anime.score,
      'year': anime.year,
      'type': anime.type,
      'episodes': anime.episodes,
      'synopsis': anime.synopsis,
      'genres': anime.genres,
    };
  }
}
