import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../movies/domain/entities/movie.dart';
import '../../../movies/domain/entities/movie_details.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../movies/presentation/widgets/movie_grid.dart';

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
                  if (movie.backdropUrl.isEmpty)
                    ColoredBox(color: Theme.of(context).cardColor)
                  else
                    Image.network(movie.backdropUrl, fit: BoxFit.cover),
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
            child: movie.posterUrl.isEmpty
                ? const SizedBox(
                    width: 128,
                    height: 192,
                    child: ColoredBox(
                      color: Color(0xFF252936),
                      child: Icon(Icons.movie_outlined),
                    ),
                  )
                : Image.network(
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
          onPressed: () {},
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: member.profileUrl.isEmpty
                            ? const SizedBox(
                                width: 96,
                                height: 96,
                                child: ColoredBox(
                                  color: Color(0xFF252936),
                                  child: Icon(Icons.person_outline),
                                ),
                              )
                            : Image.network(
                                member.profileUrl,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
                          child: Image.network(
                            provider.logoUrl,
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
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
        else
          SizedBox(height: 520, child: MovieGrid(movies: recommendations)),
      ],
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
