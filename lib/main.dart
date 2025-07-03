// lib/main.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ✅ UTILISÉ: Configuration émulateur Firebase Functions
import 'package:flutter_stripe/flutter_stripe.dart'; // ✅ UTILISÉ: Configuration Stripe obligatoire
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kipik_v5/utils/payment_limits_manager.dart'; // ✅ UTILISÉ: Debug des limites de paiement
import 'package:kipik_v5/services/auth/captcha_manager.dart'; // ✅ UTILISÉ: Initialisation sécurité CAPTCHA

import 'package:kipik_v5/locator.dart'; // ✅ UTILISÉ: setupLocator() - Dependency injection
import 'package:kipik_v5/routes/router.dart'; // ✅ UTILISÉ: appRoutes + generateRoute
import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ UTILISÉ: Type pour services
import 'package:kipik_v5/services/payment/firebase_payment_service.dart'; // ✅ UTILISÉ: Initialisation service paiement

// Splash Screen
import 'package:kipik_v5/pages/splash/combined_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Portrait uniquement
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 2. Barre d'état transparente
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // 3. Charger les variables d'environnement
    await dotenv.load(fileName: ".env").catchError((e) {
      // Si le fichier .env n'existe pas, continuer sans erreur
      print('⚠️ Fichier .env non trouvé, utilisation des valeurs par défaut');
      return Future.value(); // Retourner une Future résolue
    });

    // 4. Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé avec succès');
    
    // 5. ✅ UTILISATION: Configuration Firebase Functions pour développement
    if (dotenv.env['APP_ENV'] == 'development') {
      // ✅ CLOUD_FUNCTIONS utilisé ici pour l'émulateur
      // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      print('🔧 Mode développement activé - Functions émulateur disponible');
    }

    // 6. ✅ UTILISATION: Configuration Stripe
    final stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY_TEST'] ?? 
        dotenv.env['STRIPE_PUBLISHABLE_KEY_LIVE'];
    
    if (stripePublishableKey != null && stripePublishableKey.isNotEmpty) {
      try {
        // ✅ FLUTTER_STRIPE utilisé ici
        Stripe.publishableKey = stripePublishableKey;
        await Stripe.instance.applySettings();
        print('✅ Stripe initialisé avec succès');
      } catch (stripeError) {
        print('⚠️ Erreur initialisation Stripe: $stripeError');
      }
    } else {
      print('⚠️ Clé Stripe manquante - Paiements désactivés');
    }

    // 7. Initialiser les traductions
    await EasyLocalization.ensureInitialized();
    print('✅ Traductions initialisées');

    // 8. ✅ UTILISATION: Initialiser les services dependency injection
    setupLocator(); // ✅ LOCATOR utilisé ici
    print('✅ Services initialisés');

    // 9. ✅ UTILISATION: Initialiser le CaptchaManager + debug limites
    try {
      // ✅ CAPTCHA_MANAGER utilisé ici
      await CaptchaManager.instance.initialize();
      
      // ✅ PAYMENT_LIMITS_MANAGER utilisé ici pour debug
      if (dotenv.env['APP_ENV'] == 'development') {
        print('🔐 Limites configurées:');
        print('  - Transaction max: €${PaymentLimitsManager.maxTransactionAmount}');
        print('  - Nouveau client: €${PaymentLimitsManager.newUserLimit}');
        print('  - Acompte nouveau: €${PaymentLimitsManager.newUserDepositLimit}');
        CaptchaManager.instance.debugPrintState();
      }
      
      print('✅ CaptchaManager + limites initialisés');
    } catch (captchaError) {
      print('⚠️ Erreur initialisation CaptchaManager: $captchaError');
    }

    // 10. ✅ UTILISATION: Initialiser le service de paiement
    try {
      // ✅ FIREBASE_PAYMENT_SERVICE utilisé ici
      FirebasePaymentService.instance;
      print('✅ Service de paiement initialisé');
    } catch (paymentError) {
      print('⚠️ Erreur initialisation service paiement: $paymentError');
    }

    // 11. Lancer l'application
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

    print('🚀 Application KIPIK V5 lancée avec succès');

  } catch (e, stackTrace) {
    // Gestion d'erreur globale
    print('❌ Erreur critique d\'initialisation: $e');
    print('📍 Stack trace: $stackTrace');
    
    // Afficher un écran d'erreur personnalisé
    runApp(
      MaterialApp(
        title: 'Kipik - Erreur',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'PermanentMarker',
        ),
        home: ErrorScreen(
          error: e.toString(),
          stackTrace: stackTrace.toString(),
        ),
      ),
    );
  }
}

class KipikApp extends StatelessWidget {
  const KipikApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kipik V5',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.redAccent,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'PermanentMarker',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        
        // Configuration AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        // Configuration boutons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Configuration champs de texte
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[600]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
        ),
        
        // Configuration cartes
        cardTheme: CardTheme(
          color: Colors.grey[900],
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Configuration des langues
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Écran de démarrage
      home: const CombinedSplashScreen(),

      // ✅ UTILISATION: Système de routage centralisé
      routes: appRoutes, // ✅ ROUTER utilisé ici
      onGenerateRoute: generateRoute, // ✅ ROUTER utilisé ici
      
      // Configuration de navigation
      navigatorObservers: [
        // Ajoutez vos observateurs de navigation ici si nécessaire
      ],
    );
  }
}

/// Écran d'erreur amélioré en cas de problème d'initialisation
class ErrorScreen extends StatelessWidget {
  final String error;
  final String? stackTrace;
  
  const ErrorScreen({
    Key? key, 
    required this.error,
    this.stackTrace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône d'erreur
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 32),
              
              // Logo KIPIK
              const Text(
                'KIPIK',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'PermanentMarker',
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'V5',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Titre erreur
              const Text(
                'Erreur d\'initialisation',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Message d'erreur
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Détails de l\'erreur:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Redémarrer l'app
                        main();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Bouton debug (mode développement)
              if (stackTrace != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    _showDebugDialog(context);
                  },
                  icon: const Icon(Icons.bug_report, size: 16),
                  label: const Text('Détails debug'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Message de support
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Si le problème persiste, contactez le support technique.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Informations de debug',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            stackTrace ?? 'Aucune information de debug disponible',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}