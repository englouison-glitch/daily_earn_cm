import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AppLocalization {
  final Locale locale;
  AppLocalization(this.locale);

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization)!;
  }

  Map<String, String> _translations = {};

  Future<void> loadLanguage() async {
    String jsonContent = await rootBundle.loadString(
      'assets/locale/${locale.languageCode}.json'
    );
    Map decoded = json.decode(jsonContent);
    _translations = decoded.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  String translate(String key) {
    return _translations[key] ?? key;
  }

  static const LocalizationsDelegate<AppLocalization> delegate = _AppLocalizationDelegate();

  static Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    delegate,
  ];

  static Locale? localeResolutionCallback(Locale? deviceLocale, Iterable<Locale> supportedLocales) {
    for (var locale in supportedLocales) {
      if (locale.languageCode == deviceLocale?.languageCode) {
        return deviceLocale;
      }
    }
    return supportedLocales.first;
  }
}

class _AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const _AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    var localization = AppLocalization(locale);
    await localization.loadLanguage();
    return localization;
  }

  @override
  bool shouldReload(_AppLocalizationDelegate oldDelegate) => true;
}

