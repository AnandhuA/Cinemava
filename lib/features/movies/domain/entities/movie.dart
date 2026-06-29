class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.runtime,
    required this.genres,
    required this.language,
    required this.rating,
    required this.overview,
    required this.posterUrl,
    required this.backdropUrl,
    required this.cast,
  });

  final int id;
  final String title;
  final int year;
  final String runtime;
  final List<String> genres;
  final String language;
  final double rating;
  final String overview;
  final String posterUrl;
  final String backdropUrl;
  final List<String> cast;
}
