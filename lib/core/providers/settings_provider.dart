import 'package:flutter/material.dart';
import 'package:my_app/core/services/settings_service.dart';
import 'package:my_app/core/services/auth_service.dart';

class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  factory SettingsProvider() => _instance;
  SettingsProvider._internal();

  final _settingsService = SettingsService();
  final _authService = AuthService();

  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'en';
  String _currency = '₹';

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  String get currency => _currency;

  Future<void> loadSettings() async {
    final uid = _authService.currentUserId;
    if (uid == null) return;

    final settings = await _settingsService.getSettings(uid);
    
    // Parse Theme
    final themeStr = settings['theme'] ?? 'light';
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }

    _language = settings['language'] ?? 'en';
    _currency = settings['currency'] ?? '₹';
    
    notifyListeners();
  }

  Future<void> updateTheme(String theme) async {
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
    await _saveSetting('theme', theme);
  }

  Future<void> updateLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    await _saveSetting('language', lang);
  }

  Future<void> updateCurrency(String curr) async {
    _currency = curr;
    notifyListeners();
    await _saveSetting('currency', curr);
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final uid = _authService.currentUserId;
    if (uid == null) return;
    
    await _settingsService.saveSettings(uid, {key: value});
  }
}
