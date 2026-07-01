import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/cached_app_image.dart';
import '../../../movies/domain/entities/movie.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../data/marathon_data.dart';
import '../providers/marathon_provider.dart';

class MarathonEditorPage extends StatefulWidget {
  const MarathonEditorPage({super.key, this.marathon});

  final MarathonCollection? marathon;

  @override
  State<MarathonEditorPage> createState() => _MarathonEditorPageState();
}

class _MarathonEditorPageState extends State<MarathonEditorPage> {
  static const _accentColors = [
    0xFFE53935,
    0xFF5E35B1,
    0xFF1565C0,
    0xFF00897B,
    0xFF2E7D32,
    0xFFFB8C00,
    0xFF546E7A,
    0xFFD81B60,
  ];
  static const _collectionSuggestions = [
    'Alien Collection',
    'Avatar Collection',
    'Batman Collection',
    'Blade Runner Collection',
    'Deadpool Collection',
    'Die Hard Collection',
    'Indiana Jones Collection',
    'James Bond Collection',
    'John Wick Collection',
    'Mad Max Collection',
    'Mission: Impossible Collection',
    'Pirates of the Caribbean Collection',
    'Planet of the Apes Collection',
    'Predator Collection',
    'Rocky Collection',
    'Spider-Man Collection',
    'Star Trek Collection',
    'Star Wars Collection',
    'Terminator Collection',
    'The Dark Knight Collection',
    'The Matrix Collection',
    'Toy Story Collection',
    'Transformers Collection',
    'X-Men Collection',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _queryController = TextEditingController();
  final _movieSearchController = TextEditingController();
  final List<String> _collectionQueries = [];
  final List<Movie> _manualMovies = [];
  int _accentColor = _accentColors.first;

  bool get _isEditing => widget.marathon != null;

  @override
  void initState() {
    super.initState();
    final marathon = widget.marathon;
    if (marathon == null) return;
    _titleController.text = marathon.title;
    _subtitleController.text = marathon.subtitle;
    _descriptionController.text = marathon.description;
    _collectionQueries.addAll(marathon.collectionQueries);
    _manualMovies.addAll(marathon.manualMovies);
    _accentColor = marathon.accentColor;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _queryController.dispose();
    _movieSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuggestions = _filteredSuggestions;
    final movieSuggestions = _movieSuggestions(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit LineUp' : 'New LineUp')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _EditorHeader(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'LineUp name',
                hintText: 'Example: Alien Saga',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Add a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subtitleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Short subtitle',
                hintText: 'Example: Main films and spin-offs',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What order should this LineUp cover?',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: 'Collections',
              subtitle:
                  'Filter official TMDb collection names or type your own.',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _queryController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Filter or type collection',
                hintText: 'Example: Alien Collection',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _addCollectionQuery(),
            ),
            const SizedBox(height: 12),
            if (_collectionQueries.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final query in _collectionQueries)
                    InputChip(
                      avatar: const Icon(Icons.movie_filter_outlined),
                      label: Text(query),
                      onDeleted: () =>
                          setState(() => _collectionQueries.remove(query)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (filteredSuggestions.isEmpty)
              const _InlineHint(
                icon: Icons.keyboard_return,
                text:
                    'Press done on the keyboard to add this collection, or save to use it.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final suggestion in filteredSuggestions)
                    FilterChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: Text(suggestion),
                      selected: _collectionQueries.contains(suggestion),
                      onSelected: (_) => _toggleCollectionQuery(suggestion),
                    ),
                ],
              ),
            if (_collectionQueries.isEmpty) ...[
              const SizedBox(height: 10),
              const _InlineHint(
                icon: Icons.info_outline,
                text:
                    'Choose collections, individual movies, or both before saving.',
              ),
            ],
            const SizedBox(height: 22),
            const _SectionTitle(
              title: 'Add movies one by one',
              subtitle: 'Search loaded movies, add them, then drag to reorder.',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _movieSearchController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Find movie',
                hintText: 'Example: Iron Man',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (movieSuggestions.isEmpty)
              const _InlineHint(
                icon: Icons.movie_outlined,
                text:
                    'Loaded movies will appear here. Use Discover/Home first if the movie is not loaded.',
              )
            else
              SizedBox(
                height: 122,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: movieSuggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final movie = movieSuggestions[index];
                    return _MovieSuggestionCard(
                      movie: movie,
                      onAdd: () => _addManualMovie(movie),
                    );
                  },
                ),
              ),
            if (_manualMovies.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Custom order',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _manualMovies.length,
                onReorderItem: _reorderManualMovies,
                itemBuilder: (context, index) {
                  final movie = _manualMovies[index];
                  return _ManualMovieTile(
                    key: ValueKey(movie.id),
                    index: index,
                    movie: movie,
                    onRemove: () => setState(() {
                      _manualMovies.removeAt(index);
                    }),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            const _SectionTitle(
              title: 'Color',
              subtitle: 'Pick the accent used on the LineUp card.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in _accentColors)
                  _ColorDot(
                    color: Color(color),
                    selected: _accentColor == color,
                    onTap: () => setState(() => _accentColor = color),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Update LineUp' : 'Save LineUp'),
            ),
          ],
        ),
      ),
    );
  }

  List<Movie> _movieSuggestions(BuildContext context) {
    final library = context.watch<MovieLibraryProvider>();
    final query = _movieSearchController.text.trim().toLowerCase();
    final selectedIds = _manualMovies.map((movie) => movie.id).toSet();
    final source = library.availableMovies
        .where((movie) => !selectedIds.contains(movie.id))
        .toList();
    final filtered = query.isEmpty
        ? source
        : source.where((movie) {
            final titleMatch = movie.title.toLowerCase().contains(query);
            final genreMatch = movie.genres.any(
              (genre) => genre.toLowerCase().contains(query),
            );
            final languageMatch = movie.language.toLowerCase().contains(query);
            return titleMatch || genreMatch || languageMatch;
          }).toList();
    filtered.sort((a, b) => b.rating.compareTo(a.rating));
    return filtered.take(12).toList();
  }

  List<String> get _filteredSuggestions {
    final query = _queryController.text.trim().toLowerCase();
    final source = _collectionSuggestions.where(
      (suggestion) => !_collectionQueries.contains(suggestion),
    );
    if (query.isEmpty) return source.take(8).toList();
    return source
        .where((suggestion) => suggestion.toLowerCase().contains(query))
        .take(8)
        .toList();
  }

  void _addCollectionQuery() {
    final query = _queryController.text.trim();
    if (query.isEmpty || _collectionQueries.contains(query)) return;
    setState(() {
      _collectionQueries.add(query);
      _queryController.clear();
    });
  }

  void _toggleCollectionQuery(String query) {
    setState(() {
      if (!_collectionQueries.remove(query)) {
        _collectionQueries.add(query);
      }
      _queryController.clear();
    });
  }

  void _addManualMovie(Movie movie) {
    if (_manualMovies.any((item) => item.id == movie.id)) return;
    setState(() {
      _manualMovies.add(movie);
      _movieSearchController.clear();
    });
  }

  void _reorderManualMovies(int oldIndex, int newIndex) {
    setState(() {
      final movie = _manualMovies.removeAt(oldIndex);
      _manualMovies.insert(newIndex, movie);
    });
  }

  void _save() {
    _addCollectionQuery();
    if (_formKey.currentState?.validate() != true) return;
    if (_collectionQueries.isEmpty && _manualMovies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one collection or movie.')),
      );
      return;
    }

    final provider = context.read<MarathonProvider>();
    final marathon = widget.marathon;
    if (marathon == null) {
      provider.addMarathon(
        title: _titleController.text,
        subtitle: _subtitleController.text,
        description: _descriptionController.text,
        accentColor: _accentColor,
        collectionQueries: _collectionQueries,
        manualMovies: _manualMovies,
      );
    } else {
      provider.updateMarathon(
        id: marathon.id,
        title: _titleController.text,
        subtitle: _subtitleController.text,
        description: _descriptionController.text,
        accentColor: _accentColor,
        collectionQueries: _collectionQueries,
        manualMovies: _manualMovies,
      );
    }
    context.pop();
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.16),
              child: Icon(
                Icons.movie_filter_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build a watch order',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cinemava will load the selected TMDb collections and movies in your order.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _MovieSuggestionCard extends StatelessWidget {
  const _MovieSuggestionCard({required this.movie, required this.onAdd});

  final Movie movie;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedAppImage(
                  imageUrl: movie.posterUrl,
                  width: 52,
                  height: 78,
                  placeholderIcon: Icons.local_movies_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${movie.year} • ${movie.rating.toStringAsFixed(1)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filledTonal(
                        tooltip: 'Add movie',
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualMovieTile extends StatelessWidget {
  const _ManualMovieTile({
    super.key,
    required this.index,
    required this.movie,
    required this.onRemove,
  });

  final int index;
  final Movie movie;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(
          movie.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${movie.year} • ${movie.language}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
