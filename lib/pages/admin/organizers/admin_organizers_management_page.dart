// lib/pages/admin/organizers/admin_organizers_management_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/services/organisateur/firebase_organisateur_service.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_admin.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/core/database_manager.dart';

class AdminOrganizersManagementPage extends StatefulWidget {
  const AdminOrganizersManagementPage({super.key});

  @override
  State<AdminOrganizersManagementPage> createState() => _AdminOrganizersManagementPageState();
}

class _AdminOrganizersManagementPageState extends State<AdminOrganizersManagementPage> 
    with TickerProviderStateMixin {
  final FirebaseOrganisateurService _organizerService = FirebaseOrganisateurService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isLoading = true;
  
  // Statistiques
  int _totalOrganizers = 0;
  int _verifiedOrganizers = 0;
  int _totalConventions = 0;
  
  DatabaseManager get _databaseManager => DatabaseManager.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedFilter = 'pending';
              break;
            case 1:
              _selectedFilter = 'verified';
              break;
            case 2:
              _selectedFilter = 'suspended';
              break;
            case 3:
            default:
              _selectedFilter = 'all';
              break;
          }
        });
      }
    });
    
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final metrics = await _organizerService.getActivityMetrics();
      if (mounted) {
        setState(() {
          _totalOrganizers = metrics['total_organizers'] ?? 0;
          _verifiedOrganizers = metrics['verified_organizers'] ?? 0;
          _totalConventions = metrics['total_conventions'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement stats organisateurs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KipikTheme.noir,
      appBar: CustomAppBarKipik(
        title: 'Admin Organisateurs',
        showBackButton: true,
      ),
      endDrawer: const CustomDrawerAdmin(),
      body: _isLoading
          ? Center(child: KipikTheme.loading())
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: KipikTheme.rouge,
              child: KipikTheme.pageContent(
                children: [
                  const SizedBox(height: 16),
                  
                  // Titre principal style Kipik
                  Text(
                    'Gestion des Organisateurs',
                    textAlign: TextAlign.center,
                    style: KipikTheme.titleStyle.copyWith(
                      color: KipikTheme.rouge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Sous-titre
                  Text(
                    'Gérez les demandes et statuts',
                    textAlign: TextAlign.center,
                    style: KipikTheme.subtitleStyle.copyWith(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Indicateur mode démo avec helper
                  if (_databaseManager.isDemoMode) ...[
                    KipikTheme.demoBadge(customText: 'MODE DÉMO ADMIN'),
                    const SizedBox(height: 16),
                  ],
                  
                  // Barre de recherche avec helper
                  KipikTheme.searchField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    hintText: 'Rechercher un organisateur...',
                    backgroundColor: KipikTheme.rouge.withOpacity(0.2),
                    textColor: KipikTheme.blanc,
                  ),
                  const SizedBox(height: 16),
                  
                  // Statistiques style Kipik
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.business_center,
                          title: 'Total',
                          value: '$_totalOrganizers',
                          color: KipikTheme.rouge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.verified,
                          title: 'Vérifiés',
                          value: '$_verifiedOrganizers',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.event,
                          title: 'Conventions',
                          value: '$_totalConventions',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Onglets style Kipik
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: KipikTheme.rouge.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: KipikTheme.blanc,
                      unselectedLabelColor: KipikTheme.rouge,
                      indicator: BoxDecoration(
                        color: KipikTheme.rouge,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelStyle: TextStyle(
                        fontFamily: KipikTheme.fontTitle,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontFamily: KipikTheme.fontTitle,
                        fontSize: 12,
                      ),
                      tabs: const [
                        Tab(text: 'Attente'),
                        Tab(text: 'Vérifiés'),
                        Tab(text: 'Suspendus'),
                        Tab(text: 'Tous'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Liste des organisateurs
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrganizersList('pending'),
                        _buildOrganizersList('verified'),
                        _buildOrganizersList('suspended'),
                        _buildOrganizersList('all'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: KipikTheme.blanc, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: KipikTheme.fontTitle,
              fontSize: 18,
              color: KipikTheme.blanc,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: KipikTheme.blanc.withOpacity(0.7),
              fontFamily: KipikTheme.fontTitle,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizersList(String filter) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrganizersStream(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: KipikTheme.loading());
        }

        if (snapshot.hasError) {
          return KipikTheme.errorState(
            title: 'Erreur de chargement',
            message: 'Impossible de charger les organisateurs',
            onRetry: () => setState(() {}),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return KipikTheme.emptyState(
            icon: Icons.business_center_outlined,
            title: 'Aucun organisateur',
            message: _getEmptyMessage(filter),
          );
        }

        var organizers = snapshot.data!.docs;
        
        // Filtrage par recherche
        if (_searchQuery.isNotEmpty) {
          organizers = organizers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final company = (data['company'] ?? '').toString().toLowerCase();
            
            return name.contains(_searchQuery) || 
                   email.contains(_searchQuery) || 
                   company.contains(_searchQuery);
          }).toList();
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: organizers.length,
          itemBuilder: (context, index) {
            final doc = organizers[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildOrganizerCard(doc.id, data);
          },
        );
      },
    );
  }

  String _getEmptyMessage(String filter) {
    switch (filter) {
      case 'pending':
        return 'Aucune demande en attente';
      case 'verified':
        return 'Aucun organisateur vérifié';
      case 'suspended':
        return 'Aucun organisateur suspendu';
      default:
        return 'Aucun organisateur inscrit';
    }
  }

  Stream<QuerySnapshot> _getOrganizersStream(String filter) {
    final collection = FirebaseFirestore.instance.collection('organizers');
    
    switch (filter) {
      case 'pending':
        return collection
            .where('isVerified', isEqualTo: false)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots();
      
      case 'verified':
        return collection
            .where('isVerified', isEqualTo: true)
            .where('status', isEqualTo: 'verified')
            .orderBy('createdAt', descending: true)
            .snapshots();
      
      case 'suspended':
        return collection
            .where('status', isEqualTo: 'suspended')
            .orderBy('createdAt', descending: true)
            .snapshots();
      
      case 'all':
      default:
        return collection
            .orderBy('createdAt', descending: true)
            .snapshots();
    }
  }

  Widget _buildOrganizerCard(String organizerId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final createdAt = data['createdAt'] as Timestamp?;
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: KipikTheme.kipikCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar style Kipik
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: KipikTheme.blanc.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (data['name'] ?? 'O').toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: KipikTheme.blanc,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: KipikTheme.fontTitle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Nom non défini',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: KipikTheme.fontTitle,
                          color: KipikTheme.blanc,
                        ),
                      ),
                      if (data['company'] != null) ...[
                        Text(
                          data['company'],
                          style: TextStyle(
                            fontSize: 14,
                            color: KipikTheme.blanc.withOpacity(0.7),
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                      Text(
                        data['email'] ?? 'Email non défini',
                        style: TextStyle(
                          fontSize: 12,
                          color: KipikTheme.blanc.withOpacity(0.6),
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge statut avec helper
                KipikTheme.statusBadge(
                  text: _getStatusText(status),
                  color: _getStatusColor(status),
                  icon: _getStatusIcon(status),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Statistiques en ligne
            Row(
              children: [
                _buildStatChip(
                  Icons.event,
                  '${stats['totalConventions'] ?? 0}',
                  'conventions',
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  Icons.people,
                  '${stats['totalTattooers'] ?? 0}',
                  'tatoueurs',
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  Icons.euro,
                  '${stats['totalRevenue'] ?? 0}',
                  'revenus',
                ),
              ],
            ),
            
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Inscrit le ${_formatDate(createdAt.toDate())}',
                style: TextStyle(
                  fontSize: 11,
                  color: KipikTheme.blanc.withOpacity(0.6),
                  fontFamily: 'Roboto',
                ),
              ),
            ],
            
            // Actions
            const SizedBox(height: 12),
            _buildActionButtons(organizerId, status, data),
          ],
        ),
      ),
    );
  }

  // Helpers pour les statuts
  String _getStatusText(String status) {
    switch (status) {
      case 'verified': return 'Vérifié';
      case 'suspended': return 'Suspendu';
      default: return 'Attente';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified': return Colors.green;
      case 'suspended': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified': return Icons.check_circle;
      case 'suspended': return Icons.block;
      default: return Icons.hourglass_empty;
    }
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: KipikTheme.blanc.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: KipikTheme.blanc),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: KipikTheme.fontTitle,
                      color: KipikTheme.blanc,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: KipikTheme.blanc.withOpacity(0.7),
                      fontFamily: 'Roboto',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String organizerId, String status, Map<String, dynamic> data) {
    return Row(
      children: [
        if (status == 'pending') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _verifyOrganizer(organizerId),
              icon: const Icon(Icons.check, size: 14),
              label: Text(
                'Vérifier',
                style: TextStyle(fontFamily: KipikTheme.fontTitle, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: KipikTheme.blanc,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showSuspendDialog(organizerId),
              icon: const Icon(Icons.close, size: 14),
              label: Text(
                'Refuser',
                style: TextStyle(fontFamily: KipikTheme.fontTitle, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: KipikTheme.blanc,
                side: BorderSide(color: KipikTheme.blanc),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ] else if (status == 'verified') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showSuspendDialog(organizerId),
              icon: const Icon(Icons.pause, size: 14),
              label: Text(
                'Suspendre',
                style: TextStyle(fontFamily: KipikTheme.fontTitle, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: KipikTheme.blanc,
                side: BorderSide(color: KipikTheme.blanc),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ] else if (status == 'suspended') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _verifyOrganizer(organizerId),
              icon: const Icon(Icons.restore, size: 14),
              label: Text(
                'Réactiver',
                style: TextStyle(fontFamily: KipikTheme.fontTitle, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: KipikTheme.blanc,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _showOrganizerDetails(organizerId, data),
          icon: Icon(Icons.more_vert, color: KipikTheme.blanc),
          style: IconButton.styleFrom(
            backgroundColor: KipikTheme.blanc.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _verifyOrganizer(String organizerId) async {
    try {
      await _organizerService.verifyOrganizer(organizerId);
      
      if (mounted) {
        KipikTheme.showSuccessSnackBar(context, 'Organisateur vérifié avec succès');
      }
    } catch (e) {
      if (mounted) {
        KipikTheme.showErrorSnackBar(context, 'Erreur: $e');
      }
    }
  }

  Future<void> _showSuspendDialog(String organizerId) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Suspendre l\'organisateur',
          style: TextStyle(
            fontFamily: KipikTheme.fontTitle,
            color: KipikTheme.rouge,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voulez-vous vraiment suspendre cet organisateur ?',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Raison de la suspension',
                labelStyle: const TextStyle(fontFamily: 'Roboto'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: KipikTheme.rouge),
                ),
              ),
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: KipikTheme.fontTitle,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Suspendre',
              style: TextStyle(
                fontFamily: KipikTheme.fontTitle,
                color: KipikTheme.blanc,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _organizerService.suspendOrganizer(
          organizerId,
          reasonController.text.isNotEmpty 
              ? reasonController.text 
              : 'Suspension administrative',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Organisateur suspendu',
                style: TextStyle(fontFamily: KipikTheme.fontTitle),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          KipikTheme.showErrorSnackBar(context, 'Erreur: $e');
        }
      }
    }
    
    reasonController.dispose();
  }

  void _showOrganizerDetails(String organizerId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: KipikTheme.blanc,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle style Kipik
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: KipikTheme.rouge,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Détails Organisateur',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: KipikTheme.fontTitle,
                        color: KipikTheme.rouge,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildDetailSection('Informations générales', [
                      _buildDetailRow('Nom', data['name'] ?? 'Non défini'),
                      _buildDetailRow('Email', data['email'] ?? 'Non défini'),
                      _buildDetailRow('Téléphone', data['phone'] ?? 'Non défini'),
                      _buildDetailRow('Entreprise', data['company'] ?? 'Non défini'),
                      _buildDetailRow('Statut', data['status'] ?? 'pending'),
                      _buildDetailRow('Vérifié', (data['isVerified'] ?? false) ? 'Oui' : 'Non'),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    _buildDetailSection('Statistiques', [
                      _buildDetailRow('Total conventions', '${(data['stats'] ?? {})['totalConventions'] ?? 0}'),
                      _buildDetailRow('Total tatoueurs', '${(data['stats'] ?? {})['totalTattooers'] ?? 0}'),
                      _buildDetailRow('Total visiteurs', '${(data['stats'] ?? {})['totalVisitors'] ?? 0}'),
                      _buildDetailRow('Revenus totaux', '${(data['stats'] ?? {})['totalRevenue'] ?? 0}€'),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            fontSize: 18,
            fontFamily: KipikTheme.fontTitle,
            color: KipikTheme.rouge,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: KipikTheme.fontTitle,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}