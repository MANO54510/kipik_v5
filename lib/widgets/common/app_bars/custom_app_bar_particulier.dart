// lib/widgets/common/app_bars/custom_app_bar_particulier.dart

import 'package:flutter/material.dart';
import '../../../pages/particulier/accueil_particulier_page.dart';
import '../../notifications/notification_badge.dart';
import '../../../services/notification/firebase_notification_service.dart';
import '../../notifications/notification_popup.dart';

class CustomAppBarParticulier extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showBurger;
  final bool showNotificationIcon;
  final bool redirectToHome;
  final VoidCallback? onBackButtonPressed;

  const CustomAppBarParticulier({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showBurger = false,
    this.showNotificationIcon = false,
    this.redirectToHome = false,
    this.onBackButtonPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBarParticulier> createState() => _CustomAppBarParticulierState();
}

class _CustomAppBarParticulierState extends State<CustomAppBarParticulier> {
  final FirebaseNotificationService _notificationService = FirebaseNotificationService.instance;
  bool _isInitialized = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (!_isInitialized && mounted) {
      try {
        await _notificationService.initialize();
        _isInitialized = true;
        _updateUnreadCount();
      } catch (e) {
        print('Erreur initialisation notifications: $e');
        // En cas d'erreur Firebase, utiliser les notifications factices
        _notificationService.generateMockNotifications();
        _isInitialized = true;
        _updateUnreadCount();
      }
    }
  }

  void _updateUnreadCount() {
    if (mounted) {
      try {
        final count = _notificationService.getUnreadCountSync();
        if (count != _unreadCount) {
          setState(() {
            _unreadCount = count;
          });
        }
      } catch (e) {
        print('Erreur récupération count: $e');
        if (mounted) {
          setState(() {
            _unreadCount = 0;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'PermanentMarker',
          fontSize: 22,
        ),
      ),
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                try {
                  if (widget.onBackButtonPressed != null) {
                    widget.onBackButtonPressed!();
                  } else if (widget.redirectToHome) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const AccueilParticulierPage(),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print('Erreur navigation back: $e');
                }
              },
            )
          : null,
      actions: [
        if (widget.showNotificationIcon)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  try {
                    // Mettre à jour le count avant d'ouvrir
                    _updateUnreadCount();
                    showNotificationPopup(context);
                  } catch (e) {
                    print('Erreur ouverture popup notifications: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible d\'ouvrir les notifications'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: NotificationBadge(count: _unreadCount),
                ),
            ],
          ),
        if (widget.showBurger)
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                try {
                  Scaffold.of(context).openEndDrawer();
                } catch (e) {
                  print('Erreur ouverture drawer: $e');
                }
              },
            ),
          ),
      ],
    );
  }
}