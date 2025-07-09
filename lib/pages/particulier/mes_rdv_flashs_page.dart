// lib/pages/particulier/mes_rdv_flashs_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../theme/kipik_theme.dart';
import '../../models/flash/flash_booking.dart';
import '../../models/flash/flash_booking_status.dart';
import '../../models/flash/flash.dart';
import '../../services/flash/flash_service.dart';
import '../../services/auth/secure_auth_service.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../shared/booking/booking_chat_page.dart';

/// Page dashboard sophistiquée des RDV flashs pour les clients
class MesRdvFlashsPage extends StatefulWidget {
  const MesRdvFlashsPage({Key? key}) : super(key: key);

  @override
  State<MesRdvFlashsPage> createState() => _MesRdvFlashsPageState();
}

class _MesRdvFlashsPageState extends State<MesRdvFlashsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  Timer? _autoRefreshTimer;
  
  List<FlashBooking> _allBookings = [];
  List<FlashBooking> _pendingBookings = [];
  List<FlashBooking> _confirmedBookings = [];
  List<FlashBooking> _completedBookings = [];
  List<FlashBooking> _cancelledBookings = [];
  
  Map<String, Flash> _flashsCache = {};
  Map<String, String> _artistAvatarCache = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadBookings();
    _startAutoRefresh();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 4, vsync: this);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) _refreshBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) return;

      final bookings = await FlashService.instance.getBookingsByClient(currentUser['uid']);
      
      // Charger les détails des flashs en parallèle
      await _loadFlashDetails(bookings);
      
      if (!mounted) return;
      
      setState(() {
        _allBookings = bookings;
        _categorizeBookings();
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
          
          // Générer avatar pour l'artiste
          if (!_artistAvatarCache.containsKey(flash.tattooArtistName)) {
            _artistAvatarCache[flash.tattooArtistName] = _generateAvatarUrl(flash.tattooArtistName);
          }
        } catch (e) {
          print('Erreur chargement flash ${booking.flashId}: $e');
        }
      }
    });
    
    await Future.wait(futures);
  }

  String _generateAvatarUrl(String name) {
    final colors = ['FF6B6B', '4ECDC4', '45B7D1', '96CEB4', 'FFEAA7', 'DDA0DD'];
    final colorIndex = name.hashCode % colors.length;
    final initials = name.split(' ').map((n) => n[0]).take(2).join();
    return 'https://ui-avatars.com/api/?name=$initials&background=${colors[colorIndex]}&color=fff&size=128';
  }

  void _categorizeBookings() {
    _pendingBookings = _allBookings.where((b) => 
        b.status == FlashBookingStatus.pending ||
        b.status == FlashBookingStatus.quoteSent ||
        b.status == FlashBookingStatus.depositPaid).toList() // ✅ Inclus nouveaux statuts
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    _confirmedBookings = _allBookings.where((b) => 
        b.status == FlashBookingStatus.confirmed).toList()
      ..sort((a, b) => a.requestedDate.compareTo(b.requestedDate));
    
    _completedBookings = _allBookings.where((b) => 
        b.status == FlashBookingStatus.completed).toList()
      ..sort((a, b) => b.requestedDate.compareTo(a.requestedDate));
    
    _cancelledBookings = _allBookings.where((b) => 
        b.status == FlashBookingStatus.cancelled || 
        b.status == FlashBookingStatus.rejected ||
        b.status == FlashBookingStatus.expired).toList() // ✅ Inclus expired
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _refreshBookings() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    HapticFeedback.lightImpact();
    
    await _loadBookings();
    
    if (mounted) {
      setState(() => _isRefreshing = false);
      _showSuccessSnackBar('Mis à jour !');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Mes RDV Flash',
        subtitle: 'Gérez vos réservations',
        showBackButton: true,
        showNotificationIcon: false,
        useProStyle: false, // Style particulier classique
        actions: [
          IconButton(
            onPressed: _refreshBookings,
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
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Filtrer', style: TextStyle(color: Colors.white)),
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'filter':
        _showFilterDialog();
        break;
      case 'export':
        _exportBookings();
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
            'Chargement de vos RDV...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_allBookings.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildEnhancedStats(),
        _buildSophisticatedTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(_pendingBookings, BookingListType.pending),
              _buildBookingsList(_confirmedBookings, BookingListType.confirmed),
              _buildBookingsList(_completedBookings, BookingListType.completed),
              _buildBookingsList(_cancelledBookings, BookingListType.cancelled),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
                  colors: [KipikTheme.rouge.withOpacity(0.2), Colors.transparent],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flash_off,
                size: 60,
                color: KipikTheme.rouge.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun RDV flash',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Découvrez les flashs disponibles et réservez votre premier tatouage !',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildGradientButton(
              onPressed: () => Navigator.pushNamed(context, '/flash/swipe'),
              icon: Icons.flash_on,
              label: 'Découvrir les flashs',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStats() {
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
                  Icon(Icons.analytics, color: KipikTheme.rouge, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Tableau de bord',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('En attente', _pendingBookings.length, Icons.schedule, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Confirmés', _confirmedBookings.length, Icons.check_circle, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Terminés', _completedBookings.length, Icons.done_all, Colors.blue)),
                ],
              ),
              if (_allBookings.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final total = _allBookings.length;
    final completed = _completedBookings.length;
    final progress = total > 0 ? completed / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progression',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: KipikTheme.rouge,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF2A2A2A),
            valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildSophisticatedTabBar() {
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
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        padding: const EdgeInsets.all(4),
        tabs: [
          _buildTab('En attente', _pendingBookings.length, Icons.schedule),
          _buildTab('Confirmés', _confirmedBookings.length, Icons.check_circle),
          _buildTab('Terminés', _completedBookings.length, Icons.done_all),
          _buildTab('Annulés', _cancelledBookings.length, Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count, IconData icon) {
    return Tab(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 2),
          Text('$label ($count)'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<FlashBooking> bookings, BookingListType type) {
    if (bookings.isEmpty) {
      return _buildEmptyTabState(type);
    }

    return RefreshIndicator(
      onRefresh: _refreshBookings,
      color: KipikTheme.rouge,
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final flash = _flashsCache[booking.flashId];
          return _buildSophisticatedBookingCard(booking, flash, type);
        },
      ),
    );
  }

  Widget _buildEmptyTabState(BookingListType type) {
    String message;
    IconData icon;
    Color color;
    
    switch (type) {
      case BookingListType.pending:
        message = 'Aucune demande en attente';
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case BookingListType.confirmed:
        message = 'Aucun RDV confirmé';
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case BookingListType.completed:
        message = 'Aucun RDV terminé';
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case BookingListType.cancelled:
        message = 'Aucun RDV annulé';
        icon = Icons.cancel;
        color = Colors.red;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSophisticatedBookingCard(FlashBooking booking, Flash? flash, BookingListType type) {
    final statusColor = _getStatusColor(booking.status);
    final artistAvatar = flash != null ? _artistAvatarCache[flash.tattooArtistName] : null;

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
                statusColor.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            children: [
              _buildCardHeader(booking, statusColor),
              _buildCardContent(booking, flash, artistAvatar),
              _buildCardActions(booking, flash, type),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(FlashBooking booking, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
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
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(booking.status),
              color: statusColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(booking.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'RDV #${booking.id.substring(0, 8)}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
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

  Widget _buildCardContent(FlashBooking booking, Flash? flash, String? artistAvatar) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: artistAvatar != null ? NetworkImage(artistAvatar) : null,
                      backgroundColor: KipikTheme.rouge,
                      child: artistAvatar == null 
                          ? const Icon(Icons.person, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        flash?.tattooArtistName ?? 'Artiste inconnu',
                        style: TextStyle(
                          color: KipikTheme.rouge,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBookingDetails(booking, flash),
              ],
            ),
          ),
          _buildPriceColumn(booking),
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

  Widget _buildBookingDetails(FlashBooking booking, Flash? flash) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.straighten, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              flash?.size ?? 'Taille inconnue',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
        if (booking.clientNotes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.note, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  booking.clientNotes,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
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
              '${booking.depositAmount.toInt()}€ versé',
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

  Widget _buildCardActions(FlashBooking booking, Flash? flash, BookingListType type) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildActionsForStatus(booking, flash, type),
    );
  }

  // ✅ MÉTHODE CORRIGÉE avec tous les statuts
  Widget _buildActionsForStatus(FlashBooking booking, Flash? flash, BookingListType type) {
    switch (booking.status) {
      case FlashBookingStatus.pending:
        return _buildPendingActions(booking);
      case FlashBookingStatus.quoteSent: // ✅ Ajouté
        return _buildQuoteSentActions(booking);
      case FlashBookingStatus.depositPaid: // ✅ Ajouté
        return _buildDepositPaidActions(booking);
      case FlashBookingStatus.confirmed:
        return _buildConfirmedActions(booking, flash);
      case FlashBookingStatus.completed:
        return _buildCompletedActions(booking, flash);
      case FlashBookingStatus.cancelled:
      case FlashBookingStatus.rejected:
      case FlashBookingStatus.expired: // ✅ Ajouté
        return _buildCancelledActions(booking);
    }
  }

  Widget _buildPendingActions(FlashBooking booking) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            onPressed: () => _cancelBooking(booking),
            icon: Icons.cancel_outlined,
            label: 'Annuler',
            color: Colors.red,
            isOutlined: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            onPressed: () => _openChat(booking),
            icon: Icons.chat_outlined,
            label: 'Contacter',
            color: KipikTheme.rouge,
          ),
        ),
      ],
    );
  }

  // ✅ NOUVELLES MÉTHODES pour les nouveaux statuts
  Widget _buildQuoteSentActions(FlashBooking booking) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                onPressed: () => _payDeposit(booking),
                icon: Icons.payment,
                label: 'Payer acompte',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                onPressed: () => _openChat(booking),
                icon: Icons.chat,
                label: 'Négocier',
                color: KipikTheme.rouge,
                isOutlined: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildWarningCard('Devis reçu - Paiement requis pour confirmer'),
      ],
    );
  }

  Widget _buildDepositPaidActions(FlashBooking booking) {
    return Column(
      children: [
        _buildActionButton(
          onPressed: () => _openChat(booking),
          icon: Icons.chat,
          label: 'Contacter le tatoueur',
          color: KipikTheme.rouge,
        ),
        const SizedBox(height: 12),
        _buildWarningCard('Acompte payé - En attente de validation du tatoueur', color: Colors.green),
      ],
    );
  }

  Widget _buildConfirmedActions(FlashBooking booking, Flash? flash) {
    final isWithin48Hours = _isWithin48Hours(booking.requestedDate);
    
    return Column(
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
                onPressed: () => _viewDetails(booking, flash),
                icon: Icons.info_outline,
                label: 'Détails',
                color: Colors.blue,
                isOutlined: true,
              ),
            ),
          ],
        ),
        if (isWithin48Hours) ...[
          const SizedBox(height: 12),
          _buildWarningCard('RDV dans moins de 48h - Annulation impossible'),
        ] else ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              onPressed: () => _cancelBooking(booking),
              icon: Icons.cancel_outlined,
              label: 'Annuler le RDV',
              color: Colors.red,
              isOutlined: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedActions(FlashBooking booking, Flash? flash) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            onPressed: () => _rateExperience(booking),
            icon: Icons.star_outline,
            label: 'Noter',
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            onPressed: () => _viewDetails(booking, flash),
            icon: Icons.receipt_outlined,
            label: 'Reçu',
            color: Colors.blue,
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelledActions(FlashBooking booking) {
    String message;
    switch (booking.status) {
      case FlashBookingStatus.rejected:
        message = 'Demande refusée - Remboursement effectué';
        break;
      case FlashBookingStatus.expired:
        message = 'Réservation expirée - Remboursement effectué';
        break;
      default:
        message = 'Annulé - Remboursement effectué';
    }
    
    return _buildWarningCard(message, color: Colors.red);
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

  Widget _buildWarningCard(String message, {Color color = Colors.orange}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: KipikTheme.rouge.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/flash/swipe'),
            backgroundColor: KipikTheme.rouge,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Nouveau RDV',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ HELPER METHODS CORRIGÉS avec tous les statuts
  Color _getStatusColor(FlashBookingStatus status) {
    switch (status) {
      case FlashBookingStatus.pending:
        return Colors.orange;
      case FlashBookingStatus.quoteSent: // ✅ Ajouté
        return Colors.blue;
      case FlashBookingStatus.depositPaid: // ✅ Ajouté
        return Colors.purple;
      case FlashBookingStatus.confirmed:
        return Colors.green;
      case FlashBookingStatus.completed:
        return Colors.blue;
      case FlashBookingStatus.cancelled:
      case FlashBookingStatus.rejected:
        return Colors.red;
      case FlashBookingStatus.expired: // ✅ Ajouté
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(FlashBookingStatus status) {
    switch (status) {
      case FlashBookingStatus.pending:
        return Icons.schedule;
      case FlashBookingStatus.quoteSent: // ✅ Ajouté
        return Icons.description;
      case FlashBookingStatus.depositPaid: // ✅ Ajouté
        return Icons.payment;
      case FlashBookingStatus.confirmed:
        return Icons.check_circle;
      case FlashBookingStatus.completed:
        return Icons.done_all;
      case FlashBookingStatus.cancelled:
      case FlashBookingStatus.rejected:
        return Icons.cancel;
      case FlashBookingStatus.expired: // ✅ Ajouté
        return Icons.timer_off;
    }
  }

  String _getStatusText(FlashBookingStatus status) {
    return status.displayText;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isWithin48Hours(DateTime date) {
    return date.difference(DateTime.now()).inHours < 48;
  }

  // Action methods
  Future<void> _cancelBooking(FlashBooking booking) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Annuler le RDV',
      message: 'Êtes-vous sûr de vouloir annuler ce rendez-vous ? Cette action est irréversible.',
      confirmText: 'Oui, annuler',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await FlashService.instance.cancelBooking(booking.id);
        await _refreshBookings();
        _showSuccessSnackBar('RDV annulé avec succès');
        HapticFeedback.lightImpact();
      } catch (e) {
        _showErrorSnackBar('Erreur: ${e.toString()}');
      }
    }
  }

  void _payDeposit(FlashBooking booking) {
    _showInfoSnackBar('Paiement acompte - Bientôt disponible');
    // TODO: Implémenter le paiement avec FlashBookingService
  }

  void _openChat(FlashBooking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingChatPage(booking: booking),
      ),
    );
  }

  void _viewDetails(FlashBooking booking, Flash? flash) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDetailsBottomSheet(booking, flash),
    );
  }

  void _rateExperience(FlashBooking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildRatingBottomSheet(booking),
    );
  }

  void _showFilterDialog() {
    _showInfoSnackBar('Filtres - Bientôt disponible');
  }

  void _exportBookings() {
    _showInfoSnackBar('Export - Bientôt disponible');
  }

  Widget _buildDetailsBottomSheet(FlashBooking booking, Flash? flash) {
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
                      _buildBookingDetailsCard(booking),
                      const SizedBox(height: 20),
                      _buildPaymentDetailsCard(booking),
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
            'Flash tatoué',
            style: TextStyle(
              color: KipikTheme.rouge,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  flash.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flash.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      flash.tattooArtistName,
                      style: TextStyle(
                        color: KipikTheme.rouge,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (flash.description.isNotEmpty)
                      Text(
                        flash.description,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard(FlashBooking booking) {
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
            'Informations du RDV',
            style: TextStyle(
              color: KipikTheme.rouge,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Date', _formatDate(booking.requestedDate)),
          _buildDetailRow('Heure', booking.timeSlot),
          _buildDetailRow('Statut', _getStatusText(booking.status)),
          if (booking.clientNotes.isNotEmpty)
            _buildDetailRow('Notes', booking.clientNotes),
          if (booking.clientPhone.isNotEmpty)
            _buildDetailRow('Téléphone', booking.clientPhone),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard(FlashBooking booking) {
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
            'Détails de paiement',
            style: TextStyle(
              color: KipikTheme.rouge,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Prix total', '${booking.totalPrice.toInt()}€'),
          _buildDetailRow('Acompte versé', '${booking.depositAmount.toInt()}€'),
          _buildDetailRow('Reste à payer', '${(booking.totalPrice - booking.depositAmount).toInt()}€'),
          if (booking.paymentIntentId?.isNotEmpty == true)
            _buildDetailRow('ID transaction', booking.paymentIntentId!),
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

  Widget _buildRatingBottomSheet(FlashBooking booking) {
    int rating = 5;
    String comment = '';

    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Noter votre expérience',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setModalState(() => rating = index + 1),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Partagez votre expérience (optionnel)',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: const Color(0xFF0A0A0A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: KipikTheme.rouge),
                        ),
                      ),
                      onChanged: (value) => comment = value,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade600),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showSuccessSnackBar('Merci pour votre avis !');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KipikTheme.rouge,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Envoyer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KipikTheme.rouge,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

enum BookingListType {
  pending,
  confirmed,
  completed,
  cancelled,
}