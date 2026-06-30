import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../movies/domain/entities/movie.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../movies/presentation/widgets/movie_list_card.dart';
import '../../../movies/presentation/widgets/movie_poster_card.dart';
import '../../../onboarding/presentation/providers/user_preference_provider.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _searchController = TextEditingController();
  String? _selectedGenre;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieLibraryProvider>();
    final preferences = context.watch<UserPreferenceProvider>();
    final query = provider.query.trim();
    final source = query.isEmpty
        ? provider.availableMovies
        : provider.searchResults;
    final filteredMovies = _filteredMovies(source);
    final genres = _availableGenres(provider, preferences);
    final languages = _availableLanguages(provider, preferences);
    final hasFilters = _selectedGenre != null || _selectedLanguage != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<MovieLibraryProvider>().loadInitialMovies(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SearchField(
                      controller: _searchController,
                      isSearching: provider.isSearching,
                      onChanged: context.read<MovieLibraryProvider>().setQuery,
                      onClear: () {
                        _searchController.clear();
                        context.read<MovieLibraryProvider>().setQuery('');
                      },
                    ),
                    const SizedBox(height: 14),
                    _FilterSection(
                      title: 'Genres',
                      values: genres,
                      selectedValue: _selectedGenre,
                      onSelected: (value) {
                        setState(() {
                          _selectedGenre = _selectedGenre == value
                              ? null
                              : value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _FilterSection(
                      title: 'Languages',
                      values: languages,
                      selectedValue: _selectedLanguage,
                      onSelected: (value) {
                        setState(() {
                          _selectedLanguage = _selectedLanguage == value
                              ? null
                              : value;
                        });
                      },
                    ),
                    if (hasFilters) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedGenre = null;
                              _selectedLanguage = null;
                            });
                          },
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Clear filters'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            if (provider.isSearching)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (query.isEmpty && !hasFilters) ...[
              _MovieRail(title: 'Trending now', movies: provider.trending),
              _MovieRail(title: 'Top rated', movies: provider.topRated),
              _MovieRail(title: 'Upcoming', movies: provider.upcoming),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'All loaded movies',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ] else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          query.isEmpty
                              ? 'Filtered movies'
                              : 'Results for "$query"',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '${filteredMovies.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (provider.searchErrorMessage != null &&
                query.isNotEmpty &&
                filteredMovies.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _DiscoverMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Search is not ready',
                  message: provider.searchErrorMessage!,
                ),
              )
            else if (filteredMovies.isEmpty && !provider.isSearching)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _DiscoverMessage(
                  icon: Icons.search_off,
                  title: 'No matching movies',
                  message: 'Try a different title, genre, or language.',
                ),
              )
            else
              SliverList.separated(
                itemCount: filteredMovies.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final movie = filteredMovies[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      index == 0 ? 4 : 0,
                      16,
                      index == filteredMovies.length - 1 ? 24 : 0,
                    ),
                    child: MovieListCard(movie: movie),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  List<Movie> _filteredMovies(List<Movie> movies) {
    return movies.where((movie) {
      final genreMatch =
          _selectedGenre == null || movie.genres.contains(_selectedGenre);
      final languageMatch =
          _selectedLanguage == null || movie.language == _selectedLanguage;
      return genreMatch && languageMatch;
    }).toList();
  }

  List<String> _availableGenres(
    MovieLibraryProvider provider,
    UserPreferenceProvider preferences,
  ) {
    final values = <String>{
      ...preferences.selectedGenres,
      ...provider.availableMovies.expand((movie) => movie.genres),
    }.where((value) => value.isNotEmpty && value != 'Movie').toList()..sort();
    return values.take(14).toList();
  }

  List<String> _availableLanguages(
    MovieLibraryProvider provider,
    UserPreferenceProvider preferences,
  ) {
    final values = <String>{
      ...preferences.selectedLanguages,
      ...provider.availableMovies.map((movie) => movie.language),
    }.where((value) => value.isNotEmpty).toList()..sort();
    return values.take(12).toList();
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.isSearching,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search movies, actors, genres...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null
            : IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<String> values;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final value = values[index];
              return FilterChip(
                label: Text(value),
                selected: selectedValue == value,
                onSelected: (_) => onSelected(value),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MovieRail extends StatelessWidget {
  const _MovieRail({required this.title, required this.movies});

  final String title;
  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(
            height: 238,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: movies.take(10).length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return MoviePosterRailCard(movie: movies[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverMessage extends StatelessWidget {
  const _DiscoverMessage({
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
