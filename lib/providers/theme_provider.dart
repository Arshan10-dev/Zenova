import 'package:flutter/material.dart';

import '../repository/settings_repository.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsRepository _settings;

  ThemeProvider(this._settings) {
    _themeMode = _parseThemeMode(_settings.themeMode);
    _amoled = _settings.amoledEnabled;
    _accent = Color(_settings.accentColorValue);
  }

  late ThemeMode _themeMode;
  late bool _amoled;
  late Color _accent;

  ThemeMode get themeMode => _themeMode;
  bool get amoledEnabled => _amoled;
  Color get accentColor => _accent;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _settings.setThemeMode(_themeModeToString(mode));
  }

  Future<void> setAmoledEnabled(bool value) async {
    _amoled = value;
    notifyListeners();
    await _settings.setAmoledEnabled(value);
  }

  Future<void> setAccentColor(Color color) async {
    _accent = color;
    notifyListeners();
    await _settings.setAccentColorValue(color.toARGB32());
  }

  ThemeMode _parseThemeMode(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  String _themeModeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
