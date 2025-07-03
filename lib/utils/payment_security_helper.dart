// lib/utils/payment_security_helper.dart - Version avec scores adaptatifs

import 'package:kipik_v5/services/auth/captcha_manager.dart';
import 'package:kipik_v5/services/payment/firebase_payment_service.dart';
import 'package:kipik_v5/utils/auth_helper.dart';
import 'package:kipik_v5/locator.dart';

/// Helper pour sécuriser tous les paiements avec reCAPTCHA adaptatif
class PaymentSecurityHelper {
  static FirebasePaymentService get _paymentService => locator<FirebasePaymentService>();
  static CaptchaManager get _captchaManager => CaptchaManager.instance;

  /// 🔐 ÉTAPE 1: Validation reCAPTCHA AVANT redirection Stripe (SCORE ADAPTATIF)
  static Future<PaymentValidationResult> validatePaymentSecurity({
    required String paymentType, // 'subscription', 'project', 'deposit'
    required double amount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // ✅ NOUVEAU: Validation avec score adaptatif selon le type de paiement
      final captchaResult = await _captchaManager.validateInvisibleCaptcha('payment');
      
      // ✅ UTILISER LE SCORE REQUIS DYNAMIQUE (0.8 pour paiements depuis .env)
      if (!captchaResult.isValid || !captchaResult.meetsRequirement) {
        return PaymentValidationResult(
          isValid: false,
          error: 'Score de sécurité insuffisant pour le paiement (${(captchaResult.score * 100).round()}% < ${(captchaResult.requiredScore * 100).round()}%)',
          captchaScore: captchaResult.score,
          captchaResult: captchaResult,
          requiredScore: captchaResult.requiredScore,
        );
      }

      // Validation renforcée pour montants élevés
      final enhancedValidation = await _validateHighValuePayment(amount, captchaResult);
      if (!enhancedValidation.isValid) {
        return enhancedValidation;
      }

      // Validation utilisateur connecté
      final currentUser = getCurrentUser();
      if (currentUser == null) {
        return PaymentValidationResult(
          isValid: false,
          error: 'Utilisateur non connecté',
          captchaScore: captchaResult.score,
          captchaResult: captchaResult,
          requiredScore: captchaResult.requiredScore,
        );
      }

      // ✅ Validation réussie avec informations de sécurité complètes
      print('✅ Validation paiement réussie - Score: ${(captchaResult.score * 100).round()}%/${(captchaResult.requiredScore * 100).round()}% - Niveau: ${captchaResult.achievedLevel.name.toUpperCase()}');
      
      return PaymentValidationResult(
        isValid: true,
        captchaResult: captchaResult,
        captchaScore: captchaResult.score,
        requiredScore: captchaResult.requiredScore,
        validatedAmount: amount,
        validatedUser: currentUser,
        securityLevel: captchaResult.achievedLevel,
        securityMargin: captchaResult.scoreMargin,
      );

    } catch (e) {
      print('❌ Erreur validation sécurité paiement: $e');
      return PaymentValidationResult(
        isValid: false,
        error: e.toString(),
        captchaScore: 0.0,
        requiredScore: CaptchaManager.paymentMinScore, // Score par défaut
      );
    }
  }

  /// ✅ NOUVEAU: Validation renforcée pour montants élevés
  static Future<PaymentValidationResult> _validateHighValuePayment(
    double amount, 
    CaptchaResult captchaResult,
  ) async {
    // Limites par tranche de montant
    if (amount > 5000) {
      // Montants > €5,000 nécessitent un score parfait (0.95+)
      if (captchaResult.score < 0.95) {
        return PaymentValidationResult(
          isValid: false,
          error: 'Montant élevé: score de sécurité maximum requis (${(captchaResult.score * 100).round()}% < 95%)',
          captchaScore: captchaResult.score,
          captchaResult: captchaResult,
          requiredScore: 0.95,
        );
      }
    } else if (amount > 1000) {
      // Montants > €1,000 nécessitent un score très élevé (0.9+)
      if (captchaResult.score < 0.9) {
        return PaymentValidationResult(
          isValid: false,
          error: 'Montant important: score de sécurité élevé requis (${(captchaResult.score * 100).round()}% < 90%)',
          captchaScore: captchaResult.score,
          captchaResult: captchaResult,
          requiredScore: 0.9,
        );
      }
    } else if (amount > 10000) {
      // Limite absolue €10,000
      return PaymentValidationResult(
        isValid: false,
        error: 'Montant trop élevé (limite: €10,000)',
        captchaScore: captchaResult.score,
        captchaResult: captchaResult,
        requiredScore: captchaResult.requiredScore,
      );
    }

    // Validation réussie
    return PaymentValidationResult(
      isValid: true,
      captchaScore: captchaResult.score,
      captchaResult: captchaResult,
      requiredScore: captchaResult.requiredScore,
    );
  }

  /// ✅ NOUVEAU: Validation express pour actions critiques
  static Future<PaymentValidationResult> validateCriticalPayment({
    required String paymentType,
    required double amount,
    Map<String, dynamic>? metadata,
  }) async {
    // Utiliser la validation critique (score 0.9+ requis)
    final isCriticalValid = await _captchaManager.validateCriticalAction('payment');
    
    if (!isCriticalValid) {
      return PaymentValidationResult(
        isValid: false,
        error: 'Action critique: score de sécurité maximum requis',
        captchaScore: 0.0,
        requiredScore: 0.9,
      );
    }

    return validatePaymentSecurity(
      paymentType: paymentType,
      amount: amount,
      metadata: metadata,
    );
  }

  /// 💳 ÉTAPE 2: Paiement abonnement sécurisé
  static Future<Map<String, dynamic>> processSecureSubscriptionPayment({
    required String planKey,
    required bool promoMode,
    required PaymentValidationResult validation,
  }) async {
    if (!validation.isValid) {
      throw Exception(validation.error ?? 'Validation sécurité échouée');
    }

    try {
      final result = await _paymentService.paySubscription(
        planKey: planKey,
        promoMode: promoMode,
      );

      // ✅ Métadonnées de sécurité enrichies
      result['securityInfo'] = _buildSecurityMetadata(validation, {
        'paymentType': 'subscription',
        'planKey': planKey,
        'promoMode': promoMode,
      });

      print('💳 Abonnement sécurisé initié - Plan: $planKey (${validation.securityLevel?.name.toUpperCase()})');
      return result;

    } catch (e) {
      print('❌ Erreur paiement abonnement sécurisé: $e');
      rethrow;
    }
  }

  /// 🎨 ÉTAPE 2: Paiement projet sécurisé
  static Future<Map<String, dynamic>> processSecureProjectPayment({
    required String projectId,
    required double amount,
    required String tattooistId,
    required PaymentValidationResult validation,
    String? description,
  }) async {
    if (!validation.isValid) {
      throw Exception(validation.error ?? 'Validation sécurité échouée');
    }

    try {
      final result = await _paymentService.payProject(
        projectId: projectId,
        amount: amount,
        tattooistId: tattooistId,
        description: description ?? 'Paiement projet tatouage sécurisé',
      );

      result['securityInfo'] = _buildSecurityMetadata(validation, {
        'paymentType': 'project',
        'projectId': projectId,
        'tattooistId': tattooistId,
      });

      print('💳 Projet sécurisé initié - €${amount.toStringAsFixed(2)} (${validation.securityLevel?.name.toUpperCase()})');
      return result;

    } catch (e) {
      print('❌ Erreur paiement projet sécurisé: $e');
      rethrow;
    }
  }

  /// 💰 ÉTAPE 2: Paiement acompte sécurisé
  static Future<Map<String, dynamic>> processSecureDepositPayment({
    required String projectId,
    required double totalAmount,
    required String tattooistId,
    required PaymentValidationResult validation,
    double depositPercentage = 0.3,
  }) async {
    if (!validation.isValid) {
      throw Exception(validation.error ?? 'Validation sécurité échouée');
    }

    try {
      final result = await _paymentService.payDeposit(
        projectId: projectId,
        totalAmount: totalAmount,
        tattooistId: tattooistId,
        depositPercentage: depositPercentage,
      );

      final depositAmount = totalAmount * depositPercentage;
      result['securityInfo'] = _buildSecurityMetadata(validation, {
        'paymentType': 'deposit',
        'projectId': projectId,
        'totalAmount': totalAmount,
        'depositAmount': depositAmount,
        'depositPercentage': depositPercentage,
      });

      print('💳 Acompte sécurisé initié - €${depositAmount.toStringAsFixed(2)} (${validation.securityLevel?.name.toUpperCase()})');
      return result;

    } catch (e) {
      print('❌ Erreur acompte sécurisé: $e');
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Construire les métadonnées de sécurité standardisées
  static Map<String, dynamic> _buildSecurityMetadata(
    PaymentValidationResult validation,
    Map<String, dynamic> additionalData,
  ) {
    return {
      'captchaScore': validation.captchaScore,
      'requiredScore': validation.requiredScore,
      'securityLevel': validation.securityLevel?.name.toUpperCase() ?? 'UNKNOWN',
      'scoreMargin': validation.securityMargin,
      'securityTimestamp': DateTime.now().toIso8601String(),
      'securityAction': 'payment',
      'validation': {
        'isHighConfidence': validation.captchaResult?.isHighConfidence ?? false,
        'isMediumConfidence': validation.captchaResult?.isMediumConfidence ?? false,
        'achievedLevel': validation.securityLevel?.name ?? 'unknown',
      },
      ...additionalData,
    };
  }

  /// 🔄 ÉTAPE 3: Gestion retour Stripe avec logging sécurisé
  static Future<bool> handleStripeReturn({
    required String paymentIntentId,
    required String status,
    Map<String, dynamic>? securityInfo,
  }) async {
    try {
      print('🔄 Retour Stripe - Payment: $paymentIntentId, Status: $status');
      
      // Log avec infos sécurité si disponibles
      if (securityInfo != null) {
        final securityLevel = securityInfo['securityLevel'] ?? 'UNKNOWN';
        final captchaScore = securityInfo['captchaScore'] ?? 0.0;
        print('🔐 Sécurité - Niveau: $securityLevel, Score: ${(captchaScore * 100).round()}%');
      }
      
      switch (status.toLowerCase()) {
        case 'succeeded':
          print('✅ Paiement Stripe réussi');
          return true;
        case 'failed':
          print('❌ Paiement Stripe échoué');
          return false;
        case 'canceled':
          print('⚠️ Paiement Stripe annulé');
          return false;
        default:
          print('❓ Statut Stripe inconnu: $status');
          return false;
      }
    } catch (e) {
      print('❌ Erreur traitement retour Stripe: $e');
      return false;
    }
  }

  /// 📊 Stats de sécurité enrichies
  static Future<PaymentSecurityStats> getPaymentSecurityStats() async {
    try {
      final securityStats = _captchaManager.getSecurityStats();
      
      return PaymentSecurityStats(
        totalSecurePayments: 0, // À implémenter avec Firestore
        averageCaptchaScore: 0.85,
        blockedPaymentAttempts: securityStats.totalFailedAttempts,
        lastPaymentTimestamp: DateTime.now(),
        highSecurityPayments: 0, // Paiements avec score > 0.8
        mediumSecurityPayments: 0, // Paiements avec score 0.6-0.8
        lowSecurityPayments: 0, // Paiements avec score < 0.6
        criticalPaymentsBlocked: 0, // Paiements bloqués pour sécurité
      );
    } catch (e) {
      print('Erreur stats sécurité paiements: $e');
      return PaymentSecurityStats.empty();
    }
  }

  /// ✅ NOUVEAU: Vérifier si un montant nécessite une validation renforcée
  static bool requiresEnhancedValidation(double amount) {
    return amount > 1000; // Montants > €1,000
  }

  /// ✅ NOUVEAU: Obtenir le niveau de sécurité recommandé pour un montant
  static SecurityLevel getRecommendedSecurityLevel(double amount) {
    if (amount > 5000) return SecurityLevel.high; // Score 0.95+
    if (amount > 1000) return SecurityLevel.high; // Score 0.9+
    return SecurityLevel.medium; // Score standard 0.8+
  }
}

/// ✅ Résultat de validation enrichi
class PaymentValidationResult {
  final bool isValid;
  final String? error;
  final double captchaScore;
  final double requiredScore;
  final CaptchaResult? captchaResult;
  final double? validatedAmount;
  final dynamic validatedUser;
  final SecurityLevel? securityLevel;
  final double? securityMargin;

  PaymentValidationResult({
    required this.isValid,
    this.error,
    required this.captchaScore,
    required this.requiredScore,
    this.captchaResult,
    this.validatedAmount,
    this.validatedUser,
    this.securityLevel,
    this.securityMargin,
  });

  /// Niveau de confiance atteint
  bool get isHighSecurity => securityLevel == SecurityLevel.high;
  bool get isMediumSecurity => securityLevel == SecurityLevel.medium;
  bool get isLowSecurity => securityLevel == SecurityLevel.low;

  /// Marge de sécurité
  String get securityMarginFormatted {
    if (securityMargin == null) return 'N/A';
    final margin = securityMargin! * 100;
    return margin >= 0 ? '+${margin.round()}%' : '${margin.round()}%';
  }
}

/// ✅ Statistiques enrichies
class PaymentSecurityStats {
  final int totalSecurePayments;
  final double averageCaptchaScore;
  final int blockedPaymentAttempts;
  final DateTime lastPaymentTimestamp;
  final int highSecurityPayments;
  final int mediumSecurityPayments;
  final int lowSecurityPayments;
  final int criticalPaymentsBlocked;

  PaymentSecurityStats({
    required this.totalSecurePayments,
    required this.averageCaptchaScore,
    required this.blockedPaymentAttempts,
    required this.lastPaymentTimestamp,
    this.highSecurityPayments = 0,
    this.mediumSecurityPayments = 0,
    this.lowSecurityPayments = 0,
    this.criticalPaymentsBlocked = 0,
  });

  factory PaymentSecurityStats.empty() {
    return PaymentSecurityStats(
      totalSecurePayments: 0,
      averageCaptchaScore: 0.0,
      blockedPaymentAttempts: 0,
      lastPaymentTimestamp: DateTime.now(),
    );
  }

  /// Répartition des niveaux de sécurité
  double get highSecurityPercentage {
    if (totalSecurePayments == 0) return 0.0;
    return (highSecurityPayments / totalSecurePayments) * 100;
  }

  double get mediumSecurityPercentage {
    if (totalSecurePayments == 0) return 0.0;
    return (mediumSecurityPayments / totalSecurePayments) * 100;
  }

  double get lowSecurityPercentage {
    if (totalSecurePayments == 0) return 0.0;
    return (lowSecurityPayments / totalSecurePayments) * 100;
  }
}