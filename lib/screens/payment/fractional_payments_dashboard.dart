// lib/screens/payment/fractional_payments_dashboard.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/models/payment_models.dart';
import 'package:kipik_v5/services/payment/firebase_payment_service.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class FractionalPaymentsDashboard extends StatefulWidget {
  const FractionalPaymentsDashboard({super.key});

  @override
  State<FractionalPaymentsDashboard> createState() => _FractionalPaymentsDashboardState();
}

class _FractionalPaymentsDashboardState extends State<FractionalPaymentsDashboard> with TickerProviderStateMixin {
  final _paymentService = FirebasePaymentService.instance;
  late TabController _tabController;

  List<Map<String, dynamic>> _allPayments = [];
  List<Map<String, dynamic>> _activePayments = [];
  List<Map<String, dynamic>> _completedPayments = [];
  List<Map<String, dynamic>> _failedPayments = [];
  
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger tous les paiements fractionnés
      _allPayments = await _paymentService.getUserFractionalPayments();
      
      // Filtrer par statut
      _activePayments = _allPayments.where((p) => 
        p['status'] == 'active' || p['status'] == 'processing'
      ).toList();
      
      _completedPayments = _allPayments.where((p) => 
        p['status'] == 'completed' || p['status'] == 'succeeded'
      ).toList();
      
      _failedPayments = _allPayments.where((p) => 
        p['status'] == 'failed' || p['status'] == 'cancelled'
      ).toList();

      // Calculer les statistiques
      _dashboardStats = _calculateStats();
      
    } catch (e) {
      _errorMessage = 'Erreur de chargement: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateStats() {
    final totalRevenue = _completedPayments.fold<double>(0, 
      (sum, payment) => sum + (payment['totalAmount'] ?? 0.0));
    
    final pendingRevenue = _activePayments.fold<double>(0, 
      (sum, payment) => sum + (payment['remainingAmount'] ?? 0.0));
    
    final failedRevenue = _failedPayments.fold<double>(0, 
      (sum, payment) => sum + (payment['remainingAmount'] ?? 0.0));

    return {
      'totalPayments': _allPayments.length,
      'activePayments': _activePayments.length,
      'completedPayments': _completedPayments.length,
      'failedPayments': _failedPayments.length,
      'totalRevenue': totalRevenue,
      'pendingRevenue': pendingRevenue,
      'failedRevenue': failedRevenue,
      'averagePayment': _allPayments.isNotEmpty 
          ? totalRevenue / _allPayments.length 
          : 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildDashboardContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0B),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '💳 Paiements Fractionnés',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'PermanentMarker',
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadDashboardData,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Exporter'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Paramètres'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: KipikTheme.rouge),
          SizedBox(height: 16),
          Text(
            'Chargement des paiements fractionnés...',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
              child: Text('Réessayer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        _buildStatsHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPaymentsList(_allPayments, 'Tous les paiements'),
              _buildPaymentsList(_activePayments, 'Paiements actifs'),
              _buildPaymentsList(_completedPayments, 'Paiements terminés'),
              _buildPaymentsList(_failedPayments, 'Paiements échoués'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    if (_dashboardStats == null) return SizedBox.shrink();

    final stats = _dashboardStats!;
    
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: KipikTheme.rouge, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vue d\'ensemble',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${stats['totalPayments']} paiements',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Revenus encaissés',
                  '${stats['totalRevenue'].toStringAsFixed(0)}€',
                  Icons.trending_up,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'En attente',
                  '${stats['pendingRevenue'].toStringAsFixed(0)}€',
                  Icons.schedule,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Actifs',
                  '${stats['activePayments']}',
                  Icons.play_circle,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Terminés',
                  '${stats['completedPayments']}',
                  Icons.check_circle,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Échecs',
                  '${stats['failedPayments']}',
                  Icons.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: KipikTheme.rouge,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[400],
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        tabs: [
          Tab(text: 'Tous (${_allPayments.length})'),
          Tab(text: 'Actifs (${_activePayments.length})'),
          Tab(text: 'Terminés (${_completedPayments.length})'),
          Tab(text: 'Échecs (${_failedPayments.length})'),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(List<Map<String, dynamic>> payments, String title) {
    if (payments.isEmpty) {
      return _buildEmptyState(title);
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: _buildPaymentCard(payment),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title) {
    IconData icon;
    String message;

    if (title.contains('actifs')) {
      icon = Icons.schedule;
      message = 'Aucun paiement fractionné en cours';
    } else if (title.contains('terminés')) {
      icon = Icons.check_circle;
      message = 'Aucun paiement fractionné terminé';
    } else if (title.contains('échoués')) {
      icon = Icons.error;
      message = 'Aucun paiement fractionné échoué';
    } else {
      icon = Icons.payments;
      message = 'Aucun paiement fractionné configuré';
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[400], size: 64),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Les paiements fractionnés de vos clients apparaîtront ici',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (title.contains('Tous')) ...[
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () => _showHowToEnable(),
                child: Text(
                  'Comment activer ?',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'] ?? 'unknown';
    final totalAmount = payment['totalAmount'] ?? 0.0;
    final paidAmount = payment['paidAmount'] ?? 0.0;
    final remainingAmount = payment['remainingAmount'] ?? 0.0;
    final installments = payment['installments'] ?? 2;
    final paidInstallments = payment['paidInstallments'] ?? 0;
    final nextPaymentDate = payment['nextPaymentDate'];
    final clientName = payment['clientName'] ?? 'Client inconnu';
    final projectTitle = payment['projectTitle'] ?? 'Projet tatouage';
    
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPaymentDetails(payment),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec statut
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectTitle,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          clientName,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Progression des paiements
              Row(
                children: [
                  Text(
                    'Progression: $paidInstallments/$installments',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: installments > 0 ? paidInstallments / installments : 0,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Montants
              Row(
                children: [
                  Expanded(
                    child: _buildAmountInfo(
                      'Total',
                      '${totalAmount.toStringAsFixed(0)}€',
                      Colors.white,
                    ),
                  ),
                  Expanded(
                    child: _buildAmountInfo(
                      'Encaissé',
                      '${paidAmount.toStringAsFixed(0)}€',
                      Colors.white,
                    ),
                  ),
                  Expanded(
                    child: _buildAmountInfo(
                      'Restant',
                      '${remainingAmount.toStringAsFixed(0)}€',
                      Colors.grey[400]!,
                    ),
                  ),
                ],
              ),
              
              if (nextPaymentDate != null && status == 'active') ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.grey[400], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Prochain prélèvement: ${_formatDate(DateTime.parse(nextPaymentDate))}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
      case 'processing':
        return KipikTheme.rouge;
      case 'completed':
      case 'succeeded':
        return Colors.white;
      case 'failed':
      case 'cancelled':
      case 'paused':
        return Colors.grey[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'ACTIF';
      case 'processing':
        return 'EN COURS';
      case 'completed':
      case 'succeeded':
        return 'TERMINÉ';
      case 'failed':
        return 'ÉCHEC';
      case 'cancelled':
        return 'ANNULÉ';
      case 'paused':
        return 'SUSPENDU';
      default:
        return 'INCONNU';
    }
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPaymentDetailsSheet(payment),
    );
  }

  Widget _buildPaymentDetailsSheet(Map<String, dynamic> payment) {
    final installments = payment['installments'] ?? 2;
    final totalAmount = payment['totalAmount'] ?? 0.0;
    final installmentAmount = totalAmount / installments;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Détails du paiement fractionné',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Informations principales
          _buildDetailSection('Informations générales', [
            _buildDetailRow('Client', payment['clientName'] ?? 'Inconnu'),
            _buildDetailRow('Projet', payment['projectTitle'] ?? 'Projet tatouage'),
            _buildDetailRow('Montant total', '${payment['totalAmount']?.toStringAsFixed(2) ?? '0'}€'),
            _buildDetailRow('Nombre de paiements', '${payment['installments'] ?? 2}x'),
            _buildDetailRow('Montant par paiement', '${installmentAmount.toStringAsFixed(2)}€'),
            _buildDetailRow('Statut', _getStatusText(payment['status'] ?? 'unknown')),
          ]),
          
          SizedBox(height: 24),
          
          // Planning des paiements
          _buildDetailSection('Planning des paiements', []),
          
          SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: installments,
              itemBuilder: (context, index) {
                final isPaid = index < (payment['paidInstallments'] ?? 0);
                final isNext = index == (payment['paidInstallments'] ?? 0);
                
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isPaid 
                          ? Colors.green.withOpacity(0.1)
                          : isNext
                              ? Colors.orange.withOpacity(0.1)
                              : Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPaid 
                            ? Colors.green.withOpacity(0.3)
                            : isNext
                                ? Colors.orange.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isPaid 
                                ? Colors.green
                                : isNext
                                    ? Colors.orange
                                    : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isPaid
                                ? Icon(Icons.check, color: Colors.white, size: 16)
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPaid 
                                    ? 'Paiement ${index + 1} - Encaissé'
                                    : isNext
                                        ? 'Paiement ${index + 1} - Prochain'
                                        : 'Paiement ${index + 1} - En attente',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                index == 0 
                                    ? 'Paiement immédiat'
                                    : 'Prélèvement automatique',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Text(
                          '${installmentAmount.toStringAsFixed(2)}€',
                          style: TextStyle(
                            color: isPaid ? Colors.green : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Actions
          SizedBox(height: 16),
          Row(
            children: [
              if (payment['status'] == 'active') ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () => _pausePayment(payment),
                    child: Text(
                      'Suspendre',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ),
                SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KipikTheme.rouge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () => _contactClient(payment),
                  child: Text(
                    'Contacter client',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportData();
        break;
      case 'settings':
        _showSettings();
        break;
    }
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export des données - À implémenter'),
        backgroundColor: KipikTheme.rouge,
      ),
    );
  }

  void _showSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paramètres paiements fractionnés - À implémenter'),
        backgroundColor: KipikTheme.rouge,
      ),
    );
  }

  void _showHowToEnable() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Text(
          'Comment activer les paiements fractionnés ?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Configurez un mandat SEPA dans vos paramètres',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 8),
            Text(
              '2. Activez les paiements fractionnés dans votre profil',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 8),
            Text(
              '3. Vos clients pourront alors choisir de payer en 2, 3 ou 4 fois',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _pausePayment(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Text(
          'Suspendre le paiement fractionné',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir suspendre ce paiement fractionné ? Le client ne sera plus prélevé automatiquement.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              _performPausePayment(payment);
            },
            child: Text('Suspendre', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performPausePayment(Map<String, dynamic> payment) async {
    try {
      await _paymentService.cancelFractionalPayment(
        payment['id'],
        reason: 'artist_requested',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement fractionné suspendu'),
          backgroundColor: Colors.orange,
        ),
      );
      
      await _loadDashboardData();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _contactClient(Map<String, dynamic> payment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact client - À implémenter'),
        backgroundColor: KipikTheme.rouge,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}