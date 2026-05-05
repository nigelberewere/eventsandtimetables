import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;

  ThemeMode get themeMode =>
      _isDark ? ThemeMode.dark : ThemeMode.light;

  //  DARK THEME COLORS
  static const Color darkBg = Color(0xFF1E1E1E); // dark grey background
  static const Color darkSurface = Color(0xFF2A2A2A); // cards
  static const Color darkAccent = Color(0xFF7FB3D5); // brighter blue
  static const Color darkText = Color(0xFFF2F2F2); // readable white text

  Color get bg => darkBg;
  Color get surface => darkSurface;
  Color get text => darkText;

  //  LIGHT THEME COLORS (optional reference)
  static const Color lightBg = Colors.white;

  void toggleTheme(bool value) {
    _isDark = value;
    notifyListeners();
  }

  //  HELPER: BACKGROUND COLOR
  Color get backgroundColor =>
      _isDark ? darkBg : lightBg;

  //  HELPER: SURFACE/CARD COLOR
  Color get surfaceColor =>
      _isDark ? darkSurface : Colors.white;

  // HELPER: PRIMARY ACCENT
  Color get accentColor =>
      _isDark ? darkAccent : const Color(0xFF5E88B0);

  // HELPER: TEXT COLOR
  Color get textColor =>
      _isDark ? darkText : Colors.black;
}