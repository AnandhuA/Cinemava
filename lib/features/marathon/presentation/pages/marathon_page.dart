import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/marathon_data.dart';

class MarathonPage extends StatelessWidget {
  const MarathonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marathon')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: marathonCollections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final marathon = marathonCollections[index];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.push('/marathon/${marathon.id}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(marathon.accentColor),
                      child: const Icon(
                        Icons.local_movies,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            marathon.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${marathon.subtitle} • TMDb collections',
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
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
