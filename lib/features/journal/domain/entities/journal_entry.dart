class JournalEntry {
  const JournalEntry({
    required this.movieId,
    required this.movieTitle,
    required this.note,
    required this.rating,
    required this.createdAt,
  });

  final int movieId;
  final String movieTitle;
  final String note;
  final double rating;
  final DateTime createdAt;
}
