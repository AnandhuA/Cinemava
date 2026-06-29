import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../movies/presentation/widgets/movie_grid.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieLibraryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: context.read<MovieLibraryProvider>().setQuery,
              decoration: const InputDecoration(
                hintText: 'Search movies, genres...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          if (provider.isSearching)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          Expanded(
            child: provider.errorMessage != null && provider.movies.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : MovieGrid(movies: provider.searchResults),
          ),
        ],
      ),
    );
  }
}
