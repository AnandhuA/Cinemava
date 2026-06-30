import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/user_preference_provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
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

  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final preferences = context.read<UserPreferenceProvider>();
    _nameController = TextEditingController(text: preferences.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UserPreferenceProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 18),
            Icon(
              Icons.movie_filter_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 22),
            Text(
              'Set up your movie space.',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              'Tell Cinemava your name and interests. Your setup stays local and shapes Home, Discover, and recommendations.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              onChanged: context.read<UserPreferenceProvider>().setDisplayName,
              decoration: const InputDecoration(
                labelText: 'Your name',
                hintText: 'Example: Arjun',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 28),
            _ChoiceGroup(
              title: 'Choose interests',
              values: _genres,
              selectedValues: preferences.selectedGenres,
              onSelected: context.read<UserPreferenceProvider>().toggleGenre,
            ),
            const SizedBox(height: 28),
            _ChoiceGroup(
              title: 'Choose languages',
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
                      if (context.mounted) context.go('/');
                    }
                  : null,
              icon: const Icon(Icons.home_outlined),
              label: const Text('Save and go home'),
            ),
            const SizedBox(height: 12),
            Text(
              'Name, one interest, and one language are required.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
