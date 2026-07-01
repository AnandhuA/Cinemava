import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../data/marathon_data.dart';

class MarathonProvider extends ChangeNotifier {
  static const _marathonsKey = 'marathons';

  MarathonProvider(this._box) {
    _customMarathons.addAll(_readSavedMarathons());
  }

  final Box<dynamic>? _box;
  final List<MarathonCollection> _customMarathons = [];

  List<MarathonCollection> get customMarathons =>
      List.unmodifiable(_customMarathons);

  List<MarathonCollection> get allMarathons =>
      List.unmodifiable([..._customMarathons, ...marathonCollections]);

  MarathonCollection? marathonById(String id) {
    for (final marathon in allMarathons) {
      if (marathon.id == id) return marathon;
    }
    return null;
  }

  void addMarathon({
    required String title,
    required String subtitle,
    required String description,
    required int accentColor,
    required List<String> collectionQueries,
  }) {
    final normalizedQueries = collectionQueries
        .map((query) => query.trim())
        .where((query) => query.isNotEmpty)
        .toSet()
        .toList();
    if (title.trim().isEmpty || normalizedQueries.isEmpty) return;

    _customMarathons.insert(
      0,
      MarathonCollection(
        id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
        title: title.trim(),
        subtitle: subtitle.trim().isEmpty ? 'Custom marathon' : subtitle.trim(),
        description: description.trim().isEmpty
            ? 'A custom release-order marathon from TMDb collections.'
            : description.trim(),
        accentColor: accentColor,
        collectionQueries: normalizedQueries,
        isUserCreated: true,
      ),
    );
    _save();
    notifyListeners();
  }

  void updateMarathon({
    required String id,
    required String title,
    required String subtitle,
    required String description,
    required int accentColor,
    required List<String> collectionQueries,
  }) {
    final index = _customMarathons.indexWhere((marathon) => marathon.id == id);
    if (index == -1) return;

    final normalizedQueries = collectionQueries
        .map((query) => query.trim())
        .where((query) => query.isNotEmpty)
        .toSet()
        .toList();
    if (title.trim().isEmpty || normalizedQueries.isEmpty) return;

    _customMarathons[index] = MarathonCollection(
      id: id,
      title: title.trim(),
      subtitle: subtitle.trim().isEmpty ? 'Custom marathon' : subtitle.trim(),
      description: description.trim().isEmpty
          ? 'A custom release-order marathon from TMDb collections.'
          : description.trim(),
      accentColor: accentColor,
      collectionQueries: normalizedQueries,
      isUserCreated: true,
    );
    _save();
    notifyListeners();
  }

  void deleteMarathon(String id) {
    _customMarathons.removeWhere((marathon) => marathon.id == id);
    _save();
    notifyListeners();
  }

  List<MarathonCollection> _readSavedMarathons() {
    final saved = _box?.get(_marathonsKey);
    if (saved is! List) return const [];

    return saved
        .whereType<Map>()
        .map(_marathonFromMap)
        .where((marathon) => marathon.collectionQueries.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    await _box?.put(
      _marathonsKey,
      _customMarathons.map(_marathonToMap).toList(),
    );
  }

  MarathonCollection _marathonFromMap(Map<dynamic, dynamic> map) {
    return MarathonCollection(
      id:
          map['id'] as String? ??
          'custom-${DateTime.now().microsecondsSinceEpoch}',
      title: map['title'] as String? ?? 'Custom Marathon',
      subtitle: map['subtitle'] as String? ?? 'Custom marathon',
      description:
          map['description'] as String? ??
          'A custom release-order marathon from TMDb collections.',
      accentColor: map['accentColor'] as int? ?? 0xFFE53935,
      collectionQueries: ((map['collectionQueries'] as List?) ?? const [])
          .map((value) => value.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList(),
      isUserCreated: true,
    );
  }

  Map<String, dynamic> _marathonToMap(MarathonCollection marathon) {
    return {
      'id': marathon.id,
      'title': marathon.title,
      'subtitle': marathon.subtitle,
      'description': marathon.description,
      'accentColor': marathon.accentColor,
      'collectionQueries': marathon.collectionQueries,
    };
  }
}
