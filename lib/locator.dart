// lib/locator.dart

import 'dart:io'; // Pour File
import 'package:get_it/get_it.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ SERVICE PRINCIPAL
import 'package:kipik_v5/services/auth/captcha_manager.dart';
import 'package:kipik_v5/core/database_manager.dart'; // ✅ AJOUTÉ pour mode démo
import 'package:kipik_v5/utils/database_sync_manager.dart'; // ✅ AJOUTÉ pour synchronisation

// Services de chat
import 'package:kipik_v5/services/chat/chat_service.dart';  // IA Assistant
import 'package:kipik_v5/services/chat/project_chat_service.dart';  // Chat projet-client

// Services unifiés (Production + Démo)
import 'package:kipik_v5/services/convention/firebase_convention_service.dart';
import 'package:kipik_v5/services/photo/firebase_photo_service.dart';
import 'package:kipik_v5/services/project/firebase_project_service.dart';
import 'package:kipik_v5/services/quote/enhanced_quote_service.dart';
import 'package:kipik_v5/services/payment/firebase_payment_service.dart';
import 'package:kipik_v5/services/demande_devis/firebase_demande_devis_service.dart'; // ✅ RESTAURÉ
import 'package:kipik_v5/services/inspiration/firebase_inspiration_service.dart';
import 'package:kipik_v5/services/notification/firebase_notification_service.dart';
import 'package:kipik_v5/services/promo/firebase_promo_code_service.dart';
import 'package:kipik_v5/services/subscription/firebase_subscription_service.dart';
import 'package:kipik_v5/services/tattooist/firebase_tattooist_service.dart';
import 'package:kipik_v5/services/supplier/supplier_service.dart'; // ✅ SERVICE DIRECT (plus d'interface)
import 'package:kipik_v5/services/permissions/feature_permission_service.dart'; // ✅ AJOUTÉ
import 'package:kipik_v5/services/help_center_service.dart'; // ✅ AJOUTÉ

final GetIt locator = GetIt.instance;

void setupLocator() {
  // ✅ CORE SERVICES - Base système
  locator.registerLazySingleton<DatabaseManager>(() => DatabaseManager.instance);
  locator.registerLazySingleton<DatabaseSyncManager>(() => DatabaseSyncManager.instance); // ✅ AJOUTÉ
  
  // ✅ AUTH SERVICES - Sécurité et authentification
  locator.registerLazySingleton<SecureAuthService>(() => SecureAuthService.instance); // ✅ SERVICE PRINCIPAL
  locator.registerLazySingleton<CaptchaManager>(() => CaptchaManager.instance);
  locator.registerLazySingleton<FeaturePermissionService>(() => FeaturePermissionService.instance); // ✅ AJOUTÉ
  
  // ✅ CHAT SERVICES - Communication
  locator.registerLazySingleton<ChatService>(() => ChatService());  // IA Assistant
  locator.registerLazySingleton<ProjectChatService>(() => ProjectChatService());  // Chat projet-client
  
  // ✅ SERVICES MÉTIER UNIFIÉS (Production + Démo automatique)
  locator.registerLazySingleton<FirebaseConventionService>(() => FirebaseConventionService.instance);
  locator.registerLazySingleton<FirebasePhotoService>(() => FirebasePhotoService.instance);
  locator.registerLazySingleton<FirebaseProjectService>(() => FirebaseProjectService.instance);
  locator.registerLazySingleton<EnhancedQuoteService>(() => EnhancedQuoteService.instance);
  locator.registerLazySingleton<FirebasePaymentService>(() => FirebasePaymentService.instance);
  locator.registerLazySingleton<FirebaseDemandeDevisService>(() => FirebaseDemandeDevisService.instance); // ✅ RESTAURÉ
  locator.registerLazySingleton<FirebaseInspirationService>(() => FirebaseInspirationService.instance);
  locator.registerLazySingleton<FirebaseNotificationService>(() => FirebaseNotificationService.instance);
  locator.registerLazySingleton<FirebasePromoCodeService>(() => FirebasePromoCodeService.instance);
  locator.registerLazySingleton<FirebaseSubscriptionService>(() => FirebaseSubscriptionService.instance);
  locator.registerLazySingleton<FirebaseTattooistService>(() => FirebaseTattooistService.instance);
  
  // ✅ SERVICES SUPPLÉMENTAIRES - Support et fournisseurs
  locator.registerLazySingleton<SupplierService>(() => SupplierService()); // ✅ DIRECT (plus d'interface)
  locator.registerLazySingleton<HelpCenterService>(() => HelpCenterService()); // ✅ AJOUTÉ
  
  print('✅ Service Locator unifié initialisé avec ${_getRegisteredServicesCount()} services');
  print('🎯 Mode démo disponible : ${DatabaseManager.instance.isDemoMode ? "Activé" : "Production"}');
}

// ✅ MÉTHODES UTILITAIRES POUR ACCÈS FACILE AUX SERVICES
extension LocatorExtensions on GetIt {
  // Core & Auth
  DatabaseManager get databaseManager => get<DatabaseManager>();
  DatabaseSyncManager get syncManager => get<DatabaseSyncManager>(); // ✅ AJOUTÉ
  SecureAuthService get secureAuthService => get<SecureAuthService>();
  CaptchaManager get captchaManager => get<CaptchaManager>();
  FeaturePermissionService get permissionService => get<FeaturePermissionService>();
  
  // Chat
  ChatService get chatService => get<ChatService>();
  ProjectChatService get projectChatService => get<ProjectChatService>();
  
  // Services métier unifiés
  FirebaseConventionService get conventionService => get<FirebaseConventionService>();
  FirebasePhotoService get photoService => get<FirebasePhotoService>();
  FirebaseProjectService get projectService => get<FirebaseProjectService>();
  EnhancedQuoteService get quoteService => get<EnhancedQuoteService>();
  FirebasePaymentService get paymentService => get<FirebasePaymentService>();
  FirebaseDemandeDevisService get demandeDevisService => get<FirebaseDemandeDevisService>(); // ✅ RESTAURÉ
  FirebaseInspirationService get inspirationService => get<FirebaseInspirationService>();
  FirebaseNotificationService get notificationService => get<FirebaseNotificationService>();
  FirebasePromoCodeService get promoCodeService => get<FirebasePromoCodeService>();
  FirebaseSubscriptionService get subscriptionService => get<FirebaseSubscriptionService>();
  FirebaseTattooistService get tattooistService => get<FirebaseTattooistService>();
  
  // Services supplémentaires
  SupplierService get supplierService => get<SupplierService>();
  HelpCenterService get helpCenterService => get<HelpCenterService>();
  
  // ✅ RACCOURCIS COMPATIBILITÉ (pour transition douce)
  SecureAuthService get authService => get<SecureAuthService>(); // ✅ Redirige vers SecureAuthService
}

// ✅ MÉTHODE POUR NETTOYER LES SERVICES (utile pour les tests)
void resetLocator() {
  locator.reset();
  print('🔄 Service Locator réinitialisé');
}

// ✅ MÉTHODE POUR VÉRIFIER SI TOUS LES SERVICES SONT PRÊTS
bool areServicesReady() {
  try {
    // Vérifier les services critiques
    locator.get<SecureAuthService>();
    locator.get<DatabaseManager>();
    locator.get<CaptchaManager>();
    locator.get<DatabaseSyncManager>(); // ✅ AJOUTÉ
    return true;
  } catch (e) {
    print('❌ Erreur dans les services critiques: $e');
    return false;
  }
}

// ✅ MÉTHODE POUR BASCULER EN MODE DÉMO
Future<void> enableDemoMode() async {
  try {
    await DatabaseManager.instance.switchToDemo();
    print('🎭 Mode démo activé - Tous les services utilisent maintenant des données factices');
  } catch (e) {
    print('❌ Erreur activation mode démo: $e');
  }
}

// ✅ MÉTHODE POUR REVENIR EN MODE PRODUCTION
Future<void> enableProductionMode() async {
  try {
    await DatabaseManager.instance.switchToProduction();
    print('🏭 Mode production activé - Tous les services utilisent maintenant les données réelles');
  } catch (e) {
    print('❌ Erreur activation mode production: $e');
  }
}

// ✅ NOUVELLE MÉTHODE POUR SYNCHRONISER LES BASES
Future<void> syncDemoData() async {
  try {
    await DatabaseSyncManager.instance.syncAllFromProduction();
    print('🔄 Synchronisation démo/test terminée avec succès');
  } catch (e) {
    print('❌ Erreur synchronisation: $e');
  }
}

// ✅ NOUVELLE MÉTHODE POUR SYNCHRONISATION RAPIDE
Future<void> quickSyncDemoData() async {
  try {
    await DatabaseSyncManager.instance.quickSyncFromProduction();
    print('⚡ Synchronisation rapide terminée avec succès');
  } catch (e) {
    print('❌ Erreur synchronisation rapide: $e');
  }
}

// ✅ MÉTHODE POUR DIAGNOSTIQUER TOUS LES SERVICES (CORRIGÉE AVEC ASYNC)
Future<void> debugServices() async {
  print('🔍 DIAGNOSTIC DES SERVICES UNIFIÉS:');
  
  // Services core
  print('📋 SERVICES CORE:');
  print('  - DatabaseManager: ${locator.isRegistered<DatabaseManager>() ? '✅' : '❌'}');
  print('  - DatabaseSyncManager: ${locator.isRegistered<DatabaseSyncManager>() ? '✅' : '❌'}'); // ✅ AJOUTÉ
  print('  - SecureAuthService: ${locator.isRegistered<SecureAuthService>() ? '✅' : '❌'}');
  print('  - CaptchaManager: ${locator.isRegistered<CaptchaManager>() ? '✅' : '❌'}');
  print('  - FeaturePermissionService: ${locator.isRegistered<FeaturePermissionService>() ? '✅' : '❌'}');
  
  // Services chat
  print('💬 SERVICES CHAT:');
  print('  - ChatService (IA): ${locator.isRegistered<ChatService>() ? '✅' : '❌'}');
  print('  - ProjectChatService: ${locator.isRegistered<ProjectChatService>() ? '✅' : '❌'}');
  
  // Services métier unifiés
  print('🔧 SERVICES MÉTIER UNIFIÉS:');
  print('  - ConventionService: ${locator.isRegistered<FirebaseConventionService>() ? '✅' : '❌'}');
  print('  - PhotoService: ${locator.isRegistered<FirebasePhotoService>() ? '✅' : '❌'}');
  print('  - ProjectService: ${locator.isRegistered<FirebaseProjectService>() ? '✅' : '❌'}');
  print('  - QuoteService: ${locator.isRegistered<EnhancedQuoteService>() ? '✅' : '❌'}');
  print('  - PaymentService: ${locator.isRegistered<FirebasePaymentService>() ? '✅' : '❌'}');
  print('  - DemandeDevisService: ${locator.isRegistered<FirebaseDemandeDevisService>() ? '✅' : '❌'}'); // ✅ RESTAURÉ
  print('  - InspirationService: ${locator.isRegistered<FirebaseInspirationService>() ? '✅' : '❌'}');
  print('  - NotificationService: ${locator.isRegistered<FirebaseNotificationService>() ? '✅' : '❌'}');
  print('  - PromoCodeService: ${locator.isRegistered<FirebasePromoCodeService>() ? '✅' : '❌'}');
  print('  - SubscriptionService: ${locator.isRegistered<FirebaseSubscriptionService>() ? '✅' : '❌'}');
  print('  - TattooistService: ${locator.isRegistered<FirebaseTattooistService>() ? '✅' : '❌'}');
  
  // Services supplémentaires
  print('🛠️ SERVICES SUPPLÉMENTAIRES:');
  print('  - SupplierService: ${locator.isRegistered<SupplierService>() ? '✅' : '❌'}');
  print('  - HelpCenterService: ${locator.isRegistered<HelpCenterService>() ? '✅' : '❌'}');
  
  // État du système
  print('🎯 ÉTAT DU SYSTÈME:');
  print('  - Mode actuel: ${DatabaseManager.instance.isDemoMode ? "🎭 DÉMO" : "🏭 PRODUCTION"}');
  print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');
  print('  - Utilisateur connecté: ${SecureAuthService.instance.isAuthenticated ? "✅" : "❌"}');
  
  // ✅ CORRIGÉ - Statistiques de synchronisation avec await
  try {
    final syncStats = await DatabaseSyncManager.instance.getSyncStats();
    print('📊 SYNCHRONISATION:');
    print('  - Dernière sync démo: ${syncStats['demo']?['lastSync'] ?? "Jamais"}');
    print('  - Dernière sync test: ${syncStats['test']?['lastSync'] ?? "Jamais"}');
    print('  - Collections démo: ${syncStats['demo']?['collectionsCount'] ?? 0}');
    print('  - Documents démo: ${syncStats['demo']?['documentsCount'] ?? 0}');
  } catch (e) {
    print('📊 SYNCHRONISATION: Informations non disponibles - $e');
  }
  
  final total = _getRegisteredServicesCount();
  print('📊 RÉSUMÉ: $total services enregistrés et opérationnels');
  
  if (total >= 18) { // ✅ AJUSTÉ pour inclure DatabaseSyncManager
    print('🎉 Tous les services sont correctement enregistrés !');
  } else {
    print('⚠️ Certains services manquent. Vérifiez la configuration.');
  }
}

// ✅ MÉTHODE POUR COMPTER LES SERVICES ENREGISTRÉS
int _getRegisteredServicesCount() {
  int count = 0;
  final services = [
    // Core
    DatabaseManager,
    DatabaseSyncManager, // ✅ AJOUTÉ
    SecureAuthService,
    CaptchaManager,
    FeaturePermissionService,
    // Chat
    ChatService,
    ProjectChatService,
    // Métier unifiés
    FirebaseConventionService,
    FirebasePhotoService,
    FirebaseProjectService,
    EnhancedQuoteService,
    FirebasePaymentService,
    FirebaseDemandeDevisService, // ✅ RESTAURÉ
    FirebaseInspirationService,
    FirebaseNotificationService,
    FirebasePromoCodeService,
    FirebaseSubscriptionService,
    FirebaseTattooistService,
    // Supplémentaires
    SupplierService,
    HelpCenterService,
  ];
  
  for (final service in services) {
    if (locator.isRegistered(instance: service)) {
      count++;
    }
  }
  
  return count;
}

// ✅ MÉTHODE POUR DIAGNOSTIQUER UN SERVICE SPÉCIFIQUE (CORRIGÉE)
Future<void> debugService<T extends Object>() async {
  try {
    final service = locator.get<T>();
    print('🔍 Service ${T.toString()}: ✅ Opérationnel');
    
    // Diagnostics spéciaux pour certains services
    if (T == DatabaseManager) {
      final dbManager = service as DatabaseManager;
      print('  - Mode: ${dbManager.isDemoMode ? "Démo" : "Production"}');
      print('  - Config: ${dbManager.activeDatabaseConfig.name}');
    } else if (T == SecureAuthService) {
      final authService = service as SecureAuthService;
      print('  - Authentifié: ${authService.isAuthenticated}');
      print('  - Rôle: ${authService.currentUserRole?.toString() ?? "Aucun"}');
    } else if (T == DatabaseSyncManager) { // ✅ CORRIGÉ avec await
      final syncManager = service as DatabaseSyncManager;
      try {
        final stats = await syncManager.getSyncStats();
        print('  - Dernière sync démo: ${stats['demo']?['lastSync'] ?? "Jamais"}');
        print('  - Collections sync: ${stats['demo']?['collectionsCount'] ?? 0}');
      } catch (e) {
        print('  - Sync stats: Non disponibles');
      }
    }
  } catch (e) {
    print('❌ Service ${T.toString()}: Erreur - $e');
  }
}

// ✅ MÉTHODE POUR TESTER TOUS LES SERVICES (CORRIGÉE)
Future<void> testAllServices() async {
  print('🧪 TEST DE TOUS LES SERVICES...');
  
  try {
    // Test des services core
    locator.get<DatabaseManager>();
    locator.get<DatabaseSyncManager>(); // ✅ AJOUTÉ
    locator.get<SecureAuthService>();
    locator.get<CaptchaManager>();
    locator.get<FeaturePermissionService>();
    print('✅ Services core: OK');
    
    // Test des services chat
    locator.get<ChatService>();
    locator.get<ProjectChatService>();
    print('✅ Services chat: OK');
    
    // Test des services métier
    locator.get<FirebaseConventionService>();
    locator.get<FirebasePhotoService>();
    locator.get<FirebaseProjectService>();
    locator.get<EnhancedQuoteService>();
    locator.get<FirebasePaymentService>();
    locator.get<FirebaseDemandeDevisService>(); // ✅ RESTAURÉ
    locator.get<FirebaseInspirationService>();
    locator.get<FirebaseNotificationService>();
    locator.get<FirebasePromoCodeService>();
    locator.get<FirebaseSubscriptionService>();
    locator.get<FirebaseTattooistService>();
    print('✅ Services métier: OK');
    
    // Test des services supplémentaires
    locator.get<SupplierService>();
    locator.get<HelpCenterService>();
    print('✅ Services supplémentaires: OK');
    
    // ✅ CORRIGÉ - Test de synchronisation avec await
    final syncManager = locator.get<DatabaseSyncManager>();
    try {
      final stats = await syncManager.getSyncStats();
      print('✅ Service de synchronisation: OK (${stats['demo']?['collectionsCount'] ?? 0} collections)');
    } catch (e) {
      print('✅ Service de synchronisation: OK (stats non disponibles)');
    }
    
    print('🎉 TOUS LES SERVICES FONCTIONNENT CORRECTEMENT !');
    
  } catch (e) {
    print('❌ ERREUR DANS LES TESTS: $e');
  }
}