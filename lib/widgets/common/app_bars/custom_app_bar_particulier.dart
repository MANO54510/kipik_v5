// lib/widgets/common/app_bars/custom_app_bar_particulier.dart

import 'package:flutter/material.dart';
import '../../../theme/kipik_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (!_isInitialized) {
      try {
        await _notificationService.initialize();
        _isInitialized = true;
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print('Erreur initialisation notifications: $e');
        // En cas d'erreur Firebase, utiliser les notifications factices
        _notificationService.generateMockNotifications();
        _isInitialized = true;
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser un StreamBuilder ou setState pour réactualiser le count
    return StreamBuilder<Object>(
      stream: Stream.periodic(const Duration(seconds: 2)), // Refresh toutes les 2 secondes
      builder: (context, snapshot) {
        // Utiliser la méthode synchrone qui existe dans votre service
        final int unreadCount = _notificationService.getUnreadCountSync();

        return AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: KipikTheme.fontTitle,
              fontSize: 22,
            ),
          ),
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
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
                      // Afficher le popup des notifications
                      showNotificationPopup(context);
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: NotificationBadge(count: unreadCount),
                    ),
                ],
              ),
            if (widget.showBurger)
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
          ],
        );
      },
    );
  }
}