// lib/services/notification/firebase_notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../auth/auth_service.dart';
import '../../models/notification_item.dart';

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

  // ✅ CORRIGÉ: Méthodes asynchrones pour compatibilité avec la page
  Future<List<NotificationItem>> getAllNotifications() async {
    await _ensureInitialized();
    return List.from(_notifications);
  }

  Future<int> getUnreadCount() async {
    await _ensureInitialized();
    return _unreadCount;
  }

  Future<List<NotificationItem>> getUnreadNotifications() async {
    await _ensureInitialized();
    return _notifications.where((notification) => !notification.read).toList();
  }

  // ✅ CORRIGÉ: Méthodes asynchrones
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].read) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      // Synchroniser avec Firebase
      await _updateReadStatusInFirestore(notificationId);
    }
  }

  Future<void> markAllAsRead() async {
    _unreadCount = 0;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].read) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
    }
    // Synchroniser avec Firebase
    await _markAllAsReadInFirestore();
  }

  Future<void> deleteNotification(String notificationId) async {
    final removedNotification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse:
          () => NotificationItem(
            id: '',
            title: '',
            message: '',
            date: DateTime.now(),
            icon: Icons.notifications,
            color: Colors.grey,
            type: NotificationType.system,
          ),
    );

    if (removedNotification.id.isNotEmpty) {
      _notifications.removeWhere((n) => n.id == notificationId);
      if (!removedNotification.read) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }
      // Supprimer de Firebase
      await _deleteFromFirestore(notificationId);
    }
  }

  Future<void> deleteAllNotifications() async {
    _notifications.clear();
    _unreadCount = 0;
    // Supprimer toutes de Firebase
    await _deleteAllFromFirestore();
  }

  // ✅ AJOUTÉ: Méthodes de compatibilité synchrones pour usage interne
  int getUnreadCountSync() => _unreadCount;
  List<NotificationItem> getAllNotificationsSync() => List.from(_notifications);

  // Méthodes de gestion des notifications
  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    if (!notification.read) {
      _unreadCount++;
    }
  }

  void removeNotification(String id) {
    final removedNotification = _notifications.firstWhere(
      (n) => n.id == id,
      orElse:
          () => NotificationItem(
            id: '',
            title: '',
            message: '',
            date: DateTime.now(),
            icon: Icons.notifications,
            color: Colors.grey,
            type: NotificationType.system,
          ),
    );

    if (removedNotification.id.isNotEmpty) {
      _notifications.removeWhere((n) => n.id == id);
      if (!removedNotification.read) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }
    }
  }

  void clearAllNotifications() {
    _notifications.clear();
    _unreadCount = 0;
  }

  // ✅ CORRIGÉ: Générer des notifications compatibles avec NotificationType
  void generateMockNotifications() {
    clearAllNotifications();

    final mockNotifications = [
      NotificationItem(
        id: 'mock_1',
        title: 'Nouveau message de Marie Lefevre',
        message:
            'Concernant votre projet "Mandala sur l\'épaule" - J\'ai quelques questions sur le placement.',
        fullMessage:
            'Bonjour,\n\nConcernant votre projet "Mandala sur l\'épaule", j\'ai quelques questions importantes sur le placement exact que vous souhaitez. Pourrions-nous planifier un rendez-vous pour en discuter en détail ?\n\nCordialement,\nMarie Lefevre',
        date: DateTime.now().subtract(const Duration(minutes: 15)),
        icon: Icons.chat,
        color: Colors.blue,
        type: NotificationType.message,
        read: false,
      ),
      NotificationItem(
        id: 'mock_2',
        title: 'Devis reçu - Tatouage géométrique',
        message:
            'Alexandre Petit vous a envoyé un devis détaillé. Montant: 320€',
        fullMessage:
            'Devis détaillé pour votre projet de tatouage géométrique :\n\n- Design personnalisé : 120€\n- Réalisation (3h) : 180€\n- Matériel : 20€\n\nTotal : 320€\n\nValidité : 30 jours',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        icon: Icons.receipt,
        color: Colors.green,
        type: NotificationType.devis,
        read: false,
      ),
      NotificationItem(
        id: 'mock_3',
        title: 'RDV confirmé - 25 mai 2025',
        message: 'Votre rendez-vous avec Sophie Martin à 14h30 est confirmé.',
        date: DateTime.now().subtract(const Duration(hours: 6)),
        icon: Icons.event,
        color: Colors.orange,
        type: NotificationType.system,
        read: true,
      ),
      NotificationItem(
        id: 'mock_4',
        title: 'Projet mis à jour',
        message:
            'Sophie Martin a ajouté des photos à votre projet "Rose vintage".',
        date: DateTime.now().subtract(const Duration(days: 1)),
        icon: Icons.art_track,
        color: Colors.purple,
        type: NotificationType.projet,
        read: true,
      ),
      NotificationItem(
        id: 'mock_5',
        title: 'Nouveau tatoueur disponible',
        message: 'Lucas Dubois vient de rejoindre Kipik dans votre région.',
        date: DateTime.now().subtract(const Duration(days: 2)),
        icon: Icons.person,
        color: Colors.teal,
        type: NotificationType.tatoueur,
        read: false,
      ),
    ];

    for (final notification in mockNotifications) {
      addNotification(notification);
    }

    // Recalculer le count
    _unreadCount = _notifications.where((n) => !n.read).length;
  }

  // ✅ AJOUTÉ: S'assurer que les données sont initialisées
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
      _isInitialized = true;
    }
  }

  // Initialisation Firebase
  Future<void> initialize() async {
    try {
      // Demander permission
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // Récupérer le token FCM
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Écouter les changements de token
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // Écouter les messages en premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Écouter les clics sur notifications
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message);
      });

      // Charger les notifications existantes depuis Firestore
      await loadNotificationsFromFirestore();
    } catch (e) {
      print('Erreur initialisation notifications: $e');
      // En cas d'erreur, utiliser les notifications factices
      generateMockNotifications();
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur sauvegarde token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Nouvelle notification',
      message: message.notification?.body ?? '',
      date: DateTime.now(),
      icon: _getIconFromType(_getTypeFromData(message.data)),
      color: _getColorFromType(_getTypeFromData(message.data)),
      type: _getTypeFromData(message.data),
      read: false,
    );

    addNotification(notification);
  }

  void _handleNotificationClick(RemoteMessage message) {
    print('Notification cliquée: ${message.data}');
    // Gérer la navigation selon le type
  }

  NotificationType _getTypeFromData(Map<String, dynamic> data) {
    final typeString = data['type'] as String?;
    return _getTypeFromString(typeString);
  }

  // ✅ AJOUTÉ: Méthodes utilitaires pour icônes et couleurs
  IconData _getIconFromType(NotificationType type) {
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

  Color _getColorFromType(NotificationType type) {
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

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    NotificationType type = NotificationType.system,
    String? projectId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final data = {
        'type': type.name,
        'projectId': projectId,
        ...?additionalData,
      };

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'type': type.name,
        'projectId': projectId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur envoi notification: $e');
    }
  }

  Future<void> loadNotificationsFromFirestore() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        generateMockNotifications();
        return;
      }

      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();

      _notifications.clear();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['createdAt'] as Timestamp?;
        final type = _getTypeFromString(data['type']);

        final notification = NotificationItem(
          id: doc.id,
          title: data['title'] ?? '',
          message: data['body'] ?? '',
          fullMessage: data['fullMessage'],
          date: timestamp?.toDate() ?? DateTime.now(),
          icon: _getIconFromType(type),
          color: _getColorFromType(type),
          type: type,
          read: data['read'] ?? false,
        );

        _notifications.add(notification);
      }

      _unreadCount = _notifications.where((n) => !n.read).length;
    } catch (e) {
      print('Erreur chargement notifications: $e');
      // En cas d'erreur, générer des notifications factices
      generateMockNotifications();
    }
  }

  NotificationType _getTypeFromString(String? typeString) {
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
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }

  Future<void> _updateReadStatusInFirestore(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('Erreur mise à jour statut lu: $e');
    }
  }

  Future<void> _markAllAsReadInFirestore() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .where('read', isEqualTo: false)
              .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Erreur marquage toutes lues: $e');
    }
  }

  // ✅ AJOUTÉ: Méthodes de suppression Firebase
  Future<void> _deleteFromFirestore(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Erreur suppression notification: $e');
    }
  }

  Future<void> _deleteAllFromFirestore() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Erreur suppression toutes notifications: $e');
    }
  }

  // Obtenir les statistiques
  Map<String, int> getNotificationStats() {
    return {
      'total': _notifications.length,
      'unread': getUnreadCountSync(),
      'read': _notifications.length - getUnreadCountSync(),
      'messages':
          _notifications
              .where((n) => n.type == NotificationType.message)
              .length,
      'devis':
          _notifications.where((n) => n.type == NotificationType.devis).length,
      'projets':
          _notifications.where((n) => n.type == NotificationType.projet).length,
      'tatoueurs':
          _notifications
              .where((n) => n.type == NotificationType.tatoueur)
              .length,
      'system':
          _notifications.where((n) => n.type == NotificationType.system).length,
    };
  }
}
