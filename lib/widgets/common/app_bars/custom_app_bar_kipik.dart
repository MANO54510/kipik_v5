// lib/widgets/common/app_bars/custom_app_bar_kipik.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/kipik_theme.dart';

/// AppBar universelle respectant le style global Kipik
/// 
/// Conserve exactement :
/// - Les couleurs KipikTheme (rouge, noir, blanc)
/// - La police PermanentMarker pour les titres
/// - Le style transparent/gradient existant
/// - La cohérence visuelle de l'app
class CustomAppBarKipik extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final bool showBurger;
  final bool showNotificationIcon;
  final VoidCallback? onNotificationPressed;
  final int notificationCount;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool useProStyle;
  final bool isCompact;

  const CustomAppBarKipik({
    Key? key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.showBurger = false,
    this.showNotificationIcon = false,
    this.onNotificationPressed,
    this.notificationCount = 0,
    this.actions,
    this.onBackPressed,
    this.useProStyle = false,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<CustomAppBarKipik> createState() => _CustomAppBarKipikState();

  @override
  Size get preferredSize => Size.fromHeight(isCompact ? 50 : kToolbarHeight);
}

class _CustomAppBarKipikState extends State<CustomAppBarKipik> 
    with TickerProviderStateMixin {
  
  late AnimationController _notificationController;
  late Animation<double> _notificationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Animation subtile pour les notifications (respecte le style Kipik)
    _notificationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _notificationAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _notificationController,
      curve: Curves.easeInOut,
    ));

    // Animation uniquement si notifications > 0
    if (widget.notificationCount > 0) {
      _notificationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CustomAppBarKipik oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.notificationCount > 0 && oldWidget.notificationCount == 0) {
      _notificationController.repeat(reverse: true);
    } else if (widget.notificationCount == 0 && oldWidget.notificationCount > 0) {
      _notificationController.stop();
      _notificationController.reset();
    }
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // CONSERVE le style transparent original Kipik
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: widget.preferredSize.height,
      title: _buildTitle(),
      centerTitle: true,
      leading: _buildLeading(context),
      actions: _buildActions(context),
      // Conserve le style système light
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  /// Titre avec la police PermanentMarker originale Kipik
  Widget _buildTitle() {
    if (widget.subtitle != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              // CONSERVE la police Kipik originale
              fontFamily: 'PermanentMarker',
              fontSize: widget.useProStyle ? 20 : 22,
              color: Colors.white,
              fontWeight: widget.useProStyle ? FontWeight.w400 : FontWeight.normal,
              // CONSERVE les ombres originales sauf en mode Pro
              shadows: widget.useProStyle ? null : [
                const Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          Text(
            widget.subtitle!,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto', // Police secondaire pour sous-titres
            ),
          ),
        ],
      );
    }

    return Text(
      widget.title,
      style: TextStyle(
        // CONSERVE exactement le style Kipik original
        fontFamily: 'PermanentMarker',
        fontSize: widget.useProStyle ? 20 : 22,
        color: Colors.white,
        fontWeight: widget.useProStyle ? FontWeight.w400 : FontWeight.normal,
        shadows: widget.useProStyle ? null : [
          const Shadow(
            color: Colors.black54,
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  /// Bouton leading respectant le style Kipik
  Widget? _buildLeading(BuildContext context) {
    if (widget.showBackButton) {
      if (widget.useProStyle) {
        // Style Pro avec container arrondi mais couleurs Kipik
        return Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            // Utilise la transparence blanche existante
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white, // CONSERVE le blanc Kipik
              size: 20,
            ),
            onPressed: widget.onBackPressed ?? () => _handleBackNavigation(context),
          ),
        );
      } else {
        // CONSERVE le style classique Kipik original
        return IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBackPressed ?? () => _handleBackNavigation(context),
        );
      }
    } else if (widget.showBurger) {
      if (widget.useProStyle) {
        return Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white, // CONSERVE le blanc Kipik
              size: 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        );
      } else {
        // CONSERVE le style original
        return IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        );
      }
    }
    return null;
  }

  /// Actions respectant le style Kipik
  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actionWidgets = [];
    
    // Bouton de notification avec style Kipik
    if (widget.showNotificationIcon) {
      actionWidgets.add(_buildNotificationButton());
    }
    
    // Actions personnalisées
    if (widget.actions != null) {
      if (widget.useProStyle) {
        // Applique le style Pro aux actions sans changer les couleurs
        actionWidgets.addAll(
          widget.actions!.map((action) {
            if (action is Container) {
              return action;
            }
            return Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: action,
            );
          }),
        );
      } else {
        actionWidgets.addAll(widget.actions!);
      }
    }
    
    return actionWidgets;
  }

  /// Bouton notification avec badge Kipik rouge
  Widget _buildNotificationButton() {
    Widget button;
    
    if (widget.useProStyle) {
      button = Container(
        margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white, // CONSERVE le blanc Kipik
                size: 24,
              ),
              onPressed: widget.onNotificationPressed ?? () => _handleNotifications(context),
            ),
            if (widget.notificationCount > 0) _buildNotificationBadge(),
          ],
        ),
      );
    } else {
      // CONSERVE exactement le style original
      button = Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: widget.onNotificationPressed ?? () => _handleNotifications(context),
          ),
          if (widget.notificationCount > 0) _buildNotificationBadge(),
        ],
      );
    }

    // Animation subtile si notifications
    if (widget.notificationCount > 0) {
      return AnimatedBuilder(
        animation: _notificationAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _notificationAnimation.value,
            child: button,
          );
        },
      );
    }

    return button;
  }

  /// Badge notification avec le rouge Kipik original
  Widget _buildNotificationBadge() {
    return Positioned(
      top: widget.useProStyle ? 8 : 8,
      right: widget.useProStyle ? 8 : 8,
      child: Container(
        padding: EdgeInsets.all(widget.useProStyle ? 4.0 : 2.0),
        decoration: BoxDecoration(
          // UTILISE le rouge Kipik original
          color: KipikTheme.rouge,
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        child: Text(
          widget.notificationCount > 9 ? '9+' : widget.notificationCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto', // Police system pour les badges
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Gestion navigation respectant l'architecture Kipik
  void _handleBackNavigation(BuildContext context) {
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // Fallback vers page d'accueil appropriée selon le contexte
        // Évite d'importer des pages spécifiques pour rester flexible
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      print('Erreur navigation back: $e');
      // Fallback silencieux
    }
  }

  /// Gestion notifications
  void _handleNotifications(BuildContext context) {
    try {
      // Tente la navigation vers les notifications
      Navigator.pushNamed(context, '/notifications');
    } catch (e) {
      // Fallback : SnackBar avec style Kipik
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.notificationCount} nouvelles notifications'),
          backgroundColor: KipikTheme.rouge, // UTILISE le rouge Kipik
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Extensions pour faciliter l'utilisation
extension CustomAppBarKipikStyles on CustomAppBarKipik {
  /// Style Pro rapide
  static CustomAppBarKipik pro({
    required String title,
    String? subtitle,
    bool showBackButton = false,
    bool showNotificationIcon = false,
    int notificationCount = 0,
    VoidCallback? onNotificationPressed,
    List<Widget>? actions,
    VoidCallback? onBackPressed,
  }) {
    return CustomAppBarKipik(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      showNotificationIcon: showNotificationIcon,
      notificationCount: notificationCount,
      onNotificationPressed: onNotificationPressed,
      actions: actions,
      onBackPressed: onBackPressed,
      useProStyle: true, // Active les containers arrondis
    );
  }

  /// Style Particulier classique Kipik
  static CustomAppBarKipik particulier({
    required String title,
    String? subtitle,
    bool showBackButton = false,
    bool showNotificationIcon = false,
    int notificationCount = 0,
    VoidCallback? onNotificationPressed,
    VoidCallback? onBackPressed,
  }) {
    return CustomAppBarKipik(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      showNotificationIcon: showNotificationIcon,
      notificationCount: notificationCount,
      onNotificationPressed: onNotificationPressed,
      onBackPressed: onBackPressed,
      useProStyle: false, // Conserve le style original
    );
  }
}