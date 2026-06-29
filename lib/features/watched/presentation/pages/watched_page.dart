import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../movies/presentation/widgets/movie_grid.dart';

class WatchedPage extends StatelessWidget {
  const WatchedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final movies = context.watch<MovieLibraryProvider>().watched;

    return Scaffold(
      appBar: AppBar(title: const Text('Watched')),
      body: movies.isEmpty
          ? const AppEmptyState(
              icon: Icons.visibility_outlined,
              title: 'Nothing watched yet',
              message: 'Mark movies as watched to build your personal history.',
            )
          : MovieGrid(movies: movies),
    );
  }
}
