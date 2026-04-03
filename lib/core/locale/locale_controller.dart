import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const _prefKey = 'app_language_code';

  String _languageCode = 'en';

  String get languageCode => _languageCode;

  Locale get locale => Locale(_languageCode);

  bool get isSpanish => _languageCode == 'es';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getString(_prefKey) ?? '').trim().toLowerCase();

    if (saved == 'es' || saved == 'en') {
      _languageCode = saved;
      return;
    }

    final deviceCode = PlatformDispatcher.instance.locale.languageCode
        .trim()
        .toLowerCase();
    _languageCode = deviceCode.startsWith('es') ? 'es' : 'en';
  }

  Future<void> setLanguageCode(String code) async {
    final next = code.trim().toLowerCase();
    if (next != 'es' && next != 'en') return;
    if (next == _languageCode) return;

    _languageCode = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _languageCode);
    notifyListeners();
  }
}
