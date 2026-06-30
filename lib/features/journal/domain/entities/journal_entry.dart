class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.note,
    required this.rating,
    required this.watchedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int movieId;
  final String movieTitle;
  final String note;
  final double rating;
  final DateTime watchedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry copyWith({
    String? id,
    int? movieId,
    String? movieTitle,
    String? note,
    double? rating,
    DateTime? watchedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      movieTitle: movieTitle ?? this.movieTitle,
      note: note ?? this.note,
      rating: rating ?? this.rating,
      watchedAt: watchedAt ?? this.watchedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
