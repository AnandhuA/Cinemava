import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/cached_app_image.dart';
import '../../domain/entities/movie.dart';
import 'movie_status_badges.dart';

class MovieListCard extends StatelessWidget {
  const MovieListCard({
    super.key,
    required this.movie,
    this.label,
    this.actions = const [],
  });

  final Movie movie;
  final String? label;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/movie/${movie.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 76,
                height: 114,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedAppImage(
                        imageUrl: movie.posterUrl,
                        width: 76,
                        height: 114,
                        placeholderIcon: Icons.local_movies_outlined,
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: MovieStatusBadges(
                          movieId: movie.id,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            movie.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (actions.isNotEmpty)
                          Wrap(spacing: 2, children: actions),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          icon: Icons.event_outlined,
                          label: movie.year.toString(),
                        ),
                        _InfoChip(
                          icon: Icons.star,
                          label: movie.rating.toStringAsFixed(1),
                        ),
                        if (movie.language.isNotEmpty)
                          _InfoChip(
                            icon: Icons.translate,
                            label: movie.language,
                          ),
                      ],
                    ),
                    if (label != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                    if (movie.genres.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        movie.genres.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (movie.overview.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        movie.overview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
