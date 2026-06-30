import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/journal_entry.dart';

class JournalProvider extends ChangeNotifier {
  static const _entriesKey = 'entries';

  JournalProvider(this._box) {
    _entries.addAll(_readSavedEntries());
  }

  final Box<dynamic>? _box;
  final List<JournalEntry> _entries = [];

  List<JournalEntry> get entries => List.unmodifiable(_entries);

  double get averageRating {
    if (_entries.isEmpty) return 0;
    final total = _entries.fold<double>(0, (sum, entry) => sum + entry.rating);
    return total / _entries.length;
  }

  JournalEntry? entryForMovie(int movieId) {
    for (final entry in _entries) {
      if (entry.movieId == movieId) return entry;
    }
    return null;
  }

  void saveEntry({
    required int movieId,
    required String movieTitle,
    required String note,
    required double rating,
    required DateTime watchedAt,
  }) {
    final now = DateTime.now();
    final existingIndex = _entries.indexWhere(
      (entry) => entry.movieId == movieId,
    );

    if (existingIndex == -1) {
      _entries.insert(
        0,
        JournalEntry(
          id: '$movieId-${now.microsecondsSinceEpoch}',
          movieId: movieId,
          movieTitle: movieTitle,
          note: note.trim(),
          rating: rating,
          watchedAt: watchedAt,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      final existing = _entries.removeAt(existingIndex);
      _entries.insert(
        0,
        existing.copyWith(
          movieTitle: movieTitle,
          note: note.trim(),
          rating: rating,
          watchedAt: watchedAt,
          updatedAt: now,
        ),
      );
    }

    _save();
    notifyListeners();
  }

  void deleteEntry(String id) {
    _entries.removeWhere((entry) => entry.id == id);
    _save();
    notifyListeners();
  }

  List<JournalEntry> _readSavedEntries() {
    final saved = _box?.get(_entriesKey);
    if (saved is! List) return const [];

    final entries =
        saved
            .whereType<Map>()
            .map(_entryFromMap)
            .where((entry) => entry.movieId != 0)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entries;
  }

  JournalEntry _entryFromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now();
    final movieId = map['movieId'] as int? ?? 0;
    return JournalEntry(
      id: map['id'] as String? ?? '$movieId-${now.microsecondsSinceEpoch}',
      movieId: movieId,
      movieTitle: map['movieTitle'] as String? ?? 'Untitled',
      note: map['note'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      watchedAt: _dateFromMap(map['watchedAt']) ?? now,
      createdAt: _dateFromMap(map['createdAt']) ?? now,
      updatedAt: _dateFromMap(map['updatedAt']) ?? now,
    );
  }

  DateTime? _dateFromMap(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '');
  }

  Future<void> _save() async {
    await _box?.put(
      _entriesKey,
      _entries.map((entry) {
        return {
          'id': entry.id,
          'movieId': entry.movieId,
          'movieTitle': entry.movieTitle,
          'note': entry.note,
          'rating': entry.rating,
          'watchedAt': entry.watchedAt.toIso8601String(),
          'createdAt': entry.createdAt.toIso8601String(),
          'updatedAt': entry.updatedAt.toIso8601String(),
        };
      }).toList(),
    );
  }
}
