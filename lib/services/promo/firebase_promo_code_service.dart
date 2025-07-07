// lib/services/promo/firebase_promo_code_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore_helper.dart'; // ✅ AJOUTÉ
import '../../core/database_manager.dart'; // ✅ AJOUTÉ pour détecter le mode
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/models/user_role.dart';

/// Service de gestion des codes promo unifié (Production + Démo)
/// En mode démo : simule les codes avec données factices et validations
/// En mode production : utilise Firestore réel
class FirebasePromoCodeService {
  static FirebasePromoCodeService? _instance;
  static FirebasePromoCodeService get instance => _instance ??= FirebasePromoCodeService._();
  FirebasePromoCodeService._();

  final FirebaseFirestore _firestore = FirestoreHelper.instance; // ✅ CHANGÉ

  // ✅ DONNÉES MOCK POUR LES DÉMOS
  final List<Map<String, dynamic>> _mockPromoCodes = [];
  final List<Map<String, dynamic>> _mockPromoUses = [];
  final Map<String, List<Map<String, dynamic>>> _mockUserReferrals = {};

  /// ✅ MÉTHODE PRINCIPALE - Détection automatique du mode
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  /// ✅ VALIDER CODE PROMO (mode auto)
  Future<Map<String, dynamic>?> validatePromoCode(String code) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Validation code promo: $code');
      return await _validatePromoCodeMock(code);
    } else {
      print('🏭 Mode production - Validation code promo: $code');
      return await _validatePromoCodeFirebase(code);
    }
  }

  /// ✅ FIREBASE - Validation code réelle
  Future<Map<String, dynamic>?> _validatePromoCodeFirebase(String code) async {
    try {
      final snapshot = await _firestore
          .collection('promo_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final promoData = snapshot.docs.first.data();
      final now = DateTime.now();
      final expiresAt = (promoData['expiresAt'] as Timestamp?)?.toDate();

      if (expiresAt != null && now.isAfter(expiresAt)) {
        return null;
      }

      final maxUses = promoData['maxUses'] as int?;
      final currentUses = promoData['currentUses'] as int? ?? 0;
           
      if (maxUses != null && currentUses >= maxUses) {
        return null;
      }

      return promoData;
    } catch (e) {
      print('❌ Erreur validation code promo Firebase: $e');
      return null;
    }
  }

  /// ✅ MOCK - Validation code factice
  Future<Map<String, dynamic>?> _validatePromoCodeMock(String code) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _initializeMockPromoCodes();

    try {
      final promo = _mockPromoCodes.firstWhere(
        (p) => (p['code'] as String).toUpperCase() == code.toUpperCase() && p['isActive'] == true,
      );

      final now = DateTime.now();
      final expiresAt = promo['expiresAt'] as DateTime?;

      if (expiresAt != null && now.isAfter(expiresAt)) {
        print('❌ Code démo expiré: $code');
        return null;
      }

      final maxUses = promo['maxUses'] as int?;
      final currentUses = promo['currentUses'] as int? ?? 0;
           
      if (maxUses != null && currentUses >= maxUses) {
        print('❌ Code démo épuisé: $code');
        return null;
      }

      print('✅ Code démo valide: $code (${promo['description']})');
      return Map<String, dynamic>.from(promo);
    } catch (e) {
      print('❌ Code démo invalide: $code');
      return null;
    }
  }

  /// ✅ INITIALISER CODES PROMO DÉMO
  void _initializeMockPromoCodes() {
    if (_mockPromoCodes.isNotEmpty) return;

    _mockPromoCodes.addAll([
      {
        'id': 'demo_promo_1',
        'code': 'DEMO10',
        'type': 'percentage',
        'value': 10.0,
        'description': '[DÉMO] Code de bienvenue - 10% de réduction',
        'expiresAt': DateTime.now().add(const Duration(days: 30)),
        'maxUses': 100,
        'currentUses': Random().nextInt(20),
        'minOrderAmount': 50.0,
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
        'createdBy': 'demo_admin',
        '_source': 'mock',
        '_demoData': true,
      },
      {
        'id': 'demo_promo_2',
        'code': 'FIXE20',
        'type': 'fixed',
        'value': 20.0,
        'description': '[DÉMO] Réduction fixe de 20€',
        'expiresAt': DateTime.now().add(const Duration(days: 60)),
        'maxUses': 50,
        'currentUses': Random().nextInt(15),
        'minOrderAmount': 100.0,
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 20)),
        'createdBy': 'demo_admin',
        '_source': 'mock',
        '_demoData': true,
      },
      {
        'id': 'demo_promo_3',
        'code': 'TATTOO15',
        'type': 'percentage',
        'value': 15.0,
        'description': '[DÉMO] Spécial tatouage - 15% de réduction',
        'expiresAt': DateTime.now().add(const Duration(days: 90)),
        'maxUses': null,
        'currentUses': Random().nextInt(30),
        'allowedCategories': ['tatouage', 'convention'],
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'createdBy': 'demo_admin',
        '_source': 'mock',
        '_demoData': true,
      },
      {
        'id': 'demo_promo_4',
        'code': 'WELCOME50',
        'type': 'percentage',
        'value': 50.0,
        'description': '[DÉMO] Méga réduction - 50% pour les nouveaux clients',
        'expiresAt': DateTime.now().add(const Duration(days: 15)),
        'maxUses': 10,
        'currentUses': Random().nextInt(8),
        'minOrderAmount': 200.0,
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'createdBy': 'demo_admin',
        '_source': 'mock',
        '_demoData': true,
      },
      {
        'id': 'demo_promo_5',
        'code': 'EXPIRED',
        'type': 'percentage',
        'value': 25.0,
        'description': '[DÉMO] Code expiré pour test',
        'expiresAt': DateTime.now().subtract(const Duration(days: 1)),
        'maxUses': 100,
        'currentUses': 5,
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 30)),
        'createdBy': 'demo_admin',
        '_source': 'mock',
        '_demoData': true,
      },
    ]);

    print('🎭 ${_mockPromoCodes.length} codes promo démo initialisés');
  }

  /// ✅ UTILISER CODE PROMO (mode auto)
  Future<void> usePromoCode(String code) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Utilisation code promo: $code');
      await _usePromoCodeMock(code);
    } else {
      print('🏭 Mode production - Utilisation code promo: $code');
      await _usePromoCodeFirebase(code);
    }
  }

  /// ✅ FIREBASE - Utilisation code réelle
  Future<void> _usePromoCodeFirebase(String code) async {
    try {
      final currentUserId = SecureAuthService.instance.currentUserId;
      
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final snapshot = await _firestore
          .collection('promo_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docRef = snapshot.docs.first.reference;
             
        await _firestore.runTransaction((transaction) async {
          final doc = await transaction.get(docRef);
          final currentUses = doc.data()?['currentUses'] as int? ?? 0;
                   
          transaction.update(docRef, {
            'currentUses': currentUses + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          transaction.set(
            _firestore.collection('promo_code_uses').doc(),
            {
              'code': code,
              'userId': currentUserId,
              'usedAt': FieldValue.serverTimestamp(),
            },
          );
        });
      }
    } catch (e) {
      throw Exception('Erreur utilisation code promo Firebase: $e');
    }
  }

  /// ✅ MOCK - Utilisation code factice
  Future<void> _usePromoCodeMock(String code) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final currentUserId = SecureAuthService.instance.currentUserId;
    
    if (currentUserId == null) {
      throw Exception('[DÉMO] Utilisateur non connecté');
    }

    _initializeMockPromoCodes();

    final promoIndex = _mockPromoCodes.indexWhere(
      (p) => (p['code'] as String).toUpperCase() == code.toUpperCase(),
    );

    if (promoIndex != -1) {
      final promo = _mockPromoCodes[promoIndex];
      final currentUses = promo['currentUses'] as int? ?? 0;
      
      _mockPromoCodes[promoIndex] = {
        ...promo,
        'currentUses': currentUses + 1,
        'updatedAt': DateTime.now(),
      };

      _mockPromoUses.add({
        'id': 'demo_use_${DateTime.now().millisecondsSinceEpoch}',
        'code': code.toUpperCase(),
        'userId': currentUserId,
        'usedAt': DateTime.now(),
        '_source': 'mock',
        '_demoData': true,
      });

      print('✅ Code démo utilisé: $code (utilisation #${currentUses + 1})');
    }
  }

  /// ✅ CRÉER CODE PROMO (mode auto)
  Future<String> createPromoCode({
    required String code,
    required String type,
    required double value,
    String? description,
    DateTime? expiresAt,
    int? maxUses,
    double? minOrderAmount,
    List<String>? allowedCategories,
    String? createdBy,
  }) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Création code promo: $code');
      return await _createPromoCodeMock(
        code: code,
        type: type,
        value: value,
        description: description,
        expiresAt: expiresAt,
        maxUses: maxUses,
        minOrderAmount: minOrderAmount,
        allowedCategories: allowedCategories,
        createdBy: createdBy,
      );
    } else {
      print('🏭 Mode production - Création code promo: $code');
      return await _createPromoCodeFirebase(
        code: code,
        type: type,
        value: value,
        description: description,
        expiresAt: expiresAt,
        maxUses: maxUses,
        minOrderAmount: minOrderAmount,
        allowedCategories: allowedCategories,
        createdBy: createdBy,
      );
    }
  }

  /// ✅ FIREBASE - Création code réelle
  Future<String> _createPromoCodeFirebase({
    required String code,
    required String type,
    required double value,
    String? description,
    DateTime? expiresAt,
    int? maxUses,
    double? minOrderAmount,
    List<String>? allowedCategories,
    String? createdBy,
  }) async {
    try {
      final currentUserRole = SecureAuthService.instance.currentUserRole;
      if (type != 'referral' && currentUserRole != UserRole.admin) {
        throw Exception('Seuls les administrateurs peuvent créer des codes promo généraux');
      }

      final docRef = await _firestore.collection('promo_codes').add({
        'code': code.toUpperCase(),
        'type': type,
        'value': value,
        'description': description,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'maxUses': maxUses,
        'currentUses': 0,
        'minOrderAmount': minOrderAmount,
        'allowedCategories': allowedCategories,
        'createdBy': createdBy ?? SecureAuthService.instance.currentUserId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur création code promo Firebase: $e');
    }
  }

  /// ✅ MOCK - Création code factice
  Future<String> _createPromoCodeMock({
    required String code,
    required String type,
    required double value,
    String? description,
    DateTime? expiresAt,
    int? maxUses,
    double? minOrderAmount,
    List<String>? allowedCategories,
    String? createdBy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final currentUserRole = SecureAuthService.instance.currentUserRole;
    if (type != 'referral' && currentUserRole != UserRole.admin) {
      throw Exception('[DÉMO] Seuls les administrateurs peuvent créer des codes promo généraux');
    }

    _initializeMockPromoCodes();

    final promoId = 'demo_promo_${DateTime.now().millisecondsSinceEpoch}';
    
    final newPromo = {
      'id': promoId,
      'code': code.toUpperCase(),
      'type': type,
      'value': value,
      'description': description ?? '[DÉMO] Code créé par ${createdBy ?? 'utilisateur'}',
      'expiresAt': expiresAt,
      'maxUses': maxUses,
      'currentUses': 0,
      'minOrderAmount': minOrderAmount,
      'allowedCategories': allowedCategories,
      'createdBy': createdBy ?? SecureAuthService.instance.currentUserId,
      'isActive': true,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      '_source': 'mock',
      '_demoData': true,
    };

    _mockPromoCodes.insert(0, newPromo);
    
    print('✅ Code promo démo créé: $code (ID: $promoId)');
    return promoId;
  }

  /// ✅ OBTENIR TOUS LES CODES (mode auto)
  Future<List<Map<String, dynamic>>> getAllPromoCodes() async {
    if (_isDemoMode) {
      return await _getAllPromoCodesMock();
    } else {
      return await _getAllPromoCodesFirebase();
    }
  }

  /// ✅ FIREBASE - Tous les codes réels
  Future<List<Map<String, dynamic>>> _getAllPromoCodesFirebase() async {
    try {
      final currentUserRole = SecureAuthService.instance.currentUserRole;
      if (currentUserRole != UserRole.admin) {
        throw Exception('Accès réservé aux administrateurs');
      }

      final snapshot = await _firestore
          .collection('promo_codes')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (data['expiresAt'] != null) {
          data['expiresAt'] = (data['expiresAt'] as Timestamp).toDate();
        }
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        if (data['updatedAt'] != null) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
        }
        data['_source'] = 'firebase';
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération codes promo Firebase: $e');
    }
  }

  /// ✅ MOCK - Tous les codes factices
  Future<List<Map<String, dynamic>>> _getAllPromoCodesMock() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final currentUserRole = SecureAuthService.instance.currentUserRole;
    if (currentUserRole != UserRole.admin) {
      throw Exception('[DÉMO] Accès réservé aux administrateurs');
    }

    _initializeMockPromoCodes();

    print('✅ Codes promo démo récupérés: ${_mockPromoCodes.length}');
    return List<Map<String, dynamic>>.from(_mockPromoCodes);
  }

  /// ✅ OBTENIR CODES UTILISATEUR (mode auto)
  Future<List<Map<String, dynamic>>> getUserPromoCodes() async {
    if (_isDemoMode) {
      return await _getUserPromoCodesMock();
    } else {
      return await _getUserPromoCodesFirebase();
    }
  }

  /// ✅ FIREBASE - Codes utilisateur réels
  Future<List<Map<String, dynamic>>> _getUserPromoCodesFirebase() async {
    try {
      final currentUserId = SecureAuthService.instance.currentUserId;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final snapshot = await _firestore
          .collection('promo_codes')
          .where('createdBy', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (data['expiresAt'] != null) {
          data['expiresAt'] = (data['expiresAt'] as Timestamp).toDate();
        }
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        if (data['updatedAt'] != null) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
        }
        data['_source'] = 'firebase';
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération codes utilisateur Firebase: $e');
    }
  }

  /// ✅ MOCK - Codes utilisateur factices
  Future<List<Map<String, dynamic>>> _getUserPromoCodesMock() async {
    await Future.delayed(const Duration(milliseconds: 250));
    
    final currentUserId = SecureAuthService.instance.currentUserId;
    if (currentUserId == null) {
      throw Exception('[DÉMO] Utilisateur non connecté');
    }

    _initializeMockPromoCodes();

    final userCodes = _mockPromoCodes
        .where((code) => code['createdBy'] == currentUserId)
        .toList();

    // Générer un code de parrainage pour l'utilisateur s'il n'en a pas
    if (userCodes.isEmpty) {
      final referralCode = 'REF-${currentUserId.substring(0, 6).toUpperCase()}';
      final userReferralCode = {
        'id': 'demo_referral_$currentUserId',
        'code': referralCode,
        'type': 'referral',
        'value': 0.0,
        'description': '[DÉMO] Code de parrainage personnel',
        'expiresAt': null,
        'maxUses': null,
        'currentUses': Random().nextInt(5),
        'createdBy': currentUserId,
        'isActive': true,
        'createdAt': DateTime.now().subtract(Duration(days: Random().nextInt(30))),
        'updatedAt': DateTime.now(),
        '_source': 'mock',
        '_demoData': true,
      };
      
      _mockPromoCodes.add(userReferralCode);
      userCodes.add(userReferralCode);
    }

    print('✅ Codes utilisateur démo: ${userCodes.length}');
    return userCodes;
  }

  /// ✅ CALCULER RÉDUCTION (inchangé - fonctionne en mode auto)
  double calculateDiscount(Map<String, dynamic> promoData, double orderAmount) {
    final type = promoData['type'] as String;
    final value = (promoData['value'] as num).toDouble();
    final minOrderAmount = (promoData['minOrderAmount'] as num?)?.toDouble();

    if (minOrderAmount != null && orderAmount < minOrderAmount) {
      return 0.0;
    }

    if (type == 'percentage') {
      return orderAmount * (value / 100);
    } else if (type == 'fixed') {
      return value;
    }

    return 0.0;
  }

  /// ✅ VÉRIFIER UTILISATION UTILISATEUR (mode auto)
  Future<bool> hasUserUsedPromoCode(String code, String userId) async {
    if (_isDemoMode) {
      return await _hasUserUsedPromoCodeMock(code, userId);
    } else {
      return await _hasUserUsedPromoCodeFirebase(code, userId);
    }
  }

  /// ✅ FIREBASE - Vérification utilisation réelle
  Future<bool> _hasUserUsedPromoCodeFirebase(String code, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('promo_code_uses')
          .where('code', isEqualTo: code.toUpperCase())
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// ✅ MOCK - Vérification utilisation factice
  Future<bool> _hasUserUsedPromoCodeMock(String code, String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    return _mockPromoUses.any((use) =>
      use['code'] == code.toUpperCase() && use['userId'] == userId);
  }

  /// ✅ STATISTIQUES PARRAINAGE (mode auto)
  static Future<Map<String, int>> getReferralStats() async {
    final instance = FirebasePromoCodeService.instance;
    
    if (instance._isDemoMode) {
      return await instance._getReferralStatsMock();
    } else {
      return await instance._getReferralStatsFirebase();
    }
  }

  /// ✅ FIREBASE - Stats parrainage réelles
  Future<Map<String, int>> _getReferralStatsFirebase() async {
    try {
      final currentUserId = SecureAuthService.instance.currentUserId;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final snapshot = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: currentUserId)
          .get();
      
      int totalReferrals = snapshot.docs.length;
      int completedReferrals = 0;
      int totalRewardMonths = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        
        if (status == 'completed') {
          completedReferrals++;
          totalRewardMonths += (data['rewardMonths'] as int? ?? 1);
        }
      }
      
      return {
        'totalReferrals': totalReferrals,
        'completedReferrals': completedReferrals,
        'totalRewardMonths': totalRewardMonths,
      };
    } catch (e) {
      print('❌ Erreur récupération stats parrainage Firebase: $e');
      return {
        'totalReferrals': 0,
        'completedReferrals': 0,
        'totalRewardMonths': 0,
      };
    }
  }

  /// ✅ MOCK - Stats parrainage factices
  Future<Map<String, int>> _getReferralStatsMock() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final currentUserId = SecureAuthService.instance.currentUserId;
    if (currentUserId == null) {
      return {
        'totalReferrals': 0,
        'completedReferrals': 0,
        'totalRewardMonths': 0,
      };
    }

    if (!_mockUserReferrals.containsKey(currentUserId)) {
      _initializeMockUserReferrals(currentUserId);
    }

    final userReferrals = _mockUserReferrals[currentUserId] ?? [];
    final completedReferrals = userReferrals.where((r) => r['status'] == 'completed').length;
    final totalRewardMonths = userReferrals
        .where((r) => r['status'] == 'completed')
        .fold<int>(0, (sum, r) => sum + (r['rewardMonths'] as int? ?? 1));

    final stats = {
      'totalReferrals': userReferrals.length,
      'completedReferrals': completedReferrals,
      'totalRewardMonths': totalRewardMonths,
    };

    print('✅ Stats parrainage démo: $stats');
    return stats;
  }

  /// ✅ INITIALISER PARRAINAGES DÉMO UTILISATEUR
  void _initializeMockUserReferrals(String userId) {
    final referralCount = Random().nextInt(6) + 2; // 2-7 parrainages
    final referrals = <Map<String, dynamic>>[];

    for (int i = 0; i < referralCount; i++) {
      final status = Random().nextBool() ? 'completed' : 'pending';
      
      referrals.add({
        'id': 'demo_referral_${userId}_$i',
        'referrerId': userId,
        'referredUserId': 'demo_referred_user_$i',
        'referralCode': 'REF-${userId.substring(0, 6).toUpperCase()}',
        'status': status,
        'createdAt': DateTime.now().subtract(Duration(days: Random().nextInt(60))),
        'completedAt': status == 'completed' 
            ? DateTime.now().subtract(Duration(days: Random().nextInt(30)))
            : null,
        'rewardMonths': 1,
        '_source': 'mock',
        '_demoData': true,
      });
    }

    _mockUserReferrals[userId] = referrals;
    print('🎭 ${referrals.length} parrainages démo initialisés pour $userId');
  }

  /// ✅ GÉNÉRER CODE PARRAINAGE (mode auto)
  static Future<String?> generateReferralCode() async {
    final instance = FirebasePromoCodeService.instance;
    
    if (instance._isDemoMode) {
      return await instance._generateReferralCodeMock();
    } else {
      return await instance._generateReferralCodeFirebase();
    }
  }

  /// ✅ FIREBASE - Génération code parrainage réel
  Future<String?> _generateReferralCodeFirebase() async {
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      final currentUserId = SecureAuthService.instance.currentUserId;
      
      if (currentUserId == null || currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final userEmail = currentUser['email']?.toString() ?? '';
      
      final existingCode = await _findExistingReferralCode(currentUserId);
      if (existingCode != null) {
        return existingCode;
      }
      
      final code = 'REF-${currentUserId.substring(0, 6).toUpperCase()}';
      
      await createPromoCode(
        code: code,
        type: 'referral',
        value: 0.0,
        description: 'Code de parrainage pour $userEmail',
        expiresAt: null,
        maxUses: null,
        createdBy: currentUserId,
      );
      
      return code;
    } catch (e) {
      print('❌ Erreur génération code parrainage Firebase: $e');
      return null;
    }
  }

  /// ✅ MOCK - Génération code parrainage factice
  Future<String?> _generateReferralCodeMock() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      final currentUserId = SecureAuthService.instance.currentUserId;
      
      if (currentUserId == null || currentUser == null) {
        throw Exception('[DÉMO] Utilisateur non connecté');
      }

      final userEmail = currentUser['email']?.toString() ?? '';
      
      final existingCode = await _findExistingReferralCodeMock(currentUserId);
      if (existingCode != null) {
        print('✅ Code parrainage démo existant: $existingCode');
        return existingCode;
      }
      
      final code = 'REF-${currentUserId.substring(0, 6).toUpperCase()}';
      
      await createPromoCode(
        code: code,
        type: 'referral',
        value: 0.0,
        description: '[DÉMO] Code de parrainage pour $userEmail',
        expiresAt: null,
        maxUses: null,
        createdBy: currentUserId,
      );
      
      print('✅ Code parrainage démo généré: $code');
      return code;
    } catch (e) {
      print('❌ Erreur génération code parrainage démo: $e');
      return null;
    }
  }

  /// ✅ NOUVELLE MÉTHODE - OBTENIR LES PARRAINAGES DE L'UTILISATEUR ACTUEL
  Future<List<Map<String, dynamic>>> getCurrentUserReferrals() async {
    if (_isDemoMode) {
      return await _getCurrentUserReferralsMock();
    } else {
      return await _getCurrentUserReferralsFirebase();
    }
  }

  /// ✅ FIREBASE - Parrainages utilisateur réels
  Future<List<Map<String, dynamic>>> _getCurrentUserReferralsFirebase() async {
    try {
      final currentUserId = SecureAuthService.instance.currentUserId;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final snapshot = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        if (data['completedAt'] != null) {
          data['completedAt'] = (data['completedAt'] as Timestamp).toDate();
        }
        data['_source'] = 'firebase';
        
        return data;
      }).toList();
    } catch (e) {
      print('❌ Erreur récupération parrainages Firebase: $e');
      return [];
    }
  }

  /// ✅ MOCK - Parrainages utilisateur factices
  Future<List<Map<String, dynamic>>> _getCurrentUserReferralsMock() async {
    await Future.delayed(const Duration(milliseconds: 250));
    
    final currentUserId = SecureAuthService.instance.currentUserId;
    if (currentUserId == null) {
      print('⚠️ [DÉMO] Utilisateur non connecté');
      return [];
    }

    if (!_mockUserReferrals.containsKey(currentUserId)) {
      _initializeMockUserReferrals(currentUserId);
    }

    final userReferrals = _mockUserReferrals[currentUserId] ?? [];
    print('✅ Parrainages démo récupérés: ${userReferrals.length}');
    
    return List<Map<String, dynamic>>.from(userReferrals);
  }

  /// ✅ MÉTHODE DE DIAGNOSTIC
  Future<void> debugPromoService() async {
    print('🔍 Debug FirebasePromoCodeService:');
    print('  - Mode démo: $_isDemoMode');
    print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');
    
    final currentUserId = SecureAuthService.instance.currentUserId;
    final currentUserRole = SecureAuthService.instance.currentUserRole;
    
    print('  - User ID: ${currentUserId ?? 'Non connecté'}');
    print('  - User Role: ${currentUserRole?.name ?? 'Aucun'}');
    
    if (currentUserId != null) {
      try {
        final userCodes = await getUserPromoCodes();
        print('  - Codes utilisateur: ${userCodes.length}');
        
        final referralCode = await getCurrentUserReferralCode();
        print('  - Code de parrainage: ${referralCode ?? 'Aucun'}');
        
        final stats = await getReferralStats();
        print('  - Stats parrainage: $stats');
        
        final referrals = await getCurrentUserReferrals();
        print('  - Parrainages actifs: ${referrals.length}');
        
        if (_isDemoMode) {
          print('  - Codes mock: ${_mockPromoCodes.length}');
          print('  - Utilisations mock: ${_mockPromoUses.length}');
          print('  - Parrainages mock: ${_mockUserReferrals.length} utilisateurs');
        }
      } catch (e) {
        print('  - Erreur: $e');
      }
    }
  }

  // ✅ MÉTHODES UTILITAIRES (adaptées pour le mode auto)

  /// Méthode privée pour trouver un code de parrainage existant
  Future<String?> _findExistingReferralCode(String userId) async {
    if (_isDemoMode) {
      return await _findExistingReferralCodeMock(userId);
    } else {
      return await _findExistingReferralCodeFirebase(userId);
    }
  }

  /// FIREBASE - Trouver code parrainage existant
  Future<String?> _findExistingReferralCodeFirebase(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('promo_codes')
          .where('type', isEqualTo: 'referral')
          .where('createdBy', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['code'] as String?;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// MOCK - Trouver code parrainage existant
  Future<String?> _findExistingReferralCodeMock(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    _initializeMockPromoCodes();
    
    try {
      final referralCode = _mockPromoCodes.firstWhere(
        (code) => code['type'] == 'referral' && code['createdBy'] == userId,
      );
      return referralCode['code'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Obtenir le code de parrainage de l'utilisateur actuel
  static Future<String?> getCurrentUserReferralCode() async {
    try {
      final currentUserId = SecureAuthService.instance.currentUserId;
      if (currentUserId == null) return null;

      final instance = FirebasePromoCodeService.instance;
      return await instance._findExistingReferralCode(currentUserId);
    } catch (e) {
      print('❌ Erreur récupération code parrainage: $e');
      return null;
    }
  }

  /// Valider et utiliser un code promo (usage unique par utilisateur)
  Future<bool> validateAndUsePromoCode(String code) async {
    try {
      final currentUserId = SecureAuthService.instance.currentUserId;
      if (currentUserId == null) {
        throw Exception(_isDemoMode ? '[DÉMO] Utilisateur non connecté' : 'Utilisateur non connecté');
      }

      // Vérifier que le code est valide
      final promoData = await validatePromoCode(code);
      if (promoData == null) return false;

      // Vérifier que l'utilisateur n'a pas déjà utilisé ce code
      final hasUsed = await hasUserUsedPromoCode(code, currentUserId);
      if (hasUsed) return false;

      // Utiliser le code
      await usePromoCode(code);
      
      print('✅ Code promo validé et utilisé (${_isDemoMode ? 'démo' : 'production'}): $code');
      return true;
    } catch (e) {
      print('❌ Erreur validation/utilisation code: $e');
      return false;
    }
  }

  // ✅ MÉTHODES RESTANTES (simplifiées ou adaptées selon le besoin)

  /// Toggle actif/inactif d'un code promo (simplifié)
  Future<void> togglePromoCodeStatus(String promoId, bool isActive) async {
    if (_isDemoMode) {
      // Version simplifiée pour démo
      final promoIndex = _mockPromoCodes.indexWhere((p) => p['id'] == promoId);
      if (promoIndex != -1) {
        _mockPromoCodes[promoIndex]['isActive'] = isActive;
        _mockPromoCodes[promoIndex]['updatedAt'] = DateTime.now();
        print('✅ Statut code démo mis à jour: $promoId → $isActive');
      }
    } else {
      // Version complète Firebase
      final currentUserRole = SecureAuthService.instance.currentUserRole;
      final currentUserId = SecureAuthService.instance.currentUserId;
      
      if (currentUserRole != UserRole.admin) {
        final doc = await _firestore.collection('promo_codes').doc(promoId).get();
        if (!doc.exists || doc.data()?['createdBy'] != currentUserId) {
          throw Exception('Vous ne pouvez modifier que vos propres codes');
        }
      }

      await _firestore.collection('promo_codes').doc(promoId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Supprimer un code promo (simplifié)
  Future<void> deletePromoCode(String promoId) async {
    if (_isDemoMode) {
      final promoIndex = _mockPromoCodes.indexWhere((p) => p['id'] == promoId);
      if (promoIndex != -1) {
        final promo = _mockPromoCodes.removeAt(promoIndex);
        print('✅ Code démo supprimé: ${promo['code']}');
      }
    } else {
      final currentUserRole = SecureAuthService.instance.currentUserRole;
      final currentUserId = SecureAuthService.instance.currentUserId;
      
      if (currentUserRole != UserRole.admin) {
        final doc = await _firestore.collection('promo_codes').doc(promoId).get();
        if (!doc.exists || doc.data()?['createdBy'] != currentUserId) {
          throw Exception('Vous ne pouvez supprimer que vos propres codes');
        }
      }

      await _firestore.collection('promo_codes').doc(promoId).delete();
    }
  }

  /// Obtenir l'historique d'utilisation (simplifié pour démo)
  Future<List<Map<String, dynamic>>> getPromoCodeUsageHistory(String code) async {
    if (_isDemoMode) {
      return _mockPromoUses
          .where((use) => use['code'] == code.toUpperCase())
          .toList();
    } else {
      try {
        final snapshot = await _firestore
            .collection('promo_code_uses')
            .where('code', isEqualTo: code.toUpperCase())
            .orderBy('usedAt', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          
          if (data['usedAt'] != null) {
            data['usedAt'] = (data['usedAt'] as Timestamp).toDate();
          }
          
          return data;
        }).toList();
      } catch (e) {
        throw Exception('Erreur récupération historique Firebase: $e');
      }
    }
  }

  /// Obtenir les codes promo actifs
  Future<List<Map<String, dynamic>>> getActivePromoCodes() async {
    if (_isDemoMode) {
      _initializeMockPromoCodes();
      final now = DateTime.now();
      return _mockPromoCodes
          .where((code) => 
            code['isActive'] == true && 
            (code['expiresAt'] == null || (code['expiresAt'] as DateTime).isAfter(now)))
          .toList();
    } else {
      try {
        final now = Timestamp.now();
        final snapshot = await _firestore
            .collection('promo_codes')
            .where('isActive', isEqualTo: true)
            .where('expiresAt', isGreaterThan: now)
            .orderBy('expiresAt', descending: false)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          
          if (data['expiresAt'] != null) {
            data['expiresAt'] = (data['expiresAt'] as Timestamp).toDate();
          }
          if (data['createdAt'] != null) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
          }
          
          return data;
        }).toList();
      } catch (e) {
        throw Exception('Erreur récupération codes promo actifs Firebase: $e');
      }
    }
  }
}