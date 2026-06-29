import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Theme mode',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.phone_android),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {themeProvider.themeMode},
            onSelectionChanged: (selection) =>
                themeProvider.setThemeMode(selection.first),
          ),
          const SizedBox(height: 24),
          Text(
            'Accent color',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: const [
              _AccentButton(color: AppColors.primary),
              _AccentButton(color: Color(0xFF1DB954)),
              _AccentButton(color: Color(0xFF4F8CFF)),
              _AccentButton(color: Color(0xFFFFB020)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccentButton extends StatelessWidget {
  const _AccentButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ThemeProvider>().accentColor == color;

    return IconButton.filled(
      style: IconButton.styleFrom(backgroundColor: color),
      onPressed: () => context.read<ThemeProvider>().setAccentColor(color),
      icon: Icon(selected ? Icons.check : Icons.circle, color: Colors.white),
      tooltip: 'Set accent color',
    );
  }
}
