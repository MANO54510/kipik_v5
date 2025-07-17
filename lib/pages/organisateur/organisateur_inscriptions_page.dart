// lib/pages/organisateur/organisateur_inscriptions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/common/drawers/drawer_factory.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';

enum RequestStatus { pending, negotiating, accepted, rejected, paid, cancelled }
enum TattooerType { verified, premium, standard, new_user }

class OrganisateurInscriptionsPage extends StatefulWidget {
  const OrganisateurInscriptionsPage({Key? key}) : super(key: key);

  @override
  State<OrganisateurInscriptionsPage> createState() => _OrganisateurInscriptionsPageState();
}

class _OrganisateurInscriptionsPageState extends State<OrganisateurInscriptionsPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _tabController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _tabAnimation;

  int _selectedTabIndex = 0;
  bool _isLoading = true;
  String _searchQuery = '';
  RequestStatus? _statusFilter;

  List<Map<String, dynamic>> _standRequests = [];
  List<Map<String, dynamic>> _filteredRequests = [];
  Map<String, dynamic>? _selectedRequest;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadStandRequests();
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

  void _setupSearchListener() {
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
      _filterRequests();
    });
  }

  void _loadStandRequests() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _standRequests = _generateStandRequestsData();
        _filteredRequests = _standRequests;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: DrawerFactory.of(context),
      appBar: CustomAppBarKipik(
        title: 'Demandes de Stands',
        subtitle: '${_filteredRequests.length} demandes',
        showBackButton: true,
        showBurger: true,
        useProStyle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: _showAdvancedFilters,
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportRequests,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "bulk_actions",
            onPressed: _showBulkActions,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.select_all, color: Colors.white),
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
              child: _isLoading ? _buildLoadingState() : _buildContent(),
            ),
          ),
        ],
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
            'Chargement des demandes...',
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
          child: _buildRequestsList(),
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
                  hintText: 'Rechercher un tatoueur, style...',
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
                  _filterRequests();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    final tabs = [
      {'label': 'Toutes', 'status': null, 'count': _standRequests.length},
      {'label': 'En attente', 'status': RequestStatus.pending, 'count': _standRequests.where((r) => r['status'] == RequestStatus.pending).length},
      {'label': 'Négociation', 'status': RequestStatus.negotiating, 'count': _standRequests.where((r) => r['status'] == RequestStatus.negotiating).length},
      {'label': 'Acceptées', 'status': RequestStatus.accepted, 'count': _standRequests.where((r) => r['status'] == RequestStatus.accepted).length},
      {'label': 'Payées', 'status': RequestStatus.paid, 'count': _standRequests.where((r) => r['status'] == RequestStatus.paid).length},
    ];

    return AnimatedBuilder(
      animation: _tabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _tabAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  final isSelected = _selectedTabIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = index;
                        _statusFilter = tab['status'] as RequestStatus?;
                      });
                      _filterRequests();
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: isSelected ? LinearGradient(
                          colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
                        ) : null,
                        color: isSelected ? null : Colors.white.withOpacity(0.95),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tab['label'] as String,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withOpacity(0.2) : KipikTheme.rouge.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${tab['count']}',
                              style: TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 12,
                                color: isSelected ? Colors.white : KipikTheme.rouge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader() {
    final pendingCount = _standRequests.where((r) => r['status'] == RequestStatus.pending).length;
    final totalRevenue = _standRequests.where((r) => r['status'] == RequestStatus.paid).fold(0.0, (sum, r) => sum + r['standPrice']);
    final avgProcessingTime = 2.3; // En jours

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
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
              'En Attente',
              pendingCount.toString(),
              Icons.pending,
              pendingCount > 0 ? Colors.orange : Colors.white,
            ),
            _buildStatItem(
              'Revenus Confirmés',
              '${totalRevenue.toStringAsFixed(0)}€',
              Icons.euro,
              Colors.green,
            ),
            _buildStatItem(
              'Temps Moyen',
              '${avgProcessingTime}j',
              Icons.timer,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
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

  Widget _buildRequestsList() {
    if (_filteredRequests.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        itemCount: _filteredRequests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(_filteredRequests[index]);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] as RequestStatus;
    final tattooerType = request['tattooerType'] as TattooerType;
    
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
                // Avatar et infos tatoueur
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    request['tattooerName'][0].toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            request['tattooerName'],
                            style: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTattooerTypeBadge(tattooerType),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Demande reçue le ${request['requestDate']}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      if (request['rating'] > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber[300], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${request['rating']}/5',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${request['completedConventions']} conventions',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
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
                    const SizedBox(height: 8),
                    Text(
                      '${request['standPrice']}€',
                      style: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Détails du stand demandé
                _buildStandDetails(request),
                
                const SizedBox(height: 16),
                
                // Spécialités et portfolio
                _buildTattooerInfo(request),
                
                const SizedBox(height: 16),
                
                // Message du tatoueur
                if (request['message'] != null) ...[
                  _buildTattooerMessage(request),
                  const SizedBox(height: 16),
                ],
                
                // Actions selon le statut
                _buildRequestActions(request, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTattooerTypeBadge(TattooerType type) {
    Color color;
    String label;
    IconData icon;

    switch (type) {
      case TattooerType.verified:
        color = Colors.green;
        label = 'VÉRIFIÉ';
        icon = Icons.verified;
        break;
      case TattooerType.premium:
        color = Colors.purple;
        label = 'PREMIUM';
        icon = Icons.star;
        break;
      case TattooerType.standard:
        color = Colors.blue;
        label = 'STANDARD';
        icon = Icons.person;
        break;
      case TattooerType.new_user:
        color = Colors.orange;
        label = 'NOUVEAU';
        icon = Icons.new_label;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandDetails(Map<String, dynamic> request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Demande de Stand',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Taille', request['standSize']),
              ),
              Expanded(
                child: _buildDetailItem('Emplacement', request['preferredLocation'] ?? 'Flexible'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Prix demandé', '${request['standPrice']}€'),
              ),
              Expanded(
                child: _buildDetailItem('Paiement', request['paymentType']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTattooerInfo(Map<String, dynamic> request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Profil Artistique',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Spécialités
          if (request['specialties'] != null) ...[
            const Text(
              'Spécialités:',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: (request['specialties'] as List).map((specialty) => 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    specialty,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ).toList(),
            ),
            const SizedBox(height: 8),
          ],
          
          // Portfolio et réseaux
          Row(
            children: [
              if (request['portfolioImages'] > 0) ...[
                Icon(Icons.photo_library, color: Colors.blue[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  '${request['portfolioImages']} photos',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (request['instagramFollowers'] > 0) ...[
                Icon(Icons.camera_alt, color: Colors.blue[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_formatNumber(request['instagramFollowers'])} followers',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTattooerMessage(Map<String, dynamic> request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.message, color: Colors.amber[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Message du tatoueur',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request['message'],
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: Colors.black87,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestActions(Map<String, dynamic> request, RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewTattooerProfile(request),
                    icon: const Icon(Icons.person, size: 16),
                    label: const Text('Profil', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(request),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Refuser', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptRequest(request),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accepter', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _startNegotiation(request),
                icon: const Icon(Icons.forum, size: 16),
                label: const Text('Négocier', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ],
        );
        
      case RequestStatus.negotiating:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewNegotiation(request),
                icon: const Icon(Icons.chat, size: 16),
                label: const Text('Chat', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _finalizeNegotiation(request),
                icon: const Icon(Icons.handshake, size: 16),
                label: const Text('Finaliser', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case RequestStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _sendContract(request),
                icon: const Icon(Icons.description, size: 16),
                label: const Text('Contrat', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'En attente de paiement',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
        
      case RequestStatus.paid:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _assignStand(request),
                icon: const Icon(Icons.place, size: 16),
                label: const Text('Assigner', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '✓ Payé - Confirmé',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
        
      default:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewRequestDetails(request),
                icon: const Icon(Icons.info, size: 16),
                label: const Text('Détails', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
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
                Icons.inbox,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune demande trouvée',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Les demandes de stands apparaîtront ici',
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
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.negotiating:
        return Colors.blue;
      case RequestStatus.accepted:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.paid:
        return Colors.purple;
      case RequestStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'EN ATTENTE';
      case RequestStatus.negotiating:
        return 'NÉGOCIATION';
      case RequestStatus.accepted:
        return 'ACCEPTÉE';
      case RequestStatus.rejected:
        return 'REFUSÉE';
      case RequestStatus.paid:
        return 'PAYÉE';
      case RequestStatus.cancelled:
        return 'ANNULÉE';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  void _filterRequests() {
    setState(() {
      _filteredRequests = _standRequests.where((request) {
        // Filtre par recherche
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!request['tattooerName'].toLowerCase().contains(query) &&
              !(request['specialties'] as List).any((s) => s.toLowerCase().contains(query))) {
            return false;
          }
        }
        
        // Filtre par statut
        if (_statusFilter != null) {
          if (request['status'] != _statusFilter) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  // Actions
  void _showAdvancedFilters() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtres avancés - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportRequests() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export des demandes - À implémenter'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showBulkActions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Actions groupées - À implémenter'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewTattooerProfile(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profil ${request['tattooerName']} - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _acceptRequest(Map<String, dynamic> request) {
    setState(() {
      request['status'] = RequestStatus.accepted;
    });
    _filterRequests();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande de ${request['tattooerName']} acceptée'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rejectRequest(Map<String, dynamic> request) {
    setState(() {
      request['status'] = RequestStatus.rejected;
    });
    _filterRequests();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande de ${request['tattooerName']} refusée'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startNegotiation(Map<String, dynamic> request) {
    setState(() {
      request['status'] = RequestStatus.negotiating;
    });
    _filterRequests();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Négociation avec ${request['tattooerName']} démarrée'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewNegotiation(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat avec ${request['tattooerName']} - À implémenter'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _finalizeNegotiation(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Finalisation négociation ${request['tattooerName']} - À implémenter'),
        backgroundColor: KipikTheme.rouge,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendContract(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Envoi contrat ${request['tattooerName']} - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _assignStand(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attribution stand ${request['tattooerName']} - À implémenter'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewRequestDetails(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Détails demande ${request['tattooerName']} - À implémenter'),
        backgroundColor: Colors.grey,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Données de test
  List<Map<String, dynamic>> _generateStandRequestsData() {
    return [
      {
        'id': '1',
        'tattooerName': 'Mike Tattoo',
        'tattooerType': TattooerType.verified,
        'status': RequestStatus.pending,
        'requestDate': '22/12/2024',
        'standSize': '3x3m',
        'standPrice': 450.0,
        'preferredLocation': 'Entrée principale',
        'paymentType': 'Paiement fractionné 3x',
        'rating': 4.8,
        'completedConventions': 12,
        'specialties': ['Réalisme', 'Portraits'],
        'portfolioImages': 45,
        'instagramFollowers': 8500,
        'message': 'Bonjour, je souhaiterais participer à votre convention. Je me spécialise dans le réalisme et les portraits. Merci !',
      },
      {
        'id': '2',
        'tattooerName': 'Sarah Ink',
        'tattooerType': TattooerType.premium,
        'status': RequestStatus.negotiating,
        'requestDate': '21/12/2024',
        'standSize': '2x3m',
        'standPrice': 320.0,
        'preferredLocation': null,
        'paymentType': 'Paiement comptant',
        'rating': 4.6,
        'completedConventions': 8,
        'specialties': ['Japonais', 'Traditionnel'],
        'portfolioImages': 67,
        'instagramFollowers': 12000,
        'message': null,
      },
      {
        'id': '3',
        'tattooerName': 'Alex Neo',
        'tattooerType': TattooerType.standard,
        'status': RequestStatus.accepted,
        'requestDate': '20/12/2024',
        'standSize': '3x4m',
        'standPrice': 520.0,
        'preferredLocation': 'Zone centrale',
        'paymentType': 'Paiement fractionné 2x',
        'rating': 4.3,
        'completedConventions': 5,
        'specialties': ['Géométrique', 'Blackwork'],
        'portfolioImages': 32,
        'instagramFollowers': 4200,
        'message': 'Première participation à une convention, très motivé !',
      },
      {
        'id': '4',
        'tattooerName': 'Emma Style',
        'tattooerType': TattooerType.new_user,
        'status': RequestStatus.paid,
        'requestDate': '19/12/2024',
        'standSize': '2x2m',
        'standPrice': 280.0,
        'preferredLocation': null,
        'paymentType': 'Paiement comptant',
        'rating': 0,
        'completedConventions': 0,
        'specialties': ['Minimaliste', 'Fine Line'],
        'portfolioImages': 18,
        'instagramFollowers': 1800,
        'message': 'Nouvelle sur Kipik, j\'aimerais commencer par une petite convention pour faire mes preuves.',
      },
      {
        'id': '5',
        'tattooerName': 'David Iron',
        'tattooerType': TattooerType.verified,
        'status': RequestStatus.rejected,
        'requestDate': '18/12/2024',
        'standSize': '4x4m',
        'standPrice': 680.0,
        'preferredLocation': 'Angle de salle',
        'paymentType': 'Paiement fractionné 4x',
        'rating': 4.9,
        'completedConventions': 25,
        'specialties': ['Old School', 'Pin-up'],
        'portfolioImages': 89,
        'instagramFollowers': 15600,
        'message': null,
      },
    ];
  }
}