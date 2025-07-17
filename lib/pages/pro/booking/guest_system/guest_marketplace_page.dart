// lib/pages/pro/booking/guest_system/guest_marketplace_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/kipik_theme.dart';
import '../../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../../../core/database_manager.dart';
import '../../../../services/auth/secure_auth_service.dart';
import 'guest_proposal_page.dart';
import 'guest_contract_page.dart';

enum MarketplaceMode { browse, seeking, offering }
enum GuestFilter { all, style, location, duration, price }

class GuestMarketplacePage extends StatefulWidget {
  const GuestMarketplacePage({Key? key}) : super(key: key);

  @override
  State<GuestMarketplacePage> createState() => _GuestMarketplacePageState();
}

class _GuestMarketplacePageState extends State<GuestMarketplacePage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _fabController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;

  MarketplaceMode _selectedMode = MarketplaceMode.browse;
  GuestFilter _selectedFilter = GuestFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;
  
  final TextEditingController _searchController = TextEditingController();

  // Services
  SecureAuthService get _authService => SecureAuthService.instance;
  DatabaseManager get _databaseManager => DatabaseManager.instance;

  // Données
  List<Map<String, dynamic>> _allOffers = [];
  List<Map<String, dynamic>> _filteredOffers = [];
  Map<String, dynamic> _marketplaceStats = {
    'totalOffers': 0,
    'activeGuests': 0,
    'openShops': 0,
    'userOffers': 0,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMarketplaceData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fabController = AnimationController(
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
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fabController.forward();
    });
  }

  Future<void> _loadMarketplaceData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadOffers(),
        _loadStats(),
      ]);
      
      _applyFilters();
    } catch (e) {
      print('❌ Erreur chargement marketplace: $e');
      _setDefaultData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadOffers() async {
    try {
      if (_databaseManager.isDemoMode) {
        // Mode démo avec données simulées
        _allOffers = _generateDemoOffers();
      } else {
        // Mode production avec Firestore
        final snapshot = await _databaseManager.firestore
            .collection('guest_offers')
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();

        _allOffers = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        
        // Fallback si pas de données
        if (_allOffers.isEmpty) {
          _allOffers = _generateDemoOffers();
        }
      }
    } catch (e) {
      print('❌ Erreur chargement offres: $e');
      _allOffers = _generateDemoOffers();
    }
  }

  Future<void> _loadStats() async {
    try {
      if (_databaseManager.isDemoMode) {
        _marketplaceStats = {
          'totalOffers': _allOffers.length,
          'activeGuests': 12,
          'openShops': 8,
          'userOffers': 1,
        };
      } else {
        // Charger stats réelles depuis Firestore
        final offersCount = await _databaseManager.firestore
            .collection('guest_offers')
            .where('status', isEqualTo: 'active')
            .count()
            .get();

        final guestsCount = _allOffers.where((o) => o['type'] == 'guest').length;
        final shopsCount = _allOffers.where((o) => o['type'] == 'shop').length;

        _marketplaceStats = {
          'totalOffers': offersCount.count ?? _allOffers.length,
          'activeGuests': guestsCount,
          'openShops': shopsCount,
          'userOffers': 1,
        };
      }
    } catch (e) {
      print('❌ Erreur chargement stats: $e');
      _marketplaceStats = {
        'totalOffers': _allOffers.length,
        'activeGuests': 0,
        'openShops': 0,
        'userOffers': 0,
      };
    }
  }

  void _setDefaultData() {
    _allOffers = _generateDemoOffers();
    _marketplaceStats = {
      'totalOffers': _allOffers.length,
      'activeGuests': 8,
      'openShops': 4,
      'userOffers': 0,
    };
  }

  List<Map<String, dynamic>> _generateDemoOffers() {
    return [
      {
        'id': '1',
        'type': 'shop',
        'name': 'Ink Studio Paris',
        'location': 'Paris 9ème, France',
        'rating': 4.8,
        'reviewCount': 127,
        'avatar': null,
        'availableDates': '15-25 Juin 2025',
        'styles': ['Réalisme', 'Japonais', 'Portrait'],
        'description': 'Studio parisien haut de gamme, clientèle internationale. Équipe expérimentée et ambiance professionnelle.',
        'fullDescription': 'Studio de tatouage réputé au cœur de Paris 9ème. Nous accueillons des artistes guests talentueux pour des collaborations enrichissantes. Notre clientèle internationale et notre équipe expérimentée offrent un environnement idéal pour développer votre art et élargir votre réseau.',
        'commission': 25,
        'accommodation': true,
        'duration': '10 jours',
        'isVerified': true,
        'isPremium': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': '2',
        'type': 'guest',
        'name': 'Alex Martinez',
        'location': 'Lyon, France',
        'rating': 4.9,
        'reviewCount': 89,
        'avatar': null,
        'availableDates': '1-15 Juillet 2025',
        'styles': ['Blackwork', 'Géométrique', 'Minimaliste'],
        'description': 'Tatoueur spécialisé blackwork et géométrique. 6 ans d\'expérience, portfolio solide.',
        'fullDescription': 'Tatoueur professionnel spécialisé dans le blackwork et les designs géométriques. Avec 6 ans d\'expérience, je propose des créations uniques et précises. Recherche des opportunités de guest pour découvrir de nouveaux environnements et partager mon savoir-faire.',
        'commission': 30,
        'accommodation': false,
        'duration': '2 semaines',
        'isVerified': true,
        'isPremium': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': '3',
        'type': 'shop',
        'name': 'Urban Art Marseille',
        'location': 'Marseille, France',
        'rating': 4.6,
        'reviewCount': 156,
        'avatar': null,
        'availableDates': 'Août-Septembre 2025',
        'styles': ['Aquarelle', 'Neo-traditional', 'Couleur'],
        'description': 'Shop moderne sur le Vieux-Port. Spécialisé couleur et aquarelle.',
        'fullDescription': 'Studio moderne situé sur le Vieux-Port de Marseille. Nous sommes spécialisés dans les techniques couleur et aquarelle. Notre équipe jeune et dynamique accueille des artistes guests pour des collaborations créatives dans une ambiance décontractée.',
        'commission': 20,
        'accommodation': true,
        'duration': 'Flexible',
        'isVerified': true,
        'isPremium': false,
        'createdAt': DateTime.now().subtract(const Duration(hours: 18)),
      },
      {
        'id': '4',
        'type': 'guest',
        'name': 'Sophie Chen',
        'location': 'Nice, France',
        'rating': 4.7,
        'reviewCount': 134,
        'avatar': null,
        'availableDates': '20-30 Juin 2025',
        'styles': ['Japonais', 'Traditionnel', 'Oriental'],
        'description': 'Artiste spécialisée tatouage japonais traditionnel. Formation au Japon.',
        'fullDescription': 'Artiste tatouage spécialisée dans l\'art japonais traditionnel. Formée directement au Japon, je maîtrise les techniques ancestrales et propose des créations authentiques. Je recherche des collaborations avec des shops partageant les mêmes valeurs artistiques.',
        'commission': 35,
        'accommodation': true,
        'duration': '10 jours',
        'isVerified': true,
        'isPremium': true,
        'createdAt': DateTime.now().subtract(const Duration(hours: 12)),
      },
    ];
  }

  void _applyFilters() {
    setState(() {
      _filteredOffers = _allOffers.where((offer) {
        // Filtre par mode
        if (_selectedMode == MarketplaceMode.seeking) {
          if (offer['type'] != 'shop') return false;
        } else if (_selectedMode == MarketplaceMode.offering) {
          if (offer['type'] != 'guest') return false;
        }
        
        // Filtre par recherche
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!offer['name'].toLowerCase().contains(query) &&
              !offer['location'].toLowerCase().contains(query) &&
              !offer['styles'].any((style) => 
                style.toLowerCase().contains(query))) {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      // Trier par premium, vérifié, puis rating
      _filteredOffers.sort((a, b) {
        if (a['isPremium'] == true && b['isPremium'] != true) return -1;
        if (a['isPremium'] != true && b['isPremium'] == true) return 1;
        if (a['isVerified'] == true && b['isVerified'] != true) return -1;
        if (a['isVerified'] != true && b['isVerified'] == true) return 1;
        return (b['rating'] as double).compareTo(a['rating'] as double);
      });
    });
  }

  Future<void> _refreshData() async {
    await _loadMarketplaceData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Guest Marketplace',
        subtitle: 'Réseau professionnel tatouage',
        showBackButton: true,
        useProStyle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _hasActiveFilters() ? Colors.amber : Colors.white,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filtres',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton.extended(
              onPressed: _createGuestOffer,
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Nouvelle offre',
                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
              ),
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
            child: _isLoading 
                ? _buildLoadingState()
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    color: KipikTheme.rouge,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildContent(),
                    ),
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
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement du marketplace...',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildHeader(),
          const SizedBox(height: 16),
          _buildModeSelector(),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildStatsHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildOffersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.9),
            Colors.purple.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.public,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Guest Network',
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    if (_databaseManager.isDemoMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DÉMO',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Connectez-vous avec des professionnels',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
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
        children: MarketplaceMode.values.map((mode) {
          final isSelected = _selectedMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = mode;
                });
                _applyFilters();
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? LinearGradient(
                    colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
                  ) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getModeIcon(mode),
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getModeLabel(mode),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Rechercher par ville, style, nom...',
          hintStyle: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.grey[500],
          ),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: KipikTheme.rouge),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.8),
            Colors.purple.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Offres actives', 
            '${_marketplaceStats['totalOffers']}', 
            Icons.local_offer
          ),
          _buildStatItem(
            'Tatoueurs', 
            '${_marketplaceStats['activeGuests']}', 
            Icons.person
          ),
          _buildStatItem(
            'Shops', 
            '${_marketplaceStats['openShops']}', 
            Icons.store
          ),
        ],
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
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildOffersList() {
    if (_filteredOffers.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredOffers.length,
        itemBuilder: (context, index) {
          final offer = _filteredOffers[index];
          return _buildOfferCard(offer);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune offre trouvée',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres ou créez une nouvelle offre',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createGuestOffer,
            icon: const Icon(Icons.add),
            label: const Text('Créer une offre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final isGuestOffer = offer['type'] == 'guest';
    final gradientColors = isGuestOffer 
        ? [Colors.blue.withOpacity(0.8), Colors.blue.withOpacity(0.6)]
        : [Colors.purple.withOpacity(0.8), Colors.purple.withOpacity(0.6)];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: offer['isPremium'] == true
            ? Border.all(color: Colors.amber.withOpacity(0.5), width: 2)
            : null,
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
          // En-tête avec gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isGuestOffer ? Icons.person : Icons.store,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    if (offer['isVerified'] == true)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    if (offer['isPremium'] == true)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer['name'],
                              style: const TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isGuestOffer ? 'GUEST' : 'SHOP',
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
                      const SizedBox(height: 4),
                      Text(
                        offer['location'],
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${offer['rating']} • ${offer['reviewCount']} avis',
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
              ],
            ),
          ),
          
          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dates disponibles
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: KipikTheme.rouge, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Disponible: ${offer['availableDates']}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Styles
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (offer['styles'] as List).map<Widget>((style) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        style,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 12),
                
                // Description
                Text(
                  offer['description'],
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Détails commission/hébergement
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Commission',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${offer['commission']}%',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hébergement',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            offer['accommodation'] ? 'Inclus' : 'Non inclus',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: offer['accommodation'] ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Durée',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            offer['duration'],
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewOfferDetails(offer),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text(
                          'Voir détails',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makeProposal(offer),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text(
                          'Contacter',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KipikTheme.rouge,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
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

  // Actions
  void _createGuestOffer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GuestProposalPage(mode: ProposalMode.create),
      ),
    );
  }

  void _makeProposal(Map<String, dynamic> offer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuestProposalPage(
          mode: ProposalMode.respond,
          targetOffer: offer,
        ),
      ),
    );
  }

  void _viewOfferDetails(Map<String, dynamic> offer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: _buildOfferDetailsContent(offer, scrollController),
          );
        },
      ),
    );
  }

  Widget _buildOfferDetailsContent(Map<String, dynamic> offer, ScrollController scrollController) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: KipikTheme.rouge.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          offer['type'] == 'guest' ? Icons.person : Icons.store,
                          color: KipikTheme.rouge,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer['name'],
                              style: const TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 20,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              offer['location'],
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${offer['rating']} (${offer['reviewCount']} avis)',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description complète
                  _buildDetailSection('Description', offer['fullDescription'] ?? offer['description']),
                  
                  // Styles et spécialités
                  _buildDetailSection('Styles & Spécialités', (offer['styles'] as List).join(', ')),
                  
                  // Disponibilités
                  _buildDetailSection('Disponibilités', offer['availableDates']),
                  
                  // Conditions
                  _buildDetailSection('Conditions', 
                    'Commission: ${offer['commission']}%\n'
                    'Hébergement: ${offer['accommodation'] ? 'Inclus' : 'Non inclus'}\n'
                    'Durée: ${offer['duration']}'
                  ),
                  
                  const SizedBox(height: 80), // Espace pour les boutons
                ],
              ),
            ),
          ),
          
          // Boutons d'action
          Container(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Fermer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _makeProposal(offer);
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Contacter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KipikTheme.rouge,
                      foregroundColor: Colors.white,
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

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Filtres',
          style: TextStyle(fontFamily: 'PermanentMarker'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GuestFilter.values.map((filter) {
            return RadioListTile<GuestFilter>(
              title: Text(_getFilterLabel(filter)),
              value: filter,
              groupValue: _selectedFilter,
              activeColor: KipikTheme.rouge,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
                _applyFilters();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // Helper methods
  bool _hasActiveFilters() {
    return _selectedFilter != GuestFilter.all || _searchQuery.isNotEmpty;
  }

  String _getModeLabel(MarketplaceMode mode) {
    switch (mode) {
      case MarketplaceMode.browse:
        return 'Parcourir';
      case MarketplaceMode.seeking:
        return 'Chercher Shop';
      case MarketplaceMode.offering:
        return 'Chercher Guest';
    }
  }

  IconData _getModeIcon(MarketplaceMode mode) {
    switch (mode) {
      case MarketplaceMode.browse:
        return Icons.explore;
      case MarketplaceMode.seeking:
        return Icons.store;
      case MarketplaceMode.offering:
        return Icons.person_search;
    }
  }

  String _getFilterLabel(GuestFilter filter) {
    switch (filter) {
      case GuestFilter.all:
        return 'Tous';
      case GuestFilter.style:
        return 'Par style';
      case GuestFilter.location:
        return 'Par localisation';
      case GuestFilter.duration:
        return 'Par durée';
      case GuestFilter.price:
        return 'Par commission';
    }
  }
}