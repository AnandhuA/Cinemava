import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class UserPreferenceProvider extends ChangeNotifier {
  UserPreferenceProvider(this._box) {
    _displayName =
        _box?.get(_displayNameKey, defaultValue: '') as String? ?? '';
    _selectedGenres = Set<String>.from(
      (_box?.get(_genresKey, defaultValue: <String>[]) as List).cast<String>(),
    );
    _selectedLanguages = Set<String>.from(
      (_box?.get(_languagesKey, defaultValue: <String>[]) as List)
          .cast<String>(),
    );
    _isOnboardingComplete =
        _box?.get(_onboardingCompleteKey, defaultValue: false) as bool? ??
        false;
  }

  static const _genresKey = 'favorite_genres';
  static const _languagesKey = 'favorite_languages';
  static const _displayNameKey = 'display_name';
  static const _onboardingCompleteKey = 'onboarding_complete';

  final Box<dynamic>? _box;
  String _displayName = '';
  Set<String> _selectedGenres = {};
  Set<String> _selectedLanguages = {};
  bool _isOnboardingComplete = false;

  String get displayName => _displayName;
  Set<String> get selectedGenres => Set.unmodifiable(_selectedGenres);
  Set<String> get selectedLanguages => Set.unmodifiable(_selectedLanguages);
  bool get isOnboardingComplete => _isOnboardingComplete;
  bool get canContinue =>
      _displayName.trim().isNotEmpty &&
      _selectedGenres.isNotEmpty &&
      _selectedLanguages.isNotEmpty;

  void setDisplayName(String value) {
    _displayName = value;
    notifyListeners();
  }

  void toggleGenre(String genre) {
    if (!_selectedGenres.add(genre)) {
      _selectedGenres.remove(genre);
    }
    notifyListeners();
  }

  void toggleLanguage(String language) {
    if (!_selectedLanguages.add(language)) {
      _selectedLanguages.remove(language);
    }
    notifyListeners();
  }

  Future<void> savePreferences() async {
    _isOnboardingComplete = true;
    await _box?.put(_displayNameKey, _displayName.trim());
    await _box?.put(_genresKey, _selectedGenres.toList());
    await _box?.put(_languagesKey, _selectedLanguages.toList());
    await _box?.put(_onboardingCompleteKey, true);
    notifyListeners();
  }
}
