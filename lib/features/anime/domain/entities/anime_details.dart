import 'anime.dart';

class AnimeDetails {
  const AnimeDetails({
    required this.anime,
    required this.trailerUrl,
    required this.streamingLinks,
    required this.characters,
    required this.recommendations,
    required this.status,
    required this.rating,
    required this.duration,
  });

  final Anime anime;
  final String? trailerUrl;
  final List<AnimeStreamingLink> streamingLinks;
  final List<AnimeCharacter> characters;
  final List<Anime> recommendations;
  final String status;
  final String rating;
  final String duration;
}

class AnimeStreamingLink {
  const AnimeStreamingLink({required this.name, required this.url});

  final String name;
  final String url;
}

class AnimeCharacter {
  const AnimeCharacter({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.voiceActorName,
  });

  final String name;
  final String role;
  final String imageUrl;
  final String voiceActorName;
}
