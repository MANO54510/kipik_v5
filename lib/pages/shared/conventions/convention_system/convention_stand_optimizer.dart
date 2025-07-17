// lib/pages/shared/conventions/convention_system/convention_stand_optimizer.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/kipik_theme.dart';
import '../../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../../../models/user_subscription.dart';
import '../../../../models/user_role.dart';
import '../../../../services/features/premium_feature_guard.dart';
import 'dart:math' as math;

// Modèles pour l'optimiseur
class ConventionSpace {
  final String id;
  final String name;
  final SpaceType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final List<FixedElement> elements;
  final List<StandLinear> linears;
  final SpaceConfiguration configuration;

  ConventionSpace({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.elements = const [],
    this.linears = const [],
    required this.configuration,
  });

  double get totalArea => width * height;
  double get fixedElementsArea => elements.fold(0.0, (sum, el) => sum + (el.width * el.height));
  double get usableArea => totalArea - fixedElementsArea;
  double get standsArea => linears.fold(0.0, (sum, linear) => 
    sum + linear.stands.fold(0.0, (standSum, stand) => standSum + stand.area));
  double get optimizationRate => usableArea > 0 ? (standsArea / usableArea) * 100 : 0;
  double get totalRevenue => linears.fold(0.0, (sum, linear) => 
    sum + linear.stands.fold(0.0, (standSum, stand) => standSum + stand.totalPrice));
  int get totalStands => linears.fold(0, (sum, linear) => sum + linear.stands.length);

  ConventionSpace copyWith({
    String? id,
    String? name,
    SpaceType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    List<FixedElement>? elements,
    List<StandLinear>? linears,
    SpaceConfiguration? configuration,
  }) {
    return ConventionSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      elements: elements ?? this.elements,
      linears: linears ?? this.linears,
      configuration: configuration ?? this.configuration,
    );
  }
}

class FixedElement {
  final String id;
  final String name;
  final ElementType type;
  final double x;
  final double y;
  final double width;
  final double height;

  FixedElement({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class StandLinear {
  final String id;
  final String name;
  final LinearType type;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double depth;
  final List<Stand> stands;

  StandLinear({
    required this.id,
    required this.name,
    required this.type,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.depth,
    this.stands = const [],
  });

  double get length => math.sqrt(math.pow(endX - startX, 2) + math.pow(endY - startY, 2));

  StandLinear copyWith({
    String? id,
    String? name,
    LinearType? type,
    double? startX,
    double? startY,
    double? endX,
    double? endY,
    double? depth,
    List<Stand>? stands,
  }) {
    return StandLinear(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      startX: startX ?? this.startX,
      startY: startY ?? this.startY,
      endX: endX ?? this.endX,
      endY: endY ?? this.endY,
      depth: depth ?? this.depth,
      stands: stands ?? this.stands,
    );
  }
}

class Stand {
  final String id;
  final String name;
  final double x;
  final double y;
  final double width;
  final double depth;
  final double pricePerSqm;
  final LinearType type;
  final StandStatus status;

  Stand({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.depth,
    required this.pricePerSqm,
    required this.type,
    this.status = StandStatus.available,
  });

  double get area => width * depth;
  double get totalPrice => area * pricePerSqm;
}

class SpaceConfiguration {
  final double ceilingHeight;
  final bool accessiblePMR;
  final int emergencyExits;
  final bool allowCustomStandSelection;

  SpaceConfiguration({
    required this.ceilingHeight,
    required this.accessiblePMR,
    required this.emergencyExits,
    required this.allowCustomStandSelection,
  });
}

class GlobalConfiguration {
  final double standDepth;
  final double aisleWidth;
  final double secondaryAisleWidth;
  final double emergencyAisleWidth;
  final double pricePerSqmTattoo;
  final double pricePerSqmMerchant;

  GlobalConfiguration({
    this.standDepth = 3.0,
    this.aisleWidth = 2.0,
    this.secondaryAisleWidth = 1.5,
    this.emergencyAisleWidth = 3.0,
    this.pricePerSqmTattoo = 80.0,
    this.pricePerSqmMerchant = 60.0,
  });

  GlobalConfiguration copyWith({
    double? standDepth,
    double? aisleWidth,
    double? secondaryAisleWidth,
    double? emergencyAisleWidth,
    double? pricePerSqmTattoo,
    double? pricePerSqmMerchant,
  }) {
    return GlobalConfiguration(
      standDepth: standDepth ?? this.standDepth,
      aisleWidth: aisleWidth ?? this.aisleWidth,
      secondaryAisleWidth: secondaryAisleWidth ?? this.secondaryAisleWidth,
      emergencyAisleWidth: emergencyAisleWidth ?? this.emergencyAisleWidth,
      pricePerSqmTattoo: pricePerSqmTattoo ?? this.pricePerSqmTattoo,
      pricePerSqmMerchant: pricePerSqmMerchant ?? this.pricePerSqmMerchant,
    );
  }
}

// Enums
enum SpaceType { room, outdoor }
enum ElementType { entrance, stage, bar, wc, food, storage, pillar }
enum LinearType { tattoo, merchant, mixed }
enum StandStatus { available, reserved, occupied }

// Extensions pour les enums
extension SpaceTypeExtension on SpaceType {
  String get displayName {
    switch (this) {
      case SpaceType.room:
        return 'Salle';
      case SpaceType.outdoor:
        return 'Extérieur';
    }
  }

  Color get color {
    switch (this) {
      case SpaceType.room:
        return Colors.grey.shade100;
      case SpaceType.outdoor:
        return Colors.green.shade100;
    }
  }

  Color get borderColor {
    switch (this) {
      case SpaceType.room:
        return Colors.grey.shade600;
      case SpaceType.outdoor:
        return Colors.green.shade600;
    }
  }
}

extension ElementTypeExtension on ElementType {
  String get displayName {
    switch (this) {
      case ElementType.entrance:
        return 'Entrée';
      case ElementType.stage:
        return 'Scène';
      case ElementType.bar:
        return 'Bar';
      case ElementType.wc:
        return 'WC';
      case ElementType.food:
        return 'Food Truck';
      case ElementType.storage:
        return 'Stockage';
      case ElementType.pillar:
        return 'Pilier';
    }
  }

  Color get color {
    switch (this) {
      case ElementType.entrance:
        return Colors.green;
      case ElementType.stage:
        return Colors.purple;
      case ElementType.bar:
        return Colors.orange;
      case ElementType.wc:
        return Colors.cyan;
      case ElementType.food:
        return Colors.deepOrange;
      case ElementType.storage:
        return Colors.grey;
      case ElementType.pillar:
        return Colors.blueGrey;
    }
  }

  String get icon {
    switch (this) {
      case ElementType.entrance:
        return '🚪';
      case ElementType.stage:
        return '🎭';
      case ElementType.bar:
        return '🍺';
      case ElementType.wc:
        return '🚽';
      case ElementType.food:
        return '🚚';
      case ElementType.storage:
        return '📦';
      case ElementType.pillar:
        return '🏛️';
    }
  }

  Size get defaultSize {
    switch (this) {
      case ElementType.entrance:
        return const Size(80, 20);
      case ElementType.stage:
        return const Size(120, 60);
      case ElementType.bar:
        return const Size(60, 40);
      case ElementType.wc:
        return const Size(40, 40);
      case ElementType.food:
        return const Size(80, 40);
      case ElementType.storage:
        return const Size(60, 40);
      case ElementType.pillar:
        return const Size(20, 20);
    }
  }
}

extension LinearTypeExtension on LinearType {
  String get displayName {
    switch (this) {
      case LinearType.tattoo:
        return 'Tatoueurs';
      case LinearType.merchant:
        return 'Marchands';
      case LinearType.mixed:
        return 'Mixte';
    }
  }

  Color get color {
    switch (this) {
      case LinearType.tattoo:
        return Colors.red.shade600;
      case LinearType.merchant:
        return Colors.blue.shade600;
      case LinearType.mixed:
        return Colors.purple.shade600;
    }
  }
}

// Widget principal
class ConventionStandOptimizer extends StatefulWidget {
  final String conventionId;
  final UserRole userType;

  const ConventionStandOptimizer({
    Key? key,
    required this.conventionId,
    required this.userType,
  }) : super(key: key);

  @override
  State<ConventionStandOptimizer> createState() => _ConventionStandOptimizerState();
}

class _ConventionStandOptimizerState extends State<ConventionStandOptimizer> {
  List<ConventionSpace> _spaces = [];
  ConventionSpace? _selectedSpace;
  String _selectedTool = 'select';
  double _zoom = 1.0;
  GlobalConfiguration _globalConfig = GlobalConfiguration();

  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    // Exemple de données pour la démo
    setState(() {
      _spaces = [
        ConventionSpace(
          id: 'space-1',
          name: 'Salle Principale',
          type: SpaceType.room,
          x: 50,
          y: 50,
          width: 400,
          height: 300,
          configuration: SpaceConfiguration(
            ceilingHeight: 4.0,
            accessiblePMR: true,
            emergencyExits: 2,
            allowCustomStandSelection: true,
          ),
        ),
      ];
    });
  }

  // Générer automatiquement les linéaires optimaux
  void _generateOptimalLinears(String spaceId) {
    final spaceIndex = _spaces.indexWhere((s) => s.id == spaceId);
    if (spaceIndex == -1) return;

    final space = _spaces[spaceIndex];
    final newLinears = <StandLinear>[];

    // Zone utilisable après allées
    final usableArea = Rect.fromLTWH(
      _globalConfig.aisleWidth,
      _globalConfig.aisleWidth,
      space.width - (_globalConfig.aisleWidth * 2),
      space.height - (_globalConfig.aisleWidth * 2),
    );

    // Générer linéaires horizontaux dos à dos
    double currentY = usableArea.top + _globalConfig.standDepth;
    int linearCount = 0;

    while (currentY + _globalConfig.standDepth + _globalConfig.secondaryAisleWidth < usableArea.bottom) {
      // Éviter les obstacles
      final hasCollision = space.elements.any((element) =>
          currentY < element.y + element.height && currentY + _globalConfig.standDepth > element.y);

      if (!hasCollision) {
        final linearType = LinearType.values[linearCount % LinearType.values.length];

        // Linéaire face
        newLinears.add(StandLinear(
          id: 'linear-${linearCount}',
          name: '${linearType.displayName} ${(linearCount ~/ 2) + 1}',
          type: linearType,
          startX: usableArea.left,
          startY: currentY,
          endX: usableArea.right,
          endY: currentY,
          depth: _globalConfig.standDepth,
        ));

        // Linéaire dos si espace suffisant
        if (currentY + (_globalConfig.standDepth * 2) + _globalConfig.secondaryAisleWidth < usableArea.bottom) {
          newLinears.add(StandLinear(
            id: 'linear-${linearCount + 1}',
            name: '${linearType.displayName} ${(linearCount ~/ 2) + 1} (Dos)',
            type: linearType,
            startX: usableArea.left,
            startY: currentY + _globalConfig.standDepth,
            endX: usableArea.right,
            endY: currentY + _globalConfig.standDepth,
            depth: _globalConfig.standDepth,
          ));
          linearCount += 2;
          currentY += (_globalConfig.standDepth * 2) + _globalConfig.secondaryAisleWidth;
        } else {
          linearCount++;
          currentY += _globalConfig.standDepth + _globalConfig.secondaryAisleWidth;
        }
      } else {
        currentY += _globalConfig.secondaryAisleWidth;
      }
    }

    setState(() {
      _spaces[spaceIndex] = space.copyWith(linears: newLinears);
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newLinears.length} linéaires générés automatiquement'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Générer les stands sur les linéaires
  void _generateStands(String spaceId) {
    final spaceIndex = _spaces.indexWhere((s) => s.id == spaceId);
    if (spaceIndex == -1) return;

    final space = _spaces[spaceIndex];
    final updatedLinears = <StandLinear>[];

    for (final linear in space.linears) {
      if (linear.stands.isNotEmpty) {
        updatedLinears.add(linear);
        continue;
      }

      final stands = _generateStandardCuts(linear);
      updatedLinears.add(linear.copyWith(stands: stands));
    }

    setState(() {
      _spaces[spaceIndex] = space.copyWith(linears: updatedLinears);
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stands générés sur tous les linéaires'),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<Stand> _generateStandardCuts(StandLinear linear) {
    const minStandWidth = 3.0;
    const maxStandWidth = 8.0;
    final stands = <Stand>[];
    double remainingLength = linear.length;
    double currentX = linear.startX;
    int position = 0;

    while (remainingLength >= minStandWidth) {
      double standWidth;
      if (remainingLength <= maxStandWidth) {
        standWidth = remainingLength;
      } else if (position % 3 == 0) {
        standWidth = math.min(maxStandWidth, remainingLength);
      } else if (position % 3 == 1) {
        standWidth = math.min(6.0, remainingLength);
      } else {
        standWidth = math.min(minStandWidth + 1, remainingLength);
      }

      final pricePerSqm = linear.type == LinearType.tattoo
          ? _globalConfig.pricePerSqmTattoo
          : _globalConfig.pricePerSqmMerchant;

      stands.add(Stand(
        id: '${linear.id}-stand-${position + 1}',
        name: '${linear.type == LinearType.tattoo ? 'T' : 'M'}${position + 1}',
        x: currentX,
        y: linear.startY,
        width: standWidth,
        depth: linear.depth,
        pricePerSqm: pricePerSqm,
        type: linear.type,
      ));

      currentX += standWidth;
      remainingLength -= standWidth;
      position++;
    }

    return stands;
  }

  @override
  Widget build(BuildContext context) {
    // Protection Premium pour organisateurs
    if (widget.userType == UserRole.organisateur) {
      return PremiumFeatureGuard(
        requiredFeature: PremiumFeature.conventions,
        child: _buildScaffold(),
      );
    }

    return _buildScaffold();
  }

  Widget _buildScaffold() {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Optimiseur Stands',
        subtitle: '${_spaces.fold(0, (sum, space) => sum + space.totalStands)} stands • ${_spaces.fold(0.0, (sum, space) => sum + space.totalRevenue).toStringAsFixed(0)}€',
        showBackButton: true,
        useProStyle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveConfiguration,
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportConfiguration,
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
            child: Row(
              children: [
                // Sidebar Configuration
                _buildConfigurationSidebar(),

                // Canvas Principal
                Expanded(
                  child: _buildMainCanvas(),
                ),

                // Panel espace sélectionné
                if (_selectedSpace != null) _buildSpaceConfigPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSidebar() {
    return Container(
      width: 320,
      color: Colors.white,
      child: Column(
        children: [
          // Configuration globale
          _buildGlobalConfigSection(),

          // Outils
          _buildToolsSection(),

          // Liste des espaces
          Expanded(
            child: _buildSpacesList(),
          ),

          // Actions
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildGlobalConfigSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Configuration Globale',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Profondeur stands
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profondeur stands (m)',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: _globalConfig.standDepth.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) {
                        final depth = double.tryParse(value);
                        if (depth != null && depth >= 2 && depth <= 6) {
                          setState(() {
                            _globalConfig = _globalConfig.copyWith(standDepth: depth);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Allées (m)',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: _globalConfig.aisleWidth.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) {
                        final width = double.tryParse(value);
                        if (width != null && width >= 1.5 && width <= 4) {
                          setState(() {
                            _globalConfig = _globalConfig.copyWith(aisleWidth: width);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Prix
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prix Tatoueurs €/m²',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: _globalConfig.pricePerSqmTattoo.toInt().toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) {
                        final price = double.tryParse(value);
                        if (price != null && price >= 50 && price <= 200) {
                          setState(() {
                            _globalConfig = _globalConfig.copyWith(pricePerSqmTattoo: price);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prix Marchands €/m²',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: _globalConfig.pricePerSqmMerchant.toInt().toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) {
                        final price = double.tryParse(value);
                        if (price != null && price >= 30 && price <= 150) {
                          setState(() {
                            _globalConfig = _globalConfig.copyWith(pricePerSqmMerchant: price);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection() {
    final tools = [
      {'id': 'select', 'icon': Icons.pan_tool, 'label': 'Sélectionner'},
      {'id': 'room', 'icon': Icons.crop_square, 'label': 'Salle'},
      {'id': 'outdoor', 'icon': Icons.circle_outlined, 'label': 'Extérieur'},
      {'id': 'element', 'icon': Icons.add_box, 'label': 'Élément'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Outils',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: tools.map((tool) {
              final isSelected = _selectedTool == tool['id'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTool = tool['id'] as String;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? KipikTheme.rouge.withOpacity(0.1) : Colors.grey.shade100,
                    border: Border.all(
                      color: isSelected ? KipikTheme.rouge : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tool['icon'] as IconData,
                        color: isSelected ? KipikTheme.rouge : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tool['label'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? KipikTheme.rouge : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Espaces (${_spaces.length})',
                style: const TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: _addNewSpace,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: KipikTheme.rouge.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.add,
                    color: KipikTheme.rouge,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _spaces.length,
              itemBuilder: (context, index) {
                final space = _spaces[index];
                final isSelected = _selectedSpace?.id == space.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? KipikTheme.rouge.withOpacity(0.1) : Colors.grey.shade50,
                    border: Border.all(
                      color: isSelected ? KipikTheme.rouge : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSpace = space;
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                space.name,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: space.optimizationRate >= 60
                                    ? Colors.green.shade100
                                    : space.optimizationRate >= 40
                                        ? Colors.orange.shade100
                                        : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${space.optimizationRate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: space.optimizationRate >= 60
                                      ? Colors.green.shade700
                                      : space.optimizationRate >= 40
                                          ? Colors.orange.shade700
                                          : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Surface: ${space.width.toInt()}×${space.height.toInt()}m (${space.totalArea.toInt()}m²)',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Linéaires: ${space.linears.length} • Stands: ${space.totalStands}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Revenus: ${space.totalRevenue.toStringAsFixed(0)}€',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),

                        if (isSelected) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _generateOptimalLinears(space.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: KipikTheme.rouge,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Text(
                                    'Optimiser',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _generateStands(space.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Text(
                                    'Stands',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    final totalRevenue = _spaces.fold(0.0, (sum, space) => sum + space.totalRevenue);
    final totalStands = _spaces.fold(0, (sum, space) => sum + space.totalStands);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        children: [
          // Résumé
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Revenus:',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${totalRevenue.toStringAsFixed(0)}€',
                      style: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Stands:',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      totalStands.toString(),
                      style: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Commission 1%:',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(totalRevenue * 0.01).toStringAsFixed(0)}€',
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: KipikTheme.rouge,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Boutons d'action
          ElevatedButton.icon(
            onPressed: _exportConfiguration,
            icon: const Icon(Icons.download, size: 16),
            label: const Text(
              'Exporter Configuration',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCanvas() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Toolbar canvas
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.grey,
                border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Row(
                children: [
                  // Zoom controls
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _zoom = math.max(0.5, _zoom - 0.1);
                      });
                    },
                    icon: const Icon(Icons.zoom_out, size: 20),
                  ),
                  Text(
                    '${(_zoom * 100).toInt()}%',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _zoom = math.min(2.0, _zoom + 0.1);
                      });
                    },
                    icon: const Icon(Icons.zoom_in, size: 20),
                  ),

                  const SizedBox(width: 16),
                  const VerticalDivider(),
                  const SizedBox(width: 16),

                  // Infos
                  Text(
                    '${_spaces.length} espaces • ${_spaces.fold(0, (sum, space) => sum + space.totalStands)} stands',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const Spacer(),

                  // Outil actuel
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Outil: $_selectedTool',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Canvas avec grille et espaces
            Expanded(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 3.0,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey.shade100,
                  child: CustomPaint(
                    painter: ConventionCanvasPainter(
                      spaces: _spaces,
                      selectedSpace: _selectedSpace,
                      zoom: _zoom,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceConfigPanel() {
    if (_selectedSpace == null) return const SizedBox.shrink();

    return Container(
      width: 300,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selectedSpace!.name,
                  style: const TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedSpace = null;
                  });
                },
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Statistiques
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistiques d\'optimisation',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatRow('Surface totale:', '${_selectedSpace!.totalArea.toInt()}m²'),
                _buildStatRow('Surface stands:', '${_selectedSpace!.standsArea.toStringAsFixed(1)}m²'),
                _buildStatRow('Optimisation:', '${_selectedSpace!.optimizationRate.toStringAsFixed(1)}%'),
                _buildStatRow('Revenus totaux:', '${_selectedSpace!.totalRevenue.toStringAsFixed(0)}€'),
                _buildStatRow('€/m² espace:', '${(_selectedSpace!.totalRevenue / _selectedSpace!.totalArea).toStringAsFixed(0)}€'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Configuration
          const Text(
            'Configuration',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          CheckboxListTile(
            title: const Text(
              'Tatoueurs choisissent leur emplacement',
              style: TextStyle(fontSize: 12),
            ),
            value: _selectedSpace!.configuration.allowCustomStandSelection,
            onChanged: (value) {
              if (value != null) {
                _updateSpaceConfiguration(
                  _selectedSpace!.configuration.copyWith(allowCustomStandSelection: value),
                );
              }
            },
            dense: true,
          ),

          const SizedBox(height: 16),

          // Linéaires
          Text(
            'Linéaires (${_selectedSpace!.linears.length})',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: _selectedSpace!.linears.length,
              itemBuilder: (context, index) {
                final linear = _selectedSpace!.linears[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: linear.type.color.withOpacity(0.1),
                    border: Border.all(color: linear.type.color.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        linear.name,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${linear.length.toStringAsFixed(1)}m × ${linear.depth.toStringAsFixed(1)}m',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${linear.stands.length} stands',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${linear.stands.fold(0.0, (sum, stand) => sum + stand.totalPrice).toStringAsFixed(0)}€',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _updateSpaceConfiguration(SpaceConfiguration newConfig) {
    if (_selectedSpace == null) return;

    final spaceIndex = _spaces.indexWhere((s) => s.id == _selectedSpace!.id);
    if (spaceIndex == -1) return;

    setState(() {
      _spaces[spaceIndex] = _selectedSpace!.copyWith(configuration: newConfig);
      _selectedSpace = _spaces[spaceIndex];
    });
  }

  void _addNewSpace() {
    final newSpace = ConventionSpace(
      id: 'space-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Nouvel Espace ${_spaces.length + 1}',
      type: SpaceType.room,
      x: 50.0 + (_spaces.length * 50),
      y: 50.0 + (_spaces.length * 50),
      width: 400,
      height: 300,
      configuration: SpaceConfiguration(
        ceilingHeight: 4.0,
        accessiblePMR: true,
        emergencyExits: 2,
        allowCustomStandSelection: true,
      ),
    );

    setState(() {
      _spaces.add(newSpace);
      _selectedSpace = newSpace;
    });

    HapticFeedback.mediumImpact();
  }

  void _saveConfiguration() {
    // TODO: Implémenter la sauvegarde Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration sauvegardée'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportConfiguration() {
    // TODO: Implémenter l'export JSON/PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration exportée'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// Custom Painter pour le canvas
class ConventionCanvasPainter extends CustomPainter {
  final List<ConventionSpace> spaces;
  final ConventionSpace? selectedSpace;
  final double zoom;

  ConventionCanvasPainter({
    required this.spaces,
    this.selectedSpace,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grille
    _drawGrid(canvas, size);

    // Espaces
    for (final space in spaces) {
      _drawSpace(canvas, space, space.id == selectedSpace?.id);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    const gridSize = 20.0;

    // Lignes verticales
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Lignes horizontales
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawSpace(Canvas canvas, ConventionSpace space, bool isSelected) {
    // Fond de l'espace
    final rect = Rect.fromLTWH(space.x, space.y, space.width, space.height);
    final paint = Paint()
      ..color = space.type.color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSelected ? Colors.blue : space.type.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;

    if (space.type == SpaceType.outdoor) {
      canvas.drawOval(rect, paint);
      canvas.drawOval(rect, borderPaint);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);
    }

    // Éléments fixes
    for (final element in space.elements) {
      _drawElement(canvas, space, element);
    }

    // Linéaires et stands
    for (final linear in space.linears) {
      _drawLinear(canvas, space, linear);
    }

    // Nom de l'espace
    _drawText(
      canvas,
      space.name,
      Offset(space.x + 8, space.y + 8),
      const TextStyle(
        fontFamily: 'PermanentMarker',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );

    // Optimisation %
    _drawText(
      canvas,
      '${space.optimizationRate.toStringAsFixed(1)}%',
      Offset(space.x + space.width - 50, space.y + 8),
      TextStyle(
        fontFamily: 'Roboto',
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: space.optimizationRate >= 60 ? Colors.green : Colors.orange,
      ),
    );
  }

  void _drawElement(Canvas canvas, ConventionSpace space, FixedElement element) {
    final rect = Rect.fromLTWH(
      space.x + element.x,
      space.y + element.y,
      element.width,
      element.height,
    );

    final paint = Paint()
      ..color = element.type.color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = element.type.color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);

    // Nom de l'élément
    _drawText(
      canvas,
      element.name,
      Offset(rect.center.dx - 20, rect.center.dy - 6),
      const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 8,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  void _drawLinear(Canvas canvas, ConventionSpace space, StandLinear linear) {
    // Ligne du linéaire
    final start = Offset(space.x + linear.startX, space.y + linear.startY);
    final end = Offset(space.x + linear.endX, space.y + linear.endY);

    final paint = Paint()
      ..color = linear.type.color.withOpacity(0.3)
      ..strokeWidth = linear.depth;

    canvas.drawLine(start, end, paint);

    // Stands sur le linéaire
    for (final stand in linear.stands) {
      _drawStand(canvas, space, stand);
    }
  }

  void _drawStand(Canvas canvas, ConventionSpace space, Stand stand) {
    final rect = Rect.fromLTWH(
      space.x + stand.x,
      space.y + stand.y,
      stand.width,
      stand.depth,
    );

    final paint = Paint()
      ..color = stand.type == LinearType.tattoo ? Colors.red.shade50 : Colors.blue.shade50
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = stand.type == LinearType.tattoo ? Colors.red : Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), borderPaint);

    // Nom + Prix du stand
    _drawText(
      canvas,
      stand.name,
      Offset(rect.center.dx - 10, rect.center.dy - 8),
      const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 8,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );

    _drawText(
      canvas,
      '${stand.totalPrice.toInt()}€',
      Offset(rect.center.dx - 10, rect.center.dy + 2),
      const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 7,
        fontWeight: FontWeight.w600,
        color: Colors.green,
      ),
    );
  }

  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(ConventionCanvasPainter oldDelegate) {
    return oldDelegate.spaces != spaces ||
           oldDelegate.selectedSpace != selectedSpace ||
           oldDelegate.zoom != zoom;
  }
}

// Extension pour SpaceConfiguration
extension SpaceConfigurationExtension on SpaceConfiguration {
  SpaceConfiguration copyWith({
    double? ceilingHeight,
    bool? accessiblePMR,
    int? emergencyExits,
    bool? allowCustomStandSelection,
  }) {
    return SpaceConfiguration(
      ceilingHeight: ceilingHeight ?? this.ceilingHeight,
      accessiblePMR: accessiblePMR ?? this.accessiblePMR,
      emergencyExits: emergencyExits ?? this.emergencyExits,
      allowCustomStandSelection: allowCustomStandSelection ?? this.allowCustomStandSelection,
    );
  }
}

