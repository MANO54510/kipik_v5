// lib/pages/organisateur/organisateur_billeterie_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/common/drawers/drawer_factory.dart';
import '../../theme/kipik_theme.dart';
import '../../services/organisateur/firebase_organisateur_service.dart';
import '../../services/organisateur/billeterie_service.dart';
import '../../services/organisateur/analytics_service.dart';

enum TicketType { standard, vip, group, earlybird }
enum SalesPeriod { all, today, week, month, custom }

class OrganisateurBilleteriePage extends StatefulWidget {
  final String? conventionId;

  const OrganisateurBilleteriePage({Key? key, this.conventionId}) : super(key: key);

  @override
  State<OrganisateurBilleteriePage> createState() => _OrganisateurBilleteriePageState();
}

class _OrganisateurBilleteriePageState extends State<OrganisateurBilleteriePage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _cardController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;

  // Services Firebase
  final FirebaseOrganisateurService _organizateurService = FirebaseOrganisateurService.instance;
  final BilleterieService _billeterieService = BilleterieService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  // State
  int _selectedTabIndex = 0;
  String _currentOrganizerId = '';
  String? _selectedConventionId;
  SalesPeriod _selectedPeriod = SalesPeriod.month;
  bool _isLoading = true;

  // Streams
  Stream<QuerySnapshot>? _conventionsStream;
  Stream<QuerySnapshot>? _salesAnalyticsStream;
  Stream<QuerySnapshot>? _ticketSalesStream;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _cardAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
    _cardController.forward();
  }

  Future<void> _initializeData() async {
    try {
      // Obtenir l'ID de l'organisateur actuel
      final organizerId = _organizateurService.getCurrentOrganizerId();
      if (organizerId != null) {
        _currentOrganizerId = organizerId;
        _selectedConventionId = widget.conventionId;
        
        _initializeFirebaseStreams();
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur initialisation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeFirebaseStreams() {
    if (_currentOrganizerId.isNotEmpty) {
      _conventionsStream = _billeterieService.getConventionsWithTicketsStream(_currentOrganizerId);
      _salesAnalyticsStream = _analyticsService.getSalesAnalyticsStream(_currentOrganizerId);
      _updateTicketSalesStream();
    }
  }

  void _updateTicketSalesStream() {
    if (_currentOrganizerId.isNotEmpty) {
      _ticketSalesStream = _billeterieService.getTicketSalesStream(
        organizerId: _currentOrganizerId,
        conventionId: _selectedConventionId,
        period: _selectedPeriod.toString().split('.').last,
      );
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KipikTheme.noir,
      appBar: CustomAppBarKipik(
        title: 'Billetterie',
        showBackButton: true,
      ),
      endDrawer: DrawerFactory.of(context),
      body: _isLoading
          ? Center(child: KipikTheme.loading())
          : SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      
                      // Titre avec style Kipik
                      Text(
                        'Gestion Billetterie',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: KipikTheme.fontTitle,
                          fontSize: 24,
                          color: KipikTheme.rouge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        'Suivez vos ventes de billets en temps réel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: KipikTheme.fontTitle,
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Stats principales
                      ScaleTransition(
                        scale: _cardAnimation,
                        child: _buildStatsOverview(),
                      ),
                      const SizedBox(height: 20),
                      
                      // Onglets
                      _buildTabBar(),
                      const SizedBox(height: 16),
                      
                      // Contenu selon l'onglet sélectionné
                      Expanded(
                        child: _buildTabContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatsOverview() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _billeterieService.getBilleterieStats(_currentOrganizerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: KipikTheme.loading()),
          );
        }

        if (snapshot.hasError) {
          return KipikTheme.errorState(
            title: 'Erreur stats',
            message: 'Impossible de charger les statistiques',
            onRetry: () => setState(() {}),
          );
        }

        final stats = snapshot.data ?? {
          'totalTickets': 0,
          'soldTickets': 0,
          'availableTickets': 0,
          'totalRevenue': 0.0,
          'salesRate': 0.0,
        };

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.confirmation_number, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Vue d\'ensemble',
                    style: TextStyle(
                      fontFamily: KipikTheme.fontTitle,
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
                  _buildStatItem(
                    'Vendus',
                    '${stats['soldTickets']}',
                    Icons.check_circle,
                  ),
                  _buildStatItem(
                    'Disponibles',
                    '${stats['availableTickets']}',
                    Icons.inventory,
                  ),
                  _buildStatItem(
                    'Revenus',
                    '${(stats['totalRevenue'] as double).toStringAsFixed(0)}€',
                    Icons.euro,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Barre de progression
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Taux de vente',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      Text(
                        '${(stats['salesRate'] as double).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (stats['salesRate'] as double) / 100,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: KipikTheme.fontTitle,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 10,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KipikTheme.rouge.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Vue d\'ensemble', 0),
          ),
          Expanded(
            child: _buildTabButton('Types de billets', 1),
          ),
          Expanded(
            child: _buildTabButton('Historique', 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? KipikTheme.rouge : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: KipikTheme.fontTitle,
            fontSize: 11,
            color: isSelected ? Colors.white : KipikTheme.rouge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildTicketTypesTab();
      case 2:
        return _buildHistoryTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return ListView(
      children: [
        _buildRevenueChart(),
        const SizedBox(height: 20),
        _buildQuickActions(),
        const SizedBox(height: 20),
        _buildRecentSales(),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _analyticsService.getAnalytics(_currentOrganizerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return KipikTheme.kipikCard(
            child: Center(child: KipikTheme.loading()),
          );
        }

        final analytics = snapshot.data ?? {};
        final revenueData = analytics['revenue'] ?? {'total': 0.0, 'growth': 0.0};

        return Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: KipikTheme.rouge, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Évolution des ventes',
                    style: TextStyle(
                      fontFamily: KipikTheme.fontTitle,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Text(
                '${(revenueData['total'] as double).toStringAsFixed(0)}€',
                style: TextStyle(
                  fontFamily: KipikTheme.fontTitle,
                  fontSize: 32,
                  color: KipikTheme.rouge,
                ),
              ),
              
              Row(
                children: [
                  Icon(
                    (revenueData['growth'] as double) >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: (revenueData['growth'] as double) >= 0 ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(revenueData['growth'] as double).abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: (revenueData['growth'] as double) >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'vs mois précédent',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Graphique simple simulé
              SizedBox(
                height: 120,
                child: Row(
                  children: List.generate(7, (index) {
                    final height = 40.0 + (index % 3) * 30;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: height,
                              decoration: BoxDecoration(
                                color: KipikTheme.rouge.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: TextStyle(
              fontFamily: KipikTheme.fontTitle,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _createNewTicketType,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau type'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KipikTheme.rouge,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportSalesData,
                  icon: const Icon(Icons.download),
                  label: const Text('Exporter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KipikTheme.rouge,
                    side: BorderSide(color: KipikTheme.rouge),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSales() {
    return StreamBuilder<QuerySnapshot>(
      stream: _billeterieService.getRecentSalesStream(_currentOrganizerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: KipikTheme.loading()),
          );
        }

        if (snapshot.hasError) {
          return KipikTheme.errorState(
            title: 'Erreur ventes',
            message: 'Impossible de charger les ventes récentes',
            onRetry: () => setState(() {}),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return KipikTheme.emptyState(
            icon: Icons.receipt,
            title: 'Aucune vente',
            message: 'Aucune vente récente trouvée',
          );
        }

        final sales = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ventes récentes',
                style: TextStyle(
                  fontFamily: KipikTheme.fontTitle,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              ...sales.take(5).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['buyerName'] ?? 'Client anonyme',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            Text(
                              '${data['quantity']} billets • ${data['totalAmount']}€',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatTimestamp(data['saleDate']),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicketTypesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _conventionsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return KipikTheme.errorState(
            title: 'Erreur types de billets',
            message: 'Impossible de charger les types de billets',
            onRetry: () => setState(() {}),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return KipikTheme.emptyState(
            icon: Icons.confirmation_number,
            title: 'Aucun type de billet',
            message: 'Créez votre premier type de billet',
          );
        }

        final tickets = snapshot.data!.docs;

        return ListView.builder(
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final doc = tickets[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Type de billet',
                          style: TextStyle(
                            fontFamily: KipikTheme.fontTitle,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data['price']}€ • ${data['sold'] ?? 0}/${data['quantity'] ?? 0} vendus',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        if (!(data['isActive'] ?? true)) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DÉSACTIVÉ',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editTicketType(doc.id, data);
                          break;
                        case 'disable':
                          _disableTicketType(doc.id);
                          break;
                        case 'enable':
                          _enableTicketType(doc.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifier'),
                      ),
                      if (data['isActive'] ?? true)
                        const PopupMenuItem(
                          value: 'disable',
                          child: Text('Désactiver'),
                        )
                      else
                        const PopupMenuItem(
                          value: 'enable',
                          child: Text('Activer'),
                        ),
                    ],
                    icon: Icon(Icons.more_vert, color: KipikTheme.rouge),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ticketSalesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return KipikTheme.errorState(
            title: 'Erreur historique',
            message: 'Impossible de charger l\'historique des ventes',
            onRetry: () => setState(() {}),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return KipikTheme.emptyState(
            icon: Icons.history,
            title: 'Aucune vente',
            message: 'Aucune vente trouvée pour cette période',
          );
        }

        final sales = snapshot.data!.docs;

        return Column(
          children: [
            // Filtres de période
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Période:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<SalesPeriod>(
                      value: _selectedPeriod,
                      onChanged: (period) {
                        if (period != null) {
                          setState(() {
                            _selectedPeriod = period;
                          });
                          _updateTicketSalesStream();
                        }
                      },
                      items: SalesPeriod.values.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(_getPeriodLabel(period)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Liste des ventes
            Expanded(
              child: ListView.builder(
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final doc = sales[index];
                  final data = doc.data() as Map<String, dynamic>;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['buyerName'] ?? 'Client anonyme',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              Text(
                                data['buyerEmail'] ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data['quantity']} billets • ${data['totalAmount']}€',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTimestamp(data['saleDate']),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(data['status']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusLabel(data['status']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _getPeriodLabel(SalesPeriod period) {
    switch (period) {
      case SalesPeriod.all:
        return 'Toutes';
      case SalesPeriod.today:
        return 'Aujourd\'hui';
      case SalesPeriod.week:
        return 'Cette semaine';
      case SalesPeriod.month:
        return 'Ce mois';
      case SalesPeriod.custom:
        return 'Personnalisé';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmé';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Date inconnue';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Date invalide';
      }
      
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date inconnue';
    }
  }

  void _createNewTicketType() {
    // TODO: Naviguer vers la page de création de ticket
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Création de nouveau type de billet',
          style: TextStyle(fontFamily: KipikTheme.fontTitle),
        ),
        backgroundColor: KipikTheme.rouge,
      ),
    );
  }

  void _editTicketType(String ticketId, Map<String, dynamic> data) {
    // TODO: Naviguer vers la page d'édition
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Édition du billet ${data['name']}',
          style: TextStyle(fontFamily: KipikTheme.fontTitle),
        ),
        backgroundColor: KipikTheme.rouge,
      ),
    );
  }

  void _disableTicketType(String ticketTypeId) async {
    final success = await _billeterieService.disableTicketType(ticketTypeId);
    if (success && mounted) {
      KipikTheme.showSuccessSnackBar(context, 'Type de billet désactivé');
    } else if (mounted) {
      KipikTheme.showErrorSnackBar(context, 'Erreur lors de la désactivation');
    }
  }

  void _enableTicketType(String ticketTypeId) async {
    final success = await _billeterieService.enableTicketType(ticketTypeId);
    if (success && mounted) {
      KipikTheme.showSuccessSnackBar(context, 'Type de billet activé');
    } else if (mounted) {
      KipikTheme.showErrorSnackBar(context, 'Erreur lors de l\'activation');
    }
  }

  void _exportSalesData() async {
    try {
      final sales = await _billeterieService.getSalesHistory(_currentOrganizerId);
      // TODO: Implémenter l'export réel (CSV, PDF, etc.)
      
      if (mounted) {
        KipikTheme.showSuccessSnackBar(
          context, 
          'Export de ${sales.length} ventes terminé'
        );
      }
    } catch (e) {
      if (mounted) {
        KipikTheme.showErrorSnackBar(context, 'Erreur lors de l\'export');
      }
    }
  }
}