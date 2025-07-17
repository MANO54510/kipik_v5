// lib/pages/pro/booking/guest_system/guest_notifications.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/kipik_theme.dart';
import '../../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../../widgets/common/buttons/tattoo_assistant_button.dart';

enum NotificationType { arrival, session, revenue, departure, review, contract }
enum NotificationPriority { low, normal, high, urgent }
enum NotificationStatus { unread, read, archived }

class GuestNotifications extends StatefulWidget {
  const GuestNotifications({Key? key}) : super(key: key);

  @override
  State<GuestNotifications> createState() => _GuestNotificationsState();
}

class _GuestNotificationsState extends State<GuestNotifications> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _floatController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;

  NotificationStatus _selectedFilter = NotificationStatus.unread;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _filteredNotifications = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNotifications();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _floatController.repeat(reverse: true);
    });
  }

  void _loadNotifications() {
    setState(() => _isLoading = true);
    
    // Simulation de chargement des notifications
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _notifications = _generateSampleNotifications();
        _filteredNotifications = _notifications;
        _isLoading = false;
      });
      _filterNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Notifications Guest',
        subtitle: 'Système Premium',
        showBackButton: true,
        useProStyle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: _markAllAsRead,
              ),
              if (_getUnreadCount() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_floatAnimation.value * 0.2),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_getUnreadCount()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: const TattooAssistantButton(),
      body: Stack(
        children: [
          // Background charbon
          Image.asset(
            'assets/background_charbon.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildFilterTabs(),
          const SizedBox(height: 16),
          _buildStatsHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: NotificationStatus.values.map((status) {
          final isSelected = _selectedFilter == status;
          final count = _getStatusCount(status);
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = status;
                  _filterNotifications();
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? LinearGradient(
                    colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
                  ) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 18,
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withOpacity(0.3) : KipikTheme.rouge.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalNotifications = _notifications.length;
    final unreadNotifications = _getUnreadCount();
    final highPriorityNotifications = _notifications
        .where((n) => n['priority'] == NotificationPriority.high || n['priority'] == NotificationPriority.urgent)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.8),
            Colors.blue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', '$totalNotifications', Icons.notifications),
          _buildStatItem('Non lues', '$unreadNotifications', Icons.mark_email_unread),
          _buildStatItem('Priorité', '$highPriorityNotifications', Icons.priority_high),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Chargement des notifications...',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _filteredNotifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(_filteredNotifications[index], index);
      },
    );
  }

  Widget _buildEmptyState() {
    String message = '';
    IconData icon = Icons.notifications_none;
    
    switch (_selectedFilter) {
      case NotificationStatus.unread:
        message = 'Aucune notification non lue';
        icon = Icons.mark_email_read;
        break;
      case NotificationStatus.read:
        message = 'Aucune notification lue';
        icon = Icons.drafts;
        break;
      case NotificationStatus.archived:
        message = 'Aucune notification archivée';
        icon = Icons.archive;
        break;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les notifications Guest apparaîtront ici',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final type = notification['type'] as NotificationType;
    final priority = notification['priority'] as NotificationPriority;
    final status = notification['status'] as NotificationStatus;
    final isUnread = status == NotificationStatus.unread;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(notification['id']),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => _archiveNotification(notification),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.archive,
            color: Colors.white,
            size: 24,
          ),
        ),
        child: GestureDetector(
          onTap: () => _openNotification(notification),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isUnread ? 0.98 : 0.85),
              borderRadius: BorderRadius.circular(20),
              border: isUnread ? Border.all(
                color: KipikTheme.rouge.withOpacity(0.3),
                width: 2,
              ) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isUnread ? 0.15 : 0.1),
                  blurRadius: isUnread ? 10 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(type),
                        color: _getTypeColor(type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title'],
                                  style: TextStyle(
                                    fontFamily: 'PermanentMarker',
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (priority == NotificationPriority.high || priority == NotificationPriority.urgent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(priority),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getPriorityLabel(priority),
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                notification['guestName'] ?? 'Système',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimeAgo(notification['timestamp']),
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: KipikTheme.rouge,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Contenu
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    notification['content'],
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
                
                // Actions spécifiques selon le type
                if (notification['actions'] != null) ...[
                  const SizedBox(height: 12),
                  _buildNotificationActions(notification),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationActions(Map<String, dynamic> notification) {
    final actions = notification['actions'] as List<Map<String, dynamic>>;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: actions.map((action) {
        return Container(
          margin: const EdgeInsets.only(left: 8),
          child: TextButton.icon(
            onPressed: () => _executeAction(action['id'], notification),
            icon: Icon(
              action['icon'] as IconData,
              size: 16,
              color: action['color'] as Color,
            ),
            label: Text(
              action['label'],
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: action['color'] as Color,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: (action['color'] as Color).withOpacity(0.3)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Actions
  void _openNotification(Map<String, dynamic> notification) {
    if (notification['status'] == NotificationStatus.unread) {
      setState(() {
        notification['status'] = NotificationStatus.read;
      });
    }
    
    _showNotificationDetails(notification);
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: _buildNotificationDetailsContent(notification, scrollController),
          );
        },
      ),
    );
  }

  Widget _buildNotificationDetailsContent(Map<String, dynamic> notification, ScrollController scrollController) {
    final type = notification['type'] as NotificationType;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'],
                      style: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'De: ${notification['guestName'] ?? 'Système Guest'}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      _formatFullDate(notification['timestamp']),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Contenu détaillé
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['content'],
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  
                  if (notification['details'] != null) ...[
                    const SizedBox(height: 20),
                    _buildNotificationDetails(notification['details']),
                  ],
                  
                  if (notification['attachments'] != null) ...[
                    const SizedBox(height: 20),
                    _buildAttachments(notification['attachments']),
                  ],
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          // Actions
          if (notification['actions'] != null) ...[
            const Divider(),
            Row(
              children: (notification['actions'] as List<Map<String, dynamic>>)
                  .map((action) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _executeAction(action['id'], notification);
                        },
                        icon: Icon(action['icon'] as IconData, size: 16),
                        label: Text(
                          action['label'],
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: action['color'] as Color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ))
                  .toList(),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationDetails(Map<String, dynamic> details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...details.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '${entry.key}:',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAttachments(List<Map<String, dynamic>> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pièces jointes',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...attachments.map((attachment) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                _getAttachmentIcon(attachment['type']),
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment['name'],
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (attachment['size'] != null)
                      Text(
                        attachment['size'],
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _downloadAttachment(attachment),
                icon: const Icon(Icons.download, color: Colors.blue),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _archiveNotification(Map<String, dynamic> notification) {
    setState(() {
      notification['status'] = NotificationStatus.archived;
      _filterNotifications();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification archivée'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        if (notification['status'] == NotificationStatus.unread) {
          notification['status'] = NotificationStatus.read;
        }
      }
      _filterNotifications();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications marquées comme lues'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _executeAction(String actionId, Map<String, dynamic> notification) {
    switch (actionId) {
      case 'accept_guest':
        _showSuccessSnackBar('Guest accepté dans votre planning !');
        break;
      case 'decline_guest':
        _showInfoSnackBar('Guest décliné. Le demandeur sera notifié.');
        break;
      case 'view_revenue':
        _showInfoSnackBar('Ouverture du détail des revenus...');
        break;
      case 'rate_guest':
        _showInfoSnackBar('Système de notation en cours de développement.');
        break;
      case 'view_portfolio':
        _showInfoSnackBar('Ouverture du portfolio...');
        break;
      case 'contact_guest':
        _showInfoSnackBar('Ouverture de la messagerie...');
        break;
      default:
        _showInfoSnackBar('Action exécutée: $actionId');
    }
  }

  void _downloadAttachment(Map<String, dynamic> attachment) {
    _showInfoSnackBar('Téléchargement de ${attachment['name']}...');
  }

  void _filterNotifications() {
    setState(() {
      switch (_selectedFilter) {
        case NotificationStatus.unread:
          _filteredNotifications = _notifications
              .where((n) => n['status'] == NotificationStatus.unread)
              .toList();
          break;
        case NotificationStatus.read:
          _filteredNotifications = _notifications
              .where((n) => n['status'] == NotificationStatus.read)
              .toList();
          break;
        case NotificationStatus.archived:
          _filteredNotifications = _notifications
              .where((n) => n['status'] == NotificationStatus.archived)
              .toList();
          break;
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Helper methods
  int _getUnreadCount() {
    return _notifications
        .where((n) => n['status'] == NotificationStatus.unread)
        .length;
  }

  int _getStatusCount(NotificationStatus status) {
    return _notifications
        .where((n) => n['status'] == status)
        .length;
  }

  String _getStatusLabel(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.unread:
        return 'Non lues';
      case NotificationStatus.read:
        return 'Lues';
      case NotificationStatus.archived:
        return 'Archivées';
    }
  }

  IconData _getStatusIcon(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.unread:
        return Icons.mark_email_unread;
      case NotificationStatus.read:
        return Icons.drafts;
      case NotificationStatus.archived:
        return Icons.archive;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.arrival:
        return Colors.green;
      case NotificationType.session:
        return Colors.blue;
      case NotificationType.revenue:
        return Colors.orange;
      case NotificationType.departure:
        return Colors.purple;
      case NotificationType.review:
        return Colors.amber;
      case NotificationType.contract:
        return Colors.red;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.arrival:
        return Icons.flight_land;
      case NotificationType.session:
        return Icons.brush;
      case NotificationType.revenue:
        return Icons.euro;
      case NotificationType.departure:
        return Icons.flight_takeoff;
      case NotificationType.review:
        return Icons.star;
      case NotificationType.contract:
        return Icons.assignment;
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  String _getPriorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Faible';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'Élevé';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  IconData _getAttachmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'document':
        return Icons.description;
      default:
        return Icons.attachment;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatFullDate(DateTime timestamp) {
    const weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 
                   'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    
    final weekday = weekdays[timestamp.weekday - 1];
    final day = timestamp.day;
    final month = months[timestamp.month - 1];
    final year = timestamp.year;
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    
    return '$weekday $day $month $year à ${hour}h${minute}';
  }

  List<Map<String, dynamic>> _generateSampleNotifications() {
    final now = DateTime.now();
    
    return [
      {
        'id': '1',
        'type': NotificationType.arrival,
        'priority': NotificationPriority.high,
        'status': NotificationStatus.unread,
        'title': 'Arrivée de Guest confirmée',
        'content': 'Emma Chen arrivera dans votre studio demain à 14h pour son guest de 2 semaines. Assurez-vous que l\'espace de travail soit prêt.',
        'guestName': 'Emma Chen',
        'timestamp': now.subtract(const Duration(hours: 2)),
        'details': {
          'Date d\'arrivée': 'Demain 14h00',
          'Durée': '2 semaines',
          'Style': 'Japonais traditionnel',
          'Commission': '25%',
        },
        'actions': [
          {
            'id': 'accept_guest',
            'label': 'Confirmer',
            'icon': Icons.check,
            'color': Colors.green,
          },
          {
            'id': 'contact_guest',
            'label': 'Contacter',
            'icon': Icons.message,
            'color': Colors.blue,
          },
        ],
      },
      {
        'id': '2',
        'type': NotificationType.revenue,
        'priority': NotificationPriority.normal,
        'status': NotificationStatus.unread,
        'title': 'Nouveau revenu Guest',
        'content': 'Votre guest Lucas a réalisé un tatouage de 350€. Votre commission: 70€ (20%).',
        'guestName': 'Lucas Dubois',
        'timestamp': now.subtract(const Duration(hours: 6)),
        'details': {
          'Montant tatouage': '350€',
          'Commission': '20%',
          'Votre part': '70€',
          'Client': 'Marie D.',
        },
        'actions': [
          {
            'id': 'view_revenue',
            'label': 'Détails',
            'icon': Icons.visibility,
            'color': Colors.orange,
          },
        ],
      },
      {
        'id': '3',
        'type': NotificationType.session,
        'priority': NotificationPriority.normal,
        'status': NotificationStatus.read,
        'title': 'Session Guest terminée',
        'content': 'Alex Martin a terminé sa session de 6h. Excellent travail sur le portrait réaliste !',
        'guestName': 'Alex Martin',
        'timestamp': now.subtract(const Duration(days: 1)),
        'attachments': [
          {
            'type': 'image',
            'name': 'Tatouage_final.jpg',
            'size': '2.4 MB',
          },
        ],
      },
      {
        'id': '4',
        'type': NotificationType.contract,
        'priority': NotificationPriority.urgent,
        'status': NotificationStatus.unread,
        'title': 'Nouveau contrat Guest',
        'content': 'Sofia Rodriguez propose un guest dans votre studio pour Août 2025. Conditions: 30% commission, hébergement requis.',
        'guestName': 'Sofia Rodriguez',
        'timestamp': now.subtract(const Duration(minutes: 30)),
        'details': {
          'Période': 'Août 2025',
          'Durée': '3 semaines',
          'Commission': '30%',
          'Hébergement': 'Requis',
          'Style': 'Réalisme couleur',
        },
        'actions': [
          {
            'id': 'accept_guest',
            'label': 'Accepter',
            'icon': Icons.check,
            'color': Colors.green,
          },
          {
            'id': 'decline_guest',
            'label': 'Refuser',
            'icon': Icons.close,
            'color': Colors.red,
          },
          {
            'id': 'view_portfolio',
            'label': 'Portfolio',
            'icon': Icons.photo_library,
            'color': Colors.purple,
          },
        ],
      },
      {
        'id': '5',
        'type': NotificationType.departure,
        'priority': NotificationPriority.normal,
        'status': NotificationStatus.read,
        'title': 'Guest terminé avec succès',
        'content': 'Le guest d\'Emma Chen s\'est terminé. Revenus totaux: 2,400€. N\'oubliez pas de laisser un avis !',
        'guestName': 'Emma Chen',
        'timestamp': now.subtract(const Duration(days: 3)),
        'details': {
          'Durée totale': '2 semaines',
          'Tatouages réalisés': '8',
          'Revenus totaux': '2,400€',
          'Votre commission': '600€',
        },
        'actions': [
          {
            'id': 'rate_guest',
            'label': 'Noter',
            'icon': Icons.star,
            'color': Colors.amber,
          },
        ],
      },
    ];
  }
}