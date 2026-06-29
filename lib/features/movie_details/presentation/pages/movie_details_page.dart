import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../movies/presentation/providers/movie_library_provider.dart';

class MovieDetailsPage extends StatelessWidget {
  const MovieDetailsPage({super.key, required this.movieId});

  final int movieId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieLibraryProvider>();
    final movie = provider.movieById(movieId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(movie.backdropUrl, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.16),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Hero(
                        tag: 'movie-poster-${movie.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            movie.posterUrl,
                            width: 128,
                            height: 192,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${movie.year} • ${movie.runtime} • ${movie.genres.join(', ')}',
                            ),
                            const SizedBox(height: 8),
                            Chip(
                              avatar: const Icon(Icons.star, size: 18),
                              label: Text(movie.rating.toStringAsFixed(1)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.overview,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => provider.toggleWatchlist(movie.id),
                        icon: Icon(
                          provider.isInWatchlist(movie.id)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                        label: Text(
                          provider.isInWatchlist(movie.id)
                              ? 'In Watchlist'
                              : 'Add to Watchlist',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => provider.toggleWatched(movie.id),
                        icon: Icon(
                          provider.isWatched(movie.id)
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                        ),
                        label: Text(
                          provider.isWatched(movie.id)
                              ? 'Watched'
                              : 'Mark Watched',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Write Journal'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Trailer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cast',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(movie.cast.join(' • ')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
