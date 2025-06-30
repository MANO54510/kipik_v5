// lib/models/notification_item.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Types de notifications - Compatible avec FirebaseNotificationService et NotificationsPage
enum NotificationType {
  message,
  devis,
  projet,
  tatoueur,
  system,
}

// Modèle de données pour une notification
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String? fullMessage; // ✅ Ajouté pour compatibilité avec la page
  final DateTime date;
  final IconData icon; // ✅ Ajouté comme propriété directe
  final Color color; // ✅ Ajouté comme propriété directe
  final NotificationType type;
  final String? projectId;
  final bool read;
  
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.fullMessage, // ✅ Paramètre optionnel
    required this.date,
    required this.icon, // ✅ Requis maintenant
    required this.color, // ✅ Requis maintenant
    required this.type,
    this.projectId,
    this.read = false,
  });
  
  // Créer une copie de cette notification avec certains champs mis à jour
  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? fullMessage,
    DateTime? date,
    IconData? icon,
    Color? color,
    NotificationType? type,
    String? projectId,
    bool? read,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      fullMessage: fullMessage ?? this.fullMessage,
      date: date ?? this.date,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      projectId: projectId ?? this.projectId,
      read: read ?? this.read,
    );
  }
  
  // ✅ Méthodes statiques pour obtenir icône et couleur par type
  static IconData getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.chat;
      case NotificationType.devis:
        return Icons.receipt;
      case NotificationType.projet:
        return Icons.art_track;
      case NotificationType.tatoueur:
        return Icons.person;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }
  
  static Color getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.devis:
        return Colors.green;
      case NotificationType.projet:
        return Colors.purple;
      case NotificationType.tatoueur:
        return Colors.teal;
      case NotificationType.system:
        return Colors.orange;
    }
  }
  
  // Formater la date pour l'affichage
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Aujourd\'hui, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateToCheck == yesterday) {
      return 'Hier, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      final difference = now.difference(date);
      if (difference.inDays > 7) {
        // Format complet pour les dates au-delà d'une semaine
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        // Format "Il y a X jours"
        return 'Il y a ${difference.inDays} ${difference.inDays == 1 ? 'jour' : 'jours'}';
      }
    }
  }
  
  // ✅ Méthode pour créer depuis Firestore
  factory NotificationItem.fromFirestore(Map<String, dynamic> data, String id) {
    final type = _getTypeFromString(data['type']);
    return NotificationItem(
      id: id,
      title: data['title'] ?? '',
      message: data['body'] ?? data['message'] ?? '',
      fullMessage: data['fullMessage'],
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? 
            (data['date'] as Timestamp?)?.toDate() ?? 
            DateTime.now(),
      icon: getIconForType(type),
      color: getColorForType(type),
      type: type,
      projectId: data['projectId'],
      read: data['read'] ?? false,
    );
  }
  
  // ✅ Méthode pour convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': message,
      'message': message,
      'fullMessage': fullMessage,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(date),
      'type': _getStringFromType(type),
      'projectId': projectId,
      'read': read,
    };
  }
  
  // ✅ Méthodes utilitaires pour la conversion de types
  static NotificationType _getTypeFromString(String? typeString) {
    switch (typeString) {
      case 'message':
        return NotificationType.message;
      case 'devis':
        return NotificationType.devis;
      case 'projet':
        return NotificationType.projet;
      case 'tatoueur':
        return NotificationType.tatoueur;
      case 'system':
      case 'info': // ✅ Rétrocompatibilité
        return NotificationType.system;
      // ✅ Mapping des anciens types vers les nouveaux
      case 'rdv':
        return NotificationType.system;
      case 'facture':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
  
  static String _getStringFromType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return 'message';
      case NotificationType.devis:
        return 'devis';
      case NotificationType.projet:
        return 'projet';
      case NotificationType.tatoueur:
        return 'tatoueur';
      case NotificationType.system:
        return 'system';
    }
  }
  
  // ✅ Factory constructeur avec type automatique (pour faciliter la création)
  factory NotificationItem.create({
    required String id,
    required String title,
    required String message,
    String? fullMessage,
    DateTime? date,
    required NotificationType type,
    String? projectId,
    bool read = false,
  }) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      fullMessage: fullMessage,
      date: date ?? DateTime.now(),
      icon: getIconForType(type),
      color: getColorForType(type),
      type: type,
      projectId: projectId,
      read: read,
    );
  }
}