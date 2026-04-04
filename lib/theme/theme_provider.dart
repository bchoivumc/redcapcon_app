import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  String _currentTheme = 'professional'; // 'classic', 'blue', 'earth', or 'professional'

  String get currentTheme => _currentTheme;
  
  ThemeData get themeData {
    switch (_currentTheme) {
      case 'blue':
        return AppTheme.blueTheme;
      case 'earth':
        return AppTheme.earthTheme;
      case 'professional':
        return AppTheme.professionalTheme;
      default:
        return AppTheme.lightTheme;
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTheme = prefs.getString(_themeKey) ?? 'professional';
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    if (!['classic', 'blue', 'earth', 'professional'].contains(theme)) return;
    
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
    notifyListeners();
  }
}
