import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/cached_app_image.dart';
import '../../../movies/domain/entities/movie.dart';
import '../../../movies/domain/entities/movie_details.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../random_pick/presentation/providers/spin_wheel_provider.dart';

class MovieDetailsPage extends StatefulWidget {
  const MovieDetailsPage({super.key, required this.movieId});

  final int movieId;

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MovieLibraryProvider>().loadMovieDetails(widget.movieId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieLibraryProvider>();
    final movie = provider.movieById(widget.movieId);
    final details = provider.detailsByMovieId(widget.movieId);

    if (movie == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Movie details')),
        body: const Center(child: Text('Movie not found.')),
      );
    }

    final runtime = details?.runtime ?? movie.runtime;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedAppImage(
                    imageUrl: movie.backdropUrl,
                    placeholderIcon: Icons.movie_filter_outlined,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.18),
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
                  _MovieHeader(movie: movie, runtime: runtime),
                  const SizedBox(height: 20),
                  _ActionButtons(movie: movie, details: details),
                  if (provider.loadingDetailsMovieId == movie.id) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (provider.detailsErrorMessage != null) ...[
                    const SizedBox(height: 20),
                    _InlineMessage(message: provider.detailsErrorMessage!),
                  ],
                  const SizedBox(height: 26),
                  _SectionTitle(title: 'Description'),
                  const SizedBox(height: 8),
                  Text(
                    movie.overview.isEmpty
                        ? 'No description available.'
                        : movie.overview,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 26),
                  _CastSection(cast: details?.cast ?? const []),
                  const SizedBox(height: 26),
                  _StreamingSection(
                    providers: details?.streamingProviders ?? const [],
                  ),
                  const SizedBox(height: 26),
                  _SuggestionsSection(
                    recommendations: details?.recommendations ?? const [],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieHeader extends StatelessWidget {
  const _MovieHeader({required this.movie, required this.runtime});

  final Movie movie;
  final String runtime;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Hero(
          tag: 'movie-poster-${movie.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedAppImage(
              imageUrl: movie.posterUrl,
              width: 128,
              height: 192,
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${movie.year} • $runtime • ${movie.language}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                movie.genres.join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.star, size: 18),
                    label: Text('${movie.rating.toStringAsFixed(1)} TMDb'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.people_alt_outlined, size: 18),
                    label: const Text('Audience'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.movie, required this.details});

  final Movie movie;
  final MovieDetails? details;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieLibraryProvider>();
    final wheel = context.watch<SpinWheelProvider>();
    final trailerUrl = details?.trailerUrl;

    return Wrap(
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
            provider.isWatched(movie.id) ? 'Watched' : 'Mark Watched',
          ),
        ),
        OutlinedButton.icon(
          onPressed: wheel.contains(movie.id)
              ? null
              : () {
                  final added = wheel.addPriorityMovie(movie);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        added
                            ? 'Added ${movie.title} to the spin wheel.'
                            : movie.isReleased
                            ? '${movie.title} is already in the spin wheel.'
                            : 'Only released movies can be added to the spin wheel.',
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.casino_outlined),
          label: Text(
            wheel.contains(movie.id) ? 'In Spin Wheel' : 'Add to Spin',
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/journal/movie/${movie.id}'),
          icon: const Icon(Icons.edit_note),
          label: const Text('Write Journal'),
        ),
        OutlinedButton.icon(
          onPressed: trailerUrl == null
              ? null
              : () => launchUrl(
                  Uri.parse(trailerUrl),
                  mode: LaunchMode.externalApplication,
                ),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Watch Trailer'),
        ),
      ],
    );
  }
}

class _CastSection extends StatelessWidget {
  const _CastSection({required this.cast});

  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Cast'),
        const SizedBox(height: 12),
        if (cast.isEmpty)
          const _InlineMessage(message: 'Cast details are not available yet.')
        else
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cast.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final member = cast[index];
                return SizedBox(
                  width: 96,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: member.id == 0
                        ? null
                        : () => context.push(
                            '/person/${member.id}?name=${Uri.encodeComponent(member.name)}',
                          ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedAppImage(
                            imageUrl: member.profileUrl,
                            width: 96,
                            height: 96,
                            placeholderIcon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          member.character,
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
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StreamingSection extends StatelessWidget {
  const _StreamingSection({required this.providers});

  final List<WatchProvider> providers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Streaming'),
        const SizedBox(height: 12),
        if (providers.isEmpty)
          const _InlineMessage(
            message: 'Streaming availability is not listed for your region.',
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final provider in providers)
                Chip(
                  avatar: provider.logoUrl.isEmpty
                      ? const Icon(Icons.live_tv_outlined)
                      : ClipOval(
                          child: CachedAppImage(
                            imageUrl: provider.logoUrl,
                            width: 22,
                            height: 22,
                            placeholderIcon: Icons.live_tv_outlined,
                          ),
                        ),
                  label: Text(provider.name),
                ),
            ],
          ),
      ],
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  const _SuggestionsSection({required this.recommendations});

  final List<Movie> recommendations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Suggestions'),
        const SizedBox(height: 12),
        if (recommendations.isEmpty)
          const _InlineMessage(message: 'Suggestions are not available yet.')
        else ...[
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recommendations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _SuggestionCard(movie: recommendations[index]);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push('/movie/${movie.id}'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedAppImage(
                      imageUrl: movie.posterUrl,
                      width: double.infinity,
                      placeholderIcon: Icons.local_movies_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movie.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        movie.year.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
