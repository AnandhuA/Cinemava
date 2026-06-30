import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/cached_app_image.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../providers/journal_provider.dart';

class JournalEditorPage extends StatefulWidget {
  const JournalEditorPage({super.key, required this.movieId});

  final int movieId;

  @override
  State<JournalEditorPage> createState() => _JournalEditorPageState();
}

class _JournalEditorPageState extends State<JournalEditorPage> {
  late final TextEditingController _noteController;
  double _rating = 4;
  DateTime _watchedAt = DateTime.now();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final entry = context.read<JournalProvider>().entryForMovie(widget.movieId);
    if (entry != null) {
      _noteController.text = entry.note;
      _rating = entry.rating;
      _watchedAt = entry.watchedAt;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movie = context.watch<MovieLibraryProvider>().movieById(
      widget.movieId,
    );
    final entry = context.watch<JournalProvider>().entryForMovie(
      widget.movieId,
    );

    if (movie == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Journal')),
        body: const Center(child: Text('Movie not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(entry == null ? 'New journal' : 'Edit journal'),
        actions: [
          if (entry != null)
            IconButton(
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(entry.id),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedAppImage(
                  imageUrl: movie.posterUrl,
                  width: 92,
                  height: 138,
                  placeholderIcon: Icons.local_movies_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${movie.year} • ${movie.language}'),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _pickWatchedDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Text('Watched ${_formatDate(_watchedAt)}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Your rating',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                _rating.toStringAsFixed(1),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Expanded(
                child: Slider(
                  value: _rating,
                  min: 0.5,
                  max: 5,
                  divisions: 9,
                  label: _rating.toStringAsFixed(1),
                  onChanged: (value) => setState(() => _rating = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            minLines: 7,
            maxLines: 12,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Review notes',
              hintText: 'What did you think about this movie?',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(entry == null ? 'Save journal' : 'Update journal'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickWatchedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _watchedAt,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _watchedAt = picked);
  }

  void _save() {
    final movie = context.read<MovieLibraryProvider>().movieById(
      widget.movieId,
    );
    if (movie == null) return;

    context.read<JournalProvider>().saveEntry(
      movieId: movie.id,
      movieTitle: movie.title,
      note: _noteController.text,
      rating: _rating,
      watchedAt: _watchedAt,
    );
    context.read<MovieLibraryProvider>().markWatched(movie.id);
    context.pop();
  }

  Future<void> _confirmDelete(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete journal?'),
          content: const Text('This review will be removed from your journal.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    context.read<JournalProvider>().deleteEntry(entryId);
    context.pop();
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
