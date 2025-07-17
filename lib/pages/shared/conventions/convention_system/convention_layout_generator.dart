// lib/pages/shared/conventions/convention_system/convention_layout_generator.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/kipik_theme.dart';
import '../../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../../widgets/common/buttons/tattoo_assistant_button.dart';

enum LayoutElement { stage, bar, toilet, storage, foodTruck, entrance, exit, pillar, emergency }
enum StandType { tattoo, merchant }
enum ZoneType { premium, standard, discount, forbidden }

class LayoutPoint {
  final double x;
  final double y;
  final double width;
  final double height;
  final LayoutElement type;
  final String? label;
  final bool isFixed;
  
  LayoutPoint({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
    this.label,
    this.isFixed = false,
  });
}

class StandSlot {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final StandType type;
  final ZoneType zone;
  final double pricePerSqm;
  final bool isBooked;
  final String? bookedBy;
  
  StandSlot({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
    required this.zone,
    required this.pricePerSqm,
    this.isBooked = false,
    this.bookedBy,
  });
  
  double get totalPrice => width * height * pricePerSqm;
  double get area => width * height;
}

class ConventionLayoutGenerator extends StatefulWidget {
  final Map<String, dynamic>? convention;
  
  const ConventionLayoutGenerator({
    Key? key,
    this.convention,
  }) : super(key: key);

  @override
  State<ConventionLayoutGenerator> createState() => _ConventionLayoutGeneratorState();
}

class _ConventionLayoutGeneratorState extends State<ConventionLayoutGenerator> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 0;
  bool _isGenerating = false;
  
  // Configuration salle
  double _roomWidth = 40.0;
  double _roomHeight = 30.0;
  bool _hasSecondRoom = false;
  double _secondRoomWidth = 20.0;
  double _secondRoomHeight = 15.0;
  
  // Contraintes sécurité
  double _mainAlleyWidth = 3.0;
  double _secondaryAlleyWidth = 2.0;
  double _pmrAlleyWidth = 1.4;
  double _emergencyDistance = 15.0;
  
  // Configuration stands
  int _expectedTattooers = 45;
  int _expectedMerchants = 8;
  double _defaultDepth = 2.0;
  double _tattooRatio = 75.0;
  double _merchantRatio = 15.0;
  
  // Pricing
  double _basePricePerSqm = 80.0;
  double _premiumMultiplier = 1.5;
  double _discountMultiplier = 0.8;
  
  // Éléments placés
  List<LayoutPoint> _fixedElements = [];
  List<LayoutPoint> _forbiddenZones = [];
  List<StandSlot> _generatedStands = [];
  
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDefaultElements();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _initializeDefaultElements() {
    // Éléments par défaut
    _fixedElements = [
      LayoutPoint(x: 35, y: 2, width: 6, height: 4, type: LayoutElement.stage, label: 'Scène principale'),
      LayoutPoint(x: 2, y: 2, width: 3, height: 2, type: LayoutElement.bar, label: 'Bar 1'),
      LayoutPoint(x: 35, y: 24, width: 3, height: 2, type: LayoutElement.bar, label: 'Bar 2'),
      LayoutPoint(x: 2, y: 26, width: 4, height: 2, type: LayoutElement.toilet, label: 'Sanitaires'),
    ];
    
    _forbiddenZones = [
      LayoutPoint(x: 0, y: 0, width: 40, height: 1, type: LayoutElement.entrance, label: 'Zone entrée'),
      LayoutPoint(x: 19, y: 29, width: 2, height: 1, type: LayoutElement.exit, label: 'Sortie secours'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Générateur de Plan',
        subtitle: 'IA d\'optimisation convention',
        showBackButton: true,
        useProStyle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showHelp,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentStep == 3)
            FloatingActionButton.extended(
              heroTag: "generate",
              onPressed: _isGenerating ? null : _generateLayout,
              backgroundColor: KipikTheme.rouge,
              icon: _isGenerating 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                _isGenerating ? 'Génération...' : 'Générer Plan IA',
                style: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
              ),
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
        _buildProgressIndicator(),
        const SizedBox(height: 16),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            children: [
              _buildRoomConfigurationStep(),
              _buildSafetyConstraintsStep(),
              _buildFixedElementsStep(),
              _buildStandConfigurationStep(),
              _buildGeneratedLayoutStep(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildNavigationButtons(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProgressIndicator() {
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
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: KipikTheme.rouge, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Générateur IA Convention Layout',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  '${_currentStep + 1}/5',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _getStepTitle(_currentStep),
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

  Widget _buildRoomConfigurationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Configuration des Salles',
            'Définissez les dimensions de votre espace',
            Icons.aspect_ratio,
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Salle principale
                  _buildConfigCard(
                    'Salle principale',
                    [
                      _buildSliderConfig(
                        'Largeur (m)',
                        _roomWidth,
                        10.0,
                        100.0,
                        (value) => setState(() => _roomWidth = value),
                      ),
                      _buildSliderConfig(
                        'Longueur (m)',
                        _roomHeight,
                        10.0,
                        80.0,
                        (value) => setState(() => _roomHeight = value),
                      ),
                      _buildInfoRow('Surface totale', '${(_roomWidth * _roomHeight).toInt()}m²'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Salle annexe
                  _buildConfigCard(
                    'Salle annexe (optionnel)',
                    [
                      _buildSwitchConfig(
                        'Ajouter une salle annexe',
                        _hasSecondRoom,
                        (value) => setState(() => _hasSecondRoom = value),
                      ),
                      if (_hasSecondRoom) ...[
                        _buildSliderConfig(
                          'Largeur annexe (m)',
                          _secondRoomWidth,
                          5.0,
                          50.0,
                          (value) => setState(() => _secondRoomWidth = value),
                        ),
                        _buildSliderConfig(
                          'Longueur annexe (m)',
                          _secondRoomHeight,
                          5.0,
                          40.0,
                          (value) => setState(() => _secondRoomHeight = value),
                        ),
                        _buildInfoRow('Surface annexe', '${(_secondRoomWidth * _secondRoomHeight).toInt()}m²'),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Résumé
                  _buildSummaryCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyConstraintsStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Contraintes de Sécurité',
            'Paramètres obligatoires et réglementaires',
            Icons.security,
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildConfigCard(
                    'Largeurs d\'allées',
                    [
                      _buildSliderConfig(
                        'Allées principales (m)',
                        _mainAlleyWidth,
                        2.0,
                        5.0,
                        (value) => setState(() => _mainAlleyWidth = value),
                      ),
                      _buildSliderConfig(
                        'Allées secondaires (m)',
                        _secondaryAlleyWidth,
                        1.5,
                        3.0,
                        (value) => setState(() => _secondaryAlleyWidth = value),
                      ),
                      _buildSliderConfig(
                        'Accessibilité PMR (m)',
                        _pmrAlleyWidth,
                        1.4,
                        2.0,
                        (value) => setState(() => _pmrAlleyWidth = value),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildConfigCard(
                    'Sécurité incendie',
                    [
                      _buildSliderConfig(
                        'Distance max sortie secours (m)',
                        _emergencyDistance,
                        10.0,
                        25.0,
                        (value) => setState(() => _emergencyDistance = value),
                      ),
                      _buildInfoRow('Réglementation', 'ERP Type L'),
                      _buildInfoRow('Capacité max calculée', '${_calculateMaxCapacity()} personnes'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildWarningCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedElementsStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Éléments Fixes',
            'Placez scène, bars, WC et zones interdites',
            Icons.widgets,
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Plan interactif simplifié
                  _buildMiniLayoutView(),
                  
                  const SizedBox(height: 16),
                  
                  _buildConfigCard(
                    'Éléments disponibles',
                    [
                      _buildElementButton('Scène', Icons.theater_comedy, LayoutElement.stage),
                      _buildElementButton('Bar', Icons.local_bar, LayoutElement.bar),
                      _buildElementButton('WC', Icons.wc, LayoutElement.toilet),
                      _buildElementButton('Stockage', Icons.inventory, LayoutElement.storage),
                      _buildElementButton('Zone interdite', Icons.block, LayoutElement.pillar),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildFixedElementsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandConfigurationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Configuration Stands',
            'Paramètres pour la génération automatique',
            Icons.store,
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildConfigCard(
                    'Nombre de stands',
                    [
                      _buildSliderConfig(
                        'Tatoueurs attendus',
                        _expectedTattooers.toDouble(),
                        10.0,
                        100.0,
                        (value) => setState(() => _expectedTattooers = value.toInt()),
                        isInteger: true,
                      ),
                      _buildSliderConfig(
                        'Stands marchands',
                        _expectedMerchants.toDouble(),
                        0.0,
                        20.0,
                        (value) => setState(() => _expectedMerchants = value.toInt()),
                        isInteger: true,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildConfigCard(
                    'Dimensions par défaut',
                    [
                      _buildSliderConfig(
                        'Profondeur stands (m)',
                        _defaultDepth,
                        1.5,
                        4.0,
                        (value) => setState(() => _defaultDepth = value),
                      ),
                      _buildInfoRow('Tailles proposées', '${_defaultDepth.toStringAsFixed(1)}x2m, ${_defaultDepth.toStringAsFixed(1)}x3m, ${_defaultDepth.toStringAsFixed(1)}x4m...'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildConfigCard(
                    'Tarification',
                    [
                      _buildSliderConfig(
                        'Prix de base (€/m²)',
                        _basePricePerSqm,
                        50.0,
                        150.0,
                        (value) => setState(() => _basePricePerSqm = value),
                      ),
                      _buildSliderConfig(
                        'Multiplicateur premium',
                        _premiumMultiplier,
                        1.2,
                        2.0,
                        (value) => setState(() => _premiumMultiplier = value),
                      ),
                      _buildSliderConfig(
                        'Multiplicateur discount',
                        _discountMultiplier,
                        0.5,
                        0.9,
                        (value) => setState(() => _discountMultiplier = value),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildRevenueProjection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedLayoutStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Plan Généré',
            'Résultat de l\'optimisation IA',
            Icons.auto_awesome,
          ),
          
          const SizedBox(height: 24),
          
          if (_generatedStands.isEmpty)
            _buildNoLayoutState()
          else
            Expanded(
              child: Column(
                children: [
                  _buildLayoutStats(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildFullLayoutView(),
                  ),
                  const SizedBox(height: 16),
                  _buildLayoutActions(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
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

  Widget _buildConfigCard(String title, List<Widget> children) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderConfig(String label, double value, double min, double max, Function(double) onChanged, {bool isInteger = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: KipikTheme.rouge.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isInteger ? value.toInt().toString() : value.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 14,
                  color: KipikTheme.rouge,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: KipikTheme.rouge,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: KipikTheme.rouge,
            overlayColor: KipikTheme.rouge.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: isInteger ? (max - min).toInt() : null,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSwitchConfig(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: KipikTheme.rouge,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalArea = _roomWidth * _roomHeight + (_hasSecondRoom ? _secondRoomWidth * _secondRoomHeight : 0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.summarize, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Résumé de configuration',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Surface totale', '${totalArea.toInt()}m²'),
          _buildSummaryRow('Capacité estimée', '${(totalArea / 2.5).toInt()} personnes'),
          _buildSummaryRow('Stands potentiels', '${(totalArea * 0.6 / 6).toInt()} emplacements'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ces paramètres respectent la réglementation ERP. Consultez votre SDIS local pour validation.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniLayoutView() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gesture, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Plan interactif',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            Text(
              'Drag & Drop pour placer les éléments',
              style: TextStyle(
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

  Widget _buildElementButton(String label, IconData icon, LayoutElement type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: () => _addElement(type),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade100,
          foregroundColor: Colors.blue.shade700,
          minimumSize: const Size(double.infinity, 36),
        ),
      ),
    );
  }

  Widget _buildFixedElementsList() {
    return _buildConfigCard(
      'Éléments placés (${_fixedElements.length + _forbiddenZones.length})',
      [
        ..._fixedElements.map((element) => _buildElementListItem(element, true)),
        ..._forbiddenZones.map((element) => _buildElementListItem(element, false)),
        if (_fixedElements.isEmpty && _forbiddenZones.isEmpty)
          const Text(
            'Aucun élément placé',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildElementListItem(LayoutPoint element, bool isFixed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isFixed ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFixed ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getElementIcon(element.type),
            size: 16,
            color: isFixed ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              element.label ?? _getElementLabel(element.type),
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: isFixed ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
          Text(
            '${element.width.toInt()}x${element.height.toInt()}m',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              color: isFixed ? Colors.green.shade600 : Colors.red.shade600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeElement(element, isFixed),
            child: Icon(
              Icons.delete,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueProjection() {
    final projectedRevenue = _calculateProjectedRevenue();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.euro, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Projection de revenus',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRevenueRow('Revenus tatoueurs', '${projectedRevenue['tattoo']?.toInt() ?? 0}€'),
          _buildRevenueRow('Revenus marchands', '${projectedRevenue['merchant']?.toInt() ?? 0}€'),
          const Divider(color: Colors.white54),
          _buildRevenueRow('Total estimé', '${projectedRevenue['total']?.toInt() ?? 0}€'),
          _buildRevenueRow('Commission Kipik (1%)', '${((projectedRevenue['total'] ?? 0) * 0.01).toInt()}€'),
        ],
      ),
    );
  }

  Widget _buildRevenueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLayoutState() {
    return Expanded(
      child: Center(
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
                Icons.auto_awesome,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Plan en attente de génération',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Cliquez sur "Générer Plan IA" pour créer automatiquement l\'agencement optimal',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutStats() {
    if (_generatedStands.isEmpty) return const SizedBox.shrink();
    
    final stats = _calculateLayoutStats();
    
    return Container(
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
        children: [
          const Text(
            'Statistiques du plan généré',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatItem('Stands', stats['totalStands']?.toString() ?? '0', Icons.store)),
              Expanded(child: _buildStatItem('Surface', '${stats['usedArea']?.toInt() ?? 0}m²', Icons.square_foot)),
              Expanded(child: _buildStatItem('Revenus', '${stats['revenue']?.toInt() ?? 0}€', Icons.euro)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: KipikTheme.rouge, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 16,
            color: KipikTheme.rouge,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFullLayoutView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Plan de convention généré',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            Text(
              'Vue interactive avec stands optimisés',
              style: TextStyle(
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

  Widget _buildLayoutActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _exportLayout,
            icon: const Icon(Icons.download, size: 16),
            label: const Text(
              'Exporter PDF',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _optimizeLayout,
            icon: const Icon(Icons.tune, size: 16),
            label: const Text(
              'Réoptimiser',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _publishLayout,
            icon: const Icon(Icons.publish, size: 16),
            label: const Text(
              'Publier',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text(
                  'Précédent',
                  style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ),
          if (_currentStep > 0 && _currentStep < 4) const SizedBox(width: 12),
          if (_currentStep < 4)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _nextStep,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text(
                  'Suivant',
                  style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: KipikTheme.rouge,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Configuration des salles';
      case 1: return 'Contraintes de sécurité';
      case 2: return 'Placement des éléments fixes';
      case 3: return 'Paramètres des stands';
      case 4: return 'Plan généré et optimisé';
      default: return '';
    }
  }

  IconData _getElementIcon(LayoutElement type) {
    switch (type) {
      case LayoutElement.stage: return Icons.theater_comedy;
      case LayoutElement.bar: return Icons.local_bar;
      case LayoutElement.toilet: return Icons.wc;
      case LayoutElement.storage: return Icons.inventory;
      case LayoutElement.foodTruck: return Icons.local_shipping;
      case LayoutElement.entrance: return Icons.door_front_door;
      case LayoutElement.exit: return Icons.exit_to_app;
      case LayoutElement.pillar: return Icons.block;
      case LayoutElement.emergency: return Icons.emergency;
    }
  }

  String _getElementLabel(LayoutElement type) {
    switch (type) {
      case LayoutElement.stage: return 'Scène';
      case LayoutElement.bar: return 'Bar';
      case LayoutElement.toilet: return 'Sanitaires';
      case LayoutElement.storage: return 'Stockage';
      case LayoutElement.foodTruck: return 'Food Truck';
      case LayoutElement.entrance: return 'Entrée';
      case LayoutElement.exit: return 'Sortie';
      case LayoutElement.pillar: return 'Zone interdite';
      case LayoutElement.emergency: return 'Sortie secours';
    }
  }

  int _calculateMaxCapacity() {
    final totalArea = _roomWidth * _roomHeight + (_hasSecondRoom ? _secondRoomWidth * _secondRoomHeight : 0);
    return (totalArea / 2.5).toInt(); // 2.5m² par personne (norme ERP)
  }

  Map<String, double> _calculateProjectedRevenue() {
    final totalArea = _roomWidth * _roomHeight + (_hasSecondRoom ? _secondRoomWidth * _secondRoomHeight : 0);
    final availableArea = totalArea * 0.6; // 60% pour stands
    
    final tattooArea = availableArea * (_tattooRatio / 100);
    final merchantArea = availableArea * (_merchantRatio / 100);
    
    final tattooRevenue = tattooArea * _basePricePerSqm;
    final merchantRevenue = merchantArea * _basePricePerSqm * 0.8; // Marchands moins chers
    
    return {
      'tattoo': tattooRevenue,
      'merchant': merchantRevenue,
      'total': tattooRevenue + merchantRevenue,
    };
  }

  Map<String, dynamic> _calculateLayoutStats() {
    if (_generatedStands.isEmpty) return {};
    
    final totalStands = _generatedStands.length;
    final usedArea = _generatedStands.fold(0.0, (sum, stand) => sum + stand.area);
    final revenue = _generatedStands.fold(0.0, (sum, stand) => sum + stand.totalPrice);
    
    return {
      'totalStands': totalStands,
      'usedArea': usedArea,
      'revenue': revenue,
    };
  }

  // Actions
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aide générateur de plan - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addElement(LayoutElement type) {
    // Ajouter élément par défaut
    final newElement = LayoutPoint(
      x: 10,
      y: 10,
      width: type == LayoutElement.stage ? 6 : 3,
      height: type == LayoutElement.stage ? 4 : 2,
      type: type,
      label: '${_getElementLabel(type)} ${_fixedElements.length + 1}',
    );
    
    setState(() {
      _fixedElements.add(newElement);
    });
    
    HapticFeedback.lightImpact();
  }

  void _removeElement(LayoutPoint element, bool isFixed) {
    setState(() {
      if (isFixed) {
        _fixedElements.remove(element);
      } else {
        _forbiddenZones.remove(element);
      }
    });
    
    HapticFeedback.lightImpact();
  }

  void _generateLayout() async {
    setState(() => _isGenerating = true);
    
    // Simulation génération IA
    await Future.delayed(const Duration(seconds: 3));
    
    // Génération stands simulée
    final generatedStands = <StandSlot>[];
    
    for (int i = 0; i < _expectedTattooers; i++) {
      generatedStands.add(
        StandSlot(
          id: 'T${i + 1}',
          x: (i % 10) * 4.0 + 5,
          y: (i ~/ 10) * 3.0 + 8,
          width: _defaultDepth,
          height: 3.0,
          type: StandType.tattoo,
          zone: i < 15 ? ZoneType.premium : ZoneType.standard,
          pricePerSqm: i < 15 ? _basePricePerSqm * _premiumMultiplier : _basePricePerSqm,
        ),
      );
    }
    
    for (int i = 0; i < _expectedMerchants; i++) {
      generatedStands.add(
        StandSlot(
          id: 'M${i + 1}',
          x: 2.0,
          y: i * 3.0 + 8,
          width: 2.0,
          height: 2.0,
          type: StandType.merchant,
          zone: ZoneType.standard,
          pricePerSqm: _basePricePerSqm * 0.8,
        ),
      );
    }
    
    setState(() {
      _generatedStands = generatedStands;
      _isGenerating = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plan généré avec succès ! 🎉'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportLayout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export PDF du plan - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _optimizeLayout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réoptimisation du plan - À implémenter'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _publishLayout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Publication du plan - À implémenter'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}