import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../domain/entities/movie.dart';
import 'movie_poster_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
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
        return MoviePosterCard(movie: movies[index], compact: true);
      },
    );
  }
}
