// lib/models/notification_item.dart - Version étendue compatible

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ ÉTENDU: Types de notifications enrichis par rôle (compatible avec l'existant)
enum NotificationType {
  // 📱 EXISTANT - Maintenu pour compatibilité
  message,
  devis,
  projet,
  tatoueur,
  system,
  rdv,
  facture,
  info,
  
  // 👤 NOUVEAU - PARTICULIER spécifique
  devisRequested,        // "Votre demande de devis a été envoyée"
  devisReceived,         // "Vous avez reçu un devis de [Tatoueur]"
  devisPending,          // "Votre devis expire dans 2 jours"
  devisAccepted,         // "Votre devis a été accepté"
  devisRejected,         // "Votre devis a été refusé"
  appointmentConfirmed,  // "RDV confirmé le [date]"
  appointmentReminder,   // "RDV demain à 14h avec [Tatoueur]"
  projectUpdated,        // "Votre projet a été mis à jour"
  projectCompleted,      // "Votre tatouage est terminé !"
  
  // 🎨 NOUVEAU - TATOUEUR PRO spécifique  
  devisRequestReceived,  // "Nouvelle demande de devis de [Client]"
  devisReminder,         // "Rappel: Devis en attente pour [Client]"
  devisExpiringSoon,     // "Votre devis expire dans 2 jours"
  paymentRequest,        // "Demande de paiement envoyée"
  paymentReceived,       // "Paiement reçu de [Client]"
  paymentOverdue,        // "Facture impayée depuis [X] jours"
  clientMessage,         // "Nouveau message de [Client]"
  appointmentBooked,     // "Nouveau RDV réservé"
  reviewReceived,        // "Nouvel avis client"
  
  // 🎪 NOUVEAU - ORGANISATEUR spécifique
  eventSubmitted,        // "Votre événement a été soumis"
  eventApproved,         // "Votre événement a été approuvé"
  eventRejected,         // "Votre événement a été refusé"
  tattooerApplicationReceived, // "Nouvelle candidature de tatoueur"
  tattooerApplicationReminder, // "Candidatures en attente de réponse"
  tattooerAccepted,      // "Tatoueur accepté pour votre événement"
  tattooerRejectedByOrganizer, // "Tatoueur refusé"
  eventCapacityFull,     // "Votre événement est complet"
  eventStartsSoon,       // "Votre événement commence demain"
  
  // 🔔 NOUVEAU - SYSTÈME étendu
  welcome,               // "Bienvenue sur Kipik !"
  systemMaintenance,     // "Maintenance programmée"
  newFeature,            // "Nouvelle fonctionnalité disponible"
  securityAlert,         // "Connexion depuis un nouvel appareil"
  subscriptionExpiring,  // "Votre abonnement expire bientôt"
  profileIncomplete,     // "Complétez votre profil"
}

// ✅ NOUVEAU: Priorités et catégories (optionnel)
enum NotificationPriority {
  low,      // Gris - Info générale
  medium,   // Bleu - Action recommandée  
  high,     // Orange - Action requise
  urgent,   // Rouge - Action immédiate
}

enum NotificationCategory {
  business,     // Devis, paiements, projets
  communication, // Messages, avis
  events,       // RDV, événements
  system,       // Maintenance, sécurité
  marketing,    // Nouvelles fonctionnalités
}

// ✅ COMPATIBLE: Modèle existant étendu
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String? fullMessage;
  final DateTime date;
  final IconData icon;
  final Color color;
  final NotificationType type;
  final String? projectId;
  final bool read;
  
  // ✅ NOUVEAU: Métadonnées enrichies (optionnelles pour compatibilité)
  final NotificationPriority? priority;
  final NotificationCategory? category;
  final String? devisId;
  final String? eventId;
  final String? senderId;
  final String? senderName;
  final Map<String, dynamic>? actionData;
  final DateTime? expiresAt;
  final bool? requiresAction;
  
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.fullMessage,
    required this.date,
    required this.icon,
    required this.color,
    required this.type,
    this.projectId,
    this.read = false,
    // ✅ NOUVEAU: Paramètres optionnels pour compatibilité
    this.priority,
    this.category,
    this.devisId,
    this.eventId,
    this.senderId,
    this.senderName,
    this.actionData,
    this.expiresAt,
    this.requiresAction,
  });
  
  // ✅ ÉTENDU: CopyWith avec nouveaux champs
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
    NotificationPriority? priority,
    NotificationCategory? category,
    String? devisId,
    String? eventId,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? actionData,
    DateTime? expiresAt,
    bool? requiresAction,
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
      priority: priority ?? this.priority,
      category: category ?? this.category,
      devisId: devisId ?? this.devisId,
      eventId: eventId ?? this.eventId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      actionData: actionData ?? this.actionData,
      expiresAt: expiresAt ?? this.expiresAt,
      requiresAction: requiresAction ?? this.requiresAction,
    );
  }
  
  // ✅ ÉTENDU: Icônes pour nouveaux types
  static IconData getIconForType(NotificationType type) {
    switch (type) {
      // Existant - maintenu
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
      case NotificationType.rdv:
        return Icons.event;
      case NotificationType.facture:
        return Icons.receipt;
      case NotificationType.info:
        return Icons.info_outline;
        
      // Nouveau - Particulier
      case NotificationType.devisRequested:
      case NotificationType.devisReceived:
      case NotificationType.devisPending:
      case NotificationType.devisAccepted:
      case NotificationType.devisRejected:
        return Icons.receipt_long;
      case NotificationType.appointmentConfirmed:
      case NotificationType.appointmentReminder:
        return Icons.event;
      case NotificationType.projectUpdated:
      case NotificationType.projectCompleted:
        return Icons.art_track;
        
      // Nouveau - Tatoueur
      case NotificationType.devisRequestReceived:
      case NotificationType.devisReminder:
      case NotificationType.devisExpiringSoon:
        return Icons.assignment;
      case NotificationType.paymentRequest:
      case NotificationType.paymentReceived:
      case NotificationType.paymentOverdue:
        return Icons.payment;
      case NotificationType.clientMessage:
        return Icons.chat;
      case NotificationType.appointmentBooked:
        return Icons.event_available;
      case NotificationType.reviewReceived:
        return Icons.star;
        
      // Nouveau - Organisateur
      case NotificationType.eventSubmitted:
      case NotificationType.eventApproved:
      case NotificationType.eventRejected:
      case NotificationType.eventCapacityFull:
      case NotificationType.eventStartsSoon:
        return Icons.event_available;
      case NotificationType.tattooerApplicationReceived:
      case NotificationType.tattooerApplicationReminder:
      case NotificationType.tattooerAccepted:
      case NotificationType.tattooerRejectedByOrganizer:
        return Icons.person_add;
        
      // Nouveau - Système
      case NotificationType.welcome:
        return Icons.waving_hand;
      case NotificationType.systemMaintenance:
        return Icons.build;
      case NotificationType.newFeature:
        return Icons.new_releases;
      case NotificationType.securityAlert:
        return Icons.security;
      case NotificationType.subscriptionExpiring:
        return Icons.payment;
      case NotificationType.profileIncomplete:
        return Icons.account_circle;
    }
  }
  
  // ✅ ÉTENDU: Couleurs pour nouveaux types
  static Color getColorForType(NotificationType type) {
    switch (type) {
      // Existant - maintenu
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
      case NotificationType.rdv:
        return Colors.orange;
      case NotificationType.facture:
        return Colors.green;
      case NotificationType.info:
        return Colors.orange;
        
      // Nouveau - Particulier (bleus/verts)
      case NotificationType.devisRequested:
        return Colors.blue;
      case NotificationType.devisReceived:
        return Colors.green;
      case NotificationType.devisPending:
        return Colors.orange;
      case NotificationType.devisAccepted:
        return Colors.green;
      case NotificationType.devisRejected:
        return Colors.red;
      case NotificationType.appointmentConfirmed:
      case NotificationType.appointmentReminder:
        return Colors.orange;
      case NotificationType.projectUpdated:
        return Colors.purple;
      case NotificationType.projectCompleted:
        return Colors.green;
        
      // Nouveau - Tatoueur (oranges/verts)
      case NotificationType.devisRequestReceived:
        return Colors.blue;
      case NotificationType.devisReminder:
        return Colors.orange;
      case NotificationType.devisExpiringSoon:
        return Colors.red;
      case NotificationType.paymentRequest:
        return Colors.orange;
      case NotificationType.paymentReceived:
        return Colors.green;
      case NotificationType.paymentOverdue:
        return Colors.red;
      case NotificationType.clientMessage:
        return Colors.blue;
      case NotificationType.appointmentBooked:
        return Colors.green;
      case NotificationType.reviewReceived:
        return Colors.amber;
        
      // Nouveau - Organisateur (teals/purples)
      case NotificationType.eventSubmitted:
        return Colors.blue;
      case NotificationType.eventApproved:
        return Colors.green;
      case NotificationType.eventRejected:
        return Colors.red;
      case NotificationType.tattooerApplicationReceived:
        return Colors.teal;
      case NotificationType.tattooerApplicationReminder:
        return Colors.orange;
      case NotificationType.tattooerAccepted:
        return Colors.green;
      case NotificationType.tattooerRejectedByOrganizer:
        return Colors.red;
      case NotificationType.eventCapacityFull:
        return Colors.green;
      case NotificationType.eventStartsSoon:
        return Colors.orange;
        
      // Nouveau - Système (greys/oranges)
      case NotificationType.welcome:
        return Colors.blue;
      case NotificationType.systemMaintenance:
        return Colors.orange;
      case NotificationType.newFeature:
        return Colors.purple;
      case NotificationType.securityAlert:
        return Colors.red;
      case NotificationType.subscriptionExpiring:
        return Colors.orange;
      case NotificationType.profileIncomplete:
        return Colors.amber;
    }
  }
  
  // ✅ NOUVEAU: Getters pour les nouvelles propriétés
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isUrgent => priority == NotificationPriority.urgent;
  bool get isActionRequired => (requiresAction ?? false) && !read;
  
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return null;
    return expiresAt!.difference(now);
  }
  
  // ✅ COMPATIBLE: Formater la date (maintenu)
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
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return 'Il y a ${difference.inDays} ${difference.inDays == 1 ? 'jour' : 'jours'}';
      }
    }
  }
  
  // ✅ ÉTENDU: Firestore avec nouveaux champs
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
      // Nouveaux champs
      priority: data['priority'] != null ? _getPriorityFromString(data['priority']) : null,
      category: data['category'] != null ? _getCategoryFromString(data['category']) : null,
      devisId: data['devisId'],
      eventId: data['eventId'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      actionData: data['actionData'],
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      requiresAction: data['requiresAction'],
    );
  }
  
  // ✅ ÉTENDU: ToFirestore avec nouveaux champs
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
      // Nouveaux champs
      'priority': priority?.name,
      'category': category?.name,
      'devisId': devisId,
      'eventId': eventId,
      'senderId': senderId,
      'senderName': senderName,
      'actionData': actionData,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'requiresAction': requiresAction,
    };
  }
  
  // ✅ ÉTENDU: Conversion types enrichis
  static NotificationType _getTypeFromString(String? typeString) {
    switch (typeString) {
      // Existant
      case 'message': return NotificationType.message;
      case 'devis': return NotificationType.devis;
      case 'projet': return NotificationType.projet;
      case 'tatoueur': return NotificationType.tatoueur;
      case 'system': return NotificationType.system;
      case 'rdv': return NotificationType.rdv;
      case 'facture': return NotificationType.facture;
      case 'info': return NotificationType.info;
      
      // Nouveau - Particulier
      case 'devisRequested': return NotificationType.devisRequested;
      case 'devisReceived': return NotificationType.devisReceived;
      case 'devisPending': return NotificationType.devisPending;
      case 'devisAccepted': return NotificationType.devisAccepted;
      case 'devisRejected': return NotificationType.devisRejected;
      case 'appointmentConfirmed': return NotificationType.appointmentConfirmed;
      case 'appointmentReminder': return NotificationType.appointmentReminder;
      case 'projectUpdated': return NotificationType.projectUpdated;
      case 'projectCompleted': return NotificationType.projectCompleted;
      
      // Nouveau - Tatoueur
      case 'devisRequestReceived': return NotificationType.devisRequestReceived;
      case 'devisReminder': return NotificationType.devisReminder;
      case 'devisExpiringSoon': return NotificationType.devisExpiringSoon;
      case 'paymentRequest': return NotificationType.paymentRequest;
      case 'paymentReceived': return NotificationType.paymentReceived;
      case 'paymentOverdue': return NotificationType.paymentOverdue;
      case 'clientMessage': return NotificationType.clientMessage;
      case 'appointmentBooked': return NotificationType.appointmentBooked;
      case 'reviewReceived': return NotificationType.reviewReceived;
      
      // Nouveau - Organisateur
      case 'eventSubmitted': return NotificationType.eventSubmitted;
      case 'eventApproved': return NotificationType.eventApproved;
      case 'eventRejected': return NotificationType.eventRejected;
      case 'tattooerApplicationReceived': return NotificationType.tattooerApplicationReceived;
      case 'tattooerApplicationReminder': return NotificationType.tattooerApplicationReminder;
      case 'tattooerAccepted': return NotificationType.tattooerAccepted;
      case 'tattooerRejectedByOrganizer': return NotificationType.tattooerRejectedByOrganizer;
      case 'eventCapacityFull': return NotificationType.eventCapacityFull;
      case 'eventStartsSoon': return NotificationType.eventStartsSoon;
      
      // Nouveau - Système
      case 'welcome': return NotificationType.welcome;
      case 'systemMaintenance': return NotificationType.systemMaintenance;
      case 'newFeature': return NotificationType.newFeature;
      case 'securityAlert': return NotificationType.securityAlert;
      case 'subscriptionExpiring': return NotificationType.subscriptionExpiring;
      case 'profileIncomplete': return NotificationType.profileIncomplete;
      
      default: return NotificationType.system;
    }
  }
  
  static String _getStringFromType(NotificationType type) {
    return type.name;
  }
  
  static NotificationPriority? _getPriorityFromString(String? priorityString) {
    switch (priorityString) {
      case 'low': return NotificationPriority.low;
      case 'medium': return NotificationPriority.medium;
      case 'high': return NotificationPriority.high;
      case 'urgent': return NotificationPriority.urgent;
      default: return null;
    }
  }
  
  static NotificationCategory? _getCategoryFromString(String? categoryString) {
    switch (categoryString) {
      case 'business': return NotificationCategory.business;
      case 'communication': return NotificationCategory.communication;
      case 'events': return NotificationCategory.events;
      case 'system': return NotificationCategory.system;
      case 'marketing': return NotificationCategory.marketing;
      default: return null;
    }
  }
  
  // ✅ COMPATIBLE: Factory create maintenu
  factory NotificationItem.create({
    required String id,
    required String title,
    required String message,
    String? fullMessage,
    DateTime? date,
    required NotificationType type,
    String? projectId,
    bool read = false,
    // Nouveaux paramètres optionnels
    NotificationPriority? priority,
    NotificationCategory? category,
    String? devisId,
    String? eventId,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? actionData,
    DateTime? expiresAt,
    bool? requiresAction,
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
      priority: priority,
      category: category,
      devisId: devisId,
      eventId: eventId,
      senderId: senderId,
      senderName: senderName,
      actionData: actionData,
      expiresAt: expiresAt,
      requiresAction: requiresAction,
    );
  }
}