import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale_code';

/// Drives [MaterialApp.locale] so Language settings apply without a full app rewrite.
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

/// Call after [SharedPreferences] is ready (e.g. from [initInjection]).
Future<void> loadSavedAppLocale(SharedPreferences prefs) async {
  final code = prefs.getString(_kLocaleKey);
  if (code == 'hi') {
    appLocale.value = const Locale('hi');
  } else {
    appLocale.value = const Locale('en');
  }
}

/// Persists and applies locale (Hindi or English for now).
Future<void> setAppLocale(SharedPreferences prefs, Locale locale) async {
  appLocale.value = locale;
  await prefs.setString(_kLocaleKey, locale.languageCode);
}
