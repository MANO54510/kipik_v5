// lib/services/organisateur/convention_management_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ConventionManagementService {
  static final ConventionManagementService _instance = ConventionManagementService._internal();
  factory ConventionManagementService() => _instance;
  ConventionManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _conventionsCollection => _firestore.collection('conventions');

  /// Stream des conventions d'un organisateur
  Stream<QuerySnapshot> getConventionsStream(String organizerId) {
    return _conventionsCollection
        .where('basic.organizerId', isEqualTo: organizerId)
        .orderBy('basic.updatedAt', descending: true)
        .snapshots();
  }

  /// Récupère une convention spécifique
  Future<DocumentSnapshot> getConvention(String conventionId) {
    return _conventionsCollection.doc(conventionId).get();
  }

  /// Crée une nouvelle convention
  Future<String> createConvention(Map<String, dynamic> conventionData) async {
    try {
      final docRef = await _conventionsCollection.add(conventionData);
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la convention: $e');
    }
  }

  /// Met à jour une convention
  Future<void> updateConvention(String conventionId, Map<String, dynamic> data) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        ...data,
        'basic.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Publie une convention (change le statut de draft à published)
  Future<void> publishConvention(String conventionId) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'basic.status': 'published',
        'basic.publishedAt': FieldValue.serverTimestamp(),
        'basic.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la publication: $e');
    }
  }

  /// Duplique une convention
  Future<String> duplicateConvention(String conventionId) async {
    try {
      final originalDoc = await _conventionsCollection.doc(conventionId).get();
      if (!originalDoc.exists) {
        throw Exception('Convention non trouvée');
      }

      final originalData = originalDoc.data() as Map<String, dynamic>;
      
      // Modifier les données pour la copie
      final duplicatedData = Map<String, dynamic>.from(originalData);
      duplicatedData['basic']['name'] = '${originalData['basic']['name']} - Copie';
      duplicatedData['basic']['status'] = 'draft';
      duplicatedData['basic']['createdAt'] = FieldValue.serverTimestamp();
      duplicatedData['basic']['updatedAt'] = FieldValue.serverTimestamp();
      duplicatedData['basic']['publishedAt'] = null;
      
      // Réinitialiser les stats
      duplicatedData['stats'] = {
        'tattooersCount': 0,
        'maxTattooers': originalData['stats']['maxTattooers'] ?? 50,
        'ticketsSold': 0,
        'expectedVisitors': originalData['stats']['expectedVisitors'] ?? 500,
        'revenue': {
          'total': 0.0,
          'stands': 0.0,
          'tickets': 0.0,
          'kipikCommission': 0.0,
        },
      };

      final docRef = await _conventionsCollection.add(duplicatedData);
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la duplication: $e');
    }
  }

  /// Annule une convention
  Future<void> cancelConvention(String conventionId, String reason) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'basic.status': 'cancelled',
        'basic.cancelledAt': FieldValue.serverTimestamp(),
        'basic.cancellationReason': reason,
        'basic.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  /// Marque une convention comme terminée
  Future<void> completeConvention(String conventionId) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'basic.status': 'completed',
        'basic.completedAt': FieldValue.serverTimestamp(),
        'basic.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la finalisation: $e');
    }
  }

  /// Stream des conventions publiques (pour les tatoueurs et visiteurs)
  Stream<QuerySnapshot> getPublicConventionsStream({
    String? location,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) {
    Query query = _conventionsCollection
        .where('basic.status', whereIn: ['published', 'active']);

    if (location != null && location.isNotEmpty) {
      query = query.where('location.address', isGreaterThanOrEqualTo: location);
    }

    if (type != null && type.isNotEmpty) {
      query = query.where('basic.type', isEqualTo: type);
    }

    if (startDate != null) {
      query = query.where('dates.start', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('dates.start', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query
        .orderBy('dates.start', descending: false)
        .limit(limit)
        .snapshots();
  }

  /// Recherche de conventions par nom
  Future<QuerySnapshot> searchConventions(String query, {String? organizerId}) async {
    try {
      Query firestoreQuery = _conventionsCollection
          .where('basic.name', isGreaterThanOrEqualTo: query)
          .where('basic.name', isLessThanOrEqualTo: '$query\uf8ff');

      if (organizerId != null) {
        firestoreQuery = firestoreQuery.where('basic.organizerId', isEqualTo: organizerId);
      }

      return await firestoreQuery.limit(20).get();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Met à jour les statistiques de la convention
  Future<void> updateConventionStats(String conventionId, Map<String, dynamic> stats) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'stats': stats,
        'basic.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des stats: $e');
    }
  }

  /// Incrémente une statistique spécifique
  Future<void> incrementConventionStat(String conventionId, String statPath, num value) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'stats.$statPath': FieldValue.increment(value),
        'basic.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'incrémentation: $e');
    }
  }

  /// Stream des conventions par statut
  Stream<QuerySnapshot> getConventionsByStatusStream(String organizerId, String status) {
    return _conventionsCollection
        .where('basic.organizerId', isEqualTo: organizerId)
        .where('basic.status', isEqualTo: status)
        .orderBy('basic.updatedAt', descending: true)
        .snapshots();
  }

  /// Récupère les conventions populaires (par nombre de tatoueurs inscrits)
  Future<QuerySnapshot> getPopularConventions({int limit = 10}) async {
    try {
      return await _conventionsCollection
          .where('basic.status', whereIn: ['published', 'active'])
          .orderBy('stats.tattooersCount', descending: true)
          .limit(limit)
          .get();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des conventions populaires: $e');
    }
  }

  /// Récupère les conventions à venir
  Future<QuerySnapshot> getUpcomingConventions({int limit = 20}) async {
    try {
      final now = Timestamp.now();
      return await _conventionsCollection
          .where('basic.status', whereIn: ['published', 'active'])
          .where('dates.start', isGreaterThan: now)
          .orderBy('dates.start', descending: false)
          .limit(limit)
          .get();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des conventions à venir: $e');
    }
  }

  /// Ajoute une zone de prix à une convention
  Future<void> addPricingZone(String conventionId, Map<String, dynamic> zone) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'pricing.zones': FieldValue.arrayUnion([zone]),
        'pricing.hasZonePricing': true,
        'basic.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la zone: $e');
    }
  }

  /// Supprime une zone de prix
  Future<void> removePricingZone(String conventionId, Map<String, dynamic> zone) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'pricing.zones': FieldValue.arrayRemove([zone]),
        'basic.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la zone: $e');
    }
  }

  /// Met à jour les équipements/services d'une convention
  Future<void> updateAmenities(String conventionId, List<String> amenities) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'settings.amenities': amenities,
        'basic.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des équipements: $e');
    }
  }

  /// Active/désactive la réservation en ligne
  Future<void> toggleOnlineBooking(String conventionId, bool enabled) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'settings.onlineBooking': enabled,
        'basic.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la modification des réservations: $e');
    }
  }

  /// Supprime définitivement une convention (GDPR)
  Future<void> deleteConvention(String conventionId) async {
    try {
      // Vérifier s'il y a des données liées avant suppression
      final standRequests = await _firestore
          .collection('standRequests')
          .where('convention.conventionId', isEqualTo: conventionId)
          .get();

      if (standRequests.docs.isNotEmpty) {
        throw Exception('Impossible de supprimer: des demandes de stands existent');
      }

      await _conventionsCollection.doc(conventionId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Calcule les revenus estimés d'une convention
  Map<String, double> calculateEstimatedRevenue(Map<String, dynamic> conventionData) {
    final hasZonePricing = conventionData['pricing']?['hasZonePricing'] ?? false;
    final maxTattooers = (conventionData['stats']?['maxTattooers'] ?? 50).toDouble();
    final expectedVisitors = (conventionData['stats']?['expectedVisitors'] ?? 500).toDouble();
    final ticketPrice = (conventionData['pricing']?['ticketPrice'] ?? 15.0).toDouble();
    
    double standRevenue = 0.0;
    
    if (hasZonePricing && conventionData['pricing']?['zones'] != null) {
      final zones = conventionData['pricing']['zones'] as List;
      if (zones.isNotEmpty) {
        final avgPrice = zones.fold<double>(0.0, (sum, zone) => 
            sum + ((zone['pricePerM2'] ?? 0.0) as num).toDouble()) / zones.length;
        standRevenue = maxTattooers * avgPrice * 6; // 6m² moyenne par stand
      }
    } else {
      final standPrice = (conventionData['pricing']?['standPrice'] ?? 300.0).toDouble();
      standRevenue = maxTattooers * standPrice;
    }
    
    final ticketRevenue = expectedVisitors * ticketPrice;
    final totalRevenue = standRevenue + ticketRevenue;
    final kipikCommission = totalRevenue * 0.01;
    final netRevenue = totalRevenue - kipikCommission;
    
    return {
      'standRevenue': standRevenue,
      'ticketRevenue': ticketRevenue,
      'totalRevenue': totalRevenue,
      'kipikCommission': kipikCommission,
      'netRevenue': netRevenue,
    };
  }
}