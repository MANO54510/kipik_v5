// lib/models/support_ticket.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String category; // 'bug', 'question', 'suggestion', 'payment', 'account'
  final String status; // 'open', 'in_progress', 'waiting_customer', 'resolved', 'closed'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final String? assignedToAgent;
  final int messageCount;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.assignedToAgent,
    this.messageCount = 0,
  });

  // Factory pour créer depuis Firestore
  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SupportTicket(
      id: doc.id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      category: data['category'] ?? 'question',
      status: data['status'] ?? 'open',
      priority: data['priority'] ?? 'low',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      assignedToAgent: data['assignedToAgent'],
      messageCount: data['messageCount'] ?? 0,
    );
  }

  // Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'subject': subject,
      'category': category,
      'status': status,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'assignedToAgent': assignedToAgent,
      'messageCount': messageCount,
    };
  }

  // Méthodes utilitaires
  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
  bool get isHighPriority => priority == 'high' || priority == 'urgent';

  String get statusDisplay {
    switch (status) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'waiting_customer':
        return 'En attente de votre réponse';
      case 'resolved':
        return 'Résolu';
      case 'closed':
        return 'Fermé';
      default:
        return 'Inconnu';
    }
  }

  String get categoryDisplay {
    switch (category) {
      case 'bug':
        return 'Bug/Problème technique';
      case 'question':
        return 'Question';
      case 'suggestion':
        return 'Suggestion';
      case 'payment':
        return 'Paiement';
      case 'account':
        return 'Compte utilisateur';
      default:
        return 'Autre';
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case 'low':
        return 'Faible';
      case 'medium':
        return 'Moyenne';
      case 'high':
        return 'Élevée';
      case 'urgent':
        return 'Urgente';
      default:
        return 'Non définie';
    }
  }

  // Copier avec modifications
  SupportTicket copyWith({
    String? id,
    String? userId,
    String? subject,
    String? category,
    String? status,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
    String? assignedToAgent,
    int? messageCount,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      assignedToAgent: assignedToAgent ?? this.assignedToAgent,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  @override
  String toString() {
    return 'SupportTicket(id: $id, subject: $subject, status: $status, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupportTicket && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}