// lib/services/event_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/models/event_model.dart';
import '../core/database_manager.dart';

/// 🎪 Service pour la gestion des événements/conventions
/// Gère toutes les opérations CRUD et business logic des événements
class EventService {
  static const String collectionName = 'events';
  
  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _collection;

  EventService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? DatabaseManager.instance.firestore {
    _collection = _firestore.collection(collectionName);
  }

  // ===== OPÉRATIONS CRUD =====

  /// Créer un nouvel événement
  Future<Event> createEvent(Event event) async {
    try {
      final newEvent = event.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _collection.add(newEvent.toFirestore());
      
      return newEvent.copyWith(id: docRef.id);
    } catch (e) {
      throw EventServiceException('Erreur lors de la création de l\'événement: $e');
    }
  }

  /// Récupérer un événement par ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _collection.doc(eventId).get();
      
      if (!doc.exists) return null;
      
      return Event.fromFirestore(doc);
    } catch (e) {
      throw EventServiceException('Erreur lors de la récupération de l\'événement: $e');
    }
  }

  /// Mettre à jour un événement
  Future<Event> updateEvent(Event event) async {
    try {
      final updatedEvent = event.copyWith(updatedAt: DateTime.now());
      
      await _collection.doc(event.id).update(updatedEvent.toFirestore());
      
      return updatedEvent;
    } catch (e) {
      throw EventServiceException('Erreur lors de la mise à jour de l\'événement: $e');
    }
  }

  /// Supprimer un événement
  Future<void> deleteEvent(String eventId) async {
    try {
      await _collection.doc(eventId).delete();
    } catch (e) {
      throw EventServiceException('Erreur lors de la suppression de l\'événement: $e');
    }
  }

  // ===== REQUÊTES BUSINESS =====

  /// Récupérer les événements d'un organisateur
  Future<List<Event>> getEventsByOrganizerId(String organizerId) async {
    try {
      final query = await _collection
          .where('organiserId', isEqualTo: organizerId)
          .orderBy('dates.startDate', descending: false)
          .get();

      return query.docs.map((doc) => Event.fromFirestore(doc)).toList();
    } catch (e) {
      throw EventServiceException('Erreur lors de la récupération des événements de l\'organisateur: $e');
    }
  }

  /// Récupérer tous les événements publics
  Future<List<Event>> getPublicEvents({
    String? city,
    EventType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true);

      // Filtrer par ville si spécifiée
      if (city != null && city.isNotEmpty) {
        query = query.where('location.city', isEqualTo: city);
      }

      // Filtrer par type si spécifié
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      // Ordonner par date de début
      query = query.orderBy('dates.startDate', descending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query.get();
      var events = result.docs.map((doc) => Event.fromFirestore(doc)).toList();

      // Filtrer par dates côté client si spécifié
      if (startDate != null || endDate != null) {
        events = events.where((event) {
          if (startDate != null && event.dates.endDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && event.dates.startDate.isAfter(endDate)) {
            return false;
          }
          return true;
        }).toList();
      }

      return events;
    } catch (e) {
      throw EventServiceException('Erreur lors de la récupération des événements publics: $e');
    }
  }

  /// Récupérer les événements à venir
  Future<List<Event>> getUpcomingEvents({String? city, int? limit}) async {
    try {
      final now = DateTime.now();
      
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true)
          .where('dates.startDate', isGreaterThan: Timestamp.fromDate(now));

      if (city != null && city.isNotEmpty) {
        query = query.where('location.city', isEqualTo: city);
      }

      query = query.orderBy('dates.startDate', descending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query.get();
      return result.docs.map((doc) => Event.fromFirestore(doc)).toList();
    } catch (e) {
      throw EventServiceException('Erreur lors de la récupération des événements à venir: $e');
    }
  }

  /// Récupérer les événements en cours
  Future<List<Event>> getOngoingEvents({String? city}) async {
    try {
      final now = DateTime.now();
      
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true)
          .where('dates.startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('dates.endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now));

      if (city != null && city.isNotEmpty) {
        query = query.where('location.city', isEqualTo: city);
      }

      query = query.orderBy('dates.startDate', descending: false);

      final result = await query.get();
      return result.docs.map((doc) => Event.fromFirestore(doc)).toList();
    } catch (e) {
      throw EventServiceException('Erreur lors de la récupération des événements en cours: $e');
    }
  }

  /// Rechercher des événements
  Future<List<Event>> searchEvents({
    required String query,
    String? city,
    EventType? type,
    int? limit,
  }) async {
    try {
      // Récupérer tous les événements publics puis filtrer côté client
      final events = await getPublicEvents(
        city: city,
        type: type,
        limit: limit,
      );

      final lowerQuery = query.toLowerCase();
      
      return events.where((event) =>
        event.title.toLowerCase().contains(lowerQuery) ||
        event.description.toLowerCase().contains(lowerQuery) ||
        event.location.venue.toLowerCase().contains(lowerQuery) ||
        event.location.city.toLowerCase().contains(lowerQuery) ||
        event.category.toLowerCase().contains(lowerQuery)
      ).toList();
    } catch (e) {
      throw EventServiceException('Erreur lors de la recherche d\'événements: $e');
    }
  }

  /// Récupérer événements par ville
  Future<List<Event>> getEventsByCity(String city, {bool onlyUpcoming = true}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true)
          .where('location.city', isEqualTo: city);

      if (onlyUpcoming) {
        final now = DateTime.now();
        query = query.where('dates.startDate', isGreaterThan: Timestamp.fromDate(now));
      }

      query = query.orderBy('dates.startDate', descending: false);

      final result = await query.get();
      return result.docs.map((doc) => Event.fromFirestore(doc)).toList();
    } catch (e) {
      throw EventServiceException('Erreur lors de la récupération des événements par ville: $e');
    }
  }

  /// Récupérer événements par type
  Future<List<Event>> getEventsByType(EventType type, {bool onlyUpcoming = true}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true)
          .where('type', isEqualTo: type.name);

      if (onlyUpcoming) {
        final now = DateTime.now();
        query = query.where('dates.startDate', isGreaterThan: Timestamp.fromDate(now));
      }

      query = query.orderBy('dates.startDate', descending: false);

      final result = await query.get();
      return result.docs.map((doc) => Event.fromFirestore(doc)).toList();
    } catch (e) {
      throw EventServiceException('Erreur lors de la récupération des événements par type: $e');
    }
  }

  /// Récupérer événements avec places disponibles
  Future<List<Event>> getAvailableEvents({String? city}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true)
          .where('settings.allowsOnlineTicketing', isEqualTo: true);

      if (city != null && city.isNotEmpty) {
        query = query.where('location.city', isEqualTo: city);
      }

      final now = DateTime.now();
      query = query
          .where('dates.startDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('dates.startDate', descending: false);

      final result = await query.get();
      final events = result.docs.map((doc) => Event.fromFirestore(doc)).toList();

      // Filtrer côté client pour avoir des places disponibles
      return events.where((event) => event.availableSpots > 0).toList();
    } catch (e) {
      throw EventServiceException('Erreur lors de la récupération des événements disponibles: $e');
    }
  }

  // ===== STREAMS TEMPS RÉEL =====

  /// Stream des événements d'un organisateur
  Stream<List<Event>> watchEventsByOrganizerId(String organizerId) {
    return _collection
        .where('organiserId', isEqualTo: organizerId)
        .orderBy('dates.startDate', descending: false)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList()
        );
  }

  /// Stream des événements publics
  Stream<List<Event>> watchPublicEvents({String? city, int? limit}) {
    Query<Map<String, dynamic>> query = _collection
        .where('settings.isPublic', isEqualTo: true)
        .orderBy('dates.startDate', descending: false);

    if (city != null && city.isNotEmpty) {
      query = query.where('location.city', isEqualTo: city);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList()
    );
  }

  /// Stream d'un événement spécifique
  Stream<Event?> watchEvent(String eventId) {
    return _collection
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? Event.fromFirestore(doc) : null);
  }

  // ===== OPÉRATIONS BUSINESS =====

  /// Mettre à jour la capacité d'un événement
  Future<void> updateEventCapacity(String eventId, {
    int? currentRegistrations,
    int? currentApplications,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (currentRegistrations != null) {
        updates['capacity.currentRegistrations'] = currentRegistrations;
      }
      if (currentApplications != null) {
        updates['capacity.currentApplications'] = currentApplications;
      }
      
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _collection.doc(eventId).update(updates);
      }
    } catch (e) {
      throw EventServiceException('Erreur lors de la mise à jour de la capacité: $e');
    }
  }

  /// Activer/désactiver la visibilité publique
  Future<void> togglePublicVisibility(String eventId, bool isPublic) async {
    try {
      await _collection.doc(eventId).update({
        'settings.isPublic': isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw EventServiceException('Erreur lors du changement de visibilité: $e');
    }
  }

  /// Activer/désactiver la billetterie en ligne
  Future<void> toggleOnlineTicketing(String eventId, bool allowsOnlineTicketing) async {
    try {
      await _collection.doc(eventId).update({
        'settings.allowsOnlineTicketing': allowsOnlineTicketing,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw EventServiceException('Erreur lors du changement de la billetterie: $e');
    }
  }

  /// Mettre à jour les tarifs
  Future<void> updateEventPricing(String eventId, EventPricing pricing) async {
    try {
      await _collection.doc(eventId).update({
        'pricing': pricing.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw EventServiceException('Erreur lors de la mise à jour des tarifs: $e');
    }
  }

  /// Ajouter une fonctionnalité
  Future<void> addFeature(String eventId, String feature) async {
    try {
      await _collection.doc(eventId).update({
        'features': FieldValue.arrayUnion([feature]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw EventServiceException('Erreur lors de l\'ajout de fonctionnalité: $e');
    }
  }

  /// Supprimer une fonctionnalité
  Future<void> removeFeature(String eventId, String feature) async {
    try {
      await _collection.doc(eventId).update({
        'features': FieldValue.arrayRemove([feature]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw EventServiceException('Erreur lors de la suppression de fonctionnalité: $e');
    }
  }

  // ===== STATISTIQUES =====

  /// Obtenir le nombre d'événements par ville
  Future<Map<String, int>> getEventsCountByCity() async {
    try {
      final events = await getPublicEvents();
      final Map<String, int> cityCount = {};
      
      for (final event in events) {
        final city = event.location.city;
        cityCount[city] = (cityCount[city] ?? 0) + 1;
      }
      
      return cityCount;
    } catch (e) {
      throw EventServiceException('Erreur lors du calcul des stats par ville: $e');
    }
  }

  /// Obtenir le nombre d'événements par type
  Future<Map<EventType, int>> getEventsCountByType() async {
    try {
      final events = await getPublicEvents();
      final Map<EventType, int> typeCount = {};
      
      for (final event in events) {
        typeCount[event.type] = (typeCount[event.type] ?? 0) + 1;
      }
      
      return typeCount;
    } catch (e) {
      throw EventServiceException('Erreur lors du calcul des stats par type: $e');
    }
  }

  /// Obtenir les événements les plus populaires
  Future<List<Event>> getPopularEvents({int limit = 10}) async {
    try {
      final events = await getPublicEvents();
      
      // Trier par pourcentage de remplissage
      events.sort((a, b) => b.fillPercentage.compareTo(a.fillPercentage));
      
      return events.take(limit).toList();
    } catch (e) {
      throw EventServiceException('Erreur lors de la récupération des événements populaires: $e');
    }
  }

  // ===== VALIDATION =====

  /// Valider qu'un événement peut être créé/modifié
  Future<bool> validateEvent(Event event) async {
    try {
      // Vérifier que les dates sont cohérentes
      if (!event.dates.isValid) {
        throw EventServiceException('Les dates de l\'événement ne sont pas valides');
      }

      // Vérifier que l'événement est dans le futur (pour création)
      if (event.id.isEmpty && event.dates.startDate.isBefore(DateTime.now())) {
        throw EventServiceException('Un événement ne peut pas être créé dans le passé');
      }

      // Vérifier la cohérence des capacités
      if (event.capacity.maxVisitors <= 0 || event.capacity.maxTattooists <= 0) {
        throw EventServiceException('Les capacités doivent être supérieures à 0');
      }

      // Vérifier la cohérence des tarifs
      if (event.pricing.public.dayPass <= 0 || event.pricing.professional.dayPass <= 0) {
        throw EventServiceException('Les tarifs doivent être supérieurs à 0');
      }

      return true;
    } catch (e) {
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Erreur lors de la validation de l\'événement: $e');
    }
  }
}

/// Exception personnalisée pour le EventService
class EventServiceException implements Exception {
  final String message;
  EventServiceException(this.message);
  
  @override
  String toString() => 'EventServiceException: $message';
}