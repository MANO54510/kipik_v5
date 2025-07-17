// lib/pages/conventions/convention_admin_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_admin.dart';
import 'package:kipik_v5/widgets/common/buttons/tattoo_assistant_button.dart';
import 'package:kipik_v5/services/organisateur/firebase_organisateur_service.dart';
import 'package:kipik_v5/core/helpers/service_helper.dart';
import 'package:kipik_v5/models/user_subscription.dart';
import 'package:kipik_v5/services/features/premium_feature_guard.dart';

enum ConventionStatus { draft, published, active, finished, cancelled }
enum StandManagementMode { manual, automatic, hybrid }

class ConventionAdminPage extends StatefulWidget {
  const ConventionAdminPage({Key? key}) : super(key: key);

  @override
  State<ConventionAdminPage> createState() => _ConventionAdminPageState();
}

class _ConventionAdminPageState extends State<ConventionAdminPage> 
    with TickerProviderStateMixin {
  
  // Services Firebase
  final FirebaseFirestore _firestore = ServiceHelper.firestore;
  final FirebaseAuth _auth = ServiceHelper.auth;
  final FirebaseOrganisateurService _organizerService = FirebaseOrganisateurService.instance;
  
  // Contrôleurs d'animation
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // État
  bool _isLoading = true;
  String? _selectedConventionId;
  String _searchQuery = '';
  ConventionStatus? _filterStatus;
  
  // Contrôleurs
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Streams
  Stream<QuerySnapshot>? _conventionsStream;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeStreams();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeStreams() {
    setState(() {
      _conventionsStream = _buildConventionsQuery();
      _isLoading = false;
    });
  }

  Stream<QuerySnapshot> _buildConventionsQuery() {
    Query query = _firestore.collection('conventions');
    
    // Filtre par statut si sélectionné
    if (_filterStatus != null) {
      query = query.where('status', isEqualTo: _filterStatus!.name);
    }
    
    // Tri par date de création décroissante
    query = query.orderBy('createdAt', descending: true);
    
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumFeatureGuard(
      requiredFeature: PremiumFeature.conventions,
      child: Scaffold(
        endDrawer: const CustomDrawerAdmin(),
        appBar: CustomAppBarKipik(
          title: 'Administration Conventions',
          subtitle: 'Gestion centralisée',
          showBackButton: true,
          useProStyle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.white),
              onPressed: _createNewConvention,
            ),
            IconButton(
              icon: const Icon(Icons.analytics, color: Colors.white),
              onPressed: _viewGlobalAnalytics,
            ),
          ],
        ),
        floatingActionButton: const TattooAssistantButton(),
        body: Stack(
          children: [
            // Background
            Image.asset(
              'assets/background_charbon.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            
            // Contenu principal
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      children: [
        // Liste des conventions (gauche)
        Expanded(
          flex: 4,
          child: _buildConventionsList(),
        ),
        
        // Détails de la convention sélectionnée (droite)
        if (_selectedConventionId != null)
          Expanded(
            flex: 6,
            child: _buildConventionDetails(),
          ),
      ],
    );
  }

  Widget _buildConventionsList() {
    return Container(
      color: Colors.white.withOpacity(0.95),
      child: Column(
        children: [
          // Header avec stats
          _buildListHeader(),
          
          // Barre de recherche et filtres
          _buildSearchAndFilters(),
          
          // Liste des conventions
          Expanded(
            child: _buildConventionsListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('conventions').snapshots(),
        builder: (context, snapshot) {
          final totalConventions = snapshot.data?.docs.length ?? 0;
          final activeConventions = snapshot.data?.docs
              .where((doc) => doc['status'] == 'active')
              .length ?? 0;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONVENTIONS',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatChip(
                    Icons.event,
                    totalConventions.toString(),
                    'Total',
                    Colors.white,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    Icons.check_circle,
                    activeConventions.toString(),
                    'Actives',
                    Colors.green.shade300,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de recherche
          KipikTheme.searchField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            hintText: 'Rechercher une convention...',
            backgroundColor: Colors.grey.shade100,
            textColor: Colors.black87,
          ),
          
          const SizedBox(height: 12),
          
          // Filtres par statut
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(null, 'Toutes'),
                const SizedBox(width: 8),
                ...ConventionStatus.values.map((status) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(status, _getStatusLabel(status)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ConventionStatus? status, String label) {
    final isSelected = _filterStatus == status;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? status : null;
          _conventionsStream = _buildConventionsQuery();
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: KipikTheme.rouge,
    );
  }

  Widget _buildConventionsListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _conventionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(child: KipikTheme.loading());
        }

        if (snapshot.hasError) {
          return KipikTheme.errorState(
            title: 'Erreur de chargement',
            message: 'Impossible de charger les conventions',
            onRetry: _initializeStreams,
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return KipikTheme.emptyState(
            icon: Icons.event_busy,
            title: 'Aucune convention',
            message: 'Créez votre première convention',
            action: ElevatedButton.icon(
              onPressed: _createNewConvention,
              icon: const Icon(Icons.add),
              label: const Text('Créer une convention'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                foregroundColor: Colors.white,
              ),
            ),
          );
        }

        var conventions = snapshot.data!.docs;
        
        // Filtre par recherche
        if (_searchQuery.isNotEmpty) {
          conventions = conventions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final city = (data['location']?['city'] ?? '').toString().toLowerCase();
            
            return name.contains(_searchQuery) || city.contains(_searchQuery);
          }).toList();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: conventions.length,
          itemBuilder: (context, index) {
            final doc = conventions[index];
            final convention = doc.data() as Map<String, dynamic>;
            final isSelected = _selectedConventionId == doc.id;
            
            return _buildConventionTile(doc.id, convention, isSelected);
          },
        );
      },
    );
  }

  Widget _buildConventionTile(String id, Map<String, dynamic> convention, bool isSelected) {
    final status = ConventionStatus.values.firstWhere(
      (s) => s.name == convention['status'],
      orElse: () => ConventionStatus.draft,
    );
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isSelected ? KipikTheme.rouge.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedConventionId = id;
            });
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? KipikTheme.rouge : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        convention['name'] ?? 'Sans nom',
                        style: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getStatusLabel(status),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      convention['location']?['city'] ?? 'Ville non définie',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateRange(convention['dates']),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniStat(Icons.people, '${convention['stats']?['tattooersCount'] ?? 0} tatoueurs'),
                    const SizedBox(width: 12),
                    _buildMiniStat(Icons.euro, '${convention['stats']?['revenue']?['total'] ?? 0}€'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: KipikTheme.rouge),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildConventionDetails() {
    if (_selectedConventionId == null) {
      return Container();
    }

    return Container(
      color: Colors.grey.shade50,
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('conventions')
            .doc(_selectedConventionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: KipikTheme.loading());
          }

          final convention = snapshot.data!.data() as Map<String, dynamic>;
          
          return _buildDetailsContent(snapshot.data!.id, convention);
        },
      ),
    );
  }

  Widget _buildDetailsContent(String id, Map<String, dynamic> convention) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // Header avec infos principales
          _buildDetailsHeader(id, convention),
          
          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: KipikTheme.rouge,
              unselectedLabelColor: Colors.grey,
              indicatorColor: KipikTheme.rouge,
              tabs: const [
                Tab(text: 'Général', icon: Icon(Icons.info, size: 16)),
                Tab(text: 'Stands', icon: Icon(Icons.store, size: 16)),
                Tab(text: 'Finances', icon: Icon(Icons.euro, size: 16)),
                Tab(text: 'Analytics', icon: Icon(Icons.analytics, size: 16)),
              ],
            ),
          ),
          
          // TabBarView
          Expanded(
            child: TabBarView(
              children: [
                _buildGeneralTab(id, convention),
                _buildStandsTab(id, convention),
                _buildFinancesTab(id, convention),
                _buildAnalyticsTab(id, convention),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsHeader(String id, Map<String, dynamic> convention) {
    final status = ConventionStatus.values.firstWhere(
      (s) => s.name == convention['status'],
      orElse: () => ConventionStatus.draft,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      convention['name'] ?? 'Sans nom',
                      style: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 24,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${convention['location']?['venue'] ?? ''}, ${convention['location']?['city'] ?? ''}',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions rapides
              Row(
                children: [
                  _buildActionButton(
                    Icons.edit,
                    'Modifier',
                    () => _editConvention(id),
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    Icons.visibility,
                    'Prévisualiser',
                    () => _previewConvention(id),
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    _getStatusActionIcon(status),
                    _getStatusActionLabel(status),
                    () => _updateConventionStatus(id, status),
                    _getStatusColor(status),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats rapides
          Row(
            children: [
              _buildQuickStat(
                Icons.calendar_today,
                'Dates',
                _formatDateRange(convention['dates']),
              ),
              const SizedBox(width: 24),
              _buildQuickStat(
                Icons.people,
                'Tatoueurs',
                '${convention['stats']?['tattooersCount'] ?? 0}',
              ),
              const SizedBox(width: 24),
              _buildQuickStat(
                Icons.store,
                'Stands',
                '${convention['stats']?['standsCount'] ?? 0}',
              ),
              const SizedBox(width: 24),
              _buildQuickStat(
                Icons.euro,
                'Revenus',
                ServiceHelper.formatCurrency(
                  (convention['stats']?['revenue']?['total'] ?? 0).toDouble(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Tabs content
  Widget _buildGeneralTab(String id, Map<String, dynamic> convention) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KipikTheme.card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations générales',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Description', convention['description'] ?? 'Aucune description'),
                _buildInfoRow('Type', convention['type'] ?? 'Standard'),
                _buildInfoRow('Capacité max', '${convention['capacity']?['max'] ?? 0} personnes'),
                _buildInfoRow('Organisateur', convention['organizer']?['name'] ?? 'Non défini'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          KipikTheme.card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuration',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Inscriptions ouvertes'),
                  value: convention['registrationOpen'] ?? false,
                  onChanged: (value) => _updateConventionField(id, 'registrationOpen', value),
                  activeColor: KipikTheme.rouge,
                ),
                SwitchListTile(
                  title: const Text('Visible publiquement'),
                  value: convention['isPublic'] ?? false,
                  onChanged: (value) => _updateConventionField(id, 'isPublic', value),
                  activeColor: KipikTheme.rouge,
                ),
                SwitchListTile(
                  title: const Text('Mode premium'),
                  value: convention['isPremium'] ?? false,
                  onChanged: (value) => _updateConventionField(id, 'isPremium', value),
                  activeColor: KipikTheme.rouge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandsTab(String id, Map<String, dynamic> convention) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats stands
          Row(
            children: [
              Expanded(
                child: KipikTheme.card(
                  backgroundColor: Colors.blue.shade50,
                  child: Column(
                    children: [
                      Icon(Icons.store, size: 32, color: Colors.blue.shade700),
                      const SizedBox(height: 8),
                      Text(
                        '${convention['stands']?['total'] ?? 0}',
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 24,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        'Stands total',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KipikTheme.card(
                  backgroundColor: Colors.green.shade50,
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 32, color: Colors.green.shade700),
                      const SizedBox(height: 8),
                      Text(
                        '${convention['stands']?['occupied'] ?? 0}',
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 24,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        'Occupés',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KipikTheme.card(
                  backgroundColor: Colors.orange.shade50,
                  child: Column(
                    children: [
                      Icon(Icons.hourglass_empty, size: 32, color: Colors.orange.shade700),
                      const SizedBox(height: 8),
                      Text(
                        '${convention['stands']?['available'] ?? 0}',
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 24,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      Text(
                        'Disponibles',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Configuration stands
          KipikTheme.card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion des stands',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Mode de gestion
                const Text(
                  'Mode de gestion',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<StandManagementMode>(
                  segments: const [
                    ButtonSegment(
                      value: StandManagementMode.manual,
                      label: Text('Manuel'),
                      icon: Icon(Icons.pan_tool, size: 16),
                    ),
                    ButtonSegment(
                      value: StandManagementMode.automatic,
                      label: Text('Automatique'),
                      icon: Icon(Icons.smart_toy, size: 16),
                    ),
                    ButtonSegment(
                      value: StandManagementMode.hybrid,
                      label: Text('Hybride'),
                      icon: Icon(Icons.merge_type, size: 16),
                    ),
                  ],
                  selected: {
                    StandManagementMode.values.firstWhere(
                      (mode) => mode.name == convention['standManagement']?['mode'],
                      orElse: () => StandManagementMode.manual,
                    ),
                  },
                  onSelectionChanged: (selected) {
                    _updateConventionField(
                      id,
                      'standManagement.mode',
                      selected.first.name,
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Actions stands
                Row(
                  children: [
                    Expanded(
                      child: KipikTheme.primaryButton(
                        text: 'Gérer les stands',
                        onPressed: () => _manageStands(id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KipikTheme.secondaryButton(
                        text: 'Optimiser',
                        onPressed: () => _optimizeStands(id),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancesTab(String id, Map<String, dynamic> convention) {
    final revenue = convention['stats']?['revenue'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenus totaux
          KipikTheme.card(
            backgroundColor: Colors.green.shade50,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.attach_money,
                    size: 32,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenus totaux',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        ServiceHelper.formatCurrency(
                          (revenue['total'] ?? 0).toDouble(),
                        ),
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 28,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Détail des revenus
          Row(
            children: [
              Expanded(
                child: _buildRevenueCard(
                  'Stands',
                  revenue['stands'] ?? 0,
                  Icons.store,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRevenueCard(
                  'Billetterie',
                  revenue['tickets'] ?? 0,
                  Icons.confirmation_number,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRevenueCard(
                  'Autres',
                  revenue['other'] ?? 0,
                  Icons.more_horiz,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Actions financières
          KipikTheme.card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actions financières',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('Générer rapport financier'),
                  subtitle: const Text('PDF détaillé des revenus et dépenses'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _generateFinancialReport(id),
                ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Gérer les paiements'),
                  subtitle: const Text('Suivre les paiements en attente'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _managePayments(id),
                ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.calculate),
                  title: const Text('Calculer commission Kipik'),
                  subtitle: Text('1% sur ${ServiceHelper.formatCurrency((revenue['total'] ?? 0).toDouble())}'),
                  trailing: Text(
                    ServiceHelper.formatCurrency(
                      (revenue['total'] ?? 0) * 0.01,
                    ),
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 16,
                      color: KipikTheme.rouge,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String title, num amount, IconData icon, Color color) {
    return KipikTheme.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ServiceHelper.formatCurrency(amount.toDouble()),
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(String id, Map<String, dynamic> convention) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphiques et statistiques
          KipikTheme.card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Placeholder pour graphique
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Graphique des revenus',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Métriques clés
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Taux d\'occupation',
                '${((convention['stats']?['occupancyRate'] ?? 0) * 100).toStringAsFixed(1)}%',
                Icons.pie_chart,
                Colors.blue,
              ),
              _buildMetricCard(
                'Satisfaction',
                '${convention['stats']?['satisfaction']?['average'] ?? 0}/5',
                Icons.star,
                Colors.amber,
              ),
              _buildMetricCard(
                'Visiteurs uniques',
                '${convention['stats']?['visitors']?['unique'] ?? 0}',
                Icons.people,
                Colors.green,
              ),
              _buildMetricCard(
                'Conversion',
                '${convention['stats']?['conversion']?['rate'] ?? 0}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return KipikTheme.card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDateRange(Map<String, dynamic>? dates) {
    if (dates == null) return 'Dates non définies';
    
    final start = ServiceHelper.timestampToDateTime(dates['start']);
    final end = ServiceHelper.timestampToDateTime(dates['end']);
    
    if (start == null || end == null) return 'Dates non définies';
    
    return '${ServiceHelper.formatDate(start)} - ${ServiceHelper.formatDate(end)}';
  }

  String _getStatusLabel(ConventionStatus status) {
    switch (status) {
      case ConventionStatus.draft:
        return 'Brouillon';
      case ConventionStatus.published:
        return 'Publié';
      case ConventionStatus.active:
        return 'Actif';
      case ConventionStatus.finished:
        return 'Terminé';
      case ConventionStatus.cancelled:
        return 'Annulé';
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
      case ConventionStatus.finished:
        return Colors.indigo;
      case ConventionStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusActionIcon(ConventionStatus status) {
    switch (status) {
      case ConventionStatus.draft:
        return Icons.publish;
      case ConventionStatus.published:
        return Icons.play_arrow;
      case ConventionStatus.active:
        return Icons.stop;
      case ConventionStatus.finished:
        return Icons.archive;
      case ConventionStatus.cancelled:
        return Icons.restore;
    }
  }

  String _getStatusActionLabel(ConventionStatus status) {
    switch (status) {
      case ConventionStatus.draft:
        return 'Publier';
      case ConventionStatus.published:
        return 'Activer';
      case ConventionStatus.active:
        return 'Terminer';
      case ConventionStatus.finished:
        return 'Archiver';
      case ConventionStatus.cancelled:
        return 'Restaurer';
    }
  }

  // Actions
  Future<void> _createNewConvention() async {
    // TODO: Naviguer vers la page de création
    KipikTheme.showInfoSnackBar(context, 'Création de convention - À implémenter');
  }

  void _viewGlobalAnalytics() {
    // TODO: Naviguer vers analytics globales
    KipikTheme.showInfoSnackBar(context, 'Analytics globales - À implémenter');
  }

  void _editConvention(String id) {
    // TODO: Naviguer vers édition
    KipikTheme.showInfoSnackBar(context, 'Édition convention - À implémenter');
  }

  void _previewConvention(String id) {
    // TODO: Naviguer vers preview
    KipikTheme.showInfoSnackBar(context, 'Prévisualisation - À implémenter');
  }

  Future<void> _updateConventionStatus(String id, ConventionStatus currentStatus) async {
    ConventionStatus? newStatus;
    
    switch (currentStatus) {
      case ConventionStatus.draft:
        newStatus = ConventionStatus.published;
        break;
      case ConventionStatus.published:
        newStatus = ConventionStatus.active;
        break;
      case ConventionStatus.active:
        newStatus = ConventionStatus.finished;
        break;
      case ConventionStatus.finished:
      case ConventionStatus.cancelled:
        // Pas d'action automatique
        return;
    }
    
    if (newStatus != null) {
      try {
        await _firestore
            .collection('conventions')
            .doc(id)
            .update({
          'status': newStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid,
        });
        
        KipikTheme.showSuccessSnackBar(
          context,
          'Statut mis à jour : ${_getStatusLabel(newStatus)}',
        );
      } catch (e) {
        KipikTheme.showErrorSnackBar(context, 'Erreur: $e');
      }
    }
  }

  Future<void> _updateConventionField(String id, String field, dynamic value) async {
    try {
      await _firestore
          .collection('conventions')
          .doc(id)
          .update({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
      
      HapticFeedback.lightImpact();
    } catch (e) {
      KipikTheme.showErrorSnackBar(context, 'Erreur: $e');
    }
  }

  void _manageStands(String id) {
    // TODO: Naviguer vers gestion stands
    KipikTheme.showInfoSnackBar(context, 'Gestion stands - À implémenter');
  }

  void _optimizeStands(String id) {
    // TODO: Naviguer vers optimiseur
    KipikTheme.showInfoSnackBar(context, 'Optimiseur stands - À implémenter');
  }

  void _generateFinancialReport(String id) {
    // TODO: Générer PDF
    KipikTheme.showInfoSnackBar(context, 'Génération rapport - À implémenter');
  }

  void _managePayments(String id) {
    // TODO: Naviguer vers paiements
    KipikTheme.showInfoSnackBar(context, 'Gestion paiements - À implémenter');
  }
}