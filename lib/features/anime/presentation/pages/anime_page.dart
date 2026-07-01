import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/cached_app_image.dart';
import '../../domain/entities/anime.dart';
import '../providers/anime_provider.dart';

class AnimePage extends StatefulWidget {
  const AnimePage({super.key});

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnimeProvider>();
    final anime = provider.anime;
    final query = provider.query.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Anime')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AnimeProvider>().loadTopAnime(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: context.read<AnimeProvider>().setQuery,
                      decoration: InputDecoration(
                        hintText: 'Search anime...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? provider.isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : null
                            : IconButton(
                                tooltip: 'Clear',
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<AnimeProvider>().setQuery('');
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (query.isEmpty) ...[
                      _AnimeSummary(provider: provider),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      query.isEmpty ? 'Popular anime' : 'Results for "$query"',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (provider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.errorMessage != null && anime.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _AnimeMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Anime API is not ready',
                  message: provider.errorMessage!,
                ),
              )
            else if (anime.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _AnimeMessage(
                  icon: Icons.search_off,
                  title: 'No anime found',
                  message: 'Try another title.',
                ),
              )
            else
              SliverList.separated(
                itemCount: anime.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      index == 0 ? 0 : 0,
                      16,
                      index == anime.length - 1 ? 24 : 0,
                    ),
                    child: _AnimeCard(anime: anime[index]),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimeCard extends StatelessWidget {
  const _AnimeCard({required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnimeProvider>();
    return Card(
      child: InkWell(
        onTap: () => context.push('/anime/${anime.id}', extra: anime),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedAppImage(
                  imageUrl: anime.imageUrl,
                  width: 92,
                  height: 132,
                  placeholderIcon: Icons.auto_awesome_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        anime.type,
                        if (anime.year != null) anime.year.toString(),
                        if (anime.episodes != null) '${anime.episodes} eps',
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (anime.score > 0)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.star, size: 16),
                            label: Text(anime.score.toStringAsFixed(1)),
                          ),
                        for (final genre in anime.genres.take(2))
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(genre),
                          ),
                      ],
                    ),
                    if (anime.synopsis.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        anime.synopsis,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: Icon(
                            provider.isInWishlist(anime.id)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 18,
                          ),
                          label: Text(
                            provider.isInWishlist(anime.id)
                                ? 'Wishlisted'
                                : 'Wishlist',
                          ),
                          onPressed: () => context
                              .read<AnimeProvider>()
                              .toggleWishlist(anime),
                        ),
                        ActionChip(
                          avatar: Icon(
                            provider.isWatched(anime.id)
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: Text(
                            provider.isWatched(anime.id)
                                ? 'Watched'
                                : 'Watched',
                          ),
                          onPressed: () => context
                              .read<AnimeProvider>()
                              .toggleWatched(anime),
                        ),
                      ],
                    ),
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

class _AnimeSummary extends StatelessWidget {
  const _AnimeSummary({required this.provider});

  final AnimeProvider provider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _SummaryMetric(
              icon: Icons.auto_awesome,
              label: 'Popular',
              value: provider.topAnime.length.toString(),
            ),
            const SizedBox(width: 10),
            _SummaryMetric(
              icon: Icons.bookmark,
              label: 'Wishlist',
              value: provider.wishlistIds.length.toString(),
            ),
            const SizedBox(width: 10),
            _SummaryMetric(
              icon: Icons.check_circle,
              label: 'Watched',
              value: provider.watchedIds.length.toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimeMessage extends StatelessWidget {
  const _AnimeMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
