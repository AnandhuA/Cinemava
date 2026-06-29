import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../domain/entities/movie.dart';

class MoviePosterCard extends StatelessWidget {
  const MoviePosterCard({
    super.key,
    required this.movie,
    this.compact = false,
    this.enableHero = true,
  });

  final Movie movie;
  final bool compact;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackWidth = compact
            ? double.infinity
            : Responsive.movieRailCardWidth(context);
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : fallbackWidth;

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go('/movie/${movie.id}'),
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PosterImage(movie: movie, enableHero: enableHero),
                const SizedBox(height: 8),
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${movie.year} • ${movie.rating.toStringAsFixed(1)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MoviePosterRailCard extends StatelessWidget {
  const MoviePosterRailCard({
    super.key,
    required this.movie,
    this.enableHero = false,
  });

  final Movie movie;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    final width = Responsive.movieRailCardWidth(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final posterHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight - 54).clamp(120.0, width * 1.5).toDouble()
            : width * 1.5;

        return SizedBox(
          width: width,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.go('/movie/${movie.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PosterImage(
                  movie: movie,
                  enableHero: enableHero,
                  height: posterHeight,
                ),
                const SizedBox(height: 6),
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${movie.year} • ${movie.rating.toStringAsFixed(1)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({
    required this.movie,
    required this.enableHero,
    this.height,
  });

  final Movie movie;
  final bool enableHero;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final poster = SizedBox(
      height: height,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: movie.posterUrl.isEmpty
              ? const ColoredBox(
                  color: Color(0xFF252936),
                  child: Center(child: Icon(Icons.movie_outlined)),
                )
              : Image.network(movie.posterUrl, fit: BoxFit.cover),
        ),
      ),
    );

    if (!enableHero) return poster;

    return Hero(tag: 'movie-poster-${movie.id}', child: poster);
  }
}
