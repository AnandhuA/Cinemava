import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/user_preference_provider.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.movie_filter_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Tune Cinemava to your taste.',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'Pick what you like now. Cinemava will save it locally and use it for better suggestions next time.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            _ChoiceGroup(
              title: 'Genres you like',
              values: _genres,
              selectedValues: preferences.selectedGenres,
              onSelected: context.read<UserPreferenceProvider>().toggleGenre,
            ),
            const SizedBox(height: 28),
            _ChoiceGroup(
              title: 'Languages you watch',
              values: _languages,
              selectedValues: preferences.selectedLanguages,
              onSelected: context.read<UserPreferenceProvider>().toggleLanguage,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: preferences.canContinue
                  ? () async {
                      await context
                          .read<UserPreferenceProvider>()
                          .savePreferences();
                      if (context.mounted) context.go('/login');
                    }
                  : null,
              child: const Text('Save and continue'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await context.read<UserPreferenceProvider>().savePreferences();
                if (context.mounted) context.go('/');
              },
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.title,
    required this.values,
    required this.selectedValues,
    required this.onSelected,
  });

  final String title;
  final List<String> values;
  final Set<String> selectedValues;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
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
        ),
      ],
    );
  }
}
