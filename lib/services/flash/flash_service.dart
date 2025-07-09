// lib/services/flash/flash_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/flash/flash.dart';
import '../../models/flash/flash_booking.dart';
import '../../models/flash/flash_booking_status.dart'; // ✅ Import correct

/// Service sophistiqué et unifié pour la gestion des flashs
class FlashService {
  static final FlashService _instance = FlashService._internal();
  static FlashService get instance => _instance;
  FlashService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections Firestore
  static const String _flashsCollection = 'flashs';
  static const String _bookingsCollection = 'flash_bookings';
  static const String _favoritesCollection = 'user_favorites';
  static const String _analyticsCollection = 'flash_analytics';

  /// ✅ MÉTHODES BOOKING - TOUTES CORRIGÉES

  /// Créer une nouvelle réservation
  Future<String> createBooking(FlashBooking booking) async {
    try {
      final docRef = await _firestore
          .collection(_bookingsCollection)
          .add(booking.toFirestore());
      
      await _incrementFlashBookingRequests(booking.flashId);
      return docRef.id;
    } catch (e) {
      print('Erreur createBooking: $e');
      throw Exception('Erreur lors de la création de la réservation');
    }
  }

  /// ✅ Obtenir les réservations d'un client
  Future<List<FlashBooking>> getBookingsByClient(String clientId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FlashBooking.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur getBookingsByClient: $e');
      return _generateDemoBookings(clientId);
    }
  }

  /// ✅ Obtenir les réservations d'un artiste
  Future<List<FlashBooking>> getBookingsByArtist(String artistId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('tattooArtistId', isEqualTo: artistId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FlashBooking.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur getBookingsByArtist: $e');
      return _generateDemoBookings(artistId);
    }
  }

  /// ✅ MÉTHODE UNIVERSELLE pour changer le statut
  Future<void> updateBookingStatus(String bookingId, FlashBookingStatus newStatus) async {
    try {
      await _firestore
          .collection(_bookingsCollection)
          .doc(bookingId)
          .update({
        'status': newStatus.name, // ✅ Utilise .name au lieu de .toString()
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Erreur updateBookingStatus: $e');
      throw Exception('Erreur lors du changement de statut');
    }
  }

  /// ✅ Confirmer une réservation (tatoueur)
  Future<void> confirmBooking(String bookingId) async {
    await updateBookingStatus(bookingId, FlashBookingStatus.confirmed);
  }

  /// ✅ Refuser une réservation (tatoueur)
  Future<void> rejectBooking(String bookingId, [String? reason]) async {
    try {
      final updates = {
        'status': FlashBookingStatus.rejected.name, // ✅ Corrigé
        'updatedAt': Timestamp.now(),
      };
      
      if (reason != null) {
        updates['rejectionReason'] = reason;
      }
      
      await _firestore
          .collection(_bookingsCollection)
          .doc(bookingId)
          .update(updates);
    } catch (e) {
      print('Erreur rejectBooking: $e');
      throw Exception('Erreur lors du refus');
    }
  }

  /// ✅ Annuler une réservation (client)
  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, FlashBookingStatus.cancelled);
  }

  /// ✅ Marquer comme terminée
  Future<void> completeBooking(String bookingId) async {
    await updateBookingStatus(bookingId, FlashBookingStatus.completed);
  }

  /// ✅ MÉTHODES FLASH DE BASE

  /// Obtenir tous les flashs disponibles
  Future<List<Flash>> getAvailableFlashs({int limit = 20, String? lastFlashId}) async {
    try {
      Query query = _firestore
          .collection(_flashsCollection)
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastFlashId != null) {
        final lastDoc = await _firestore.collection(_flashsCollection).doc(lastFlashId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Flash.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur getAvailableFlashs: $e');
      return _generateDemoFlashs();
    }
  }

  /// Obtenir un flash par ID
  Future<Flash> getFlashById(String flashId) async {
    try {
      final doc = await _firestore
          .collection(_flashsCollection)
          .doc(flashId)
          .get();

      if (doc.exists) {
        await _incrementFlashViews(flashId);
        return Flash.fromFirestore(doc);
      } else {
        throw Exception('Flash non trouvé');
      }
    } catch (e) {
      print('Erreur getFlashById: $e');
      return _generateDemoFlashs().firstWhere(
        (flash) => flash.id == flashId,
        orElse: () => _generateDemoFlashs().first,
      );
    }
  }

  /// Obtenir les flashs d'un artiste
  Future<List<Flash>> getFlashsByArtist(
    String artistId, {
    FlashStatus? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_flashsCollection)
          .where('tattooArtistId', isEqualTo: artistId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Flash.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur getFlashsByArtist: $e');
      return _generateDemoFlashs();
    }
  }

  /// Créer un nouveau flash
  Future<String> createFlash(Flash flash) async {
    try {
      final flashData = flash.toMap();
      flashData['createdAt'] = Timestamp.now();
      flashData['updatedAt'] = Timestamp.now();
      
      final docRef = await _firestore
          .collection(_flashsCollection)
          .add(flashData);
      
      await _createFlashAnalytics(docRef.id);
      return docRef.id;
    } catch (e) {
      print('Erreur createFlash: $e');
      throw Exception('Erreur lors de la création du flash');
    }
  }

  /// Mettre à jour un flash
  Future<void> updateFlash(String flashId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      
      await _firestore
          .collection(_flashsCollection)
          .doc(flashId)
          .update(updates);
    } catch (e) {
      print('Erreur updateFlash: $e');
      throw Exception('Erreur lors de la mise à jour du flash');
    }
  }

  /// ✅ MÉTHODES FAVORIS

  /// Toggle favori
  Future<bool> toggleFlashFavorite({required String userId, required String flashId}) async {
    try {
      final favoriteId = '${userId}_$flashId';
      final favoriteDoc = await _firestore
          .collection(_favoritesCollection)
          .doc(favoriteId)
          .get();

      if (favoriteDoc.exists) {
        await _firestore
            .collection(_favoritesCollection)
            .doc(favoriteId)
            .delete();
        await _decrementFlashSaves(flashId);
        return false;
      } else {
        await _firestore
            .collection(_favoritesCollection)
            .doc(favoriteId)
            .set({
          'userId': userId,
          'flashId': flashId,
          'addedAt': Timestamp.now(),
        });
        await _incrementFlashSaves(flashId);
        return true;
      }
    } catch (e) {
      print('Erreur toggleFlashFavorite: $e');
      throw Exception('Erreur lors de la gestion des favoris');
    }
  }

  /// ✅ MÉTHODES ANALYTICS

  /// Obtenir les statistiques d'un artiste
  Future<Map<String, dynamic>> getArtistStats(String artistId) async {
    try {
      final flashsSnapshot = await _firestore
          .collection(_flashsCollection)
          .where('tattooArtistId', isEqualTo: artistId)
          .get();

      final bookingsSnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('tattooArtistId', isEqualTo: artistId)
          .get();

      final totalFlashs = flashsSnapshot.docs.length;
      final totalBookings = bookingsSnapshot.docs.length;
      
      // ✅ Utilise .name pour comparer avec l'enum
      final completedBookings = bookingsSnapshot.docs
          .where((doc) => doc.data()['status'] == FlashBookingStatus.completed.name)
          .length;

      final totalViews = flashsSnapshot.docs.fold<int>(
        0, (sum, doc) => sum + ((doc.data()['views'] as int?) ?? 0)
      );

      final totalLikes = flashsSnapshot.docs.fold<int>(
        0, (sum, doc) => sum + ((doc.data()['likes'] as int?) ?? 0)
      );

      final totalSaves = flashsSnapshot.docs.fold<int>(
        0, (sum, doc) => sum + ((doc.data()['saves'] as int?) ?? 0)
      );

      return {
        'totalFlashs': totalFlashs,
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'successRate': totalBookings > 0 ? (completedBookings / totalBookings * 100) : 0.0,
        'totalViews': totalViews,
        'totalLikes': totalLikes,
        'totalSaves': totalSaves,
        'engagementRate': totalViews > 0 ? ((totalLikes + totalSaves) / totalViews * 100) : 0.0,
        'conversionRate': totalViews > 0 ? (totalBookings / totalViews * 100) : 0.0,
      };
    } catch (e) {
      print('Erreur getArtistStats: $e');
      return _getDefaultStats();
    }
  }

  /// ✅ MÉTHODES PRIVÉES UTILITAIRES

  Future<void> _incrementFlashViews(String flashId) async {
    try {
      await _firestore
          .collection(_flashsCollection)
          .doc(flashId)
          .update({'views': FieldValue.increment(1)});
    } catch (e) {
      print('Erreur _incrementFlashViews: $e');
    }
  }

  Future<void> _incrementFlashSaves(String flashId) async {
    try {
      await _firestore
          .collection(_flashsCollection)
          .doc(flashId)
          .update({'saves': FieldValue.increment(1)});
    } catch (e) {
      print('Erreur _incrementFlashSaves: $e');
    }
  }

  Future<void> _decrementFlashSaves(String flashId) async {
    try {
      await _firestore
          .collection(_flashsCollection)
          .doc(flashId)
          .update({'saves': FieldValue.increment(-1)});
    } catch (e) {
      print('Erreur _decrementFlashSaves: $e');
    }
  }

  Future<void> _incrementFlashBookingRequests(String flashId) async {
    try {
      await _firestore
          .collection(_flashsCollection)
          .doc(flashId)
          .update({'bookingRequests': FieldValue.increment(1)});
    } catch (e) {
      print('Erreur _incrementFlashBookingRequests: $e');
    }
  }

  Future<void> _createFlashAnalytics(String flashId) async {
    try {
      await _firestore
          .collection(_analyticsCollection)
          .doc(flashId)
          .set({
        'flashId': flashId,
        'totalViews': 0,
        'totalLikes': 0,
        'totalSaves': 0,
        'totalBookingRequests': 0,
        'viewsByDay': {},
        'conversionRate': 0.0,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Erreur _createFlashAnalytics: $e');
    }
  }

  Map<String, dynamic> _getDefaultStats() {
    return {
      'totalFlashs': 0,
      'totalBookings': 0,
      'completedBookings': 0,
      'successRate': 0.0,
      'totalViews': 0,
      'totalLikes': 0,
      'totalSaves': 0,
      'engagementRate': 0.0,
      'conversionRate': 0.0,
    };
  }

  /// ✅ DONNÉES DÉMO CORRIGÉES

  List<Flash> _generateDemoFlashs() {
    final random = Random();
    final styles = ['Minimaliste', 'Géométrique', 'Réalisme', 'Japonais', 'Old School'];
    final bodyPlacements = ['Avant-bras', 'Épaule', 'Poignet', 'Cheville', 'Dos'];
    final cities = ['Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice'];
    
    return List.generate(10, (index) {
      final basePrice = 80.0 + (random.nextInt(200));
      
      return Flash(
        id: 'demo_flash_${index + 1}',
        title: _generateFlashTitle(index),
        description: _generateFlashDescription(index),
        imageUrl: 'https://picsum.photos/400/600?random=${index + 1}',
        additionalImages: [],
        tattooArtistId: 'demo_artist_${random.nextInt(5) + 1}',
        tattooArtistName: _generateArtistName(index),
        studioName: 'Studio ${_generateArtistName(index)}',
        style: styles[random.nextInt(styles.length)],
        size: '${random.nextInt(8) + 5}x${random.nextInt(6) + 4}cm',
        sizeDescription: 'Parfait pour ${bodyPlacements[random.nextInt(bodyPlacements.length)].toLowerCase()}',
        price: basePrice,
        discountedPrice: random.nextBool() ? basePrice * 0.8 : null,
        priceNote: random.nextBool() ? 'Offre limitée !' : null,
        bodyPlacements: [bodyPlacements[random.nextInt(bodyPlacements.length)]],
        colors: ['Noir'],
        tags: _generateTags(index),
        availableTimeSlots: _generateTimeSlots(),
        flashType: FlashType.standard,
        status: FlashStatus.published,
        isMinuteFlash: false,
        minuteFlashDeadline: null,
        urgencyReason: null,
        likes: random.nextInt(50),
        saves: random.nextInt(30),
        views: random.nextInt(200) + 50,
        bookingRequests: random.nextInt(10),
        isVerified: random.nextBool(),
        isOriginalWork: true,
        qualityScore: 4.0 + random.nextDouble(),
        latitude: 48.8566 + (random.nextDouble() - 0.5) * 0.1,
        longitude: 2.3522 + (random.nextDouble() - 0.5) * 0.1,
        city: cities[random.nextInt(cities.length)],
        country: 'France',
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        updatedAt: DateTime.now().subtract(Duration(hours: random.nextInt(24))),
      );
    });
  }

  List<FlashBooking> _generateDemoBookings(String userId) {
    final random = Random();
    final now = DateTime.now();
    
    return List.generate(5, (index) {
      final isClient = userId.startsWith('client_') || userId.length > 10;
      final flashPrice = 120.0 + (random.nextInt(100));
      final status = FlashBookingStatus.values[random.nextInt(FlashBookingStatus.values.length)];
      
      return FlashBooking(
        id: 'demo_booking_${index + 1}',
        flashId: 'demo_flash_${index + 1}',
        clientId: isClient ? userId : 'demo_client_${index + 1}',
        tattooArtistId: isClient ? 'demo_artist_${index + 1}' : userId,
        requestedDate: now.add(Duration(days: random.nextInt(14) + 1)),
        timeSlot: '${9 + random.nextInt(8)}:00',
        status: status,
        totalPrice: flashPrice,
        depositAmount: flashPrice * 0.3,
        clientNotes: _generateClientNotes(index),
        clientPhone: '+33 6 ${random.nextInt(90) + 10} ${random.nextInt(90) + 10} ${random.nextInt(90) + 10} ${random.nextInt(90) + 10}',
        artistNotes: status == FlashBookingStatus.confirmed ? 'RDV confirmé' : null,
        rejectionReason: status == FlashBookingStatus.rejected ? 'Planning complet' : null,
        paymentIntentId: 'pi_demo_${index}_${random.nextInt(9999)}',
        createdAt: now.subtract(Duration(days: random.nextInt(5))),
        updatedAt: now.subtract(Duration(hours: random.nextInt(24))),
      );
    });
  }

  String _generateFlashTitle(int index) {
    final titles = [
      'Rose Géométrique', 'Dragon Minimaliste', 'Mandala Sacré', 'Lune Mystique',
      'Fleur de Lotus', 'Géométrie Sacrée', 'Phoenix Renaissance', 'Constellation',
      'Arbre de Vie', 'Papillon Aquarelle'
    ];
    return titles[index % titles.length];
  }

  String _generateFlashDescription(int index) {
    final descriptions = [
      'Design élégant aux lignes épurées',
      'Motif puissant symbolisant la renaissance',
      'Création unique mêlant spiritualité et esthétisme',
      'Tatouage délicat aux détails fins',
      'Design coloré apportant fraîcheur',
      'Motif géométrique complexe',
      'Symbole de force et de renouveau',
      'Constellation personnalisée',
      'Représentation de la croissance',
      'Technique aquarelle unique'
    ];
    return descriptions[index % descriptions.length];
  }

  String _generateArtistName(int index) {
    final names = [
      'Sophie Martinez', 'Alex Dubois', 'Marie Laurent', 'Thomas Moreau',
      'Emma Lefebvre', 'Lucas Roux', 'Léa Bernard', 'Nathan Petit',
      'Chloé Durand', 'Maxime Leroy'
    ];
    return names[index % names.length];
  }

  List<String> _generateTags(int index) {
    final allTags = ['Rose', 'Fleur', 'Géométrique', 'Minimaliste', 'Dragon', 'Mandala'];
    final random = Random(index);
    final numTags = random.nextInt(3) + 2;
    final tags = <String>[];
    
    for (int i = 0; i < numTags; i++) {
      final tag = allTags[random.nextInt(allTags.length)];
      if (!tags.contains(tag)) {
        tags.add(tag);
      }
    }
    
    return tags;
  }

  List<DateTime> _generateTimeSlots() {
    final slots = <DateTime>[];
    final now = DateTime.now();
    final random = Random();
    
    for (int day = 1; day <= 14; day++) {
      if (random.nextBool()) {
        final date = now.add(Duration(days: day));
        final hour = 9 + random.nextInt(9);
        slots.add(DateTime(date.year, date.month, date.day, hour, 0));
      }
    }
    
    return slots;
  }

  String _generateClientNotes(int index) {
    final notes = [
      'Premier tatouage, un peu stressé mais motivé !',
      'J\'aimerais adapter légèrement la taille',
      'Très flexible sur les horaires',
      'Ce design correspond exactement à mes attentes',
      'Pouvez-vous me conseiller sur les soins ?',
    ];
    return notes[index % notes.length];
  }
}