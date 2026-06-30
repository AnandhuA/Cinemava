import 'package:flutter/foundation.dart';

import '../../data/repositories/jikan_anime_repository.dart';
import '../../domain/entities/anime.dart';
import '../../domain/entities/anime_details.dart';

class AnimeProvider extends ChangeNotifier {
  AnimeProvider(this._repository);

  final JikanAnimeRepository _repository;

  List<Anime> _topAnime = [];
  List<Anime> _searchResults = [];
  final Map<int, AnimeDetails> _detailsByAnimeId = {};
  final Map<int, Anime> _animeById = {};
  bool _isLoading = false;
  bool _isSearching = false;
  int? _loadingDetailsAnimeId;
  String _query = '';
  String? _errorMessage;
  String? _detailsErrorMessage;

  List<Anime> get topAnime => List.unmodifiable(_topAnime);
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
}
