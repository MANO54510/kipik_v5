import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/kipik_theme.dart';
import '../../models/flash/flash.dart';
import '../../models/flash/flash_booking_status.dart';
import '../../services/flash/flash_service.dart';
import '../../services/auth/secure_auth_service.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../shared/flashs/flash_detail_page.dart';

class MesFavorisFlashsPage extends StatefulWidget {
  const MesFavorisFlashsPage({Key? key}) : super(key: key);

  @override
  State<MesFavorisFlashsPage> createState() => _MesFavorisFlashsPageState();
}

class _MesFavorisFlashsPageState extends State<MesFavorisFlashsPage> 
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  
  List<Flash> _allFavorites = [];
  List<Flash> _availableFavorites = [];
  List<Flash> _unavailableFavorites = [];
  
  bool _isLoading = true;
  String _selectedFilter = 'Tous';
  
  final List<String> _filters = ['Tous', 'Disponibles', 'Flash Minute', 'Par prix'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
    
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) return;
      
      // Simuler le chargement des favoris
      await Future.delayed(const Duration(seconds: 1));
      
      // TODO: Remplacer par l'appel réel au service des favoris
      final allFlashs = await FlashService.instance.getAvailableFlashs(limit: 50);
      
      // Simuler des favoris (prendre les 10 premiers)
      _allFavorites = allFlashs.take(10).toList();
      
      _categorizeFavorites();
      
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des favoris');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _categorizeFavorites() {
    _availableFavorites = _allFavorites
        .where((f) => f.status == FlashStatus.published)
        .toList();
    
    _unavailableFavorites = _allFavorites
        .where((f) => f.status != FlashStatus.published)
        .toList();
  }

  Future<void> _removeFavorite(Flash flash) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Retirer des favoris',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Voulez-vous retirer "${flash.title}" de vos favoris ?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      _heartController.forward().then((_) {
        _heartController.reverse();
      });
      
      HapticFeedback.mediumImpact();
      
      // Appeler le service pour retirer des favoris
      try {
        await FlashService.instance.toggleFlashFavorite(
          userId: SecureAuthService.instance.currentUser?['uid'] ?? '',
          flashId: flash.id,
        );
        
        setState(() {
          _allFavorites.remove(flash);
          _categorizeFavorites();
        });
        
        _showSuccessSnackBar('Flash retiré des favoris');
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Mes Favoris',
        subtitle: '${_allFavorites.length} flashs sauvegardés',
        showBackButton: true,
        useProStyle: false,
        actions: [
          if (_allFavorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _showFilterOptions,
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
          AnimatedBuilder(
            animation: _heartAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _heartAnimation.value,
                child: Icon(
                  Icons.favorite,
                  size: 60,
                  color: KipikTheme.rouge,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Chargement de vos favoris...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_allFavorites.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFavoritesList(_allFavorites, 'Aucun favori'),
              _buildFavoritesList(_availableFavorites, 'Aucun flash disponible'),
              _buildFavoritesList(_unavailableFavorites, 'Tous vos favoris sont disponibles'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun favori',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sauvegardez des flashs pour les retrouver ici',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
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
        unselectedLabelColor: Colors.grey,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Tous'),
                const SizedBox(width: 4),
                Text(
                  '(${_allFavorites.length})',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Disponibles'),
                const SizedBox(width: 4),
                Text(
                  '(${_availableFavorites.length})',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Indisponibles'),
                const SizedBox(width: 4),
                Text(
                  '(${_unavailableFavorites.length})',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(List<Flash> flashs, String emptyMessage) {
    if (flashs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    // Appliquer le filtre
    List<Flash> filteredFlashs = flashs;
    switch (_selectedFilter) {
      case 'Disponibles':
        filteredFlashs = flashs.where((f) => f.status == FlashStatus.published).toList();
        break;
      case 'Flash Minute':
        filteredFlashs = flashs.where((f) => f.isMinuteFlash).toList();
        break;
      case 'Par prix':
        filteredFlashs = List.from(flashs)..sort((a, b) => a.price.compareTo(b.price));
        break;
    }
    
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: KipikTheme.rouge,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: filteredFlashs.length,
        itemBuilder: (context, index) {
          final flash = filteredFlashs[index];
          return _buildFavoriteCard(flash);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Flash flash) {
    final isAvailable = flash.status == FlashStatus.published;
    
    return GestureDetector(
      onTap: () => _viewFlashDetail(flash),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.network(
                flash.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              
              // Overlay si indisponible
              if (!isAvailable)
                Container(
                  color: Colors.black.withOpacity(0.6),
                  child: const Center(
                    child: Text(
                      'INDISPONIBLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              
              // Favorite button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeFavorite(flash),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedBuilder(
                      animation: _heartAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _heartAnimation.value,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Flash info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        flash.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (flash.isMinuteFlash)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'MINUTE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Text(
                            '${flash.effectivePrice.toInt()}€',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewFlashDetail(Flash flash) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashDetailPage(flash: flash),
      ),
    ).then((_) {
      // Recharger au retour au cas où le statut ait changé
      _loadFavorites();
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Filtrer par',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...List.generate(_filters.length, (index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter;
              
              return ListTile(
                leading: Icon(
                  _getFilterIcon(filter),
                  color: isSelected ? KipikTheme.rouge : Colors.grey,
                ),
                title: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? KipikTheme.rouge : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: KipikTheme.rouge)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Tous':
        return Icons.all_inclusive;
      case 'Disponibles':
        return Icons.check_circle;
      case 'Flash Minute':
        return Icons.flash_on;
      case 'Par prix':
        return Icons.euro;
      default:
        return Icons.filter_list;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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