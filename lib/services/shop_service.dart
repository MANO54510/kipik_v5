// lib/services/shop_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/models/shop_model.dart';
import '../core/database_manager.dart';

/// 🏪 Service pour la gestion des boutiques de tatoueurs
/// Gère toutes les opérations CRUD et business logic des shops
class ShopService {
  static const String collectionName = 'shops';
  
  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _collection;

  ShopService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? DatabaseManager.instance.firestore {
    _collection = _firestore.collection(collectionName);
  }

  // ===== OPÉRATIONS CRUD =====

  /// Créer un nouveau shop
  Future<Shop> createShop(Shop shop) async {
    try {
      final newShop = shop.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _collection.add(newShop.toFirestore());
      
      return newShop.copyWith(id: docRef.id);
    } catch (e) {
      throw ShopServiceException('Erreur lors de la création du shop: $e');
    }
  }

  /// Récupérer un shop par ID
  Future<Shop?> getShopById(String shopId) async {
    try {
      final doc = await _collection.doc(shopId).get();
      
      if (!doc.exists) return null;
      
      return Shop.fromFirestore(doc);
    } catch (e) {
      throw ShopServiceException('Erreur lors de la récupération du shop: $e');
    }
  }

  /// Mettre à jour un shop
  Future<Shop> updateShop(Shop shop) async {
    try {
      final updatedShop = shop.copyWith(updatedAt: DateTime.now());
      
      await _collection.doc(shop.id).update(updatedShop.toFirestore());
      
      return updatedShop;
    } catch (e) {
      throw ShopServiceException('Erreur lors de la mise à jour du shop: $e');
    }
  }

  /// Supprimer un shop
  Future<void> deleteShop(String shopId) async {
    try {
      await _collection.doc(shopId).delete();
    } catch (e) {
      throw ShopServiceException('Erreur lors de la suppression du shop: $e');
    }
  }

  // ===== REQUÊTES BUSINESS =====

  /// Récupérer les shops d'un tatoueur
  Future<List<Shop>> getShopsByTattooistId(String tattooistId) async {
    try {
      final query = await _collection
          .where('tattooistId', isEqualTo: tattooistId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Shop.fromFirestore(doc)).toList();
    } catch (e) {
      throw ShopServiceException('Erreur lors de la récupération des shops du tatoueur: $e');
    }
  }

  /// Récupérer les shops publics (pour clients et organisateurs)
  Future<List<Shop>> getPublicShops({
    String? city,
    List<String>? specialties,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true);

      // Filtrer par ville si spécifiée
      if (city != null && city.isNotEmpty) {
        query = query.where('address.city', isEqualTo: city);
      }

      // Ordonner par note puis par nom
      query = query.orderBy('stats.rating', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query.get();
      var shops = result.docs.map((doc) => Shop.fromFirestore(doc)).toList();

      // Filtrer par spécialités côté client (Firestore ne supporte pas les array-contains-any avec d'autres where)
      if (specialties != null && specialties.isNotEmpty) {
        shops = shops.where((shop) =>
          specialties.any((specialty) =>
            shop.specialties.any((shopSpecialty) =>
              shopSpecialty.toLowerCase().contains(specialty.toLowerCase())
            )
          )
        ).toList();
      }

      return shops;
    } catch (e) {
      throw ShopServiceException('Erreur lors de la récupération des shops publics: $e');
    }
  }

  /// Rechercher des shops
  Future<List<Shop>> searchShops({
    required String query,
    String? city,
    List<String>? specialties,
    bool onlyPublic = true,
    int? limit,
  }) async {
    try {
      // Récupérer tous les shops publics puis filtrer côté client
      // (Firestore ne supporte pas la recherche textuelle native)
      final shops = await getPublicShops(
        city: city,
        specialties: specialties,
        limit: limit,
      );

      final lowerQuery = query.toLowerCase();
      
      return shops.where((shop) =>
        shop.name.toLowerCase().contains(lowerQuery) ||
        (shop.description?.toLowerCase().contains(lowerQuery) ?? false) ||
        shop.specialties.any((specialty) => 
          specialty.toLowerCase().contains(lowerQuery)
        ) ||
        shop.address.city.toLowerCase().contains(lowerQuery)
      ).toList();
    } catch (e) {
      throw ShopServiceException('Erreur lors de la recherche de shops: $e');
    }
  }

  /// Récupérer shops par ville
  Future<List<Shop>> getShopsByCity(String city, {bool onlyPublic = true}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('address.city', isEqualTo: city);

      if (onlyPublic) {
        query = query.where('settings.isPublic', isEqualTo: true);
      }

      query = query.orderBy('stats.rating', descending: true);

      final result = await query.get();
      return result.docs.map((doc) => Shop.fromFirestore(doc)).toList();
    } catch (e) {
      throw ShopServiceException('Erreur lors de la récupération des shops par ville: $e');
    }
  }

  /// Récupérer shops par spécialité
  Future<List<Shop>> getShopsBySpecialty(String specialty, {bool onlyPublic = true}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('specialties', arrayContains: specialty);

      if (onlyPublic) {
        query = query.where('settings.isPublic', isEqualTo: true);
      }

      query = query.orderBy('stats.rating', descending: true);

      final result = await query.get();
      return result.docs.map((doc) => Shop.fromFirestore(doc)).toList();
    } catch (e) {
      throw ShopServiceException('Erreur lors de la récupération des shops par spécialité: $e');
    }
  }

  /// Récupérer shops qui acceptent les walk-ins
  Future<List<Shop>> getWalkInShops({String? city}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true)
          .where('settings.acceptsWalkIns', isEqualTo: true);

      if (city != null && city.isNotEmpty) {
        query = query.where('address.city', isEqualTo: city);
      }

      query = query.orderBy('stats.rating', descending: true);

      final result = await query.get();
      return result.docs.map((doc) => Shop.fromFirestore(doc)).toList();
    } catch (e) {
      throw ShopServiceException('Erreur lors de la récupération des shops walk-in: $e');
    }
  }

  /// Récupérer shops qui permettent le booking
  Future<List<Shop>> getBookingShops({String? city}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true)
          .where('settings.allowsBooking', isEqualTo: true);

      if (city != null && city.isNotEmpty) {
        query = query.where('address.city', isEqualTo: city);
      }

      query = query.orderBy('stats.rating', descending: true);

      final result = await query.get();
      return result.docs.map((doc) => Shop.fromFirestore(doc)).toList();
    } catch (e) {
      throw ShopServiceException('Erreur lors de la récupération des shops avec booking: $e');
    }
  }

  /// Récupérer shops qui acceptent les guests (Premium)
  Future<List<Shop>> getGuestFriendlyShops({String? city}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true)
          .where('settings.allowsGuests', isEqualTo: true);

      if (city != null && city.isNotEmpty) {
        query = query.where('address.city', isEqualTo: city);
      }

      query = query.orderBy('stats.rating', descending: true);

      final result = await query.get();
      return result.docs.map((doc) => Shop.fromFirestore(doc)).toList();
    } catch (e) {
      throw ShopServiceException('Erreur lors de la récupération des shops guest-friendly: $e');
    }
  }

  // ===== STREAMS TEMPS RÉEL =====

  /// Stream des shops d'un tatoueur
  Stream<List<Shop>> watchShopsByTattooistId(String tattooistId) {
    return _collection
        .where('tattooistId', isEqualTo: tattooistId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => Shop.fromFirestore(doc)).toList()
        );
  }

  /// Stream des shops publics
  Stream<List<Shop>> watchPublicShops({String? city, int? limit}) {
    Query<Map<String, dynamic>> query = _collection
        .where('settings.isPublic', isEqualTo: true)
        .orderBy('stats.rating', descending: true);

    if (city != null && city.isNotEmpty) {
      query = query.where('address.city', isEqualTo: city);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => Shop.fromFirestore(doc)).toList()
    );
  }

  /// Stream d'un shop spécifique
  Stream<Shop?> watchShop(String shopId) {
    return _collection
        .doc(shopId)
        .snapshots()
        .map((doc) => doc.exists ? Shop.fromFirestore(doc) : null);
  }

  // ===== OPÉRATIONS BUSINESS =====

  /// Mettre à jour les statistiques d'un shop
  Future<void> updateShopStats(String shopId, {
    int? totalTattoos,
    double? rating,
    int? reviewCount,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (totalTattoos != null) {
        updates['stats.totalTattoos'] = totalTattoos;
      }
      if (rating != null) {
        updates['stats.rating'] = rating;
      }
      if (reviewCount != null) {
        updates['stats.reviewCount'] = reviewCount;
      }
      
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _collection.doc(shopId).update(updates);
      }
    } catch (e) {
      throw ShopServiceException('Erreur lors de la mise à jour des stats: $e');
    }
  }

  /// Activer/désactiver la visibilité publique
  Future<void> togglePublicVisibility(String shopId, bool isPublic) async {
    try {
      await _collection.doc(shopId).update({
        'settings.isPublic': isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ShopServiceException('Erreur lors du changement de visibilité: $e');
    }
  }

  /// Activer/désactiver les guests (Premium feature)
  Future<void> toggleGuestAcceptance(String shopId, bool allowsGuests, {int? maxGuestsPerMonth}) async {
    try {
      final Map<String, dynamic> updates = {
        'settings.allowsGuests': allowsGuests,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (maxGuestsPerMonth != null) {
        updates['settings.maxGuestsPerMonth'] = maxGuestsPerMonth;
      }

      await _collection.doc(shopId).update(updates);
    } catch (e) {
      throw ShopServiceException('Erreur lors du changement des paramètres guests: $e');
    }
  }

  /// Ajouter une spécialité
  Future<void> addSpecialty(String shopId, String specialty) async {
    try {
      await _collection.doc(shopId).update({
        'specialties': FieldValue.arrayUnion([specialty]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ShopServiceException('Erreur lors de l\'ajout de spécialité: $e');
    }
  }

  /// Supprimer une spécialité
  Future<void> removeSpecialty(String shopId, String specialty) async {
    try {
      await _collection.doc(shopId).update({
        'specialties': FieldValue.arrayRemove([specialty]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ShopServiceException('Erreur lors de la suppression de spécialité: $e');
    }
  }

  /// Mettre à jour les horaires
  Future<void> updateSchedule(String shopId, ShopSchedule schedule) async {
    try {
      await _collection.doc(shopId).update({
        'schedule': schedule.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ShopServiceException('Erreur lors de la mise à jour des horaires: $e');
    }
  }

  // ===== STATISTIQUES =====

  /// Obtenir le nombre de shops par ville
  Future<Map<String, int>> getShopsCountByCity() async {
    try {
      final shops = await getPublicShops();
      final Map<String, int> cityCount = {};
      
      for (final shop in shops) {
        final city = shop.address.city;
        cityCount[city] = (cityCount[city] ?? 0) + 1;
      }
      
      return cityCount;
    } catch (e) {
      throw ShopServiceException('Erreur lors du calcul des stats par ville: $e');
    }
  }

  /// Obtenir le nombre de shops par spécialité
  Future<Map<String, int>> getShopsCountBySpecialty() async {
    try {
      final shops = await getPublicShops();
      final Map<String, int> specialtyCount = {};
      
      for (final shop in shops) {
        for (final specialty in shop.specialties) {
          specialtyCount[specialty] = (specialtyCount[specialty] ?? 0) + 1;
        }
      }
      
      return specialtyCount;
    } catch (e) {
      throw ShopServiceException('Erreur lors du calcul des stats par spécialité: $e');
    }
  }

  /// Obtenir les shops les mieux notés
  Future<List<Shop>> getTopRatedShops({int limit = 10}) async {
    try {
      final result = await _collection
          .where('settings.isPublic', isEqualTo: true)
          .where('stats.reviewCount', isGreaterThan: 0)
          .orderBy('stats.reviewCount', descending: false)
          .orderBy('stats.rating', descending: true)
          .limit(limit)
          .get();

      return result.docs.map((doc) => Shop.fromFirestore(doc)).toList();
    } catch (e) {
      throw ShopServiceException('Erreur lors de la récupération des top shops: $e');
    }
  }

  // ===== VALIDATION =====

  /// Valider qu'un shop peut être créé/modifié
  Future<bool> validateShop(Shop shop) async {
    try {
      // Vérifier l'unicité du nom par tatoueur
      final existing = await _collection
          .where('tattooistId', isEqualTo: shop.tattooistId)
          .where('name', isEqualTo: shop.name)
          .get();

      if (existing.docs.isNotEmpty) {
        // Si c'est une mise à jour du même shop, c'est OK
        if (existing.docs.length == 1 && existing.docs.first.id == shop.id) {
          return true;
        }
        throw ShopServiceException('Un shop avec ce nom existe déjà pour ce tatoueur');
      }

      return true;
    } catch (e) {
      if (e is ShopServiceException) rethrow;
      throw ShopServiceException('Erreur lors de la validation du shop: $e');
    }
  }
}

/// Exception personnalisée pour le ShopService
class ShopServiceException implements Exception {
  final String message;
  ShopServiceException(this.message);
  
  @override
  String toString() => 'ShopServiceException: $message';
}