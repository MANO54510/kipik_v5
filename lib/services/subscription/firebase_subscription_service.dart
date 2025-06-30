// lib/services/subscription/firebase_subscription_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_service.dart';

class FirebaseSubscriptionService {
  static FirebaseSubscriptionService? _instance;
  static FirebaseSubscriptionService get instance => _instance ??= FirebaseSubscriptionService._();
  FirebaseSubscriptionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtenir l'abonnement actuel de l'utilisateur
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      
      // Convertir les Timestamps
      if (data['startDate'] != null) {
        data['startDate'] = (data['startDate'] as Timestamp).toDate();
      }
      if (data['endDate'] != null) {
        data['endDate'] = (data['endDate'] as Timestamp).toDate();
      }
      if (data['createdAt'] != null) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
      }
      
      return data;
    } catch (e) {
      print('Erreur récupération abonnement: $e');
      return null;
    }
  }

  /// Créer un nouvel abonnement
  Future<String> createSubscription({
    required String planId,
    required String planName,
    required double price,
    required Duration duration,
    String? description,
    Map<String, dynamic>? features,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Annuler l'abonnement actuel s'il existe
      await cancelCurrentSubscription();

      final endDate = DateTime.now().add(duration);
      
      final docRef = await _firestore.collection('subscriptions').add({
        'userId': user.uid,
        'planId': planId,
        'planName': planName,
        'description': description,
        'price': price,
        'duration': duration.inDays,
        'features': features,
        'status': 'active',
        'startDate': FieldValue.serverTimestamp(),
        'endDate': Timestamp.fromDate(endDate),
        'autoRenew': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur création abonnement: $e');
    }
  }

  /// Annuler l'abonnement actuel
  Future<void> cancelCurrentSubscription() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Erreur annulation abonnement: $e');
    }
  }

  /// Suspendre un abonnement
  Future<void> suspendSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': 'suspended',
        'suspendedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur suspension abonnement: $e');
    }
  }

  /// Réactiver un abonnement suspendu
  Future<void> reactivateSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': 'active',
        'reactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur réactivation abonnement: $e');
    }
  }

  /// Renouveler un abonnement
  Future<String> renewSubscription(String currentSubscriptionId) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Récupérer l'abonnement actuel
      final currentDoc = await _firestore
          .collection('subscriptions')
          .doc(currentSubscriptionId)
          .get();

      if (!currentDoc.exists) {
        throw Exception('Abonnement introuvable');
      }

      final currentData = currentDoc.data()!;
      
      // Marquer l'ancien comme expiré
      await currentDoc.reference.update({
        'status': 'expired',
        'expiredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer le nouvel abonnement
      final duration = Duration(days: currentData['duration'] as int);
      final newSubscriptionId = await createSubscription(
        planId: currentData['planId'],
        planName: currentData['planName'],
        price: (currentData['price'] as num).toDouble(),
        duration: duration,
        description: currentData['description'],
        features: currentData['features'],
      );

      return newSubscriptionId;
    } catch (e) {
      throw Exception('Erreur renouvellement abonnement: $e');
    }
  }

  /// Vérifier si l'utilisateur a un abonnement actif
  Future<bool> hasActiveSubscription() async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) return false;

      final endDate = subscription['endDate'] as DateTime?;
      if (endDate == null) return false;

      return DateTime.now().isBefore(endDate);
    } catch (e) {
      return false;
    }
  }

  /// Vérifier si l'utilisateur a une fonctionnalité spécifique
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

  /// Obtenir l'historique des abonnements
  Future<List<Map<String, dynamic>>> getSubscriptionHistory() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Convertir les Timestamps
        if (data['startDate'] != null) {
          data['startDate'] = (data['startDate'] as Timestamp).toDate();
        }
        if (data['endDate'] != null) {
          data['endDate'] = (data['endDate'] as Timestamp).toDate();
        }
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        if (data['cancelledAt'] != null) {
          data['cancelledAt'] = (data['cancelledAt'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération historique: $e');
    }
  }

  /// Obtenir tous les plans d'abonnement disponibles
  Future<List<Map<String, dynamic>>> getAvailablePlans() async {
    try {
      final snapshot = await _firestore
          .collection('subscription_plans')
          .where('isActive', isEqualTo: true)
          .orderBy('price', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération plans: $e');
    }
  }

  /// Mettre à jour les préférences d'auto-renouvellement
  Future<void> updateAutoRenew(String subscriptionId, bool autoRenew) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'autoRenew': autoRenew,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur mise à jour auto-renouvellement: $e');
    }
  }

  /// Vérifier les abonnements expirés (à appeler périodiquement)
  Future<void> checkExpiredSubscriptions() async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('status', isEqualTo: 'active')
          .where('endDate', isLessThan: now)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'status': 'expired',
          'expiredAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur vérification abonnements expirés: $e');
    }
  }

  /// Obtenir les statistiques d'abonnements (pour les admins)
  Future<Map<String, int>> getSubscriptionStats() async {
    try {
      final snapshot = await _firestore.collection('subscriptions').get();
      
      int active = 0;
      int expired = 0;
      int cancelled = 0;
      int suspended = 0;
      
      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String?;
        switch (status) {
          case 'active':
            active++;
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
        'expired': expired,
        'cancelled': cancelled,
        'suspended': suspended,
      };
    } catch (e) {
      throw Exception('Erreur récupération statistiques: $e');
    }
  }

  /// Créer des plans d'abonnement de test
  Future<void> createSamplePlans() async {
    final samplePlans = [
      {
        'name': 'Basique',
        'description': 'Plan basique pour les tatoueurs débutants',
        'price': 19.99,
        'duration': 30, // jours
        'features': {
          'maxProjects': 5,
          'maxPhotos': 20,
          'analytics': false,
          'priority_support': false,
          'custom_portfolio': false,
        },
        'isActive': true,
        'popular': false,
      },
      {
        'name': 'Pro',
        'description': 'Plan professionnel pour les tatoueurs expérimentés',
        'price': 49.99,
        'duration': 30,
        'features': {
          'maxProjects': 25,
          'maxPhotos': 100,
          'analytics': true,
          'priority_support': true,
          'custom_portfolio': true,
          'advanced_tools': true,
        },
        'isActive': true,
        'popular': true,
      },
      {
        'name': 'Premium',
        'description': 'Plan premium pour les studios et artistes renommés',
        'price': 99.99,
        'duration': 30,
        'features': {
          'maxProjects': -1, // illimité
          'maxPhotos': -1, // illimité
          'analytics': true,
          'priority_support': true,
          'custom_portfolio': true,
          'advanced_tools': true,
          'white_label': true,
          'api_access': true,
        },
        'isActive': true,
        'popular': false,
      },
    ];

    for (final planData in samplePlans) {
      try {
        await _firestore.collection('subscription_plans').add({
          ...planData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Plan créé: ${planData['name']}');
      } catch (e) {
        print('Erreur création plan ${planData['name']}: $e');
      }
    }
  }

  /// Créer un abonnement de test
  Future<void> createTestSubscription() async {
    try {
      await createSubscription(
        planId: 'pro_plan',
        planName: 'Pro',
        price: 49.99,
        duration: const Duration(days: 30),
        description: 'Abonnement Pro de test',
        features: {
          'maxProjects': 25,
          'maxPhotos': 100,
          'analytics': true,
          'priority_support': true,
        },
      );
      print('Abonnement de test créé');
    } catch (e) {
      print('Erreur création abonnement test: $e');
    }
  }
}