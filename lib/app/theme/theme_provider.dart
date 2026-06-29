import 'package:flutter/material.dart';

import 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = AppColors.primary;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void setAccentColor(Color color) {
    if (_accentColor == color) return;
    _accentColor = color;
    notifyListeners();
  }
}
