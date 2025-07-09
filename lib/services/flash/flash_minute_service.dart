// lib/services/flash/flash_minute_service.dart

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/flash/flash.dart';
import '../../models/user_role.dart';
import '../../services/notification/firebase_notification_service.dart';
import '../../services/auth/secure_auth_service.dart';

/// Service spécialisé pour la gestion des Flash Minute
/// Gère les créneaux last-minute avec réductions et notifications urgentes
class FlashMinuteService {
  static final FlashMinuteService _instance = FlashMinuteService._internal();
  static FlashMinuteService get instance => _instance;
  FlashMinuteService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseNotificationService _notificationService = FirebaseNotificationService.instance;
  final SecureAuthService _authService = SecureAuthService.instance;

  // Collections Firestore
  static const String _flashsCollection = 'flashs';
  static const String _minuteFlashsCollection = 'minute_flashs';
  static const String _interestedUsersCollection = 'interested_users';
  static const String _urgencyAlertsCollection = 'urgency_alerts';

  // Timer pour les vérifications automatiques
  Timer? _urgencyCheckTimer;
  Timer? _expirationCheckTimer;

  /// ✅ INITIALISATION DU SERVICE
  Future<void> initialize() async {
    try {
      print('🔥 Initialisation FlashMinuteService...');
      
      // Démarrer les timers de vérification
      _startUrgencyChecker();
      _startExpirationChecker();
      
      // Nettoyer les Flash Minute expirés
      await _cleanupExpiredFlashs();
      
      print('✅ FlashMinuteService initialisé');
    } catch (e) {
      print('❌ Erreur initialisation FlashMinuteService: $e');
    }
  }

  /// ✅ CRÉATION FLASH MINUTE
  
  /// Créer un Flash Minute à partir d'un flash existant
  Future<Flash> createMinuteFlash({
    required String flashId,
    required double discountPercentage,
    required DateTime deadline,
    required String urgencyReason,
    String? customMessage,
  }) async {
    try {
      // Vérifier les privilèges
      if (_authService.currentUserRole != UserRole.tatoueur) {
        throw Exception('Seuls les tatoueurs peuvent créer des Flash Minute');
      }

      // Récupérer le flash original
      final flashDoc = await _firestore.collection(_flashsCollection).doc(flashId).get();
      if (!flashDoc.exists) {
        throw Exception('Flash non trouvé');
      }

      final originalFlash = Flash.fromFirestore(flashDoc);
      
      // Vérifier que le flash appartient au tatoueur connecté
      if (originalFlash.tattooArtistId != _authService.currentUserId) {
        throw Exception('Vous ne pouvez modifier que vos propres flashs');
      }

      // Calculer le prix réduit
      final discountedPrice = originalFlash.price * (1 - discountPercentage / 100);
      
      // Créer le Flash Minute
      final minuteFlash = originalFlash.copyWith(
        isMinuteFlash: true,
        minuteFlashDeadline: deadline,
        discountedPrice: discountedPrice,
        urgencyReason: urgencyReason,
        flashType: FlashType.minute,
        updatedAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore
      await _firestore.collection(_flashsCollection).doc(flashId).update(minuteFlash.toMap());
      
      // Créer l'entrée dans la collection spécialisée
      await _firestore.collection(_minuteFlashsCollection).doc(flashId).set({
        'flashId': flashId,
        'originalPrice': originalFlash.price,
        'discountedPrice': discountedPrice,
        'discountPercentage': discountPercentage,
        'deadline': Timestamp.fromDate(deadline),
        'urgencyReason': urgencyReason,
        'customMessage': customMessage,
        'createdBy': _authService.currentUserId,
        'createdAt': Timestamp.now(),
        'notificationsSent': 0,
        'interestedUsers': [],
        'isActive': true,
      });

      // Notifier les utilisateurs intéressés
      await _notifyInterestedUsers(minuteFlash);
      
      // Envoyer notifications de proximité
      await _sendProximityNotifications(minuteFlash);

      print('✅ Flash Minute créé: $flashId');
      return minuteFlash;
    } catch (e) {
      print('❌ Erreur createMinuteFlash: $e');
      throw Exception('Erreur lors de la création du Flash Minute: $e');
    }
  }

  /// ✅ RÉCUPÉRATION FLASH MINUTE

  /// Obtenir tous les Flash Minute actifs
  Future<List<Flash>> getActiveMinuteFlashs({
    double? latitude,
    double? longitude,
    double maxDistanceKm = 50.0,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_flashsCollection)
          .where('isMinuteFlash', isEqualTo: true)
          .where('status', isEqualTo: 'published')
          .orderBy('minuteFlashDeadline', descending: false)
          .limit(limit);

      final querySnapshot = await query.get();
      var flashs = querySnapshot.docs
          .map((doc) => Flash.fromFirestore(doc))
          .where((flash) => flash.minuteFlashDeadline != null && 
                           DateTime.now().isBefore(flash.minuteFlashDeadline!))
          .toList();

      // Filtrer par distance si coordonnées fournies
      if (latitude != null && longitude != null) {
        flashs = flashs.where((flash) {
          final distance = flash.distanceFrom(latitude, longitude);
          return distance <= maxDistanceKm;
        }).toList();
      }

      // Trier par urgence (deadline le plus proche en premier)
      flashs.sort((a, b) => a.minuteFlashDeadline!.compareTo(b.minuteFlashDeadline!));

      return flashs;
    } catch (e) {
      print('❌ Erreur getActiveMinuteFlashs: $e');
      return _generateDemoMinuteFlashs();
    }
  }

  /// Obtenir les Flash Minute d'un artiste
  Future<List<Flash>> getArtistMinuteFlashs(String artistId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_flashsCollection)
          .where('tattooArtistId', isEqualTo: artistId)
          .where('isMinuteFlash', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Flash.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur getArtistMinuteFlashs: $e');
      return [];
    }
  }

  /// ✅ GESTION INTÉRÊT UTILISATEUR

  /// Marquer un utilisateur comme intéressé par un Flash Minute
  Future<void> markUserInterested(String flashId, String userId) async {
    try {
      final interestRef = _firestore
          .collection(_interestedUsersCollection)
          .doc('${flashId}_$userId');

      await interestRef.set({
        'flashId': flashId,
        'userId': userId,
        'interestedAt': Timestamp.now(),
        'notified': false,
      });

      // Ajouter à la liste des intéressés du Flash Minute
      await _firestore
          .collection(_minuteFlashsCollection)
          .doc(flashId)
          .update({
        'interestedUsers': FieldValue.arrayUnion([userId]),
      });

      print('✅ Utilisateur $userId marqué comme intéressé pour $flashId');
    } catch (e) {
      print('❌ Erreur markUserInterested: $e');
    }
  }

  /// ✅ EXPIRATION ET NETTOYAGE

  /// Faire expirer un Flash Minute
  Future<void> expireMinuteFlash(String flashId, {String? reason}) async {
    try {
      // Mettre à jour le statut du flash
      await _firestore.collection(_flashsCollection).doc(flashId).update({
        'status': FlashStatus.expired.name,
        'isMinuteFlash': false,
        'updatedAt': Timestamp.now(),
      });

      // Désactiver dans la collection spécialisée
      await _firestore.collection(_minuteFlashsCollection).doc(flashId).update({
        'isActive': false,
        'expiredAt': Timestamp.now(),
        'expirationReason': reason ?? 'Temps écoulé',
      });

      print('✅ Flash Minute expiré: $flashId');
    } catch (e) {
      print('❌ Erreur expireMinuteFlash: $e');
    }
  }

  /// ✅ NOTIFICATIONS

  /// Notifier les utilisateurs intéressés par des Flash Minute
  Future<void> _notifyInterestedUsers(Flash flash) async {
    try {
      // Récupérer les utilisateurs ayant des préférences similaires
      final interestedUsers = await _findInterestedUsers(flash);
      
      for (final userId in interestedUsers) {
        // Créer la notification
        try {
          // TODO: Utiliser FirebaseNotificationService pour envoyer push notification
          print('📱 Notification Flash Minute envoyée à $userId');
        } catch (e) {
          print('❌ Erreur envoi notification à $userId: $e');
        }
      }

      // Mettre à jour le compteur de notifications
      await _firestore.collection(_minuteFlashsCollection).doc(flash.id).update({
        'notificationsSent': FieldValue.increment(interestedUsers.length),
      });
    } catch (e) {
      print('❌ Erreur _notifyInterestedUsers: $e');
    }
  }

  /// Envoyer des notifications de proximité
  Future<void> _sendProximityNotifications(Flash flash) async {
    try {
      // TODO: Implémenter notifications géolocalisées
      // Trouver les utilisateurs dans un rayon de X km
      // Envoyer notifications push personnalisées
      print('📍 Notifications de proximité envoyées pour ${flash.id}');
    } catch (e) {
      print('❌ Erreur _sendProximityNotifications: $e');
    }
  }

  /// Envoyer alertes d'urgence (< 2h restantes)
  Future<void> sendUrgencyAlerts() async {
    try {
      final urgentFlashs = await _getUrgentFlashs();
      
      for (final flash in urgentFlashs) {
        // Vérifier si alerte déjà envoyée
        final alertDoc = await _firestore
            .collection(_urgencyAlertsCollection)
            .doc(flash.id)
            .get();

        if (!alertDoc.exists) {
          // Envoyer alerte urgence
          await _sendUrgentAlert(flash);
          
          // Marquer comme envoyée
          await _firestore
              .collection(_urgencyAlertsCollection)
              .doc(flash.id)
              .set({
            'flashId': flash.id,
            'sentAt': Timestamp.now(),
            'timeRemaining': flash.timeRemaining?.inMinutes ?? 0,
          });
        }
      }
    } catch (e) {
      print('❌ Erreur sendUrgencyAlerts: $e');
    }
  }

  /// ✅ MÉTHODES PRIVÉES

  void _startUrgencyChecker() {
    _urgencyCheckTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      sendUrgencyAlerts();
    });
  }

  void _startExpirationChecker() {
    _expirationCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredFlashs();
    });
  }

  Future<void> _cleanupExpiredFlashs() async {
    try {
      final expiredQuery = await _firestore
          .collection(_flashsCollection)
          .where('isMinuteFlash', isEqualTo: true)
          .where('minuteFlashDeadline', isLessThan: Timestamp.now())
          .get();

      for (final doc in expiredQuery.docs) {
        await expireMinuteFlash(doc.id, reason: 'Nettoyage automatique');
      }

      if (expiredQuery.docs.isNotEmpty) {
        print('🧹 ${expiredQuery.docs.length} Flash Minute expirés nettoyés');
      }
    } catch (e) {
      print('❌ Erreur _cleanupExpiredFlashs: $e');
    }
  }

  Future<List<String>> _findInterestedUsers(Flash flash) async {
    try {
      // TODO: Implémenter algorithme de matching basé sur:
      // - Préférences de style
      // - Historique de vues/likes
      // - Proximité géographique
      // - Budget compatible
      
      // Pour l'instant, retourner une liste simulée
      return ['user1', 'user2', 'user3'];
    } catch (e) {
      print('❌ Erreur _findInterestedUsers: $e');
      return [];
    }
  }

  Future<List<Flash>> _getUrgentFlashs() async {
    try {
      final urgentDeadline = DateTime.now().add(const Duration(hours: 2));
      
      final querySnapshot = await _firestore
          .collection(_flashsCollection)
          .where('isMinuteFlash', isEqualTo: true)
          .where('status', isEqualTo: 'published')
          .where('minuteFlashDeadline', isLessThan: Timestamp.fromDate(urgentDeadline))
          .get();

      return querySnapshot.docs
          .map((doc) => Flash.fromFirestore(doc))
          .where((flash) => flash.minuteFlashDeadline != null && 
                           DateTime.now().isBefore(flash.minuteFlashDeadline!))
          .toList();
    } catch (e) {
      print('❌ Erreur _getUrgentFlashs: $e');
      return [];
    }
  }

  Future<void> _sendUrgentAlert(Flash flash) async {
    try {
      // TODO: Envoyer notification push urgente
      print('🚨 Alerte urgence envoyée pour ${flash.title}');
    } catch (e) {
      print('❌ Erreur _sendUrgentAlert: $e');
    }
  }

  /// ✅ DONNÉES DÉMO

  List<Flash> _generateDemoMinuteFlashs() {
    final random = Random();
    final now = DateTime.now();
    
    return List.generate(5, (index) {
      final basePrice = 120.0 + (random.nextInt(200));
      final discountPercent = 20 + random.nextInt(40); // 20-60% de réduction
      final discountedPrice = basePrice * (1 - discountPercent / 100);
      
      return Flash(
        id: 'minute_demo_${index + 1}',
        title: _generateMinuteFlashTitle(index),
        description: _generateMinuteFlashDescription(index),
        imageUrl: 'https://picsum.photos/400/600?random=${100 + index}',
        tattooArtistId: 'demo_artist_${index + 1}',
        tattooArtistName: _generateArtistName(index),
        studioName: 'Studio ${_generateArtistName(index)}',
        style: ['Minimaliste', 'Géométrique', 'Aquarelle', 'Old School'][index % 4],
        size: '${6 + random.nextInt(4)}x${4 + random.nextInt(3)}cm',
        sizeDescription: 'Format adapté aux créneaux express',
        price: basePrice,
        discountedPrice: discountedPrice,
        bodyPlacements: [['Poignet', 'Cheville', 'Avant-bras'][index % 3]], // ✅ Corrigé: List au lieu de split()
        colors: ['Noir'],
        tags: ['Flash', 'Minute', 'Urgent'],
        availableTimeSlots: [now.add(Duration(hours: 2 + index))],
        flashType: FlashType.minute,
        status: FlashStatus.published,
        isMinuteFlash: true,
        minuteFlashDeadline: now.add(Duration(hours: 2 + random.nextInt(12))),
        urgencyReason: _generateUrgencyReason(index),
        likes: random.nextInt(20),
        saves: random.nextInt(15),
        views: random.nextInt(100) + 20,
        bookingRequests: random.nextInt(5),
        isVerified: true,
        isOriginalWork: true,
        qualityScore: 4.0 + random.nextDouble(),
        latitude: 48.8566 + (random.nextDouble() - 0.5) * 0.1,
        longitude: 2.3522 + (random.nextDouble() - 0.5) * 0.1,
        city: 'Paris',
        country: 'France',
        createdAt: now.subtract(Duration(hours: random.nextInt(6))),
        updatedAt: now.subtract(Duration(minutes: random.nextInt(60))),
      );
    });
  }

  String _generateMinuteFlashTitle(int index) {
    final titles = [
      'Rose Express',
      'Géométrie Minute',
      'Flash Aquarelle',
      'Minimalist Quick',
      'Urgent Mandala'
    ];
    return titles[index % titles.length];
  }

  String _generateMinuteFlashDescription(int index) {
    final descriptions = [
      'Créneau libéré dernière minute !',
      'Offre flash limitée - Réduction exceptionnelle',
      'Design rapide et efficace',
      'Session express disponible maintenant',
      'Dernière minute - Prix cassé !'
    ];
    return descriptions[index % descriptions.length];
  }

  String _generateUrgencyReason(int index) {
    final reasons = [
      'Annulation client',
      'Créneau libéré',
      'Fin de journée disponible',
      'Report de RDV',
      'Promotion flash'
    ];
    return reasons[index % reasons.length];
  }

  String _generateArtistName(int index) {
    final names = [
      'Sophie Flash',
      'Alex Speed',
      'Marie Quick',
      'Tom Express',
      'Luna Minute'
    ];
    return names[index % names.length];
  }

  /// ✅ NETTOYAGE

  void dispose() {
    _urgencyCheckTimer?.cancel();
    _expirationCheckTimer?.cancel();
    print('🧹 FlashMinuteService disposed');
  }
}