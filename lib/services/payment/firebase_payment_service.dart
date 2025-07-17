// lib/services/payment/firebase_payment_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/models/payment_models.dart';
import 'package:kipik_v5/models/user_subscription.dart';
import '../../core/firestore_helper.dart';
import '../../core/database_manager.dart';
import '../auth/secure_auth_service.dart';

/// Service de paiement sécurisé unifié (Production + Démo)
/// NOUVEAU: Support des paiements fractionnés et gestion SEPA
/// En mode démo : simule les paiements avec des données factices
/// En mode production : utilise Firebase Functions et Stripe réel
class FirebasePaymentService {
  static FirebasePaymentService? _instance;
  static FirebasePaymentService get instance => _instance ??= FirebasePaymentService._();
  FirebasePaymentService._();

  final FirebaseFirestore _firestore = FirestoreHelper.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  static const double _platformFeePercentage = 1.0; // 1% commission KIPIK de base

  // ✅ DONNÉES MOCK POUR LES DÉMOS
  final List<Map<String, dynamic>> _mockTransactions = [];
  final Map<String, dynamic> _mockAccounts = {};
  final Map<String, List<FractionalPaymentOption>> _mockFractionalOptions = {};
  final Map<String, SepaMandate> _mockSepaMandates = {};

  /// ✅ MÉTHODE PRINCIPALE - Détection automatique du mode
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  // ===== PAIEMENTS FRACTIONNÉS (NOUVEAU) =====

  /// Obtenir les options de paiement fractionné disponibles pour un artiste
  Future<List<FractionalPaymentOption>> getAvailableFractionalOptions({
    required String artistId,
    required double totalAmount,
  }) async {
    if (_isDemoMode) {
      return await _getFractionalOptionsMock(artistId: artistId, totalAmount: totalAmount);
    } else {
      return await _getFractionalOptionsFirebase(artistId: artistId, totalAmount: totalAmount);
    }
  }

  /// FIREBASE - Options fractionnées réelles
  Future<List<FractionalPaymentOption>> _getFractionalOptionsFirebase({
    required String artistId,
    required double totalAmount,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('getFractionalPaymentOptions')
          .call({
        'artistId': artistId,
        'totalAmount': totalAmount,
      });

      final optionsData = List<Map<String, dynamic>>.from(result.data['options']);
      return optionsData.map((data) => FractionalPaymentOption.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Erreur récupération options fractionnées: $e');
    }
  }

  /// MOCK - Options fractionnées factices
  Future<List<FractionalPaymentOption>> _getFractionalOptionsMock({
    required String artistId,
    required double totalAmount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Simuler l'abonnement de l'artiste (Premium par défaut pour la démo)
    final artistSubscription = SubscriptionType.premium;
    
    final options = FractionalPaymentOption.generateOptions(
      totalAmount: totalAmount,
      artistSubscription: artistSubscription,
      minimumAmount: 50.0,
    );

    _mockFractionalOptions[artistId] = options;
    print('✅ Options fractionnées démo générées: ${options.length} options');
    
    return options;
  }

  /// Créer un paiement fractionné
  Future<PaymentResult> createFractionalPayment({
    required String projectId,
    required String artistId,
    required double totalAmount,
    required FractionalPaymentOption paymentOption,
  }) async {
    if (_isDemoMode) {
      return await _createFractionalPaymentMock(
        projectId: projectId,
        artistId: artistId,
        totalAmount: totalAmount,
        paymentOption: paymentOption,
      );
    } else {
      return await _createFractionalPaymentFirebase(
        projectId: projectId,
        artistId: artistId,
        totalAmount: totalAmount,
        paymentOption: paymentOption,
      );
    }
  }

  /// FIREBASE - Paiement fractionné réel
  Future<PaymentResult> _createFractionalPaymentFirebase({
    required String projectId,
    required String artistId,
    required double totalAmount,
    required FractionalPaymentOption paymentOption,
  }) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final result = await _functions
          .httpsCallable('createFractionalPayment')
          .call({
        'projectId': projectId,
        'artistId': artistId,
        'totalAmount': totalAmount,
        'paymentOption': paymentOption.toJson(),
        'userId': user['uid'] ?? user['id'],
      });

      return PaymentResult.fromJson(result.data);
    } catch (e) {
      throw Exception('Erreur création paiement fractionné: $e');
    }
  }

  /// MOCK - Paiement fractionné factice
  Future<PaymentResult> _createFractionalPaymentMock({
    required String projectId,
    required String artistId,
    required double totalAmount,
    required FractionalPaymentOption paymentOption,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final transactionId = 'demo_fract_${Random().nextInt(99999)}';
    final now = DateTime.now();

    // Simuler le premier paiement immédiat
    final firstPayment = paymentOption.paymentSchedule.first;
    
    final paymentResult = PaymentResult(
      success: true,
      transactionId: transactionId,
      totalAmount: totalAmount,
      status: PaymentStatus.succeeded,
      createdAt: now,
      metadata: {
        'type': 'fractional',
        'installments': paymentOption.installments,
        'projectId': projectId,
        'artistId': artistId,
        'firstPaymentAmount': firstPayment.amount,
        '_source': 'mock',
        '_demoData': true,
      },
    );

    // Ajouter à l'historique mock
    _mockTransactions.add({
      'id': transactionId,
      'status': 'succeeded',
      'amount': firstPayment.amount,
      'totalAmount': totalAmount,
      'currency': 'eur',
      'type': 'fractional_first',
      'description': '[DÉMO] Paiement fractionné 1/${paymentOption.installments}',
      'projectId': projectId,
      'artistId': artistId,
      'installments': paymentOption.installments,
      'created': now.toIso8601String(),
      'userId': user['uid'] ?? user['id'],
      '_source': 'mock',
      '_demoData': true,
    });

    print('✅ Paiement fractionné démo créé: ${firstPayment.amount}€ (1/${paymentOption.installments})');
    
    return paymentResult;
  }

  // ===== GESTION SEPA (NOUVEAU) =====

  /// Créer un mandat SEPA
  Future<SepaMandate> createSepaMandate({
    required String iban,
    required String bic,
    required String accountHolderName,
  }) async {
    if (_isDemoMode) {
      return await _createSepaMandateMock(
        iban: iban,
        bic: bic,
        accountHolderName: accountHolderName,
      );
    } else {
      return await _createSepaMandateFirebase(
        iban: iban,
        bic: bic,
        accountHolderName: accountHolderName,
      );
    }
  }

  /// FIREBASE - Mandat SEPA réel
  Future<SepaMandate> _createSepaMandateFirebase({
    required String iban,
    required String bic,
    required String accountHolderName,
  }) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final result = await _functions
          .httpsCallable('createSepaMandate')
          .call({
        'iban': iban,
        'bic': bic,
        'accountHolderName': accountHolderName,
        'userId': user['uid'] ?? user['id'],
      });

      return SepaMandate.fromJson(result.data);
    } catch (e) {
      throw Exception('Erreur création mandat SEPA: $e');
    }
  }

  /// MOCK - Mandat SEPA factice
  Future<SepaMandate> _createSepaMandateMock({
    required String iban,
    required String bic,
    required String accountHolderName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final userId = user['uid'] ?? user['id'];
    final mandateId = 'demo_sepa_${Random().nextInt(99999)}';
    final now = DateTime.now();

    final mandate = SepaMandate(
      mandateId: mandateId,
      userId: userId,
      iban: iban,
      bic: bic,
      accountHolderName: accountHolderName,
      status: SepaMandateStatus.active,
      createdAt: now,
      signedAt: now,
    );

    _mockSepaMandates[userId] = mandate;
    print('✅ Mandat SEPA démo créé: ${mandate.maskedIban}');
    
    return mandate;
  }

  /// Obtenir le mandat SEPA actuel
  Future<SepaMandate?> getCurrentSepaMandate() async {
    if (_isDemoMode) {
      return await _getCurrentSepaMandateMock();
    } else {
      return await _getCurrentSepaMandateFirebase();
    }
  }

  /// FIREBASE - Mandat SEPA réel
  Future<SepaMandate?> _getCurrentSepaMandateFirebase() async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return null;

      final userId = user['uid'] ?? user['id'];
      final snapshot = await _firestore
          .collection('sepa_mandates')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      
      return SepaMandate.fromJson(snapshot.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  /// MOCK - Mandat SEPA factice
  Future<SepaMandate?> _getCurrentSepaMandateMock() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) return null;

    final userId = user['uid'] ?? user['id'];
    return _mockSepaMandates[userId];
  }

  /// Révoquer un mandat SEPA
  Future<void> revokeSepaMandate({required String mandateId, String? reason}) async {
    if (_isDemoMode) {
      await _revokeSepaMandateMock(mandateId: mandateId, reason: reason);
    } else {
      await _revokeSepaMandateFirebase(mandateId: mandateId, reason: reason);
    }
  }

  /// FIREBASE - Révocation SEPA réelle
  Future<void> _revokeSepaMandateFirebase({required String mandateId, String? reason}) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _functions
          .httpsCallable('revokeSepaMandate')
          .call({
        'mandateId': mandateId,
        'reason': reason ?? 'user_requested',
        'userId': user['uid'] ?? user['id'],
      });
    } catch (e) {
      throw Exception('Erreur révocation mandat SEPA: $e');
    }
  }

  /// MOCK - Révocation SEPA factice
  Future<void> _revokeSepaMandateMock({required String mandateId, String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final userId = user['uid'] ?? user['id'];
    if (_mockSepaMandates.containsKey(userId)) {
      final mandate = _mockSepaMandates[userId]!;
      if (mandate.mandateId == mandateId) {
        _mockSepaMandates.remove(userId);
        print('✅ Mandat SEPA démo révoqué: $mandateId');
      }
    }
  }

  // ===== STATISTIQUES COMMISSIONS (NOUVEAU) =====

  /// Obtenir les statistiques de commissions pour le dashboard abonnement
  Future<Map<String, dynamic>> getCommissionStats(String userId, {int months = 1}) async {
    if (_isDemoMode) {
      return await _getCommissionStatsMock(userId, months: months);
    } else {
      return await _getCommissionStatsFirebase(userId, months: months);
    }
  }

  /// FIREBASE - Stats commissions réelles
  Future<Map<String, dynamic>> _getCommissionStatsFirebase(String userId, {int months = 1}) async {
    try {
      final result = await _functions
          .httpsCallable('getCommissionStats')
          .call({
        'userId': userId,
        'months': months,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur stats commissions: $e');
    }
  }

  /// MOCK - Stats commissions factices
  Future<Map<String, dynamic>> _getCommissionStatsMock(String userId, {int months = 1}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Générer des statistiques factices réalistes
    final totalRevenue = 1200.0 + Random().nextDouble() * 800;
    final commissionRate = 0.02; // 2% par défaut
    final totalCommissions = totalRevenue * commissionRate;
    final paymentsCount = 8 + Random().nextInt(12);

    return {
      'total_revenue': totalRevenue,
      'total_commissions': totalCommissions,
      'payments_count': paymentsCount,
      'commission_rate': commissionRate,
      'average_payment': totalRevenue / paymentsCount,
      'months': months,
      'demo_mode': true,
      '_source': 'mock',
      '_demoData': true,
    };
  }

  // ===== MÉTHODES EXISTANTES (inchangées mais améliorées) =====

  /// ✅ PAYER UN ABONNEMENT (mode auto) - inchangé
  Future<Map<String, dynamic>> paySubscription({
    required String planKey, 
    required bool promoMode
  }) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Simulation paiement abonnement');
      return await _paySubscriptionMock(planKey: planKey, promoMode: promoMode);
    } else {
      print('🏭 Mode production - Paiement abonnement réel');
      return await _paySubscriptionFirebase(planKey: planKey, promoMode: promoMode);
    }
  }

  /// ✅ FIREBASE - Paiement abonnement réel (inchangé)
  Future<Map<String, dynamic>> _paySubscriptionFirebase({
    required String planKey, 
    required bool promoMode
  }) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final result = await _functions
          .httpsCallable('createSubscriptionPayment')
          .call({
        'planKey': planKey,
        'promoMode': promoMode,
        'userId': user['uid'] ?? user['id'],
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur paiement abonnement Firebase: $e');
    }
  }

  /// ✅ MOCK - Paiement abonnement factice (inchangé)
  Future<Map<String, dynamic>> _paySubscriptionMock({
    required String planKey, 
    required bool promoMode
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final plans = {
      'basic': {'price': 9.99, 'name': 'Plan Basic'},
      'premium': {'price': 19.99, 'name': 'Plan Premium'},
      'pro': {'price': 39.99, 'name': 'Plan Professionnel'},
    };
    
    final plan = plans[planKey] ?? {'price': 9.99, 'name': 'Plan Basic'};
    final price = promoMode ? (plan['price'] as double) * 0.5 : plan['price'];
    
    final mockPayment = {
      'id': 'demo_sub_${Random().nextInt(99999)}',
      'status': 'succeeded',
      'amount': price,
      'currency': 'eur',
      'planKey': planKey,
      'planName': plan['name'],
      'promoMode': promoMode,
      'created': DateTime.now().toIso8601String(),
      'userId': user['uid'] ?? user['id'],
      '_source': 'mock',
      '_demoData': true,
    };
    
    _mockTransactions.add(mockPayment);
    print('✅ Abonnement démo payé: ${plan['name']} - ${price}€');
    
    return mockPayment;
  }

  /// ✅ PAIEMENT PROJET (mode auto) - inchangé mais amélioré
  Future<Map<String, dynamic>> payProject({
    required String projectId,
    required double amount,
    required String tattooistId,
    String? description,
  }) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Simulation paiement projet');
      return await _payProjectMock(
        projectId: projectId,
        amount: amount,
        tattooistId: tattooistId,
        description: description,
      );
    } else {
      print('🏭 Mode production - Paiement projet réel');
      return await _payProjectFirebase(
        projectId: projectId,
        amount: amount,
        tattooistId: tattooistId,
        description: description,
      );
    }
  }

  /// ✅ FIREBASE - Paiement projet réel (amélioré avec commission dynamique)
  Future<Map<String, dynamic>> _payProjectFirebase({
    required String projectId,
    required double amount,
    required String tattooistId,
    String? description,
  }) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      if (amount <= 0) throw Exception('Montant invalide');
      if (projectId.isEmpty || tattooistId.isEmpty) {
        throw Exception('Données projet invalides');
      }

      final result = await _functions
          .httpsCallable('createProjectPayment')
          .call({
        'projectId': projectId,
        'amount': amount,
        'tattooistId': tattooistId,
        'description': description ?? 'Paiement projet tatouage',
        'userId': user['uid'] ?? user['id'],
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur paiement projet Firebase: $e');
    }
  }

  /// ✅ MOCK - Paiement projet factice (amélioré)
  Future<Map<String, dynamic>> _payProjectMock({
    required String projectId,
    required double amount,
    required String tattooistId,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    if (amount <= 0) throw Exception('[DÉMO] Montant invalide');

    // Simuler un taux de commission selon un abonnement fictif
    final subscriptionType = SubscriptionType.standard; // Exemple
    final platformFee = PaymentUtils.calculatePlatformFee(amount, subscriptionType);
    final tattooistAmount = PaymentUtils.calculateArtistAmount(amount, subscriptionType);

    final mockPayment = {
      'id': 'demo_pay_${Random().nextInt(99999)}',
      'status': Random().nextBool() ? 'succeeded' : 'processing',
      'amount': amount,
      'currency': 'eur',
      'projectId': projectId,
      'tattooistId': tattooistId,
      'description': description ?? '[DÉMO] Paiement projet tatouage',
      'platformFee': platformFee,
      'tattooistAmount': tattooistAmount,
      'commissionRate': PaymentUtils.getCommissionRate(subscriptionType),
      'created': DateTime.now().toIso8601String(),
      'userId': user['uid'] ?? user['id'],
      '_source': 'mock',
      '_demoData': true,
    };
    
    _mockTransactions.add(mockPayment);
    print('✅ Paiement projet démo: ${amount}€ (Commission: ${platformFee.toStringAsFixed(2)}€)');
    
    return mockPayment;
  }

  /// ✅ PAIEMENT ACOMPTE (mode auto) - inchangé
  Future<Map<String, dynamic>> payDeposit({
    required String projectId,
    required double totalAmount,
    required String tattooistId,
    double depositPercentage = 0.3,
  }) async {
    final depositAmount = totalAmount * depositPercentage;
    
    return await payProject(
      projectId: projectId,
      amount: depositAmount,
      tattooistId: tattooistId,
      description: _isDemoMode 
          ? '[DÉMO] Acompte ${(depositPercentage * 100).round()}% - Projet $projectId'
          : 'Acompte ${(depositPercentage * 100).round()}% - Projet $projectId',
    );
  }

  /// ✅ PAIEMENT SOLDE FINAL (mode auto) - inchangé
  Future<Map<String, dynamic>> payFinalBalance({
    required String projectId,
    required double totalAmount,
    required double depositAmount,
    required String tattooistId,
  }) async {
    final finalAmount = totalAmount - depositAmount;
    
    if (finalAmount <= 0) {
      throw Exception(_isDemoMode ? '[DÉMO] Solde final invalide' : 'Solde final invalide');
    }
    
    return await payProject(
      projectId: projectId,
      amount: finalAmount,
      tattooistId: tattooistId,
      description: _isDemoMode 
          ? '[DÉMO] Solde final - Projet $projectId'
          : 'Solde final - Projet $projectId',
    );
  }

  /// ✅ CRÉER COMPTE STRIPE (mode auto) - inchangé
  Future<Map<String, dynamic>> createTattooistAccount({
    required String email,
    required String businessName,
    String country = 'FR',
  }) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Simulation création compte Stripe');
      return await _createAccountMock(email: email, businessName: businessName, country: country);
    } else {
      print('🏭 Mode production - Création compte Stripe réel');
      return await _createAccountFirebase(email: email, businessName: businessName, country: country);
    }
  }

  /// ✅ FIREBASE - Création compte réel (inchangé)
  Future<Map<String, dynamic>> _createAccountFirebase({
    required String email,
    required String businessName,
    String country = 'FR',
  }) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final result = await _functions
          .httpsCallable('createStripeAccount')
          .call({
        'email': email,
        'businessName': businessName,
        'country': country,
        'userId': user['uid'] ?? user['id'],
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur création compte Firebase: $e');
    }
  }

  /// ✅ MOCK - Création compte factice (inchangé)
  Future<Map<String, dynamic>> _createAccountMock({
    required String email,
    required String businessName,
    String country = 'FR',
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final userId = user['uid'] ?? user['id'];
    final accountId = 'demo_acct_${Random().nextInt(99999)}';
    
    final mockAccount = {
      'id': accountId,
      'email': email,
      'businessName': businessName,
      'country': country,
      'status': 'pending',
      'created': DateTime.now().toIso8601String(),
      'canReceivePayments': false,
      '_source': 'mock',
      '_demoData': true,
    };
    
    _mockAccounts[userId] = mockAccount;
    print('✅ Compte Stripe démo créé: $businessName ($email)');
    
    return mockAccount;
  }

  /// ✅ LIEN D'ONBOARDING (mode auto) - inchangé
  Future<String> createOnboardingLink({
    String? returnUrl,
    String? refreshUrl,
  }) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Simulation lien onboarding');
      return await _createOnboardingLinkMock(returnUrl: returnUrl, refreshUrl: refreshUrl);
    } else {
      print('🏭 Mode production - Lien onboarding réel');
      return await _createOnboardingLinkFirebase(returnUrl: returnUrl, refreshUrl: refreshUrl);
    }
  }

  /// ✅ FIREBASE - Lien onboarding réel (inchangé)
  Future<String> _createOnboardingLinkFirebase({
    String? returnUrl,
    String? refreshUrl,
  }) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final result = await _functions
          .httpsCallable('createOnboardingLink')
          .call({
        'returnUrl': returnUrl ?? 'https://kipik.app/onboarding/success',
        'refreshUrl': refreshUrl ?? 'https://kipik.app/onboarding/refresh',
        'userId': user['uid'] ?? user['id'],
      });

      return result.data['url'] as String;
    } catch (e) {
      throw Exception('Erreur lien onboarding Firebase: $e');
    }
  }

  /// ✅ MOCK - Lien onboarding factice (inchangé)
  Future<String> _createOnboardingLinkMock({
    String? returnUrl,
    String? refreshUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final userId = user['uid'] ?? user['id'];
    if (_mockAccounts.containsKey(userId)) {
      Future.delayed(const Duration(seconds: 3), () {
        _mockAccounts[userId]!['status'] = 'active';
        _mockAccounts[userId]!['canReceivePayments'] = true;
        print('✅ Onboarding démo terminé - Compte activé');
      });
    }
    
    return 'https://demo.stripe.com/onboarding/acct_demo_${Random().nextInt(99999)}';
  }

  /// ✅ DASHBOARD STRIPE (mode auto) - inchangé
  Future<String> createDashboardLink() async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return 'https://demo.stripe.com/dashboard/demo_${Random().nextInt(99999)}';
    } else {
      try {
        final user = SecureAuthService.instance.currentUser;
        if (user == null) throw Exception('Utilisateur non connecté');

        final result = await _functions
            .httpsCallable('createDashboardLink')
            .call({'userId': user['uid'] ?? user['id']});

        return result.data['url'] as String;
      } catch (e) {
        throw Exception('Erreur dashboard Firebase: $e');
      }
    }
  }

  /// ✅ STATUT COMPTE (mode auto) - inchangé
  Future<Map<String, dynamic>?> getAccountStatus() async {
    if (_isDemoMode) {
      return await _getAccountStatusMock();
    } else {
      return await _getAccountStatusFirebase();
    }
  }

  /// ✅ FIREBASE - Statut compte réel (inchangé)
  Future<Map<String, dynamic>?> _getAccountStatusFirebase() async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return null;

      final userId = user['uid'] ?? user['id'];
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'hasStripeAccount': data['stripeAccountId'] != null,
        'accountStatus': data['stripeAccountStatus'] ?? 'none',
        'accountCreatedAt': data['stripeAccountCreatedAt'],
        'canReceivePayments': data['stripeAccountStatus'] == 'active',
        '_source': 'firebase',
      };
    } catch (e) {
      return null;
    }
  }

  /// ✅ MOCK - Statut compte factice (inchangé)
  Future<Map<String, dynamic>?> _getAccountStatusMock() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) return null;

    final userId = user['uid'] ?? user['id'];
    if (userId == null) return null;

    if (_mockAccounts.containsKey(userId)) {
      final account = _mockAccounts[userId]!;
      return {
        'hasStripeAccount': true,
        'accountStatus': account['status'],
        'accountCreatedAt': account['created'],
        'canReceivePayments': account['canReceivePayments'],
        '_source': 'mock',
        '_demoData': true,
      };
    }

    return {
      'hasStripeAccount': false,
      'accountStatus': 'none',
      'accountCreatedAt': null,
      'canReceivePayments': false,
      '_source': 'mock',
      '_demoData': true,
    };
  }

  /// ✅ HISTORIQUE PAIEMENTS (mode auto) - inchangé
  Future<List<Map<String, dynamic>>> getUserPayments({int limit = 20}) async {
    if (_isDemoMode) {
      return await _getUserPaymentsMock(limit: limit);
    } else {
      return await _getUserPaymentsFirebase(limit: limit);
    }
  }

  /// ✅ FIREBASE - Historique réel (inchangé)
  Future<List<Map<String, dynamic>>> _getUserPaymentsFirebase({int limit = 20}) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return [];

      final userId = user['uid'] ?? user['id'];
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        
        data.remove('stripePaymentIntentId');
        data.remove('stripeAccountId');
        data['_source'] = 'firebase';
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur historique paiements Firebase: $e');
    }
  }

  /// ✅ MOCK - Historique factice (amélioré)
  Future<List<Map<String, dynamic>>> _getUserPaymentsMock({int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) return [];

    final userId = user['uid'] ?? user['id'];
    if (userId == null) return [];

    if (_mockTransactions.isEmpty) {
      for (int i = 0; i < 8; i++) {
        _mockTransactions.add({
          'id': 'demo_hist_${Random().nextInt(99999)}',
          'status': ['succeeded', 'succeeded', 'succeeded', 'processing'][Random().nextInt(4)],
          'amount': [50.0, 120.0, 350.0, 75.0, 200.0][Random().nextInt(5)],
          'currency': 'eur',
          'type': ['project', 'deposit', 'subscription', 'fractional'][Random().nextInt(4)],
          'description': '[DÉMO] ${['Acompte tatouage', 'Solde final', 'Abonnement Premium', 'Paiement fractionné'][Random().nextInt(4)]}',
          'created': DateTime.now().subtract(Duration(days: Random().nextInt(30))).toIso8601String(),
          'userId': userId,
          '_source': 'mock',
          '_demoData': true,
        });
      }
    }

    return _mockTransactions
        .where((t) => t['userId'] == userId)
        .take(limit)
        .toList();
  }

  /// ✅ STATISTIQUES TATOUEUR (mode auto) - inchangé
  Future<Map<String, dynamic>?> getTattooistStats() async {
    if (_isDemoMode) {
      return await _getTattooistStatsMock();
    } else {
      return await _getTattooistStatsFirebase();
    }
  }

  /// ✅ FIREBASE - Stats réelles (inchangé)
  Future<Map<String, dynamic>?> _getTattooistStatsFirebase() async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return null;

      final result = await _functions
          .httpsCallable('getTattooistStats')
          .call({'userId': user['uid'] ?? user['id']});

      return result.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// ✅ MOCK - Stats factices (inchangé)
  Future<Map<String, dynamic>?> _getTattooistStatsMock() async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) return null;

    return {
      'totalEarnings': 2847.50,
      'thisMonthEarnings': 420.00,
      'totalTransactions': 28,
      'thisMonthTransactions': 6,
      'averageOrderValue': 101.70,
      'topProject': '[DÉMO] Tatouage dragon japonais',
      'conversionRate': 0.68,
      'rating': 4.8,
      '_source': 'mock',
      '_demoData': true,
    };
  }

  /// ✅ DEMANDE DE REMBOURSEMENT (mode auto) - inchangé
  Future<void> requestRefund({
    required String paymentId,
    String? reason,
    double? amount,
  }) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Simulation remboursement');
      await _requestRefundMock(paymentId: paymentId, reason: reason, amount: amount);
    } else {
      print('🏭 Mode production - Remboursement réel');
      await _requestRefundFirebase(paymentId: paymentId, reason: reason, amount: amount);
    }
  }

  /// ✅ FIREBASE - Remboursement réel (inchangé)
  Future<void> _requestRefundFirebase({
    required String paymentId,
    String? reason,
    double? amount,
  }) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _functions
          .httpsCallable('requestRefund')
          .call({
        'paymentId': paymentId,
        'reason': reason ?? 'requested_by_customer',
        'amount': amount,
        'userId': user['uid'] ?? user['id'],
      });
    } catch (e) {
      throw Exception('Erreur demande remboursement Firebase: $e');
    }
  }

  /// ✅ MOCK - Remboursement factice (inchangé)
  Future<void> _requestRefundMock({
    required String paymentId,
    String? reason,
    double? amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final transactionIndex = _mockTransactions.indexWhere((t) => t['id'] == paymentId);
    if (transactionIndex != -1) {
      _mockTransactions[transactionIndex]['status'] = 'refunded';
      _mockTransactions[transactionIndex]['refundedAt'] = DateTime.now().toIso8601String();
      _mockTransactions[transactionIndex]['refundReason'] = reason ?? 'requested_by_customer';
      print('✅ Remboursement démo traité: $paymentId');
    } else {
      throw Exception('[DÉMO] Transaction introuvable');
    }
  }

  // ===== MÉTHODES RESTANTES (inchangées) =====

  Future<List<Map<String, dynamic>>> getProjectPayments(String projectId) async {
    return _isDemoMode ? [] : _getProjectPaymentsFirebase(projectId);
  }

  Future<List<Map<String, dynamic>>> _getProjectPaymentsFirebase(String projectId) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return [];

      final userId = user['uid'] ?? user['id'];
      if (userId == null) return [];

      final projectDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .get();

      if (!projectDoc.exists) throw Exception('Projet introuvable');

      final projectData = projectDoc.data()!;
      final isOwner = projectData['userId'] == userId;
      final isTattooist = projectData['tattooistId'] == userId;

      if (!isOwner && !isTattooist) {
        throw Exception('Accès non autorisé');
      }

      final snapshot = await _firestore
          .collection('transactions')
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        
        data.remove('stripePaymentIntentId');
        data.remove('stripeAccountId');
        data['_source'] = 'firebase';
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur paiements projet Firebase: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyEarnings(int year) async {
    if (_isDemoMode) {
      return List.generate(12, (month) => {
        'month': month + 1,
        'earnings': Random().nextDouble() * 500 + 100,
        'transactions': Random().nextInt(20) + 5,
        '_source': 'mock',
        '_demoData': true,
      });
    } else {
      try {
        final user = SecureAuthService.instance.currentUser;
        if (user == null) return [];

        final result = await _functions
            .httpsCallable('getMonthlyEarnings')
            .call({
          'userId': user['uid'] ?? user['id'],
          'year': year,
        });

        return List<Map<String, dynamic>>.from(result.data['earnings']);
      } catch (e) {
        return [];
      }
    }
  }

  Stream<Map<String, dynamic>?> watchPaymentStatus(String paymentId) {
    return _firestore
        .collection('transactions')
        .doc(paymentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      data.remove('stripePaymentIntentId');
      data.remove('stripeAccountId');
      
      return data;
    });
  }

  // ===== MÉTHODES AVANCÉES POUR PAIEMENTS FRACTIONNÉS =====

  /// Obtenir le statut d'un paiement fractionné
  Future<Map<String, dynamic>?> getFractionalPaymentStatus(String fractionalPaymentId) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final transaction = _mockTransactions.firstWhere(
        (t) => t['id'] == fractionalPaymentId,
        orElse: () => {},
      );
      
      if (transaction.isEmpty) return null;
      
      return {
        'id': fractionalPaymentId,
        'status': transaction['status'],
        'totalAmount': transaction['totalAmount'] ?? transaction['amount'],
        'installments': transaction['installments'] ?? 2,
        'paidInstallments': 1,
        'nextPaymentDate': DateTime.now().add(Duration(days: 30)).toIso8601String(),
        'remainingAmount': (transaction['totalAmount'] ?? transaction['amount']) - transaction['amount'],
        '_source': 'mock',
        '_demoData': true,
      };
    } else {
      try {
        final result = await _functions
            .httpsCallable('getFractionalPaymentStatus')
            .call({'fractionalPaymentId': fractionalPaymentId});
        
        return result.data as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
  }

  /// Annuler un paiement fractionné restant
  Future<void> cancelFractionalPayment(String fractionalPaymentId, {String? reason}) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      
      final transactionIndex = _mockTransactions.indexWhere((t) => t['id'] == fractionalPaymentId);
      if (transactionIndex != -1) {
        _mockTransactions[transactionIndex]['status'] = 'cancelled';
        _mockTransactions[transactionIndex]['cancelledAt'] = DateTime.now().toIso8601String();
        _mockTransactions[transactionIndex]['cancelReason'] = reason ?? 'user_requested';
        print('✅ Paiement fractionné démo annulé: $fractionalPaymentId');
      }
    } else {
      try {
        final user = SecureAuthService.instance.currentUser;
        if (user == null) throw Exception('Utilisateur non connecté');

        await _functions
            .httpsCallable('cancelFractionalPayment')
            .call({
          'fractionalPaymentId': fractionalPaymentId,
          'reason': reason ?? 'user_requested',
          'userId': user['uid'] ?? user['id'],
        });
      } catch (e) {
        throw Exception('Erreur annulation paiement fractionné: $e');
      }
    }
  }

  /// Obtenir les paiements fractionnés d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserFractionalPayments() async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return [];

      final userId = user['uid'] ?? user['id'];
      
      return _mockTransactions
          .where((t) => t['userId'] == userId && t['type'] == 'fractional')
          .toList();
    } else {
      try {
        final user = SecureAuthService.instance.currentUser;
        if (user == null) return [];

        final result = await _functions
            .httpsCallable('getUserFractionalPayments')
            .call({'userId': user['uid'] ?? user['id']});

        return List<Map<String, dynamic>>.from(result.data['payments']);
      } catch (e) {
        return [];
      }
    }
  }

  // ===== UTILITAIRES SEPA AVANCÉS =====

  /// Vérifier la validité d'un IBAN avec l'API bancaire
  Future<Map<String, dynamic>> validateIbanWithApi(String iban) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final isValid = PaymentUtils.isValidIban(iban);
      return {
        'valid': isValid,
        'iban': iban,
        'country': iban.substring(0, 2),
        'bankName': isValid ? '[DÉMO] Banque Populaire' : null,
        'accountType': isValid ? 'checking' : null,
        '_source': 'mock',
        '_demoData': true,
      };
    } else {
      try {
        final result = await _functions
            .httpsCallable('validateIban')
            .call({'iban': iban});
        
        return result.data as Map<String, dynamic>;
      } catch (e) {
        return {
          'valid': false,
          'error': 'Erreur validation IBAN: $e',
        };
      }
    }
  }

  /// Obtenir l'historique des mandats SEPA
  Future<List<SepaMandate>> getSepaHistory() async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return [];

      final userId = user['uid'] ?? user['id'];
      final currentMandate = _mockSepaMandates[userId];
      
      return currentMandate != null ? [currentMandate] : [];
    } else {
      try {
        final user = SecureAuthService.instance.currentUser;
        if (user == null) return [];

        final snapshot = await _firestore
            .collection('sepa_mandates')
            .where('userId', isEqualTo: user['uid'] ?? user['id'])
            .orderBy('createdAt', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => SepaMandate.fromJson(doc.data()))
            .toList();
      } catch (e) {
        return [];
      }
    }
  }

  // ===== NOTIFICATIONS ET WEBHOOKS =====

  /// Configurer les notifications de paiement
  Future<void> configurePaymentNotifications({
    required bool emailNotifications,
    required bool smsNotifications,
    required bool pushNotifications,
  }) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      print('✅ Notifications démo configurées');
      return;
    }

    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _functions
          .httpsCallable('configurePaymentNotifications')
          .call({
        'emailNotifications': emailNotifications,
        'smsNotifications': smsNotifications,
        'pushNotifications': pushNotifications,
        'userId': user['uid'] ?? user['id'],
      });
    } catch (e) {
      throw Exception('Erreur configuration notifications: $e');
    }
  }

  /// Obtenir les préférences de notification actuelles
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return {
        'emailNotifications': true,
        'smsNotifications': false,
        'pushNotifications': true,
        '_source': 'mock',
        '_demoData': true,
      };
    }

    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return {};

      final doc = await _firestore
          .collection('user_preferences')
          .doc(user['uid'] ?? user['id'])
          .get();

      if (!doc.exists) return {};

      final data = doc.data()!;
      return {
        'emailNotifications': data['emailNotifications'] ?? true,
        'smsNotifications': data['smsNotifications'] ?? false,
        'pushNotifications': data['pushNotifications'] ?? true,
        '_source': 'firebase',
      };
    } catch (e) {
      return {};
    }
  }

  // ===== SÉCURITÉ ET AUDIT =====

  /// Logger une action de paiement pour audit
  Future<void> _logPaymentAction(String action, Map<String, dynamic> details) async {
    if (!_isDemoMode) {
      try {
        await _firestore.collection('payment_audit_logs').add({
          'action': action,
          'details': details,
          'userId': _getCurrentUserId(),
          'timestamp': FieldValue.serverTimestamp(),
          'userAgent': 'flutter_app',
          'ip': 'unknown',
        });
      } catch (e) {
        print('Erreur logging audit: $e');
      }
    }
  }

  /// Vérifier les limites de paiement de l'utilisateur
  Future<Map<String, dynamic>> checkPaymentLimits(double amount) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return {
        'allowed': amount <= 5000.0,
        'dailyLimit': 5000.0,
        'monthlyLimit': 20000.0,
        'dailyUsed': Random().nextDouble() * 1000,
        'monthlyUsed': Random().nextDouble() * 5000,
        '_source': 'mock',
        '_demoData': true,
      };
    }

    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final result = await _functions
          .httpsCallable('checkPaymentLimits')
          .call({
        'amount': amount,
        'userId': user['uid'] ?? user['id'],
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur vérification limites: $e');
    }
  }

  // ===== MÉTHODES UTILITAIRES ÉTENDUES =====

  /// Vérifier si un utilisateur peut utiliser les paiements fractionnés
  Future<bool> canUseFractionalPayments(String artistId) async {
    try {
      if (_isDemoMode) {
        return true;
      }
      
      final result = await _functions
          .httpsCallable('checkFractionalPaymentEligibility')
          .call({'artistId': artistId});
      
      return result.data['eligible'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Calculer la commission selon l'abonnement
  double calculateCommissionForAmount(double amount, SubscriptionType subscriptionType) {
    return PaymentUtils.calculatePlatformFee(amount, subscriptionType);
  }

  /// Valider un IBAN
  bool validateIban(String iban) {
    return PaymentUtils.isValidIban(iban);
  }

  /// Formater un IBAN pour l'affichage
  String formatIban(String iban) {
    return PaymentUtils.formatIban(iban);
  }

  /// ✅ MÉTHODE DE DIAGNOSTIC ÉTENDUE
  Future<void> debugPaymentService() async {
    print('🔍 Debug FirebasePaymentService Enhanced:');
    print('  - Mode démo: $_isDemoMode');
    print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');
    print('  - Utilisateur connecté: ${isUserAuthenticated}');
    
    if (_isDemoMode) {
      print('  - Transactions mock: ${_mockTransactions.length}');
      print('  - Comptes mock: ${_mockAccounts.length}');
      print('  - Options fractionnées mock: ${_mockFractionalOptions.length}');
      print('  - Mandats SEPA mock: ${_mockSepaMandates.length}');
    } else {
      try {
        final status = await _getAccountStatusFirebase();
        print('  - Statut compte Firebase: ${status?['accountStatus'] ?? 'aucun'}');
      } catch (e) {
        print('  - Erreur statut Firebase: $e');
      }
    }
  }

  // ===== MÉTHODES UTILITAIRES INCHANGÉES
  String? _getCurrentUserId() {
    final user = SecureAuthService.instance.currentUser;
    if (user == null) return null;
    return user['uid'] ?? user['id'];
  }

  bool get isUserAuthenticated {
    return SecureAuthService.instance.isAuthenticated;
  }

  UserRole? get currentUserRole {
    return SecureAuthService.instance.currentUserRole;
  }

  static double calculatePlatformFee(double amount) {
    return (amount * _platformFeePercentage / 100);
  }

  static double calculateTattooistAmount(double totalAmount) {
    return totalAmount - calculatePlatformFee(totalAmount);
  }

  bool canProcessPayments() {
    if (!isUserAuthenticated) return false;
    
    final role = currentUserRole;
    return role == UserRole.client || 
           role == UserRole.tatoueur || 
           role == UserRole.admin;
  }

  bool canViewStats() {
    if (!isUserAuthenticated) return false;
    
    final role = currentUserRole;
    return role == UserRole.tatoueur || 
           role == UserRole.admin;
  }

  bool canManageStripeAccount() {
    if (!isUserAuthenticated) return false;
    
    final role = currentUserRole;
    return role == UserRole.tatoueur || 
           role == UserRole.admin;
  }

  Future<bool> canReceivePayments() async {
    try {
      final status = await getAccountStatus();
      return status?['canReceivePayments'] == true;
    } catch (e) {
      return false;
    }
  }

  // ===== ALIAS POUR COMPATIBILITÉ =====

  /// Alias pour maintenir la compatibilité avec l'ancienne API
  Future<Map<String, dynamic>> processPayment({
    required String projectId,
    required double amount,
    required String tattooistId,
    String? description,
  }) async {
    return await payProject(
      projectId: projectId,
      amount: amount,
      tattooistId: tattooistId,
      description: description,
    );
  }

  /// Alias pour l'instance singleton (compatibilité)
  static FirebasePaymentService getInstance() => instance;
}