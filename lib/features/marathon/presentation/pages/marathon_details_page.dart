import 'package:flutter/material.dart';

import '../../data/marathon_data.dart';

class MarathonDetailsPage extends StatelessWidget {
  const MarathonDetailsPage({super.key, required this.marathon});

  final MarathonCollection? marathon;

  @override
  Widget build(BuildContext context) {
    final marathon = this.marathon;
    if (marathon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Release order')),
        body: const Center(child: Text('Marathon not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(marathon.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(marathon.accentColor).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(marathon.accentColor).withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    marathon.subtitle,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Color(marathon.accentColor),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    marathon.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.movie_outlined, size: 18),
                        label: Text('${marathon.items.length} movies'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.schedule, size: 18),
                        label: Text(
                          _formatRuntime(marathon.totalRuntimeMinutes),
                        ),
                      ),
                      const Chip(
                        avatar: Icon(Icons.event_available_outlined, size: 18),
                        label: Text('Release order'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Release Order',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < marathon.items.length; index++)
            _WatchOrderTile(
              index: index + 1,
              item: marathon.items[index],
              accentColor: Color(marathon.accentColor),
              isLast: index == marathon.items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _WatchOrderTile extends StatelessWidget {
  const _WatchOrderTile({
    required this.index,
    required this.item,
    required this.accentColor,
    required this.isLast,
  });

  final int index;
  final MarathonItem item;
  final Color accentColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.releaseDate} • ${_formatRuntime(item.runtimeMinutes)}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.note,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRuntime(int minutes) {
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours == 0) return '${remainingMinutes}m';
  if (remainingMinutes == 0) return '${hours}h';
  return '${hours}h ${remainingMinutes}m';
}
