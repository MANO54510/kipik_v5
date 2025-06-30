// lib/models/message_model.dart

/// Un modèle de message autonome, avec un timestamp Dart natif.
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    required this.isRead,
  });

  /// Crée à partir d'une Map (JSON-like).
  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      id: data['id'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      timestamp: DateTime.tryParse(data['timestamp'] as String? ?? '') ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  /// Convertit en Map pour envoi futur (backend).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}