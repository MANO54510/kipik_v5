// lib/services/promo/firebase_promo_code_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ MIGRATION
import 'package:kipik_v5/models/user_role.dart'; // ✅ AJOUTÉ

class FirebasePromoCodeService {
  static FirebasePromoCodeService? _instance;
  static FirebasePromoCodeService get instance => _instance ??= FirebasePromoCodeService._();
  FirebasePromoCodeService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Valider un code promo
  Future<Map<String, dynamic>?> validatePromoCode(String code) async {
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

      // Vérifier expiration
      if (expiresAt != null && now.isAfter(expiresAt)) {
        return null;
      }

      // Vérifier limite d'utilisation
      final maxUses = promoData['maxUses'] as int?;
      final currentUses = promoData['currentUses'] as int? ?? 0;
           
      if (maxUses != null && currentUses >= maxUses) {
        return null;
      }

      return promoData;
    } catch (e) {
      print('Erreur validation code promo: $e');
      return null;
    }
  }

  /// Utiliser un code promo
  Future<void> usePromoCode(String code) async {
    try {
      // ✅ MIGRATION: Utiliser SecureAuthService
      final currentUser = SecureAuthService.instance.currentUser;
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

          // Enregistrer l'utilisation
          transaction.set(
            _firestore.collection('promo_code_uses').doc(),
            {
              'code': code,
              'userId': currentUserId, // ✅ MIGRATION
              'usedAt': FieldValue.serverTimestamp(),
            },
          );
        });
      }
    } catch (e) {
      throw Exception('Erreur utilisation code promo: $e');
    }
  }

  /// Créer un nouveau code promo (pour les admins)
  Future<String> createPromoCode({
    required String code,
    required String type, // 'percentage', 'fixed', 'referral'
    required double value,
    String? description,
    DateTime? expiresAt,
    int? maxUses,
    double? minOrderAmount,
    List<String>? allowedCategories,
    String? createdBy, // ID de l'utilisateur qui a créé le code
  }) async {
    try {
      // ✅ SÉCURITÉ: Vérifier les permissions admin pour certains types
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
        'createdBy': createdBy ?? SecureAuthService.instance.currentUserId, // ✅ MIGRATION
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur création code promo: $e');
    }
  }

  /// Obtenir tous les codes promo (pour les admins)
  Future<List<Map<String, dynamic>>> getAllPromoCodes() async {
    try {
      // ✅ SÉCURITÉ: Vérifier les permissions admin
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
        
        // Convertir les Timestamps en DateTime pour l'affichage
        if (data['expiresAt'] != null) {
          data['expiresAt'] = (data['expiresAt'] as Timestamp).toDate();
        }
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        if (data['updatedAt'] != null) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération codes promo: $e');
    }
  }

  /// Obtenir les codes promo de l'utilisateur actuel (codes de parrainage)
  Future<List<Map<String, dynamic>>> getUserPromoCodes() async {
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
        
        // Convertir les Timestamps en DateTime pour l'affichage
        if (data['expiresAt'] != null) {
          data['expiresAt'] = (data['expiresAt'] as Timestamp).toDate();
        }
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        if (data['updatedAt'] != null) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération codes utilisateur: $e');
    }
  }

  /// Activer/désactiver un code promo
  Future<void> togglePromoCodeStatus(String promoId, bool isActive) async {
    try {
      // ✅ SÉCURITÉ: Vérifier les permissions
      final currentUserRole = SecureAuthService.instance.currentUserRole;
      final currentUserId = SecureAuthService.instance.currentUserId;
      
      if (currentUserRole != UserRole.admin) {
        // Vérifier si c'est le propriétaire du code
        final doc = await _firestore.collection('promo_codes').doc(promoId).get();
        if (!doc.exists || doc.data()?['createdBy'] != currentUserId) {
          throw Exception('Vous ne pouvez modifier que vos propres codes');
        }
      }

      await _firestore.collection('promo_codes').doc(promoId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur mise à jour statut code promo: $e');
    }
  }

  /// Supprimer un code promo
  Future<void> deletePromoCode(String promoId) async {
    try {
      // ✅ SÉCURITÉ: Vérifier les permissions
      final currentUserRole = SecureAuthService.instance.currentUserRole;
      final currentUserId = SecureAuthService.instance.currentUserId;
      
      if (currentUserRole != UserRole.admin) {
        // Vérifier si c'est le propriétaire du code
        final doc = await _firestore.collection('promo_codes').doc(promoId).get();
        if (!doc.exists || doc.data()?['createdBy'] != currentUserId) {
          throw Exception('Vous ne pouvez supprimer que vos propres codes');
        }
      }

      await _firestore.collection('promo_codes').doc(promoId).delete();
    } catch (e) {
      throw Exception('Erreur suppression code promo: $e');
    }
  }

  /// Vérifier si un utilisateur a déjà utilisé un code promo
  Future<bool> hasUserUsedPromoCode(String code, String userId) async {
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

  /// Obtenir l'historique d'utilisation d'un code promo
  Future<List<Map<String, dynamic>>> getPromoCodeUsageHistory(String code) async {
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
      throw Exception('Erreur récupération historique: $e');
    }
  }

  /// Calculer la réduction d'un code promo
  double calculateDiscount(Map<String, dynamic> promoData, double orderAmount) {
    final type = promoData['type'] as String;
    final value = (promoData['value'] as num).toDouble();
    final minOrderAmount = (promoData['minOrderAmount'] as num?)?.toDouble();

    // Vérifier le montant minimum
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

  /// Obtenir les codes promo actifs et valides
  Future<List<Map<String, dynamic>>> getActivePromoCodes() async {
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
      throw Exception('Erreur récupération codes promo actifs: $e');
    }
  }

  /// Créer des codes promo de test
  Future<void> createSamplePromoCodes() async {
    try {
      // ✅ SÉCURITÉ: Vérifier les permissions admin
      final currentUserRole = SecureAuthService.instance.currentUserRole;
      if (currentUserRole != UserRole.admin) {
        throw Exception('Seuls les administrateurs peuvent créer des codes de test');
      }

      final sampleCodes = [
        {
          'code': 'WELCOME10',
          'type': 'percentage',
          'value': 10.0,
          'description': 'Code de bienvenue - 10% de réduction',
          'expiresAt': DateTime.now().add(const Duration(days: 30)),
          'maxUses': 100,
          'minOrderAmount': 50.0,
        },
        {
          'code': 'FIXE20',
          'type': 'fixed',
          'value': 20.0,
          'description': 'Réduction fixe de 20€',
          'expiresAt': DateTime.now().add(const Duration(days: 60)),
          'maxUses': 50,
          'minOrderAmount': 100.0,
        },
        {
          'code': 'TATTOO15',
          'type': 'percentage',
          'value': 15.0,
          'description': 'Spécial tatouage - 15% de réduction',
          'expiresAt': DateTime.now().add(const Duration(days: 90)),
          'allowedCategories': ['tatouage', 'convention'],
        },
      ];

      for (final codeData in sampleCodes) {
        try {
          await createPromoCode(
            code: codeData['code'] as String,
            type: codeData['type'] as String,
            value: codeData['value'] as double,
            description: codeData['description'] as String?,
            expiresAt: codeData['expiresAt'] as DateTime?,
            maxUses: codeData['maxUses'] as int?,
            minOrderAmount: codeData['minOrderAmount'] as double?,
            allowedCategories: codeData['allowedCategories'] as List<String>?,
          );
          print('✅ Code promo créé: ${codeData['code']}');
        } catch (e) {
          print('❌ Erreur création code ${codeData['code']}: $e');
        }
      }
    } catch (e) {
      print('❌ Erreur création codes de test: $e');
    }
  }

  // ===============================================
  // MÉTHODES STATIQUES POUR LE PARRAINAGE
  // ===============================================

  /// ✅ MIGRATION: Génère ou récupère un code de parrainage pour l'utilisateur actuel
  static Future<String?> generateReferralCode() async {
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      final currentUserId = SecureAuthService.instance.currentUserId;
      
      if (currentUserId == null || currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final userEmail = currentUser['email']?.toString() ?? '';
      final service = FirebasePromoCodeService.instance;
      
      // Vérifier si l'utilisateur a déjà un code de parrainage
      final existingCode = await service._findExistingReferralCode(currentUserId);
      if (existingCode != null) {
        return existingCode;
      }
      
      // Créer un nouveau code de parrainage unique
      final code = 'REF-${currentUserId.substring(0, 6).toUpperCase()}';
      
      await service.createPromoCode(
        code: code,
        type: 'referral',
        value: 0.0,
        description: 'Code de parrainage pour $userEmail',
        expiresAt: null, // Pas d'expiration pour les codes de parrainage
        maxUses: null, // Pas de limite d'usage pour le parrainage
        createdBy: currentUserId,
      );
      
      return code;
    } catch (e) {
      print('❌ Erreur génération code parrainage: $e');
      return null;
    }
  }

  /// ✅ MIGRATION: Récupère les statistiques de parrainage pour l'utilisateur actuel
  static Future<Map<String, int>> getReferralStats() async {
    try {
      final currentUserId = SecureAuthService.instance.currentUserId;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final service = FirebasePromoCodeService.instance;
      
      // Récupérer tous les parrainages de cet utilisateur
      final snapshot = await service._firestore
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
      print('❌ Erreur récupération stats parrainage: $e');
      return {
        'totalReferrals': 0,
        'completedReferrals': 0,
        'totalRewardMonths': 0,
      };
    }
  }

  /// ✅ NOUVEAU: Récupère le code de parrainage de l'utilisateur actuel
  static Future<String?> getCurrentUserReferralCode() async {
    try {
      final currentUserId = SecureAuthService.instance.currentUserId;
      if (currentUserId == null) return null;

      final service = FirebasePromoCodeService.instance;
      return await service._findExistingReferralCode(currentUserId);
    } catch (e) {
      print('❌ Erreur récupération code parrainage: $e');
      return null;
    }
  }

  // ===============================================
  // MÉTHODES D'INSTANCE POUR LE PARRAINAGE
  // ===============================================

  /// Méthode privée pour trouver un code de parrainage existant
  Future<String?> _findExistingReferralCode(String userId) async {
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

  /// Enregistrer un parrainage quand quelqu'un utilise le code
  Future<void> recordReferral({
    required String referrerId,
    required String referredUserId,
    required String referralCode,
  }) async {
    try {
      await _firestore.collection('referrals').add({
        'referrerId': referrerId,
        'referredUserId': referredUserId,
        'referralCode': referralCode,
        'status': 'pending', // pending, completed, cancelled
        'createdAt': FieldValue.serverTimestamp(),
        'rewardMonths': 1, // Nombre de mois gratuits à accorder
      });
    } catch (e) {
      throw Exception('Erreur enregistrement parrainage: $e');
    }
  }

  /// Marquer un parrainage comme complété (quand le filleul souscrit)
  Future<void> completeReferral(String referralId) async {
    try {
      await _firestore.collection('referrals').doc(referralId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur finalisation parrainage: $e');
    }
  }

  /// ✅ NOUVEAU: Obtenir les parrainages de l'utilisateur actuel
  Future<List<Map<String, dynamic>>> getCurrentUserReferrals() async {
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
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération parrainages: $e');
    }
  }

  // ===============================================
  // MÉTHODES UTILITAIRES POUR LES PROMOTIONS
  // ===============================================

  /// Crée un code de parrainage pour l'utilisateur actuel
  Future<String> createReferralCode({
    String? description,
    DateTime? expiresAt,
  }) async {
    final currentUserId = SecureAuthService.instance.currentUserId;
    final currentUser = SecureAuthService.instance.currentUser;
    
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    final userEmail = currentUser?['email']?.toString() ?? '';
    final code = 'REF-${currentUserId.substring(0, 6).toUpperCase()}';
    
    return createPromoCode(
      code: code,
      type: 'referral',
      value: 0.0,
      description: description ?? 'Code de parrainage pour $userEmail',
      expiresAt: expiresAt, // null = pas de date limite
      maxUses: null, // Pas de limite pour le parrainage
      createdBy: currentUserId,
    );
  }

  /// Crée un code promo national / multi-uses (admin uniquement)
  Future<String> createGeneralPromo({
    required String prefix,
    required double percent,
    required DateTime until,
    int? maxUses, // null = illimité
    String? description,
  }) async {
    // ✅ SÉCURITÉ: Vérifier les permissions admin
    final currentUserRole = SecureAuthService.instance.currentUserRole;
    if (currentUserRole != UserRole.admin) {
      throw Exception('Seuls les administrateurs peuvent créer des codes promo généraux');
    }

    // On génère un suffixe unique pour éviter les collisions
    final suffix = DateTime.now().millisecondsSinceEpoch % 10000;
    final code = '${prefix.toUpperCase()}$suffix';
    final dateStr = until.toLocal().toIso8601String().split("T").first;
    
    return createPromoCode(
      code: code,
      type: 'percentage',
      value: percent,
      description: description ?? 'Promo ${percent.toInt()}% jusqu\'au $dateStr',
      expiresAt: until,
      maxUses: maxUses, // plusieurs utilisations
    );
  }

  /// Valide et consomme un code pour l'utilisateur actuel (usage unique par user)
  Future<bool> validateAndUsePromoCode(String code) async {
    try {
      final currentUserId = SecureAuthService.instance.currentUserId;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // 1. Récupère le document promo
      final promoSnap = await _firestore
          .collection('promo_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (promoSnap.docs.isEmpty) return false;

      final data = promoSnap.docs.first.data();
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        return false; // expiré
      }

      // 2. Vérifie que l'utilisateur n'a pas déjà utilisé ce code
      final usedSnap = await _firestore
          .collection('promo_code_uses')
          .where('code', isEqualTo: code.toUpperCase())
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();
      if (usedSnap.docs.isNotEmpty) {
        return false; // déjà utilisé par cet user
      }

      // 3. (Optionnel) Vérifie la limite globale
      final maxUses = data['maxUses'] as int?;
      if (maxUses != null) {
        final totalUses = await _firestore
            .collection('promo_code_uses')
            .where('code', isEqualTo: code.toUpperCase())
            .get()
            .then((q) => q.docs.length);
        if (totalUses >= maxUses) {
          return false; // plus d'utilisations dispo
        }
      }

      // 4. Tout est OK → on enregistre l'utilisation
      await _firestore.collection('promo_code_uses').add({
        'code': code.toUpperCase(),
        'userId': currentUserId,
        'usedAt': FieldValue.serverTimestamp(),
      });

      return true; // succès
    } catch (e) {
      print('❌ Erreur validation/utilisation code: $e');
      return false;
    }
  }

  /// ✅ NOUVEAU: Méthode de diagnostic pour debug
  Future<void> debugPromoService() async {
    print('🔍 DIAGNOSTIC FirebasePromoCodeService:');
    
    try {
      final currentUserId = SecureAuthService.instance.currentUserId;
      final currentUserRole = SecureAuthService.instance.currentUserRole;
      
      print('  - User ID: ${currentUserId ?? 'Non connecté'}');
      print('  - User Role: ${currentUserRole?.name ?? 'Aucun'}');
      
      if (currentUserId != null) {
        final userCodes = await getUserPromoCodes();
        print('  - Codes utilisateur: ${userCodes.length}');
        
        final referralCode = await getCurrentUserReferralCode();
        print('  - Code de parrainage: ${referralCode ?? 'Aucun'}');
        
        final stats = await getReferralStats();
        print('  - Stats parrainage: ${stats}');
      }
      
      if (currentUserRole == UserRole.admin) {
        final allCodes = await getAllPromoCodes();
        print('  - Total codes (admin): ${allCodes.length}');
      }
    } catch (e) {
      print('  - Erreur: $e');
    }
  }
}