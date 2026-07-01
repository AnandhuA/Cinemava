import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../data/marathon_data.dart';
import '../../../movies/domain/entities/movie.dart';

class MarathonProvider extends ChangeNotifier {
  static const _marathonsKey = 'marathons';

  MarathonProvider(this._box) {
    _customMarathons.addAll(_readSavedMarathons());
  }

  final Box<dynamic>? _box;
  final List<MarathonCollection> _customMarathons = [];

  List<MarathonCollection> get customMarathons =>
      List.unmodifiable(_customMarathons);

  List<MarathonCollection> get allMarathons =>
      List.unmodifiable([..._customMarathons, ...marathonCollections]);

  MarathonCollection? marathonById(String id) {
    for (final marathon in allMarathons) {
      if (marathon.id == id) return marathon;
    }
    return null;
  }

  void addMarathon({
    required String title,
    required String subtitle,
    required String description,
    required int accentColor,
    required List<String> collectionQueries,
    List<Movie> manualMovies = const [],
  }) {
    final normalizedQueries = collectionQueries
        .map((query) => query.trim())
        .where((query) => query.isNotEmpty)
        .toSet()
        .toList();
    final normalizedMovies = _uniqueMovies(manualMovies);
    if (title.trim().isEmpty ||
        (normalizedQueries.isEmpty && normalizedMovies.isEmpty)) {
      return;
    }

    _customMarathons.insert(
      0,
      MarathonCollection(
        id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
        title: title.trim(),
        subtitle: subtitle.trim().isEmpty ? 'Custom LineUp' : subtitle.trim(),
        description: description.trim().isEmpty
            ? 'A custom watch order from TMDb collections and selected movies.'
            : description.trim(),
        accentColor: accentColor,
        collectionQueries: normalizedQueries,
        manualMovies: normalizedMovies,
        isUserCreated: true,
      ),
    );
    _save();
    notifyListeners();
  }

  void updateMarathon({
    required String id,
    required String title,
    required String subtitle,
    required String description,
    required int accentColor,
    required List<String> collectionQueries,
    List<Movie> manualMovies = const [],
  }) {
    final index = _customMarathons.indexWhere((marathon) => marathon.id == id);
    if (index == -1) return;

    final normalizedQueries = collectionQueries
        .map((query) => query.trim())
        .where((query) => query.isNotEmpty)
        .toSet()
        .toList();
    final normalizedMovies = _uniqueMovies(manualMovies);
    if (title.trim().isEmpty ||
        (normalizedQueries.isEmpty && normalizedMovies.isEmpty)) {
      return;
    }

    _customMarathons[index] = MarathonCollection(
      id: id,
      title: title.trim(),
      subtitle: subtitle.trim().isEmpty ? 'Custom LineUp' : subtitle.trim(),
      description: description.trim().isEmpty
          ? 'A custom watch order from TMDb collections and selected movies.'
          : description.trim(),
      accentColor: accentColor,
      collectionQueries: normalizedQueries,
      manualMovies: normalizedMovies,
      isUserCreated: true,
    );
    _save();
    notifyListeners();
  }

  void deleteMarathon(String id) {
    _customMarathons.removeWhere((marathon) => marathon.id == id);
    _save();
    notifyListeners();
  }

  List<MarathonCollection> _readSavedMarathons() {
    final saved = _box?.get(_marathonsKey);
    if (saved is! List) return const [];

    return saved
        .whereType<Map>()
        .map(_marathonFromMap)
        .where(
          (marathon) =>
              marathon.collectionQueries.isNotEmpty ||
              marathon.manualMovies.isNotEmpty,
        )
        .toList();
  }

  Future<void> _save() async {
    await _box?.put(
      _marathonsKey,
      _customMarathons.map(_marathonToMap).toList(),
    );
  }

  MarathonCollection _marathonFromMap(Map<dynamic, dynamic> map) {
    return MarathonCollection(
      id:
          map['id'] as String? ??
          'custom-${DateTime.now().microsecondsSinceEpoch}',
      title: map['title'] as String? ?? 'Custom LineUp',
      subtitle: map['subtitle'] as String? ?? 'Custom LineUp',
      description:
          map['description'] as String? ??
          'A custom watch order from TMDb collections and selected movies.',
      accentColor: map['accentColor'] as int? ?? 0xFFE53935,
      collectionQueries: ((map['collectionQueries'] as List?) ?? const [])
          .map((value) => value.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList(),
      manualMovies: ((map['manualMovies'] as List?) ?? const [])
          .whereType<Map>()
          .map(_movieFromMap)
          .where((movie) => movie.id != 0)
          .toList(),
      isUserCreated: true,
    );
  }

  Map<String, dynamic> _marathonToMap(MarathonCollection marathon) {
    return {
      'id': marathon.id,
      'title': marathon.title,
      'subtitle': marathon.subtitle,
      'description': marathon.description,
      'accentColor': marathon.accentColor,
      'collectionQueries': marathon.collectionQueries,
      'manualMovies': marathon.manualMovies.map(_movieToMap).toList(),
    };
  }

  List<Movie> _uniqueMovies(List<Movie> movies) {
    final seen = <int>{};
    final result = <Movie>[];
    for (final movie in movies) {
      if (movie.id == 0 || !seen.add(movie.id)) continue;
      result.add(movie);
    }
    return result;
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
}
