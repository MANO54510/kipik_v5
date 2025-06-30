// lib/services/promo/firebase_promo_code_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_service.dart';

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
      final user = AuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

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
              'userId': user.uid,
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
    required String type, // 'percentage' ou 'fixed'
    required double value,
    String? description,
    DateTime? expiresAt,
    int? maxUses,
    double? minOrderAmount,
    List<String>? allowedCategories,
  }) async {
    try {
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

  /// Activer/désactiver un code promo
  Future<void> togglePromoCodeStatus(String promoId, bool isActive) async {
    try {
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
        print('Code promo créé: ${codeData['code']}');
      } catch (e) {
        print('Erreur création code ${codeData['code']}: $e');
      }
    }
  }
}