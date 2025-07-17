// lib/widgets/common/app_bars/universal_app_bar_kipik.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/kipik_theme.dart';
import '../../../models/user_role.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../notifications/notification_popup.dart';
import '../../notifications/notification_badge.dart';
import '../../../services/notification/firebase_notification_service.dart';

/// AppBar UNIVERSELLE pour toute l'application Kipik
/// 
/// ✅ Remplace TOUS les autres AppBars
/// ✅ Navigation sécurisée par rôle
/// ✅ Intégration notifications complète
/// ✅ Style cohérent Kipik (PermanentMarker + KipikTheme)
class UniversalAppBarKipik extends StatefulWidget implements PreferredSizeWidget {
  // === PARAMÈTRES OBLIGATOIRES ===
  final String title;
  
  // === PARAMÈTRES DE NAVIGATION ===
  final String? subtitle;
  final bool showBackButton;
  final bool showDrawer;
  final VoidCallback? onBackPressed;
  
  // === PARAMÈTRES NOTIFICATIONS ===
  final bool showNotificationIcon;
  final VoidCallback? onNotificationPressed;
  
  // === PARAMÈTRES ACTIONS ===
  final List<Widget>? actions;
  final Widget? searchAction;
  final Widget? quickAction;
  
  // === PARAMÈTRES STYLE ===
  final bool useProStyle;
  final bool isCompact;
  final Color? backgroundColor;
  
  // === PARAMÈTRES AVATAR ===
  final bool showUserAvatar;
  final String? userImageUrl;
  
  const UniversalAppBarKipik({
    Key? key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.showDrawer = false,
    this.onBackPressed,
    this.showNotificationIcon = true,
    this.onNotificationPressed,
    this.actions,
    this.searchAction,
    this.quickAction,
    this.useProStyle = false,
    this.isCompact = false,
    this.backgroundColor,
    this.showUserAvatar = false,
    this.userImageUrl,
  }) : super(key: key);

  @override
  State<UniversalAppBarKipik> createState() => _UniversalAppBarKipikState();

  @override
  Size get preferredSize => Size.fromHeight(isCompact ? 50 : kToolbarHeight);
}

class _UniversalAppBarKipikState extends State<UniversalAppBarKipik> 
    with TickerProviderStateMixin {
  
  late AnimationController _notificationController;
  late Animation<double> _notificationAnimation;
  final FirebaseNotificationService _notificationService = FirebaseNotificationService.instance;
  
  int _unreadCount = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeNotifications();
  }

  void _initializeAnimations() {
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
  }

  Future<void> _initializeNotifications() async {
    if (!_isInitialized && mounted) {
      try {
        await _notificationService.initialize();
        _isInitialized = true;
        _updateUnreadCount();
      } catch (e) {
        print('Erreur initialisation notifications: $e');
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
          
          // Animation si nouvelles notifications
          if (count > 0 && _unreadCount == 0) {
            _notificationController.repeat(reverse: true);
          } else if (count == 0 && _unreadCount > 0) {
            _notificationController.stop();
            _notificationController.reset();
          }
        }
      } catch (e) {
        print('Erreur récupération count: $e');
      }
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
      backgroundColor: widget.backgroundColor ?? Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: widget.preferredSize.height,
      title: _buildTitle(),
      centerTitle: true,
      leading: _buildLeading(context),
      actions: _buildActions(context),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  /// === TITRE AVEC STYLE KIPIK ===
  Widget _buildTitle() {
    if (widget.subtitle != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: TextStyle(
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
          ),
          Text(
            widget.subtitle!,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      );
    }

    return Text(
      widget.title,
      style: TextStyle(
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

  /// === BOUTON LEADING (BACK/DRAWER) ===
  Widget? _buildLeading(BuildContext context) {
    if (widget.showBackButton) {
      return _buildStyledButton(
        icon: widget.useProStyle ? Icons.arrow_back_ios_new : Icons.arrow_back,
        iconSize: widget.useProStyle ? 20 : 24,
        onPressed: widget.onBackPressed ?? () => _handleSecureBackNavigation(context),
      );
    } else if (widget.showDrawer) {
      return _buildStyledButton(
        icon: Icons.menu,
        iconSize: 24,
        onPressed: () => _handleSecureDrawerOpen(context),
      );
    }
    return null;
  }

  /// === ACTIONS COMPLÈTES ===
  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actionWidgets = [];
    
    // Action de recherche
    if (widget.searchAction != null) {
      actionWidgets.add(_wrapActionWithStyle(widget.searchAction!));
    }
    
    // Action rapide
    if (widget.quickAction != null) {
      actionWidgets.add(_wrapActionWithStyle(widget.quickAction!));
    }
    
    // Notifications
    if (widget.showNotificationIcon) {
      actionWidgets.add(_buildNotificationButton());
    }
    
    // Avatar utilisateur
    if (widget.showUserAvatar) {
      actionWidgets.add(_buildUserAvatar());
    }
    
    // Actions personnalisées
    if (widget.actions != null) {
      actionWidgets.addAll(
        widget.actions!.map((action) => _wrapActionWithStyle(action)),
      );
    }
    
    // Drawer à droite
    if (widget.showDrawer) {
      actionWidgets.add(_buildStyledButton(
        icon: Icons.menu,
        iconSize: 24,
        onPressed: () => _handleSecureDrawerOpen(context),
        isRightAction: true,
      ));
    }
    
    return actionWidgets;
  }

  /// === BOUTON STYLÉ UNIVERSEL ===
  Widget _buildStyledButton({
    required IconData icon,
    required VoidCallback onPressed,
    double iconSize = 24,
    bool isRightAction = false,
  }) {
    if (widget.useProStyle) {
      return Container(
        margin: EdgeInsets.only(
          left: isRightAction ? 0 : 16,
          right: isRightAction ? 16 : 0,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: iconSize),
          onPressed: onPressed,
        ),
      );
    } else {
      return IconButton(
        icon: Icon(icon, color: Colors.white, size: iconSize),
        onPressed: onPressed,
      );
    }
  }

  /// === WRAPPER POUR ACTIONS PERSONNALISÉES ===
  Widget _wrapActionWithStyle(Widget action) {
    if (!widget.useProStyle || action is Container) {
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
  }

  /// === BOUTON NOTIFICATIONS AVEC BADGE ===
  Widget _buildNotificationButton() {
    Widget button = Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            widget.useProStyle ? Icons.notifications_outlined : Icons.notifications,
            color: Colors.white,
            size: 24,
          ),
          onPressed: widget.onNotificationPressed ?? () => _handleNotifications(context),
        ),
        if (_unreadCount > 0)
          Positioned(
            top: widget.useProStyle ? 8 : 8,
            right: widget.useProStyle ? 8 : 8,
            child: NotificationBadge(count: _unreadCount),
          ),
      ],
    );

    if (widget.useProStyle) {
      button = Container(
        margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: button,
      );
    }

    // Animation si notifications
    if (_unreadCount > 0) {
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

  /// === AVATAR UTILISATEUR ===
  Widget _buildUserAvatar() {
    final authService = SecureAuthService.instance;
    final user = authService.currentUser;
    
    Widget avatar = CircleAvatar(
      radius: 16,
      backgroundColor: KipikTheme.rouge.withOpacity(0.2),
      backgroundImage: widget.userImageUrl != null 
          ? NetworkImage(widget.userImageUrl!) 
          : null,
      child: widget.userImageUrl == null
          ? Text(
              user?['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _showUserMenu(context),
        child: widget.useProStyle 
            ? Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: avatar,
              )
            : avatar,
      ),
    );
  }

  /// === NAVIGATION SÉCURISÉE BACK ===
  void _handleSecureBackNavigation(BuildContext context) {
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // Redirection sécurisée vers la home de l'utilisateur
        _redirectToUserHome(context);
      }
    } catch (e) {
      print('Erreur navigation back: $e');
      _redirectToUserHome(context);
    }
  }

  /// === OUVERTURE DRAWER SÉCURISÉE ===
  void _handleSecureDrawerOpen(BuildContext context) {
    try {
      final authService = SecureAuthService.instance;
      if (!authService.isAuthenticated) {
        _redirectToLogin(context);
        return;
      }
      
      // Vérifier que l'utilisateur peut accéder au drawer
      final role = authService.currentUserRole;
      if (role == null) {
        _redirectToLogin(context);
        return;
      }
      
      Scaffold.of(context).openEndDrawer();
    } catch (e) {
      print('Erreur ouverture drawer: $e');
      _showSecurityError(context);
    }
  }

  /// === GESTION NOTIFICATIONS ===
  void _handleNotifications(BuildContext context) {
    try {
      _updateUnreadCount();
      showNotificationPopup(context);
    } catch (e) {
      print('Erreur ouverture notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir les notifications'),
          backgroundColor: KipikTheme.rouge,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// === MENU UTILISATEUR ===
  void _showUserMenu(BuildContext context) {
    final authService = SecureAuthService.instance;
    final user = authService.currentUser;
    final role = authService.currentUserRole;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: Text(
                user?['name'] ?? 'Utilisateur',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                role?.name ?? 'Rôle inconnu',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _navigateToSettings(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: KipikTheme.rouge),
              title: const Text('Déconnexion', style: TextStyle(color: KipikTheme.rouge)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// === REDIRECTION SÉCURISÉE VERS HOME ===
  void _redirectToUserHome(BuildContext context) {
    final authService = SecureAuthService.instance;
    final role = authService.currentUserRole;
    
    if (role == null) {
      _redirectToLogin(context);
      return;
    }
    
    String homeRoute;
    switch (role) {
      case UserRole.client:
      case UserRole.particulier:
        homeRoute = '/particulier/dashboard';
        break;
      case UserRole.tatoueur:
        homeRoute = '/pro/dashboard';
        break;
      case UserRole.admin:
        homeRoute = '/admin/dashboard';
        break;
      case UserRole.organisateur:
        homeRoute = '/organisateur/dashboard';
        break;
    }
    
    Navigator.pushNamedAndRemoveUntil(
      context,
      homeRoute,
      (route) => false,
    );
  }

  /// === REDIRECTION LOGIN ===
  void _redirectToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  /// === NAVIGATION PARAMÈTRES ===
  void _navigateToSettings(BuildContext context) {
    final authService = SecureAuthService.instance;
    final role = authService.currentUserRole;
    
    String settingsRoute;
    switch (role) {
      case UserRole.client:
      case UserRole.particulier:
        settingsRoute = '/particulier/parametres';
        break;
      case UserRole.tatoueur:
        settingsRoute = '/pro/parametres';
        break;
      case UserRole.admin:
        settingsRoute = '/admin/parametres';
        break;
      case UserRole.organisateur:
        settingsRoute = '/organisateur/parametres';
        break;
      default:
        settingsRoute = '/parametres';
    }
    
    Navigator.pushNamed(context, settingsRoute);
  }

  /// === DÉCONNEXION ===
  void _handleLogout(BuildContext context) async {
    try {
      await SecureAuthService.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/welcome',
        (route) => false,
      );
    } catch (e) {
      print('Erreur déconnexion: $e');
      _showSecurityError(context);
    }
  }

  /// === ERREUR SÉCURITÉ ===
  void _showSecurityError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erreur de sécurité - Veuillez vous reconnecter'),
        backgroundColor: KipikTheme.rouge,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

/// === EXTENSIONS POUR SIMPLIFIER L'USAGE ===
extension UniversalAppBarKipikStyles on UniversalAppBarKipik {
  /// Style Particulier
  static UniversalAppBarKipik particulier({
    required String title,
    String? subtitle,
    bool showBackButton = false,
    bool showNotificationIcon = true,
    bool showDrawer = false,
    bool showUserAvatar = false,
    VoidCallback? onBackPressed,
    VoidCallback? onNotificationPressed,
    List<Widget>? actions,
    Widget? searchAction,
    Widget? quickAction,
  }) {
    return UniversalAppBarKipik(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      showNotificationIcon: showNotificationIcon,
      showDrawer: showDrawer,
      showUserAvatar: showUserAvatar,
      onBackPressed: onBackPressed,
      onNotificationPressed: onNotificationPressed,
      actions: actions,
      searchAction: searchAction,
      quickAction: quickAction,
      useProStyle: false,
    );
  }

  /// Style Pro
  static UniversalAppBarKipik pro({
    required String title,
    String? subtitle,
    bool showBackButton = false,
    bool showNotificationIcon = true,
    bool showDrawer = false,
    bool showUserAvatar = true,
    VoidCallback? onBackPressed,
    VoidCallback? onNotificationPressed,
    List<Widget>? actions,
    Widget? searchAction,
    Widget? quickAction,
  }) {
    return UniversalAppBarKipik(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      showNotificationIcon: showNotificationIcon,
      showDrawer: showDrawer,
      showUserAvatar: showUserAvatar,
      onBackPressed: onBackPressed,
      onNotificationPressed: onNotificationPressed,
      actions: actions,
      searchAction: searchAction,
      quickAction: quickAction,
      useProStyle: true,
    );
  }

  /// Style Admin
  static UniversalAppBarKipik admin({
    required String title,
    String? subtitle,
    bool showBackButton = false,
    bool showNotificationIcon = true,
    bool showDrawer = true,
    bool showUserAvatar = true,
    VoidCallback? onBackPressed,
    VoidCallback? onNotificationPressed,
    List<Widget>? actions,
    Widget? searchAction,
  }) {
    return UniversalAppBarKipik(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      showNotificationIcon: showNotificationIcon,
      showDrawer: showDrawer,
      showUserAvatar: showUserAvatar,
      onBackPressed: onBackPressed,
      onNotificationPressed: onNotificationPressed,
      actions: actions,
      searchAction: searchAction,
      useProStyle: true,
      backgroundColor: Colors.black.withOpacity(0.8),
    );
  }

  /// Style Organisateur
  static UniversalAppBarKipik organisateur({
    required String title,
    String? subtitle,
    bool showBackButton = false,
    bool showNotificationIcon = true,
    bool showDrawer = true,
    bool showUserAvatar = true,
    VoidCallback? onBackPressed,
    VoidCallback? onNotificationPressed,
    List<Widget>? actions,
    Widget? searchAction,
    Widget? quickAction,
  }) {
    return UniversalAppBarKipik(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      showNotificationIcon: showNotificationIcon,
      showDrawer: showDrawer,
      showUserAvatar: showUserAvatar,
      onBackPressed: onBackPressed,
      onNotificationPressed: onNotificationPressed,
      actions: actions,
      searchAction: searchAction,
      quickAction: quickAction,
      useProStyle: true,
    );
  }
}