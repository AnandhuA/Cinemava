import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../anime/domain/entities/anime.dart';
import '../../../anime/presentation/providers/anime_provider.dart';
import '../../../movies/domain/entities/movie.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../movies/presentation/widgets/movie_list_card.dart';

enum _WatchedFilter { all, movies, anime }

class WatchedPage extends StatefulWidget {
  const WatchedPage({super.key});

  @override
  State<WatchedPage> createState() => _WatchedPageState();
}

class _WatchedPageState extends State<WatchedPage> {
  _WatchedFilter _filter = _WatchedFilter.all;

  @override
  Widget build(BuildContext context) {
    final movieProvider = context.watch<MovieLibraryProvider>();
    final animeProvider = context.watch<AnimeProvider>();
    final movies = movieProvider.watched;
    final anime = animeProvider.watched;
    final totalWatched = movies.length + anime.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Watched')),
      body: totalWatched == 0
          ? const AppEmptyState(
              icon: Icons.visibility_outlined,
              title: 'Nothing watched yet',
              message:
                  'Mark movies or anime as watched to build your personal history.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ListSummary(
                  icon: Icons.visibility,
                  title: '$totalWatched watched',
                  subtitle: '${movies.length} movies • ${anime.length} anime',
                ),
                const SizedBox(height: 12),
                _WatchedFilterTabs(
                  selected: _filter,
                  movieCount: movies.length,
                  animeCount: anime.length,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 16),
                ..._buildWatchedItems(context, movies, anime),
              ],
            ),
    );
  }

  List<Widget> _buildWatchedItems(
    BuildContext context,
    List<Movie> movies,
    List<Anime> anime,
  ) {
    final showMovies =
        _filter == _WatchedFilter.all || _filter == _WatchedFilter.movies;
    final showAnime =
        _filter == _WatchedFilter.all || _filter == _WatchedFilter.anime;
    final children = <Widget>[];

    if (showMovies && movies.isNotEmpty) {
      if (_filter == _WatchedFilter.all) {
        children.add(const _SectionLabel(title: 'Movies'));
      }
      for (final movie in movies) {
        children.add(
          MovieListCard(
            movie: movie,
            label: 'Watched',
            actions: [
              IconButton(
                tooltip: 'Write journal',
                onPressed: () => context.push('/journal/movie/${movie.id}'),
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
          ),
        );
        children.add(const SizedBox(height: 12));
      }
    }

    if (showAnime && anime.isNotEmpty) {
      if (_filter == _WatchedFilter.all) {
        children.add(const _SectionLabel(title: 'Anime'));
      }
      for (final item in anime) {
        children.add(_AnimeWatchedCard(anime: item));
        children.add(const SizedBox(height: 12));
      }
    }

    if (children.isEmpty) {
      return [
        _FilteredEmpty(
          message: _filter == _WatchedFilter.movies
              ? 'No watched movies yet.'
              : 'No watched anime yet.',
        ),
      ];
    }

    if (children.last is SizedBox) children.removeLast();
    return children;
  }
}

class _WatchedFilterTabs extends StatelessWidget {
  const _WatchedFilterTabs({
    required this.selected,
    required this.movieCount,
    required this.animeCount,
    required this.onChanged,
  });

  final _WatchedFilter selected;
  final int movieCount;
  final int animeCount;
  final ValueChanged<_WatchedFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_WatchedFilter>(
      segments: [
        ButtonSegment(
          value: _WatchedFilter.all,
          icon: const Icon(Icons.grid_view_rounded),
          label: Text('All ${movieCount + animeCount}'),
        ),
        ButtonSegment(
          value: _WatchedFilter.movies,
          icon: const Icon(Icons.local_movies_outlined),
          label: Text('Movies $movieCount'),
        ),
        ButtonSegment(
          value: _WatchedFilter.anime,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: Text('Anime $animeCount'),
        ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class _AnimeWatchedCard extends StatelessWidget {
  const _AnimeWatchedCard({required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/anime/${anime.id}', extra: anime),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedAppImage(
                  imageUrl: anime.imageUrl,
                  width: 76,
                  height: 114,
                  placeholderIcon: Icons.auto_awesome_outlined,
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
                            anime.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Wrap(
                          spacing: 2,
                          children: [
                            IconButton(
                              tooltip: 'Write journal',
                              onPressed: () =>
                                  context.push('/journal/movie/${-anime.id}'),
                              icon: const Icon(Icons.edit_note_outlined),
                            ),
                            IconButton(
                              tooltip: 'Remove watched',
                              onPressed: () => context
                                  .read<AnimeProvider>()
                                  .toggleWatched(anime),
                              icon: const Icon(Icons.visibility_off_outlined),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (anime.year != null)
                          _InfoChip(
                            icon: Icons.event_outlined,
                            label: anime.year.toString(),
                          ),
                        if (anime.type.isNotEmpty)
                          _InfoChip(
                            icon: Icons.live_tv_outlined,
                            label: anime.type,
                          ),
                        if (anime.score > 0)
                          _InfoChip(
                            icon: Icons.star,
                            label: anime.score.toStringAsFixed(1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Watched anime',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (anime.genres.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        anime.genres.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (anime.synopsis.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        anime.synopsis,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _FilteredEmpty extends StatelessWidget {
  const _FilteredEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              Icons.filter_list_off,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
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
