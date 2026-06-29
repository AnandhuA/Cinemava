import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/movie.dart';

class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.releaseDate,
    required this.genreIds,
    required this.originalLanguage,
    required this.voteAverage,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
  });

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDto(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? json['name'] ?? 'Untitled') as String,
      releaseDate:
          (json['release_date'] ?? json['first_air_date'] ?? '') as String,
      genreIds: ((json['genre_ids'] as List<dynamic>?) ?? const [])
          .whereType<int>()
          .toList(),
      originalLanguage: json['original_language'] as String? ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
    );
  }

  final int id;
  final String title;
  final String releaseDate;
  final List<int> genreIds;
  final String originalLanguage;
  final double voteAverage;
  final String overview;
  final String? posterPath;
  final String? backdropPath;

  Movie toEntity() {
    return Movie(
      id: id,
      title: title,
      year: _releaseYear,
      runtime: '-',
      genres: genreIds.map((id) => _genreNames[id] ?? 'Movie').toList(),
      language:
          _languageNames[originalLanguage] ?? originalLanguage.toUpperCase(),
      rating: voteAverage,
      overview: overview,
      posterUrl: posterPath == null
          ? ''
          : '${ApiConstants.tmdbImageBaseUrl}$posterPath',
      backdropUrl: backdropPath == null
          ? ''
          : '${ApiConstants.tmdbBackdropBaseUrl}$backdropPath',
      cast: const [],
    );
  }

  int get _releaseYear {
    if (releaseDate.length < 4) return DateTime.now().year;
    return int.tryParse(releaseDate.substring(0, 4)) ?? DateTime.now().year;
  }
}

const _genreNames = {
  28: 'Action',
  12: 'Adventure',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  14: 'Fantasy',
  36: 'History',
  27: 'Horror',
  10402: 'Music',
  9648: 'Mystery',
  10749: 'Romance',
  878: 'Sci-Fi',
  10770: 'TV Movie',
  53: 'Thriller',
  10752: 'War',
  37: 'Western',
};

const _languageNames = {
  'en': 'English',
  'hi': 'Hindi',
  'ml': 'Malayalam',
  'ta': 'Tamil',
  'te': 'Telugu',
  'kn': 'Kannada',
  'ko': 'Korean',
  'ja': 'Japanese',
  'fr': 'French',
  'es': 'Spanish',
};
