// lib/services/chat/chat_manager.dart

import '../../models/chat_message.dart';
import '../../models/support_ticket.dart';
import 'ai_chat_service.dart';
import 'project_chat_service.dart';
import 'support_chat_service.dart';

class ChatManager {
  static final ProjectChatService _projectChat = ProjectChatService();
  static final SupportChatService _supportChat = SupportChatService();

  // AI Chat
  static Future<ChatMessage> askAI(String prompt, {bool allowImages = true}) {
    return AIChatService.getAIResponse(prompt, allowImages);
  }

  // Project Chat
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

  // Support Chat
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
}