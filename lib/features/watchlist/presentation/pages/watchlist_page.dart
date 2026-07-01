import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../anime/domain/entities/anime.dart';
import '../../../anime/presentation/providers/anime_provider.dart';
import '../../../anime/presentation/widgets/anime_status_badges.dart';
import '../../../movies/domain/entities/movie.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../movies/presentation/widgets/movie_list_card.dart';

enum _SavedFilter { all, movies, anime }

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  _SavedFilter _filter = _SavedFilter.all;

  @override
  Widget build(BuildContext context) {
    final movieProvider = context.watch<MovieLibraryProvider>();
    final animeProvider = context.watch<AnimeProvider>();
    final movies = movieProvider.watchlist;
    final anime = animeProvider.wishlist;
    final totalSaved = movies.length + anime.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: totalSaved == 0
          ? const AppEmptyState(
              icon: Icons.bookmark_border,
              title: 'No saved titles yet',
              message:
                  'Add movies or anime from details and they will appear here.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ListSummary(
                  icon: Icons.bookmark,
                  title: '$totalSaved saved',
                  subtitle: '${movies.length} movies • ${anime.length} anime',
                ),
                const SizedBox(height: 12),
                _SavedFilterTabs(
                  selected: _filter,
                  movieCount: movies.length,
                  animeCount: anime.length,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 16),
                ..._buildSavedItems(context, movies, anime, animeProvider),
              ],
            ),
    );
  }

  List<Widget> _buildSavedItems(
    BuildContext context,
    List<Movie> movies,
    List<Anime> anime,
    AnimeProvider animeProvider,
  ) {
    final showMovies =
        _filter == _SavedFilter.all || _filter == _SavedFilter.movies;
    final showAnime =
        _filter == _SavedFilter.all || _filter == _SavedFilter.anime;
    final children = <Widget>[];

    if (showMovies && movies.isNotEmpty) {
      if (_filter == _SavedFilter.all) {
        children.add(const _SectionLabel(title: 'Movies'));
      }
      for (final movie in movies) {
        children.add(
          MovieListCard(
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
                onPressed: () =>
                    context.read<MovieLibraryProvider>().markWatched(movie.id),
                icon: const Icon(Icons.check_circle_outline),
              ),
            ],
          ),
        );
        children.add(const SizedBox(height: 12));
      }
    }

    if (showAnime && anime.isNotEmpty) {
      if (_filter == _SavedFilter.all) {
        children.add(const _SectionLabel(title: 'Anime'));
      }
      for (final item in anime) {
        children.add(
          _AnimeListCard(
            anime: item,
            isWatched: animeProvider.isWatched(item.id),
          ),
        );
        children.add(const SizedBox(height: 12));
      }
    }

    if (children.isEmpty) {
      return [
        _FilteredEmpty(
          message: _filter == _SavedFilter.movies
              ? 'No movies in your watchlist yet.'
              : 'No anime in your wishlist yet.',
        ),
      ];
    }

    if (children.last is SizedBox) children.removeLast();
    return children;
  }
}

class _SavedFilterTabs extends StatelessWidget {
  const _SavedFilterTabs({
    required this.selected,
    required this.movieCount,
    required this.animeCount,
    required this.onChanged,
  });

  final _SavedFilter selected;
  final int movieCount;
  final int animeCount;
  final ValueChanged<_SavedFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_SavedFilter>(
      segments: [
        ButtonSegment(
          value: _SavedFilter.all,
          icon: const Icon(Icons.grid_view_rounded),
          label: Text('All ${movieCount + animeCount}'),
        ),
        ButtonSegment(
          value: _SavedFilter.movies,
          icon: const Icon(Icons.local_movies_outlined),
          label: Text('Movies $movieCount'),
        ),
        ButtonSegment(
          value: _SavedFilter.anime,
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

class _AnimeListCard extends StatelessWidget {
  const _AnimeListCard({required this.anime, required this.isWatched});

  final Anime anime;
  final bool isWatched;

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
              SizedBox(
                width: 76,
                height: 114,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedAppImage(
                        imageUrl: anime.imageUrl,
                        width: 76,
                        height: 114,
                        placeholderIcon: Icons.auto_awesome_outlined,
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AnimeStatusBadges(
                          animeId: anime.id,
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
                              tooltip: 'Remove',
                              onPressed: () => context
                                  .read<AnimeProvider>()
                                  .toggleWishlist(anime),
                              icon: const Icon(Icons.bookmark_remove_outlined),
                            ),
                            IconButton(
                              tooltip: isWatched
                                  ? 'Remove watched'
                                  : 'Mark watched',
                              onPressed: () => context
                                  .read<AnimeProvider>()
                                  .toggleWatched(anime),
                              icon: Icon(
                                isWatched
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                              ),
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
                      'Saved to anime wishlist',
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
