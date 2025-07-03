// lib/services/notification/firebase_notification_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../auth/secure_auth_service.dart'; // ✅ MIGRATION
import '../../models/notification_item.dart';
import '../../models/user_role.dart'; // ✅ MIGRATION

class FirebaseNotificationService {
  static FirebaseNotificationService? _instance;
  static FirebaseNotificationService get instance =>
      _instance ??= FirebaseNotificationService._();
  FirebaseNotificationService._(); // ✅ CORRIGÉ: Constructeur privé défini

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Variables pour stocker les notifications localement
  int _unreadCount = 0;
  List<NotificationItem> _notifications = [];

  // ✅ MIGRATION: Getters sécurisés
  String? get _currentUserId => SecureAuthService.instance.currentUserId;
  UserRole? get _currentUserRole => SecureAuthService.instance.currentUserRole;
  dynamic get _currentUser => SecureAuthService.instance.currentUser;

  // ✅ SÉCURITÉ: Vérification d'authentification obligatoire
  void _ensureAuthenticated() {
    if (_currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }
  }

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
      orElse: () => NotificationItem(
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
      orElse: () => NotificationItem(
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
    print('✅ ${_notifications.length} notifications factices générées');
  }

  // ✅ AJOUTÉ: S'assurer que les données sont initialisées
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
      _isInitialized = true;
    }
  }

  // ✅ MIGRATION: Initialisation Firebase avec SecureAuthService
  Future<void> initialize() async {
    try {
      print('🔔 Initialisation du service de notifications...');

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
      
      print('✅ Service de notifications initialisé');
    } catch (e) {
      print('❌ Erreur initialisation notifications: $e');
      // En cas d'erreur, utiliser les notifications factices
      generateMockNotifications();
    }
  }

  // ✅ MIGRATION: Sauvegarde token avec SecureAuthService
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
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    try {
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
      default:
        return Icons.notifications;
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
      default:
        return Colors.grey;
    }
  }

  // ✅ MIGRATION: Envoi notification avec SecureAuthService
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    NotificationType type = NotificationType.system,
    String? projectId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _ensureAuthenticated(); // ✅ Vérification sécurisée

      final data = {
        'type': type.name,
        'projectId': projectId,
        'sentBy': _currentUserId,
        'sentByRole': _currentUserRole?.name,
        ...?additionalData,
      };

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'type': type.name,
        'projectId': projectId,
        'sentBy': _currentUserId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notification envoyée à $userId: $title');
    } catch (e) {
      print('❌ Erreur envoi notification: $e');
    }
  }

  // ✅ MIGRATION: Chargement notifications avec SecureAuthService
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

  NotificationType _getTypeFromString(String? typeString) {
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
      default:
        return NotificationType.system;
    }
  }

  // ✅ SÉCURITÉ: Mise à jour statut avec vérification utilisateur
  Future<void> _updateReadStatusInFirestore(String notificationId) async {
    try {
      _ensureAuthenticated();

      // Vérifier que la notification appartient à l'utilisateur
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

  // ✅ SÉCURITÉ: Marquer toutes comme lues avec vérification utilisateur
  Future<void> _markAllAsReadInFirestore() async {
    try {
      _ensureAuthenticated();

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

  // ✅ SÉCURITÉ: Suppression avec vérification utilisateur
  Future<void> _deleteFromFirestore(String notificationId) async {
    try {
      _ensureAuthenticated();

      // Vérifier que la notification appartient à l'utilisateur
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

  // ✅ SÉCURITÉ: Suppression toutes avec vérification utilisateur
  Future<void> _deleteAllFromFirestore() async {
    try {
      _ensureAuthenticated();

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

  // ✅ NOUVEAU: Envoyer notification à tous les utilisateurs d'un rôle
  Future<void> sendNotificationToRole({
    required UserRole targetRole,
    required String title,
    required String body,
    NotificationType type = NotificationType.system,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _ensureAuthenticated();

      // Seuls les admins peuvent envoyer des notifications de masse
      if (_currentUserRole != UserRole.admin) {
        throw Exception('Seuls les administrateurs peuvent envoyer des notifications de masse');
      }

      // Récupérer tous les utilisateurs du rôle cible
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: targetRole.name)
          .get();

      final batch = _firestore.batch();
      int notificationCount = 0;

      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        
        batch.set(notificationRef, {
          'userId': userDoc.id,
          'title': title,
          'body': body,
          'type': type.name,
          'sentBy': _currentUserId,
          'sentByRole': _currentUserRole?.name,
          'data': additionalData ?? {},
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        notificationCount++;
      }

      await batch.commit();
      print('✅ $notificationCount notifications envoyées au rôle ${targetRole.name}');
    } catch (e) {
      print('❌ Erreur envoi notifications de masse: $e');
      rethrow;
    }
  }

  // ✅ NOUVEAU: Obtenir les statistiques personnalisées
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      await _ensureInitialized();

      final Map<String, dynamic> baseStats = {
        'total': _notifications.length,
        'unread': _unreadCount,
        'read': _notifications.length - _unreadCount,
        'messages': _notifications.where((n) => n.type == NotificationType.message).length,
        'devis': _notifications.where((n) => n.type == NotificationType.devis).length,
        'projets': _notifications.where((n) => n.type == NotificationType.projet).length,
        'tatoueurs': _notifications.where((n) => n.type == NotificationType.tatoueur).length,
        'system': _notifications.where((n) => n.type == NotificationType.system).length,
      };

      // Ajouter des stats avancées si connecté
      if (_currentUserId != null) {
        final today = DateTime.now();
        final todayNotifications = _notifications.where((n) => 
          n.date.day == today.day && 
          n.date.month == today.month && 
          n.date.year == today.year
        ).length;

        final weekNotifications = _notifications.where((n) => 
          today.difference(n.date).inDays <= 7
        ).length;

        final Map<String, dynamic> advancedStats = {
          'today': todayNotifications,
          'thisWeek': weekNotifications,
          'userId': _currentUserId!,
          'userRole': _currentUserRole?.name ?? 'unknown',
        };

        // Fusionner les maps
        baseStats.addAll(advancedStats);
      }

      return baseStats;
    } catch (e) {
      print('❌ Erreur stats notifications: $e');
      return {
        'total': 0,
        'unread': 0,
        'read': 0,
        'error': e.toString(),
      };
    }
  }

  // ✅ NOUVEAU: Nettoyer les anciennes notifications
  Future<void> cleanupOldNotifications({int daysOld = 30}) async {
    try {
      _ensureAuthenticated();

      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      final oldNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId)
          .where('createdAt', isLessThan: cutoffTimestamp)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Nettoyer aussi localement
      _notifications.removeWhere((n) => 
        DateTime.now().difference(n.date).inDays > daysOld
      );
      _unreadCount = _notifications.where((n) => !n.read).length;

      print('✅ ${oldNotifications.docs.length} anciennes notifications supprimées');
    } catch (e) {
      print('❌ Erreur nettoyage notifications: $e');
    }
  }

  // ✅ NOUVEAU: Méthode de diagnostic pour debug
  Future<void> debugNotificationService() async {
    print('🔍 DIAGNOSTIC FirebaseNotificationService:');
    
    try {
      print('  - User ID: ${_currentUserId ?? 'Non connecté'}');
      print('  - User Role: ${_currentUserRole?.name ?? 'Aucun'}');
      print('  - Initialisé: $_isInitialized');
      print('  - Notifications locales: ${_notifications.length}');
      print('  - Non lues: $_unreadCount');
      
      if (_currentUserId != null) {
        final stats = await getNotificationStats();
        print('  - Stats: $stats');
      }
    } catch (e) {
      print('  - Erreur: $e');
    }
  }

  // ✅ NOUVEAU: Réinitialiser le service (utile après déconnexion)
  void reset() {
    _notifications.clear();
    _unreadCount = 0;
    _isInitialized = false;
    print('🔄 Service de notifications réinitialisé');
  }
}