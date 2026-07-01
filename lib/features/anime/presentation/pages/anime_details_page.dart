import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/cached_app_image.dart';
import '../../../movies/domain/entities/movie.dart';
import '../../../random_pick/presentation/providers/spin_wheel_provider.dart';
import '../../domain/entities/anime.dart';
import '../../domain/entities/anime_details.dart';
import '../providers/anime_provider.dart';
import '../widgets/anime_status_badges.dart';

class AnimeDetailsPage extends StatefulWidget {
  const AnimeDetailsPage({super.key, required this.anime});

  final Anime anime;

  @override
  State<AnimeDetailsPage> createState() => _AnimeDetailsPageState();
}

class _AnimeDetailsPageState extends State<AnimeDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnimeProvider>().loadAnimeDetails(widget.anime);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnimeProvider>();
    final details = provider.detailsByAnimeId(widget.anime.id);
    final anime = details?.anime ?? widget.anime;

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
                    imageUrl: anime.imageUrl,
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.auto_awesome_outlined,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.42),
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
                  _AnimeHeader(anime: anime, details: details),
                  const SizedBox(height: 18),
                  _ActionRow(anime: anime, details: details),
                  if (provider.loadingDetailsAnimeId == anime.id) ...[
                    const SizedBox(height: 18),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (provider.detailsErrorMessage != null) ...[
                    const SizedBox(height: 16),
                    _InlineMessage(message: provider.detailsErrorMessage!),
                  ],
                  const SizedBox(height: 26),
                  const _SectionTitle(title: 'Genres'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final genre in anime.genres)
                        Chip(label: Text(genre)),
                      if (anime.genres.isEmpty) const Text('Not listed'),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle(title: 'Synopsis'),
                  const SizedBox(height: 8),
                  Text(
                    anime.synopsis.isEmpty
                        ? 'No synopsis available.'
                        : anime.synopsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 26),
                  _CharactersSection(
                    characters: details?.characters ?? const [],
                  ),
                  const SizedBox(height: 26),
                  _StreamingSection(links: details?.streamingLinks ?? const []),
                  const SizedBox(height: 26),
                  _RecommendationsSection(
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

class _AnimeHeader extends StatelessWidget {
  const _AnimeHeader({required this.anime, required this.details});

  final Anime anime;
  final AnimeDetails? details;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedAppImage(
            imageUrl: anime.imageUrl,
            width: 128,
            height: 184,
            placeholderIcon: Icons.auto_awesome_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                anime.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  anime.type,
                  if (anime.year != null) anime.year.toString(),
                  if (anime.episodes != null) '${anime.episodes} episodes',
                  if ((details?.duration ?? '').isNotEmpty) details!.duration,
                ].join(' • '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (anime.score > 0)
                    Chip(
                      avatar: const Icon(Icons.star, size: 18),
                      label: Text('${anime.score.toStringAsFixed(1)} MAL'),
                    ),
                  if ((details?.status ?? '').isNotEmpty)
                    Chip(label: Text(details!.status)),
                  if ((details?.rating ?? '').isNotEmpty)
                    Chip(label: Text(details!.rating)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.anime, required this.details});

  final Anime anime;
  final AnimeDetails? details;

  @override
  Widget build(BuildContext context) {
    final trailerUrl = details?.trailerUrl;
    final provider = context.watch<AnimeProvider>();
    final wheel = context.watch<SpinWheelProvider>();
    final spinMovie = _animeToSpinMovie(anime);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: () => provider.toggleWishlist(anime),
          icon: Icon(
            provider.isInWishlist(anime.id)
                ? Icons.bookmark
                : Icons.bookmark_border,
          ),
          label: Text(
            provider.isInWishlist(anime.id) ? 'In Wishlist' : 'Add to Wishlist',
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => provider.toggleWatched(anime),
          icon: Icon(
            provider.isWatched(anime.id)
                ? Icons.check_circle
                : Icons.check_circle_outline,
          ),
          label: Text(
            provider.isWatched(anime.id) ? 'Watched' : 'Mark Watched',
          ),
        ),
        OutlinedButton.icon(
          onPressed: wheel.contains(spinMovie.id)
              ? null
              : () {
                  final added = wheel.addPriorityMovie(spinMovie);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        added
                            ? 'Added ${anime.title} to the spin wheel.'
                            : '${anime.title} is already in the spin wheel.',
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.casino_outlined),
          label: Text(wheel.contains(spinMovie.id) ? 'In Spin' : 'Add to Spin'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/journal/movie/${-anime.id}'),
          icon: const Icon(Icons.edit_note),
          label: const Text('Write Journal'),
        ),
        FilledButton.icon(
          onPressed: trailerUrl == null
              ? null
              : () => launchUrl(
                  Uri.parse(trailerUrl),
                  mode: LaunchMode.externalApplication,
                ),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Watch Trailer'),
        ),
        OutlinedButton.icon(
          onPressed: details?.streamingLinks.isEmpty ?? true
              ? null
              : () => launchUrl(
                  Uri.parse(details!.streamingLinks.first.url),
                  mode: LaunchMode.externalApplication,
                ),
          icon: const Icon(Icons.live_tv_outlined),
          label: const Text('Stream'),
        ),
      ],
    );
  }

  Movie _animeToSpinMovie(Anime anime) {
    return Movie(
      id: -anime.id,
      title: anime.title,
      year: anime.year ?? DateTime.now().year,
      runtime: anime.episodes == null ? anime.type : '${anime.episodes} eps',
      genres: anime.genres,
      language: 'Anime',
      rating: anime.score,
      overview: anime.synopsis,
      posterUrl: anime.imageUrl,
      backdropUrl: anime.imageUrl,
      cast: const [],
      isReleased: true,
    );
  }
}

class _CharactersSection extends StatelessWidget {
  const _CharactersSection({required this.characters});

  final List<AnimeCharacter> characters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Characters'),
        const SizedBox(height: 12),
        if (characters.isEmpty)
          const _InlineMessage(
            message: 'Character details are not available yet.',
          )
        else
          SizedBox(
            height: 164,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: characters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final character = characters[index];
                return SizedBox(
                  width: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedAppImage(
                          imageUrl: character.imageUrl,
                          width: 104,
                          height: 104,
                          placeholderIcon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        character.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        character.voiceActorName.isEmpty
                            ? character.role
                            : character.voiceActorName,
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
  const _StreamingSection({required this.links});

  final List<AnimeStreamingLink> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Streaming'),
        const SizedBox(height: 12),
        if (links.isEmpty)
          const _InlineMessage(message: 'Streaming links are not listed.')
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final link in links)
                ActionChip(
                  avatar: const Icon(Icons.open_in_new, size: 18),
                  label: Text(link.name),
                  onPressed: () => launchUrl(
                    Uri.parse(link.url),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  const _RecommendationsSection({required this.recommendations});

  final List<Anime> recommendations;

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
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recommendations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final anime = recommendations[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push('/anime/${anime.id}', extra: anime),
                  child: SizedBox(
                    width: 128,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 128,
                          height: 178,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedAppImage(
                                  imageUrl: anime.imageUrl,
                                  width: 128,
                                  height: 178,
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
                        const SizedBox(height: 8),
                        Text(
                          anime.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
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
