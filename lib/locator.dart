// lib/locator.dart
import 'dart:io'; // Pour File
import 'package:get_it/get_it.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
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
  // ✅ AUTH SERVICE - Firebase
  locator.registerLazySingleton<AuthService>(() => AuthService.instance);
  
  // ✅ CHAT SERVICES - Deux services différents
  locator.registerLazySingleton<ChatService>(() => ChatService());  // IA Assistant
  locator.registerLazySingleton<ProjectChatService>(() => ProjectChatService());  // Chat projet-client
  
  // ✅ TOUS LES SERVICES FIREBASE - COMPLETS ET FONCTIONNELS 🎉
  locator.registerLazySingleton(() => FirebaseConventionService.instance);
  locator.registerLazySingleton(() => FirebasePhotoService.instance);
  locator.registerLazySingleton(() => FirebaseProjectService.instance);
  locator.registerLazySingleton(() => EnhancedQuoteService.instance);
  locator.registerLazySingleton(() => FirebasePaymentService.instance);
  locator.registerLazySingleton(() => FirebaseDemandeDevisService.instance);
  locator.registerLazySingleton(() => FirebaseInspirationService.instance);
  locator.registerLazySingleton(() => FirebaseNotificationService.instance);
  locator.registerLazySingleton(() => FirebasePromoCodeService.instance);
  locator.registerLazySingleton(() => FirebaseSubscriptionService.instance);
  locator.registerLazySingleton(() => FirebaseTattooistService.instance);
  
  // ✅ SUPPLIER SERVICE - Interface
  locator.registerLazySingleton<ISupplierService>(() => SupplierService());
}