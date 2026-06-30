import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../onboarding/presentation/providers/user_preference_provider.dart';

class PreferenceSettingsPage extends StatelessWidget {
  const PreferenceSettingsPage({super.key});

  static const _genres = [
    'Action',
    'Comedy',
    'Crime',
    'Drama',
    'Indie',
    'Music',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Thriller',
  ];

  static const _languages = [
    'English',
    'Hindi',
    'Malayalam',
    'Tamil',
    'Telugu',
    'Kannada',
  ];

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UserPreferenceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Taste setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Genres',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _ChoiceWrap(
            values: _genres,
            selectedValues: preferences.selectedGenres,
            onSelected: context.read<UserPreferenceProvider>().toggleGenre,
          ),
          const SizedBox(height: 28),
          Text(
            'Languages',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _ChoiceWrap(
            values: _languages,
            selectedValues: preferences.selectedLanguages,
            onSelected: context.read<UserPreferenceProvider>().toggleLanguage,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: preferences.canContinue
                ? () async {
                    await context
                        .read<UserPreferenceProvider>()
                        .savePreferences();
                    if (context.mounted) context.pop();
                  }
                : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save preferences'),
          ),
        ],
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selectedValues,
    required this.onSelected,
  });

  final List<String> values;
  final Set<String> selectedValues;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final value in values)
          FilterChip(
            label: Text(value),
            selected: selectedValues.contains(value),
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}
