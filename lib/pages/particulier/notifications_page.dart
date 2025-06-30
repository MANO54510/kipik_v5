import 'package:flutter/material.dart';
import 'dart:math';
import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../theme/kipik_theme.dart';
import '../../models/notification_item.dart';
import '../../services/notification/firebase_notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FirebaseNotificationService _notificationService;
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  
  // Liste des images de fond disponibles
  final List<String> _backgroundImages = [
    'assets/background_charbon.png',
    'assets/background_tatoo1.png',
    'assets/background_tatoo2.png',
    'assets/background_tatoo3.png',
  ];
  
  // Variable pour stocker l'image de fond sélectionnée aléatoirement
  late String _selectedBackground;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _notificationService = FirebaseNotificationService.instance;
    _loadNotifications();
    
    // Sélection aléatoire de l'image de fond
    _selectedBackground = _backgroundImages[Random().nextInt(_backgroundImages.length)];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Charger les notifications depuis Firebase
      final notifications = await _notificationService.getAllNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications(); // Recharger les notifications
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Toutes les notifications ont été marquées comme lues'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'OK',
            textColor: KipikTheme.rouge,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors du marquage des notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAllNotifications() async {
    // Afficher une boîte de dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Supprimer toutes les notifications',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PermanentMarker',
          ),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les notifications ? Cette action est irréversible.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _notificationService.deleteAllNotifications();
        await _loadNotifications(); // Recharger les notifications
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Toutes les notifications ont été supprimées'),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        print('Erreur lors de la suppression: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleNotificationAction(NotificationItem notification) async {
    // Marquer comme lu
    if (!notification.read) {
      try {
        await _notificationService.markAsRead(notification.id);
        setState(() {
          // Mettre à jour localement
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = NotificationItem(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              fullMessage: notification.fullMessage,
              date: notification.date,
              icon: notification.icon,
              color: notification.color,
              type: notification.type,
              read: true,
            );
          }
        });
      } catch (e) {
        print('Erreur lors du marquage comme lu: $e');
      }
    }
    
    // Naviguer vers la page appropriée en fonction du type de notification
    switch (notification.type) {
      case NotificationType.message:
        Navigator.pushNamed(context, '/messages');
        break;
      case NotificationType.devis:
        Navigator.pushNamed(context, '/suivi_devis');
        break;
      case NotificationType.projet:
        Navigator.pushNamed(context, '/mes_projets');
        break;
      case NotificationType.tatoueur:
        Navigator.pushNamed(context, '/recherche_tatoueur');
        break;
      case NotificationType.system:
        // Pour les notifications système, afficher plus de détails
        _showNotificationDetails(notification);
        break;
    }
  }

  void _showNotificationDetails(NotificationItem notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KipikTheme.rouge.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: notification.color.withOpacity(0.2),
                    radius: 25,
                    child: Icon(
                      notification.icon,
                      color: notification.color,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontFamily: 'PermanentMarker',
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          notification.formattedDate,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    notification.fullMessage ?? notification.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KipikTheme.rouge,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<NotificationItem> _getFilteredNotifications() {
    final currentTab = _tabController.index;
    
    if (currentTab == 0) {
      // Toutes les notifications
      return _notifications;
    } else if (currentTab == 1) {
      // Nouvelles
      return _notifications.where((notification) => !notification.read).toList();
    } else if (currentTab == 2) {
      // Lues
      return _notifications.where((notification) => notification.read).toList();
    } else {
      // Filtrer par type (Messages)
      return _notifications.where((notification) => notification.type == NotificationType.message).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _getFilteredNotifications();
    final unreadCount = _notifications.where((notification) => !notification.read).length;
    
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: 'Notifications',
        showBackButton: true,
        redirectToHome: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond aléatoire avec effet de parallaxe
          Image.asset(
            _selectedBackground,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          
          // Overlay dégradé pour meilleure lisibilité
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          Column(
            children: [
              // En-tête avec statistiques
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Badge(
                              backgroundColor: unreadCount > 0 ? KipikTheme.rouge : Colors.transparent,
                              isLabelVisible: unreadCount > 0,
                              label: Text(unreadCount.toString()),
                              child: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notifications (${_notifications.length})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Text(
                                    '$unreadCount non lues',
                                    style: TextStyle(
                                      color: KipikTheme.rouge,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (unreadCount > 0)
                              IconButton(
                                onPressed: _markAllAsRead,
                                icon: const Icon(Icons.mark_email_read, color: Colors.white70, size: 20),
                                tooltip: 'Tout marquer comme lu',
                              ),
                            IconButton(
                              onPressed: _deleteAllNotifications,
                              icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                              tooltip: 'Supprimer toutes les notifications',
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Onglets de filtrage avec PermanentMarker
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: KipikTheme.rouge,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        labelStyle: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontWeight: FontWeight.bold, 
                          fontSize: 12
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 12
                        ),
                        tabs: const [
                          Tab(text: 'Toutes'),
                          Tab(text: 'Nouvelles'),
                          Tab(text: 'Lues'),
                          Tab(text: 'Messages'),
                        ],
                        onTap: (index) {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Liste des notifications
              Expanded(
                child: _isLoading 
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
                      ),
                    )
                  : filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationsList(filteredNotifications),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final String message;
    final IconData icon;
    
    switch (_tabController.index) {
      case 1:
        message = 'Vous n\'avez pas de nouvelles notifications';
        icon = Icons.notifications_none;
        break;
      case 2:
        message = 'Vous n\'avez pas encore de notifications lues';
        icon = Icons.mark_email_read;
        break;
      case 3:
        message = 'Vous n\'avez pas de notifications de messages';
        icon = Icons.chat_bubble_outline;
        break;
      default:
        message = 'Vous n\'avez pas encore de notifications';
        icon = Icons.notifications_none;
    }
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Toutes les notifications importantes apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> notifications) {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: KipikTheme.rouge,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(notification.id),
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: KipikTheme.rouge,
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.centerRight,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Supprimer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) async {
          try {
            await _notificationService.deleteNotification(notification.id);
            setState(() {
              _notifications.removeWhere((n) => n.id == notification.id);
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Notification supprimée'),
                backgroundColor: Colors.black87,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                action: SnackBarAction(
                  label: 'Annuler',
                  textColor: KipikTheme.rouge,
                  onPressed: () {
                    _loadNotifications();
                  },
                ),
              ),
            );
          } catch (e) {
            print('Erreur lors de la suppression: $e');
            _loadNotifications(); // Recharger en cas d'erreur
          }
        },
        child: Card(
          elevation: notification.read ? 2 : 5,
          shadowColor: notification.read 
              ? Colors.black.withOpacity(0.2) 
              : KipikTheme.rouge.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: notification.read
                  ? Colors.transparent
                  : KipikTheme.rouge.withOpacity(0.5),
              width: notification.read ? 0 : 1.5,
            ),
          ),
          child: InkWell(
            onTap: () => _handleNotificationAction(notification),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône
                  CircleAvatar(
                    backgroundColor: notification.color.withOpacity(0.2),
                    radius: 22,
                    child: Icon(
                      notification.icon,
                      color: notification.color,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Contenu
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête (titre et date)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              notification.formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 5),
                        
                        // Message
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Action selon le type de notification
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionButton(notification),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(NotificationItem notification) {
    switch (notification.type) {
      case NotificationType.message:
        return TextButton.icon(
          onPressed: () => _handleNotificationAction(notification),
          icon: const Icon(Icons.chat, size: 16),
          label: const Text('Voir le message'),
          style: TextButton.styleFrom(
            foregroundColor: KipikTheme.rouge,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            backgroundColor: KipikTheme.rouge.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      
      case NotificationType.devis:
        return TextButton.icon(
          onPressed: () => _handleNotificationAction(notification),
          icon: const Icon(Icons.receipt, size: 16),
          label: const Text('Voir le devis'),
          style: TextButton.styleFrom(
            foregroundColor: KipikTheme.rouge,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            backgroundColor: KipikTheme.rouge.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      
      case NotificationType.projet:
        return TextButton.icon(
          onPressed: () => _handleNotificationAction(notification),
          icon: const Icon(Icons.art_track, size: 16),
          label: const Text('Voir le projet'),
          style: TextButton.styleFrom(
            foregroundColor: KipikTheme.rouge,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            backgroundColor: KipikTheme.rouge.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      
      case NotificationType.tatoueur:
        return TextButton.icon(
          onPressed: () => _handleNotificationAction(notification),
          icon: const Icon(Icons.person, size: 16),
          label: const Text('Voir le tatoueur'),
          style: TextButton.styleFrom(
            foregroundColor: KipikTheme.rouge,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            backgroundColor: KipikTheme.rouge.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      
      case NotificationType.system:
        return TextButton.icon(
          onPressed: () => _handleNotificationAction(notification),
          icon: const Icon(Icons.info_outline, size: 16),
          label: const Text('En savoir plus'),
          style: TextButton.styleFrom(
            foregroundColor: KipikTheme.rouge,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            backgroundColor: KipikTheme.rouge.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
    }
  }
}