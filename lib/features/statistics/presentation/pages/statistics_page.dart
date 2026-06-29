import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../journal/presentation/providers/journal_provider.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final movies = context.watch<MovieLibraryProvider>();
    final journal = context.watch<JournalProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: GridView(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisExtent: 140,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        children: [
          _StatCard(
            label: 'Watchlist',
            value: movies.watchlist.length.toString(),
            icon: Icons.bookmark,
          ),
          _StatCard(
            label: 'Watched',
            value: movies.watched.length.toString(),
            icon: Icons.visibility,
          ),
          _StatCard(
            label: 'Journal entries',
            value: journal.entries.length.toString(),
            icon: Icons.edit_note,
          ),
          _StatCard(
            label: 'Avg rating',
            value: journal.entries.isEmpty ? '-' : '4.5',
            icon: Icons.star,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
