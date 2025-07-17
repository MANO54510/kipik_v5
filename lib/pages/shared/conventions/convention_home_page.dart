// lib/pages/pro/conventions/convention_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../widgets/common/buttons/tattoo_assistant_button.dart';

enum UserType { admin, organizer, customer, pro }
enum ViewMode { map, list, grid }
enum ConventionSize { small, medium, large, giant }
enum ConventionDuration { oneDay, twoDays, threeDays, weekend, week }

class ConventionHomePage extends StatefulWidget {
  final UserType userType;
  
  const ConventionHomePage({
    Key? key,
    this.userType = UserType.customer,
  }) : super(key: key);

  @override
  State<ConventionHomePage> createState() => _ConventionHomePageState();
}

class _ConventionHomePageState extends State<ConventionHomePage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _mapController;
  late AnimationController _filterController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _mapAnimation;
  late Animation<double> _filterAnimation;

  ViewMode _viewMode = ViewMode.map;
  bool _showFilters = false;
  bool _isLoading = false;
  String _searchQuery = '';
  
  // Filtres
  int _distanceRadius = 100; // km
  Set<int> _selectedMonths = {};
  Set<ConventionSize> _selectedSizes = {};
  Set<ConventionDuration> _selectedDurations = {};
  RangeValues _priceRange = const RangeValues(0, 1000);
  String _selectedRegion = 'Toutes';

  List<Map<String, dynamic>> _conventions = [];
  List<Map<String, dynamic>> _filteredConventions = [];

  final TextEditingController _searchController = TextEditingController();

  // Couleurs par mois
  final Map<int, Color> _monthColors = {
    1: const Color(0xFF6BB6FF), // Janvier - Bleu glacier
    2: const Color(0xFF9B59B6), // Février - Violet tendre
    3: const Color(0xFF2ECC71), // Mars - Vert printemps
    4: const Color(0xFFF8BBD9), // Avril - Rose poudré
    5: const Color(0xFFF1C40F), // Mai - Jaune soleil
    6: const Color(0xFFFF8C00), // Juin - Orange vif
    7: const Color(0xFFE74C3C), // Juillet - Rouge vibrant
    8: const Color(0xFFFF6347), // Août - Orange brûlé
    9: const Color(0xFF8B4513), // Septembre - Marron automne
    10: const Color(0xFFFFB347), // Octobre - Jaune orangé
    11: const Color(0xFFA0522D), // Novembre - Terre de Sienne
    12: const Color(0xFF708090), // Décembre - Bleu-gris
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadConventions();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _mapController.dispose();
    _filterController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _mapController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _filterController = AnimationController(
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
    
    _mapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mapController, curve: Curves.elasticOut),
    );
    
    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _filterController, curve: Curves.easeOut),
    );

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _mapController.forward();
    });
  }

  void _loadConventions() {
    setState(() => _isLoading = true);
    
    // Simulation de chargement des conventions
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _conventions = _generateSampleConventions();
        _filteredConventions = _conventions;
        _isLoading = false;
      });
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Conventions',
        subtitle: _getUserTypeSubtitle(),
        showBackButton: true,
        useProStyle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: _toggleFilters,
          ),
          if (widget.userType == UserType.organizer || widget.userType == UserType.admin)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _createConvention,
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.userType == UserType.customer || widget.userType == UserType.pro)
            FloatingActionButton(
              heroTag: "favorites",
              onPressed: _viewFavorites,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.favorite, color: Colors.white),
            ),
          const SizedBox(height: 16),
          const TattooAssistantButton(),
        ],
      ),
      body: Stack(
        children: [
          // Background charbon
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

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildSearchAndControls(),
        if (_showFilters) ...[
          const SizedBox(height: 16),
          _buildFiltersSection(),
        ],
        const SizedBox(height: 16),
        _buildStatsHeader(),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _isLoading ? _buildLoadingState() : _buildMainContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Barre de recherche
          Container(
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher une convention, ville...',
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
                      setState(() {
                        _searchQuery = '';
                      });
                      _applyFilters();
                    },
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Contrôles de vue
          Container(
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
              children: ViewMode.values.map((mode) {
                final isSelected = _viewMode == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _viewMode = mode;
                      });
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
                          Icon(
                            _getViewModeIcon(mode),
                            color: isSelected ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getViewModeLabel(mode),
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _filterAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: KipikTheme.rouge, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Filtres avancés',
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text(
                          'Réinitialiser',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Distance
                  _buildFilterSlider(
                    'Distance',
                    'Rayon de $_distanceRadius km',
                    _distanceRadius.toDouble(),
                    0,
                    500,
                    (value) {
                      setState(() {
                        _distanceRadius = value.toInt();
                      });
                      _applyFilters();
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Mois
                  _buildMonthSelector(),
                  
                  const SizedBox(height: 20),
                  
                  // Taille des conventions
                  _buildSizeSelector(),
                  
                  const SizedBox(height: 20),
                  
                  // Durée des conventions
                  _buildDurationSelector(),
                  
                  const SizedBox(height: 20),
                  
                  // Budget stand (pour les pros)
                  if (widget.userType == UserType.pro)
                    _buildPriceRangeSlider(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSlider(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / 10).toInt(),
          activeColor: KipikTheme.rouge,
          label: subtitle,
          onChanged: onChanged,
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mois',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(12, (index) {
            final month = index + 1;
            final isSelected = _selectedMonths.contains(month);
            final monthColor = _monthColors[month]!;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedMonths.remove(month);
                  } else {
                    _selectedMonths.add(month);
                  }
                });
                _applyFilters();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? monthColor : monthColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: monthColor),
                ),
                child: Text(
                  _getMonthName(month),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : monthColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Taille de l\'événement',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ConventionSize.values.map((size) {
            final isSelected = _selectedSizes.contains(size);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSizes.remove(size);
                  } else {
                    _selectedSizes.add(size);
                  }
                });
                _applyFilters();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? KipikTheme.rouge : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? KipikTheme.rouge : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSizeIcon(size),
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getSizeLabel(size),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Durée de l\'événement',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ConventionDuration.values.map((duration) {
            final isSelected = _selectedDurations.contains(duration);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDurations.remove(duration);
                  } else {
                    _selectedDurations.add(duration);
                  }
                });
                _applyFilters();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getDurationLabel(duration),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.blue,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget stand',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 2000,
          divisions: 20,
          activeColor: KipikTheme.rouge,
          labels: RangeLabels(
            '${_priceRange.start.toInt()}€',
            '${_priceRange.end.toInt()}€',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
            _applyFilters();
          },
        ),
        Text(
          'De ${_priceRange.start.toInt()}€ à ${_priceRange.end.toInt()}€',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final totalConventions = _conventions.length;
    final filteredCount = _filteredConventions.length;
    final thisMonthCount = _filteredConventions
        .where((c) => c['month'] == DateTime.now().month)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.8),
              Colors.blue.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', '$totalConventions', Icons.event),
            _buildStatItem('Trouvées', '$filteredCount', Icons.search),
            _buildStatItem('Ce mois', '$thisMonthCount', Icons.calendar_today),
          ],
        ),
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Chargement des conventions...',
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

  Widget _buildMainContent() {
    switch (_viewMode) {
      case ViewMode.map:
        return _buildMapView();
      case ViewMode.list:
        return _buildListView();
      case ViewMode.grid:
        return _buildGridView();
    }
  }

  Widget _buildMapView() {
    return AnimatedBuilder(
      animation: _mapAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _mapAnimation.value,
          child: Container(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Carte de France simulée
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[50]!,
                          Colors.blue[100]!,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Carte interactive France',
                            style: TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Intégration Google Maps',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Points de conventions simulés
                  ..._generateMapPoints(),
                  
                  // Légende des couleurs
                  Positioned(
                    top: 20,
                    right: 20,
                    child: _buildMapLegend(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Légende',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(4, (index) {
            final months = [
              [1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]
            ];
            final seasonNames = ['Hiver', 'Printemps', 'Été', 'Automne'];
            final firstMonth = months[index][0];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _monthColors[firstMonth],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    seasonNames[index],
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _generateMapPoints() {
    // Positions simulées sur la carte de France
    final positions = [
      {'top': 0.3, 'left': 0.2}, // Nord
      {'top': 0.4, 'left': 0.7}, // Est
      {'top': 0.7, 'left': 0.3}, // Sud-Ouest
      {'top': 0.6, 'left': 0.8}, // Sud-Est
      {'top': 0.5, 'left': 0.5}, // Centre
    ];
    
    return positions.asMap().entries.map((entry) {
      final index = entry.key;
      final pos = entry.value;
      final convention = _filteredConventions.length > index 
          ? _filteredConventions[index] 
          : null;
      
      if (convention == null) return const SizedBox.shrink();
      
      final monthColor = _monthColors[convention['month']] ?? Colors.grey;
      
      return Positioned(
        top: MediaQuery.of(context).size.height * pos['top']! * 0.4,
        left: MediaQuery.of(context).size.width * pos['left']! * 0.6,
        child: GestureDetector(
          onTap: () => _viewConventionDetails(convention),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: monthColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${convention['participantCount'] ~/ 10}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildListView() {
    if (_filteredConventions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _filteredConventions.length,
      itemBuilder: (context, index) {
        return _buildConventionCard(_filteredConventions[index]);
      },
    );
  }

  Widget _buildGridView() {
    if (_filteredConventions.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredConventions.length,
      itemBuilder: (context, index) {
        return _buildConventionGridCard(_filteredConventions[index]);
      },
    );
  }

  Widget _buildConventionCard(Map<String, dynamic> convention) {
    final monthColor = _monthColors[convention['month']] ?? Colors.grey;
    
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
          // En-tête avec couleur du mois
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [monthColor, monthColor.withOpacity(0.8)],
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
                        convention['name'],
                        style: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${convention['city']} • ${convention['date']}',
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${convention['participantCount']} tatoueurs',
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
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  convention['description'],
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Icon(Icons.schedule, color: KipikTheme.rouge, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${convention['duration']} jours',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.euro, color: KipikTheme.rouge, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      widget.userType == UserType.pro 
                          ? 'Stand: ${convention['standPrice']}€'
                          : 'Entrée: ${convention['ticketPrice']}€',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildConventionActions(convention),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConventionGridCard(Map<String, dynamic> convention) {
    final monthColor = _monthColors[convention['month']] ?? Colors.grey;
    
    return Container(
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
          // En-tête compact
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [monthColor, monthColor.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  convention['name'],
                  style: const TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  convention['city'],
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu compact
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    convention['date'],
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${convention['participantCount']} tatoueurs',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _viewConventionDetails(convention),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KipikTheme.rouge,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Voir',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                        ),
                      ),
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

  Widget _buildConventionActions(Map<String, dynamic> convention) {
    switch (widget.userType) {
      case UserType.customer:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _toggleFavorite(convention),
                icon: Icon(
                  convention['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                ),
                label: const Text('Favoris'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _buyTicket(convention),
                icon: const Icon(Icons.confirmation_number, size: 16),
                label: const Text('Billet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case UserType.pro:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _contactOrganizer(convention),
                icon: const Icon(Icons.email, size: 16),
                label: const Text('Contact'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _requestStand(convention),
                icon: const Icon(Icons.store, size: 16),
                label: const Text('Stand'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case UserType.organizer:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _editConvention(convention),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _manageConvention(convention),
                icon: const Icon(Icons.dashboard, size: 16),
                label: const Text('Gérer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case UserType.admin:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _moderateConvention(convention),
                icon: const Icon(Icons.admin_panel_settings, size: 16),
                label: const Text('Modérer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _viewAnalytics(convention),
                icon: const Icon(Icons.analytics, size: 16),
                label: const Text('Stats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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
              'Essayez de modifier vos filtres ou votre recherche',
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
    );
  }

  // Actions
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    if (_showFilters) {
      _filterController.forward();
    } else {
      _filterController.reverse();
    }
  }

  void _resetFilters() {
    setState(() {
      _distanceRadius = 100;
      _selectedMonths.clear();
      _selectedSizes.clear();
      _selectedDurations.clear();
      _priceRange = const RangeValues(0, 1000);
      _selectedRegion = 'Toutes';
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredConventions = _conventions.where((convention) {
        // Recherche par nom/ville
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!convention['name'].toLowerCase().contains(query) &&
              !convention['city'].toLowerCase().contains(query)) {
            return false;
          }
        }
        
        // Filtre par mois
        if (_selectedMonths.isNotEmpty) {
          if (!_selectedMonths.contains(convention['month'])) {
            return false;
          }
        }
        
        // Filtre par taille
        if (_selectedSizes.isNotEmpty) {
          if (!_selectedSizes.contains(convention['size'])) {
            return false;
          }
        }
        
        // Filtre par durée
        if (_selectedDurations.isNotEmpty) {
          if (!_selectedDurations.contains(convention['duration_enum'])) {
            return false;
          }
        }
        
        // Filtre par prix (pour les pros)
        if (widget.userType == UserType.pro) {
          final price = convention['standPrice'].toDouble();
          if (price < _priceRange.start || price > _priceRange.end) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _createConvention() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Création de convention - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewFavorites() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mes conventions favorites - À implémenter'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewConventionDetails(Map<String, dynamic> convention) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de ${convention['name']}'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleFavorite(Map<String, dynamic> convention) {
    setState(() {
      convention['isFavorite'] = !convention['isFavorite'];
    });
    
    final message = convention['isFavorite'] 
        ? 'Ajouté aux favoris' 
        : 'Retiré des favoris';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _buyTicket(Map<String, dynamic> convention) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Achat billet ${convention['name']} - À implémenter'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _contactOrganizer(Map<String, dynamic> convention) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact organisateur ${convention['name']} - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _requestStand(Map<String, dynamic> convention) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande stand ${convention['name']} - À implémenter'),
        backgroundColor: KipikTheme.rouge,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editConvention(Map<String, dynamic> convention) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Édition ${convention['name']} - À implémenter'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _manageConvention(Map<String, dynamic> convention) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gestion ${convention['name']} - À implémenter'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _moderateConvention(Map<String, dynamic> convention) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modération ${convention['name']} - À implémenter'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewAnalytics(Map<String, dynamic> convention) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Analytics ${convention['name']} - À implémenter'),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper methods
  String _getUserTypeSubtitle() {
    switch (widget.userType) {
      case UserType.admin:
        return 'Administration';
      case UserType.organizer:
        return 'Organisateur';
      case UserType.customer:
        return 'Découvrir & Réserver';
      case UserType.pro:
        return 'Stands & Collaborations';
    }
  }

  IconData _getViewModeIcon(ViewMode mode) {
    switch (mode) {
      case ViewMode.map:
        return Icons.map;
      case ViewMode.list:
        return Icons.list;
      case ViewMode.grid:
        return Icons.grid_view;
    }
  }

  String _getViewModeLabel(ViewMode mode) {
    switch (mode) {
      case ViewMode.map:
        return 'Carte';
      case ViewMode.list:
        return 'Liste';
      case ViewMode.grid:
        return 'Grille';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }

  IconData _getSizeIcon(ConventionSize size) {
    switch (size) {
      case ConventionSize.small:
        return Icons.group;
      case ConventionSize.medium:
        return Icons.groups;
      case ConventionSize.large:
        return Icons.groups_2;
      case ConventionSize.giant:
        return Icons.stadium;
    }
  }

  String _getSizeLabel(ConventionSize size) {
    switch (size) {
      case ConventionSize.small:
        return 'Petit (<30)';
      case ConventionSize.medium:
        return 'Moyen (30-100)';
      case ConventionSize.large:
        return 'Grand (100-200)';
      case ConventionSize.giant:
        return 'Géant (200+)';
    }
  }

  String _getDurationLabel(ConventionDuration duration) {
    switch (duration) {
      case ConventionDuration.oneDay:
        return '1 jour';
      case ConventionDuration.twoDays:
        return '2 jours';
      case ConventionDuration.threeDays:
        return '3 jours';
      case ConventionDuration.weekend:
        return 'Week-end';
      case ConventionDuration.week:
        return 'Semaine';
    }
  }

  ConventionSize _getConventionSize(int participantCount) {
    if (participantCount < 30) return ConventionSize.small;
    if (participantCount < 100) return ConventionSize.medium;
    if (participantCount < 200) return ConventionSize.large;
    return ConventionSize.giant;
  }

  ConventionDuration _getConventionDuration(int days) {
    switch (days) {
      case 1:
        return ConventionDuration.oneDay;
      case 2:
        return ConventionDuration.twoDays;
      case 3:
        return ConventionDuration.threeDays;
      case 7:
        return ConventionDuration.week;
      default:
        return ConventionDuration.weekend;
    }
  }

  List<Map<String, dynamic>> _generateSampleConventions() {
    return [
      {
        'id': '1',
        'name': 'Paris Tattoo Convention',
        'city': 'Paris',
        'date': '15-17 Mars 2025',
        'month': 3,
        'duration': 3,
        'duration_enum': ConventionDuration.threeDays,
        'participantCount': 150,
        'size': ConventionSize.large,
        'description': 'La plus grande convention de tatouage de France avec les meilleurs artistes internationaux.',
        'standPrice': 800,
        'ticketPrice': 25,
        'isFavorite': false,
        'organizerId': 'org1',
      },
      {
        'id': '2',
        'name': 'Lyon Ink Festival',
        'city': 'Lyon',
        'date': '5-6 Avril 2025',
        'month': 4,
        'duration': 2,
        'duration_enum': ConventionDuration.twoDays,
        'participantCount': 80,
        'size': ConventionSize.medium,
        'description': 'Festival intimiste axé sur les styles traditionnels et neo-traditionnels.',
        'standPrice': 450,
        'ticketPrice': 15,
        'isFavorite': true,
        'organizerId': 'org2',
      },
      {
        'id': '3',
        'name': 'Marseille Tattoo Show',
        'city': 'Marseille',
        'date': '20-22 Juin 2025',
        'month': 6,
        'duration': 3,
        'duration_enum': ConventionDuration.threeDays,
        'participantCount': 200,
        'size': ConventionSize.giant,
        'description': 'Convention méditerranéenne avec focus sur le réalisme et les portraits.',
        'standPrice': 600,
        'ticketPrice': 20,
        'isFavorite': false,
        'organizerId': 'org3',
      },
      {
        'id': '4',
        'name': 'Bordeaux Art & Ink',
        'city': 'Bordeaux',
        'date': '12 Juillet 2025',
        'month': 7,
        'duration': 1,
        'duration_enum': ConventionDuration.oneDay,
        'participantCount': 25,
        'size': ConventionSize.small,
        'description': 'Journée découverte du tatouage artistique dans un cadre exceptionnel.',
        'standPrice': 200,
        'ticketPrice': 10,
        'isFavorite': false,
        'organizerId': 'org4',
      },
      {
        'id': '5',
        'name': 'Lille Tattoo Weekend',
        'city': 'Lille',
        'date': '15-16 Novembre 2025',
        'month': 11,
        'duration': 2,
        'duration_enum': ConventionDuration.weekend,
        'participantCount': 120,
        'size': ConventionSize.large,
        'description': 'Week-end tatouage dans le Nord avec les meilleurs artistes de la région.',
        'standPrice': 500,
        'ticketPrice': 18,
        'isFavorite': true,
        'organizerId': 'org5',
      },
    ];
  }
}