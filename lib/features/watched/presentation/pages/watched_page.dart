import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../movies/presentation/widgets/movie_list_card.dart';

class WatchedPage extends StatelessWidget {
  const WatchedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieLibraryProvider>();
    final movies = provider.watched;

    return Scaffold(
      appBar: AppBar(title: const Text('Watched')),
      body: movies.isEmpty
          ? const AppEmptyState(
              icon: Icons.visibility_outlined,
              title: 'Nothing watched yet',
              message: 'Mark movies as watched to build your personal history.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: movies.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ListSummary(
                    icon: Icons.visibility,
                    title: '${movies.length} watched',
                    subtitle: 'Your personal movie history',
                  );
                }

                final movie = movies[index - 1];
                return MovieListCard(
                  movie: movie,
                  label: 'Watched',
                  actions: [
                    IconButton(
                      tooltip: 'Write journal',
                      onPressed: () =>
                          context.push('/journal/movie/${movie.id}'),
                      icon: const Icon(Icons.edit_note_outlined),
                    ),
                    IconButton(
                      tooltip: 'Remove watched',
                      onPressed: () => context
                          .read<MovieLibraryProvider>()
                          .toggleWatched(movie.id),
                      icon: const Icon(Icons.visibility_off_outlined),
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
