// lib/pages/organisateur/organisateur_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/common/drawers/drawer_factory.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../core/helpers/service_helper.dart'; // ✅ NOUVEAU
import '../../core/helpers/widget_helper.dart';  // ✅ NOUVEAU

class OrganisateurDashboardPage extends StatefulWidget {
  const OrganisateurDashboardPage({Key? key}) : super(key: key);

  @override
  State<OrganisateurDashboardPage> createState() => _OrganisateurDashboardPageState();
}

class _OrganisateurDashboardPageState extends State<OrganisateurDashboardPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _cardController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;

  // ✅ CORRIGÉ - Utilisation des helpers au lieu des services directs
  String? _currentOrganizerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _cardController = AnimationController(
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
    
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  void _initializeData() {
    // ✅ SIMPLIFIÉ - Utilisation de ServiceHelper
    _currentOrganizerId = ServiceHelper.currentUserId;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!ServiceHelper.isAuthenticated || _currentOrganizerId == null) {
      return _buildAuthenticationError();
    }

    return KipikTheme.scaffoldWithoutBackground(
      backgroundColor: KipikTheme.noir,
      endDrawer: DrawerFactory.of(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBarKipik(
          title: 'Dashboard Organisateur',
          subtitle: 'Vue d\'ensemble temps réel',
          showBackButton: false,
          showBurger: true,
          useProStyle: true,
          actions: [
            _buildNotificationButton(),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _openSettings,
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "create_convention",
            onPressed: _createNewConvention,
            backgroundColor: KipikTheme.rouge,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Nouvelle Convention',
              style: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
            ),
          ),
          const SizedBox(height: 16),
          const TattooAssistantButton(
            contextPage: 'dashboard_organisateur',
            allowImageGeneration: false,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background
          KipikTheme.withSpecificBackground(
            'assets/background_charbon.png',
            child: Container(),
          ),
          
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoading ? Center(child: KipikTheme.loading()) : _buildDashboardContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return WidgetHelper.buildStreamWidget<QuerySnapshot>(
      stream: ServiceHelper.getStream('stand_requests', where: {'organizerId': _currentOrganizerId, 'status': 'pending'}),
      builder: (data) {
        final pendingCount = data.docs.length;
        
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: _viewNotifications,
            ),
            if (pendingCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$pendingCount',
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
        );
      },
      loading: IconButton(
        icon: const Icon(Icons.notifications, color: Colors.white),
        onPressed: _viewNotifications,
      ),
    );
  }

  Widget _buildAuthenticationError() {
    return KipikTheme.scaffoldWithoutBackground(
      backgroundColor: KipikTheme.noir,
      child: KipikTheme.errorState(
        title: 'Erreur d\'authentification',
        message: 'Vous devez être connecté en tant qu\'organisateur',
        onRetry: () => Navigator.pushReplacementNamed(context, '/connexion'),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          _buildKPICards(),
          const SizedBox(height: 32),
          _buildRevenueChart(),
          const SizedBox(height: 32),
          _buildActiveConventions(),
          const SizedBox(height: 32),
          _buildPendingRequests(),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 100), // Espace pour FAB
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: WidgetHelper.buildFutureWidget<Map<String, dynamic>>(
            future: ServiceHelper.getCurrentOrganizerData(),
            builder: (organizerData) {
              final organizerName = organizerData['profile']?['name'] ?? 'Organisateur';
              
              return WidgetHelper.buildFutureWidget<Map<String, dynamic>>(
                future: ServiceHelper.getAnalyticsData(_currentOrganizerId!),
                builder: (analyticsData) {
                  final monthlyRevenue = analyticsData['revenue']?['total'] ?? 0.0;
                  final growth = analyticsData['revenue']?['growth'] ?? 0.0;
                  
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade600, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👋 Bonjour $organizerName !',
                          style: const TextStyle(
                            fontFamily: 'PermanentMarker',
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildConventionsSummary(),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Revenus du mois',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      ServiceHelper.formatCurrency(monthlyRevenue),
                                      style: const TextStyle(
                                        fontFamily: 'PermanentMarker',
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (growth > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+${growth.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildConventionsSummary() {
    return WidgetHelper.buildStreamWidget<QuerySnapshot>(
      stream: ServiceHelper.getStream('conventions', where: {'basic.organizerId': _currentOrganizerId}),
      builder: (conventionsData) {
        final activeConventions = conventionsData.docs.where((doc) => 
            (doc.data() as Map<String, dynamic>)['basic']['status'] == 'active').length;
        
        return WidgetHelper.buildStreamWidget<QuerySnapshot>(
          stream: ServiceHelper.getStream('stand_requests', where: {'organizerId': _currentOrganizerId, 'status': 'pending'}),
          builder: (requestsData) {
            final pendingRequests = requestsData.docs.length;
            
            return Text(
              'Vous avez $activeConventions conventions actives et $pendingRequests demandes en attente.',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Colors.white70,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKPICards() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimation.value)),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: WidgetHelper.buildStreamWidget<QuerySnapshot>(
              stream: ServiceHelper.getStream('conventions', where: {'basic.organizerId': _currentOrganizerId}),
              builder: (conventionsData) {
                final activeConventions = conventionsData.docs.where((doc) => 
                    (doc.data() as Map<String, dynamic>)['basic']['status'] == 'active').length;
                
                return WidgetHelper.buildStreamWidget<QuerySnapshot>(
                  stream: ServiceHelper.getStream('stand_requests', where: {'organizerId': _currentOrganizerId, 'status': 'pending'}),
                  builder: (requestsData) {
                    final pendingRequests = requestsData.docs.length;
                    
                    return WidgetHelper.buildFutureWidget<Map<String, dynamic>>(
                      future: ServiceHelper.getAnalyticsData(_currentOrganizerId!),
                      builder: (analyticsData) {
                        final totalTattooers = analyticsData['tattooers']?['active'] ?? 0;
                        final kipikCommission = (analyticsData['revenue']?['total'] ?? 0.0) * 0.01;
                        
                        final kpis = [
                          {
                            'title': 'Conventions Actives',
                            'value': '$activeConventions',
                            'icon': Icons.event,
                            'color': KipikTheme.rouge,
                            'subtitle': '+${conventionsData.docs.length - activeConventions} inactives',
                          },
                          {
                            'title': 'Demandes en Attente',
                            'value': '$pendingRequests',
                            'icon': Icons.pending,
                            'color': Colors.orange,
                            'subtitle': 'À traiter',
                          },
                          {
                            'title': 'Tatoueurs Actifs',
                            'value': '$totalTattooers',
                            'icon': Icons.people,
                            'color': Colors.blue,
                            'subtitle': 'Toutes conventions',
                          },
                          {
                            'title': 'Commission Kipik',
                            'value': ServiceHelper.formatCurrency(kipikCommission),
                            'icon': Icons.account_balance_wallet,
                            'color': Colors.green,
                            'subtitle': '1% du CA',
                          },
                        ];

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          children: kpis.map((kpi) => _buildKPICard(kpi)).toList(),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildKPICard(Map<String, dynamic> kpi) {
    return WidgetHelper.buildStatCard(
      title: kpi['title'],
      value: kpi['value'],
      icon: kpi['icon'],
      backgroundColor: Colors.white.withOpacity(0.95),
      onTap: () {
        // Navigation contextuelle selon le KPI
        switch (kpi['title']) {
          case 'Conventions Actives':
            Navigator.pushNamed(context, '/organisateur/conventions');
            break;
          case 'Demandes en Attente':
            Navigator.pushNamed(context, '/organisateur/inscriptions');
            break;
          case 'Tatoueurs Actifs':
            Navigator.pushNamed(context, '/organisateur/participants');
            break;
        }
      },
    );
  }

  Widget _buildRevenueChart() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Évolution des Revenus',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Graphique des revenus temps réel',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Intégration Charts.js + Firebase',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveConventions() {
    return WidgetHelper.buildStreamWidget<QuerySnapshot>(
      stream: ServiceHelper.getStream('conventions', 
        where: {'basic.organizerId': _currentOrganizerId, 'basic.status': 'active'}, 
        limit: 3
      ),
      builder: (data) {
        return WidgetHelper.buildKipikContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_note, color: KipikTheme.rouge, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Conventions Actives',
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/organisateur/conventions'),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data.docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(
                    child: Text(
                      'Aucune convention active',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                ...data.docs.map((doc) {
                  final conventionData = doc.data() as Map<String, dynamic>;
                  return _buildConventionCard(doc.id, conventionData);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConventionCard(String conventionId, Map<String, dynamic> data) {
    final basicInfo = data['basic'] as Map<String, dynamic>?;
    final locationInfo = data['location'] as Map<String, dynamic>?;
    final statsInfo = data['stats'] as Map<String, dynamic>?;
    
    return WidgetHelper.buildListItem(
      title: basicInfo?['name'] ?? 'Convention',
      subtitle: '${locationInfo?['venue'] ?? 'Lieu'} • ${_formatDate(data['dates'])}',
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: KipikTheme.rouge.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.event, color: KipikTheme.rouge, size: 20),
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              ServiceHelper.formatCurrency(statsInfo?['revenue']?['total'] ?? 0.0),
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 14,
                color: Colors.green[600],
              ),
            ),
            Text(
              '${statsInfo?['tattooersCount'] ?? 0} tatoueurs',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
      ],
      onTap: () => Navigator.pushNamed(
        context,
        '/conventions/detail/$conventionId',
        arguments: {'role': 'organisateur'},
      ),
    );
  }

  Widget _buildPendingRequests() {
    return WidgetHelper.buildStreamWidget<QuerySnapshot>(
      stream: ServiceHelper.getStream('stand_requests', 
        where: {'organizerId': _currentOrganizerId, 'status': 'pending'}, 
        limit: 3
      ),
      builder: (data) {
        if (data.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pending, color: Colors.orange.shade600, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Demandes en Attente (${data.docs.length})',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 18,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...data.docs.map((doc) {
                final requestData = doc.data() as Map<String, dynamic>;
                final requesterInfo = requestData['requester'] as Map<String, dynamic>?;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                          requesterInfo?['name']?[0]?.toUpperCase() ?? '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              requesterInfo?['name'] ?? 'Tatoueur',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Stand ${requestData['stand']?['requestedSize']} - ${ServiceHelper.formatCurrency(requestData['pricing']?['requestedPrice'] ?? 0.0)}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/organisateur/inscriptions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(60, 30),
                        ),
                        child: const Text(
                          'Voir',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              WidgetHelper.buildActionButton(
                text: 'Traiter toutes les demandes (${data.docs.length})',
                onPressed: () => Navigator.pushNamed(context, '/organisateur/inscriptions'),
                isPrimary: false,
              ),
            ],
          ),
        );
      },
      empty: const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'Nouvelle Convention',
        'subtitle': 'Créer un événement',
        'icon': Icons.add_circle,
        'color': KipikTheme.rouge,
        'onTap': _createNewConvention,
      },
      {
        'title': 'Demandes Stands',
        'subtitle': 'Gérer les inscriptions',
        'icon': Icons.business,
        'color': Colors.orange,
        'onTap': () => Navigator.pushNamed(context, '/organisateur/inscriptions'),
      },
      {
        'title': 'Billeterie',
        'subtitle': 'Ventes & Analytics',
        'icon': Icons.confirmation_number,
        'color': Colors.green,
        'onTap': () => Navigator.pushNamed(context, '/organisateur/billeterie'),
      },
      {
        'title': 'Marketing',
        'subtitle': 'Promotion & Communication',
        'icon': Icons.campaign,
        'color': Colors.purple,
        'onTap': () => Navigator.pushNamed(context, '/organisateur/marketing'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: KipikTheme.rouge, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Actions Rapides',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: actions.map((action) => _buildActionCard(action)).toList(),
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        action['onTap']();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                action['icon'],
                color: action['color'],
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              action['title'],
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action['subtitle'],
              style: const TextStyle(
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

  // Helper methods
  String _formatDate(Map<String, dynamic>? datesInfo) {
    if (datesInfo == null) return 'Date TBD';
    
    try {
      final startTimestamp = datesInfo['start'] as Timestamp?;
      final endTimestamp = datesInfo['end'] as Timestamp?;
      
      if (startTimestamp != null && endTimestamp != null) {
        final startDate = startTimestamp.toDate();
        final endDate = endTimestamp.toDate();
        
        if (startDate.month == endDate.month) {
          return '${startDate.day}-${endDate.day}/${startDate.month}/${startDate.year}';
        } else {
          return '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}/${startDate.year}';
        }
      }
    } catch (e) {
      return 'Date invalide';
    }
    
    return 'Date TBD';
  }

  // Actions
  void _viewNotifications() {
    Navigator.pushNamed(context, '/organisateur/inscriptions');
  }

  void _openSettings() {
    Navigator.pushNamed(context, '/organisateur/settings');
  }

  void _createNewConvention() {
    Navigator.pushNamed(context, '/organisateur/conventions/create');
  }
}