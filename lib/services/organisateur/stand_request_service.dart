// lib/services/organisateur/stand_request_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class StandRequestService {
  static final StandRequestService _instance = StandRequestService._internal();
  factory StandRequestService() => _instance;
  StandRequestService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _standRequestsCollection => _firestore.collection('standRequests');
  CollectionReference get _negotiationsCollection => _firestore.collection('negotiations');

  /// Stream des demandes de stands pour un organisateur
  Stream<QuerySnapshot> getStandRequestsStream(String organizerId) {
    return _standRequestsCollection
        .where('convention.organizerId', isEqualTo: organizerId)
        .orderBy('status.createdAt', descending: true)
        .snapshots();
  }

  /// Stream des demandes par statut
  Stream<QuerySnapshot> getStandRequestsByStatusStream(String organizerId, String status) {
    return _standRequestsCollection
        .where('convention.organizerId', isEqualTo: organizerId)
        .where('status.current', isEqualTo: status)
        .orderBy('status.createdAt', descending: true)
        .snapshots();
  }

  /// Récupère une demande spécifique
  Future<DocumentSnapshot> getStandRequest(String requestId) {
    return _standRequestsCollection.doc(requestId).get();
  }

  /// Crée une nouvelle demande de stand (côté tatoueur)
  Future<String> createStandRequest(Map<String, dynamic> requestData) async {
    try {
      final docRef = await _standRequestsCollection.add({
        ...requestData,
        'status': {
          'current': 'pending',
          'history': [
            {
              'status': 'pending',
              'timestamp': FieldValue.serverTimestamp(),
              'note': 'Demande créée',
            }
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdate': FieldValue.serverTimestamp(),
        },
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la demande: $e');
    }
  }

  /// Met à jour le statut d'une demande
  Future<void> updateRequestStatus(String requestId, String newStatus, {String? note}) async {
    try {
      final currentDoc = await _standRequestsCollection.doc(requestId).get();
      if (!currentDoc.exists) {
        throw Exception('Demande non trouvée');
      }

      final currentData = currentDoc.data() as Map<String, dynamic>;
      final currentHistory = List<Map<String, dynamic>>.from(
        currentData['status']['history'] ?? []
      );

      currentHistory.add({
        'status': newStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'note': note ?? 'Statut mis à jour',
      });

      await _standRequestsCollection.doc(requestId).update({
        'status.current': newStatus,
        'status.history': currentHistory,
        'status.lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  /// Accepte une demande de stand
  Future<void> acceptStandRequest(String requestId, {Map<String, dynamic>? finalTerms}) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final requestRef = _standRequestsCollection.doc(requestId);
        final requestDoc = await transaction.get(requestRef);
        
        if (!requestDoc.exists) {
          throw Exception('Demande non trouvée');
        }

        final requestData = requestDoc.data() as Map<String, dynamic>;
        final currentHistory = List<Map<String, dynamic>>.from(
          requestData['status']['history'] ?? []
        );

        currentHistory.add({
          'status': 'accepted',
          'timestamp': FieldValue.serverTimestamp(),
          'note': 'Demande acceptée par l\'organisateur',
        });

        Map<String, dynamic> updateData = {
          'status.current': 'accepted',
          'status.history': currentHistory,
          'status.lastUpdate': FieldValue.serverTimestamp(),
        };

        if (finalTerms != null) {
          updateData['finalTerms'] = finalTerms;
        }

        transaction.update(requestRef, updateData);
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'acceptation: $e');
    }
  }

  /// Refuse une demande de stand
  Future<void> rejectStandRequest(String requestId, String reason) async {
    try {
      final currentDoc = await _standRequestsCollection.doc(requestId).get();
      if (!currentDoc.exists) {
        throw Exception('Demande non trouvée');
      }

      final currentData = currentDoc.data() as Map<String, dynamic>;
      final currentHistory = List<Map<String, dynamic>>.from(
        currentData['status']['history'] ?? []
      );

      currentHistory.add({
        'status': 'rejected',
        'timestamp': FieldValue.serverTimestamp(),
        'note': 'Refusée: $reason',
      });

      await _standRequestsCollection.doc(requestId).update({
        'status.current': 'rejected',
        'status.history': currentHistory,
        'status.lastUpdate': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });
    } catch (e) {
      throw Exception('Erreur lors du refus: $e');
    }
  }

  /// Démarre une négociation
  Future<String> startNegotiation(String requestId, String organizerId, String tattooeId) async {
    try {
      // Mettre à jour le statut de la demande
      await updateRequestStatus(requestId, 'negotiating', note: 'Négociation démarrée');

      // Créer une négociation
      final negotiationRef = await _negotiationsCollection.add({
        'participants': {
          'organizerId': organizerId,
          'tattooeId': tattooeId,
        },
        'standRequest': {
          'requestId': requestId,
        },
        'messages': [],
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return negotiationRef.id;
    } catch (e) {
      throw Exception('Erreur lors du démarrage de la négociation: $e');
    }
  }

  /// Ajoute un message à une négociation
  Future<void> addNegotiationMessage(String negotiationId, String fromUserId, String message, {String type = 'text'}) async {
    try {
      await _negotiationsCollection.doc(negotiationId).update({
        'messages': FieldValue.arrayUnion([
          {
            'from': fromUserId,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'type': type,
          }
        ]),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  /// Finalise une négociation
  Future<void> finalizeNegotiation(String negotiationId, String requestId, Map<String, dynamic> agreedTerms) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Mettre à jour la négociation
        final negotiationRef = _negotiationsCollection.doc(negotiationId);
        transaction.update(negotiationRef, {
          'status': 'completed',
          'terms': agreedTerms,
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Mettre à jour la demande
        final requestRef = _standRequestsCollection.doc(requestId);
        transaction.update(requestRef, {
          'status.current': 'accepted',
          'finalTerms': agreedTerms,
          'negotiationId': negotiationId,
        });
      });
    } catch (e) {
      throw Exception('Erreur lors de la finalisation: $e');
    }
  }

  /// Stream d'une négociation spécifique
  Stream<DocumentSnapshot> getNegotiationStream(String negotiationId) {
    return _negotiationsCollection.doc(negotiationId).snapshots();
  }

  /// Confirme le paiement d'une demande
  Future<void> confirmPayment(String requestId, Map<String, dynamic> paymentInfo) async {
    try {
      await _standRequestsCollection.doc(requestId).update({
        'status.current': 'paid',
        'payment': {
          ...paymentInfo,
          'confirmedAt': FieldValue.serverTimestamp(),
        },
        'status.lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la confirmation du paiement: $e');
    }
  }

  /// Récupère les demandes nécessitant une action
  Future<QuerySnapshot> getPendingActionsRequests(String organizerId) async {
    try {
      return await _standRequestsCollection
          .where('convention.organizerId', isEqualTo: organizerId)
          .where('status.current', whereIn: ['pending', 'negotiating'])
          .orderBy('status.createdAt', descending: true)
          .get();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des actions en attente: $e');
    }
  }

  /// Statistiques des demandes pour un organisateur
  Future<Map<String, int>> getRequestsStats(String organizerId) async {
    try {
      final snapshot = await _standRequestsCollection
          .where('convention.organizerId', isEqualTo: organizerId)
          .get();

      final stats = <String, int>{
        'total': snapshot.docs.length,
        'pending': 0,
        'negotiating': 0,
        'accepted': 0,
        'rejected': 0,
        'paid': 0,
        'cancelled': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status']['current'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  /// Recherche de demandes par nom de tatoueur
  Future<QuerySnapshot> searchRequestsByTattooer(String organizerId, String tattooerName) async {
    try {
      return await _standRequestsCollection
          .where('convention.organizerId', isEqualTo: organizerId)
          .where('requester.name', isGreaterThanOrEqualTo: tattooerName)
          .where('requester.name', isLessThanOrEqualTo: '$tattooerName\uf8ff')
          .limit(20)
          .get();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Annule une demande (côté tatoueur)
  Future<void> cancelStandRequest(String requestId, String reason) async {
    try {
      await updateRequestStatus(requestId, 'cancelled', note: 'Annulée par le tatoueur: $reason');
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  /// Met à jour les informations de paiement fractionné
  Future<void> updateInstallmentPayment(String requestId, int installmentIndex, String status) async {
    try {
      await _standRequestsCollection.doc(requestId).update({
        'payment.installments.$installmentIndex.status': status,
        'payment.installments.$installmentIndex.paidAt': status == 'completed' 
            ? FieldValue.serverTimestamp() 
            : null,
        'status.lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du paiement: $e');
    }
  }

  /// Vérifie si tous les paiements sont complétés
  Future<bool> areAllInstallmentsPaid(String requestId) async {
    try {
      final doc = await _standRequestsCollection.doc(requestId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final installments = data['payment']?['installments'] as List?;
      
      if (installments == null || installments.isEmpty) return false;

      return installments.every((installment) => installment['status'] == 'completed');
    } catch (e) {
      return false;
    }
  }

  /// Envoie un rappel de paiement
  Future<void> sendPaymentReminder(String requestId) async {
    try {
      await _standRequestsCollection.doc(requestId).update({
        'payment.lastReminderSent': FieldValue.serverTimestamp(),
        'payment.reminderCount': FieldValue.increment(1),
      });
      
      // TODO: Implémenter l'envoi d'email/notification
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du rappel: $e');
    }
  }

  /// Récupère les demandes avec paiements en retard
  Future<QuerySnapshot> getOverduePayments(String organizerId) async {
    try {
      final now = Timestamp.now();
      return await _standRequestsCollection
          .where('convention.organizerId', isEqualTo: organizerId)
          .where('status.current', isEqualTo: 'accepted')
          .where('payment.dueDate', isLessThan: now)
          .get();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des retards: $e');
    }
  }

  /// Supprime une demande (GDPR)
  Future<void> deleteStandRequest(String requestId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Supprimer la demande
        transaction.delete(_standRequestsCollection.doc(requestId));
        
        // Supprimer les négociations liées
        final negotiations = await _negotiationsCollection
            .where('standRequest.requestId', isEqualTo: requestId)
            .get();
        
        for (final negotiation in negotiations.docs) {
          transaction.delete(negotiation.reference);
        }
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}