// lib/services/convention/firebase_convention_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/convention.dart';

class FirebaseConventionService {
  static FirebaseConventionService? _instance;
  static FirebaseConventionService get instance => _instance ??= FirebaseConventionService._();
  FirebaseConventionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'conventions';

  Future<List<Convention>> fetchConventions() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('start', descending: false) // ✅ Utiliser 'start' au lieu de 'date'
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Convention(
          id: doc.id,
          title: data['title'] ?? '', // ✅ Utiliser 'title' au lieu de 'name'
          location: data['location'] ?? '',
          description: data['description'] ?? '',
          website: data['website'],
          start: (data['start'] as Timestamp?)?.toDate() ?? DateTime.now(), // ✅ 'start'
          end: (data['end'] as Timestamp?)?.toDate() ?? DateTime.now(), // ✅ 'end'
          isPremium: data['isPremium'] ?? false, // ✅ 'isPremium'
          isOpen: data['isOpen'] ?? true, // ✅ 'isOpen' au lieu de 'isActive'
          imageUrl: data['imageUrl'] ?? '',
          artists: data['artists'] != null ? List<String>.from(data['artists']) : null,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          proSpots: data['proSpots'] as int?,
          merchandiseSpots: data['merchandiseSpots'] as int?,
          dayTicketPrice: (data['dayTicketPrice'] as num?)?.toDouble(),
          weekendTicketPrice: (data['weekendTicketPrice'] as num?)?.toDouble(),
          events: data['events'] != null ? List<String>.from(data['events']) : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des conventions: $e');
    }
  }

  /// Ajouter une nouvelle convention (pour les admins)
  Future<String> createConvention(Convention convention) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'title': convention.title, // ✅ 'title'
        'location': convention.location,
        'description': convention.description,
        'website': convention.website,
        'start': Timestamp.fromDate(convention.start), // ✅ 'start'
        'end': Timestamp.fromDate(convention.end), // ✅ 'end'
        'isPremium': convention.isPremium, // ✅ 'isPremium'
        'isOpen': convention.isOpen, // ✅ 'isOpen'
        'imageUrl': convention.imageUrl,
        'artists': convention.artists,
        'latitude': convention.latitude,
        'longitude': convention.longitude,
        'proSpots': convention.proSpots,
        'merchandiseSpots': convention.merchandiseSpots,
        'dayTicketPrice': convention.dayTicketPrice,
        'weekendTicketPrice': convention.weekendTicketPrice,
        'events': convention.events,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la convention: $e');
    }
  }

  /// Mettre à jour une convention
  Future<void> updateConvention(String conventionId, Map<String, dynamic> updates) async {
    try {
      // ✅ Convertir les dates si nécessaire
      if (updates.containsKey('start') && updates['start'] is DateTime) {
        updates['start'] = Timestamp.fromDate(updates['start']);
      }
      if (updates.containsKey('end') && updates['end'] is DateTime) {
        updates['end'] = Timestamp.fromDate(updates['end']);
      }
      
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(conventionId).update(updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la convention: $e');
    }
  }

  /// Mettre à jour une convention complète
  Future<void> updateConventionObject(Convention convention) async {
    try {
      await _firestore.collection(_collection).doc(convention.id).update({
        'title': convention.title,
        'location': convention.location,
        'description': convention.description,
        'website': convention.website,
        'start': Timestamp.fromDate(convention.start),
        'end': Timestamp.fromDate(convention.end),
        'isPremium': convention.isPremium,
        'isOpen': convention.isOpen,
        'imageUrl': convention.imageUrl,
        'artists': convention.artists,
        'latitude': convention.latitude,
        'longitude': convention.longitude,
        'proSpots': convention.proSpots,
        'merchandiseSpots': convention.merchandiseSpots,
        'dayTicketPrice': convention.dayTicketPrice,
        'weekendTicketPrice': convention.weekendTicketPrice,
        'events': convention.events,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la convention: $e');
    }
  }

  /// Supprimer une convention
  Future<void> deleteConvention(String conventionId) async {
    try {
      await _firestore.collection(_collection).doc(conventionId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la convention: $e');
    }
  }

  /// Rechercher des conventions par critères
  Future<List<Convention>> searchConventions({
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    bool? isPremium,
    bool? isOpen,
    List<String>? events,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      if (startDate != null) {
        query = query.where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('end', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (isPremium != null) {
        query = query.where('isPremium', isEqualTo: isPremium);
      }

      if (isOpen != null) {
        query = query.where('isOpen', isEqualTo: isOpen);
      }

      if (events != null && events.isNotEmpty) {
        query = query.where('events', arrayContainsAny: events);
      }

      query = query.orderBy('start', descending: false);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Convention(
          id: doc.id,
          title: data['title'] ?? '',
          location: data['location'] ?? '',
          description: data['description'] ?? '',
          website: data['website'],
          start: (data['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
          end: (data['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isPremium: data['isPremium'] ?? false,
          isOpen: data['isOpen'] ?? true,
          imageUrl: data['imageUrl'] ?? '',
          artists: data['artists'] != null ? List<String>.from(data['artists']) : null,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          proSpots: data['proSpots'] as int?,
          merchandiseSpots: data['merchandiseSpots'] as int?,
          dayTicketPrice: (data['dayTicketPrice'] as num?)?.toDouble(),
          weekendTicketPrice: (data['weekendTicketPrice'] as num?)?.toDouble(),
          events: data['events'] != null ? List<String>.from(data['events']) : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche de conventions: $e');
    }
  }

  /// Obtenir les conventions actives et ouvertes
  Future<List<Convention>> getActiveConventions() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isOpen', isEqualTo: true)
          .where('start', isGreaterThan: Timestamp.now())
          .orderBy('start', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Convention(
          id: doc.id,
          title: data['title'] ?? '',
          location: data['location'] ?? '',
          description: data['description'] ?? '',
          website: data['website'],
          start: (data['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
          end: (data['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isPremium: data['isPremium'] ?? false,
          isOpen: data['isOpen'] ?? true,
          imageUrl: data['imageUrl'] ?? '',
          artists: data['artists'] != null ? List<String>.from(data['artists']) : null,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          proSpots: data['proSpots'] as int?,
          merchandiseSpots: data['merchandiseSpots'] as int?,
          dayTicketPrice: (data['dayTicketPrice'] as num?)?.toDouble(),
          weekendTicketPrice: (data['weekendTicketPrice'] as num?)?.toDouble(),
          events: data['events'] != null ? List<String>.from(data['events']) : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des conventions actives: $e');
    }
  }

  /// S'inscrire à une convention
  Future<void> registerForConvention(String conventionId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Ajouter l'inscription
      final registrationRef = _firestore
          .collection(_collection)
          .doc(conventionId)
          .collection('registrations')
          .doc(userId);

      batch.set(registrationRef, {
        'userId': userId,
        'registeredAt': FieldValue.serverTimestamp(),
        'status': 'confirmed',
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription à la convention: $e');
    }
  }

  /// Se désinscrire d'une convention
  Future<void> unregisterFromConvention(String conventionId, String userId) async {
    try {
      final registrationRef = _firestore
          .collection(_collection)
          .doc(conventionId)
          .collection('registrations')
          .doc(userId);

      await registrationRef.delete();
    } catch (e) {
      throw Exception('Erreur lors de la désinscription de la convention: $e');
    }
  }

  /// Vérifier si un utilisateur est inscrit à une convention
  Future<bool> isUserRegistered(String conventionId, String userId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(conventionId)
          .collection('registrations')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Obtenir la liste des inscrits à une convention
  Future<List<String>> getRegisteredUsers(String conventionId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(conventionId)
          .collection('registrations')
          .get();

      return snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des inscrits: $e');
    }
  }

  /// Créer des conventions de test
  Future<void> createSampleConventions() async {
    final sampleConventions = [
      Convention(
        id: '',
        title: 'Convention Tattoo Paris 2025',
        location: 'Paris Expo Porte de Versailles',
        description: 'La plus grande convention de tatouage de France. Rencontrez les meilleurs artistes tatoueurs.',
        website: 'https://paristattoo.com',
        start: DateTime(2025, 7, 15),
        end: DateTime(2025, 7, 17),
        isPremium: true,
        isOpen: true,
        imageUrl: 'https://example.com/paris-tattoo.jpg',
        artists: ['Mike Tattoo', 'Sarah Ink', 'David Black'],
        latitude: 48.8566,
        longitude: 2.3522,
        proSpots: 50,
        merchandiseSpots: 20,
        dayTicketPrice: 25.0,
        weekendTicketPrice: 40.0,
        events: ['Concours du meilleur tatouage', 'Démos live'],
      ),
      Convention(
        id: '',
        title: 'Ink Masters Lyon',
        location: 'Centre de Congrès de Lyon',
        description: 'Rencontrez les meilleurs tatoueurs de la région Rhône-Alpes.',
        website: 'https://inkmarterslyon.fr',
        start: DateTime(2025, 9, 20),
        end: DateTime(2025, 9, 22),
        isPremium: false,
        isOpen: true,
        imageUrl: 'https://example.com/lyon-tattoo.jpg',
        artists: ['Alex Lyon', 'Marie Rhône'],
        latitude: 45.7640,
        longitude: 4.8357,
        proSpots: 30,
        merchandiseSpots: 15,
        dayTicketPrice: 20.0,
        weekendTicketPrice: 35.0,
        events: ['Ateliers débutants', 'Expo photos'],
      ),
    ];

    for (final convention in sampleConventions) {
      try {
        await createConvention(convention);
        print('Convention créée: ${convention.title}');
      } catch (e) {
        print('Erreur création convention ${convention.title}: $e');
      }
    }
  }
}