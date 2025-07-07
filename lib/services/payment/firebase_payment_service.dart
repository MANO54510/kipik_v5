// lib/services/payment/firebase_payment_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kipik_v5/models/user_role.dart';
import '../../core/firestore_helper.dart'; // ✅ AJOUTÉ
import '../../core/database_manager.dart'; // ✅ AJOUTÉ pour détecter le mode
import '../auth/secure_auth_service.dart';

/// Service de paiement sécurisé unifié (Production + Démo)
/// En mode démo : simule les paiements avec des données factices
/// En mode production : utilise Firebase Functions et Stripe réel
class FirebasePaymentService {
  static FirebasePaymentService? _instance;
  static FirebasePaymentService get instance => _instance ??= FirebasePaymentService._();
  FirebasePaymentService._();

  final FirebaseFirestore _firestore = FirestoreHelper.instance; // ✅ CHANGÉ
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  static const double _platformFeePercentage = 1.0; // 1% commission KIPIK

  // ✅ DONNÉES MOCK POUR LES DÉMOS
  final List<Map<String, dynamic>> _mockTransactions = [];
  final Map<String, dynamic> _mockAccounts = {};
  
  /// ✅ MÉTHODE PRINCIPALE - Détection automatique du mode
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  /// ✅ PAYER UN ABONNEMENT (mode auto)
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

  /// ✅ FIREBASE - Paiement abonnement réel
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

  /// ✅ MOCK - Paiement abonnement factice
  Future<Map<String, dynamic>> _paySubscriptionMock({
    required String planKey, 
    required bool promoMode
  }) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simuler latence
    
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

  /// ✅ PAIEMENT PROJET (mode auto)
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

  /// ✅ FIREBASE - Paiement projet réel
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

  /// ✅ MOCK - Paiement projet factice
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

    final mockPayment = {
      'id': 'demo_pay_${Random().nextInt(99999)}',
      'status': Random().nextBool() ? 'succeeded' : 'processing',
      'amount': amount,
      'currency': 'eur',
      'projectId': projectId,
      'tattooistId': tattooistId,
      'description': description ?? '[DÉMO] Paiement projet tatouage',
      'platformFee': calculatePlatformFee(amount),
      'tattooistAmount': calculateTattooistAmount(amount),
      'created': DateTime.now().toIso8601String(),
      'userId': user['uid'] ?? user['id'],
      '_source': 'mock',
      '_demoData': true,
    };
    
    _mockTransactions.add(mockPayment);
    print('✅ Paiement projet démo: ${amount}€ (Projet: $projectId)');
    
    return mockPayment;
  }

  /// ✅ PAIEMENT ACOMPTE (mode auto)
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

  /// ✅ PAIEMENT SOLDE FINAL (mode auto)
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

  /// ✅ CRÉER COMPTE STRIPE (mode auto)
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

  /// ✅ FIREBASE - Création compte réel
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

  /// ✅ MOCK - Création compte factice
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
      'status': 'pending', // pending -> active après onboarding
      'created': DateTime.now().toIso8601String(),
      'canReceivePayments': false,
      '_source': 'mock',
      '_demoData': true,
    };
    
    _mockAccounts[userId] = mockAccount;
    print('✅ Compte Stripe démo créé: $businessName ($email)');
    
    return mockAccount;
  }

  /// ✅ LIEN D'ONBOARDING (mode auto)
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

  /// ✅ FIREBASE - Lien onboarding réel
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

  /// ✅ MOCK - Lien onboarding factice
  Future<String> _createOnboardingLinkMock({
    String? returnUrl,
    String? refreshUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    // Simuler l'onboarding en activant le compte après un délai
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

  /// ✅ DASHBOARD STRIPE (mode auto)
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

  /// ✅ STATUT COMPTE (mode auto)
  Future<Map<String, dynamic>?> getAccountStatus() async {
    if (_isDemoMode) {
      return await _getAccountStatusMock();
    } else {
      return await _getAccountStatusFirebase();
    }
  }

  /// ✅ FIREBASE - Statut compte réel
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

  /// ✅ MOCK - Statut compte factice
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

  /// ✅ HISTORIQUE PAIEMENTS (mode auto)
  Future<List<Map<String, dynamic>>> getUserPayments({int limit = 20}) async {
    if (_isDemoMode) {
      return await _getUserPaymentsMock(limit: limit);
    } else {
      return await _getUserPaymentsFirebase(limit: limit);
    }
  }

  /// ✅ FIREBASE - Historique réel
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
        
        // Masquer les données sensibles
        data.remove('stripePaymentIntentId');
        data.remove('stripeAccountId');
        data['_source'] = 'firebase';
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur historique paiements Firebase: $e');
    }
  }

  /// ✅ MOCK - Historique factice
  Future<List<Map<String, dynamic>>> _getUserPaymentsMock({int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) return [];

    final userId = user['uid'] ?? user['id'];
    if (userId == null) return [];

    // Générer des transactions factices si la liste est vide
    if (_mockTransactions.isEmpty) {
      for (int i = 0; i < 8; i++) {
        _mockTransactions.add({
          'id': 'demo_hist_${Random().nextInt(99999)}',
          'status': ['succeeded', 'succeeded', 'succeeded', 'processing'][Random().nextInt(4)],
          'amount': [50.0, 120.0, 350.0, 75.0, 200.0][Random().nextInt(5)],
          'currency': 'eur',
          'description': '[DÉMO] ${['Acompte tatouage', 'Solde final', 'Abonnement Premium', 'Consultation'][Random().nextInt(4)]}',
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

  /// ✅ STATISTIQUES TATOUEUR (mode auto)
  Future<Map<String, dynamic>?> getTattooistStats() async {
    if (_isDemoMode) {
      return await _getTattooistStatsMock();
    } else {
      return await _getTattooistStatsFirebase();
    }
  }

  /// ✅ FIREBASE - Stats réelles
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

  /// ✅ MOCK - Stats factices
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

  /// ✅ DEMANDE DE REMBOURSEMENT (mode auto)
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

  /// ✅ FIREBASE - Remboursement réel
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

  /// ✅ MOCK - Remboursement factice
  Future<void> _requestRefundMock({
    required String paymentId,
    String? reason,
    double? amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    // Simuler le remboursement
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

  /// ✅ MÉTHODE DE DIAGNOSTIC
  Future<void> debugPaymentService() async {
    print('🔍 Debug FirebasePaymentService:');
    print('  - Mode démo: $_isDemoMode');
    print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');
    print('  - Utilisateur connecté: ${isUserAuthenticated}');
    
    if (_isDemoMode) {
      print('  - Transactions mock: ${_mockTransactions.length}');
      print('  - Comptes mock: ${_mockAccounts.length}');
    } else {
      try {
        final status = await _getAccountStatusFirebase();
        print('  - Statut compte Firebase: ${status?['accountStatus'] ?? 'aucun'}');
      } catch (e) {
        print('  - Erreur statut Firebase: $e');
      }
    }
  }

  // ✅ MÉTHODES UTILITAIRES INCHANGÉES
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

  // ✅ MÉTHODES RESTANTES (inchangées mais compatibles mode auto)
  Future<List<Map<String, dynamic>>> getProjectPayments(String projectId) async {
    // TODO: Adapter avec le mode démo si nécessaire
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
}