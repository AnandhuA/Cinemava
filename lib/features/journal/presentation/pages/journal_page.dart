import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../domain/entities/journal_entry.dart';
import '../providers/journal_provider.dart';

class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();
    final entries = journal.entries;

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: entries.isEmpty
          ? const AppEmptyState(
              icon: Icons.edit_note,
              title: 'No journal entries',
              message:
                  'Your reviews, ratings, and film memories will live here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) return _JournalSummary(journal: journal);
                final entry = entries[index - 1];
                return _JournalEntryCard(entry: entry);
              },
            ),
    );
  }
}

class _JournalSummary extends StatelessWidget {
  const _JournalSummary({required this.journal});

  final JournalProvider journal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _Metric(
              label: 'Entries',
              value: journal.entries.length.toString(),
              icon: Icons.edit_note_outlined,
            ),
            const SizedBox(width: 12),
            _Metric(
              label: 'Average',
              value: journal.averageRating.toStringAsFixed(1),
              icon: Icons.star_border,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
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

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final movie = context.watch<MovieLibraryProvider>().movieById(
      entry.movieId,
    );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/journal/movie/${entry.movieId}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedAppImage(
                  imageUrl: movie?.posterUrl ?? '',
                  width: 58,
                  height: 86,
                  placeholderIcon: Icons.local_movies_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entry.movieTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              context.read<JournalProvider>().deleteEntry(
                                entry.id,
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.star, size: 18),
                          label: Text('${entry.rating.toStringAsFixed(1)} / 5'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.event_outlined, size: 18),
                          label: Text(_formatDate(entry.watchedAt)),
                        ),
                      ],
                    ),
                    if (entry.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.note,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
