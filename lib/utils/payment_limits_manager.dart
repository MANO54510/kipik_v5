// lib/utils/payment_limits_manager.dart - Gestionnaire des limites de paiement

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';

/// Gestionnaire des limites de paiement pour sécuriser les transactions
class PaymentLimitsManager {
  
  // ==========================================
  // 🔐 LIMITES DE SÉCURITÉ (configurables via .env)
  // ==========================================
  
  /// Limite maximale absolue par transaction (€2,500 par défaut)
  static double get maxTransactionAmount => 
    double.tryParse(dotenv.env['MAX_TRANSACTION_AMOUNT'] ?? '2500') ?? 2500.0;
  
  /// Limite quotidienne par utilisateur (€5,000 par défaut)
  static double get dailyLimit => 
    double.tryParse(dotenv.env['DAILY_PAYMENT_LIMIT'] ?? '5000') ?? 5000.0;
  
  /// Limite mensuelle par utilisateur (€15,000 par défaut)
  static double get monthlyLimit => 
    double.tryParse(dotenv.env['MONTHLY_PAYMENT_LIMIT'] ?? '15000') ?? 15000.0;
  
  /// Limite pour nouveaux utilisateurs (€500 SAUF acomptes)
  static double get newUserLimit => 
    double.tryParse(dotenv.env['NEW_USER_LIMIT'] ?? '500') ?? 500.0;
  
  /// ✅ NOUVEAU: Limite acompte pour nouveaux utilisateurs (€1,000)
  static double get newUserDepositLimit => 
    double.tryParse(dotenv.env['NEW_USER_DEPOSIT_LIMIT'] ?? '1000') ?? 1000.0;
  
  /// Seuil pour validation manuelle admin (€1,500 par défaut)
  static double get adminValidationThreshold => 
    double.tryParse(dotenv.env['ADMIN_VALIDATION_THRESHOLD'] ?? '1500') ?? 1500.0;

  // ==========================================
  // 🎨 LIMITES SPÉCIFIQUES TATOUAGE
  // ==========================================
  
  /// Limites par type de projet tatouage
  static const Map<String, double> projectTypeLimits = {
    'petit': 300.0,           // Petits tatouages
    'moyen': 800.0,           // Tatouages moyens
    'grand': 1500.0,          // Grands tatouages
    'session': 600.0,         // Prix par session
    'flash': 200.0,           // Tatouages flash
    'cover': 1200.0,          // Cover-up
    'realisme': 2000.0,       // Réalisme (plus complexe)
    'traditionnel': 800.0,    // Traditionnel
  };
  
  /// Limites abonnements KIPIK
  static const Map<String, double> subscriptionLimits = {
    'basic': 19.99,           // Abonnement de base mensuel
    'pro': 49.99,             // Abonnement pro mensuel
    'premium': 99.99,         // Abonnement premium mensuel
    'annual_basic': 199.99,   // Abonnement annuel de base
    'annual_pro': 499.99,     // Abonnement annuel pro
    'annual_premium': 999.99, // Abonnement annuel premium
  };

  // ==========================================
  // 🔍 VALIDATION DES LIMITES
  // ==========================================
  
  /// Valider un montant de transaction
  static PaymentLimitResult validateTransactionAmount({
    required double amount,
    required String paymentType,
    String? projectType,
    String? planKey,
  }) {
    // 1. Vérification montant positif
    if (amount <= 0) {
      return PaymentLimitResult(
        isValid: false,
        error: 'Le montant doit être supérieur à 0€',
        rejectionReason: 'INVALID_AMOUNT',
      );
    }

    // 2. Limite absolue par transaction
    if (amount > maxTransactionAmount) {
      return PaymentLimitResult(
        isValid: false,
        error: 'Montant trop élevé (maximum: ${maxTransactionAmount.toStringAsFixed(0)}€)',
        rejectionReason: 'EXCEEDS_MAX_TRANSACTION',
        suggestedAction: 'Diviser en plusieurs paiements ou contacter le support',
      );
    }

    // 3. Validation selon le type de paiement
    switch (paymentType.toLowerCase()) {
      case 'project':
        return _validateProjectAmount(amount, projectType);
      case 'subscription':
        return _validateSubscriptionAmount(amount, planKey);
      case 'deposit':
        return _validateDepositAmount(amount);
      default:
        return _validateGeneralAmount(amount);
    }
  }

  /// Validation spécifique projets tatouage
  static PaymentLimitResult _validateProjectAmount(double amount, String? projectType) {
    if (projectType != null && projectTypeLimits.containsKey(projectType)) {
      final limit = projectTypeLimits[projectType]!;
      if (amount > limit) {
        return PaymentLimitResult(
          isValid: false,
          error: 'Montant trop élevé pour un projet "$projectType" (maximum: ${limit.toStringAsFixed(0)}€)',
          rejectionReason: 'EXCEEDS_PROJECT_TYPE_LIMIT',
          suggestedAction: 'Choisir le type "grand" ou "realisme" pour des montants plus élevés',
        );
      }
    }

    // Limite générale projets (€2,000)
    const projectGeneralLimit = 2000.0;
    if (amount > projectGeneralLimit) {
      return PaymentLimitResult(
        isValid: false,
        error: 'Montant trop élevé pour un projet tatouage (maximum: ${projectGeneralLimit.toStringAsFixed(0)}€)',
        rejectionReason: 'EXCEEDS_PROJECT_LIMIT',
        suggestedAction: 'Diviser en acompte + solde final',
      );
    }

    return PaymentLimitResult(isValid: true);
  }

  /// Validation abonnements
  static PaymentLimitResult _validateSubscriptionAmount(double amount, String? planKey) {
    if (planKey != null && subscriptionLimits.containsKey(planKey)) {
      final expectedAmount = subscriptionLimits[planKey]!;
      if (amount != expectedAmount) {
        return PaymentLimitResult(
          isValid: false,
          error: 'Montant incorrect pour l\'abonnement "$planKey" (attendu: ${expectedAmount.toStringAsFixed(2)}€)',
          rejectionReason: 'INCORRECT_SUBSCRIPTION_AMOUNT',
        );
      }
    }

    return PaymentLimitResult(isValid: true);
  }

  /// Validation acomptes (30% du total) - ✅ LOGIQUE BUSINESS CORRIGÉE
  static PaymentLimitResult _validateDepositAmount(double amount) {
    // ✅ IMPORTANT: Les acomptes doivent être possibles même pour nouveaux clients
    // Un projet de €2,500 = acompte de €750 (30%)
    // Donc limite acompte plus élevée que €500 pour nouveaux clients
    
    const maxDepositAmount = 1000.0; // ✅ AUGMENTÉ: permet acompte sur projet €3,333
    if (amount > maxDepositAmount) {
      return PaymentLimitResult(
        isValid: false,
        error: 'Acompte trop élevé (maximum: ${maxDepositAmount.toStringAsFixed(0)}€)',
        rejectionReason: 'EXCEEDS_DEPOSIT_LIMIT',
        suggestedAction: 'Réduire le montant total du projet ou contacter le tatoueur',
      );
    }

    // ✅ NOUVEAU: Vérification cohérence acompte 30%
    const minProjectForThisDeposit = 100.0; // Projet minimum €100 
    if (amount < minProjectForThisDeposit * 0.3) {
      return PaymentLimitResult(
        isValid: false,
        error: 'Acompte trop faible (minimum: ${(minProjectForThisDeposit * 0.3).toStringAsFixed(0)}€)',
        rejectionReason: 'DEPOSIT_TOO_LOW',
      );
    }

    return PaymentLimitResult(isValid: true);
  }

  /// Validation générale
  static PaymentLimitResult _validateGeneralAmount(double amount) {
    if (amount > maxTransactionAmount) {
      return PaymentLimitResult(
        isValid: false,
        error: 'Montant trop élevé (maximum: ${maxTransactionAmount.toStringAsFixed(0)}€)',
        rejectionReason: 'EXCEEDS_GENERAL_LIMIT',
      );
    }

    return PaymentLimitResult(isValid: true);
  }

  // ==========================================
  // 👤 LIMITES PAR UTILISATEUR
  // ==========================================
  
  /// Vérifier les limites utilisateur (quotidienne/mensuelle)
  static Future<PaymentLimitResult> validateUserLimits({
    required double amount,
    required String userId,
    String? paymentType, // ✅ AJOUTÉ pour identifier les acomptes
  }) async {
    try {
      // 1. ✅ LOGIQUE CORRIGÉE: Nouveaux utilisateurs peuvent payer des acomptes
      final userAge = await _getUserAccountAge(userId);
      if (userAge != null && userAge.inDays < 30) {
        // ✅ EXCEPTION pour les acomptes (deposit) - pas de limite
        if (paymentType?.toLowerCase() == 'deposit') {
          // Les acomptes sont autorisés pour les nouveaux clients
          // (nécessaire pour réserver un tatouage)
          print('✅ Acompte autorisé pour nouveau client: ${amount.toStringAsFixed(2)}€');
        } else if (amount > newUserLimit) {
          // Limites uniquement pour les paiements complets
          return PaymentLimitResult(
            isValid: false,
            error: 'Limite nouveau utilisateur dépassée pour paiement complet (maximum: ${newUserLimit.toStringAsFixed(0)}€)',
            rejectionReason: 'NEW_USER_LIMIT_EXCEEDED',
            suggestedAction: 'Utiliser le paiement en acompte + solde final',
            requiresManualValidation: true,
          );
        }
      }

      // 2. Vérifier limite quotidienne
      final todaySpent = await _getUserDailySpent(userId);
      if (todaySpent + amount > dailyLimit) {
        return PaymentLimitResult(
          isValid: false,
          error: 'Limite quotidienne dépassée (${todaySpent.toStringAsFixed(0)}€/${dailyLimit.toStringAsFixed(0)}€)',
          rejectionReason: 'DAILY_LIMIT_EXCEEDED',
          suggestedAction: 'Réessayer demain ou contacter le support',
          remainingLimit: dailyLimit - todaySpent,
        );
      }

      // 3. Vérifier limite mensuelle
      final monthlySpent = await _getUserMonthlySpent(userId);
      if (monthlySpent + amount > monthlyLimit) {
        return PaymentLimitResult(
          isValid: false,
          error: 'Limite mensuelle dépassée (${monthlySpent.toStringAsFixed(0)}€/${monthlyLimit.toStringAsFixed(0)}€)',
          rejectionReason: 'MONTHLY_LIMIT_EXCEEDED',
          suggestedAction: 'Attendre le mois prochain ou contacter le support',
          remainingLimit: monthlyLimit - monthlySpent,
        );
      }

      // 4. Vérifier seuil validation manuelle
      if (amount > adminValidationThreshold) {
        return PaymentLimitResult(
          isValid: true,
          requiresManualValidation: true,
          warning: 'Montant élevé - validation manuelle requise',
        );
      }

      return PaymentLimitResult(
        isValid: true,
        remainingDailyLimit: dailyLimit - todaySpent,
        remainingMonthlyLimit: monthlyLimit - monthlySpent,
      );

    } catch (e) {
      return PaymentLimitResult(
        isValid: false,
        error: 'Erreur vérification limites utilisateur: $e',
        rejectionReason: 'VALIDATION_ERROR',
      );
    }
  }

  // ==========================================
  // 📊 MÉTHODES D'AIDE (à implémenter avec Firestore)
  // ==========================================
  
  /// Obtenir l'âge du compte utilisateur
  static Future<Duration?> _getUserAccountAge(String userId) async {
    // TODO: Implémenter avec Firestore
    // final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    // return DateTime.now().difference(userDoc.data()['createdAt'].toDate());
    return null; // Placeholder
  }

  /// Obtenir le montant dépensé aujourd'hui
  static Future<double> _getUserDailySpent(String userId) async {
    // TODO: Implémenter avec Firestore
    // Sommer les transactions de l'utilisateur pour aujourd'hui
    return 0.0; // Placeholder
  }

  /// Obtenir le montant dépensé ce mois
  static Future<double> _getUserMonthlySpent(String userId) async {
    // TODO: Implémenter avec Firestore
    // Sommer les transactions de l'utilisateur pour ce mois
    return 0.0; // Placeholder
  }

  // ==========================================
  // 🛡️ MÉTHODES UTILITAIRES
  // ==========================================
  
  /// Obtenir la limite recommandée selon le type de projet
  static double getRecommendedLimitForProject(String projectType) {
    return projectTypeLimits[projectType] ?? maxTransactionAmount;
  }

  /// Vérifier si un montant nécessite une validation admin
  static bool requiresAdminValidation(double amount) {
    return amount > adminValidationThreshold;
  }

  /// Obtenir les limites de l'utilisateur actuel
  static Future<UserLimits> getCurrentUserLimits() async {
    final user = SecureAuthService.instance.currentUser;
    if (user == null) {
      return UserLimits.guest();
    }

    final userId = user['uid'] ?? user['id'];
    final dailySpent = await _getUserDailySpent(userId);
    final monthlySpent = await _getUserMonthlySpent(userId);
    final userAge = await _getUserAccountAge(userId);

    return UserLimits(
      maxTransaction: maxTransactionAmount,
      dailyLimit: dailyLimit,
      monthlyLimit: monthlyLimit,
      remainingDaily: dailyLimit - dailySpent,
      remainingMonthly: monthlyLimit - monthlySpent,
      isNewUser: userAge != null && userAge.inDays < 30,
      newUserLimit: userAge != null && userAge.inDays < 30 ? newUserLimit : null,
    );
  }
}

// ==========================================
// 📋 CLASSES DE RÉSULTATS
// ==========================================

/// Résultat de validation des limites
class PaymentLimitResult {
  final bool isValid;
  final String? error;
  final String? rejectionReason;
  final String? suggestedAction;
  final String? warning;
  final bool requiresManualValidation;
  final double? remainingLimit;
  final double? remainingDailyLimit;
  final double? remainingMonthlyLimit;

  PaymentLimitResult({
    required this.isValid,
    this.error,
    this.rejectionReason,
    this.suggestedAction,
    this.warning,
    this.requiresManualValidation = false,
    this.remainingLimit,
    this.remainingDailyLimit,
    this.remainingMonthlyLimit,
  });

  /// Message utilisateur convivial
  String get userFriendlyMessage {
    if (isValid && warning != null) return warning!;
    if (!isValid && error != null) return error!;
    return isValid ? 'Paiement autorisé' : 'Paiement non autorisé';
  }

  /// Action recommandée pour l'utilisateur
  String? get recommendedAction {
    if (requiresManualValidation) {
      return 'Ce montant nécessite une validation manuelle. Vous serez contacté sous 24h.';
    }
    return suggestedAction;
  }
}

/// Limites d'un utilisateur
class UserLimits {
  final double maxTransaction;
  final double dailyLimit;
  final double monthlyLimit;
  final double remainingDaily;
  final double remainingMonthly;
  final bool isNewUser;
  final double? newUserLimit;

  UserLimits({
    required this.maxTransaction,
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.remainingDaily,
    required this.remainingMonthly,
    required this.isNewUser,
    this.newUserLimit,
  });

  factory UserLimits.guest() {
    return UserLimits(
      maxTransaction: 0,
      dailyLimit: 0,
      monthlyLimit: 0,
      remainingDaily: 0,
      remainingMonthly: 0,
      isNewUser: true,
      newUserLimit: 0,
    );
  }

  /// Limite effective selon le statut utilisateur
  double get effectiveMaxTransaction {
    if (isNewUser && newUserLimit != null) {
      return newUserLimit!;
    }
    return maxTransaction;
  }
}

// ==========================================
// 🔧 CONFIGURATION .ENV RECOMMANDÉE
// ==========================================

/*
# Ajoutez ces variables à votre .env :

# Limites de paiement (en euros)
MAX_TRANSACTION_AMOUNT=2500
DAILY_PAYMENT_LIMIT=5000
MONTHLY_PAYMENT_LIMIT=15000
NEW_USER_LIMIT=500                    # Limite paiements complets nouveaux clients
NEW_USER_DEPOSIT_LIMIT=1000           # ✅ NOUVEAU: Limite acomptes nouveaux clients
ADMIN_VALIDATION_THRESHOLD=1500

# Limites spéciales
FLASH_TATTOO_LIMIT=200
TRADITIONAL_TATTOO_LIMIT=800
REALISM_TATTOO_LIMIT=2000
*/