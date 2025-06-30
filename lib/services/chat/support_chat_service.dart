// 3️⃣ SUPPORT CLIENT KIPIK (nouveau)
// lib/services/chat/support_chat_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/models/support_ticket.dart';
import 'package:kipik_v5/models/chat_message.dart';

class SupportChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer un nouveau ticket de support
  Future<String> createSupportTicket({
    required String userId,
    required String subject,
    required String category, // 'bug', 'question', 'suggestion', 'payment', 'account'
    required String initialMessage,
    String? attachmentUrl,
  }) async {
    final ticket = SupportTicket(
      id: '', // Firestore va générer l'ID
      userId: userId,
      subject: subject,
      category: category,
      status: 'open', // 'open', 'in_progress', 'waiting_customer', 'resolved', 'closed'
      priority: _determinePriority(category),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      assignedToAgent: null,
    );

    final docRef = await _firestore.collection('support_tickets').add(ticket.toFirestore());
    
    // Ajouter le premier message
    final firstMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: initialMessage,
      imageUrl: attachmentUrl,
      senderId: userId,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('support_tickets')
        .doc(docRef.id)
        .collection('messages')
        .doc(firstMessage.id)
        .set(firstMessage.toFirestore());

    return docRef.id;
  }

  /// Stream des messages d'un ticket de support
  Stream<List<ChatMessage>> supportMessagesStream(String ticketId) {
    return _firestore
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Envoyer un message dans un ticket de support
  Future<void> sendSupportMessage({
    required String ticketId,
    required ChatMessage message,
  }) async {
    await _firestore
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .doc(message.id)
        .set(message.toFirestore());

    // Mettre à jour le ticket
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'updatedAt': FieldValue.serverTimestamp(),
      'status': message.senderId.startsWith('agent_') ? 'waiting_customer' : 'in_progress',
    });
  }

  /// Lister les tickets de support d'un utilisateur
  Stream<List<SupportTicket>> userTicketsStream(String userId) {
    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicket.fromFirestore(doc))
            .toList());
  }

  /// Fermer un ticket de support
  Future<void> closeTicket(String ticketId) async {
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Déterminer la priorité selon la catégorie
  String _determinePriority(String category) {
    switch (category) {
      case 'payment':
      case 'account':
        return 'high';
      case 'bug':
        return 'medium';
      case 'question':
      case 'suggestion':
      default:
        return 'low';
    }
  }
}
