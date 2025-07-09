// lib/pages/pro/flashs/gestion_flashs_page.dart

import 'package:flutter/material.dart';
import '../../../theme/kipik_theme.dart';
import '../../../services/flash/flash_service.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../../models/flash/flash.dart';
import '../../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../shared/flashs/flash_detail_page.dart';
import 'publier_flash_page.dart';

class GestionFlashsPage extends StatefulWidget {
  const GestionFlashsPage({Key? key}) : super(key: key);

  @override
  State<GestionFlashsPage> createState() => _GestionFlashsPageState();
}

class _GestionFlashsPageState extends State<GestionFlashsPage> with TickerProviderStateMixin {
  final FlashService _flashService = FlashService.instance;
  late TabController _tabController;
  
  List<Flash> _allFlashs = [];
  List<Flash> _publishedFlashs = [];
  List<Flash> _reservedFlashs = [];
  List<Flash> _completedFlashs = [];
  
  bool _isLoading = true;
  String _selectedFilter = 'Tous';
  final List<String> _filters = ['Tous', 'Réalisme', 'Japonais', 'Minimaliste', 'Géométrique'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFlashs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFlashs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final flashs = await _flashService.getFlashsByArtist(currentUser.uid);
      
      setState(() {
        _allFlashs = flashs;
        _publishedFlashs = flashs.where((f) => f.status == FlashStatus.published).toList();
        _reservedFlashs = flashs.where((f) => [FlashStatus.reserved, FlashStatus.booked].contains(f.status)).toList();
        _completedFlashs = flashs.where((f) => f.status == FlashStatus.completed).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des flashs');
    }
  }

  Future<void> _deleteFlash(Flash flash) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le flash'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${flash.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implémenter deleteFlash dans FlashService
        _showSuccessSnackBar('Flash supprimé avec succès');
        _loadFlashs(); // Recharger la liste
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: 'Mes Flashs',
        showBackButton: true,
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
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header avec statistiques
                _buildStatsHeader(),
                
                // Filtres
                _buildFilters(),
                
                // Tabs
                _buildTabBar(),
                
                // Content des tabs
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildFlashList(_allFlashs, 'Aucun flash trouvé'),
                            _buildFlashList(_publishedFlashs, 'Aucun flash publié'),
                            _buildFlashList(_reservedFlashs, 'Aucune réservation'),
                            _buildFlashList(_completedFlashs, 'Aucun flash terminé'),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Bouton d'ajout
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToPublishFlash(),
        backgroundColor: KipikTheme.rouge,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouveau Flash',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalViews = _allFlashs.fold<int>(0, (sum, flash) => sum + flash.views);
    final totalLikes = _allFlashs.fold<int>(0, (sum, flash) => sum + flash.likes);
    final totalSaves = _allFlashs.fold<int>(0, (sum, flash) => sum + flash.saves);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Icon(Icons.dashboard, color: KipikTheme.rouge),
              const SizedBox(width: 8),
              Text(
                'Tableau de bord',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KipikTheme.rouge,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Flashs',
                  _allFlashs.length.toString(),
                  Icons.flash_on,
                  KipikTheme.rouge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Vues',
                  _formatNumber(totalViews),
                  Icons.visibility,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Likes',
                  _formatNumber(totalLikes),
                  Icons.favorite,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Favoris',
                  _formatNumber(totalSaves),
                  Icons.bookmark,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
                // TODO: Implémenter le filtrage
              },
              selectedColor: KipikTheme.rouge.withOpacity(0.3),
              checkmarkColor: KipikTheme.rouge,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: KipikTheme.rouge,
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          color: KipikTheme.rouge.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        tabs: [
          Tab(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Tous', style: TextStyle(fontSize: 12)),
                Text('${_allFlashs.length}', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Publiés', style: TextStyle(fontSize: 12)),
                Text('${_publishedFlashs.length}', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Réservés', style: TextStyle(fontSize: 12)),
                Text('${_reservedFlashs.length}', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Terminés', style: TextStyle(fontSize: 12)),
                Text('${_completedFlashs.length}', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashList(List<Flash> flashs, String emptyMessage) {
    if (flashs.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flash_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Créez votre premier flash pour commencer',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFlashs,
      color: KipikTheme.rouge,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: flashs.length,
        itemBuilder: (context, index) {
          final flash = flashs[index];
          return _buildFlashCard(flash);
        },
      ),
    );
  }

  Widget _buildFlashCard(Flash flash) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToFlashDetail(flash),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  flash.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre et prix
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            flash.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${flash.effectivePrice.toStringAsFixed(0)}€',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: KipikTheme.rouge,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Style et taille
                    Text(
                      '${flash.style} • ${flash.size}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Badges et statistiques
                    Row(
                      children: [
                        // Badge statut
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(flash.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getStatusColor(flash.status).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            flash.status.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(flash.status),
                            ),
                          ),
                        ),
                        
                        // Badge Flash Minute
                        if (flash.isMinuteFlash) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'MINUTE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                        
                        const Spacer(),
                        
                        // Statistiques
                        Row(
                          children: [
                            Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 2),
                            Text('${flash.views}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 8),
                            Icon(Icons.favorite, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 2),
                            Text('${flash.likes}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                onSelected: (action) => _handleFlashAction(action, flash),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 8),
                        Text('Voir'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  if (flash.status == FlashStatus.published)
                    const PopupMenuItem(
                      value: 'minute',
                      child: Row(
                        children: [
                          Icon(Icons.flash_on, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Flash Minute'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(FlashStatus status) {
    switch (status) {
      case FlashStatus.published:
        return Colors.green;
      case FlashStatus.reserved:
        return Colors.orange;
      case FlashStatus.booked:
        return Colors.blue;
      case FlashStatus.completed:
        return Colors.purple;
      case FlashStatus.withdrawn:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleFlashAction(String action, Flash flash) {
    switch (action) {
      case 'view':
        _navigateToFlashDetail(flash);
        break;
      case 'edit':
        _showInfoSnackBar('Modification flash - Bientôt disponible');
        break;
      case 'minute':
        _showInfoSnackBar('Création Flash Minute - Semaine 5');
        break;
      case 'delete':
        _deleteFlash(flash);
        break;
    }
  }

  void _navigateToFlashDetail(Flash flash) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashDetailPage(flash: flash),
      ),
    );
  }

  void _navigateToPublishFlash() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PublierFlashPage(),
      ),
    ).then((_) {
      // Recharger la liste après publication
      _loadFlashs();
    });
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KipikTheme.rouge,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}