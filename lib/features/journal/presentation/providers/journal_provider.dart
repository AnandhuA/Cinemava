import 'package:flutter/foundation.dart';

import '../../domain/entities/journal_entry.dart';

class JournalProvider extends ChangeNotifier {
  final List<JournalEntry> _entries = [
    JournalEntry(
      movieId: 1,
      movieTitle: 'Midnight Signal',
      note: 'Loved the slow-burn atmosphere and the final reveal.',
      rating: 4.5,
      createdAt: DateTime(2026, 6, 12),
    ),
  ];

  List<JournalEntry> get entries => List.unmodifiable(_entries);

  void addEntry(JournalEntry entry) {
    _entries.insert(0, entry);
    notifyListeners();
  }
}
