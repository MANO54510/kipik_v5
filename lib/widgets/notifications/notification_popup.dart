// lib/widgets/notifications/notification_popup.dart

import 'package:flutter/material.dart';
import '../../models/notification_item.dart';
import '../../services/notification/firebase_notification_service.dart';
import '../../theme/kipik_theme.dart';

/// Popup de notification recentrée, avec le bouton « Tout marquer comme lu »  
/// placé juste en dessous du titre.
class NotificationPopup extends StatefulWidget {
  const NotificationPopup({super.key});

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> {
  late FirebaseNotificationService notificationService;
  List<NotificationItem> notifications = [];
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    notificationService = FirebaseNotificationService.instance;
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      notifications = notificationService.getAllNotifications();
      unreadCount = notificationService.getUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KipikTheme.rouge, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- En-tête avec titre + bouton en dessous ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                border: Border(
                  bottom: BorderSide(color: KipikTheme.rouge.withOpacity(0.3), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: KipikTheme.fontTitle,
                        ),
                      ),
                      Row(
                        children: [
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: KipikTheme.rouge,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          notificationService.markAllAsRead();
                          _loadNotifications();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Toutes les notifications ont été marquées comme lues'),
                              backgroundColor: KipikTheme.rouge,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: KipikTheme.rouge.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: KipikTheme.rouge.withOpacity(0.3)),
                          ),
                        ),
                        icon: const Icon(Icons.done_all, color: Colors.white70, size: 16),
                        label: const Text(
                          'Tout marquer comme lu',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // --- Corps : si aucune notification ou liste ---
            if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_off,
                      color: Colors.white.withOpacity(0.5),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune notification',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vous n\'avez aucune notification pour le moment',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(context, notification, index == notifications.length - 1);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationItem notification, bool isLast) {
    return InkWell(
      onTap: () {
        if (!notification.read) {
          notificationService.markAsRead(notification.id);
          _loadNotifications();
        }
        _handleNotificationTap(notification);
      },
      child: Container(
        decoration: BoxDecoration(
          color: notification.read 
              ? Colors.transparent 
              : KipikTheme.rouge.withOpacity(0.05),
          border: isLast ? null : Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône du type de notification
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notification.color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: notification.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                notification.icon, 
                color: notification.color, 
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Contenu de la notification
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + badge non lu
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: KipikTheme.rouge,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Message
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: notification.read 
                          ? Colors.white.withOpacity(0.6)
                          : Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Date et type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.formattedDate,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: notification.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getTypeLabel(notification.type),
                          style: TextStyle(
                            color: notification.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return 'MESSAGE';
      case NotificationType.devis:
        return 'DEVIS';
      case NotificationType.rdv:
        return 'RDV';
      case NotificationType.facture:
        return 'FACTURE';
      case NotificationType.info:
        return 'INFO';
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Gérer la navigation selon le type de notification
    switch (notification.type) {
      case NotificationType.message:
        _showPlaceholder('Messages', notification.projectId);
        break;
      case NotificationType.devis:
        _showPlaceholder('Devis', notification.projectId);
        break;
      case NotificationType.rdv:
        _showPlaceholder('Rendez-vous', notification.projectId);
        break;
      case NotificationType.facture:
        _showPlaceholder('Factures', notification.projectId);
        break;
      case NotificationType.info:
        _showPlaceholder('Informations', null);
        break;
    }
    Navigator.of(context).pop(); // Fermer le popup
  }

  void _showPlaceholder(String feature, String? projectId) {
    final message = projectId != null 
        ? 'Navigation vers $feature (Projet: $projectId) - En cours de développement'
        : 'Navigation vers $feature - En cours de développement';
        
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KipikTheme.rouge,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Affiche la popup de notifications centrée.
void showNotificationPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => const Center(child: NotificationPopup()),
  );
}