import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../providers/journal_provider.dart';

class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<JournalProvider>().entries;

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
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.movieTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text('${entry.rating.toStringAsFixed(1)} / 5'),
                        const SizedBox(height: 10),
                        Text(entry.note),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
