import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../movies/presentation/widgets/movie_grid.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final movies = context.watch<MovieLibraryProvider>().watchlist;

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: movies.isEmpty
          ? const AppEmptyState(
              icon: Icons.bookmark_border,
              title: 'No saved movies yet',
              message: 'Add movies from details and they will appear here.',
            )
          : MovieGrid(movies: movies),
    );
  }
}
