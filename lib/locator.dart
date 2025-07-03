// lib/locator.dart

import 'dart:io'; // Pour File
import 'package:get_it/get_it.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ AJOUTÉ
import 'package:kipik_v5/services/auth/captcha_manager.dart'; // ✅ NOUVEAU
import 'package:kipik_v5/services/chat/chat_service.dart';  // IA Assistant
import 'package:kipik_v5/services/chat/project_chat_service.dart';  // Chat projet-client
import 'package:kipik_v5/services/convention/firebase_convention_service.dart';
import 'package:kipik_v5/services/photo/firebase_photo_service.dart';
import 'package:kipik_v5/services/project/firebase_project_service.dart';
import 'package:kipik_v5/services/quote/enhanced_quote_service.dart';
import 'package:kipik_v5/services/payment/firebase_payment_service.dart';
import 'package:kipik_v5/services/demande_devis/firebase_demande_devis_service.dart';
import 'package:kipik_v5/services/inspiration/firebase_inspiration_service.dart';
import 'package:kipik_v5/services/notification/firebase_notification_service.dart';
import 'package:kipik_v5/services/promo/firebase_promo_code_service.dart';
import 'package:kipik_v5/services/subscription/firebase_subscription_service.dart';
import 'package:kipik_v5/services/tattooist/firebase_tattooist_service.dart';
import 'package:kipik_v5/services/supplier/supplier_service_interface.dart';
import 'package:kipik_v5/services/supplier/supplier_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // ✅ AUTH SERVICES - Firebase avec sécurité reCAPTCHA
  locator.registerLazySingleton<AuthService>(() => AuthService.instance);
  locator.registerLazySingleton<SecureAuthService>(() => SecureAuthService.instance); // ✅ AJOUTÉ
  locator.registerLazySingleton<CaptchaManager>(() => CaptchaManager.instance); // ✅ CORRIGÉ
  
  // ✅ CHAT SERVICES - Deux services différents
  locator.registerLazySingleton<ChatService>(() => ChatService());  // IA Assistant
  locator.registerLazySingleton<ProjectChatService>(() => ProjectChatService());  // Chat projet-client
  
  // ✅ TOUS LES SERVICES FIREBASE - COMPLETS ET FONCTIONNELS 🎉
  locator.registerLazySingleton<FirebaseConventionService>(() => FirebaseConventionService.instance);
  locator.registerLazySingleton<FirebasePhotoService>(() => FirebasePhotoService.instance);
  locator.registerLazySingleton<FirebaseProjectService>(() => FirebaseProjectService.instance);
  locator.registerLazySingleton<EnhancedQuoteService>(() => EnhancedQuoteService.instance);
  locator.registerLazySingleton<FirebasePaymentService>(() => FirebasePaymentService.instance);
  locator.registerLazySingleton<FirebaseDemandeDevisService>(() => FirebaseDemandeDevisService.instance);
  locator.registerLazySingleton<FirebaseInspirationService>(() => FirebaseInspirationService.instance);
  locator.registerLazySingleton<FirebaseNotificationService>(() => FirebaseNotificationService.instance);
  locator.registerLazySingleton<FirebasePromoCodeService>(() => FirebasePromoCodeService.instance);
  locator.registerLazySingleton<FirebaseSubscriptionService>(() => FirebaseSubscriptionService.instance);
  locator.registerLazySingleton<FirebaseTattooistService>(() => FirebaseTattooistService.instance);
  
  // ✅ SUPPLIER SERVICE - Interface
  locator.registerLazySingleton<ISupplierService>(() => SupplierService());
  
  print('✅ Service Locator initialisé avec tous les services + CaptchaManager + SecureAuthService');
}

// ✅ MÉTHODES UTILITAIRES POUR ACCÈS FACILE AUX SERVICES
extension LocatorExtensions on GetIt {
  AuthService get authService => get<AuthService>();
  SecureAuthService get secureAuthService => get<SecureAuthService>();
  CaptchaManager get captchaManager => get<CaptchaManager>();
  ChatService get chatService => get<ChatService>();
  ProjectChatService get projectChatService => get<ProjectChatService>();
  FirebaseConventionService get conventionService => get<FirebaseConventionService>();
  FirebasePhotoService get photoService => get<FirebasePhotoService>();
  FirebaseProjectService get projectService => get<FirebaseProjectService>();
  EnhancedQuoteService get quoteService => get<EnhancedQuoteService>();
  FirebasePaymentService get paymentService => get<FirebasePaymentService>();
  FirebaseDemandeDevisService get demandeDevisService => get<FirebaseDemandeDevisService>();
  FirebaseInspirationService get inspirationService => get<FirebaseInspirationService>();
  FirebaseNotificationService get notificationService => get<FirebaseNotificationService>();
  FirebasePromoCodeService get promoCodeService => get<FirebasePromoCodeService>();
  FirebaseSubscriptionService get subscriptionService => get<FirebaseSubscriptionService>();
  FirebaseTattooistService get tattooistService => get<FirebaseTattooistService>();
  ISupplierService get supplierService => get<ISupplierService>();
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
    locator.get<AuthService>();
    locator.get<SecureAuthService>();
    locator.get<CaptchaManager>();
    return true;
  } catch (e) {
    print('❌ Erreur dans les services: $e');
    return false;
  }
}

// ✅ MÉTHODE POUR DIAGNOSTIQUER LES SERVICES
void debugServices() {
  print('🔍 DIAGNOSTIC DES SERVICES:');
  print('  - AuthService: ${locator.isRegistered<AuthService>() ? '✅' : '❌'}');
  print('  - SecureAuthService: ${locator.isRegistered<SecureAuthService>() ? '✅' : '❌'}');
  print('  - CaptchaManager: ${locator.isRegistered<CaptchaManager>() ? '✅' : '❌'}');
  print('  - ChatService: ${locator.isRegistered<ChatService>() ? '✅' : '❌'}');
  print('  - ProjectChatService: ${locator.isRegistered<ProjectChatService>() ? '✅' : '❌'}');
  print('  - ConventionService: ${locator.isRegistered<FirebaseConventionService>() ? '✅' : '❌'}');
  print('  - PhotoService: ${locator.isRegistered<FirebasePhotoService>() ? '✅' : '❌'}');
  print('  - ProjectService: ${locator.isRegistered<FirebaseProjectService>() ? '✅' : '❌'}');
  print('  - QuoteService: ${locator.isRegistered<EnhancedQuoteService>() ? '✅' : '❌'}');
  print('  - PaymentService: ${locator.isRegistered<FirebasePaymentService>() ? '✅' : '❌'}');
  print('  - DemandeDevisService: ${locator.isRegistered<FirebaseDemandeDevisService>() ? '✅' : '❌'}');
  print('  - InspirationService: ${locator.isRegistered<FirebaseInspirationService>() ? '✅' : '❌'}');
  print('  - NotificationService: ${locator.isRegistered<FirebaseNotificationService>() ? '✅' : '❌'}');
  print('  - PromoCodeService: ${locator.isRegistered<FirebasePromoCodeService>() ? '✅' : '❌'}');
  print('  - SubscriptionService: ${locator.isRegistered<FirebaseSubscriptionService>() ? '✅' : '❌'}');
  print('  - TattooistService: ${locator.isRegistered<FirebaseTattooistService>() ? '✅' : '❌'}');
  print('  - SupplierService: ${locator.isRegistered<ISupplierService>() ? '✅' : '❌'}');
  print('📊 Total: ${_getRegisteredServicesCount()} services enregistrés');
}

// ✅ MÉTHODE POUR COMPTER LES SERVICES ENREGISTRÉS
int _getRegisteredServicesCount() {
  int count = 0;
  final services = [
    AuthService,
    SecureAuthService,
    CaptchaManager,
    ChatService,
    ProjectChatService,
    FirebaseConventionService,
    FirebasePhotoService,
    FirebaseProjectService,
    EnhancedQuoteService,
    FirebasePaymentService,
    FirebaseDemandeDevisService,
    FirebaseInspirationService,
    FirebaseNotificationService,
    FirebasePromoCodeService,
    FirebaseSubscriptionService,
    FirebaseTattooistService,
    ISupplierService,
  ];
  
  for (final service in services) {
    if (locator.isRegistered(instance: service)) {
      count++;
    }
  }
  
  return count;
}