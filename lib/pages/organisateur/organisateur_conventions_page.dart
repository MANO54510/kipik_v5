// lib/pages/organisateur/organisateur_conventions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/common/drawers/drawer_factory.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../services/organisateur/firebase_organisateur_service.dart';
import '../../services/organisateur/convention_management_service.dart';

enum ConventionStatus { draft, published, active, completed, cancelled }

class OrganisateurConventionsPage extends StatefulWidget {
  const OrganisateurConventionsPage({Key? key}) : super(key: key);

  @override
  State<OrganisateurConventionsPage> createState() => _OrganisateurConventionsPageState();
}

class _OrganisateurConventionsPageState extends State<OrganisateurConventionsPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _tabController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _tabAnimation;

  // Services Firebase
  final FirebaseOrganisateurService _organisateurService = FirebaseOrganisateurService();
  final ConventionManagementService _conventionService = ConventionManagementService();

  // State
  int _selectedTabIndex = 0;
  String _searchQuery = '';
  ConventionStatus? _statusFilter;

  // Data streams
  Stream<QuerySnapshot>? _conventionsStream;
  List<DocumentSnapshot> _filteredConventions = [];

  final TextEditingController _searchController = TextEditingController();
  String? _currentOrganizerId;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFirebaseStreams();
    _setupSearchListener();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _tabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _tabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tabController, curve: Curves.easeOut),
    );

    _slideController.forward();
    _tabController.forward();
  }

  void _initializeFirebaseStreams() {
    _currentOrganizerId = _organisateurService.getCurrentOrganizerId();
    
    if (_currentOrganizerId != null) {
      _conventionsStream = _conventionService.getConventionsStream(_currentOrganizerId!);
    }
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
      _filterConventions();
    });
  }

  void _filterConventions() {
    // Le filtrage sera fait côté client après réception des données Firebase
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_currentOrganizerId == null) {
      return _buildAuthenticationError();
    }

    return Scaffold(
      endDrawer: DrawerFactory.of(context),
      appBar: CustomAppBarKipik(
        title: 'Mes Conventions',
        subtitle: 'Gestion temps réel',
        showBackButton: true,
        showBurger: true,
        useProStyle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: _viewGlobalAnalytics,
          ),
        ],
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
          const TattooAssistantButton(),
        ],
      ),
      body: Stack(
        children: [
          // Background
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

  Widget _buildAuthenticationError() {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              const Text(
                'Erreur d\'authentification',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous devez être connecté en tant qu\'organisateur',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/connexion'),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildSearchAndFilters(),
        const SizedBox(height: 16),
        _buildStatusTabs(),
        const SizedBox(height: 16),
        _buildStatsHeader(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildConventionsList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Icon(Icons.search, color: KipikTheme.rouge),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher une convention...',
                  hintStyle: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.grey[500],
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _filterConventions();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    return AnimatedBuilder(
      animation: _tabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _tabAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StreamBuilder<QuerySnapshot>(
              stream: _conventionsStream,
              builder: (context, snapshot) {
                final allConventions = snapshot.hasData ? snapshot.data!.docs : <DocumentSnapshot>[];
                
                final tabs = [
                  {'label': 'Toutes', 'status': null, 'count': allConventions.length},
                  {'label': 'Actives', 'status': ConventionStatus.active, 'count': _getCountByStatus(allConventions, 'active')},
                  {'label': 'Brouillons', 'status': ConventionStatus.draft, 'count': _getCountByStatus(allConventions, 'draft')},
                  {'label': 'Terminées', 'status': ConventionStatus.completed, 'count': _getCountByStatus(allConventions, 'completed')},
                ];

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
                    children: tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final isSelected = _selectedTabIndex == index;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = index;
                              _statusFilter = tab['status'] as ConventionStatus?;
                            });
                            _filterConventions();
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
                                Text(
                                  tab['label'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${tab['count']}',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StreamBuilder<QuerySnapshot>(
        stream: _conventionsStream,
        builder: (context, snapshot) {
          final conventions = snapshot.hasData ? snapshot.data!.docs : <DocumentSnapshot>[];
          
          double totalRevenue = 0;
          int totalTattooers = 0;
          double avgRevenue = 0;

          for (final doc in conventions) {
            final data = doc.data() as Map<String, dynamic>;
            final stats = data['stats'] as Map<String, dynamic>?;
            if (stats != null) {
              final revenue = stats['revenue'];
              if (revenue is Map<String, dynamic>) {
                totalRevenue += (revenue['total'] as num?)?.toDouble() ?? 0;
              }
              totalTattooers += (stats['tattooersCount'] as int?) ?? 0;
            }
          }

          if (conventions.isNotEmpty) {
            avgRevenue = totalRevenue / conventions.length;
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.withOpacity(0.8), Colors.blue.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Revenus Total',
                  '${totalRevenue.toStringAsFixed(0)}€',
                  Icons.euro,
                ),
                _buildStatItem(
                  'Tatoueurs',
                  totalTattooers.toString(),
                  Icons.people,
                ),
                _buildStatItem(
                  'Moy/Convention',
                  '${avgRevenue.toStringAsFixed(0)}€',
                  Icons.trending_up,
                ),
              ],
            ),
          );
        },
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

  Widget _buildConventionsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StreamBuilder<QuerySnapshot>(
        stream: _conventionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.error.toString(),
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

          final allConventions = snapshot.data?.docs ?? [];
          final filteredConventions = _applyFilters(allConventions);

          if (filteredConventions.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: filteredConventions.length,
            itemBuilder: (context, index) {
              final doc = filteredConventions[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildConventionCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  List<DocumentSnapshot> _applyFilters(List<DocumentSnapshot> conventions) {
    return conventions.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final basicInfo = data['basic'] as Map<String, dynamic>?;
      final locationInfo = data['location'] as Map<String, dynamic>?;
      
      // Filtre par recherche
      if (_searchQuery.isNotEmpty) {
        final name = basicInfo?['name']?.toString().toLowerCase() ?? '';
        final venue = locationInfo?['venue']?.toString().toLowerCase() ?? '';
        
        if (!name.contains(_searchQuery) && !venue.contains(_searchQuery)) {
          return false;
        }
      }
      
      // Filtre par statut
      if (_statusFilter != null) {
        final status = basicInfo?['status'];
        if (status != _statusFilter.toString().split('.').last) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Widget _buildConventionCard(String conventionId, Map<String, dynamic> data) {
    final basicInfo = data['basic'] as Map<String, dynamic>?;
    final locationInfo = data['location'] as Map<String, dynamic>?;
    final datesInfo = data['dates'] as Map<String, dynamic>?;
    final statsInfo = data['stats'] as Map<String, dynamic>?;
    
    final status = _parseStatus(basicInfo?['status']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // En-tête avec statut
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_getStatusColor(status), _getStatusColor(status).withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        basicInfo?['name'] ?? 'Convention sans nom',
                        style: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${locationInfo?['venue'] ?? 'Lieu TBD'} • ${_formatDate(datesInfo)}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(status),
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
          
          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Métriques
                _buildMetricsRow(statsInfo),
                
                const SizedBox(height: 16),
                
                // Progression
                _buildProgressSection(statsInfo),
                
                const SizedBox(height: 16),
                
                // Actions
                _buildConventionActions(conventionId, data, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(Map<String, dynamic>? statsInfo) {
    final tattooersCount = statsInfo?['tattooersCount'] ?? 0;
    final maxTattooers = statsInfo?['maxTattooers'] ?? 0;
    final ticketsSold = statsInfo?['ticketsSold'] ?? 0;
    final revenue = statsInfo?['revenue'];
    final totalRevenue = revenue is Map<String, dynamic> ? (revenue['total'] ?? 0.0) : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Tatoueurs',
            '$tattooersCount',
            maxTattooers > 0 ? '/$maxTattooers' : '',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Billets',
            '$ticketsSold',
            '',
            Icons.confirmation_number,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Revenus',
            '${totalRevenue.toStringAsFixed(0)}€',
            '',
            Icons.euro,
            KipikTheme.rouge,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, String suffix, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: color,
                ),
              ),
              if (suffix.isNotEmpty)
                Text(
                  suffix,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(Map<String, dynamic>? statsInfo) {
    final tattooersCount = (statsInfo?['tattooersCount'] ?? 0).toDouble();
    final maxTattooers = (statsInfo?['maxTattooers'] ?? 1).toDouble();
    final ticketsSold = (statsInfo?['ticketsSold'] ?? 0).toDouble();
    final expectedVisitors = (statsInfo?['expectedVisitors'] ?? 1).toDouble();
    
    final tattooersProgress = maxTattooers > 0 ? tattooersCount / maxTattooers : 0.0;
    final ticketsProgress = expectedVisitors > 0 ? ticketsSold / expectedVisitors : 0.0;
    
    return Column(
      children: [
        _buildProgressBar(
          'Occupation stands',
          tattooersProgress,
          '${(tattooersProgress * 100).toInt()}%',
          Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildProgressBar(
          'Vente billets',
          ticketsProgress,
          '${(ticketsProgress * 100).toInt()}%',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, double progress, String percentage, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildConventionActions(String conventionId, Map<String, dynamic> data, ConventionStatus status) {
    switch (status) {
      case ConventionStatus.draft:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _editConvention(conventionId, data),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _publishConvention(conventionId, data),
                icon: const Icon(Icons.publish, size: 16),
                label: const Text('Publier', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case ConventionStatus.published:
      case ConventionStatus.active:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewAnalytics(conventionId, data),
                icon: const Icon(Icons.analytics, size: 16),
                label: const Text('Analytics', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _manageConvention(conventionId, data),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('Gérer', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _viewConventionMap(conventionId, data),
                icon: const Icon(Icons.map, size: 16),
                label: const Text('Plan', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case ConventionStatus.completed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _downloadReport(conventionId, data),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Rapport', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  side: const BorderSide(color: Colors.indigo),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _duplicateConvention(conventionId, data),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Dupliquer', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case ConventionStatus.cancelled:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewConventionDetails(conventionId, data),
                icon: const Icon(Icons.info, size: 16),
                label: const Text('Détails', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _duplicateConvention(conventionId, data),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Recréer', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.event_busy,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune convention trouvée',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Créez votre première convention pour commencer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createNewConvention,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Créer une convention'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  ConventionStatus _parseStatus(String? statusString) {
    switch (statusString) {
      case 'draft':
        return ConventionStatus.draft;
      case 'published':
        return ConventionStatus.published;
      case 'active':
        return ConventionStatus.active;
      case 'completed':
        return ConventionStatus.completed;
      case 'cancelled':
        return ConventionStatus.cancelled;
      default:
        return ConventionStatus.draft;
    }
  }

  Color _getStatusColor(ConventionStatus status) {
    switch (status) {
      case ConventionStatus.draft:
        return Colors.grey;
      case ConventionStatus.published:
        return Colors.blue;
      case ConventionStatus.active:
        return Colors.green;
      case ConventionStatus.completed:
        return Colors.indigo;
      case ConventionStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusLabel(ConventionStatus status) {
    switch (status) {
      case ConventionStatus.draft:
        return 'BROUILLON';
      case ConventionStatus.published:
        return 'PUBLIÉE';
      case ConventionStatus.active:
        return 'ACTIVE';
      case ConventionStatus.completed:
        return 'TERMINÉE';
      case ConventionStatus.cancelled:
        return 'ANNULÉE';
    }
  }

  int _getCountByStatus(List<DocumentSnapshot> conventions, String status) {
    return conventions.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final basicInfo = data['basic'] as Map<String, dynamic>?;
      return basicInfo?['status'] == status;
    }).length;
  }

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

  // Actions Firebase
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtres avancés',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Fonctionnalité à implémenter avec Firebase'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewGlobalAnalytics() {
    Navigator.pushNamed(context, '/organisateur/analytics');
  }

  void _createNewConvention() {
    Navigator.pushNamed(context, '/organisateur/conventions/create');
  }

  void _editConvention(String conventionId, Map<String, dynamic> data) {
    Navigator.pushNamed(
      context, 
      '/organisateur/conventions/edit',
      arguments: conventionId,
    );
  }

  void _publishConvention(String conventionId, Map<String, dynamic> data) async {
    try {
      await _conventionService.publishConvention(conventionId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Convention "${data['basic']['name']}" publiée avec succès !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la publication: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _viewAnalytics(String conventionId, Map<String, dynamic> data) {
    Navigator.pushNamed(
      context,
      '/organisateur/analytics/$conventionId',
      arguments: data,
    );
  }

  void _manageConvention(String conventionId, Map<String, dynamic> data) {
    Navigator.pushNamed(
      context,
      '/conventions/detail/$conventionId',
      arguments: {'role': 'organisateur'},
    );
  }

  void _viewConventionMap(String conventionId, Map<String, dynamic> data) {
    Navigator.pushNamed(
      context,
      '/conventions/detail/$conventionId',
      arguments: {'role': 'organisateur', 'openMap': true},
    );
  }

  void _downloadReport(String conventionId, Map<String, dynamic> data) async {
    try {
      // Implémenter génération de rapport Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Génération du rapport pour "${data['basic']['name']}"...'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _duplicateConvention(String conventionId, Map<String, dynamic> data) async {
    try {
      await _conventionService.duplicateConvention(conventionId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Convention "${data['basic']['name']}" dupliquée avec succès !'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la duplication: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _viewConventionDetails(String conventionId, Map<String, dynamic> data) {
    Navigator.pushNamed(
      context,
      '/conventions/detail/$conventionId',
      arguments: {'role': 'organisateur'},
    );
  }
}