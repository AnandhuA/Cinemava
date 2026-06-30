import 'movie.dart';

class MovieDetails {
  const MovieDetails({
    required this.movie,
    required this.cast,
    required this.trailerUrl,
    required this.streamingProviders,
    required this.recommendations,
    required this.runtime,
  });

  final Movie movie;
  final List<CastMember> cast;
  final String? trailerUrl;
  final List<WatchProvider> streamingProviders;
  final List<Movie> recommendations;
  final String runtime;
}

class CastMember {
  const CastMember({
    required this.id,
    required this.name,
    required this.character,
    required this.profileUrl,
  });

  final int id;
  final String name;
  final String character;
  final String profileUrl;
}

class WatchProvider {
  const WatchProvider({required this.name, required this.logoUrl});

  final String name;
  final String logoUrl;
}
