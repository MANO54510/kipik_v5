import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/kipik_theme.dart';
import '../../models/flash/flash.dart';
import '../../models/flash/flash_booking.dart';
import '../../models/flash/flash_booking_status.dart';
import '../../services/flash/flash_service.dart';
import '../../services/auth/secure_auth_service.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../shared/flashs/flash_detail_page.dart';

class HistoriqueFlashsPage extends StatefulWidget {
  const HistoriqueFlashsPage({Key? key}) : super(key: key);

  @override
  State<HistoriqueFlashsPage> createState() => _HistoriqueFlashsPageState();
}

class _HistoriqueFlashsPageState extends State<HistoriqueFlashsPage>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  List<FlashBooking> _bookingHistory = [];
  Map<String, Flash> _flashsCache = {};
  
  bool _isLoading = true;
  String _selectedFilter = 'all';
  
  // Stats
  int _totalBookings = 0;
  double _totalSpent = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _loadHistory();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) return;
      
      // Charger l'historique des réservations
      final bookings = await FlashService.instance.getBookingsByClient(currentUser['uid']);
      
      // Charger les détails des flashs
      await _loadFlashDetails(bookings);
      
      // Calculer les stats
      _calculateStats(bookings);
      
      setState(() {
        _bookingHistory = bookings;
        _isLoading = false;
      });
      
      _fadeController.forward();
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement de l\'historique');
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

  void _calculateStats(List<FlashBooking> bookings) {
    _totalBookings = bookings.length;
    _totalSpent = bookings.fold(0, (sum, b) => sum + b.totalPrice);
    _completedCount = bookings.where((b) => b.status == FlashBookingStatus.completed).length;
    _cancelledCount = bookings.where((b) => 
      b.status == FlashBookingStatus.cancelled || 
      b.status == FlashBookingStatus.rejected
    ).length;
  }

  List<FlashBooking> _getFilteredBookings() {
    switch (_selectedFilter) {
      case 'completed':
        return _bookingHistory.where((b) => b.status == FlashBookingStatus.completed).toList();
      case 'upcoming':
        return _bookingHistory.where((b) => 
          b.status == FlashBookingStatus.confirmed &&
          b.requestedDate.isAfter(DateTime.now())
        ).toList();
      case 'cancelled':
        return _bookingHistory.where((b) => 
          b.status == FlashBookingStatus.cancelled ||
          b.status == FlashBookingStatus.rejected
        ).toList();
      default:
        return _bookingHistory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Mon Historique',
        subtitle: '$_totalBookings réservations',
        showBackButton: true,
        useProStyle: false,
        actions: [
          if (_bookingHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.analytics, color: Colors.white),
              onPressed: _showStats,
            ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: KipikTheme.rouge),
          const SizedBox(height: 24),
          const Text(
            'Chargement de votre historique...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_bookingHistory.isEmpty) {
      return _buildEmptyState();
    }
    
    final filteredBookings = _getFilteredBookings();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildStatsOverview(),
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadHistory,
              color: KipikTheme.rouge,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredBookings.length,
                itemBuilder: (context, index) {
                  final booking = filteredBookings[index];
                  final flash = _flashsCache[booking.flashId];
                  return _buildBookingCard(booking, flash);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune réservation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre historique de flashs apparaîtra ici',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Explorer les flashs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [KipikTheme.rouge.withOpacity(0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KipikTheme.rouge.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', _totalBookings.toString(), Icons.flash_on),
          _buildStatItem('Terminés', _completedCount.toString(), Icons.check_circle),
          _buildStatItem('Dépensé', '${_totalSpent.toInt()}€', Icons.euro),
          _buildStatItem('Annulés', _cancelledCount.toString(), Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: KipikTheme.rouge, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'value': 'all', 'label': 'Tous', 'icon': Icons.all_inclusive},
      {'value': 'upcoming', 'label': 'À venir', 'icon': Icons.upcoming},
      {'value': 'completed', 'label': 'Terminés', 'icon': Icons.done},
      {'value': 'cancelled', 'label': 'Annulés', 'icon': Icons.cancel},
    ];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['value'];
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                filter['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              label: Text(filter['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['value'] as String;
                });
              },
              selectedColor: KipikTheme.rouge,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(FlashBooking booking, Flash? flash) {
    final statusColor = _getStatusColor(booking.status);
    final statusIcon = _getStatusIcon(booking.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showBookingDetails(booking, flash),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: flash != null
                      ? Image.network(
                          flash.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                
                const SizedBox(width: 16),
                
                // Info
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(booking.requestedDate),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            booking.status.displayText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${booking.totalPrice.toInt()}€',
                            style: TextStyle(
                              color: KipikTheme.rouge,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Action button
                if (booking.status == FlashBookingStatus.completed && flash != null)
                  IconButton(
                    onPressed: () => _rateFlash(booking, flash),
                    icon: const Icon(Icons.star_border, color: Colors.orange),
                  )
                else
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image, color: Colors.grey, size: 40),
    );
  }

  Color _getStatusColor(FlashBookingStatus status) {
    switch (status) {
      case FlashBookingStatus.pending:
        return Colors.orange;
      case FlashBookingStatus.quoteSent:
        return Colors.blue;
      case FlashBookingStatus.depositPaid:
        return Colors.purple;
      case FlashBookingStatus.confirmed:
        return Colors.blue;
      case FlashBookingStatus.completed:
        return Colors.green;
      case FlashBookingStatus.cancelled:
      case FlashBookingStatus.rejected:
        return Colors.red;
      case FlashBookingStatus.expired:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(FlashBookingStatus status) {
    switch (status) {
      case FlashBookingStatus.pending:
        return Icons.schedule;
      case FlashBookingStatus.quoteSent:
        return Icons.description;
      case FlashBookingStatus.depositPaid:
        return Icons.payment;
      case FlashBookingStatus.confirmed:
        return Icons.event_available;
      case FlashBookingStatus.completed:
        return Icons.check_circle;
      case FlashBookingStatus.cancelled:
        return Icons.cancel;
      case FlashBookingStatus.rejected:
        return Icons.do_not_disturb;
      case FlashBookingStatus.expired:
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showBookingDetails(FlashBooking booking, Flash? flash) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDetailsBottomSheet(booking, flash),
    );
  }

  Widget _buildDetailsBottomSheet(FlashBooking booking, Flash? flash) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
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
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'Détails de la réservation',
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (flash != null) ...[
                        // Flash info
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                flash.imageUrl,
                                width: 100,
                                height: 100,
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
                                      fontSize: 18,
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
                                  const SizedBox(height: 4),
                                  Text(
                                    flash.studioName,
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
                        const SizedBox(height: 24),
                      ],
                      
                      // Booking details
                      _buildDetailSection('Informations de réservation', [
                        _buildDetailRow('N° réservation', '#${booking.id.substring(0, 8)}'),
                        _buildDetailRow('Date du RDV', _formatDate(booking.requestedDate)),
                        _buildDetailRow('Heure', booking.timeSlot),
                        _buildDetailRow('Statut', booking.status.displayText),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      _buildDetailSection('Détails financiers', [
                        _buildDetailRow('Prix total', '${booking.totalPrice.toInt()}€'),
                        _buildDetailRow('Acompte versé', '${booking.depositAmount.toInt()}€'),
                        if (booking.status == FlashBookingStatus.completed)
                          _buildDetailRow('Solde payé', '${(booking.totalPrice - booking.depositAmount).toInt()}€'),
                      ]),
                      
                      if (booking.clientNotes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildDetailSection('Notes', [
                          Text(
                            booking.clientNotes,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ]),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Actions
                      if (flash != null && booking.status == FlashBookingStatus.confirmed)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FlashDetailPage(flash: flash),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('Voir le flash'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KipikTheme.rouge,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: KipikTheme.rouge,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.analytics, color: KipikTheme.rouge),
            const SizedBox(width: 8),
            const Text(
              'Statistiques',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total des réservations', _totalBookings.toString()),
            _buildStatRow('Flashs terminés', _completedCount.toString()),
            _buildStatRow('Flashs annulés', _cancelledCount.toString()),
            _buildStatRow('Total dépensé', '${_totalSpent.toInt()}€'),
            _buildStatRow('Dépense moyenne', '${(_totalSpent / (_totalBookings > 0 ? _totalBookings : 1)).toInt()}€'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: KipikTheme.rouge)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _rateFlash(FlashBooking booking, Flash flash) {
    HapticFeedback.mediumImpact();
    _showInfoSnackBar('Évaluation - Bientôt disponible');
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}