import 'package:flutter/material.dart';
import '../models/enums.dart';

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.en;

  AppLanguage get language => _language;

  String get languageCode => _language == AppLanguage.en ? 'EN' : 'VI';

  void toggleLanguage() {
    _language = _language == AppLanguage.en ? AppLanguage.vi : AppLanguage.en;
    notifyListeners();
  }
}

