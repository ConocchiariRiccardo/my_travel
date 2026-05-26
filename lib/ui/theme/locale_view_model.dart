import 'package:flutter/material.dart';

class LocaleViewModel extends ChangeNotifier {
  Locale _locale = const Locale('it', 'IT');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
