import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kipik_v5/utils/payment_limits_manager.dart';
import 'package:kipik_v5/services/auth/captcha_manager.dart';

import 'package:kipik_v5/locator.dart';
import 'package:kipik_v5/routes/router.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/services/payment/firebase_payment_service.dart';
import 'package:kipik_v5/services/init/firebase_init_service.dart';
import 'package:kipik_v5/core/database_manager.dart'; // ✅ AJOUTÉ
import 'package:kipik_v5/utils/database_sync_manager.dart'; // ✅ AJOUTÉ

// Splash Screen
import 'package:kipik_v5/pages/splash/combined_splash_screen.dart';

// ← **NOUVEAU** : import des options générées par FlutterFire CLI
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🚀 Démarrage KIPIK V5...');

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
      print('⚠️ Fichier .env non trouvé, utilisation des valeurs par défaut');
      return Future.value();
    });

    // 4. INITIALISATION FIREBASE CORE
    print('🔄 Initialisation Firebase Core...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase Core initialisé avec succès');

    // 4.1 TEST DE CONNECTIVITÉ FIREBASE (non-bloquant)
    try {
      await testFirebaseConnectivity();
    } catch (_) {
      print('⚠️ Test connectivité a échoué malgré tout, on continue…');
    }

    // 4.5 INITIALISATION AUTOMATIQUE DE LA STRUCTURE FIREBASE KIPIK
    try {
      print('🔄 Initialisation structure Firebase KIPIK...');
      final initService = FirebaseInitService.instance;
      await initService.initializeKipikFirebase();
      print('✅ Structure Firebase KIPIK initialisée automatiquement');
      if (dotenv.env['APP_ENV'] == 'development') {
        await initService.debugInitService();
      }
    } catch (initError) {
      print('⚠️ Erreur initialisation structure Firebase: $initError');
    }

    // 5. Émulateur Functions en dev
    if (dotenv.env['APP_ENV'] == 'development') {
      // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      print('🔧 Mode développement activé - Functions émulateur disponible');
    }

    // 6. Configuration Stripe
    await initializeStripe();

    // 7. Traductions
    await EasyLocalization.ensureInitialized();
    print('✅ Traductions initialisées');

    // 8. Dependency injection
    setupLocator();
    print('✅ Services initialisés');

    // ✅ 8.5 INITIALISATION DU GESTIONNAIRE DE BASE DE DONNÉES
    try {
      await DatabaseManager.instance.initialize();
      print('✅ DatabaseManager initialisé sur: ${DatabaseManager.instance.activeDatabaseConfig.name}');
      
      // Debug en mode développement
      if (dotenv.env['APP_ENV'] == 'development') {
        DatabaseManager.instance.debugDatabaseManager();
        
        // ✅ SYNCHRONISATION AUTOMATIQUE DES BASES DÉMO/TEST
        try {
          print('🔄 Synchronisation automatique démo/test...');
          await DatabaseSyncManager.instance.autoSyncOnStartup();
          print('✅ Synchronisation automatique terminée');
        } catch (syncError) {
          print('⚠️ Erreur synchronisation auto: $syncError');
        }
        
        // Test de toutes les connexions disponibles
        print('🧪 Test des connexions aux bases disponibles...');
        final testResults = await testAllDatabaseConnections();
        print('📊 Résultats des tests: $testResults');
      }
    } catch (dbError) {
      print('⚠️ Erreur initialisation DatabaseManager: $dbError');
      print('   → Utilisation de la base par défaut (kipik)');
    }

    // 9. CAPTCHA + limites paiement
    try {
      await CaptchaManager.instance.initialize();
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

    // 10. Service de paiement
    try {
      FirebasePaymentService.instance;
      print('✅ Service de paiement initialisé');
    } catch (paymentError) {
      print('⚠️ Erreur initialisation service paiement: $paymentError');
    }

    // 11. Validation finale Firebase
    await validateFirebaseInitialization();

    print('🎉 Toutes les initialisations terminées avec succès !');
    
    // Debug final du système complet en développement
    if (dotenv.env['APP_ENV'] == 'development') {
      print('\n🔍 ÉTAT FINAL DU SYSTÈME:');
      print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');
      print('  - Mode: ${DatabaseManager.instance.isDemoMode ? "🎭 DÉMO" : "🏭 PRODUCTION"}');
      print('  - Services disponibles: ${locator.isRegistered<DatabaseManager>() ? "✅" : "❌"}');
      print('  - Prêt pour basculement: ✅');
    }

    // 12. Lancer l'application
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
    print('❌ ERREUR CRITIQUE D\'INITIALISATION: $e');
    print('📍 Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        title: 'Kipik - Erreur',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'PermanentMarker',
        ),
        home: ErrorScreen(error: e.toString(), stackTrace: stackTrace.toString()),
      ),
    );
  }
}

/// ✅ Test de connectivité Firebase (non-bloquant)
Future<void> testFirebaseConnectivity() async {
  print('🔄 Test connectivité Firebase…');

  // 1️⃣ Test Auth
  try {
    final user = FirebaseAuth.instance.currentUser;
    print('✅ Auth accessible (user: ${user?.uid ?? 'anonyme'})');
  } catch (e) {
    print('⚠️ Auth non accessible : $e');
  }

  // 2️⃣ Test Firestore "kipik"
  try {
    final fs = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'kipik',
    );
    final doc = await fs.collection('_connectivity_test').doc('test').get();
    print('✅ Firestore kipik accessible (existe : ${doc.exists})');
  } catch (e) {
    print('⚠️ Firestore kipik non accessible (continuons quand même) : $e');
  }

  print('✅ Connectivité Firebase testée');
}

/// ✅ NOUVEAU - Test de toutes les bases de données disponibles
Future<Map<String, bool>> testAllDatabaseConnections() async {
  final results = <String, bool>{};
  final databases = ['kipik', 'kipik-demo', 'kipik-test'];
  
  for (final dbId in databases) {
    try {
      final fs = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: dbId,
      );
      
      final testDoc = fs.collection('_connectivity_test').doc('test');
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
        'database': dbId,
      });
      
      final doc = await testDoc.get();
      await testDoc.delete(); // Nettoyer
      
      results[dbId] = doc.exists;
      print('  ✅ $dbId: Accessible');
    } catch (e) {
      results[dbId] = false;
      print('  ❌ $dbId: Non accessible - $e');
    }
  }
  
  return results;
}

/// ✅ Initialisation Stripe avec gestion d'erreur
Future<void> initializeStripe() async {
  try {
    final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY_TEST'] ??
        dotenv.env['STRIPE_PUBLISHABLE_KEY_LIVE'];

    if (stripeKey != null && stripeKey.isNotEmpty) {
      Stripe.publishableKey = stripeKey;
      await Stripe.instance.applySettings();
      print('✅ Stripe initialisé avec succès');
    } else {
      print('⚠️ Clé Stripe manquante - Paiements désactivés');
    }
  } catch (stripeError) {
    print('⚠️ Erreur initialisation Stripe: $stripeError');
  }
}

/// ✅ Validation finale Firebase
Future<void> validateFirebaseInitialization() async {
  try {
    final status = await FirebaseInitService.instance.getInitializationStatus();
    if (status['fully_initialized'] == true) {
      print('🎉 Firebase KIPIK entièrement opérationnel !');
    } else {
      print('⚠️ Firebase partiellement initialisé - Certaines fonctionnalités peuvent être limitées');
      print('   Status: $status');
    }
  } catch (e) {
    print('⚠️ Impossible de vérifier le statut Firebase: $e');
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
        cardTheme: CardTheme(
          color: Colors.grey[900],
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const CombinedSplashScreen(),
      routes: appRoutes,
      onGenerateRoute: generateRoute,
      navigatorObservers: [],
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  final String? stackTrace;

  const ErrorScreen({Key? key, required this.error, this.stackTrace}) : super(key: key);

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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => main(),
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
              if (stackTrace != null) ...[
                OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Informations de debug', style: TextStyle(color: Colors.white)),
                      content: SingleChildScrollView(
                        child: Text(stackTrace!, style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer'))
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.bug_report, size: 16),
                  label: const Text('Détails debug'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.support_agent_rounded, color: Colors.white54, size: 20),
                    SizedBox(height: 8),
                    Text(
                      'Si le problème persiste, contactez le support technique.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
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
}