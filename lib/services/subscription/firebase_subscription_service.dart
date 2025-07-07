// lib/services/subscription/firebase_subscription_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore_helper.dart'; // ✅ AJOUTÉ
import '../../core/database_manager.dart'; // ✅ AJOUTÉ pour détecter le mode
import '../auth/secure_auth_service.dart'; // ✅ MIGRATION: SecureAuthService

/// Service d'abonnements unifié (Production + Démo)
/// En mode démo : simule les abonnements avec des données factices
/// En mode production : utilise Firebase Firestore réel
class FirebaseSubscriptionService {
  static FirebaseSubscriptionService? _instance;
  static FirebaseSubscriptionService get instance => _instance ??= FirebaseSubscriptionService._();
  FirebaseSubscriptionService._();

  final FirebaseFirestore _firestore = FirestoreHelper.instance; // ✅ CHANGÉ

  // ✅ DONNÉES MOCK POUR LES DÉMOS
  final Map<String, Map<String, dynamic>> _mockSubscriptions = {};
  final Map<String, List<Map<String, dynamic>>> _mockSubscriptionHistory = {};
  
  /// ✅ MÉTHODE PRINCIPALE - Détection automatique du mode
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  /// ✅ OBTENIR ABONNEMENT ACTUEL (mode auto)
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Récupération abonnement factice');
      return await _getCurrentSubscriptionMock();
    } else {
      print('🏭 Mode production - Récupération abonnement réel');
      return await _getCurrentSubscriptionFirebase();
    }
  }

  /// ✅ FIREBASE - Abonnement réel
  Future<Map<String, dynamic>?> _getCurrentSubscriptionFirebase() async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return null;

      final userId = user['uid'] ?? user['id'];
      if (userId == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return null;
      
      final userData = userDoc.data()!;
      final subscriptionData = userData['subscription'] as Map<String, dynamic>?;
      
      if (subscriptionData == null) return null;

      // Convertir les Timestamps
      if (subscriptionData['currentPeriodStart'] != null) {
        subscriptionData['currentPeriodStart'] = 
            (subscriptionData['currentPeriodStart'] as Timestamp).toDate();
      }
      if (subscriptionData['currentPeriodEnd'] != null) {
        subscriptionData['currentPeriodEnd'] = 
            (subscriptionData['currentPeriodEnd'] as Timestamp).toDate();
      }
      if (subscriptionData['trialEnd'] != null) {
        subscriptionData['trialEnd'] = 
            (subscriptionData['trialEnd'] as Timestamp).toDate();
      }
      if (subscriptionData['createdAt'] != null) {
        subscriptionData['createdAt'] = 
            (subscriptionData['createdAt'] as Timestamp).toDate();
      }
      
      return subscriptionData;
    } catch (e) {
      print('Erreur récupération abonnement Firebase: $e');
      return null;
    }
  }

  /// ✅ MOCK - Abonnement factice
  Future<Map<String, dynamic>?> _getCurrentSubscriptionMock() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) return null;

    final userId = user['uid'] ?? user['id'];
    if (userId == null) return null;

    // Générer un abonnement démo si inexistant
    if (!_mockSubscriptions.containsKey(userId)) {
      _generateMockSubscription(userId);
    }

    return _mockSubscriptions[userId];
  }

  /// ✅ GÉNÉRER ABONNEMENT DÉMO
  void _generateMockSubscription(String userId) {
    final plans = [
      {
        'planId': 'demo_basic',
        'planName': 'KIPIK Basic - Démo',
        'price': 29.0,
        'features': {
          'dashboard': true,
          'appointments': true,
          'quotes': false,
          'portfolio': false,
          'chat': false,
        }
      },
      {
        'planId': 'demo_premium',
        'planName': 'KIPIK Premium - Démo',
        'price': 79.0,
        'features': {
          'dashboard': true,
          'appointments': true,
          'quotes': true,
          'portfolio': true,
          'chat': false,
        }
      },
      {
        'planId': 'demo_pro',
        'planName': 'KIPIK Pro - Démo',
        'price': 149.0,
        'features': {
          'dashboard': true,
          'appointments': true,
          'quotes': true,
          'portfolio': true,
          'chat': true,
          'analytics': true,
          'priority_support': true,
        }
      },
    ];

    final plan = plans[Random().nextInt(plans.length)];
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: Random().nextInt(15)));
    final endDate = startDate.add(const Duration(days: 30));
    final isInTrial = Random().nextBool();

    _mockSubscriptions[userId] = {
      'planId': plan['planId'],
      'planName': plan['planName'],
      'description': '[DÉMO] ${plan['planName']} avec toutes les fonctionnalités',
      'price': plan['price'],
      'currency': 'EUR',
      'status': isInTrial ? 'trialing' : 'active',
      'currentPeriodStart': startDate,
      'currentPeriodEnd': endDate,
      'trialEnd': isInTrial ? now.add(const Duration(days: 7)) : null,
      'isLifetimePromo': plan['planId'] == 'demo_pro' && Random().nextBool(),
      'paymentMethod': 'stripe',
      'autoRenew': true,
      'features': plan['features'],
      'createdAt': startDate,
      'lastUpdated': now,
      '_source': 'mock',
      '_demoData': true,
    };

    print('✅ Abonnement démo généré: ${plan['planName']} pour $userId');
  }

  /// ✅ CRÉER ABONNEMENT (mode auto)
  Future<String> createSubscription({
    required String planId,
    required String planName,
    required double price,
    required Duration duration,
    String? description,
    Map<String, dynamic>? features,
  }) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Simulation création abonnement');
      return await _createSubscriptionMock(
        planId: planId,
        planName: planName,
        price: price,
        duration: duration,
        description: description,
        features: features,
      );
    } else {
      print('🏭 Mode production - Création abonnement réel');
      return await _createSubscriptionFirebase(
        planId: planId,
        planName: planName,
        price: price,
        duration: duration,
        description: description,
        features: features,
      );
    }
  }

  /// ✅ FIREBASE - Création abonnement réel
  Future<String> _createSubscriptionFirebase({
    required String planId,
    required String planName,
    required double price,
    required Duration duration,
    String? description,
    Map<String, dynamic>? features,
  }) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final userId = user['uid'] ?? user['id'];
      if (userId == null) throw Exception('ID utilisateur invalide');

      // Annuler l'abonnement actuel s'il existe
      await _cancelCurrentSubscriptionFirebase();

      final now = DateTime.now();
      final endDate = now.add(duration);
      final trialEnd = now.add(const Duration(days: 14)); // 14 jours d'essai
      
      await _firestore.collection('users').doc(userId).update({
        'subscription': {
          'planId': planId,
          'planName': planName,
          'description': description,
          'price': price,
          'currency': 'EUR',
          'status': 'trialing', // Commence en essai
          'currentPeriodStart': FieldValue.serverTimestamp(),
          'currentPeriodEnd': Timestamp.fromDate(endDate),
          'trialEnd': Timestamp.fromDate(trialEnd),
          'isLifetimePromo': planId == 'promo_lifetime',
          'paymentMethod': 'stripe',
          'autoRenew': true,
          'features': features,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      });

      if (planId == 'promo_lifetime') {
        await _updatePromoTracking(userId);
      }

      print('✅ Abonnement créé: $planId pour utilisateur $userId');
      return userId;
    } catch (e) {
      print('❌ Erreur création abonnement Firebase: $e');
      throw Exception('Erreur création abonnement: $e');
    }
  }

  /// ✅ MOCK - Création abonnement factice
  Future<String> _createSubscriptionMock({
    required String planId,
    required String planName,
    required double price,
    required Duration duration,
    String? description,
    Map<String, dynamic>? features,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final userId = user['uid'] ?? user['id'];
    if (userId == null) throw Exception('[DÉMO] ID utilisateur invalide');

    // Simuler l'annulation de l'ancien abonnement
    await _cancelCurrentSubscriptionMock();

    final now = DateTime.now();
    final endDate = now.add(duration);
    final trialEnd = now.add(const Duration(days: 14));

    _mockSubscriptions[userId] = {
      'planId': planId,
      'planName': planName,
      'description': description ?? '[DÉMO] $planName avec toutes les fonctionnalités',
      'price': price,
      'currency': 'EUR',
      'status': 'trialing',
      'currentPeriodStart': now,
      'currentPeriodEnd': endDate,
      'trialEnd': trialEnd,
      'isLifetimePromo': planId.contains('lifetime') || planId.contains('promo'),
      'paymentMethod': 'stripe',
      'autoRenew': true,
      'features': features ?? {
        'dashboard': true,
        'appointments': true,
        'quotes': true,
        'portfolio': true,
        'chat': true,
      },
      'createdAt': now,
      'lastUpdated': now,
      '_source': 'mock',
      '_demoData': true,
    };

    // Ajouter à l'historique
    if (!_mockSubscriptionHistory.containsKey(userId)) {
      _mockSubscriptionHistory[userId] = [];
    }
    _mockSubscriptionHistory[userId]!.add(Map.from(_mockSubscriptions[userId]!));

    print('✅ Abonnement démo créé: $planName pour $userId');
    return 'demo_sub_${Random().nextInt(99999)}';
  }

  /// ✅ ANNULER ABONNEMENT ACTUEL (mode auto)
  Future<void> cancelCurrentSubscription() async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Annulation abonnement factice');
      await _cancelCurrentSubscriptionMock();
    } else {
      print('🏭 Mode production - Annulation abonnement réel');
      await _cancelCurrentSubscriptionFirebase();
    }
  }

  /// ✅ FIREBASE - Annulation réelle
  Future<void> _cancelCurrentSubscriptionFirebase() async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return;

      final userId = user['uid'] ?? user['id'];
      if (userId == null) return;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists && userDoc.data()?['subscription'] != null) {
        await _firestore.collection('users').doc(userId).update({
          'subscription.status': 'cancelled',
          'subscription.cancelledAt': FieldValue.serverTimestamp(),
          'subscription.lastUpdated': FieldValue.serverTimestamp(),
        });
        
        print('✅ Abonnement annulé pour utilisateur $userId');
      }
    } catch (e) {
      print('❌ Erreur annulation abonnement Firebase: $e');
      throw Exception('Erreur annulation abonnement: $e');
    }
  }

  /// ✅ MOCK - Annulation factice
  Future<void> _cancelCurrentSubscriptionMock() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) return;

    final userId = user['uid'] ?? user['id'];
    if (userId == null) return;

    if (_mockSubscriptions.containsKey(userId)) {
      _mockSubscriptions[userId]!['status'] = 'cancelled';
      _mockSubscriptions[userId]!['cancelledAt'] = DateTime.now();
      _mockSubscriptions[userId]!['lastUpdated'] = DateTime.now();
      
      print('✅ Abonnement démo annulé pour utilisateur $userId');
    }
  }

  /// ✅ SUSPENDRE ABONNEMENT (mode auto)
  Future<void> suspendSubscription(String userId) async {
    if (_isDemoMode) {
      await _suspendSubscriptionMock(userId);
    } else {
      await _suspendSubscriptionFirebase(userId);
    }
  }

  /// ✅ FIREBASE - Suspension réelle
  Future<void> _suspendSubscriptionFirebase(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscription.status': 'suspended',
        'subscription.suspendedAt': FieldValue.serverTimestamp(),
        'subscription.lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('✅ Abonnement suspendu pour utilisateur $userId');
    } catch (e) {
      print('❌ Erreur suspension abonnement Firebase: $e');
      throw Exception('Erreur suspension abonnement: $e');
    }
  }

  /// ✅ MOCK - Suspension factice
  Future<void> _suspendSubscriptionMock(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (_mockSubscriptions.containsKey(userId)) {
      _mockSubscriptions[userId]!['status'] = 'suspended';
      _mockSubscriptions[userId]!['suspendedAt'] = DateTime.now();
      _mockSubscriptions[userId]!['lastUpdated'] = DateTime.now();
      
      print('✅ Abonnement démo suspendu pour utilisateur $userId');
    }
  }

  /// ✅ RÉACTIVER ABONNEMENT (mode auto)
  Future<void> reactivateSubscription(String userId) async {
    if (_isDemoMode) {
      await _reactivateSubscriptionMock(userId);
    } else {
      await _reactivateSubscriptionFirebase(userId);
    }
  }

  /// ✅ FIREBASE - Réactivation réelle
  Future<void> _reactivateSubscriptionFirebase(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscription.status': 'active',
        'subscription.reactivatedAt': FieldValue.serverTimestamp(),
        'subscription.lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('✅ Abonnement réactivé pour utilisateur $userId');
    } catch (e) {
      print('❌ Erreur réactivation abonnement Firebase: $e');
      throw Exception('Erreur réactivation abonnement: $e');
    }
  }

  /// ✅ MOCK - Réactivation factice
  Future<void> _reactivateSubscriptionMock(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (_mockSubscriptions.containsKey(userId)) {
      _mockSubscriptions[userId]!['status'] = 'active';
      _mockSubscriptions[userId]!['reactivatedAt'] = DateTime.now();
      _mockSubscriptions[userId]!['lastUpdated'] = DateTime.now();
      
      print('✅ Abonnement démo réactivé pour utilisateur $userId');
    }
  }

  /// ✅ RENOUVELER ABONNEMENT (mode auto)
  Future<String> renewSubscription() async {
    if (_isDemoMode) {
      return await _renewSubscriptionMock();
    } else {
      return await _renewSubscriptionFirebase();
    }
  }

  /// ✅ FIREBASE - Renouvellement réel
  Future<String> _renewSubscriptionFirebase() async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final userId = user['uid'] ?? user['id'];
      if (userId == null) throw Exception('ID utilisateur invalide');

      final currentSubscription = await _getCurrentSubscriptionFirebase();
      if (currentSubscription == null) {
        throw Exception('Aucun abonnement à renouveler');
      }
      
      final duration = const Duration(days: 30);
      final newSubscriptionId = await _createSubscriptionFirebase(
        planId: currentSubscription['planId'],
        planName: currentSubscription['planName'],
        price: (currentSubscription['price'] as num).toDouble(),
        duration: duration,
        description: currentSubscription['description'],
        features: currentSubscription['features'],
      );

      print('✅ Abonnement renouvelé pour utilisateur $userId');
      return newSubscriptionId;
    } catch (e) {
      print('❌ Erreur renouvellement abonnement Firebase: $e');
      throw Exception('Erreur renouvellement abonnement: $e');
    }
  }

  /// ✅ MOCK - Renouvellement factice
  Future<String> _renewSubscriptionMock() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final userId = user['uid'] ?? user['id'];
    if (userId == null) throw Exception('[DÉMO] ID utilisateur invalide');

    final currentSubscription = await _getCurrentSubscriptionMock();
    if (currentSubscription == null) {
      throw Exception('[DÉMO] Aucun abonnement à renouveler');
    }
    
    final duration = const Duration(days: 30);
    final newSubscriptionId = await _createSubscriptionMock(
      planId: currentSubscription['planId'],
      planName: currentSubscription['planName'],
      price: (currentSubscription['price'] as num).toDouble(),
      duration: duration,
      description: currentSubscription['description'],
      features: currentSubscription['features'],
    );

    print('✅ Abonnement démo renouvelé pour utilisateur $userId');
    return newSubscriptionId;
  }

  /// ✅ VÉRIFIER ABONNEMENT ACTIF (mode auto)
  Future<bool> hasActiveSubscription() async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) return false;

      final status = subscription['status'] as String?;
      if (status != 'active' && status != 'trialing') return false;

      final endDate = subscription['currentPeriodEnd'] as DateTime?;
      if (endDate == null) return false;

      return DateTime.now().isBefore(endDate);
    } catch (e) {
      print('❌ Erreur vérification abonnement actif: $e');
      return false;
    }
  }

  /// ✅ VÉRIFIER FONCTIONNALITÉ (mode auto)
  Future<bool> hasFeature(String featureName) async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) return false;

      final features = subscription['features'] as Map<String, dynamic>?;
      if (features == null) return false;

      return features[featureName] == true;
    } catch (e) {
      return false;
    }
  }

  /// ✅ HISTORIQUE ABONNEMENTS (mode auto)
  Future<List<Map<String, dynamic>>> getSubscriptionHistory() async {
    if (_isDemoMode) {
      return await _getSubscriptionHistoryMock();
    } else {
      return await _getSubscriptionHistoryFirebase();
    }
  }

  /// ✅ FIREBASE - Historique réel
  Future<List<Map<String, dynamic>>> _getSubscriptionHistoryFirebase() async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return [];

      final userId = user['uid'] ?? user['id'];
      if (userId == null) return [];

      final currentSubscription = await _getCurrentSubscriptionFirebase();
      if (currentSubscription == null) return [];
      
      return [currentSubscription];
    } catch (e) {
      print('❌ Erreur récupération historique Firebase: $e');
      throw Exception('Erreur récupération historique: $e');
    }
  }

  /// ✅ MOCK - Historique factice
  Future<List<Map<String, dynamic>>> _getSubscriptionHistoryMock() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) return [];

    final userId = user['uid'] ?? user['id'];
    if (userId == null) return [];

    // Générer un historique si inexistant
    if (!_mockSubscriptionHistory.containsKey(userId)) {
      _generateMockSubscriptionHistory(userId);
    }

    return _mockSubscriptionHistory[userId] ?? [];
  }

  /// ✅ GÉNÉRER HISTORIQUE DÉMO
  void _generateMockSubscriptionHistory(String userId) {
    final history = <Map<String, dynamic>>[];
    
    for (int i = 0; i < Random().nextInt(3) + 1; i++) {
      final daysAgo = (i + 1) * 30 + Random().nextInt(15);
      final startDate = DateTime.now().subtract(Duration(days: daysAgo));
      final endDate = startDate.add(const Duration(days: 30));
      
      history.add({
        'planId': ['demo_basic', 'demo_premium'][Random().nextInt(2)],
        'planName': ['KIPIK Basic - Démo', 'KIPIK Premium - Démo'][Random().nextInt(2)],
        'price': [29.0, 79.0][Random().nextInt(2)],
        'status': i == 0 ? 'active' : 'expired',
        'currentPeriodStart': startDate,
        'currentPeriodEnd': endDate,
        'createdAt': startDate,
        '_source': 'mock',
        '_demoData': true,
      });
    }
    
    _mockSubscriptionHistory[userId] = history;
  }

  /// ✅ PLANS DISPONIBLES (mode auto)
  Future<List<Map<String, dynamic>>> getAvailablePlans() async {
    if (_isDemoMode) {
      return await _getAvailablePlansMock();
    } else {
      return await _getAvailablePlansFirebase();
    }
  }

  /// ✅ FIREBASE - Plans réels
  Future<List<Map<String, dynamic>>> _getAvailablePlansFirebase() async {
    try {
      final canHavePromo = await _canUserHavePromoPrice();
      
      final snapshot = await _firestore
          .collection('subscription_plans')
          .where('isActive', isEqualTo: true)
          .orderBy('price', descending: false)
          .get();

      final plans = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (data['planId'] == 'promo_lifetime' && !canHavePromo) {
          data['isActive'] = false;
          data['unavailableReason'] = 'Plus de places disponibles (100 premiers)';
        }
        
        return data;
      }).toList();

      return plans.where((plan) => plan['isActive'] == true).toList();
    } catch (e) {
      print('❌ Erreur récupération plans Firebase: $e');
      throw Exception('Erreur récupération plans: $e');
    }
  }

  /// ✅ MOCK - Plans factices
  Future<List<Map<String, dynamic>>> _getAvailablePlansMock() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return [
      {
        'id': 'demo_basic',
        'planId': 'demo_basic',
        'planName': 'KIPIK Basic - Démo',
        'description': '[DÉMO] Fonctionnalités de base pour débuter',
        'price': 29.0,
        'currency': 'EUR',
        'duration': 'monthly',
        'isActive': true,
        'features': {
          'dashboard': true,
          'appointments': true,
          'quotes': false,
          'portfolio': false,
          'chat': false,
        },
        'popularBadge': false,
        '_source': 'mock',
        '_demoData': true,
      },
      {
        'id': 'demo_premium',
        'planId': 'demo_premium',
        'planName': 'KIPIK Premium - Démo',
        'description': '[DÉMO] Plan complet pour professionnels',
        'price': 79.0,
        'currency': 'EUR',
        'duration': 'monthly',
        'isActive': true,
        'features': {
          'dashboard': true,
          'appointments': true,
          'quotes': true,
          'portfolio': true,
          'chat': false,
        },
        'popularBadge': true,
        '_source': 'mock',
        '_demoData': true,
      },
      {
        'id': 'demo_pro',
        'planId': 'demo_pro',
        'planName': 'KIPIK Pro - Démo',
        'description': '[DÉMO] Plan professionnel avec toutes les fonctionnalités',
        'price': 149.0,
        'currency': 'EUR',
        'duration': 'monthly',
        'isActive': true,
        'features': {
          'dashboard': true,
          'appointments': true,
          'quotes': true,
          'portfolio': true,
          'chat': true,
          'analytics': true,
          'priority_support': true,
        },
        'popularBadge': false,
        '_source': 'mock',
        '_demoData': true,
      },
    ];
  }

  /// ✅ VÉRIFIER PROMO DISPONIBLE (mode auto)
  Future<bool> _canUserHavePromoPrice() async {
    if (_isDemoMode) {
      // En mode démo, toujours autoriser la promo
      return true;
    } else {
      try {
        final promoDoc = await _firestore
            .collection('promo_tracking')
            .doc('lifetime_promo_100')
            .get();
        
        if (!promoDoc.exists) return false;
        
        final data = promoDoc.data()!;
        final remainingSlots = data['remainingSlots'] as int;
        
        return remainingSlots > 0;
      } catch (e) {
        return false;
      }
    }
  }

  /// ✅ MISE À JOUR AUTO-RENOUVELLEMENT (mode auto)
  Future<void> updateAutoRenew(bool autoRenew) async {
    if (_isDemoMode) {
      await _updateAutoRenewMock(autoRenew);
    } else {
      await _updateAutoRenewFirebase(autoRenew);
    }
  }

  /// ✅ FIREBASE - Auto-renouvellement réel
  Future<void> _updateAutoRenewFirebase(bool autoRenew) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final userId = user['uid'] ?? user['id'];
      if (userId == null) throw Exception('ID utilisateur invalide');

      await _firestore.collection('users').doc(userId).update({
        'subscription.autoRenew': autoRenew,
        'subscription.lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('✅ Auto-renouvellement mis à jour: $autoRenew');
    } catch (e) {
      print('❌ Erreur mise à jour auto-renouvellement Firebase: $e');
      throw Exception('Erreur mise à jour auto-renouvellement: $e');
    }
  }

  /// ✅ MOCK - Auto-renouvellement factice
  Future<void> _updateAutoRenewMock(bool autoRenew) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final userId = user['uid'] ?? user['id'];
    if (userId == null) throw Exception('[DÉMO] ID utilisateur invalide');

    if (_mockSubscriptions.containsKey(userId)) {
      _mockSubscriptions[userId]!['autoRenew'] = autoRenew;
      _mockSubscriptions[userId]!['lastUpdated'] = DateTime.now();
      
      print('✅ Auto-renouvellement démo mis à jour: $autoRenew');
    }
  }

  /// ✅ STATISTIQUES ABONNEMENTS (mode auto - admin uniquement)
  Future<Map<String, int>> getSubscriptionStats() async {
    if (_isDemoMode) {
      return await _getSubscriptionStatsMock();
    } else {
      return await _getSubscriptionStatsFirebase();
    }
  }

  /// ✅ FIREBASE - Stats réelles
  Future<Map<String, int>> _getSubscriptionStatsFirebase() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('subscription', isNotEqualTo: null)
          .get();
      
      int active = 0;
      int expired = 0;
      int cancelled = 0;
      int suspended = 0;
      int trialing = 0;
      int lifetimePromo = 0;
      
      for (final doc in snapshot.docs) {
        final subscription = doc.data()['subscription'] as Map<String, dynamic>?;
        if (subscription == null) continue;
        
        final status = subscription['status'] as String?;
        final isLifetime = subscription['isLifetimePromo'] as bool? ?? false;
        
        if (isLifetime) lifetimePromo++;
        
        switch (status) {
          case 'active':
            active++;
            break;
          case 'trialing':
            trialing++;
            break;
          case 'expired':
            expired++;
            break;
          case 'cancelled':
            cancelled++;
            break;
          case 'suspended':
            suspended++;
            break;
        }
      }
      
      return {
        'total': snapshot.docs.length,
        'active': active,
        'trialing': trialing,
        'expired': expired,
        'cancelled': cancelled,
        'suspended': suspended,
        'lifetimePromo': lifetimePromo,
      };
    } catch (e) {
      print('❌ Erreur récupération statistiques Firebase: $e');
      throw Exception('Erreur récupération statistiques: $e');
    }
  }

  /// ✅ MOCK - Stats factices
  Future<Map<String, int>> _getSubscriptionStatsMock() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    return {
      'total': 247,
      'active': 189,
      'trialing': 23,
      'expired': 18,
      'cancelled': 12,
      'suspended': 3,
      'lifetimePromo': 47,
    };
  }

  /// ✅ STATUT PROMO UTILISATEUR (mode auto)
  Future<Map<String, dynamic>?> getPromoStatus() async {
    if (_isDemoMode) {
      return await _getPromoStatusMock();
    } else {
      return await _getPromoStatusFirebase();
    }
  }

  /// ✅ FIREBASE - Statut promo réel
  Future<Map<String, dynamic>?> _getPromoStatusFirebase() async {
    try {
      final subscription = await _getCurrentSubscriptionFirebase();
      if (subscription == null) return null;
      
      final isLifetimePromo = subscription['isLifetimePromo'] as bool? ?? false;
      if (!isLifetimePromo) return null;
      
      final promoDoc = await _firestore
          .collection('promo_tracking')
          .doc('lifetime_promo_100')
          .get();
      
      if (!promoDoc.exists) return null;
      
      final data = promoDoc.data()!;
      final subscribers = List<Map<String, dynamic>>.from(data['subscribers'] ?? []);
      
      final user = SecureAuthService.instance.currentUser;
      final userId = user?['uid'] ?? user?['id'];
      
      final userSubscription = subscribers.firstWhere(
        (sub) => sub['userId'] == userId,
        orElse: () => {},
      );
      
      if (userSubscription.isEmpty) return null;
      
      return {
        'isLifetimePromo': true,
        'position': userSubscription['position'],
        'price': 79.0,
        'totalSlots': 100,
        'subscribedAt': userSubscription['subscribedAt'],
      };
    } catch (e) {
      print('❌ Erreur récupération statut promo Firebase: $e');
      return null;
    }
  }

  /// ✅ MOCK - Statut promo factice
  Future<Map<String, dynamic>?> _getPromoStatusMock() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final subscription = await _getCurrentSubscriptionMock();
    if (subscription == null) return null;
    
    final isLifetimePromo = subscription['isLifetimePromo'] as bool? ?? false;
    if (!isLifetimePromo) return null;
    
    return {
      'isLifetimePromo': true,
      'position': Random().nextInt(100) + 1,
      'price': 79.0,
      'totalSlots': 100,
      'subscribedAt': DateTime.now().subtract(Duration(days: Random().nextInt(30))),
      '_source': 'mock',
      '_demoData': true,
    };
  }

  /// ✅ ABONNEMENT DE TEST (mode auto)
  Future<void> createTestSubscription() async {
    try {
      await createSubscription(
        planId: _isDemoMode ? 'demo_test' : 'monthly_standard',
        planName: _isDemoMode ? 'KIPIK Test - Démo' : 'KIPIK Pro - Standard',
        price: 99.0,
        duration: const Duration(days: 30),
        description: _isDemoMode ? '[DÉMO] Abonnement KIPIK Pro de test' : 'Abonnement KIPIK Pro de test',
        features: {
          'dashboard': true,
          'appointments': true,
          'quotes': true,
          'portfolio': true,
          'chat': true,
        },
      );
      print('✅ Abonnement de test créé');
    } catch (e) {
      print('❌ Erreur création abonnement test: $e');
    }
  }

  /// ✅ MÉTHODE DE DIAGNOSTIC
  Future<void> debugSubscriptionService() async {
    print('🔍 Debug FirebaseSubscriptionService:');
    print('  - Mode démo: $_isDemoMode');
    print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');
    
    final user = SecureAuthService.instance.currentUser;
    final userId = user?['uid'] ?? user?['id'];
    
    print('  - User ID: ${userId ?? 'Non connecté'}');
    
    if (userId != null) {
      final subscription = await getCurrentSubscription();
      print('  - Abonnement actuel: ${subscription != null ? 'Oui' : 'Non'}');
      
      if (subscription != null) {
        print('  - Plan: ${subscription['planId']}');
        print('  - Statut: ${subscription['status']}');
        print('  - Prix: ${subscription['price']}€');
        print('  - Promo à vie: ${subscription['isLifetimePromo'] ?? false}');
        print('  - Source: ${subscription['_source'] ?? 'firebase'}');
      }
      
      if (_isDemoMode) {
        print('  - Abonnements mock: ${_mockSubscriptions.length}');
        print('  - Historiques mock: ${_mockSubscriptionHistory.length}');
      }
      
      final plans = await getAvailablePlans();
      print('  - Plans disponibles: ${plans.length}');
    }
    
    final stats = await getSubscriptionStats();
    print('  - Stats globales: $stats');
  }

  // ✅ MÉTHODES COMPATIBILITÉ (inchangées mais mode auto)
  Future<void> checkExpiredSubscriptions() async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Simulation vérification abonnements expirés');
      // En mode démo, pas besoin de vérifier les expirations
      return;
    }
    
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection('users')
          .where('subscription.status', whereIn: ['active', 'trialing'])
          .where('subscription.currentPeriodEnd', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'subscription.status': 'expired',
          'subscription.expiredAt': FieldValue.serverTimestamp(),
          'subscription.lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      print('✅ ${snapshot.docs.length} abonnements expirés mis à jour');
    } catch (e) {
      print('❌ Erreur vérification abonnements expirés: $e');
    }
  }

  Future<void> _updatePromoTracking(String userId) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      final userEmail = user?['email'] ?? '';

      await _firestore.runTransaction((transaction) async {
        final promoRef = _firestore.collection('promo_tracking').doc('lifetime_promo_100');
        final promoDoc = await transaction.get(promoRef);
        
        if (promoDoc.exists) {
          final data = promoDoc.data()!;
          final currentUsed = data['usedSlots'] as int;
          final subscribers = List<Map<String, dynamic>>.from(data['subscribers'] ?? []);
          
          if (currentUsed < 100) {
            subscribers.add({
              'userId': userId,
              'position': currentUsed + 1,
              'subscribedAt': FieldValue.serverTimestamp(),
              'isActive': true,
              'email': userEmail,
            });
            
            transaction.update(promoRef, {
              'usedSlots': currentUsed + 1,
              'remainingSlots': 100 - (currentUsed + 1),
              'subscribers': subscribers,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            print('✅ Promo tracking mis à jour: position ${currentUsed + 1}/100');
          }
        }
      });
    } catch (e) {
      print('❌ Erreur mise à jour promo tracking: $e');
    }
  }
}