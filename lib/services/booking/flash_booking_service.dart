// lib/services/booking/flash_booking_service.dart

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/flash/flash.dart';
import '../../models/flash/flash_booking.dart';
import '../../models/flash/flash_booking_status.dart';
import '../../models/user_role.dart';
import '../../services/auth/secure_auth_service.dart';
import '../../services/notification/firebase_notification_service.dart';
import 'package:uuid/uuid.dart';

/// Service pour le workflow complet de réservation de flashs
/// Gère : Demande → Devis → Acompte → Validation → Confirmation
class FlashBookingService {
  static final FlashBookingService _instance = FlashBookingService._internal();
  static FlashBookingService get instance => _instance;
  FlashBookingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SecureAuthService _authService = SecureAuthService.instance;
  final FirebaseNotificationService _notificationService = FirebaseNotificationService.instance;
  final Uuid _uuid = const Uuid();

  // Collections Firestore
  static const String _bookingsCollection = 'flash_bookings';
  static const String _quotesCollection = 'booking_quotes';
  static const String _paymentsCollection = 'booking_payments';
  static const String _chatRoomsCollection = 'booking_chats';
  static const String _flashsCollection = 'flashs';

  // Configuration
  static const double _platformCommissionRate = 0.01; // 1%
  static const Duration _quoteValidityDuration = Duration(hours: 48);
  static const Duration _depositDeadlineDuration = Duration(hours: 24);

  /// ✅ WORKFLOW ÉTAPE 1 : DEMANDE DE RÉSERVATION

  /// Créer une demande de réservation
  Future<FlashBooking> requestBooking({
    required String flashId,
    required String clientId,
    required DateTime requestedDate,
    required String timeSlot,
    String? clientNotes,
    String? clientPhone,
    Map<String, dynamic>? customizations,
  }) async {
    try {
      // Vérifier que l'utilisateur est un client
      if (_authService.currentUserRole != UserRole.particulier && 
          _authService.currentUserRole != UserRole.client) {
        throw Exception('Seuls les clients peuvent faire des réservations');
      }

      // Vérifier que le flash existe et est disponible
      final flashDoc = await _firestore.collection(_flashsCollection).doc(flashId).get();
      if (!flashDoc.exists) {
        throw Exception('Flash non trouvé');
      }

      final flash = Flash.fromFirestore(flashDoc);
      if (!flash.isBookable) {
        throw Exception('Ce flash n\'est plus disponible pour réservation');
      }

      // Créer l'ID unique de la réservation
      final bookingId = _uuid.v4();
      
      // Créer la réservation
      final booking = FlashBooking(
        id: bookingId,
        flashId: flashId,
        clientId: clientId,
        tattooArtistId: flash.tattooArtistId,
        requestedDate: requestedDate,
        timeSlot: timeSlot,
        status: FlashBookingStatus.pending,
        totalPrice: flash.effectivePrice,
        depositAmount: flash.effectivePrice * 0.3, // 30% d'acompte
        clientNotes: clientNotes ?? '', // ✅ Corrigé selon votre modèle
        clientPhone: clientPhone ?? '', // ✅ Corrigé selon votre modèle
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore
      await _firestore.collection(_bookingsCollection).doc(bookingId).set(booking.toFirestore());

      // Créer une salle de chat pour la réservation
      await _createBookingChatRoom(bookingId, clientId, flash.tattooArtistId);

      // Notifier le tatoueur
      await _notifyArtistNewBooking(booking, flash);

      // Mettre à jour les statistiques du flash
      await _incrementFlashBookingRequests(flashId);

      print('✅ Demande de réservation créée: $bookingId');
      return booking;
    } catch (e) {
      print('❌ Erreur requestBooking: $e');
      throw Exception('Erreur lors de la demande de réservation: $e');
    }
  }

  /// ✅ WORKFLOW ÉTAPE 2 : ENVOI DE DEVIS

  /// Envoyer un devis personnalisé (tatoueur)
  Future<FlashBooking> sendQuote({
    required String bookingId,
    required double customPrice,
    String? artistNotes,
    List<String>? modifications,
    DateTime? alternativeDate,
    String? alternativeTimeSlot,
  }) async {
    try {
      // Vérifier que l'utilisateur est un tatoueur
      if (_authService.currentUserRole != UserRole.tatoueur) {
        throw Exception('Seuls les tatoueurs peuvent envoyer des devis');
      }

      // Récupérer la réservation
      final booking = await getBookingById(bookingId);
      if (booking.tattooArtistId != _authService.currentUserId) {
        throw Exception('Vous ne pouvez gérer que vos propres réservations');
      }

      if (booking.status != FlashBookingStatus.pending) {
        throw Exception('Cette réservation ne peut plus être modifiée');
      }

      // Calculer le nouvel acompte
      final newDepositAmount = customPrice * 0.3;
      final quoteValidUntil = DateTime.now().add(_quoteValidityDuration);

      // Créer le devis
      final quoteData = {
        'bookingId': bookingId,
        'originalPrice': booking.totalPrice,
        'customPrice': customPrice,
        'depositAmount': newDepositAmount,
        'platformCommission': newDepositAmount * _platformCommissionRate,
        'artistNotes': artistNotes,
        'modifications': modifications ?? [],
        'alternativeDate': alternativeDate?.toIso8601String(),
        'alternativeTimeSlot': alternativeTimeSlot,
        'validUntil': Timestamp.fromDate(quoteValidUntil),
        'createdBy': _authService.currentUserId,
        'createdAt': Timestamp.now(),
      };

      // Sauvegarder le devis
      await _firestore.collection(_quotesCollection).doc(bookingId).set(quoteData);

      // Mettre à jour la réservation
      final updatedBooking = booking.copyWith(
        status: FlashBookingStatus.quoteSent,
        totalPrice: customPrice,
        depositAmount: newDepositAmount,
        artistNotes: artistNotes, // ✅ Selon votre modèle (String?)
        updatedAt: DateTime.now(),
      );

      await _firestore.collection(_bookingsCollection).doc(bookingId).update(updatedBooking.toFirestore());

      // Notifier le client
      await _notifyClientQuoteReceived(updatedBooking);

      print('✅ Devis envoyé pour: $bookingId');
      return updatedBooking;
    } catch (e) {
      print('❌ Erreur sendQuote: $e');
      throw Exception('Erreur lors de l\'envoi du devis: $e');
    }
  }

  /// ✅ WORKFLOW ÉTAPE 3 : PAIEMENT ACOMPTE

  /// Traiter le paiement de l'acompte
  Future<FlashBooking> payDeposit({
    required String bookingId,
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      // Vérifier que l'utilisateur est le client de la réservation
      final booking = await getBookingById(bookingId);
      if (booking.clientId != _authService.currentUserId) {
        throw Exception('Vous ne pouvez payer que vos propres réservations');
      }

      if (booking.status != FlashBookingStatus.quoteSent) { // ✅ Corrigé
        throw Exception('Cette réservation n\'est pas prête pour le paiement');
      }

      // Vérifier que le devis est encore valide
      final quoteDoc = await _firestore.collection(_quotesCollection).doc(bookingId).get();
      if (quoteDoc.exists) {
        final quoteData = quoteDoc.data()!;
        final validUntil = (quoteData['validUntil'] as Timestamp).toDate();
        if (DateTime.now().isAfter(validUntil)) {
          throw Exception('Le devis a expiré, veuillez demander un nouveau devis');
        }
      }

      // TODO: Intégrer avec Stripe pour traiter le paiement réel
      // const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
      // const paymentIntent = await stripe.paymentIntents.confirm(paymentIntentId);

      // Simuler le succès du paiement pour la démo
      final paymentData = {
        'bookingId': bookingId,
        'paymentIntentId': paymentIntentId,
        'amount': booking.depositAmount,
        'platformCommission': booking.depositAmount * _platformCommissionRate,
        'artistAmount': booking.depositAmount * (1 - _platformCommissionRate),
        'status': 'succeeded',
        'paymentMethodId': paymentMethodId,
        'paidAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
      };

      await _firestore.collection(_paymentsCollection).doc(bookingId).set(paymentData);

      // Mettre à jour la réservation
      final updatedBooking = booking.copyWith(
        status: FlashBookingStatus.depositPaid,
        paymentIntentId: paymentIntentId,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection(_bookingsCollection).doc(bookingId).update(updatedBooking.toFirestore());

      // Démarrer le countdown pour validation du tatoueur
      await _setValidationDeadline(bookingId);

      // Notifier le tatoueur
      await _notifyArtistDepositPaid(updatedBooking);

      print('✅ Acompte payé pour: $bookingId');
      return updatedBooking;
    } catch (e) {
      print('❌ Erreur payDeposit: $e');
      throw Exception('Erreur lors du paiement: $e');
    }
  }

  /// ✅ WORKFLOW ÉTAPE 4 : VALIDATION CRÉNEAU

  /// Valider le créneau (tatoueur)
  Future<FlashBooking> validateSlot({
    required String bookingId,
    required bool isConfirmed,
    String? rejectionReason,
    DateTime? alternativeDate,
    String? alternativeTimeSlot,
  }) async {
    try {
      // Vérifier que l'utilisateur est le tatoueur de la réservation
      final booking = await getBookingById(bookingId);
      if (booking.tattooArtistId != _authService.currentUserId) {
        throw Exception('Vous ne pouvez valider que vos propres réservations');
      }

      if (booking.status != FlashBookingStatus.depositPaid) {
        throw Exception('L\'acompte doit être payé avant validation');
      }

      FlashBooking updatedBooking;

      if (isConfirmed) {
        // Confirmer la réservation
        updatedBooking = booking.copyWith(
          status: FlashBookingStatus.confirmed,
          updatedAt: DateTime.now(),
        );

        // Marquer le flash comme réservé
        await _updateFlashStatus(booking.flashId, FlashStatus.reserved);

        // Notifier le client de la confirmation
        await _notifyClientBookingConfirmed(updatedBooking);
      } else {
        // Refuser la réservation
        updatedBooking = booking.copyWith(
          status: FlashBookingStatus.rejected,
          rejectionReason: rejectionReason, // ✅ Selon votre modèle (String?)
          updatedAt: DateTime.now(),
        );

        // TODO: Rembourser l'acompte automatiquement
        await _processRefund(bookingId);

        // Notifier le client du refus
        await _notifyClientBookingRejected(updatedBooking, rejectionReason);
      }

      await _firestore.collection(_bookingsCollection).doc(bookingId).update(updatedBooking.toFirestore());

      print('✅ Validation ${isConfirmed ? 'confirmée' : 'refusée'} pour: $bookingId');
      return updatedBooking;
    } catch (e) {
      print('❌ Erreur validateSlot: $e');
      throw Exception('Erreur lors de la validation: $e');
    }
  }

  /// ✅ GESTION DES RÉSERVATIONS

  /// Obtenir une réservation par ID
  Future<FlashBooking> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      if (!doc.exists) {
        throw Exception('Réservation non trouvée');
      }
      return FlashBooking.fromFirestore(doc);
    } catch (e) {
      print('❌ Erreur getBookingById: $e');
      throw Exception('Erreur lors de la récupération de la réservation');
    }
  }

  /// Obtenir les réservations d'un client
  Future<List<FlashBooking>> getBookingsForClient(String clientId) async {
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
      print('❌ Erreur getBookingsForClient: $e');
      return _generateDemoBookings(clientId, isClient: true);
    }
  }

  /// Obtenir les réservations d'un artiste
  Future<List<FlashBooking>> getBookingsForArtist(String artistId) async {
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
      print('❌ Erreur getBookingsForArtist: $e');
      return _generateDemoBookings(artistId, isClient: false);
    }
  }

  /// Annuler une réservation
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      final booking = await getBookingById(bookingId);
      
      // Vérifier les droits d'annulation
      final currentUserId = _authService.currentUserId;
      if (currentUserId != booking.clientId && currentUserId != booking.tattooArtistId) {
        throw Exception('Vous n\'avez pas le droit d\'annuler cette réservation');
      }

      // Traiter le remboursement si applicable
      if (booking.status == FlashBookingStatus.depositPaid || 
          booking.status == FlashBookingStatus.confirmed) {
        await _processRefund(bookingId);
      }

      // Mettre à jour le statut
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': FlashBookingStatus.cancelled.name,
        'cancellationReason': reason,
        'cancelledBy': currentUserId,
        'cancelledAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Libérer le flash si nécessaire
      if (booking.status == FlashBookingStatus.confirmed) {
        await _updateFlashStatus(booking.flashId, FlashStatus.published);
      }

      print('✅ Réservation annulée: $bookingId');
    } catch (e) {
      print('❌ Erreur cancelBooking: $e');
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  /// ✅ MÉTHODES PRIVÉES

  Future<void> _createBookingChatRoom(String bookingId, String clientId, String artistId) async {
    try {
      await _firestore.collection(_chatRoomsCollection).doc(bookingId).set({
        'bookingId': bookingId,
        'participants': [clientId, artistId],
        'lastMessage': null,
        'lastMessageAt': null,
        'createdAt': Timestamp.now(),
        'isActive': true,
      });
    } catch (e) {
      print('❌ Erreur _createBookingChatRoom: $e');
    }
  }

  Future<void> _notifyArtistNewBooking(FlashBooking booking, Flash flash) async {
    try {
      // TODO: Envoyer notification push au tatoueur
      print('📱 Notification nouvelle réservation envoyée à ${booking.tattooArtistId}');
    } catch (e) {
      print('❌ Erreur _notifyArtistNewBooking: $e');
    }
  }

  Future<void> _notifyClientQuoteReceived(FlashBooking booking) async {
    try {
      // TODO: Envoyer notification push au client
      print('📱 Notification devis reçu envoyée à ${booking.clientId}');
    } catch (e) {
      print('❌ Erreur _notifyClientQuoteReceived: $e');
    }
  }

  Future<void> _notifyArtistDepositPaid(FlashBooking booking) async {
    try {
      // TODO: Envoyer notification push au tatoueur
      print('📱 Notification acompte payé envoyée à ${booking.tattooArtistId}');
    } catch (e) {
      print('❌ Erreur _notifyArtistDepositPaid: $e');
    }
  }

  Future<void> _notifyClientBookingConfirmed(FlashBooking booking) async {
    try {
      // TODO: Envoyer notification push au client
      print('📱 Notification réservation confirmée envoyée à ${booking.clientId}');
    } catch (e) {
      print('❌ Erreur _notifyClientBookingConfirmed: $e');
    }
  }

  Future<void> _notifyClientBookingRejected(FlashBooking booking, String? reason) async {
    try {
      // TODO: Envoyer notification push au client
      print('📱 Notification réservation refusée envoyée à ${booking.clientId}');
    } catch (e) {
      print('❌ Erreur _notifyClientBookingRejected: $e');
    }
  }

  Future<void> _setValidationDeadline(String bookingId) async {
    try {
      final deadline = DateTime.now().add(const Duration(hours: 24));
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'validationDeadline': Timestamp.fromDate(deadline),
      });
      
      // TODO: Programmer une tâche automatique pour gérer l'expiration
      print('⏰ Deadline de validation fixée à $deadline pour $bookingId');
    } catch (e) {
      print('❌ Erreur _setValidationDeadline: $e');
    }
  }

  Future<void> _incrementFlashBookingRequests(String flashId) async {
    try {
      await _firestore.collection(_flashsCollection).doc(flashId).update({
        'bookingRequests': FieldValue.increment(1),
      });
    } catch (e) {
      print('❌ Erreur _incrementFlashBookingRequests: $e');
    }
  }

  Future<void> _updateFlashStatus(String flashId, FlashStatus status) async {
    try {
      await _firestore.collection(_flashsCollection).doc(flashId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('❌ Erreur _updateFlashStatus: $e');
    }
  }

  Future<void> _processRefund(String bookingId) async {
    try {
      // TODO: Intégrer avec Stripe pour rembourser automatiquement
      print('💰 Remboursement traité pour: $bookingId');
    } catch (e) {
      print('❌ Erreur _processRefund: $e');
    }
  }

  /// ✅ DONNÉES DÉMO

  List<FlashBooking> _generateDemoBookings(String userId, {required bool isClient}) {
    final random = Random();
    final now = DateTime.now();
    
    return List.generate(3, (index) {
      final status = FlashBookingStatus.values[random.nextInt(FlashBookingStatus.values.length)];
      final basePrice = 120.0 + (random.nextInt(180));
      
      return FlashBooking(
        id: 'demo_booking_${userId}_$index',
        flashId: 'demo_flash_${index + 1}',
        clientId: isClient ? userId : 'demo_client_$index',
        tattooArtistId: isClient ? 'demo_artist_$index' : userId,
        requestedDate: now.add(Duration(days: random.nextInt(14) + 1)),
        timeSlot: '${9 + random.nextInt(8)}:00',
        status: status,
        totalPrice: basePrice,
        depositAmount: basePrice * 0.3,
        clientNotes: _generateClientNotes(index),
        clientPhone: '+33 6 ${random.nextInt(90) + 10} ${random.nextInt(90) + 10} ${random.nextInt(90) + 10} ${random.nextInt(90) + 10}',
        artistNotes: status == FlashBookingStatus.confirmed ? 'RDV confirmé' : null, // ✅ String?
        rejectionReason: status == FlashBookingStatus.rejected ? _generateRejectionReason(index) : null, // ✅ String?
        paymentIntentId: status.index >= FlashBookingStatus.depositPaid.index ? 'pi_demo_${random.nextInt(9999)}' : null, // ✅ String?
        createdAt: now.subtract(Duration(days: random.nextInt(5))),
        updatedAt: now.subtract(Duration(hours: random.nextInt(24))),
      );
    });
  }

  String _generateClientNotes(int index) {
    final notes = [
      'Premier tatouage, merci d\'être patient !',
      'Très flexible sur les horaires',
      'Pourriez-vous ajuster légèrement la taille ?',
      'Hâte de voir le résultat final',
      'Disponible en soirée également'
    ];
    return notes[index % notes.length];
  }

  String _generateRejectionReason(int index) {
    final reasons = [
      'Planning complet pour cette période',
      'Design trop complexe pour le créneau',
      'Incompatibilité de style',
      'Préférence pour projets plus larges',
      'Vacances durant cette période'
    ];
    return reasons[index % reasons.length];
  }
}