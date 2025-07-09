// lib/services/notification/enhanced_notification_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../auth/secure_auth_service.dart';
import '../../models/notification_item.dart';
import '../../models/user_role.dart';

/// Service de notifications enrichi compatible avec l'existant
class EnhancedNotificationService {
  static EnhancedNotificationService? _instance;
  static EnhancedNotificationService get instance =>
      _instance ??= EnhancedNotificationService._();
  EnhancedNotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Variables pour stocker les notifications localement
  int _unreadCount = 0;
  List<NotificationItem> _notifications = [];
  bool _isInitialized = false;

  // ✅ COMPATIBLE: Getters existants maintenus
  String? get _currentUserId {
    try {
      return SecureAuthService.instance.currentUserId;
    } catch (e) {
      return null;
    }
  }

  UserRole? get _currentUserRole {
    try {
      return SecureAuthService.instance.currentUserRole;
    } catch (e) {
      return null;
    }
  }

  // ✅ COMPATIBLE: Méthodes synchrones existantes
  int getUnreadCountSync() {
    try {
      return _unreadCount;
    } catch (e) {
      return 0;
    }
  }

  List<NotificationItem> getAllNotificationsSync() {
    try {
      return List.from(_notifications);
    } catch (e) {
      return [];
    }
  }

  // ✅ COMPATIBLE: Méthodes asynchrones existantes
  Future<List<NotificationItem>> getAllNotifications() async {
    try {
      await _ensureInitialized();
      return List.from(_notifications);
    } catch (e) {
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      await _ensureInitialized();
      return _unreadCount;
    } catch (e) {
      return 0;
    }
  }

  Future<List<NotificationItem>> getUnreadNotifications() async {
    try {
      await _ensureInitialized();
      return _notifications.where((notification) => !notification.read).toList();
    } catch (e) {
      return [];
    }
  }

  // ✅ COMPATIBLE: Gestion locale existante
  void addNotification(NotificationItem notification) {
    try {
      _notifications.insert(0, notification);
      if (!notification.read) {
        _unreadCount++;
      }
    } catch (e) {
      print('Erreur addNotification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].read) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
        
        try {
          await _updateReadStatusInFirestore(notificationId);
        } catch (e) {
          print('Erreur sync Firebase markAsRead: $e');
        }
      }
    } catch (e) {
      print('Erreur markAsRead: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      _unreadCount = 0;
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].read) {
          _notifications[i] = _notifications[i].copyWith(read: true);
        }
      }
      
      try {
        await _markAllAsReadInFirestore();
      } catch (e) {
        print('Erreur sync Firebase markAllAsRead: $e');
      }
    } catch (e) {
      print('Erreur markAllAsRead: $e');
    }
  }

  // ✅ COMPATIBLE: Notifications factices enrichies
  void generateMockNotifications() {
    try {
      _notifications.clear();
      _unreadCount = 0;

      final userRole = _currentUserRole ?? UserRole.client;
      List<NotificationItem> mockNotifications = [];

      switch (userRole) {
        case UserRole.client:
          mockNotifications = _generateParticulierMockNotifications();
          break;
        case UserRole.tatoueur:
          mockNotifications = _generateTatoueurMockNotifications();
          break;
        case UserRole.organisateur:
          mockNotifications = _generateOrganisateurMockNotifications();
          break;
        case UserRole.admin:
          mockNotifications = _generateSystemMockNotifications();
          break;
        default:
          mockNotifications = _generateSystemMockNotifications();
      }

      for (final notification in mockNotifications) {
        addNotification(notification);
      }

      _unreadCount = _notifications.where((n) => !n.read).length;
      print('✅ ${_notifications.length} notifications factices générées pour ${userRole.name}');
    } catch (e) {
      print('Erreur generateMockNotifications: $e');
    }
  }

  // ✅ NOUVEAU: Notifications particulier spécifiques
  List<NotificationItem> _generateParticulierMockNotifications() {
    return [
      NotificationItem.create(
        id: 'part_1',
        title: 'Devis reçu',
        message: 'Marie Lefevre vous a envoyé un devis (320€)',
        fullMessage: 'Devis détaillé pour votre projet "Mandala épaule" :\n\n- Design personnalisé : 120€\n- Réalisation (3h) : 180€\n- Matériel : 20€\n\nTotal : 320€\n\nValidité : 30 jours',
        date: DateTime.now().subtract(const Duration(minutes: 15)),
        type: NotificationType.devisReceived,
        priority: NotificationPriority.high,
        category: NotificationCategory.business,
        devisId: 'devis123',
        senderId: 'marie456',
        senderName: 'Marie Lefevre',
        requiresAction: true,
        expiresAt: DateTime.now().add(const Duration(days: 29)),
        actionData: {'action': 'view_devis', 'amount': 320.0},
      ),
      NotificationItem.create(
        id: 'part_2',
        title: 'Demande de devis envoyée',
        message: 'Votre demande pour "Rose vintage" a été envoyée',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.devisRequested,
        priority: NotificationPriority.medium,
        category: NotificationCategory.business,
        read: true,
      ),
      NotificationItem.create(
        id: 'part_3',
        title: 'RDV confirmé',
        message: 'Votre rendez-vous avec Sophie Martin le 25/05/2025 à 14h30 est confirmé',
        date: DateTime.now().subtract(const Duration(hours: 6)),
        type: NotificationType.appointmentConfirmed,
        priority: NotificationPriority.medium,
        category: NotificationCategory.events,
        read: true,
      ),
      NotificationItem.create(
        id: 'part_4',
        title: 'Devis expirant bientôt',
        message: 'Votre devis d\'Alexandre Petit expire dans 2 jours',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.devisPending,
        priority: NotificationPriority.urgent,
        category: NotificationCategory.business,
        requiresAction: true,
        expiresAt: DateTime.now().add(const Duration(days: 2)),
      ),
      NotificationItem.create(
        id: 'part_5',
        title: 'Projet mis à jour',
        message: 'Sophie Martin a ajouté des photos à votre projet "Rose vintage"',
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: NotificationType.projectUpdated,
        priority: NotificationPriority.medium,
        category: NotificationCategory.business,
        read: true,
      ),
    ];
  }

  // ✅ NOUVEAU: Notifications tatoueur spécifiques
  List<NotificationItem> _generateTatoueurMockNotifications() {
    return [
      NotificationItem.create(
        id: 'tat_1',
        title: 'Nouvelle demande de devis',
        message: 'Claire Dubois souhaite un tatouage géométrique',
        fullMessage: 'Projet : Tatouage géométrique sur avant-bras\nBudget : 300-400€\nDisponibilité : Flexible\n\nDescription détaillée :\nClaire souhaite un design géométrique moderne avec des lignes épurées. Style minimaliste avec quelques touches de couleur.',
        date: DateTime.now().subtract(const Duration(minutes: 30)),
        type: NotificationType.devisRequestReceived,
        priority: NotificationPriority.high,
        category: NotificationCategory.business,
        senderId: 'claire789',
        senderName: 'Claire Dubois',
        requiresAction: true,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        actionData: {'action': 'create_devis', 'clientId': 'claire789'},
      ),
      NotificationItem.create(
        id: 'tat_2',
        title: 'Rappel devis en attente',
        message: 'Devis non envoyé pour Lucas Martin (demande il y a 3 jours)',
        date: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.devisReminder,
        priority: NotificationPriority.urgent,
        category: NotificationCategory.business,
        requiresAction: true,
        actionData: {'action': 'create_devis', 'clientName': 'Lucas Martin'},
      ),
      NotificationItem.create(
        id: 'tat_3',
        title: 'Paiement reçu',
        message: 'Paiement de 280€ reçu de Emma Rousseau',
        date: DateTime.now().subtract(const Duration(hours: 4)),
        type: NotificationType.paymentReceived,
        priority: NotificationPriority.medium,
        category: NotificationCategory.business,
        read: true,
      ),
      NotificationItem.create(
        id: 'tat_4',
        title: 'Nouveau RDV réservé',
        message: 'Anna Lopez a réservé un créneau le 28/05/2025 à 10h',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.appointmentBooked,
        priority: NotificationPriority.medium,
        category: NotificationCategory.events,
        read: true,
      ),
      NotificationItem.create(
        id: 'tat_5',
        title: 'Facture impayée',
        message: 'Facture de 350€ impayée depuis 7 jours (Thomas Durand)',
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: NotificationType.paymentOverdue,
        priority: NotificationPriority.urgent,
        category: NotificationCategory.business,
        requiresAction: true,
        actionData: {'action': 'send_reminder', 'clientName': 'Thomas Durand'},
      ),
    ];
  }

  // ✅ NOUVEAU: Notifications organisateur spécifiques
  List<NotificationItem> _generateOrganisateurMockNotifications() {
    return [
      NotificationItem.create(
        id: 'org_1',
        title: 'Nouvelle candidature',
        message: 'Alexandre Petit souhaite participer à "Convention Paris 2025"',
        fullMessage: 'Candidature reçue pour la Convention Paris 2025\n\nTatoueur : Alexandre Petit\nSpécialités : Réalisme, Portraits\nExpérience : 8 ans\nPortfolio : Disponible\n\nMotivation :\n"Je serais ravi de participer à cet événement prestigieux. Mon style réaliste et mes portraits détaillés correspondent parfaitement à l\'ambiance de votre convention."',
        date: DateTime.now().subtract(const Duration(minutes: 45)),
        type: NotificationType.tattooerApplicationReceived,
        priority: NotificationPriority.high,
        category: NotificationCategory.events,
        senderId: 'alex456',
        senderName: 'Alexandre Petit',
        requiresAction: true,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        actionData: {
          'action': 'review_application',
          'applicationId': 'app123',
          'tattooerName': 'Alexandre Petit',
        },
      ),
      NotificationItem.create(
        id: 'org_2',
        title: 'Événement approuvé',
        message: '"Convention Lyon 2025" a été approuvé ! Vous pouvez maintenant inviter des tatoueurs.',
        date: DateTime.now().subtract(const Duration(hours: 3)),
        type: NotificationType.eventApproved,
        priority: NotificationPriority.high,
        category: NotificationCategory.events,
        eventId: 'event456',
        requiresAction: true,
        actionData: {'action': 'manage_event', 'status': 'approved'},
      ),
      NotificationItem.create(
        id: 'org_3',
        title: 'Candidatures en attente',
        message: '3 candidature(s) en attente pour "Salon Marseille"',
        date: DateTime.now().subtract(const Duration(hours: 8)),
        type: NotificationType.tattooerApplicationReminder,
        priority: NotificationPriority.urgent,
        category: NotificationCategory.events,
        requiresAction: true,
        actionData: {'action': 'review_applications', 'count': 3},
      ),
      NotificationItem.create(
        id: 'org_4',
        title: 'Événement commence bientôt',
        message: 'Votre "Festival Toulouse" commence dans 2 jours',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.eventStartsSoon,
        priority: NotificationPriority.medium,
        category: NotificationCategory.events,
        read: true,
      ),
      NotificationItem.create(
        id: 'org_5',
        title: 'Événement complet',
        message: '"Convention Bordeaux" a atteint sa capacité maximale (50 tatoueurs)',
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: NotificationType.eventCapacityFull,
        priority: NotificationPriority.medium,
        category: NotificationCategory.events,
        read: true,
      ),
    ];
  }

  // ✅ COMPATIBLE: Notifications système génériques
  List<NotificationItem> _generateSystemMockNotifications() {
    return [
      NotificationItem.create(
        id: 'sys_1',
        title: 'Bienvenue sur Kipik !',
        message: 'Découvrez toutes les fonctionnalités de la plateforme.',
        date: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.welcome,
        priority: NotificationPriority.medium,
        category: NotificationCategory.system,
      ),
      NotificationItem.create(
        id: 'sys_2',
        title: 'Profil incomplet',
        message: 'Complétez votre profil pour une meilleure expérience',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.profileIncomplete,
        priority: NotificationPriority.medium,
        category: NotificationCategory.system,
        requiresAction: true,
      ),
    ];
  }

  // ==================== NOUVELLES MÉTHODES ENRICHIES ====================

  // ✅ PARTICULIER - Notifications spécifiques
  Future<void> notifyDevisReceived({
    required String clientId,
    required String tatoueurId,
    required String tatoueurName,
    required String devisId,
    required double amount,
    String? projectTitle,
  }) async {
    await _createNotification(
      userId: clientId,
      type: NotificationType.devisReceived,
      title: "Nouveau devis reçu",
      message: "$tatoueurName vous a envoyé un devis (${amount.toStringAsFixed(0)}€)",
      priority: NotificationPriority.high,
      category: NotificationCategory.business,
      devisId: devisId,
      senderId: tatoueurId,
      senderName: tatoueurName,
      requiresAction: true,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      actionData: {'action': 'view_devis', 'amount': amount},
    );
  }

  Future<void> notifyDevisRequested({
    required String clientId,
    required String tatoueurId,
    required String projectTitle,
    required String devisId,
  }) async {
    // Notification pour le client
    await _createNotification(
      userId: clientId,
      type: NotificationType.devisRequested,
      title: "Demande de devis envoyée",
      message: "Votre demande pour \"$projectTitle\" a été envoyée",
      priority: NotificationPriority.medium,
      category: NotificationCategory.business,
      devisId: devisId,
      actionData: {'tatoueurId': tatoueurId},
    );

    // Notification pour le tatoueur
    await _createNotification(
      userId: tatoueurId,
      type: NotificationType.devisRequestReceived,
      title: "Nouvelle demande de devis",
      message: "Demande reçue pour \"$projectTitle\"",
      priority: NotificationPriority.high,
      category: NotificationCategory.business,
      devisId: devisId,
      requiresAction: true,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      actionData: {'clientId': clientId, 'action': 'create_devis'},
    );
  }

  // ✅ TATOUEUR - Notifications spécifiques
  Future<void> notifyPaymentOverdue({
    required String tatoueurId,
    required String clientName,
    required double amount,
    required int daysOverdue,
    required String invoiceId,
  }) async {
    await _createNotification(
      userId: tatoueurId,
      type: NotificationType.paymentOverdue,
      title: "Facture impayée",
      message: "Facture de ${amount.toStringAsFixed(0)}€ impayée depuis $daysOverdue jours ($clientName)",
      priority: NotificationPriority.urgent,
      category: NotificationCategory.business,
      requiresAction: true,
      actionData: {'action': 'send_reminder', 'clientName': clientName, 'invoiceId': invoiceId},
    );
  }

  // ✅ ORGANISATEUR - Notifications spécifiques
  Future<void> notifyTattooerApplicationReceived({
    required String organizerId,
    required String tattooerName,
    required String eventName,
    required String applicationId,
  }) async {
    await _createNotification(
      userId: organizerId,
      type: NotificationType.tattooerApplicationReceived,
      title: "Nouvelle candidature",
      message: "$tattooerName souhaite participer à \"$eventName\"",
      priority: NotificationPriority.high,
      category: NotificationCategory.events,
      requiresAction: true,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      actionData: {
        'action': 'review_application',
        'applicationId': applicationId,
        'tattooerName': tattooerName,
      },
    );
  }

  // ✅ CORE - Méthodes internes
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        await initialize();
        _isInitialized = true;
      } catch (e) {
        generateMockNotifications();
        _isInitialized = true;
      }
    }
  }

  Future<void> initialize() async {
    try {
      print('🔔 Initialisation du service de notifications enrichi...');
      
      try {
        await _messaging.requestPermission(alert: true, badge: true, sound: true);
        final token = await _messaging.getToken();
        if (token != null && _currentUserId != null) {
          await _saveTokenToFirestore(token);
        }
        
        await loadNotificationsFromFirestore();
        print('✅ Service de notifications Firebase initialisé');
      } catch (e) {
        print('❌ Erreur Firebase, utilisation mode factice: $e');
        generateMockNotifications();
      }
    } catch (e) {
      print('❌ Erreur critique initialisation: $e');
      generateMockNotifications();
    }
  }

  Future<void> _createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    NotificationPriority? priority,
    NotificationCategory? category,
    String? fullMessage,
    String? projectId,
    String? devisId,
    String? eventId,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? actionData,
    DateTime? expiresAt,
    bool? requiresAction,
  }) async {
    try {
      final notification = NotificationItem.create(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        fullMessage: fullMessage,
        date: DateTime.now(),
        type: type,
        priority: priority ?? NotificationPriority.medium,
        category: category ?? NotificationCategory.system,
        projectId: projectId,
        devisId: devisId,
        eventId: eventId,
        senderId: senderId,
        senderName: senderName,
        actionData: actionData,
        expiresAt: expiresAt,
        requiresAction: requiresAction ?? false,
      );

      // Sauvegarder dans Firestore
      await _firestore.collection('notifications').add(notification.toFirestore()..['userId'] = userId);

      // Ajouter au cache local si c'est l'utilisateur actuel
      if (userId == _currentUserId) {
        addNotification(notification);
      }

      print('✅ Notification créée: $title pour user $userId');
    } catch (e) {
      print('❌ Erreur création notification: $e');
    }
  }

  Future<void> loadNotificationsFromFirestore() async {
    try {
      if (_currentUserId == null) {
        generateMockNotifications();
        return;
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _notifications.clear();

      for (final doc in snapshot.docs) {
        try {
          final notification = NotificationItem.fromFirestore(doc.data(), doc.id);
          _notifications.add(notification);
        } catch (e) {
          print('❌ Erreur traitement notification ${doc.id}: $e');
        }
      }

      _unreadCount = _notifications.where((n) => !n.read).length;
      print('✅ ${_notifications.length} notifications chargées');
    } catch (e) {
      print('❌ Erreur chargement notifications: $e');
      generateMockNotifications();
    }
  }

  // ✅ COMPATIBLE: Méthodes Firebase existantes
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      if (_currentUserId != null) {
        await _firestore.collection('users').doc(_currentUserId!).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('❌ Erreur sauvegarde token: $e');
    }
  }

  Future<void> _updateReadStatusInFirestore(String notificationId) async {
    try {
      if (_currentUserId == null) return;
      
      final doc = await _firestore.collection('notifications').doc(notificationId).get();
      if (doc.exists && doc.data()?['userId'] == _currentUserId) {
        await doc.reference.update({'read': true});
      }
    } catch (e) {
      print('❌ Erreur mise à jour statut lu: $e');
    }
  }

  Future<void> _markAllAsReadInFirestore() async {
    try {
      if (_currentUserId == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('❌ Erreur marquage toutes lues: $e');
    }
  }

  // ✅ NOUVEAU: Getters enrichis pour filtrage
  List<NotificationItem> getNotificationsByPriority(NotificationPriority priority) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  List<NotificationItem> getActionRequiredNotifications() {
    return _notifications.where((n) => n.isActionRequired).toList();
  }

  List<NotificationItem> getExpiringNotifications() {
    return _notifications.where((n) {
      if (n.expiresAt == null) return false;
      final timeLeft = n.timeUntilExpiry;
      return timeLeft != null && timeLeft.inDays <= 3;
    }).toList();
  }

  void reset() {
    try {
      _notifications.clear();
      _unreadCount = 0;
      _isInitialized = false;
      print('🔄 Service de notifications réinitialisé');
    } catch (e) {
      print('Erreur reset: $e');
    }
  }
}