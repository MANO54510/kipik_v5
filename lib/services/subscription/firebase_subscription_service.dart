// lib/services/subscription/firebase_subscription_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/user_subscription.dart';
import '../../core/database_manager.dart';
import '../../core/firestore_helper.dart';
import '../auth/secure_auth_service.dart';

/// Service d'abonnement unifié KIPIK
/// - Abonnements tatoueurs : SEPA automatique (99€ ou 149€/mois)
/// - Tous paiements via app : Commission 2% (Standard) ou 1% (Premium)
/// - Aucune limite de montant ou fréquence
class FirebaseSubscriptionService {
  static FirebaseSubscriptionService? _instance;
  static FirebaseSubscriptionService get instance => _instance ??= FirebaseSubscriptionService._();
  FirebaseSubscriptionService._();

  final FirebaseFirestore _firestore = FirestoreHelper.instance;
  UserSubscription? _currentSubscription;
  UserSubscription? get currentSubscription => _currentSubscription;

  // Mock data pour démo
  final Map<String, Map<String, dynamic>> _mockSubscriptions = {};
  final Map<String, List<Map<String, dynamic>>> _mockPaymentHistory = {};
  
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  /// ✅ INSCRIPTION AVEC MANDAT SEPA (30j gratuit → prélèvement auto)
  Future<SubscriptionResult> startFreeTrial({
    required String userId,
    required SubscriptionType targetType, // standard ou premium
    required Map<String, String> sepaDetails, // IBAN, nom, email
  }) async {
    try {
      print('🚀 Démarrage essai gratuit $targetType avec SEPA...');
      
      if (_isDemoMode) {
        return await _startFreeTrialDemo(userId, targetType, sepaDetails);
      }
      
      // 1. Créer Customer Stripe via API directe
      // Note: createCustomer doit être fait côté serveur pour la sécurité
      // Ici on simule avec un ID client temporaire
      final customerId = 'temp_customer_${Random().nextInt(999999)}';
      
      print('⚠️ createCustomer doit être implémenté côté serveur');
      print('Customer ID temporaire: $customerId');
      
      // 2. Setup mandat SEPA (via PaymentSheet ou Elements)
      // Note: Setup Intent doit aussi être créé côté serveur
      final setupIntentClientSecret = 'temp_setup_intent_${Random().nextInt(999999)}';
      
      print('⚠️ createSetupIntent doit être implémenté côté serveur');
      print('Setup Intent temporaire: $setupIntentClientSecret');
      
      // 3. Créer abonnement trial
      final subscription = UserSubscription.createTrial(
        userId: userId,
        targetType: targetType,
        stripeCustomerId: customerId,
        sepaSetupIntentId: setupIntentClientSecret,
      );
      
      // 4. Programmer prélèvement J+30
      await _scheduleSepaPayment(subscription);
      
      // 5. Sauvegarder
      await _saveSubscription(subscription);
      _currentSubscription = subscription;
      
      await _logActivity(userId, 'trial_started', {
        'target_type': targetType.name,
        'customer_id': customerId,
      });
      
      return SubscriptionResult.success(
        subscription: subscription,
        setupIntentClientSecret: setupIntentClientSecret,
        message: 'Essai gratuit 30j activé. Prélèvement SEPA programmé.',
      );
      
    } catch (e) {
      print('❌ Erreur création trial: $e');
      return SubscriptionResult.error('Erreur création compte: $e');
    }
  }

  /// ✅ DEMO - Version simplifiée
  Future<SubscriptionResult> _startFreeTrialDemo(String userId, SubscriptionType targetType, Map<String, String> sepaDetails) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final subscription = UserSubscription.createTrial(
      userId: userId,
      targetType: targetType,
      stripeCustomerId: 'demo_customer_$userId',
      sepaSetupIntentId: 'demo_setup_intent',
    );
    
    await _saveSubscription(subscription);
    _currentSubscription = subscription;
    
    return SubscriptionResult.success(
      subscription: subscription,
      setupIntentClientSecret: 'demo_client_secret',
      message: '[DÉMO] Essai gratuit 30j activé',
    );
  }

  /// ✅ PROGRAMMER PRÉLÈVEMENT SEPA J+30
  Future<void> _scheduleSepaPayment(UserSubscription subscription) async {
    if (_isDemoMode) return;
    
    await _firestore.collection('scheduled_sepa_payments').doc(subscription.userId).set({
      'user_id': subscription.userId,
      'stripe_customer_id': subscription.stripeCustomerId,
      'subscription_type': subscription.targetType!.name,
      'amount': subscription.targetType!.monthlyPrice,
      'trigger_date': subscription.trialEndDate,
      'status': 'scheduled',
      'created_at': FieldValue.serverTimestamp(),
    });
    
    print('📅 Prélèvement SEPA programmé: ${subscription.targetType!.monthlyPrice}€ le ${subscription.trialEndDate}');
  }

  /// ✅ ACTIVATION ABONNEMENT (appelé par webhook après prélèvement SEPA réussi)
  Future<SubscriptionResult> activateSubscription(String userId, {String? stripeSubscriptionId}) async {
    try {
      final subscription = await _loadSubscription(userId);
      if (subscription == null) {
        return SubscriptionResult.error('Abonnement introuvable');
      }
      
      final activeSubscription = subscription.copyWith(
        type: subscription.targetType!,
        status: SubscriptionStatus.active,
        trialActive: false,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        enabledFeatures: _getFeaturesForType(subscription.targetType!),
        stripeSubscriptionId: stripeSubscriptionId,
      );
      
      await _saveSubscription(activeSubscription);
      _currentSubscription = activeSubscription;
      
      await _logActivity(userId, 'subscription_activated', {
        'type': subscription.targetType!.name,
      });
      
      return SubscriptionResult.success(
        subscription: activeSubscription,
        message: 'Abonnement ${subscription.targetType!.displayName} activé !',
      );
    } catch (e) {
      return SubscriptionResult.error('Erreur activation: $e');
    }
  }

  /// ✅ DÉSABONNEMENT AVANT J+30
  Future<bool> cancelTrialBeforeCharge(String userId) async {
    try {
      final subscription = await _loadSubscription(userId);
      if (subscription == null) return false;
      
      if (!_isDemoMode) {
        await _firestore.collection('scheduled_sepa_payments').doc(userId).update({
          'status': 'cancelled',
          'cancelled_at': FieldValue.serverTimestamp(),
        });
      }
      
      final cancelled = subscription.copyWith(
        status: SubscriptionStatus.cancelled,
        endDate: DateTime.now(),
      );
      
      await _saveSubscription(cancelled);
      _currentSubscription = cancelled;
      
      await _logActivity(userId, 'trial_cancelled', {});
      
      return true;
    } catch (e) {
      print('❌ Erreur annulation: $e');
      return false;
    }
  }

  /// ✅ TRAITEMENT PAIEMENT VIA APP (tatouages, conventions, etc.)
  /// Commission: 2% (Standard) ou 1% (Premium) sur TOUT
  Future<PaymentResult> processAppPayment({
    required String payerId, // Client ou tatoueur qui paie
    required String receiverId, // Tatoueur ou organisateur qui reçoit
    required double amount,
    required String type, // 'tattoo', 'convention', 'shop_product', etc.
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Récupérer abonnement du receveur pour calculer commission
      final receiverSubscription = await _loadSubscription(receiverId);
      if (receiverSubscription == null) {
        return PaymentResult.error('Abonnement receveur introuvable');
      }
      
      // Calculer commission KIPIK
      final commissionRate = receiverSubscription.commissionRate;
      final kipikCommission = amount * commissionRate;
      final receiverAmount = amount - kipikCommission;
      
      if (_isDemoMode) {
        return await _processAppPaymentDemo(
          payerId: payerId,
          receiverId: receiverId,
          amount: amount,
          type: type,
          commission: kipikCommission,
        );
      }
      
      // Créer PaymentIntent Stripe (côté serveur en production)
      // Note: createPaymentIntent doit être fait côté serveur pour la sécurité
      final paymentClientSecret = 'temp_pi_${Random().nextInt(999999)}';
      
      print('⚠️ createPaymentIntent doit être implémenté côté serveur');
      print('PaymentIntent temporaire: $paymentClientSecret');
      
      // Transfer immédiat vers receveur (si compte Stripe Connect configuré)
      if (receiverSubscription.stripeAccountId != null) {
        // Note: createTransfer doit être fait côté serveur
        print('⚠️ createTransfer doit être implémenté côté serveur');
        print('Transfer: ${receiverAmount}€ vers ${receiverSubscription.stripeAccountId}');
      }
      
      // Log du paiement
      await _logPayment({
        'payer_id': payerId,
        'receiver_id': receiverId,
        'amount': amount,
        'kipik_commission': kipikCommission,
        'commission_rate': commissionRate,
        'type': type,
        'description': description,
        'subscription_type': receiverSubscription.type.name,
      });
      
      return PaymentResult.success(
        paymentClientSecret: paymentClientSecret,
        totalAmount: amount,
        kipikCommission: kipikCommission,
        receiverAmount: receiverAmount,
        commissionRate: commissionRate,
      );
      
    } catch (e) {
      print('❌ Erreur paiement app: $e');
      return PaymentResult.error('Erreur traitement paiement: $e');
    }
  }

  /// ✅ DEMO - Paiement simulé
  Future<PaymentResult> _processAppPaymentDemo({
    required String payerId,
    required String receiverId,
    required double amount,
    required String type,
    required double commission,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Stocker en mock
    if (!_mockPaymentHistory.containsKey(receiverId)) {
      _mockPaymentHistory[receiverId] = [];
    }
    
    _mockPaymentHistory[receiverId]!.add({
      'payer_id': payerId,
      'amount': amount,
      'commission': commission,
      'type': type,
      'created_at': DateTime.now(),
      'demo_mode': true,
    });
    
    return PaymentResult.success(
      paymentClientSecret: 'demo_pi_${Random().nextInt(999999)}',
      totalAmount: amount,
      kipikCommission: commission,
      receiverAmount: amount - commission,
      commissionRate: commission / amount,
    );
  }

  /// ✅ RACCOURCIS POUR TYPES DE PAIEMENTS SPÉCIFIQUES
  
  /// Paiement tatouage (client → tatoueur)
  Future<PaymentResult> processTattooPayment({
    required String clientId,
    required String tatoueurId,
    required double amount,
    required String projectId,
    int? installments, // Si fractionné
  }) async {
    return await processAppPayment(
      payerId: clientId,
      receiverId: tatoueurId,
      amount: amount,
      type: 'tattoo',
      description: 'Paiement tatouage',
      metadata: {
        'project_id': projectId,
        'installments': installments?.toString(),
      },
    );
  }

  /// Paiement convention (tatoueur → organisateur)
  Future<PaymentResult> processConventionPayment({
    required String tatoueurId,
    required String organisateurId,
    required double amount,
    required String conventionId,
    required String standType,
  }) async {
    return await processAppPayment(
      payerId: tatoueurId,
      receiverId: organisateurId,
      amount: amount,
      type: 'convention',
      description: 'Réservation stand convention',
      metadata: {
        'convention_id': conventionId,
        'stand_type': standType,
      },
    );
  }

  /// ✅ VÉRIFICATIONS FONCTIONNALITÉS
  bool hasAccess(PremiumFeature feature) {
    final subscription = _currentSubscription;
    if (subscription == null) return false;
    return subscription.hasFeature(feature);
  }

  bool canUseFractionalPayments() => hasAccess(PremiumFeature.fractionalPayments);
  bool canAccessConventions() => hasAccess(PremiumFeature.conventions);
  bool canUseGuestFeatures() => hasAccess(PremiumFeature.guestApplications);
  bool canUseFlashMinute() => hasAccess(PremiumFeature.flashMinute);

  /// ✅ UPGRADE ABONNEMENT
  Future<SubscriptionResult> upgradeSubscription(SubscriptionType newType) async {
    try {
      final currentSub = _currentSubscription;
      if (currentSub == null) {
        return SubscriptionResult.error('Aucun abonnement actuel');
      }
      
      if (newType.index <= currentSub.type.index) {
        return SubscriptionResult.error('Impossible de downgrader');
      }
      
      if (_isDemoMode) {
        final upgraded = currentSub.copyWith(
          type: newType,
          enabledFeatures: _getFeaturesForType(newType),
        );
        
        await _saveSubscription(upgraded);
        _currentSubscription = upgraded;
        
        return SubscriptionResult.success(
          subscription: upgraded,
          message: '[DÉMO] Abonnement upgradé vers ${newType.displayName}',
        );
      }
      
      // En production: modifier Stripe subscription
      // TODO: Implémenter modification Stripe
      
      return SubscriptionResult.success(
        subscription: currentSub,
        message: 'Upgrade en cours...',
      );
      
    } catch (e) {
      return SubscriptionResult.error('Erreur upgrade: $e');
    }
  }

  /// ✅ CALCUL ÉCONOMIES UPGRADE
  Map<String, dynamic> calculateUpgradeSavings(SubscriptionType currentType, SubscriptionType targetType) {
    final priceDiff = targetType.monthlyPrice - currentType.monthlyPrice;
    final commissionDiff = currentType.commissionRate - targetType.commissionRate;
    
    if (commissionDiff <= 0) {
      return {
        'no_savings': true,
        'message': 'Pas d\'économie de commission',
      };
    }
    
    final breakEvenAmount = priceDiff / commissionDiff;
    
    return {
      'monthly_price_increase': priceDiff,
      'commission_reduction': '${(commissionDiff * 100).toStringAsFixed(1)}%',
      'break_even_monthly_ca': breakEvenAmount,
      'savings_per_1000': commissionDiff * 1000,
      'recommended': breakEvenAmount <= 7500, // Recommandé si < 7.5k€ CA/mois
      'message': breakEvenAmount <= 5000 
          ? 'Upgrade très rentable dès ${breakEvenAmount.toStringAsFixed(0)}€ CA/mois'
          : 'Upgrade rentable à partir de ${breakEvenAmount.toStringAsFixed(0)}€ CA/mois',
    };
  }

  /// ✅ STATISTIQUES COMMISSIONS
  Future<Map<String, dynamic>> getCommissionStats(String userId, {int months = 1}) async {
    if (_isDemoMode) {
      final payments = _mockPaymentHistory[userId] ?? [];
      final totalCommissions = payments.fold(0.0, (sum, p) => sum + (p['commission'] ?? 0));
      final totalRevenue = payments.fold(0.0, (sum, p) => sum + (p['amount'] ?? 0));
      
      return {
        'total_commissions': totalCommissions,
        'total_revenue': totalRevenue,
        'payments_count': payments.length,
        'avg_commission_rate': totalRevenue > 0 ? totalCommissions / totalRevenue : 0,
        'period': 'demo_${months}_months',
        'demo_mode': true,
      };
    }
    
    try {
      final fromDate = DateTime.now().subtract(Duration(days: months * 30));
      
      final snapshot = await _firestore
          .collection('payment_logs')
          .where('receiver_id', isEqualTo: userId)
          .where('created_at', isGreaterThanOrEqualTo: fromDate)
          .get();
      
      double totalCommissions = 0;
      double totalRevenue = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalCommissions += (data['kipik_commission'] as num).toDouble();
        totalRevenue += (data['amount'] as num).toDouble();
      }
      
      return {
        'total_commissions': totalCommissions,
        'total_revenue': totalRevenue,
        'payments_count': snapshot.docs.length,
        'avg_commission_rate': totalRevenue > 0 ? totalCommissions / totalRevenue : 0,
        'period': '${months}_months',
      };
    } catch (e) {
      print('❌ Erreur stats commissions: $e');
      return {};
    }
  }

  /// ✅ HISTORIQUE PAIEMENTS
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId, {int limit = 50}) async {
    if (_isDemoMode) {
      return _mockPaymentHistory[userId] ?? [];
    }
    
    try {
      final snapshot = await _firestore
          .collection('payment_logs')
          .where('receiver_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Erreur historique paiements: $e');
      return [];
    }
  }

  /// ✅ HELPER - FEATURES POUR TYPE
  List<PremiumFeature> _getFeaturesForType(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.free:
        return []; // Aucune fonctionnalité premium
        
      case SubscriptionType.standard:
        return [
          PremiumFeature.professionalAgenda,
          PremiumFeature.fractionalPayments, // 2% commission
          PremiumFeature.clientManagement,
          PremiumFeature.advancedAnalytics,
          PremiumFeature.advancedFilters,
        ];
        
      case SubscriptionType.premium:
        return [
          // Toutes les fonctionnalités Standard
          PremiumFeature.professionalAgenda,
          PremiumFeature.fractionalPayments, // 1% commission
          PremiumFeature.clientManagement,
          PremiumFeature.advancedAnalytics,
          PremiumFeature.advancedFilters,
          // Fonctionnalités Premium exclusives
          PremiumFeature.conventions,
          PremiumFeature.guestApplications,
          PremiumFeature.guestOffers,
          PremiumFeature.flashMinute,
        ];
        
      case SubscriptionType.enterprise:
        return PremiumFeature.values; // Toutes les fonctionnalités
    }
  }

  /// ✅ GESTION BASE DE DONNÉES
  Future<void> _saveSubscription(UserSubscription subscription) async {
    if (_isDemoMode) {
      _currentSubscription = subscription;
      _mockSubscriptions[subscription.userId] = subscription.toMap();
      return;
    }
    
    await _firestore
        .collection('user_subscriptions')
        .doc(subscription.userId)
        .set(subscription.toMap(), SetOptions(merge: true));
  }

  Future<UserSubscription?> _loadSubscription(String userId) async {
    if (_isDemoMode) {
      if (_mockSubscriptions.containsKey(userId)) {
        return UserSubscription.fromMap(_mockSubscriptions[userId]!);
      }
      return UserSubscription.createPremiumDemo(userId);
    }
    
    final doc = await _firestore
        .collection('user_subscriptions')
        .doc(userId)
        .get();
    
    if (!doc.exists) return null;
    return UserSubscription.fromFirestore(doc);
  }

  Future<void> loadUserSubscription(String userId) async {
    _currentSubscription = await _loadSubscription(userId);
  }

  /// ✅ LOGGING
  Future<void> _logActivity(String userId, String action, Map<String, dynamic> metadata) async {
    if (_isDemoMode) return;
    
    try {
      await _firestore.collection('subscription_activity').add({
        'user_id': userId,
        'action': action,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur log activité: $e');
    }
  }

  Future<void> _logPayment(Map<String, dynamic> paymentData) async {
    if (_isDemoMode) return;
    
    try {
      await _firestore.collection('payment_logs').add({
        ...paymentData,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur log paiement: $e');
    }
  }

  /// ✅ ANALYTICS ABONNEMENT
  Map<String, dynamic> getSubscriptionAnalytics() {
    final subscription = _currentSubscription;
    if (subscription == null) return {'error': 'Aucun abonnement'};
    
    return {
      'type': subscription.type.displayName,
      'commission_rate': '${(subscription.commissionRate * 100).toStringAsFixed(1)}%',
      'monthly_price': '${subscription.type.monthlyPrice}€',
      'features_count': subscription.enabledFeatures.length,
      'trial_active': subscription.trialActive,
      'days_remaining': subscription.trialActive && subscription.trialEndDate != null
          ? subscription.trialEndDate!.difference(DateTime.now()).inDays
          : null,
      'status': subscription.status.name,
    };
  }

  /// ✅ DEBUG
  void debugSubscriptionService() {
    print('🔍 FirebaseSubscriptionService Debug:');
    print('  Mode: ${_isDemoMode ? "🎭 Démo" : "🏭 Production"}');
    
    final sub = _currentSubscription;
    if (sub != null) {
      print('  Abonnement: ${sub.type.displayName}');
      print('  Commission: ${(sub.commissionRate * 100).toStringAsFixed(1)}%');
      print('  Prix: ${sub.type.monthlyPrice}€/mois');
      print('  Features: ${sub.enabledFeatures.length}');
      print('  Status: ${sub.status.name}');
      
      if (sub.trialActive) {
        final daysLeft = sub.trialEndDate?.difference(DateTime.now()).inDays ?? 0;
        print('  Essai: $daysLeft jours restants');
      }
    } else {
      print('  Aucun abonnement chargé');
    }
  }
}

/// ✅ RÉSULTATS
class SubscriptionResult {
  final bool success;
  final String? error;
  final UserSubscription? subscription;
  final String? setupIntentClientSecret;
  final String? message;

  SubscriptionResult._({
    required this.success,
    this.error,
    this.subscription,
    this.setupIntentClientSecret,
    this.message,
  });

  factory SubscriptionResult.success({
    required UserSubscription subscription,
    String? setupIntentClientSecret,
    String? message,
  }) => SubscriptionResult._(
    success: true,
    subscription: subscription,
    setupIntentClientSecret: setupIntentClientSecret,
    message: message,
  );

  factory SubscriptionResult.error(String error) => SubscriptionResult._(
    success: false,
    error: error,
  );
}

class PaymentResult {
  final bool success;
  final String? error;
  final String? paymentClientSecret;
  final double? totalAmount;
  final double? kipikCommission;
  final double? receiverAmount;
  final double? commissionRate;

  PaymentResult._({
    required this.success,
    this.error,
    this.paymentClientSecret,
    this.totalAmount,
    this.kipikCommission,
    this.receiverAmount,
    this.commissionRate,
  });

  factory PaymentResult.success({
    required String paymentClientSecret,
    required double totalAmount,
    required double kipikCommission,
    required double receiverAmount,
    required double commissionRate,
  }) => PaymentResult._(
    success: true,
    paymentClientSecret: paymentClientSecret,
    totalAmount: totalAmount,
    kipikCommission: kipikCommission,
    receiverAmount: receiverAmount,
    commissionRate: commissionRate,
  );

  factory PaymentResult.error(String error) => PaymentResult._(
    success: false,
    error: error,
  );
}