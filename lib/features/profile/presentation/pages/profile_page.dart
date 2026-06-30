import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                          'Guest Cinephile',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Local MVP profile',
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
