// lib/pages/pro/flashs/rdv_validation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../theme/kipik_theme.dart';
import '../../../models/flash/flash_booking.dart';
import '../../../models/flash/flash.dart';
import '../../../models/flash/flash_booking_status.dart'; // ✅ Import explicite
import '../../../services/flash/flash_service.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../shared/booking/booking_chat_page.dart';

/// Page professionnelle sophistiquée de validation des RDV flash
class RdvValidationPage extends StatefulWidget {
  const RdvValidationPage({Key? key}) : super(key: key);

  @override
  State<RdvValidationPage> createState() => _RdvValidationPageState();
}

class _RdvValidationPageState extends State<RdvValidationPage> 
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _notificationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _notificationAnimation;
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  Timer? _autoRefreshTimer;
  Timer? _notificationTimer;
  
  // Données et cache
  List<FlashBooking> _allBookings = [];
  List<FlashBooking> _pendingBookings = [];
  List<FlashBooking> _todayBookings = [];
  List<FlashBooking> _upcomingBookings = [];
  Map<String, Flash> _flashsCache = {};
  Map<String, Map<String, dynamic>> _clientsCache = {};
  
  // Stats analytics
  int _totalEarningsToday = 0;
  int _totalBookingsToday = 0;
  int _pendingCount = 0;
  int _urgentCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
    _startTimers();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 3, vsync: this);
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _notificationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _notificationAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _notificationController, curve: Curves.elasticOut),
    );
  }

  void _startTimers() {
    // Auto-refresh toutes les 30 secondes
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _refreshData();
    });
    
    // Vérification notifications urgence toutes les 10 secondes
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _checkUrgentBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _notificationController.dispose();
    _autoRefreshTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) return;

      // Charger les réservations du tatoueur
      final bookings = await FlashService.instance.getBookingsByArtist(currentUser['uid']);
      
      // Charger les détails en parallèle
      await Future.wait([
        _loadFlashDetails(bookings),
        _loadClientDetails(bookings),
      ]);
      
      if (!mounted) return;
      
      setState(() {
        _allBookings = bookings;
        _categorizeBookings();
        _calculateAnalytics();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erreur: ${e.toString()}');
      }
    }
  }

  Future<void> _loadFlashDetails(List<FlashBooking> bookings) async {
    final futures = bookings.map((booking) async {
      if (!_flashsCache.containsKey(booking.flashId)) {
        try {
          final flash = await FlashService.instance.getFlashById(booking.flashId);
          _flashsCache[booking.flashId] = flash;
        } catch (e) {
          print('Erreur chargement flash ${booking.flashId}: $e');
        }
      }
    });
    
    await Future.wait(futures);
  }

  Future<void> _loadClientDetails(List<FlashBooking> bookings) async {
    final futures = bookings.map((booking) async {
      if (!_clientsCache.containsKey(booking.clientId)) {
        try {
          // Simuler les données client (remplacer par votre service)
          _clientsCache[booking.clientId] = {
            'name': 'Client ${booking.clientId.substring(0, 8)}',
            'email': 'client@example.com',
            'phone': booking.clientPhone,
            'avatar': _generateClientAvatar(booking.clientId),
            'rating': (3.5 + (booking.clientId.hashCode % 3)).toDouble(),
            'totalBookings': 2 + (booking.clientId.hashCode % 8),
            'isVerified': booking.clientId.hashCode % 3 == 0,
            'lastBooking': DateTime.now().subtract(Duration(days: booking.clientId.hashCode % 90)),
          };
        } catch (e) {
          print('Erreur chargement client ${booking.clientId}: $e');
        }
      }
    });
    
    await Future.wait(futures);
  }

  String _generateClientAvatar(String clientId) {
    final colors = ['FF6B6B', '4ECDC4', '45B7D1', '96CEB4', 'FFEAA7', 'DDA0DD'];
    final colorIndex = clientId.hashCode % colors.length;
    final initials = 'C${clientId.substring(0, 1).toUpperCase()}';
    return 'https://ui-avatars.com/api/?name=$initials&background=${colors[colorIndex]}&color=fff&size=128';
  }

  void _categorizeBookings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    _pendingBookings = _allBookings
        .where((b) => b.status == FlashBookingStatus.pending)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    _todayBookings = _allBookings
        .where((b) => b.status == FlashBookingStatus.confirmed && 
                     b.requestedDate.isAfter(today) && 
                     b.requestedDate.isBefore(tomorrow))
        .toList()
      ..sort((a, b) => a.requestedDate.compareTo(b.requestedDate));
    
    _upcomingBookings = _allBookings
        .where((b) => b.status == FlashBookingStatus.confirmed && 
                     b.requestedDate.isAfter(tomorrow))
        .toList()
      ..sort((a, b) => a.requestedDate.compareTo(b.requestedDate));
  }

  void _calculateAnalytics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    _totalEarningsToday = _allBookings
        .where((b) => b.requestedDate.isAfter(today) && 
                     b.requestedDate.isBefore(tomorrow) &&
                     (b.status == FlashBookingStatus.confirmed || 
                      b.status == FlashBookingStatus.completed))
        .fold(0, (sum, b) => sum + b.totalPrice.toInt());
    
    _totalBookingsToday = _todayBookings.length;
    _pendingCount = _pendingBookings.length;
    
    // Calcul urgence (RDV dans moins de 2h)
    _urgentCount = _allBookings
        .where((b) => b.status == FlashBookingStatus.confirmed && 
                     b.requestedDate.difference(now).inHours <= 2 &&
                     b.requestedDate.isAfter(now))
        .length;
  }

  void _checkUrgentBookings() {
    if (_urgentCount > 0) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    await _loadData();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Gestion RDV',
        subtitle: _urgentCount > 0 ? '$_urgentCount RDV urgent(s)!' : 'Dashboard professionnel',
        showBackButton: true,
        showNotificationIcon: _pendingCount > 0,
        notificationCount: _pendingCount,
        onNotificationPressed: () => _tabController.animateTo(0),
        useProStyle: true, // ✅ Active le style Pro
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: AnimatedRotation(
              turns: _isRefreshing ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: Icon(
                Icons.refresh,
                color: _isRefreshing ? KipikTheme.rouge : Colors.white,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'notification_settings',
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Notifications', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'batch_accept',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Accepter tout', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'analytics',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Analytics', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Exporter', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            onSelected: _handleMenuAction,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
      ),
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _urgentCount > 0 ? _notificationAnimation : _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _urgentCount > 0 ? _notificationAnimation.value : _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _urgentCount > 0 
                          ? [Colors.red, Colors.red.withOpacity(0.7)]
                          : [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _urgentCount > 0 ? Icons.notifications_active : Icons.business_center,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestion RDV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _urgentCount > 0 ? '$_urgentCount RDV urgent(s)!' : 'Dashboard professionnel',
                style: TextStyle(
                  color: _urgentCount > 0 ? Colors.red : Colors.grey,
                  fontSize: 12,
                  fontWeight: _urgentCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_pendingCount > 0)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: () => _tabController.animateTo(0),
                      icon: const Icon(Icons.pending_actions, color: Colors.orange),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        IconButton(
          onPressed: _refreshData,
          icon: AnimatedRotation(
            turns: _isRefreshing ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: Icon(
              Icons.refresh,
              color: _isRefreshing ? KipikTheme.rouge : Colors.white,
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: const Color(0xFF1A1A1A),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'notification_settings',
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Notifications', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'batch_accept',
              child: Row(
                children: [
                  Icon(Icons.done_all, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Accepter tout', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'analytics',
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Analytics', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Exporter', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'notification_settings':
        _showNotificationSettings();
        break;
      case 'batch_accept':
        _batchAcceptBookings();
        break;
      case 'analytics':
        _showAnalytics();
        break;
      case 'export':
        _exportData();
        break;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: KipikTheme.rouge,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chargement des RDV...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildAnalyticsDashboard(),
        _buildAdvancedTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPendingBookingsTab(),
              _buildTodayBookingsTab(),
              _buildUpcomingBookingsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsDashboard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF1A1A1A),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KipikTheme.rouge.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.dashboard, color: KipikTheme.rouge, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Analytics Temps Réel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 8),
                        const SizedBox(width: 4),
                        const Text(
                          'Live',
                          style: TextStyle(color: Colors.green, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Gains Aujourd\'hui',
                      '$_totalEarningsToday€',
                      Icons.euro,
                      Colors.green,
                      trend: '+12%',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnalyticsCard(
                      'RDV Aujourd\'hui',
                      '$_totalBookingsToday',
                      Icons.today,
                      Colors.blue,
                      trend: '+3',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnalyticsCard(
                      'En Attente',
                      '$_pendingCount',
                      Icons.schedule,
                      Colors.orange,
                      isUrgent: _pendingCount > 5,
                    ),
                  ),
                ],
              ),
              if (_urgentCount > 0) ...[
                const SizedBox(height: 16),
                _buildUrgentAlert(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? trend,
    bool isUrgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.withOpacity(0.1) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.red.withOpacity(0.3) : color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: isUrgent ? _notificationAnimation : _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isUrgent ? _notificationAnimation.value : 1.0,
                child: Icon(
                  icon,
                  color: isUrgent ? Colors.red : color,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isUrgent ? Colors.red : color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trend,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUrgentAlert() {
    return AnimatedBuilder(
      animation: _notificationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _notificationAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RDV Urgents !',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_urgentCount RDV dans moins de 2h',
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Voir', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade400,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.all(4),
        tabs: [
          _buildAdvancedTab(
            'En attente',
            _pendingBookings.length,
            Icons.schedule,
            Colors.orange,
            isUrgent: _pendingCount > 5,
          ),
          _buildAdvancedTab(
            'Aujourd\'hui',
            _todayBookings.length,
            Icons.today,
            Colors.blue,
            isUrgent: _urgentCount > 0,
          ),
          _buildAdvancedTab(
            'À venir',
            _upcomingBookings.length,
            Icons.upcoming,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab(
    String label,
    int count,
    IconData icon,
    Color color, {
    bool isUrgent = false,
  }) {
    return Tab(
      child: AnimatedBuilder(
        animation: isUrgent ? _notificationAnimation : _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isUrgent ? 0.9 + (_notificationAnimation.value * 0.1) : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Icon(icon, size: 16),
                    if (isUrgent)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$label ($count)',
                  style: TextStyle(
                    color: isUrgent ? Colors.red : null,
                    fontWeight: isUrgent ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingBookingsTab() {
    if (_pendingBookings.isEmpty) {
      return _buildEmptyState(
        'Aucune demande en attente',
        'Toutes les demandes ont été traitées !',
        Icons.check_circle,
        Colors.green,
      );
    }

    return Column(
      children: [
        if (_pendingBookings.length > 1) _buildBatchActions(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: KipikTheme.rouge,
            backgroundColor: const Color(0xFF1A1A1A),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingBookings.length,
              itemBuilder: (context, index) {
                final booking = _pendingBookings[index];
                final flash = _flashsCache[booking.flashId];
                final client = _clientsCache[booking.clientId];
                return _buildPendingBookingCard(booking, flash, client);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Icon(Icons.done_all, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Actions groupées',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _batchAcceptBookings,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Tout accepter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayBookingsTab() {
    if (_todayBookings.isEmpty) {
      return _buildEmptyState(
        'Aucun RDV aujourd\'hui',
        'Profitez de votre journée libre !',
        Icons.free_breakfast,
        Colors.blue,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: KipikTheme.rouge,
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _todayBookings.length,
        itemBuilder: (context, index) {
          final booking = _todayBookings[index];
          final flash = _flashsCache[booking.flashId];
          final client = _clientsCache[booking.clientId];
          final isUrgent = _isUrgentBooking(booking);
          return _buildConfirmedBookingCard(booking, flash, client, isUrgent: isUrgent);
        },
      ),
    );
  }

  Widget _buildUpcomingBookingsTab() {
    if (_upcomingBookings.isEmpty) {
      return _buildEmptyState(
        'Aucun RDV à venir',
        'Votre planning est libre pour les prochains jours',
        Icons.event_available,
        Colors.green,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: KipikTheme.rouge,
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingBookings.length,
        itemBuilder: (context, index) {
          final booking = _upcomingBookings[index];
          final flash = _flashsCache[booking.flashId];
          final client = _clientsCache[booking.clientId];
          return _buildConfirmedBookingCard(booking, flash, client);
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), Colors.transparent],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: color.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBookingCard(
    FlashBooking booking,
    Flash? flash,
    Map<String, dynamic>? client,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: const Color(0xFF1A1A1A),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            children: [
              _buildCardHeader(booking, Colors.orange, 'NOUVELLE DEMANDE'),
              _buildCardContent(booking, flash, client),
              _buildPendingActions(booking),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmedBookingCard(
    FlashBooking booking,
    Flash? flash,
    Map<String, dynamic>? client, {
    bool isUrgent = false,
  }) {
    final color = isUrgent ? Colors.red : Colors.green;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedBuilder(
        animation: isUrgent ? _notificationAnimation : _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isUrgent ? 0.98 + (_notificationAnimation.value * 0.02) : 1.0,
            child: Card(
              color: const Color(0xFF1A1A1A),
              elevation: isUrgent ? 12 : 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                  border: isUrgent ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
                ),
                child: Column(
                  children: [
                    _buildCardHeader(
                      booking,
                      color,
                      isUrgent ? 'URGENT - DANS ${_getTimeUntilBooking(booking)}' : 'CONFIRMÉ',
                    ),
                    _buildCardContent(booking, flash, client),
                    _buildConfirmedActions(booking, isUrgent: isUrgent),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardHeader(FlashBooking booking, Color color, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              booking.status == FlashBookingStatus.pending ? Icons.schedule : Icons.check_circle,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'RDV #${booking.id.substring(0, 8)}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(booking.requestedDate),
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
              Text(
                booking.timeSlot,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(
    FlashBooking booking,
    Flash? flash,
    Map<String, dynamic>? client,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Infos flash
          Row(
            children: [
              _buildFlashImage(flash),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flash?.title ?? 'Flash supprimé',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (flash != null) ...[
                      Row(
                        children: [
                          Icon(Icons.straighten, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            flash.size,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _buildPriceColumn(booking),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2A2A2A)),
          const SizedBox(height: 16),
          
          // Infos client enrichies
          _buildClientInfo(client, booking),
          
          if (booking.clientNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNotesSection(booking.clientNotes),
          ],
        ],
      ),
    );
  }

  Widget _buildFlashImage(Flash? flash) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: flash?.imageUrl != null
            ? Image.network(
                flash!.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A2A2A),
            const Color(0xFF1A1A1A),
          ],
        ),
      ),
      child: Icon(
        Icons.image,
        color: Colors.grey.shade600,
        size: 30,
      ),
    );
  }

  Widget _buildPriceColumn(FlashBooking booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${booking.totalPrice.toInt()}€',
          style: TextStyle(
            color: KipikTheme.rouge,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (booking.depositAmount > 0) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${booking.depositAmount.toInt()}€ reçu',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClientInfo(Map<String, dynamic>? client, FlashBooking booking) {
    if (client == null) {
      return const Text(
        'Informations client non disponibles',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(client['avatar']),
              backgroundColor: KipikTheme.rouge,
            ),
            if (client['isVerified'] == true)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    client['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (client['isVerified'] == true) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    final rating = client['rating'] as double;
                    return Icon(
                      index < rating.floor() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 12,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '${client['rating']} • ${client['totalBookings']} RDV',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    booking.clientPhone.isNotEmpty ? booking.clientPhone : 'Non renseigné',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          children: [
            IconButton(
              onPressed: () => _callClient(booking.clientPhone),
              icon: const Icon(Icons.phone, color: Colors.green),
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.1),
                foregroundColor: Colors.green,
              ),
            ),
            IconButton(
              onPressed: () => _openChat(booking),
              icon: const Icon(Icons.chat),
              style: IconButton.styleFrom(
                backgroundColor: KipikTheme.rouge.withOpacity(0.1),
                foregroundColor: KipikTheme.rouge,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                'Notes du client',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActions(FlashBooking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: () => _rejectBooking(booking),
                  icon: Icons.close,
                  label: 'Refuser',
                  color: Colors.red,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildActionButton(
                  onPressed: () => _acceptBooking(booking),
                  icon: Icons.check,
                  label: 'Accepter',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: () => _openChat(booking),
                  icon: Icons.chat_outlined,
                  label: 'Discuter',
                  color: KipikTheme.rouge,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  onPressed: () => _viewBookingDetails(booking),
                  icon: Icons.info_outline,
                  label: 'Détails',
                  color: Colors.blue,
                  isOutlined: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmedActions(FlashBooking booking, {bool isUrgent = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: () => _openChat(booking),
                  icon: Icons.chat,
                  label: 'Chat',
                  color: KipikTheme.rouge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  onPressed: () => _markAsCompleted(booking),
                  icon: Icons.done,
                  label: 'Terminé',
                  color: Colors.green,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          if (isUrgent) ...[
            const SizedBox(height: 12),
            _buildUrgentInfo(booking),
          ],
        ],
      ),
    );
  }

  Widget _buildUrgentInfo(FlashBooking booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'RDV dans ${_getTimeUntilBooking(booking)} - Préparez-vous !',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isOutlined = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.transparent : color,
        foregroundColor: isOutlined ? color : Colors.white,
        side: isOutlined ? BorderSide(color: color) : null,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_pendingCount > 0)
          FloatingActionButton(
            onPressed: _quickAcceptAll,
            backgroundColor: Colors.green,
            heroTag: 'quick_accept',
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Stack(
                    children: [
                      const Icon(Icons.done_all, color: Colors.white),
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$_pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (_pendingCount > 0) const SizedBox(height: 16),
        FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/flash/create'),
          backgroundColor: KipikTheme.rouge,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nouveau Flash',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isUrgentBooking(FlashBooking booking) {
    return booking.requestedDate.difference(DateTime.now()).inHours <= 2 &&
           booking.requestedDate.isAfter(DateTime.now());
  }

  String _getTimeUntilBooking(FlashBooking booking) {
    final diff = booking.requestedDate.difference(DateTime.now());
    if (diff.inHours > 0) {
      return '${diff.inHours}h${diff.inMinutes % 60}min';
    } else {
      return '${diff.inMinutes}min';
    }
  }

  // Action methods
  Future<void> _acceptBooking(FlashBooking booking) async {
    try {
      await FlashService.instance.updateBookingStatus(
        booking.id,
        FlashBookingStatus.confirmed,
      );
      await _refreshData();
      _showSuccessSnackBar('RDV accepté avec succès !');
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    }
  }

  Future<void> _rejectBooking(FlashBooking booking) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Refuser le RDV',
      message: 'Le client sera automatiquement remboursé. Cette action est irréversible.',
      confirmText: 'Oui, refuser',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await FlashService.instance.updateBookingStatus(
          booking.id,
          FlashBookingStatus.rejected,
        );
        await _refreshData();
        _showSuccessSnackBar('RDV refusé - Remboursement en cours');
        HapticFeedback.lightImpact();
      } catch (e) {
        _showErrorSnackBar('Erreur: ${e.toString()}');
      }
    }
  }

  Future<void> _markAsCompleted(FlashBooking booking) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Marquer comme terminé',
      message: 'Le RDV sera marqué comme terminé et le paiement final sera traité.',
      confirmText: 'Confirmer',
    );

    if (confirmed == true) {
      try {
        await FlashService.instance.updateBookingStatus(
          booking.id,
          FlashBookingStatus.completed,
        );
        await _refreshData();
        _showSuccessSnackBar('RDV marqué comme terminé !');
        HapticFeedback.heavyImpact();
      } catch (e) {
        _showErrorSnackBar('Erreur: ${e.toString()}');
      }
    }
  }

  void _openChat(FlashBooking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingChatPage(booking: booking),
      ),
    );
  }

  void _viewBookingDetails(FlashBooking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDetailsBottomSheet(booking),
    );
  }

  void _callClient(String phone) {
    if (phone.isNotEmpty) {
      _showInfoSnackBar('Appel vers $phone');
    } else {
      _showErrorSnackBar('Numéro de téléphone non disponible');
    }
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Paramètres de notifications',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text(
                'Notifications push',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Recevoir les nouvelles demandes',
                style: TextStyle(color: Colors.grey),
              ),
              value: true,
              onChanged: (value) {
                // Logique de notification
              },
              activeColor: KipikTheme.rouge,
            ),
            SwitchListTile(
              title: const Text(
                'Rappels RDV',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Rappel 1h avant le RDV',
                style: TextStyle(color: Colors.grey),
              ),
              value: true,
              onChanged: (value) {
                // Logique de rappel
              },
              activeColor: KipikTheme.rouge,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: KipikTheme.rouge),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _batchAcceptBookings() async {
    if (_pendingBookings.isEmpty) return;

    final confirmed = await _showConfirmationDialog(
      title: 'Accepter tous les RDV',
      message: 'Êtes-vous sûr de vouloir accepter les ${_pendingBookings.length} demandes en attente ?',
      confirmText: 'Tout accepter',
    );

    if (confirmed == true) {
      try {
        final futures = _pendingBookings.map((booking) =>
          FlashService.instance.updateBookingStatus(
            booking.id,
            FlashBookingStatus.confirmed,
          )
        );
        
        await Future.wait(futures);
        await _refreshData();
        _showSuccessSnackBar('${_pendingBookings.length} RDV acceptés !');
        HapticFeedback.heavyImpact();
      } catch (e) {
        _showErrorSnackBar('Erreur: ${e.toString()}');
      }
    }
  }

  void _quickAcceptAll() {
    _batchAcceptBookings();
  }

  void _showAnalytics() {
    _showInfoSnackBar('Analytics détaillées - Bientôt disponible');
  }

  void _exportData() {
    _showInfoSnackBar('Export des données - Bientôt disponible');
  }

  Widget _buildDetailsBottomSheet(FlashBooking booking) {
    final flash = _flashsCache[booking.flashId];
    final client = _clientsCache[booking.clientId];

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'Détails du RDV',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (flash != null) _buildFlashDetailsCard(flash),
                      const SizedBox(height: 20),
                      if (client != null) _buildClientDetailsCard(client),
                      const SizedBox(height: 20),
                      _buildBookingDetailsCard(booking),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlashDetailsCard(Flash flash) {
    return _buildDetailCard(
      'Flash tatoué',
      KipikTheme.rouge,
      [
        _buildDetailRow('Titre', flash.title),
        _buildDetailRow('Description', flash.description),
        _buildDetailRow('Taille', flash.size),
        _buildDetailRow('Prix', '${flash.price.toInt()}€'),
      ],
    );
  }

  Widget _buildClientDetailsCard(Map<String, dynamic> client) {
    return _buildDetailCard(
      'Informations client',
      Colors.blue,
      [
        _buildDetailRow('Nom', client['name']),
        _buildDetailRow('Email', client['email']),
        _buildDetailRow('Téléphone', client['phone'] ?? 'Non renseigné'),
        _buildDetailRow('Note', '${client['rating']}/5'),
        _buildDetailRow('RDV total', '${client['totalBookings']}'),
        _buildDetailRow('Statut', client['isVerified'] ? 'Vérifié ✓' : 'Non vérifié'),
      ],
    );
  }

  Widget _buildBookingDetailsCard(FlashBooking booking) {
    return _buildDetailCard(
      'Détails de la réservation',
      Colors.green,
      [
        _buildDetailRow('ID', '#${booking.id.substring(0, 8)}'),
        _buildDetailRow('Date', _formatDate(booking.requestedDate)),
        _buildDetailRow('Heure', booking.timeSlot),
        _buildDetailRow('Statut', booking.status.displayText),
        _buildDetailRow('Prix total', '${booking.totalPrice.toInt()}€'),
        _buildDetailRow('Acompte', '${booking.depositAmount.toInt()}€'),
        _buildDetailRow('Reste à payer', '${(booking.totalPrice - booking.depositAmount).toInt()}€'),
        if (booking.clientNotes.isNotEmpty)
          _buildDetailRow('Notes', booking.clientNotes),
        _buildDetailRow('Créé le', _formatDateTime(booking.createdAt)),
        _buildDetailRow('Modifié le', _formatDateTime(booking.updatedAt)),
      ],
    );
  }

  Widget _buildDetailCard(String title, Color color, List<Widget> details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...details,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? Colors.red : KipikTheme.rouge,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KipikTheme.rouge,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}