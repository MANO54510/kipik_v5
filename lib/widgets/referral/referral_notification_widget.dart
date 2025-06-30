// lib/widgets/referral/referral_notification_widget.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/kipik_theme.dart';

class ReferralNotificationWidget extends StatefulWidget {
  final String userId;

  const ReferralNotificationWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ReferralNotificationWidget> createState() => _ReferralNotificationWidgetState();
}

class _ReferralNotificationWidgetState extends State<ReferralNotificationWidget> {
  List<ReferralNotification> _notifications = [];
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: widget.userId)
          .where('type', isEqualTo: 'referral_reward')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final notifications = querySnapshot.docs
          .map((doc) => ReferralNotification.fromFirestore(doc))
          .toList();

      setState(() {
        _notifications = notifications;
        _hasUnread = notifications.any((n) => !n.read);
      });
    } catch (e) {
      print('Erreur lors du chargement des notifications: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index >= 0) {
          _notifications[index] = _notifications[index].copyWith(read: true);
        }
        _hasUnread = _notifications.any((n) => !n.read);
      });
    } catch (e) {
      print('Erreur lors du marquage comme lu: $e');
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: KipikTheme.rouge),
                    const SizedBox(width: 8),
                    const Text(
                      'Notifications de parrainage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_notifications.where((n) => !n.read).length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),
              // Notifications list
              Expanded(
                child: _notifications.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucune notification de parrainage',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _NotificationTile(
                            notification: notification,
                            onTap: () => _markAsRead(notification.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        IconButton(
          onPressed: _showNotifications,
          icon: Icon(
            Icons.notifications,
            color: KipikTheme.rouge,
          ),
        ),
        if (_hasUnread)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final ReferralNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.read ? Colors.white : Colors.blue.withOpacity(0.05),
        border: Border.all(
          color: notification.read ? Colors.grey[300]! : Colors.blue.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.green,
            size: 24,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 8),
            if (notification.promoCode != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KipikTheme.rouge.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Code: ${notification.promoCode}',
                  style: TextStyle(
                    color: KipikTheme.rouge,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}

class ReferralNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String? promoCode;
  final DateTime createdAt;
  final bool read;

  const ReferralNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.promoCode,
    required this.createdAt,
    required this.read,
  });

  factory ReferralNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReferralNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      promoCode: data['promoCode'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
    );
  }

  ReferralNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? promoCode,
    DateTime? createdAt,
    bool? read,
  }) {
    return ReferralNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      promoCode: promoCode ?? this.promoCode,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
    );
  }
}