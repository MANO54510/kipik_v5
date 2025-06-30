// lib/services/chat_repository.dart

import 'dart:async';
import 'package:kipik_v5/models/chat_message.dart';

/// Contrat pour le chat de projet.
abstract class ChatRepository {
  /// Flux des messages du projet.
  Stream<List<ChatMessage>> messagesStream(String projectId);

  /// Envoie un message.
  Future<void> sendMessage({
    required String projectId,
    required ChatMessage message,
  });
}
