import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../movies/domain/entities/movie.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../movies/presentation/widgets/movie_poster_card.dart';
import '../../../onboarding/presentation/providers/user_preference_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<String> _loadedLanguages = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languages = context.read<UserPreferenceProvider>().selectedLanguages;
    if (setEquals(_loadedLanguages, languages)) return;

    _loadedLanguages = Set<String>.from(languages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MovieLibraryProvider>().loadLanguageMovies(languages);
    });
  }

  @override
  Widget build(BuildContext context) {
    final movieProvider = context.watch<MovieLibraryProvider>();
    final movies = movieProvider.movies;
    final preferences = context.watch<UserPreferenceProvider>();
    final recommended = movieProvider.recommendedMovies(
      genres: preferences.selectedGenres,
      languages: preferences.selectedLanguages,
    );
    final selectedLanguages = preferences.selectedLanguages.toList()..sort();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 88,
            pinned: true,
            title: const Text('Cinemava'),
          ),
          if (movieProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (movieProvider.errorMessage != null)
            SliverFillRemaining(
              child: _HomeErrorState(message: movieProvider.errorMessage!),
            )
          else if (movies.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No movies found.')),
            )
          else ...[
            if (selectedLanguages.isNotEmpty)
              _LanguageMovieTabs(languages: selectedLanguages),
            SliverToBoxAdapter(
              child: _TrendingPosterFeature(movie: movies.first),
            ),
            _MovieRail(title: 'Trending Now', movies: movieProvider.trending),
            _MovieRail(title: 'Recommended For You', movies: recommended),
            _MovieRail(title: 'Popular Movies', movies: movieProvider.popular),
            _MovieRail(title: 'Top Rated', movies: movieProvider.topRated),
            _MovieRail(title: 'Upcoming', movies: movieProvider.upcoming),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _LanguageMovieTabs extends StatelessWidget {
  const _LanguageMovieTabs({required this.languages});

  final List<String> languages;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieLibraryProvider>();

    return SliverToBoxAdapter(
      child: DefaultTabController(
        length: languages.length,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Your Setup', actionLabel: 'Languages'),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: [for (final language in languages) Tab(text: language)],
            ),
            SizedBox(
              height: Responsive.movieRailHeight(context) + 20,
              child: TabBarView(
                children: [
                  for (final language in languages)
                    _LanguageMovieRail(
                      language: language,
                      movies: provider.moviesForLanguage(language),
                      isLoading: provider.isLoadingLanguage(language),
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

class _LanguageMovieRail extends StatelessWidget {
  const _LanguageMovieRail({
    required this.language,
    required this.movies,
    required this.isLoading,
  });

  final String language;
  final List<Movie> movies;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && movies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (movies.isEmpty) {
      return Center(child: Text('No $language movies loaded yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      scrollDirection: Axis.horizontal,
      itemCount: movies.length,
      separatorBuilder: (_, _) => const SizedBox(width: 14),
      itemBuilder: (context, index) =>
          MoviePosterRailCard(movie: movies[index]),
    );
  }
}

class _TrendingPosterFeature extends StatelessWidget {
  const _TrendingPosterFeature({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push('/movie/${movie.id}'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Hero(
                    tag: 'movie-poster-${movie.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedAppImage(
                        imageUrl: movie.posterUrl,
                        width: 124,
                        height: 186,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trending Movie',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          movie.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${movie.year} • ${movie.language} • ${movie.genres.join(', ')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'TMDb is not ready',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
            onPressed: () {
              context.read<MovieLibraryProvider>().loadInitialMovies();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
          ),
        ],
      ),
    );
  }
}

class _MovieRail extends StatelessWidget {
  const _MovieRail({required this.title, required this.movies});

  final String title;
  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          SizedBox(
            height: Responsive.movieRailHeight(context),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: movies.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) =>
                  MoviePosterRailCard(movie: movies[index]),
            ),
          ),
        ],
      ),
    );
  }
}
