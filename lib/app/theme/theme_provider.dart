import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._box) {
    _themeMode = _themeModeFromName(
      _box?.get(_themeModeKey, defaultValue: ThemeMode.system.name) as String?,
    );
    _accentColor = Color(
      _box?.get(_accentColorKey, defaultValue: AppColors.primary.toARGB32())
              as int? ??
          AppColors.primary.toARGB32(),
    );
  }

  static const _themeModeKey = 'theme_mode';
  static const _accentColorKey = 'accent_color';

  final Box<dynamic>? _box;
  late ThemeMode _themeMode;
  late Color _accentColor;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _box?.put(_themeModeKey, mode.name);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    if (_accentColor == color) return;
    _accentColor = color;
    await _box?.put(_accentColorKey, color.toARGB32());
    notifyListeners();
  }

  ThemeMode _themeModeFromName(String? name) {
    for (final mode in ThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return ThemeMode.system;
  }
}
