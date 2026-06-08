import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-global locale (en/ru), persisted. See commands/02 (Theming).
class LocaleCubit extends Cubit<Locale> {
  static const _key = 'locale';
  final SharedPreferences _prefs;

  LocaleCubit(this._prefs) : super(_load(_prefs));

  static Locale _load(SharedPreferences p) =>
      Locale(p.getString(_key) == 'ru' ? 'ru' : 'en');

  bool get isRu => state.languageCode == 'ru';

  void setRu(bool ru) {
    _prefs.setString(_key, ru ? 'ru' : 'en');
    emit(Locale(ru ? 'ru' : 'en'));
  }
}
