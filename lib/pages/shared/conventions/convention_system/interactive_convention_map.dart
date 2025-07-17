// lib/pages/shared/conventions/convention_system/interactive_convention_map.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/kipik_theme.dart';
import '../../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../../../models/user_subscription.dart';
import '../../../../models/user_role.dart';

import '../../../../enums/convention_enums.dart';
import '../../../../enums/tattoo_style.dart';

class StandInfo {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final double pricePerSqm;
  final StandStatus status;
  final String? tattooerId;
  final String? tattouerName;
  final List<TattooStyle> styles;
  final String? profileImage;
  final double rating;
  final List<String> availableSlots;
  final int waitingTime;
  final bool isHighTraffic;
  
  StandInfo({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.pricePerSqm,
    required this.status,
    this.tattooerId,
    this.tattouerName,
    this.styles = const [],
    this.profileImage,
    this.rating = 0.0,
    this.availableSlots = const [],
    this.waitingTime = 0,
    this.isHighTraffic = false,
  });
  
  double get totalPrice => width * height * pricePerSqm;
  double get area => width * height;
  bool get isAvailable => status == StandStatus.available;
  bool get hasSlots => availableSlots.isNotEmpty;
}

class InteractiveConventionMap extends StatefulWidget {
  final String conventionId;
  final MapMode initialMode;
  final UserRole userType;
  final String? currentUserId;
  
  const InteractiveConventionMap({
    Key? key,
    required this.conventionId,
    required this.initialMode,
    required this.userType,
    this.currentUserId,
  }) : super(key: key);

  @override
  State<InteractiveConventionMap> createState() => _InteractiveConventionMapState();
}

class _InteractiveConventionMapState extends State<InteractiveConventionMap> 
    with TickerProviderStateMixin {
  
  late AnimationController _zoomController;
  late AnimationController _searchAnimController;
  late Animation<double> _zoomAnimation;
  late Animation<double> _searchAnimation;
  
  MapMode _currentMode = MapMode.visitor;
  double _mapScale = 1.0;
  Offset _mapOffset = Offset.zero;
  
  // Recherche et filtres
  final TextEditingController _searchTextController = TextEditingController();
  List<TattooStyle> _selectedStyles = [];
  bool _showOnlyAvailable = false;
  String _searchQuery = '';
  
  // Stands et données
  List<StandInfo> _allStands = [];
  List<StandInfo> _filteredStands = [];
  StandInfo? _selectedStand;
  List<String> _favoriteStands = [];
  
  // Mode tatoueur
  StandInfo? _myStand;
  List<StandInfo> _nearbyStands = [];
  
  // Navigation
  bool _showOptimalPath = false;
  List<String> _pathStands = [];

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _initializeAnimations();
    _loadConventionData();
    _setupSearchListener();
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _searchAnimController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _searchAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOut),
    );
    
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimController, curve: Curves.easeOutCubic),
    );
  }

  void _setupSearchListener() {
    _searchTextController.addListener(() {
      setState(() {
        _searchQuery = _searchTextController.text.toLowerCase();
      });
      _filterStands();
    });
  }

  void _loadConventionData() {
    // Simulation des données de convention
    _allStands = _generateSampleStands();
    _filteredStands = List.from(_allStands);
    
    if (_currentMode == MapMode.tattooer && widget.currentUserId != null) {
      _myStand = _allStands.firstWhere(
        (stand) => stand.tattooerId == widget.currentUserId,
        orElse: () => _allStands.first,
      );
      _findNearbyStands();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: _buildAppBar(),
      floatingActionButton: _buildFloatingActions(),
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
            child: Column(
              children: [
                _buildModeSelector(),
                _buildSearchAndFilters(),
                Expanded(
                  child: _buildInteractiveMap(),
                ),
              ],
            ),
          ),
          
          // Overlays
          if (_selectedStand != null) _buildStandDetails(),
          if (_showOptimalPath) _buildPathOverlay(),
        ],
      ),
    );
  }

  CustomAppBarKipik _buildAppBar() {
    String title;
    String subtitle;
    
    switch (_currentMode) {
      case MapMode.organizer:
        title = 'Gestion Convention';
        subtitle = 'Vue organisateur';
        break;
      case MapMode.tattooer:
        title = 'Mon Emplacement';
        subtitle = 'Vue tatoueur';
        break;
      case MapMode.visitor:
        title = 'Plan Interactif';
        subtitle = 'Explorez la convention';
        break;
    }
    
    return CustomAppBarKipik(
      title: title,
      subtitle: subtitle,
      showBackButton: true,
      useProStyle: _currentMode != MapMode.visitor,
      actions: [
        IconButton(
          icon: const Icon(Icons.my_location, color: Colors.white),
          onPressed: _centerOnUserLocation,
        ),
        if (_currentMode == MapMode.visitor)
          IconButton(
            icon: Icon(
              _favoriteStands.isNotEmpty ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: _showFavorites,
          ),
      ],
    );
  }

  Widget _buildModeSelector() {
    if (_currentMode == MapMode.organizer && widget.userType != UserRole.admin) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
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
          if (widget.userType == UserRole.admin)
            _buildModeButton('Organisateur', MapMode.organizer, Icons.admin_panel_settings),
          if (widget.userType == UserRole.tatoueur)
            _buildModeButton('Mon Stand', MapMode.tattooer, Icons.store),
          _buildModeButton('Visiteur', MapMode.visitor, Icons.explore),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, MapMode mode, IconData icon) {
    final isSelected = _currentMode == mode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? KipikTheme.rouge : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                label,
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
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(25),
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
                Icon(Icons.search, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchTextController,
                    decoration: InputDecoration(
                      hintText: _getSearchHint(),
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filtres
          if (_currentMode == MapMode.visitor) _buildFilters(),
          if (_currentMode == MapMode.tattooer) _buildTattouerControls(),
          if (_currentMode == MapMode.organizer) _buildOrganizerControls(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            'Disponible',
            _showOnlyAvailable,
            Icons.check_circle,
            () => setState(() => _showOnlyAvailable = !_showOnlyAvailable),
          ),
          const SizedBox(width: 8),
          ..._buildStyleFilters(),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Favoris',
            _favoriteStands.isNotEmpty,
            Icons.favorite,
            _showFavorites,
            color: Colors.pink,
          ),
        ],
      ),
    );
  }

  Widget _buildTattouerControls() {
    return Row(
      children: [
        Expanded(
          child: _buildControlButton(
            'Mon Stand',
            Icons.my_location,
            () => _focusOnMyStand(),
            KipikTheme.rouge,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildControlButton(
            'Concurrence',
            Icons.groups,
            () => _showCompetitionAnalysis(),
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildControlButton(
            'Analytics',
            Icons.analytics,
            () => _showMyAnalytics(),
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerControls() {
    return Row(
      children: [
        Expanded(
          child: _buildControlButton(
            'Vue Globale',
            Icons.view_module,
            () => _showGlobalView(),
            KipikTheme.rouge,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildControlButton(
            'Revenus',
            Icons.euro,
            () => _showRevenueAnalytics(),
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildControlButton(
            'Optimiser',
            Icons.tune,
            () => _optimizeLayout(),
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveMap() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onTap: () => setState(() => _selectedStand = null),
          onScaleUpdate: _handleMapGesture,
          child: Stack(
            children: [
              // Plan de la convention
              Transform(
                transform: Matrix4.identity()
                  ..scale(_mapScale)
                  ..translate(_mapOffset.dx, _mapOffset.dy),
                child: _buildMapLayout(),
              ),
              
              // Légende
              Positioned(
                top: 16,
                right: 16,
                child: _buildMapLegend(),
              ),
              
              // Zoom controls
              Positioned(
                bottom: 16,
                right: 16,
                child: _buildZoomControls(),
              ),
              
              // Path indicator
              if (_showOptimalPath)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: _buildPathIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapLayout() {
    return Container(
      width: 400,
      height: 300,
      color: Colors.grey[100],
      child: Stack(
        children: [
          // Structure de base
          _buildRoomStructure(),
          
          // Stands
          ..._filteredStands.map((stand) => _buildStandWidget(stand)),
          
          // Éléments fixes
          _buildFixedElements(),
          
          // Indicateurs spéciaux
          if (_currentMode == MapMode.tattooer && _myStand != null)
            _buildMyStandIndicator(),
          
          // Chemin optimal
          if (_showOptimalPath) _buildOptimalPath(),
        ],
      ),
    );
  }

  Widget _buildStandWidget(StandInfo stand) {
    final isSelected = _selectedStand?.id == stand.id;
    final isHighlighted = _isStandHighlighted(stand);
    final isFavorite = _favoriteStands.contains(stand.id);
    
    return Positioned(
      left: stand.x,
      top: stand.y,
      child: GestureDetector(
        onTap: () => _selectStand(stand),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: stand.width * 10, // Scale factor
          height: stand.height * 10,
          decoration: BoxDecoration(
            color: _getStandColor(stand),
            border: Border.all(
              color: isSelected ? KipikTheme.rouge : Colors.grey[400]!,
              width: isSelected ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected || isHighlighted ? [
              BoxShadow(
                color: KipikTheme.rouge.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Stack(
            children: [
              // ID du stand
              Positioned(
                top: 2,
                left: 4,
                child: Text(
                  stand.id,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              // Avatar tatoueur
              if (stand.tattouerName != null)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: KipikTheme.rouge.withOpacity(0.2),
                    child: const Icon(Icons.person, size: 10, color: Colors.black54),
                  ),
                ),
              
              // Indicateur favori
              if (isFavorite)
                const Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(Icons.favorite, size: 8, color: Colors.pink),
                ),
              
              // Indicateur disponibilité
              if (stand.hasSlots)
                Positioned(
                  bottom: 2,
                  left: 2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              
              // Temps d'attente
              if (stand.waitingTime > 0)
                Positioned(
                  bottom: 2,
                  left: 12,
                  child: Text(
                    '${stand.waitingTime}min',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 6,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandDetails() {
    if (_selectedStand == null) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStandDetailHeader(),
            const SizedBox(height: 16),
            _buildStandDetailContent(),
            const SizedBox(height: 16),
            _buildStandDetailActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStandDetailHeader() {
    final stand = _selectedStand!;
    
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 25,
          backgroundColor: KipikTheme.rouge.withOpacity(0.2),
          child: const Icon(Icons.person, color: Colors.black54, size: 30),
        ),
        
        const SizedBox(width: 12),
        
        // Infos principales
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    stand.tattouerName ?? 'Stand ${stand.id}',
                    style: const TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (stand.rating > 0) ...[
                    Icon(Icons.star, size: 16, color: Colors.amber[600]),
                    Text(
                      stand.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Stand ${stand.id} • ${stand.area.toInt()}m² • ${stand.totalPrice.toInt()}€',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              if (stand.styles.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: stand.styles.take(3).map((style) => 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: KipikTheme.rouge.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        style.displayName,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: KipikTheme.rouge,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ],
          ),
        ),
        
        // Actions rapides
        Column(
          children: [
            GestureDetector(
              onTap: () => _toggleFavorite(stand.id),
              child: Icon(
                _favoriteStands.contains(stand.id) ? Icons.favorite : Icons.favorite_border,
                color: _favoriteStands.contains(stand.id) ? Colors.pink : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _shareStand(stand),
              child: const Icon(Icons.share, color: Colors.blue, size: 24),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStandDetailContent() {
    final stand = _selectedStand!;
    
    return Column(
      children: [
        // Statut et disponibilité
        Row(
          children: [
            Expanded(
              child:               _buildDetailCard(
                'Statut',
                stand.status.displayName,
                stand.status.statusColor,
                Icons.circle,
              ),
            ),
            const SizedBox(width: 8),
            if (stand.waitingTime > 0)
              Expanded(
                child: _buildDetailCard(
                  'Attente',
                  '${stand.waitingTime} min',
                  Colors.orange,
                  Icons.timer,
                ),
              ),
            if (stand.hasSlots)
              Expanded(
                child: _buildDetailCard(
                  'Créneaux',
                  '${stand.availableSlots.length} libres',
                  Colors.green,
                  Icons.schedule,
                ),
              ),
          ],
        ),
        
        // Navigation
        if (_currentMode == MapMode.visitor) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailCard(
                  'Distance',
                  _calculateDistance(stand),
                  Colors.blue,
                  Icons.directions_walk,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailCard(
                  'Flux',
                  stand.isHighTraffic ? 'Élevé' : 'Normal',
                  stand.isHighTraffic ? Colors.red : Colors.green,
                  Icons.people,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStandDetailActions() {
    final stand = _selectedStand!;
    
    return Row(
      children: [
        // Action principale selon le mode
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _primaryAction(stand),
            icon: Icon(_getPrimaryActionIcon(), size: 16),
            label: Text(
              _getPrimaryActionLabel(),
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Action secondaire
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _secondaryAction(stand),
            icon: Icon(_getSecondaryActionIcon(), size: 16),
            label: Text(
              _getSecondaryActionLabel(),
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Action contextuelle selon le mode
        if (_currentMode == MapMode.visitor && _favoriteStands.isNotEmpty)
          FloatingActionButton.extended(
            heroTag: "optimal_path",
            onPressed: _generateOptimalPath,
            backgroundColor: Colors.purple,
            icon: const Icon(Icons.route, color: Colors.white),
            label: const Text(
              'Parcours Optimal',
              style: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
            ),
          ),
        
        if (_currentMode == MapMode.tattooer)
          FloatingActionButton.extended(
            heroTag: "my_analytics",
            onPressed: _showMyAnalytics,
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.analytics, color: Colors.white),
            label: const Text(
              'Mes Stats',
              style: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
            ),
          ),
        
        if (_currentMode == MapMode.organizer)
          FloatingActionButton.extended(
            heroTag: "optimize",
            onPressed: _optimizeLayout,
            backgroundColor: Colors.green,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text(
              'Optimiser',
              style: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
            ),
          ),
        
        const SizedBox(height: 16),
        const TattooAssistantButton(),
      ],
    );
  }

  // Helper methods pour les widgets
  Widget _buildFilterChip(String label, bool isSelected, IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? KipikTheme.rouge) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? KipikTheme.rouge) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(String label, IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 12,
              color: color,
            ),
          ),
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

  Widget _buildRoomStructure() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!, width: 2),
      ),
      child: Stack(
        children: [
          // Entrée
          Positioned(
            top: 0,
            left: 150,
            child: Container(
              width: 100,
              height: 10,
              color: Colors.green[200],
              child: const Center(
                child: Text(
                  'ENTRÉE',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          
          // Scène
          Positioned(
            bottom: 20,
            left: 150,
            child: Container(
              width: 100,
              height: 40,
              color: Colors.purple[200],
              child: const Center(
                child: Text(
                  'SCÈNE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          
          // Bars
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 30,
              height: 20,
              color: Colors.orange[200],
              child: const Center(
                child: Text(
                  'BAR',
                  style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 30,
              height: 20,
              color: Colors.orange[200],
              child: const Center(
                child: Text(
                  'BAR',
                  style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedElements() {
    return const SizedBox.shrink();
  }

  Widget _buildMyStandIndicator() {
    if (_myStand == null) return const SizedBox.shrink();
    
    return Positioned(
      left: _myStand!.x - 5,
      top: _myStand!.y - 5,
      child: Container(
        width: (_myStand!.width * 10) + 10,
        height: (_myStand!.height * 10) + 10,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.star, color: Colors.blue, size: 16),
        ),
      ),
    );
  }

  Widget _buildOptimalPath() {
    return const SizedBox.shrink(); // À implémenter avec CustomPainter
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegendItem('Disponible', StandStatus.available.statusColor),
          _buildLegendItem('Occupé', StandStatus.occupied.statusColor),
          _buildLegendItem('Réservé', StandStatus.booked.statusColor),
          if (_currentMode == MapMode.tattooer)
            _buildLegendItem('Mon stand', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: "zoom_in",
          mini: true,
          onPressed: _zoomIn,
          backgroundColor: Colors.white,
          child: const Icon(Icons.zoom_in, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "zoom_out",
          mini: true,
          onPressed: _zoomOut,
          backgroundColor: Colors.white,
          child: const Icon(Icons.zoom_out, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildPathIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            'Parcours: ${_pathStands.length} stands',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showOptimalPath = false),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPathOverlay() {
    return const SizedBox.shrink(); // Overlay pour le chemin optimal
  }

  List<Widget> _buildStyleFilters() {
    return TattooStyle.values.map((style) => 
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _buildFilterChip(
          style.displayName,
          _selectedStyles.contains(style),
          style.iconData,
          () => _toggleStyleFilter(style),
        ),
      ),
    ).toList();
  }

  // Méthodes utilitaires
  List<StandInfo> _generateSampleStands() {
    return List.generate(30, (index) {
      final random = index % 4;
      return StandInfo(
        id: 'S${index + 1}',
        x: (index % 8) * 45.0 + 20,
        y: (index ~/ 8) * 35.0 + 60,
        width: 4,
        height: 3,
        pricePerSqm: 80 + (random * 10),
        status: StandStatus.values[random],
        tattooerId: random == 0 ? 'user_$index' : null,
        tattouerName: random == 0 ? 'Tatoueur ${index + 1}' : null,
        styles: random == 0 ? [TattooStyle.values[index % TattooStyle.values.length]] : [],
        rating: random == 0 ? 4.0 + (index % 10) * 0.1 : 0,
        availableSlots: random == 0 ? ['14h00', '16h00'] : [],
        waitingTime: random == 1 ? 15 + (index % 20) : 0,
        isHighTraffic: index % 5 == 0,
      );
    });
  }

  String _getSearchHint() {
    switch (_currentMode) {
      case MapMode.organizer:
        return 'Rechercher un stand, tatoueur...';
      case MapMode.tattooer:
        return 'Rechercher un concurrent, style...';
      case MapMode.visitor:
        return 'Rechercher un tatoueur, style...';
    }
  }

  Color _getStandColor(StandInfo stand) {
    return stand.status.statusColor.withOpacity(0.7); // Ajout opacité pour lisibilité
  }

  String getStatusLabel(StandStatus status) {
    return status.displayName; // Utilise l'extension
  }

  Color getStatusColor(StandStatus status) {
    return status.statusColor; // Utilise l'extension
  }

  String _getStyleLabel(TattooStyle style) {
    switch (style) {
      case TattooStyle.realism:
        return 'Réalisme';
      case TattooStyle.japanese:
        return 'Japonais';
      case TattooStyle.geometric:
        return 'Géométrique';
      case TattooStyle.traditional:
        return 'Traditionnel';
      case TattooStyle.blackwork:
        return 'Blackwork';
      case TattooStyle.watercolor:
        return 'Aquarelle';
      case TattooStyle.tribal:
        return 'Tribal';
      case TattooStyle.minimalist:
        return 'Minimaliste';
    }
  }

  IconData _getStyleIcon(TattooStyle style) {
    switch (style) {
      case TattooStyle.realism:
        return Icons.photo;
      case TattooStyle.japanese:
        return Icons.nature;
      case TattooStyle.geometric:
        return Icons.category;
      case TattooStyle.traditional:
        return Icons.flag;
      case TattooStyle.blackwork:
        return Icons.brush;
      case TattooStyle.watercolor:
        return Icons.palette;
      case TattooStyle.tribal:
        return Icons.waves;
      case TattooStyle.minimalist:
        return Icons.minimize;
    }
  }

  String _calculateDistance(StandInfo stand) {
    // Simulation calcul distance
    final distance = (stand.x / 10).round();
    return '${distance}m';
  }

  bool _isStandHighlighted(StandInfo stand) {
    if (_searchQuery.isEmpty) return false;
    
    return stand.tattouerName?.toLowerCase().contains(_searchQuery) == true ||
           stand.id.toLowerCase().contains(_searchQuery) ||
           stand.styles.any((style) => style.displayName.toLowerCase().contains(_searchQuery));
  }

  IconData _getPrimaryActionIcon() {
    switch (_currentMode) {
      case MapMode.organizer:
        return Icons.settings;
      case MapMode.tattooer:
        return Icons.analytics;
      case MapMode.visitor:
        return Icons.schedule;
    }
  }

  String _getPrimaryActionLabel() {
    switch (_currentMode) {
      case MapMode.organizer:
        return 'Gérer';
      case MapMode.tattooer:
        return 'Analyser';
      case MapMode.visitor:
        return 'Réserver';
    }
  }

  IconData _getSecondaryActionIcon() {
    switch (_currentMode) {
      case MapMode.organizer:
        return Icons.euro;
      case MapMode.tattooer:
        return Icons.directions;
      case MapMode.visitor:
        return Icons.info;
    }
  }

  String _getSecondaryActionLabel() {
    switch (_currentMode) {
      case MapMode.organizer:
        return 'Revenus';
      case MapMode.tattooer:
        return 'Itinéraire';
      case MapMode.visitor:
        return 'Portfolio';
    }
  }

  // Méthodes d'action
  void _switchMode(MapMode mode) {
    setState(() {
      _currentMode = mode;
      _selectedStand = null;
    });
    
    if (mode == MapMode.tattooer) {
      _findNearbyStands();
    }
    
    _filterStands();
    HapticFeedback.selectionClick();
  }

  void _filterStands() {
    setState(() {
      _filteredStands = _allStands.where((stand) {
        // Filtre par recherche
        if (_searchQuery.isNotEmpty) {
          final matchesSearch = stand.tattouerName?.toLowerCase().contains(_searchQuery) == true ||
                               stand.id.toLowerCase().contains(_searchQuery) ||
                               stand.styles.any((style) => _getStyleLabel(style).toLowerCase().contains(_searchQuery));
          if (!matchesSearch) return false;
        }
        
        // Filtre par disponibilité
        if (_showOnlyAvailable && !stand.isAvailable) return false;
        
        // Filtre par styles
        if (_selectedStyles.isNotEmpty) {
          final hasMatchingStyle = stand.styles.any((style) => _selectedStyles.contains(style));
          if (!hasMatchingStyle) return false;
        }
        
        return true;
      }).toList();
    });
  }

  void _clearSearch() {
    _searchTextController.clear();
    _filterStands();
  }

  void _toggleStyleFilter(TattooStyle style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        _selectedStyles.remove(style);
      } else {
        _selectedStyles.add(style);
      }
    });
    _filterStands();
  }

  void _selectStand(StandInfo stand) {
    setState(() {
      _selectedStand = stand;
    });
    HapticFeedback.lightImpact();
  }

  void _toggleFavorite(String standId) {
    setState(() {
      if (_favoriteStands.contains(standId)) {
        _favoriteStands.remove(standId);
      } else {
        _favoriteStands.add(standId);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _centerOnUserLocation() {
    // Animation pour centrer sur la position utilisateur
    _zoomController.forward().then((_) => _zoomController.reverse());
  }

  void _showFavorites() {
    if (_favoriteStands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun favori pour le moment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _filteredStands = _allStands.where((stand) => _favoriteStands.contains(stand.id)).toList();
    });
  }

  void _focusOnMyStand() {
    if (_myStand != null) {
      setState(() {
        _selectedStand = _myStand;
      });
    }
  }

  void _findNearbyStands() {
    if (_myStand != null) {
      _nearbyStands = _allStands.where((stand) {
        if (stand.id == _myStand!.id) return false;
        final distance = (stand.x - _myStand!.x).abs() + (stand.y - _myStand!.y).abs();
        return distance < 100; // Distance arbitraire
      }).toList();
    }
  }

  void _generateOptimalPath() {
    setState(() {
      _pathStands = List.from(_favoriteStands);
      _showOptimalPath = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Parcours optimal généré pour ${_pathStands.length} stands'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _handleMapGesture(ScaleUpdateDetails details) {
    setState(() {
      _mapScale = (_mapScale * details.scale).clamp(0.5, 3.0);
    });
  }

  void _zoomIn() {
    setState(() {
      _mapScale = (_mapScale * 1.2).clamp(0.5, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _mapScale = (_mapScale / 1.2).clamp(0.5, 3.0);
    });
  }

  void _primaryAction(StandInfo stand) {
    switch (_currentMode) {
      case MapMode.organizer:
        _manageStand(stand);
        break;
      case MapMode.tattooer:
        _analyzeStand(stand);
        break;
      case MapMode.visitor:
        _bookSlot(stand);
        break;
    }
  }

  void _secondaryAction(StandInfo stand) {
    switch (_currentMode) {
      case MapMode.organizer:
        _showStandRevenue(stand);
        break;
      case MapMode.tattooer:
        _getDirections(stand);
        break;
      case MapMode.visitor:
        _viewPortfolio(stand);
        break;
    }
  }

  void _shareStand(StandInfo stand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage du stand ${stand.id} - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Actions spécifiques par mode
  void _showCompetitionAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analyse concurrentielle - À implémenter'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showMyAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mes analytics - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showGlobalView() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vue globale - À implémenter'),
        backgroundColor: KipikTheme.rouge,
      ),
    );
  }

  void _showRevenueAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics revenus - À implémenter'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _optimizeLayout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Optimisation layout - À implémenter'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _manageStand(StandInfo stand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gestion stand ${stand.id} - À implémenter'),
        backgroundColor: KipikTheme.rouge,
      ),
    );
  }

  void _analyzeStand(StandInfo stand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Analyse stand ${stand.id} - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _bookSlot(StandInfo stand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Réservation stand ${stand.id} - À implémenter'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showStandRevenue(StandInfo stand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Revenus stand ${stand.id}: ${stand.totalPrice.toInt()}€'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _getDirections(StandInfo stand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Itinéraire vers ${stand.id} - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewPortfolio(StandInfo stand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Portfolio ${stand.tattouerName ?? stand.id} - À implémenter'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}