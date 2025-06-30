// lib/main.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:kipik_v5/locator.dart';
import 'package:kipik_v5/routes/router.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';

// Splash Screen
import 'package:kipik_v5/pages/splash/combined_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Barre d'état transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialiser Firebase
  await Firebase.initializeApp();
  
  // Initialiser AuthService
  await AuthService.instance.initialize();

  await EasyLocalization.ensureInitialized();
  setupLocator();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('de'),
        Locale('es'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      child: const KipikApp(),
    ),
  );
}

class KipikApp extends StatelessWidget {
  const KipikApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kipik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.redAccent,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'PermanentMarker',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Écran de démarrage
      home: const CombinedSplashScreen(),

      // Utilisation du système de routage centralisé
      routes: appRoutes,
      onGenerateRoute: generateRoute,
    );
  }
}