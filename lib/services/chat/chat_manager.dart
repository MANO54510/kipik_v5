// lib/services/chat/chat_manager.dart

import '../../models/chat_message.dart';
import '../../models/support_ticket.dart';
import '../ai/ai_service_manager.dart';
import '../auth/secure_auth_service.dart';
import 'ai_chat_service.dart';
import 'project_chat_service.dart';
import 'support_chat_service.dart';

class ChatManager {
  static final ProjectChatService _projectChat = ProjectChatService();
  static final SupportChatService _supportChat = SupportChatService();

  // ===============================
  // 🤖 AI CHAT - VERSION AMÉLIORÉE
  // ===============================

  /// 🚀 Point d'entrée principal pour l'IA avec actions interactives
  static Future<ChatMessage> askAI(
    String prompt, {
    bool allowImages = false,
    String? contextPage,
  }) async {
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // ✅ NOUVEAU: Utiliser le service IA enhanced avec actions
      if (AIServiceManager.isConfigured) {
        return await AIServiceManager.getAIResponse(
          prompt,
          currentUser.uid,
          allowImageGeneration: allowImages,
          contextPage: contextPage,
        );
      } else {
        // ✅ FALLBACK: Utiliser l'ancien service si le nouveau n'est pas configuré
        return await AIChatService.getAIResponse(prompt, allowImages);
      }
    } catch (e) {
      // Message d'erreur user-friendly
      return ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Désolé, je ne peux pas répondre pour le moment. Réessayez dans quelques instants.',
        senderId: 'assistant',
        timestamp: DateTime.now(),
      );
    }
  }

  /// 📊 Statistiques budget IA (pour monitoring)
  static Future<Map<String, dynamic>> getAIBudgetStats() async {
    try {
      if (AIServiceManager.isConfigured) {
        return await AIServiceManager.getBudgetStats();
      } else {
        return {
          'configured': false,
          'currentCost': 0.0,
          'budgetLimit': 35.0,
          'percentage': 0,
          'isOverBudget': false,
        };
      }
    } catch (e) {
      return {
        'error': true,
        'configured': false,
        'currentCost': 0.0,
        'budgetLimit': 35.0,
        'percentage': 0,
        'isOverBudget': false,
      };
    }
  }

  // ===============================
  // 📝 PROJECT CHAT (inchangé)
  // ===============================

  static Stream<List<ChatMessage>> projectMessages(String projectId) {
    return _projectChat.messagesStream(projectId);
  }

  static Future<void> sendProjectMessage(String projectId, ChatMessage message) {
    return _projectChat.sendMessage(projectId: projectId, message: message);
  }

  static Future<void> markProjectMessagesAsRead(String projectId, String userId) {
    return _projectChat.markMessagesAsRead(projectId, userId);
  }

  static Future<int> getProjectUnreadCount(String projectId, String userId) {
    return _projectChat.getUnreadCount(projectId, userId);
  }

  // ===============================
  // 🎧 SUPPORT CHAT (inchangé)
  // ===============================

  static Future<String> createSupportTicket({
    required String userId,
    required String subject,
    required String category,
    required String message,
    String? attachmentUrl,
  }) {
    return _supportChat.createSupportTicket(
      userId: userId,
      subject: subject,
      category: category,
      initialMessage: message,
      attachmentUrl: attachmentUrl,
    );
  }

  static Stream<List<ChatMessage>> supportMessages(String ticketId) {
    return _supportChat.supportMessagesStream(ticketId);
  }

  static Future<void> sendSupportMessage(String ticketId, ChatMessage message) {
    return _supportChat.sendSupportMessage(ticketId: ticketId, message: message);
  }

  static Stream<List<SupportTicket>> userSupportTickets(String userId) {
    return _supportChat.userTicketsStream(userId);
  }

  static Future<void> closeSupportTicket(String ticketId) {
    return _supportChat.closeTicket(ticketId);
  }

  // ===============================
  // 🛠️ MÉTHODES UTILITAIRES
  // ===============================

  /// Vérifier si les services IA sont disponibles
  static bool get isAIAvailable => AIServiceManager.isConfigured;

  /// Obtenir le statut des services
  static Map<String, bool> getServicesStatus() {
    return {
      'aiConfigured': AIServiceManager.isConfigured,
      'projectChat': true, // Toujours disponible
      'supportChat': true, // Toujours disponible
    };
  }
}