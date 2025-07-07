// lib/services/feature_permission_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/firestore_helper.dart'; // ✅ AJOUTÉ
import '../../core/database_manager.dart'; // ✅ AJOUTÉ pour détecter le mode
import '../auth/secure_auth_service.dart'; // ✅ AJOUTÉ pour cohérence

/// Service de gestion des permissions unifié (Production + Démo)
/// En mode démo : simule les permissions avec accès total pour les présentations
/// En mode production : utilise les vrais abonnements et restrictions
class FeaturePermissionService {
  static FeaturePermissionService? _instance;
  static FeaturePermissionService get instance => _instance ??= FeaturePermissionService._();
  FeaturePermissionService._();

  final FirebaseFirestore _firestore = FirestoreHelper.instance; // ✅ CHANGÉ

  // ✅ DONNÉES MOCK POUR LES DÉMOS
  final Map<String, dynamic> _mockUserData = {};
  final Map<String, dynamic> _mockPlans = {
    'demo_basic': {
      'name': 'Plan Basic (Démo)',
      'features': ['basic_features', 'portfolio', 'messaging'],
      'excludedFeatures': <String>[],
    },
    'demo_premium': {
      'name': 'Plan Premium (Démo)',
      'features': ['conventions', 'guest_management', 'forum', 'advanced_analytics', 'portfolio', 'messaging'],
      'excludedFeatures': <String>[],
    },
    'demo_pro': {
      'name': 'Plan Pro (Démo)',
      'features': ['conventions', 'guest_management', 'forum', 'advanced_analytics', 'portfolio', 'messaging', 'priority_support', 'custom_branding'],
      'excludedFeatures': <String>[],
    },
  };

  /// ✅ MÉTHODE PRINCIPALE - Détection automatique du mode
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  /// ✅ VÉRIFIER ACCÈS FONCTIONNALITÉ (mode auto)
  Future<bool> hasFeatureAccess(String feature) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Vérification permission: $feature');
      return await _hasFeatureAccessMock(feature);
    } else {
      print('🏭 Mode production - Vérification permission: $feature');
      return await _hasFeatureAccessFirebase(feature);
    }
  }

  /// ✅ FIREBASE - Vérification permissions réelle
  Future<bool> _hasFeatureAccessFirebase(String feature) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      final subscription = data['subscription'] as Map<String, dynamic>?;
      if (subscription == null) return false;

      final planId = subscription['planId'] as String?;
      final status = subscription['status'] as String?;
      if (status != 'active' && status != 'trialing') return false;

      final planDoc = await _firestore.collection('subscription_plans').doc(planId).get();
      if (!planDoc.exists) return false;

      final planData = planDoc.data()!;
      final features = List<String>.from(planData['features'] ?? []);
      final excluded = List<String>.from(planData['excludedFeatures'] ?? []);
      return features.contains(feature) && !excluded.contains(feature);
    } catch (e) {
      print('❌ Erreur vérification permission Firebase pour $feature: $e');
      return false;
    }
  }

  /// ✅ MOCK - Vérification permissions factice
  Future<bool> _hasFeatureAccessMock(String feature) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simuler latence
    
    final user = SecureAuthService.instance.currentUser ?? FirebaseAuth.instance.currentUser?.uid;
    if (user == null) return false;

    final userId = user is String ? user : (user['uid'] ?? user['id']);
    if (userId == null) return false;

    // Initialiser les données utilisateur démo si nécessaire
    if (!_mockUserData.containsKey(userId)) {
      _initializeMockUserData(userId);
    }

    final userData = _mockUserData[userId]!;
    final subscription = userData['subscription'] as Map<String, dynamic>?;
    if (subscription == null) return false;

    final planId = subscription['planId'] as String?;
    final status = subscription['status'] as String?;
    
    if (status != 'active' && status != 'trialing') return false;

    final plan = _mockPlans[planId];
    if (plan == null) return false;

    final features = List<String>.from(plan['features'] ?? []);
    final excluded = List<String>.from(plan['excludedFeatures'] ?? []);
    
    final hasAccess = features.contains(feature) && !excluded.contains(feature);
    print('✅ Permission démo "$feature": ${hasAccess ? "ACCORDÉE" : "REFUSÉE"} (Plan: ${plan['name']})');
    
    return hasAccess;
  }

  /// ✅ INITIALISER DONNÉES UTILISATEUR DÉMO
  void _initializeMockUserData(String userId) {
    // Créer un profil démo aléatoire mais cohérent
    final plans = ['demo_basic', 'demo_premium', 'demo_pro'];
    final selectedPlan = plans[Random().nextInt(plans.length)];
    
    _mockUserData[userId] = {
      'subscription': {
        'planId': selectedPlan,
        'status': 'active',
        'startDate': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 335)).toIso8601String(),
      },
      'profile': {
        'type': 'tatoueur',
        'verified': true,
        'joinDate': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
      },
      '_source': 'mock',
      '_demoData': true,
    };
    
    print('🎭 Profil démo initialisé: Plan ${_mockPlans[selectedPlan]!['name']}');
  }

  /// ✅ RÉCUPÉRER FONCTIONNALITÉS UTILISATEUR (mode auto)
  Future<List<String>> getUserFeatures() async {
    if (_isDemoMode) {
      return await _getUserFeaturesMock();
    } else {
      return await _getUserFeaturesFirebase();
    }
  }

  /// ✅ FIREBASE - Fonctionnalités réelles
  Future<List<String>> _getUserFeaturesFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return [];

      final data = userDoc.data()!;
      final subscription = data['subscription'] as Map<String, dynamic>?;
      if (subscription == null) return [];

      final planId = subscription['planId'] as String?;
      final status = subscription['status'] as String?;
      if (status != 'active' && status != 'trialing') return [];

      final planDoc = await _firestore.collection('subscription_plans').doc(planId).get();
      if (!planDoc.exists) return [];

      final planData = planDoc.data()!;
      final features = List<String>.from(planData['features'] ?? []);
      final excluded = List<String>.from(planData['excludedFeatures'] ?? []);
      return features.where((f) => !excluded.contains(f)).toList();
    } catch (e) {
      print('❌ Erreur récupération fonctionnalités Firebase: $e');
      return [];
    }
  }

  /// ✅ MOCK - Fonctionnalités factices
  Future<List<String>> _getUserFeaturesMock() async {
    await Future.delayed(const Duration(milliseconds: 150));
    
    final user = SecureAuthService.instance.currentUser ?? FirebaseAuth.instance.currentUser?.uid;
    if (user == null) return [];

    final userId = user is String ? user : (user['uid'] ?? user['id']);
    if (userId == null) return [];

    if (!_mockUserData.containsKey(userId)) {
      _initializeMockUserData(userId);
    }

    final userData = _mockUserData[userId]!;
    final subscription = userData['subscription'] as Map<String, dynamic>?;
    if (subscription == null) return [];

    final planId = subscription['planId'] as String?;
    final plan = _mockPlans[planId];
    if (plan == null) return [];

    final features = List<String>.from(plan['features'] ?? []);
    final excluded = List<String>.from(plan['excludedFeatures'] ?? []);
    
    return features.where((f) => !excluded.contains(f)).toList();
  }

  /// ✅ TYPE D'ABONNEMENT (mode auto)
  Future<String> getUserSubscriptionType() async {
    if (_isDemoMode) {
      return await _getUserSubscriptionTypeMock();
    } else {
      return await _getUserSubscriptionTypeFirebase();
    }
  }

  /// ✅ FIREBASE - Type abonnement réel
  Future<String> _getUserSubscriptionTypeFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'none';
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return 'none';
      
      final sub = doc.data()?['subscription'] as Map<String, dynamic>?;
      final planId = sub?['planId'] as String?;
      final status = sub?['status'] as String?;
      
      if (status != 'active' && status != 'trialing') return 'expired';
      if (planId == 'free_trial') return 'trial';
      if (planId?.contains('basic') == true) return 'basic';
      if (planId?.contains('premium') == true) return 'premium';
      if (planId?.contains('pro') == true) return 'pro';
      
      return 'unknown';
    } catch (e) {
      return 'none';
    }
  }

  /// ✅ MOCK - Type abonnement factice
  Future<String> _getUserSubscriptionTypeMock() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final user = SecureAuthService.instance.currentUser ?? FirebaseAuth.instance.currentUser?.uid;
    if (user == null) return 'none';

    final userId = user is String ? user : (user['uid'] ?? user['id']);
    if (userId == null) return 'none';

    if (!_mockUserData.containsKey(userId)) {
      _initializeMockUserData(userId);
    }

    final userData = _mockUserData[userId]!;
    final subscription = userData['subscription'] as Map<String, dynamic>?;
    if (subscription == null) return 'none';

    final planId = subscription['planId'] as String?;
    final status = subscription['status'] as String?;
    
    if (status != 'active' && status != 'trialing') return 'expired';
    
    if (planId?.contains('basic') == true) return 'basic';
    if (planId?.contains('premium') == true) return 'premium';
    if (planId?.contains('pro') == true) return 'pro';
    
    return 'demo';
  }

  /// ✅ ESSAI GRATUIT (mode auto)
  Future<bool> isOnFreeTrial() async {
    if (_isDemoMode) {
      return false; // En démo, on simule des comptes payants
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) return false;
        
        final sub = doc.data()?['subscription'] as Map<String, dynamic>?;
        return sub?['planId'] == 'free_trial' && sub?['status'] == 'trialing';
      } catch (e) {
        return false;
      }
    }
  }

  /// ✅ MÉTHODES DE VÉRIFICATION SPÉCIFIQUES (inchangées)
  Future<bool> canAccessConventions() => hasFeatureAccess('conventions');
  Future<bool> canAccessGuestManagement() => hasFeatureAccess('guest_management');
  Future<bool> canAccessForum() => hasFeatureAccess('forum');
  Future<bool> canAccessAdvancedAnalytics() => hasFeatureAccess('advanced_analytics');

  /// ✅ MÉTHODES UTILITAIRES
  bool _isSubscriptionActive(String? status) {
    return status == 'active' || status == 'trialing';
  }

  /// ✅ CHANGER PLAN DÉMO (utile pour les tests)
  Future<void> setDemoPlan(String planKey) async {
    if (!_isDemoMode) {
      print('⚠️ setDemoPlan ne fonctionne qu\'en mode démo');
      return;
    }

    final user = SecureAuthService.instance.currentUser ?? FirebaseAuth.instance.currentUser?.uid;
    if (user == null) return;

    final userId = user is String ? user : (user['uid'] ?? user['id']);
    if (userId == null) return;

    if (!_mockUserData.containsKey(userId)) {
      _initializeMockUserData(userId);
    }

    if (_mockPlans.containsKey(planKey)) {
      _mockUserData[userId]!['subscription']['planId'] = planKey;
      print('🎭 Plan démo changé: ${_mockPlans[planKey]!['name']}');
    }
  }

  /// ✅ OBTENIR INFO PLAN DÉMO
  Map<String, dynamic>? getDemoPlanInfo() {
    if (!_isDemoMode) return null;

    final user = SecureAuthService.instance.currentUser ?? FirebaseAuth.instance.currentUser?.uid;
    if (user == null) return null;

    final userId = user is String ? user : (user['uid'] ?? user['id']);
    if (userId == null) return null;

    if (!_mockUserData.containsKey(userId)) {
      _initializeMockUserData(userId);
    }

    final planId = _mockUserData[userId]!['subscription']['planId'];
    return _mockPlans[planId];
  }

  /// ✅ MÉTHODE DE DIAGNOSTIC
  Future<void> debugFeatureService() async {
    print('🔍 Debug FeaturePermissionService:');
    print('  - Mode démo: $_isDemoMode');
    print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');
    
    if (_isDemoMode) {
      print('  - Utilisateurs mock: ${_mockUserData.length}');
      print('  - Plans disponibles: ${_mockPlans.keys.join(', ')}');
      
      final planInfo = getDemoPlanInfo();
      if (planInfo != null) {
        print('  - Plan actuel: ${planInfo['name']}');
        print('  - Fonctionnalités: ${planInfo['features'].join(', ')}');
      }
    } else {
      try {
        final features = await _getUserFeaturesFirebase();
        print('  - Fonctionnalités Firebase: ${features.length} disponibles');
        final subType = await _getUserSubscriptionTypeFirebase();
        print('  - Type abonnement: $subType');
      } catch (e) {
        print('  - Erreur Firebase: $e');
      }
    }
  }

  /// ✅ CRÉER DONNÉES DE DÉMO DANS FIREBASE
  Future<void> createDemoDataInFirebase() async {
    if (!_isDemoMode) {
      print('⚠️ Cette méthode ne fonctionne qu\'en mode démo');
      return;
    }

    try {
      print('🎭 Création de plans d\'abonnement pour la démo...');
      
      // Créer les plans de démo dans Firebase
      for (final entry in _mockPlans.entries) {
        await _firestore.collection('subscription_plans').doc(entry.key).set({
          'name': entry.value['name'],
          'features': entry.value['features'],
          'excludedFeatures': entry.value['excludedFeatures'],
          'price': entry.key.contains('basic') ? 9.99 : entry.key.contains('premium') ? 19.99 : 39.99,
          'currency': 'EUR',
          'interval': 'month',
          'isDemo': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      print('✅ Plans d\'abonnement de démo créés dans Firebase');
    } catch (e) {
      print('❌ Erreur création données démo: $e');
    }
  }
}

/// ✅ Widget pour restreindre l'accès - VERSION AMÉLIORÉE
class FeatureGate extends StatefulWidget {
  final String feature;
  final Widget child;
  final Widget? premiumRequiredWidget;
  final VoidCallback? onUpgradePressed;
  final bool showDemoIndicator; // ✅ NOUVEAU: Indicateur mode démo

  const FeatureGate({
    Key? key,
    required this.feature,
    required this.child,
    this.premiumRequiredWidget,
    this.onUpgradePressed,
    this.showDemoIndicator = true, // ✅ NOUVEAU
  }) : super(key: key);

  @override
  State<FeatureGate> createState() => _FeatureGateState();
}

class _FeatureGateState extends State<FeatureGate> {
  bool _hasAccess = false;
  bool _isLoading = true;
  bool _isDemoMode = false; // ✅ NOUVEAU

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    _isDemoMode = DatabaseManager.instance.isDemoMode; // ✅ NOUVEAU
    final ok = await FeaturePermissionService.instance.hasFeatureAccess(widget.feature);
    setState(() {
      _hasAccess = ok;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_hasAccess) {
      // ✅ NOUVEAU: Wrapper avec indicateur démo si activé
      if (_isDemoMode && widget.showDemoIndicator) {
        return Stack(
          children: [
            widget.child,
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DÉMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      }
      return widget.child;
    }
    
    return widget.premiumRequiredWidget ?? _buildDefault();
  }

  Widget _buildDefault() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange.withOpacity(0.1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, color: Colors.orange, size: 48),
          const SizedBox(height: 8),
          Text(
            _isDemoMode ? 'Fonctionnalité Premium (Démo)' : 'Fonctionnalité Premium', // ✅ NOUVEAU
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(
            _isDemoMode 
                ? 'En mode réel, cette fonctionnalité nécessiterait un abonnement Premium.'
                : 'Cette fonctionnalité nécessite un abonnement Premium.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isDemoMode 
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mode démo - Upgrade simulé')),
                  )
                : (widget.onUpgradePressed ?? () => Navigator.pushNamed(context, '/subscription')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(_isDemoMode ? 'Simuler Upgrade' : 'Passer au Premium'), // ✅ NOUVEAU
          ),
        ],
      ),
    );
  }
}