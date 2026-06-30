import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../domain/entities/movie.dart';
import 'movie_poster_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies, this.enableHero = true});

  final List<Movie> movies;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    final firstIndexByMovieId = <int, int>{};
    for (var index = 0; index < movies.length; index++) {
      firstIndexByMovieId.putIfAbsent(movies[index].id, () => index);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.posterGridCount(context),
        childAspectRatio: Responsive.posterGridAspectRatio(context),
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
      ),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return MoviePosterCard(
          movie: movie,
          compact: true,
          enableHero: enableHero && firstIndexByMovieId[movie.id] == index,
        );
      },
    );
  }
}
