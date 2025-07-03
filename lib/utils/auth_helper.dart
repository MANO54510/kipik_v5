// lib/utils/auth_helper.dart

import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/services/auth/captcha_manager.dart';
import 'package:kipik_v5/models/user_role.dart'; // ✅ Import du vrai enum
import 'package:kipik_v5/locator.dart';

/// ✅ INTÉGRATION reCAPTCHA: Vérifie les crédentials de manière sécurisée
Future<UserRole?> checkUserCredentialsSecure({
  required String email,
  required String password,
  CaptchaResult? captchaResult,
}) async {
  try {
    final captchaManager = locator<CaptchaManager>();
    
    // 1. Vérifier si CAPTCHA est requis
    if (captchaManager.shouldShowCaptcha('login')) {
      if (captchaResult == null || !captchaResult.isValid) {
        throw Exception('CAPTCHA requis pour cette connexion');
      }
      
      // Vérifier le score pour une connexion
      final requiredScore = captchaManager.getRequiredScoreForAction('login');
      if (captchaResult.score < requiredScore) {
        captchaManager.recordFailedAttempt('login');
        throw Exception('Score de sécurité insuffisant');
      }
    }

    // 2. Connexion avec SecureAuthService
    final user = await SecureAuthService.instance.signInWithEmailAndPassword(
      email, 
      password, 
      captchaResult: captchaResult,
    );
    
    if (user != null) {
      // 3. Connexion réussie - Reset des tentatives
      captchaManager.recordSuccessfulAttempt('login');
      
      // Récupérer le rôle depuis les données utilisateur
      final roleString = user['role']?.toString();
      return UserRoleExtension.fromString(roleString ?? 'client');
    }
    
    // 4. Connexion échouée
    captchaManager.recordFailedAttempt('login');
    return null;
    
  } catch (e) {
    print('Erreur lors de la vérification des crédentials: $e');
    // Enregistrer l'échec pour la sécurité
    locator<CaptchaManager>().recordFailedAttempt('login');
    rethrow;
  }
}

/// ✅ RÉTROCOMPATIBILITÉ: Version originale sans CAPTCHA (pour la transition)
Future<UserRole?> checkUserCredentials(String email, String password) async {
  try {
    final user = await SecureAuthService.instance.signInWithEmailAndPassword(email, password);
    
    if (user != null) {
      final roleString = user['role']?.toString();
      return UserRoleExtension.fromString(roleString ?? 'client');
    }
    
    return null;
  } catch (e) {
    print('Erreur lors de la vérification des crédentials: $e');
    return null;
  }
}

/// ✅ INTÉGRATION reCAPTCHA: Création de compte sécurisée
Future<dynamic> createUserWithEmailAndPasswordSecure({
  required String email,
  required String password,
  required CaptchaResult captchaResult,
  String? displayName,
}) async {
  try {
    final captchaManager = CaptchaManager.instance;
    final requiredScore = captchaManager.getRequiredScoreForAction('signup');
    
    // 1. CAPTCHA obligatoire pour l'inscription
    if (!captchaResult.isValid || captchaResult.score < requiredScore) {
      throw Exception('Vérification de sécurité requise pour l\'inscription');
    }

    // 2. Création du compte avec SecureAuthService
    final user = await SecureAuthService.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
      captchaResult: captchaResult,
    );

    if (user != null) {
      print('✅ Compte créé avec sécurité reCAPTCHA - Score: ${(captchaResult.score * 100).round()}%');
    }

    return user;
  } catch (e) {
    print('❌ Erreur création compte sécurisé: $e');
    rethrow;
  }
}

/// ✅ INTÉGRATION reCAPTCHA: Création du premier admin avec sécurité renforcée
Future<bool> createFirstAdminAccountSecure({
  required CaptchaResult captchaResult,
  String? customEmail,
  String? customPassword,
  String? customDisplayName,
}) async {
  try {
    // Vérification reCAPTCHA renforcée pour admin
    if (!captchaResult.isValid || captchaResult.score < 0.8) {
      throw Exception('Score de sécurité élevé requis pour créer un compte admin');
    }

    final email = customEmail ?? 'mano@kipik.ink';
    final password = customPassword ?? 'VotreMotDePasseSecurise123!';
    final displayName = customDisplayName ?? 'Mano Admin';

    final success = await SecureAuthService.instance.createFirstSuperAdmin(
      email: email,
      password: password,
      displayName: displayName,
      captchaResult: captchaResult,
    );
    
    if (success) {
      print('✅ Super admin créé avec sécurité renforcée !');
      print('📧 Email: $email');
      print('🔐 Score sécurité: ${(captchaResult.score * 100).round()}%');
      return true;
    } else {
      print('❌ Erreur lors de la création du super admin');
      return false;
    }
  } catch (e) {
    print('❌ Erreur: $e');
    return false;
  }
}

/// Version originale sans CAPTCHA (pour compatibilité)
Future<bool> createFirstAdminAccount({
  String? customEmail,
  String? customPassword,
  String? customDisplayName,
}) async {
  try {
    // Créer un CaptchaResult factice avec un score élevé pour le dev
    final fakeCaptcha = CaptchaResult(
      isValid: true,
      score: 0.9,
      action: 'create_admin',
      requiredScore: 0.8,
      timestamp: DateTime.now(),
      token: 'dev_token',
    );

    return await createFirstAdminAccountSecure(
      captchaResult: fakeCaptcha,
      customEmail: customEmail,
      customPassword: customPassword,
      customDisplayName: customDisplayName,
    );
  } catch (e) {
    print('❌ Erreur: $e');
    return false;
  }
}

/// ✅ NOUVEAUX HELPERS pour reCAPTCHA
class CaptchaAuthHelper {
  static CaptchaManager get _captchaManager => locator<CaptchaManager>();

  /// Vérifier si CAPTCHA est requis pour une action
  static bool shouldShowCaptcha(String context) {
    return _captchaManager.shouldShowCaptcha(context);
  }

  /// Valider reCAPTCHA pour n'importe quelle action
  static Future<CaptchaResult> validateCaptcha(String action) {
    return _captchaManager.validateInvisibleCaptcha(action);
  }

  /// Obtenir le délai de blocage restant
  static Duration? getLoginLockoutTime() {
    return _captchaManager.getRemainingLockout();
  }

  /// Obtenir les statistiques de sécurité (pour admin)
  static SecurityStats getSecurityStats() {
    return _captchaManager.getSecurityStats();
  }

  /// Réinitialiser toutes les tentatives (admin uniquement)
  static void resetAllAttempts() {
    _captchaManager.resetAllAttempts();
  }

  /// Enregistrer une tentative échouée manuellement
  static void recordFailedAttempt(String context) {
    _captchaManager.recordFailedAttempt(context);
  }

  /// Enregistrer une connexion réussie manuellement
  static void recordSuccessfulAttempt(String context) {
    _captchaManager.recordSuccessfulAttempt(context);
  }

  /// Obtenir le score minimum requis pour une action
  static double getRequiredScore(String action) {
    return _captchaManager.getRequiredScoreForAction(action);
  }

  /// Obtenir le niveau de sécurité pour une action
  static SecurityLevel getSecurityLevel(String action) {
    return _captchaManager.getSecurityLevelForAction(action);
  }
}

/// Fonction pour créer des comptes de test (avec sécurité)
Future<void> createTestAccountsSecure({required CaptchaResult captchaResult}) async {
  // Vérifier CAPTCHA pour création de comptes de test
  if (!captchaResult.isValid || captchaResult.score < 0.7) {
    throw Exception('Score de sécurité requis pour créer des comptes de test');
  }

  final authService = SecureAuthService.instance;
  
  try {
    // Créer un client de test
    await authService.createUserWithEmailAndPassword(
      email: 'client@kipik.ink',
      password: 'Client123!',
      displayName: 'Client Test',
      userRole: 'client',
      captchaResult: captchaResult,
    );
    
    // Créer un tatoueur de test
    await authService.createUserWithEmailAndPassword(
      email: 'tatoueur@kipik.ink',
      password: 'Tatoueur123!',
      displayName: 'Tatoueur Test',
      userRole: 'tatoueur',
      captchaResult: captchaResult,
    );
    
    // Créer un organisateur de test
    await authService.createUserWithEmailAndPassword(
      email: 'organisateur@kipik.ink',
      password: 'Orga123!',
      displayName: 'Organisateur Test',
      userRole: 'organisateur',
      captchaResult: captchaResult,
    );
    
    print('✅ Comptes de test créés avec sécurité reCAPTCHA !');
  } catch (e) {
    print('❌ Erreur lors de la création des comptes de test: $e');
  }
}

/// Version originale sans CAPTCHA (pour compatibilité)
Future<void> createTestAccounts() async {
  try {
    // Créer un CaptchaResult factice pour le dev
    final fakeCaptcha = CaptchaResult(
      isValid: true,
      score: 0.8,
      action: 'create_test_accounts',
      requiredScore: 0.7,
      timestamp: DateTime.now(),
      token: 'dev_token',
    );

    await createTestAccountsSecure(captchaResult: fakeCaptcha);
  } catch (e) {
    print('❌ Erreur lors de la création des comptes de test: $e');
  }
}

/// Fonction utilitaire pour convertir un UserRole en string
String userRoleToString(UserRole role) {
  return role.value;
}

/// Fonction utilitaire pour convertir un string en UserRole
UserRole? stringToUserRole(String? roleString) {
  if (roleString == null) return null;
  return UserRoleExtension.fromString(roleString);
}

/// Vérifie si l'utilisateur actuel est admin
Future<bool> isCurrentUserAdmin() async {
  try {
    final currentRole = SecureAuthService.instance.currentUserRole;
    return currentRole == UserRole.admin;
  } catch (e) {
    print('Erreur vérification admin: $e');
    return false;
  }
}

/// Vérifie si l'utilisateur actuel est super admin
Future<bool> isCurrentUserSuperAdmin() async {
  try {
    return SecureAuthService.instance.isSuperAdmin;
  } catch (e) {
    print('Erreur vérification super admin: $e');
    return false;
  }
}

/// Obtenir l'utilisateur actuel
dynamic getCurrentUser() {
  return SecureAuthService.instance.currentUser;
}

/// Obtenir le rôle de l'utilisateur actuel
UserRole? getCurrentUserRole() {
  return SecureAuthService.instance.currentUserRole;
}

/// Obtenir l'ID de l'utilisateur actuel
String? getCurrentUserId() {
  return SecureAuthService.instance.currentUserId;
}

/// Vérifier si l'utilisateur est authentifié
bool isAuthenticated() {
  return SecureAuthService.instance.isAuthenticated;
}

/// Déconnexion rapide
Future<void> signOut() async {
  try {
    await SecureAuthService.instance.signOut();
    print('✅ Déconnexion réussie');
  } catch (e) {
    print('❌ Erreur déconnexion: $e');
  }
}

/// ✅ NOUVEAUX HELPERS POUR ACTIONS SPÉCIFIQUES

/// Valider une action de paiement
Future<bool> validatePaymentAction() async {
  try {
    final result = await CaptchaManager.instance.validateInvisibleCaptcha('payment');
    return result.isValid && result.score >= 0.8;
  } catch (e) {
    print('❌ Erreur validation paiement: $e');
    return false;
  }
}

/// Valider une réservation
Future<bool> validateBookingAction() async {
  try {
    final result = await CaptchaManager.instance.validateInvisibleCaptcha('booking');
    return result.isValid && result.score >= 0.6;
  } catch (e) {
    print('❌ Erreur validation réservation: $e');
    return false;
  }
}

/// Valider une action critique (admin)
Future<bool> validateCriticalAction(String action) async {
  try {
    return await CaptchaManager.instance.validateCriticalAction(action);
  } catch (e) {
    print('❌ Erreur validation action critique: $e');
    return false;
  }
}

/// Helper pour promouvoir un utilisateur en admin (super admin uniquement)
Future<bool> promoteUserToAdmin({
  required String userId,
  required String adminLevel,
  CaptchaResult? captchaResult,
}) async {
  try {
    if (!SecureAuthService.instance.isSuperAdmin) {
      throw Exception('Seul le super admin peut promouvoir des utilisateurs');
    }

    return await SecureAuthService.instance.promoteUserToAdmin(
      userId: userId,
      adminLevel: adminLevel,
      captchaResult: captchaResult,
    );
  } catch (e) {
    print('❌ Erreur promotion admin: $e');
    return false;
  }
}

/// Helper pour révoquer l'accès admin
Future<bool> revokeAdminAccess({
  required String userId,
  CaptchaResult? captchaResult,
}) async {
  try {
    if (!SecureAuthService.instance.isSuperAdmin) {
      throw Exception('Seul le super admin peut révoquer des accès admin');
    }

    return await SecureAuthService.instance.revokeAdminAccess(
      userId: userId,
      captchaResult: captchaResult,
    );
  } catch (e) {
    print('❌ Erreur révocation admin: $e');
    return false;
  }
}

/// ✅ HELPER POUR DIAGNOSTIC ET DEBUG
class AuthDiagnostics {
  static void printCurrentState() {
    print('🔍 ÉTAT AUTHENTIFICATION:');
    print('  - Authentifié: ${isAuthenticated()}');
    print('  - User ID: ${getCurrentUserId() ?? 'Non connecté'}');
    print('  - Rôle: ${getCurrentUserRole()?.name ?? 'Aucun'}');
    print('  - Super Admin: ${SecureAuthService.instance.isSuperAdmin}');
    
    final user = getCurrentUser();
    if (user != null) {
      print('  - Email: ${user['email'] ?? 'N/A'}');
      print('  - Nom: ${user['name'] ?? user['displayName'] ?? 'N/A'}');
    }
  }

  static void printSecurityState() {
    print('🔐 ÉTAT SÉCURITÉ:');
    final stats = CaptchaAuthHelper.getSecurityStats();
    print('  - Tentatives échouées: ${stats.totalFailedAttempts}');
    print('  - Appareils bloqués: ${stats.lockedDevices}');
    print('  - Appareils uniques: ${stats.uniqueDevices}');
    
    final lockout = CaptchaAuthHelper.getLoginLockoutTime();
    if (lockout != null) {
      print('  - Temps de blocage restant: ${lockout.inMinutes}min ${lockout.inSeconds % 60}s');
    }
  }

  static Future<void> testCaptchaScores() async {
    print('🧪 TEST SCORES CAPTCHA:');
    
    final actions = ['login', 'signup', 'payment', 'booking'];
    for (final action in actions) {
      final requiredScore = CaptchaAuthHelper.getRequiredScore(action);
      final level = CaptchaAuthHelper.getSecurityLevel(action);
      print('  - $action: ${requiredScore} (${level.name})');
    }
  }
}