// lib/pages/pro/booking/guest_system/guest_tracking_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/kipik_theme.dart';
import '../../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../../widgets/common/buttons/tattoo_assistant_button.dart';

enum TrackingPeriod { today, week, month, total }
enum RevenueType { commission, tip, bonus }

class GuestTrackingPage extends StatefulWidget {
  final Map<String, dynamic>? activeGuest;
  
  const GuestTrackingPage({
    Key? key,
    this.activeGuest,
  }) : super(key: key);

  @override
  State<GuestTrackingPage> createState() => _GuestTrackingPageState();
}

class _GuestTrackingPageState extends State<GuestTrackingPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _chartController;
  late AnimationController _revenueController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _chartAnimation;
  late Animation<double> _revenueAnimation;

  TrackingPeriod _selectedPeriod = TrackingPeriod.week;
  bool _isLoading = false;
  
  Map<String, dynamic> _trackingData = {};
  List<Map<String, dynamic>> _recentSessions = [];
  List<Map<String, dynamic>> _revenueHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTrackingData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _chartController.dispose();
    _revenueController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _revenueController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.elasticOut),
    );
    
    _revenueAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revenueController, curve: Curves.easeOutBack),
    );

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _chartController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _revenueController.forward();
    });
  }

  void _loadTrackingData() {
    setState(() => _isLoading = true);
    
    // Simulation de chargement des données de suivi
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _trackingData = _generateTrackingData();
        _recentSessions = _generateRecentSessions();
        _revenueHistory = _generateRevenueHistory();
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Suivi Guest',
        subtitle: 'Réalisations & Revenus',
        showBackButton: true,
        useProStyle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportData,
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
          if (widget.activeGuest != null) ...[
            _buildActiveGuestHeader(),
            const SizedBox(height: 16),
          ],
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildTrackingContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGuestHeader() {
    final guest = widget.activeGuest!;
    
    return AnimatedBuilder(
      animation: _revenueAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _revenueAnimation.value,
          child: Container(
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
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: guest['avatar'] != null
                      ? AssetImage(guest['avatar'])
                      : null,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: guest['avatar'] == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guest['name'],
                        style: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Guest actif • ${guest['daysRemaining']} jours restants',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            guest['location'],
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ACTIF',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
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
        children: TrackingPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                  _loadTrackingData();
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
                child: Text(
                  _getPeriodLabel(period),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
            'Chargement des données...',
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

  Widget _buildTrackingContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildRevenueOverview(),
          const SizedBox(height: 16),
          _buildPerformanceMetrics(),
          const SizedBox(height: 16),
          _buildRevenueChart(),
          const SizedBox(height: 16),
          _buildRecentSessions(),
          const SizedBox(height: 16),
          _buildDetailedBreakdown(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview() {
    final data = _trackingData['revenue'] ?? {};
    
    return AnimatedBuilder(
      animation: _revenueAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _revenueAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.8),
                  Colors.teal.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.euro, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Revenus ${_getPeriodLabel(_selectedPeriod).toLowerCase()}',
                      style: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRevenueItem(
                      'Commission',
                      '${data['commission'] ?? 0}€',
                      Icons.percent,
                      Colors.white,
                    ),
                    _buildRevenueItem(
                      'Pourboires',
                      '${data['tips'] ?? 0}€',
                      Icons.volunteer_activism,
                      Colors.white70,
                    ),
                    _buildRevenueItem(
                      'Total',
                      '${data['total'] ?? 0}€',
                      Icons.account_balance_wallet,
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevenueItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    final metrics = _trackingData['metrics'] ?? {};
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Métriques de performance',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Tatouages',
                  '${metrics['tattoos'] ?? 0}',
                  Icons.brush,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Heures',
                  '${metrics['hours'] ?? 0}h',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Clients',
                  '${metrics['clients'] ?? 0}',
                  Icons.people,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Moyenne/RDV',
                  '${metrics['avgPerSession'] ?? 0}€',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
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
            value,
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart, color: KipikTheme.rouge, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Évolution des revenus',
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Graphique simplifié
                SizedBox(
                  height: 150,
                  child: _buildSimpleChart(),
                ),
                
                const SizedBox(height: 16),
                
                // Légende
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildChartLegend('Commission', Colors.blue),
                    _buildChartLegend('Pourboires', Colors.orange),
                    _buildChartLegend('Total', Colors.green),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Graphique des revenus',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.grey,
              ),
            ),
            Text(
              'Intégration en cours...',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSessions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Sessions récentes',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ..._recentSessions.take(5).map((session) => _buildSessionCard(session)),
          
          if (_recentSessions.length > 5) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _viewAllSessions,
                child: Text(
                  'Voir toutes les sessions (${_recentSessions.length})',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: KipikTheme.rouge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.brush,
              color: Colors.blue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session['title'],
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session['client']} • ${session['duration']}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${session['amount']}€',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                session['date'],
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Détail des revenus',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ..._revenueHistory.map((item) => _buildRevenueItem2(item)),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportRevenue,
                  icon: const Icon(Icons.file_download, size: 16),
                  label: const Text(
                    'Exporter',
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _viewDetailedReport,
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text(
                    'Rapport',
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KipikTheme.rouge,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem2(Map<String, dynamic> item) {
    final type = item['type'] as RevenueType;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getRevenueTypeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getRevenueTypeColor(type).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getRevenueTypeIcon(type),
            color: _getRevenueTypeColor(type),
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['description'],
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item['client']} • ${item['date']}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${item['amount']}€',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getRevenueTypeColor(type),
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  void _refreshData() {
    _loadTrackingData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Données actualisées'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export en cours...'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewAllSessions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture de toutes les sessions - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportRevenue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export des revenus en cours...'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewDetailedReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération du rapport détaillé...'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper methods
  String _getPeriodLabel(TrackingPeriod period) {
    switch (period) {
      case TrackingPeriod.today:
        return 'Aujourd\'hui';
      case TrackingPeriod.week:
        return 'Cette semaine';
      case TrackingPeriod.month:
        return 'Ce mois';
      case TrackingPeriod.total:
        return 'Total';
    }
  }

  Color _getRevenueTypeColor(RevenueType type) {
    switch (type) {
      case RevenueType.commission:
        return Colors.blue;
      case RevenueType.tip:
        return Colors.orange;
      case RevenueType.bonus:
        return Colors.purple;
    }
  }

  IconData _getRevenueTypeIcon(RevenueType type) {
    switch (type) {
      case RevenueType.commission:
        return Icons.percent;
      case RevenueType.tip:
        return Icons.volunteer_activism;
      case RevenueType.bonus:
        return Icons.star;
    }
  }

  Map<String, dynamic> _generateTrackingData() {
    return {
      'revenue': {
        'commission': 850,
        'tips': 120,
        'total': 970,
      },
      'metrics': {
        'tattoos': 6,
        'hours': 28,
        'clients': 5,
        'avgPerSession': 162,
      },
    };
  }

  List<Map<String, dynamic>> _generateRecentSessions() {
    return [
      {
        'title': 'Portrait réaliste',
        'client': 'Sarah M.',
        'duration': '4h',
        'amount': 280,
        'date': 'Aujourd\'hui',
      },
      {
        'title': 'Tatouage géométrique',
        'client': 'Lucas P.',
        'duration': '3h',
        'amount': 200,
        'date': 'Hier',
      },
      {
        'title': 'Lettering custom',
        'client': 'Emma R.',
        'duration': '2h',
        'amount': 150,
        'date': 'Il y a 2 jours',
      },
      {
        'title': 'Retouche couleur',
        'client': 'Marie D.',
        'duration': '1h30',
        'amount': 80,
        'date': 'Il y a 3 jours',
      },
      {
        'title': 'Mandala détaillé',
        'client': 'Alex C.',
        'duration': '5h',
        'amount': 350,
        'date': 'Il y a 4 jours',
      },
    ];
  }

  List<Map<String, dynamic>> _generateRevenueHistory() {
    return [
      {
        'type': RevenueType.commission,
        'description': 'Commission portrait Sarah M.',
        'client': 'Sarah M.',
        'amount': 56,
        'date': 'Aujourd\'hui',
      },
      {
        'type': RevenueType.tip,
        'description': 'Pourboire client Lucas P.',
        'client': 'Lucas P.',
        'amount': 30,
        'date': 'Hier',
      },
      {
        'type': RevenueType.commission,
        'description': 'Commission lettering Emma R.',
        'client': 'Emma R.',
        'amount': 30,
        'date': 'Il y a 2 jours',
      },
      {
        'type': RevenueType.bonus,
        'description': 'Bonus qualité mandala',
        'client': 'Alex C.',
        'amount': 50,
        'date': 'Il y a 4 jours',
      },
    ];
  }
}