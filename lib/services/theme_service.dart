import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeType {
  light,
  dark,
  system,
}

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _aiPromptKey = 'ai_prompt';
  static const String _aiApiUrlKey = 'ai_api_url';
  static const String _aiApiKeyKey = 'ai_api_key';

  // 单例模式
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeModeType _themeMode = ThemeModeType.system;
  String _aiPrompt = '';
  String _aiApiUrl = '';
  String _aiApiKey = '';
  bool _isInitialized = false;

  ThemeModeType get themeMode => _themeMode;
  String get aiPrompt => _aiPrompt;
  String get aiApiUrl => _aiApiUrl;
  String get aiApiKey => _aiApiKey;

  // 确保只初始化一次
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _loadSettings();
    _isInitialized = true;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 2;
    _themeMode = ThemeModeType.values[themeIndex];
    _aiPrompt = prefs.getString(_aiPromptKey) ?? '';
    _aiApiUrl = prefs.getString(_aiApiUrlKey) ?? '';
    _aiApiKey = prefs.getString(_aiApiKeyKey) ?? '';
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeModeType mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> setAiPrompt(String prompt) async {
    _aiPrompt = prompt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiPromptKey, prompt);
    notifyListeners();
  }

  Future<void> setAiApiConfig(String url, String key) async {
    _aiApiUrl = url;
    _aiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiApiUrlKey, url);
    await prefs.setString(_aiApiKeyKey, key);
    notifyListeners();
  }

  bool get hasAiConfig => _aiApiUrl.isNotEmpty && _aiApiKey.isNotEmpty;

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case ThemeModeType.light:
        return ThemeMode.light;
      case ThemeModeType.dark:
        return ThemeMode.dark;
      case ThemeModeType.system:
        return ThemeMode.system;
    }
  }
}
