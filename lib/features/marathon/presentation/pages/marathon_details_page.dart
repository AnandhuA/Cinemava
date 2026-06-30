import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/cached_app_image.dart';
import '../../../movies/domain/entities/movie.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../data/marathon_data.dart';

class MarathonDetailsPage extends StatefulWidget {
  const MarathonDetailsPage({super.key, required this.marathon});

  final MarathonCollection? marathon;

  @override
  State<MarathonDetailsPage> createState() => _MarathonDetailsPageState();
}

class _MarathonDetailsPageState extends State<MarathonDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant MarathonDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marathon?.id != widget.marathon?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  void _load({bool force = false}) {
    final marathon = widget.marathon;
    if (!mounted || marathon == null) return;
    context.read<MovieLibraryProvider>().loadMarathonMovies(
      id: marathon.id,
      collectionQueries: marathon.collectionQueries,
      force: force,
    );
  }

  @override
  Widget build(BuildContext context) {
    final marathon = widget.marathon;
    if (marathon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Release order')),
        body: const Center(child: Text('Marathon not found.')),
      );
    }

    final provider = context.watch<MovieLibraryProvider>();
    final movies = provider.moviesForMarathon(marathon.id);
    final isLoading = provider.isLoadingMarathon(marathon.id);
    final error = provider.marathonError(marathon.id);

    return Scaffold(
      appBar: AppBar(title: Text(marathon.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MarathonHeader(
            marathon: marathon,
            movieCount: movies.length,
            isLoading: isLoading,
          ),
          const SizedBox(height: 20),
          Text(
            'Release Order',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (isLoading && movies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null && movies.isEmpty)
            _MarathonError(message: error, onReload: () => _load(force: true))
          else if (movies.isEmpty)
            _MarathonError(
              message: 'TMDb did not return movies for this series yet.',
              onReload: () => _load(force: true),
            )
          else
            for (var index = 0; index < movies.length; index++)
              _WatchOrderTile(
                index: index + 1,
                movie: movies[index],
                accentColor: Color(marathon.accentColor),
                isLast: index == movies.length - 1,
              ),
        ],
      ),
    );
  }
}

class _MarathonHeader extends StatelessWidget {
  const _MarathonHeader({
    required this.marathon,
    required this.movieCount,
    required this.isLoading,
  });

  final MarathonCollection marathon;
  final int movieCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(marathon.accentColor).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(marathon.accentColor).withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              marathon.subtitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Color(marathon.accentColor),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              marathon.description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.movie_outlined, size: 18),
                  label: Text(
                    isLoading ? 'Loading movies' : '$movieCount movies',
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.cloud_sync_outlined, size: 18),
                  label: Text(
                    '${marathon.collectionQueries.length} TMDb series',
                  ),
                ),
                const Chip(
                  avatar: Icon(Icons.event_available_outlined, size: 18),
                  label: Text('Release order'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarathonError extends StatelessWidget {
  const _MarathonError({required this.message, required this.onReload});

  final String message;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
          ),
        ],
      ),
    );
  }
}

class _WatchOrderTile extends StatelessWidget {
  const _WatchOrderTile({
    required this.index,
    required this.movie,
    required this.accentColor,
    required this.isLast,
  });

  final int index;
  final Movie movie;
  final Color accentColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Card(
                margin: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final readyMovie = await context
                        .read<MovieLibraryProvider>()
                        .ensureMovie(movie);
                    if (!context.mounted) return;
                    context.push('/movie/${readyMovie.id}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedAppImage(
                            imageUrl: movie.posterUrl,
                            width: 58,
                            height: 86,
                            placeholderIcon: Icons.local_movies_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${movie.year} • ${movie.language} • ${movie.rating.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: accentColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              if (movie.genres.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  movie.genres.join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
