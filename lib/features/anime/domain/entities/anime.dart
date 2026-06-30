class Anime {
  const Anime({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.score,
    required this.year,
    required this.type,
    required this.episodes,
    required this.synopsis,
    required this.genres,
  });

  final int id;
  final String title;
  final String imageUrl;
  final double score;
  final int? year;
  final String type;
  final int? episodes;
  final String synopsis;
  final List<String> genres;
}
