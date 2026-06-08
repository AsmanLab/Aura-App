import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-global theme mode, persisted. Default light. See commands/02 (Theming).
class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = 'themeMode';
  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_load(_prefs));

  static ThemeMode _load(SharedPreferences p) =>
      p.getString(_key) == 'dark' ? ThemeMode.dark : ThemeMode.light;

  bool get isDark => state == ThemeMode.dark;

  void setDark(bool dark) {
    final mode = dark ? ThemeMode.dark : ThemeMode.light;
    _prefs.setString(_key, dark ? 'dark' : 'light');
    emit(mode);
  }
}
