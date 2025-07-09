// lib/models/chat_message.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_action.dart'; // ✅ AJOUTÉ

/// A single chat message.
class ChatMessage {
  /// Unique ID (could be a timestamp or UUID).
  final String id;
  
  /// The text content, or null if it's an image only.
  final String? text;
  
  /// URL of an uploaded image, if any.
  final String? imageUrl;
  
  /// The sender's user-ID.
  final String senderId;
  
  /// When the message was created.
  final DateTime timestamp;
  
  /// Whether the message has been read (for project and support chats).
  final bool isRead;
  
  /// When the message was read.
  final DateTime? readAt;
  
  /// ✅ NOUVEAU: Actions suggérées par l'IA
  final List<AIAction>? actions;

  ChatMessage({
    required this.id,
    this.text,
    this.imageUrl,
    required this.senderId,
    required this.timestamp,
    this.isRead = false,
    this.readAt,
    this.actions, // ✅ AJOUTÉ
  });

  /// Factory constructor pour créer depuis Firestore
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatMessage(
      id: doc.id,
      text: data['text'],
      imageUrl: data['imageUrl'],
      senderId: data['senderId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      // ✅ NOUVEAU: Désérialiser les actions
      actions: data['actions'] != null 
          ? (data['actions'] as List)
              .map((actionData) => AIAction.fromJson(actionData))
              .toList()
          : null,
    );
  }

  /// Convertir vers format Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'imageUrl': imageUrl,
      'senderId': senderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      // ✅ NOUVEAU: Sérialiser les actions
      'actions': actions?.map((action) => action.toJson()).toList(),
    };
  }

  /// Factory constructor pour créer depuis Map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      text: map['text'],
      imageUrl: map['imageUrl'],
      senderId: map['senderId'] ?? '',
      timestamp: map['timestamp'] is DateTime 
          ? map['timestamp'] 
          : DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isRead: map['isRead'] ?? false,
      readAt: map['readAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['readAt']) : null,
      // ✅ NOUVEAU: Désérialiser les actions depuis Map
      actions: map['actions'] != null 
          ? (map['actions'] as List)
              .map((actionData) => AIAction.fromJson(actionData))
              .toList()
          : null,
    );
  }

  /// Convertir vers Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'imageUrl': imageUrl,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'readAt': readAt?.millisecondsSinceEpoch,
      // ✅ NOUVEAU: Sérialiser les actions
      'actions': actions?.map((action) => action.toJson()).toList(),
    };
  }

  /// Getters utilitaires
  bool get hasText => text != null && text!.trim().isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasContent => hasText || hasImage;
  
  /// ✅ NOUVEAU: Vérifier si le message a des actions
  bool get hasActions => actions != null && actions!.isNotEmpty;
  
  /// Vérifier si le message vient d'un utilisateur (pas assistant/agent)
  bool get isFromUser => !senderId.startsWith('assistant') && 
                         !senderId.startsWith('agent_') && 
                         senderId != 'system';
  
  /// Vérifier si le message vient de l'assistant IA
  bool get isFromAssistant => senderId == 'assistant' || senderId.startsWith('assistant');
  
  /// Vérifier si le message vient d'un agent de support
  bool get isFromSupportAgent => senderId.startsWith('agent_');
  
  /// Vérifier si le message est un message système
  bool get isSystemMessage => senderId == 'system';

  /// Marquer le message comme lu
  ChatMessage markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// Copier avec modifications
  ChatMessage copyWith({
    String? id,
    String? text,
    String? imageUrl,
    String? senderId,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    List<AIAction>? actions, // ✅ AJOUTÉ
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      actions: actions ?? this.actions, // ✅ AJOUTÉ
    );
  }

  /// Format d'affichage du temps
  String get timeDisplay {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}min';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}j';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  /// Validation du message
  bool get isValid {
    return id.isNotEmpty && 
           senderId.isNotEmpty && 
           hasContent;
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, hasText: $hasText, hasImage: $hasImage, isRead: $isRead, hasActions: $hasActions)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}