import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/marathon_provider.dart';

enum _MarathonFilter { all, custom, builtIn }

class MarathonPage extends StatefulWidget {
  const MarathonPage({super.key});

  @override
  State<MarathonPage> createState() => _MarathonPageState();
}

class _MarathonPageState extends State<MarathonPage> {
  _MarathonFilter _filter = _MarathonFilter.all;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarathonProvider>();
    final allMarathons = provider.allMarathons;
    final customCount = provider.customMarathons.length;
    final builtInCount = allMarathons.length - customCount;
    final marathons = switch (_filter) {
      _MarathonFilter.all => allMarathons,
      _MarathonFilter.custom =>
        allMarathons.where((marathon) => marathon.isUserCreated).toList(),
      _MarathonFilter.builtIn =>
        allMarathons.where((marathon) => !marathon.isUserCreated).toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('LineUp'),
        actions: [
          IconButton(
            tooltip: 'Add LineUp',
            onPressed: () => context.push('/marathon/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/marathon/new'),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: marathons.length + 2,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) return const _MarathonIntro();
          if (index == 1) {
            return _MarathonFilterTabs(
              selected: _filter,
              totalCount: allMarathons.length,
              customCount: customCount,
              builtInCount: builtInCount,
              onChanged: (value) => setState(() => _filter = value),
            );
          }

          final marathon = marathons[index - 2];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () =>
                  context.push('/marathon/${marathon.id}', extra: marathon),
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
                            marathon.isUserCreated
                                ? '${marathon.subtitle} • Custom LineUp'
                                : '${marathon.subtitle} • TMDb collections',
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

class _MarathonFilterTabs extends StatelessWidget {
  const _MarathonFilterTabs({
    required this.selected,
    required this.totalCount,
    required this.customCount,
    required this.builtInCount,
    required this.onChanged,
  });

  final _MarathonFilter selected;
  final int totalCount;
  final int customCount;
  final int builtInCount;
  final ValueChanged<_MarathonFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_MarathonFilter>(
      segments: [
        ButtonSegment(
          value: _MarathonFilter.all,
          icon: const Icon(Icons.grid_view_rounded),
          label: Text('All $totalCount'),
        ),
        ButtonSegment(
          value: _MarathonFilter.custom,
          icon: const Icon(Icons.person_outline),
          label: Text('User $customCount'),
        ),
        ButtonSegment(
          value: _MarathonFilter.builtIn,
          icon: const Icon(Icons.cloud_outlined),
          label: Text('Built-in $builtInCount'),
        ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class _MarathonIntro extends StatelessWidget {
  const _MarathonIntro();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.16),
              child: Icon(
                Icons.playlist_add,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Create your own LineUp using TMDb collections or hand-picked movies.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
