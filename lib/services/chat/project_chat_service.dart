// lib/services/chat/project_chat_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/models/chat_message.dart';
import 'chat_repository.dart';

class ProjectChatService implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<ChatMessage>> messagesStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  @override
  Future<void> sendMessage({
    required String projectId,
    required ChatMessage message,
  }) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('messages')
        .doc(message.id)
        .set(message.toFirestore());
  }

  /// Marquer les messages comme lus
  Future<void> markMessagesAsRead(String projectId, String userId) async {
    final batch = _firestore.batch();
    final messages = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true, 'readAt': FieldValue.serverTimestamp()});
    }

    await batch.commit();
  }

  /// Obtenir le nombre de messages non lus
  Future<int> getUnreadCount(String projectId, String userId) async {
    final unreadMessages = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    return unreadMessages.docs.length;
  }
}

