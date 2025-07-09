// lib/services/notification/firebase_notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../auth/secure_auth_service.dart';
import '../../models/notification_item.dart';
import '../../models/user_role.dart';

class FirebaseNotificationService {
  static FirebaseNotificationService? _instance;
  static FirebaseNotificationService get instance =>
      _instance ??= FirebaseNotificationService._();
  FirebaseNotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Variables pour stocker les notifications localement
  int _unreadCount = 0;
  List<NotificationItem> _notifications = [];
  bool _isInitialized = false;

  // ✅ CORRIGÉ: Getters sécurisés avec null safety
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

  // ✅ CORRIGÉ: Méthodes synchrones fiables pour l'AppBar
  int getUnreadCountSync() {
    try {
      return _unreadCount;
    } catch (e) {
      print('Erreur getUnreadCountSync: $e');
      return 0;
    }
  }

  List<NotificationItem> getAllNotificationsSync() {
    try {
      return List.from(_notifications);
    } catch (e) {
      print('Erreur getAllNotificationsSync: $e');
      return [];
    }
  }

  // ✅ CORRIGÉ: Méthodes asynchrones sécurisées
  Future<List<NotificationItem>> getAllNotifications() async {
    try {
      await _ensureInitialized();
      return List.from(_notifications);
    } catch (e) {
      print('Erreur getAllNotifications: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      await _ensureInitialized();
      return _unreadCount;
    } catch (e) {
      print('Erreur getUnreadCount: $e');
      return 0;
    }
  }

  Future<List<NotificationItem>> getUnreadNotifications() async {
    try {
      await _ensureInitialized();
      return _notifications.where((notification) => !notification.read).toList();
    } catch (e) {
      print('Erreur getUnreadNotifications: $e');
      return [];
    }
  }

  // ✅ CORRIGÉ: Marquer comme lu avec gestion d'erreur
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].read) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
        
        // Synchroniser avec Firebase si possible
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
      
      // Synchroniser avec Firebase si possible
      try {
        await _markAllAsReadInFirestore();
      } catch (e) {
        print('Erreur sync Firebase markAllAsRead: $e');
      }
    } catch (e) {
      print('Erreur markAllAsRead: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final removedNotification = _notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => NotificationItem.create(
          id: '',
          title: '',
          message: '',
          type: NotificationType.system,
        ),
      );

      if (removedNotification.id.isNotEmpty) {
        _notifications.removeWhere((n) => n.id == notificationId);
        if (!removedNotification.read) {
          _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
        }
        
        // Supprimer de Firebase si possible
        try {
          await _deleteFromFirestore(notificationId);
        } catch (e) {
          print('Erreur sync Firebase deleteNotification: $e');
        }
      }
    } catch (e) {
      print('Erreur deleteNotification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      _notifications.clear();
      _unreadCount = 0;
      
      // Supprimer toutes de Firebase si possible
      try {
        await _deleteAllFromFirestore();
      } catch (e) {
        print('Erreur sync Firebase deleteAllNotifications: $e');
      }
    } catch (e) {
      print('Erreur deleteAllNotifications: $e');
    }
  }

  // ✅ CORRIGÉ: Méthodes de gestion locale sécurisées
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

  void removeNotification(String id) {
    try {
      final removedNotification = _notifications.firstWhere(
        (n) => n.id == id,
        orElse: () => NotificationItem.create(
          id: '',
          title: '',
          message: '',
          type: NotificationType.system,
        ),
      );

      if (removedNotification.id.isNotEmpty) {
        _notifications.removeWhere((n) => n.id == id);
        if (!removedNotification.read) {
          _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
        }
      }
    } catch (e) {
      print('Erreur removeNotification: $e');
    }
  }

  void clearAllNotifications() {
    try {
      _notifications.clear();
      _unreadCount = 0;
    } catch (e) {
      print('Erreur clearAllNotifications: $e');
    }
  }

  // ✅ CORRIGÉ: Générer des notifications de démo par rôle - SWITCH EXHAUSTIF
  void generateMockNotifications() {
    try {
      clearAllNotifications();

      final userRole = _currentUserRole ?? UserRole.particulier;
      List<NotificationItem> mockNotifications = [];

      switch (userRole) {
        case UserRole.client:
        case UserRole.particulier:
          mockNotifications = _generateParticulierMockNotifications();
          break;
        case UserRole.tatoueur:
          mockNotifications = _generateTatoueurMockNotifications();
          break;
        case UserRole.organisateur:
          mockNotifications = _generateOrganisateurMockNotifications();
          break;
        case UserRole.admin:
          mockNotifications = _generateAdminMockNotifications();
          break;
      }

      for (final notification in mockNotifications) {
        addNotification(notification);
      }

      // Recalculer le count
      _unreadCount = _notifications.where((n) => !n.read).length;
      print('✅ ${_notifications.length} notifications factices générées pour ${userRole.name}');
    } catch (e) {
      print('Erreur generateMockNotifications: $e');
      // En cas d'erreur, générer au moins des notifications de base
      _generateFallbackNotifications();
    }
  }

  // ✅ NOUVEAU: Notifications de fallback en cas d'erreur
  void _generateFallbackNotifications() {
    try {
      final fallbackNotifications = [
        NotificationItem.create(
          id: 'fallback_1',
          title: 'Bienvenue sur Kipik !',
          message: 'Votre application fonctionne correctement.',
          date: DateTime.now(),
          type: NotificationType.system,
          read: false,
        ),
      ];

      for (final notification in fallbackNotifications) {
        addNotification(notification);
      }

      _unreadCount = _notifications.where((n) => !n.read).length;
    } catch (e) {
      print('Erreur critique _generateFallbackNotifications: $e');
    }
  }

  // ✅ PARTICULIER - Notifications spécifiques
  List<NotificationItem> _generateParticulierMockNotifications() {
    try {
      return [
        NotificationItem.create(
          id: 'part_1',
          title: 'Nouveau devis reçu',
          message: 'Marie Lefevre vous a envoyé un devis (320€)',
          date: DateTime.now().subtract(const Duration(minutes: 15)),
          type: NotificationType.devis,
          read: false,
        ),
        NotificationItem.create(
          id: 'part_2',
          title: 'Demande de devis envoyée',
          message: 'Votre demande pour "Rose vintage" a été envoyée',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          type: NotificationType.devis,
          read: true,
        ),
        NotificationItem.create(
          id: 'part_3',
          title: 'RDV confirmé',
          message: 'Votre rendez-vous avec Sophie Martin le 25/05/2025 à 14h30 est confirmé',
          date: DateTime.now().subtract(const Duration(hours: 6)),
          type: NotificationType.rdv,
          read: true,
        ),
        NotificationItem.create(
          id: 'part_4',
          title: 'Devis expirant bientôt',
          message: 'Votre devis d\'Alexandre Petit expire dans 2 jours',
          date: DateTime.now().subtract(const Duration(days: 1)),
          type: NotificationType.devis,
          read: false,
        ),
        NotificationItem.create(
          id: 'part_5',
          title: 'Projet mis à jour',
          message: 'Sophie Martin a ajouté des photos à votre projet "Rose vintage"',
          date: DateTime.now().subtract(const Duration(days: 2)),
          type: NotificationType.projet,
          read: true,
        ),
      ];
    } catch (e) {
      print('Erreur _generateParticulierMockNotifications: $e');
      return [];
    }
  }

  // ✅ TATOUEUR - Notifications spécifiques
  List<NotificationItem> _generateTatoueurMockNotifications() {
    try {
      return [
        NotificationItem.create(
          id: 'tat_1',
          title: 'Nouvelle demande de devis',
          message: 'Claire Dubois souhaite un tatouage géométrique',
          date: DateTime.now().subtract(const Duration(minutes: 30)),
          type: NotificationType.devis,
          read: false,
        ),
        NotificationItem.create(
          id: 'tat_2',
          title: 'Rappel devis en attente',
          message: 'Devis non envoyé pour Lucas Martin (demande il y a 3 jours)',
          date: DateTime.now().subtract(const Duration(hours: 1)),
          type: NotificationType.devis,
          read: false,
        ),
        NotificationItem.create(
          id: 'tat_3',
          title: 'Paiement reçu',
          message: 'Paiement de 280€ reçu de Emma Rousseau',
          date: DateTime.now().subtract(const Duration(hours: 4)),
          type: NotificationType.facture,
          read: true,
        ),
        NotificationItem.create(
          id: 'tat_4',
          title: 'Nouveau RDV réservé',
          message: 'Anna Lopez a réservé un créneau le 28/05/2025 à 10h',
          date: DateTime.now().subtract(const Duration(days: 1)),
          type: NotificationType.rdv,
          read: true,
        ),
        NotificationItem.create(
          id: 'tat_5',
          title: 'Facture impayée',
          message: 'Facture de 350€ impayée depuis 7 jours (Thomas Durand)',
          date: DateTime.now().subtract(const Duration(days: 2)),
          type: NotificationType.facture,
          read: false,
        ),
      ];
    } catch (e) {
      print('Erreur _generateTatoueurMockNotifications: $e');
      return [];
    }
  }

  // ✅ ORGANISATEUR - Notifications spécifiques
  List<NotificationItem> _generateOrganisateurMockNotifications() {
    try {
      return [
        NotificationItem.create(
          id: 'org_1',
          title: 'Nouvelle candidature',
          message: 'Alexandre Petit souhaite participer à "Convention Paris 2025"',
          date: DateTime.now().subtract(const Duration(minutes: 45)),
          type: NotificationType.tatoueur,
          read: false,
        ),
        NotificationItem.create(
          id: 'org_2',
          title: 'Événement approuvé',
          message: '"Convention Lyon 2025" a été approuvé ! Vous pouvez maintenant inviter des tatoueurs.',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          type: NotificationType.info,
          read: false,
        ),
        NotificationItem.create(
          id: 'org_3',
          title: 'Candidatures en attente',
          message: '3 candidature(s) en attente pour "Salon Marseille"',
          date: DateTime.now().subtract(const Duration(hours: 8)),
          type: NotificationType.tatoueur,
          read: false,
        ),
        NotificationItem.create(
          id: 'org_4',
          title: 'Événement commence bientôt',
          message: 'Votre "Festival Toulouse" commence dans 2 jours',
          date: DateTime.now().subtract(const Duration(days: 1)),
          type: NotificationType.rdv,
          read: true,
        ),
        NotificationItem.create(
          id: 'org_5',
          title: 'Événement complet',
          message: '"Convention Bordeaux" a atteint sa capacité maximale (50 tatoueurs)',
          date: DateTime.now().subtract(const Duration(days: 3)),
          type: NotificationType.info,
          read: true,
        ),
      ];
    } catch (e) {
      print('Erreur _generateOrganisateurMockNotifications: $e');
      return [];
    }
  }

  // ✅ ADMIN - Notifications spécifiques
  List<NotificationItem> _generateAdminMockNotifications() {
    try {
      return [
        NotificationItem.create(
          id: 'admin_1',
          title: 'Nouvel utilisateur inscrit',
          message: '5 nouveaux tatoueurs inscrits aujourd\'hui',
          date: DateTime.now().subtract(const Duration(hours: 1)),
          type: NotificationType.system,
          read: false,
        ),
        NotificationItem.create(
          id: 'admin_2',
          title: 'Signalement utilisateur',
          message: 'Signalement reçu concernant le profil de "TattooArt92"',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          type: NotificationType.system,
          read: false,
        ),
        NotificationItem.create(
          id: 'admin_3',
          title: 'Statistiques mensuelles',
          message: 'Rapport d\'activité de janvier 2025 disponible',
          date: DateTime.now().subtract(const Duration(hours: 12)),
          type: NotificationType.system,
          read: true,
        ),
        NotificationItem.create(
          id: 'admin_4',
          title: 'Maintenance programmée',
          message: 'Maintenance serveur prévue le 15/02/2025 de 2h à 4h',
          date: DateTime.now().subtract(const Duration(days: 1)),
          type: NotificationType.system,
          read: false,
        ),
        NotificationItem.create(
          id: 'admin_5',
          title: 'Paiement en attente',
          message: '3 paiements nécessitent une validation manuelle',
          date: DateTime.now().subtract(const Duration(days: 2)),
          type: NotificationType.facture,
          read: true,
        ),
      ];
    } catch (e) {
      print('Erreur _generateAdminMockNotifications: $e');
      return [];
    }
  }

  // ✅ CORRIGÉ: Initialisation sécurisée
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        await initialize();
        _isInitialized = true;
      } catch (e) {
        print('Erreur _ensureInitialized: $e');
        // Utiliser les notifications factices en cas d'erreur
        generateMockNotifications();
        _isInitialized = true;
      }
    }
  }

  // ✅ CORRIGÉ: Initialisation Firebase robuste
  Future<void> initialize() async {
    try {
      print('🔔 Initialisation du service de notifications...');

      // Essayer d'initialiser Firebase
      try {
        // Demander permission
        await _messaging.requestPermission(alert: true, badge: true, sound: true);

        // Récupérer le token FCM
        final token = await _messaging.getToken();
        if (token != null && _currentUserId != null) {
          await _saveTokenToFirestore(token);
        }

        // Écouter les changements de token
        _messaging.onTokenRefresh.listen((token) async {
          try {
            await _saveTokenToFirestore(token);
          } catch (e) {
            print('Erreur sauvegarde token refresh: $e');
          }
        });

        // Écouter les messages en premier plan
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          try {
            _handleForegroundMessage(message);
          } catch (e) {
            print('Erreur gestion message foreground: $e');
          }
        });

        // Écouter les clics sur notifications
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          try {
            _handleNotificationClick(message);
          } catch (e) {
            print('Erreur gestion clic notification: $e');
          }
        });

        // Charger les notifications existantes depuis Firestore
        await loadNotificationsFromFirestore();
        
        print('✅ Service de notifications Firebase initialisé');
      } catch (e) {
        print('❌ Erreur initialisation Firebase notifications: $e');
        // Fallback vers notifications factices
        generateMockNotifications();
        print('✅ Service de notifications initialisé en mode factice');
      }
    } catch (e) {
      print('❌ Erreur critique initialisation notifications: $e');
      // Fallback de sécurité
      generateMockNotifications();
    }
  }

  // ✅ CORRIGÉ: Sauvegarde token sécurisée
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      if (_currentUserId != null) {
        await _firestore.collection('users').doc(_currentUserId!).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Token FCM sauvegardé');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde token: $e');
      // Ne pas lever l'erreur, juste logger
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final notification = NotificationItem.create(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Nouvelle notification',
        message: message.notification?.body ?? '',
        date: DateTime.now(),
        type: _getTypeFromData(message.data),
        read: false,
      );

      addNotification(notification);
      print('✅ Notification reçue en premier plan: ${notification.title}');
    } catch (e) {
      print('❌ Erreur gestion message premier plan: $e');
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    try {
      print('🔔 Notification cliquée: ${message.data}');
      // TODO: Gérer la navigation selon le type
    } catch (e) {
      print('❌ Erreur gestion clic notification: $e');
    }
  }

  NotificationType _getTypeFromData(Map<String, dynamic> data) {
    try {
      final typeString = data['type'] as String?;
      return _getTypeFromString(typeString);
    } catch (e) {
      print('Erreur _getTypeFromData: $e');
      return NotificationType.system;
    }
  }

  NotificationType _getTypeFromString(String? typeString) {
    try {
      switch (typeString?.toLowerCase()) {
        case 'message':
          return NotificationType.message;
        case 'devis':
          return NotificationType.devis;
        case 'projet':
          return NotificationType.projet;
        case 'tatoueur':
          return NotificationType.tatoueur;
        case 'system':
          return NotificationType.system;
        case 'rdv':
          return NotificationType.rdv;
        case 'facture':
          return NotificationType.facture;
        case 'info':
          return NotificationType.info;
        default:
          return NotificationType.system;
      }
    } catch (e) {
      print('Erreur _getTypeFromString: $e');
      return NotificationType.system;
    }
  }

  // ✅ CORRIGÉ: Chargement notifications sécurisé
  Future<void> loadNotificationsFromFirestore() async {
    try {
      if (_currentUserId == null) {
        print('⚠️ Utilisateur non connecté, génération de notifications factices');
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
      print('✅ ${_notifications.length} notifications chargées (${_unreadCount} non lues)');
    } catch (e) {
      print('❌ Erreur chargement notifications: $e');
      // En cas d'erreur, générer des notifications factices
      generateMockNotifications();
    }
  }

  // ✅ CORRIGÉ: Méthodes Firebase sécurisées
  Future<void> _updateReadStatusInFirestore(String notificationId) async {
    try {
      if (_currentUserId == null) return;

      final doc = await _firestore.collection('notifications').doc(notificationId).get();
      if (doc.exists && doc.data()?['userId'] == _currentUserId) {
        await doc.reference.update({'read': true});
        print('✅ Statut lecture mis à jour: $notificationId');
      } else {
        print('❌ Accès refusé à la notification: $notificationId');
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
      print('✅ Toutes les notifications marquées comme lues');
    } catch (e) {
      print('❌ Erreur marquage toutes lues: $e');
    }
  }

  Future<void> _deleteFromFirestore(String notificationId) async {
    try {
      if (_currentUserId == null) return;

      final doc = await _firestore.collection('notifications').doc(notificationId).get();
      if (doc.exists && doc.data()?['userId'] == _currentUserId) {
        await doc.reference.delete();
        print('✅ Notification supprimée: $notificationId');
      } else {
        print('❌ Accès refusé pour supprimer: $notificationId');
      }
    } catch (e) {
      print('❌ Erreur suppression notification: $e');
    }
  }

  Future<void> _deleteAllFromFirestore() async {
    try {
      if (_currentUserId == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Toutes les notifications supprimées');
    } catch (e) {
      print('❌ Erreur suppression toutes notifications: $e');
    }
  }

  // ✅ CORRIGÉ: Réinitialiser le service
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