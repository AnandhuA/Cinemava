import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../../../onboarding/presentation/providers/user_preference_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final movieProvider = context.watch<MovieLibraryProvider>();
    final preferences = context.watch<UserPreferenceProvider>();
    final displayName = preferences.displayName.trim().isEmpty
        ? 'Cinephile'
        : preferences.displayName.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Local Cinemava profile',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taste setup',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PreferenceSummary(
                    title: 'Genres',
                    values: preferences.selectedGenres,
                  ),
                  const SizedBox(height: 8),
                  _PreferenceSummary(
                    title: 'Languages',
                    values: preferences.selectedLanguages,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/preferences'),
                    icon: const Icon(Icons.tune),
                    label: const Text('Edit setup'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: movieProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            title: const Text('Refresh movies'),
            subtitle: const Text('Reload TMDb and cached sections'),
            onTap: movieProvider.isLoading
                ? null
                : () async {
                    await context
                        .read<MovieLibraryProvider>()
                        .loadInitialMovies();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Movies refreshed.')),
                      );
                    }
                  },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('Watchlist'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/watchlist'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note_outlined),
            title: const Text('Journal'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/journal'),
          ),
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text('Watched movies'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/watched'),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Statistics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/statistics'),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSummary extends StatelessWidget {
  const _PreferenceSummary({required this.title, required this.values});

  final String title;
  final Set<String> values;

  @override
  Widget build(BuildContext context) {
    final display = values.isEmpty ? 'Not selected' : values.join(', ');
    return Text(
      '$title: $display',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
