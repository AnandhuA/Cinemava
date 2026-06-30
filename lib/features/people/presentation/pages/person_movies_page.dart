import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/cached_app_image.dart';
import '../../../movies/domain/entities/movie.dart';
import '../../../movies/domain/entities/person_profile.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';

class PersonMoviesPage extends StatefulWidget {
  const PersonMoviesPage({
    super.key,
    required this.personId,
    required this.personName,
  });

  final int personId;
  final String personName;

  @override
  State<PersonMoviesPage> createState() => _PersonMoviesPageState();
}

class _PersonMoviesPageState extends State<PersonMoviesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant PersonMoviesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personId != widget.personId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(force: true));
    }
  }

  void _load({bool force = false}) {
    if (!mounted) return;
    context.read<MovieLibraryProvider>().loadPersonMovies(
      widget.personId,
      force: force,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieLibraryProvider>();
    final profile = provider.personProfile(widget.personId);
    final movies = provider.moviesForPerson(widget.personId);
    final isLoading = provider.isLoadingPerson(widget.personId);
    final error = provider.personError(widget.personId);
    final title = profile?.name.isNotEmpty == true
        ? profile!.name
        : widget.personName.isEmpty
        ? 'Actor movies'
        : widget.personName;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () async => _load(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _PersonHeader(
              profile: profile,
              fallbackName: title,
              movieCount: movies.length,
              isLoading: isLoading,
            ),
            const SizedBox(height: 20),
            Text(
              'Movies',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (isLoading && movies.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 56),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null && movies.isEmpty)
              _PersonMoviesMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Movies are not ready',
                message: error,
                onReload: () => _load(force: true),
              )
            else if (movies.isEmpty)
              _PersonMoviesMessage(
                icon: Icons.movie_outlined,
                title: 'No movies found',
                message:
                    'TMDb has no movie credits listed for this person yet.',
                onReload: () => _load(force: true),
              )
            else
              for (final movie in movies) ...[
                _ActorMovieCard(movie: movie),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _PersonHeader extends StatelessWidget {
  const _PersonHeader({
    required this.profile,
    required this.fallbackName,
    required this.movieCount,
    required this.isLoading,
  });

  final PersonProfile? profile;
  final String fallbackName;
  final int movieCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name.isNotEmpty == true
        ? profile!.name
        : fallbackName;
    final biography = profile?.biography ?? '';
    final meta = [
      if (profile?.knownForDepartment.isNotEmpty == true)
        profile!.knownForDepartment,
      if (profile?.birthday.isNotEmpty == true) profile!.birthday,
      if (profile?.placeOfBirth.isNotEmpty == true) profile!.placeOfBirth,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedAppImage(
                    imageUrl: profile?.profileUrl ?? '',
                    width: 112,
                    height: 150,
                    placeholderIcon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          meta.join(' • '),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Chip(
                        avatar: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.local_movies_outlined, size: 18),
                        label: Text(
                          isLoading ? 'Loading credits' : '$movieCount movies',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (biography.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                biography,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActorMovieCard extends StatelessWidget {
  const _ActorMovieCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/movie/${movie.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedAppImage(
                  imageUrl: movie.posterUrl,
                  width: 72,
                  height: 108,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          icon: Icons.event_outlined,
                          label: movie.year.toString(),
                        ),
                        _InfoChip(
                          icon: Icons.star,
                          label: movie.rating.toStringAsFixed(1),
                        ),
                        if (movie.language.isNotEmpty)
                          _InfoChip(
                            icon: Icons.translate,
                            label: movie.language,
                          ),
                      ],
                    ),
                    if (movie.genres.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        movie.genres.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (movie.overview.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        movie.overview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.3),
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

class _PersonMoviesMessage extends StatelessWidget {
  const _PersonMoviesMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.onReload,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
      child: Column(
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
          const SizedBox(height: 18),
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
