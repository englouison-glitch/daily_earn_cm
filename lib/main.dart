import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'localization/app_localization.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleNotifier(),
      child: Consumer<LocaleNotifier>(
        builder: (_, notifier, __) => MaterialApp(
          title: 'DailyEarn CM',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
          locale: notifier.locale,
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: AppLocalization.localizationsDelegates,
          localeResolutionCallback: AppLocalization.localeResolution,
          home: const AuthScreen(),
        ),
      ),
    );
  }
}

class LocaleNotifier extends ChangeNotifier {
  Locale _locale = const Locale('fr');
  Locale get locale => _locale;
  void setLocale(Locale l) { _locale = l; notifyListeners(); }
}

