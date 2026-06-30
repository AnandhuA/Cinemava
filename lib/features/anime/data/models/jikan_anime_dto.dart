import '../../domain/entities/anime.dart';

class JikanAnimeDto {
  const JikanAnimeDto({
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

  factory JikanAnimeDto.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>? ?? {};
    final jpg = images['jpg'] as Map<String, dynamic>? ?? {};
    final genres = (json['genres'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((genre) => genre['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    return JikanAnimeDto(
      id: json['mal_id'] as int? ?? 0,
      title: json['title_english'] as String? ?? json['title'] as String? ?? '',
      imageUrl:
          jpg['large_image_url'] as String? ??
          jpg['image_url'] as String? ??
          '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      year: json['year'] as int?,
      type: json['type'] as String? ?? 'Anime',
      episodes: json['episodes'] as int?,
      synopsis: json['synopsis'] as String? ?? '',
      genres: genres,
    );
  }

  final int id;
  final String title;
  final String imageUrl;
  final double score;
  final int? year;
  final String type;
  final int? episodes;
  final String synopsis;
  final List<String> genres;

  Anime toEntity() {
    return Anime(
      id: id,
      title: title,
      imageUrl: imageUrl,
      score: score,
      year: year,
      type: type,
      episodes: episodes,
      synopsis: synopsis,
      genres: genres,
    );
  }
}
