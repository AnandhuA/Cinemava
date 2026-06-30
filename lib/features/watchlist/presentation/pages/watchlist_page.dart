import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../movies/presentation/widgets/movie_list_card.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieLibraryProvider>();
    final movies = provider.watchlist;

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: movies.isEmpty
          ? const AppEmptyState(
              icon: Icons.bookmark_border,
              title: 'No saved movies yet',
              message: 'Add movies from details and they will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: movies.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ListSummary(
                    icon: Icons.bookmark,
                    title: '${movies.length} saved',
                    subtitle: 'Movies you want to watch later',
                  );
                }

                final movie = movies[index - 1];
                return MovieListCard(
                  movie: movie,
                  label: 'Saved to watchlist',
                  actions: [
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => context
                          .read<MovieLibraryProvider>()
                          .toggleWatchlist(movie.id),
                      icon: const Icon(Icons.bookmark_remove_outlined),
                    ),
                    IconButton(
                      tooltip: 'Mark watched',
                      onPressed: () => context
                          .read<MovieLibraryProvider>()
                          .markWatched(movie.id),
                      icon: const Icon(Icons.check_circle_outline),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ListSummary extends StatelessWidget {
  const _ListSummary({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.16),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
