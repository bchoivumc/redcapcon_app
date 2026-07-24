import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeFormatProvider extends ChangeNotifier {
  static const _key = 'time_format';
  bool _use12h = true;

  bool get use12h => _use12h;

  TimeFormatProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _use12h = (prefs.getString(_key) ?? '12h') == '12h';
    notifyListeners();
  }

  Future<void> setFormat(bool use12h) async {
    _use12h = use12h;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, use12h ? '12h' : '24h');
    notifyListeners();
  }
}
