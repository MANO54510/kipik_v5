// lib/pages/conventions/convention_tattoers_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/common/drawers/drawer_factory.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../enums/tattoo_style.dart';
import 'convention_booking_page.dart';

class ConventionTattooersListPage extends StatefulWidget {
  final String conventionId;

  const ConventionTattooersListPage({
    Key? key,
    required this.conventionId,
  }) : super(key: key);

  @override
  State<ConventionTattooersListPage> createState() => _ConventionTattooersListPageState();
}

class _ConventionTattooersListPageState extends State<ConventionTattooersListPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _listController;
  late Animation<double> _listAnimation;
  
  // Recherche et filtres
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TattooStyle? _selectedStyle;
  String _selectedFilter = 'Tous';
  
  final List<String> _filterOptions = [
    'Tous',
    'Disponibles',
    'Premium',
    'Nouveaux',
  ];

  // Données
  List<ConventionTattooer> _allTattooers = [];
  List<ConventionTattooer> _filteredTattooers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupSearchListener();
    _loadTattooers();
  }

  @override
  void dispose() {
    _listController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listController, curve: Curves.easeOutCubic),
    );

    _listController.forward();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
      _applyFilters();
    });
  }

  void _loadTattooers() {
    // Simulation chargement données
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _allTattooers = _generateTattooers();
        _filteredTattooers = List.from(_allTattooers);
        _isLoading = false;
      });
    });
  }

  List<ConventionTattooer> _generateTattooers() {
    return [
      ConventionTattooer(
        id: 'tat1',
        name: 'Alex Martin',
        bio: 'Spécialiste du réalisme depuis 15 ans. Passionné par les portraits et les animaux.',
        style: TattooStyle.realism,
        experienceYears: 15,
        rating: 4.9,
        reviewCount: 234,
        standNumber: 'A12',
        isAvailable: true,
        isPremium: true,
        isNewParticipant: false,
        priceRange: '150-300€',
        gallery: ['url1', 'url2', 'url3'],
        specialties: ['Portraits', 'Animaux', 'Noir et blanc'],
        availableSlots: [
          'Vendredi 15/08 - 14h00',
          'Samedi 16/08 - 10h00',
          'Dimanche 17/08 - 16h00',
        ],
        social: {
          'instagram': '@alexmartin_tattoo',
          'facebook': 'AlexMartinTattoo',
        },
      ),
      ConventionTattooer(
        id: 'tat2',
        name: 'Emma Dubois',
        bio: 'Artiste spécialisée dans l\'art japonais traditionnel. Formée au Japon.',
        style: TattooStyle.japanese,
        experienceYears: 12,
        rating: 4.8,
        reviewCount: 189,
        standNumber: 'B05',
        isAvailable: true,
        isPremium: true,
        isNewParticipant: false,
        priceRange: '200-400€',
        gallery: ['url4', 'url5', 'url6'],
        specialties: ['Irezumi', 'Dragons', 'Koi'],
        availableSlots: [
          'Vendredi 15/08 - 11h00',
          'Samedi 16/08 - 15h00',
        ],
        social: {
          'instagram': '@emma_irezumi',
          'website': 'www.emmadubois-tattoo.com',
        },
      ),
      ConventionTattooer(
        id: 'tat3',
        name: 'Marco Silva',
        bio: 'Créateur de motifs géométriques uniques. Approche moderne et minimaliste.',
        style: TattooStyle.geometric,
        experienceYears: 8,
        rating: 4.7,
        reviewCount: 156,
        standNumber: 'C18',
        isAvailable: false, // Complet
        isPremium: false,
        isNewParticipant: true,
        priceRange: '100-250€',
        gallery: ['url7', 'url8', 'url9'],
        specialties: ['Géométrie sacrée', 'Mandala', 'Dotwork'],
        availableSlots: [],
        social: {
          'instagram': '@marco_geometric',
        },
      ),
      ConventionTattooer(
        id: 'tat4',
        name: 'Sophie Chen',
        bio: 'Pionnière du style watercolor. Couleurs vibrantes et techniques innovantes.',
        style: TattooStyle.watercolor,
        experienceYears: 10,
        rating: 4.9,
        reviewCount: 203,
        standNumber: 'D22',
        isAvailable: true,
        isPremium: true,
        isNewParticipant: false,
        priceRange: '180-350€',
        gallery: ['url10', 'url11', 'url12'],
        specialties: ['Aquarelle', 'Fleurs', 'Abstrait'],
        availableSlots: [
          'Samedi 16/08 - 13h00',
          'Dimanche 17/08 - 10h00',
          'Dimanche 17/08 - 14h00',
        ],
        social: {
          'instagram': '@sophie_watercolor',
          'tiktok': '@sophiechen_art',
        },
      ),
      ConventionTattooer(
        id: 'tat5',
        name: 'Thomas Noir',
        bio: 'Maître du blackwork et tribal moderne. Style bold et graphique.',
        style: TattooStyle.blackwork,
        experienceYears: 18,
        rating: 4.6,
        reviewCount: 167,
        standNumber: 'E31',
        isAvailable: true,
        isPremium: false,
        isNewParticipant: false,
        priceRange: '120-280€',
        gallery: ['url13', 'url14', 'url15'],
        specialties: ['Blackwork', 'Tribal', 'Ornements'],
        availableSlots: [
          'Vendredi 15/08 - 16h00',
          'Dimanche 17/08 - 11h00',
        ],
        social: {
          'instagram': '@thomas_blackwork',
        },
      ),
    ];
  }

  void _applyFilters() {
    var filtered = _allTattooers.where((tattooer) {
      // Filtre par recherche
      final matchesSearch = _searchQuery.isEmpty ||
          tattooer.name.toLowerCase().contains(_searchQuery) ||
          tattooer.bio.toLowerCase().contains(_searchQuery) ||
          tattooer.style.displayName.toLowerCase().contains(_searchQuery) ||
          tattooer.specialties.any((s) => s.toLowerCase().contains(_searchQuery));

      if (!matchesSearch) return false;

      // Filtre par style
      if (_selectedStyle != null && tattooer.style != _selectedStyle) {
        return false;
      }

      // Filtre par catégorie
      switch (_selectedFilter) {
        case 'Disponibles':
          return tattooer.isAvailable;
        case 'Premium':
          return tattooer.isPremium;
        case 'Nouveaux':
          return tattooer.isNewParticipant;
        default:
          return true;
      }
    }).toList();

    // Trier par rating puis par nom
    filtered.sort((a, b) {
      final ratingComparison = b.rating.compareTo(a.rating);
      if (ratingComparison != 0) return ratingComparison;
      return a.name.compareTo(b.name);
    });

    setState(() {
      _filteredTattooers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: DrawerFactory.of(context),
      appBar: CustomAppBarKipik(
        title: 'Tatoueurs Présents',
        subtitle: '${_filteredTattooers.length} artistes',
        showBackButton: true,
        showBurger: true,
        useProStyle: false,
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
            child: Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: KipikTheme.rouge),
                        )
                      : FadeTransition(
                          opacity: _listAnimation,
                          child: _buildTattooersList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un tatoueur, style...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: KipikTheme.rouge),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.black54,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            style: const TextStyle(color: Colors.white),
          ),

          const SizedBox(height: 16),

          // Filtres
          Row(
            children: [
              // Filtre par catégorie
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                              _applyFilters();
                            }
                          },
                          backgroundColor: Colors.black54,
                          selectedColor: KipikTheme.rouge.withOpacity(0.3),
                          labelStyle: TextStyle(
                            color: isSelected ? KipikTheme.rouge : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Filtre par style
              PopupMenuButton<TattooStyle?>(
                icon: Icon(
                  Icons.palette,
                  color: _selectedStyle != null ? KipikTheme.rouge : Colors.white70,
                ),
                color: Colors.grey[900],
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('Tous les styles', style: TextStyle(color: Colors.white)),
                  ),
                  ...TattooStyle.values.map((style) => PopupMenuItem(
                    value: style,
                    child: Text(style.displayName, style: TextStyle(color: Colors.white)),
                  )),
                ],
                onSelected: (style) {
                  setState(() {
                    _selectedStyle = style;
                  });
                  _applyFilters();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTattooersList() {
    if (_filteredTattooers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Aucun tatoueur trouvé',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontFamily: 'PermanentMarker',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTattooers.length,
      itemBuilder: (context, index) {
        final tattooer = _filteredTattooers[index];
        return _buildTattooerCard(tattooer, index);
      },
    );
  }

  Widget _buildTattooerCard(ConventionTattooer tattooer, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tattooer.isPremium 
              ? KipikTheme.rouge.withOpacity(0.5) 
              : Colors.grey.shade700,
          width: tattooer.isPremium ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header avec photo et infos principales
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: tattooer.style.color.withOpacity(0.3),
                      child: Text(
                        tattooer.name.split(' ').map((n) => n[0]).join(),
                        style: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (tattooer.isPremium)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: KipikTheme.rouge,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star, color: Colors.white, size: 12),
                        ),
                      ),
                    if (tattooer.isNewParticipant)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fiber_new, color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Infos principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tattooer.name,
                              style: const TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: tattooer.style.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tattooer.style.displayName,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: tattooer.style.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Rating et expérience
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (i) => Icon(
                              Icons.star,
                              size: 14,
                              color: i < tattooer.rating.floor() 
                                  ? Colors.amber 
                                  : Colors.grey,
                            )),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tattooer.rating} (${tattooer.reviewCount})',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${tattooer.experienceYears} ans',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Stand et prix
                      Row(
                        children: [
                          Icon(Icons.store, color: KipikTheme.rouge, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Stand ${tattooer.standNumber}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            tattooer.priceRange,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.green.shade300,
                              fontWeight: FontWeight.bold,
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

          // Bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              tattooer.bio,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Spécialités
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tattooer.specialties.map((specialty) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    specialty,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Disponibilités
          if (tattooer.availableSlots.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Créneaux disponibles:',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.green.shade300,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...tattooer.availableSlots.take(3).map((slot) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.green.shade300, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            slot,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.event_busy, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Agenda complet',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Réseaux sociaux
                if (tattooer.social.isNotEmpty) ...[
                  ...tattooer.social.entries.take(2).map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        onPressed: () => _openSocialLink(entry.key, entry.value),
                        icon: Icon(
                          _getSocialIcon(entry.key),
                          color: Colors.white70,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                ],

                const Spacer(),

                // Bouton portfolio
                OutlinedButton.icon(
                  onPressed: () => _viewPortfolio(tattooer),
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text(
                    'Portfolio',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

                const SizedBox(width: 8),

                // Bouton réserver
                ElevatedButton.icon(
                  onPressed: tattooer.isAvailable 
                      ? () => _bookWithTattooer(tattooer) 
                      : null,
                  icon: Icon(
                    tattooer.isAvailable ? Icons.calendar_month : Icons.event_busy,
                    size: 16,
                  ),
                  label: Text(
                    tattooer.isAvailable ? 'Réserver' : 'Complet',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tattooer.isAvailable 
                        ? KipikTheme.rouge 
                        : Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'tiktok':
        return Icons.video_camera_back;
      case 'website':
        return Icons.language;
      default:
        return Icons.link;
    }
  }

  void _openSocialLink(String platform, String handle) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de $platform: $handle'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewPortfolio(ConventionTattooer tattooer) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: tattooer.style.color.withOpacity(0.3),
                      child: Text(
                        tattooer.name.split(' ').map((n) => n[0]).join(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tattooer.name,
                            style: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Portfolio - ${tattooer.style.displayName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Portfolio (simulé)
              Expanded(
                child: GridView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.grey, size: 40),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _bookWithTattooer(ConventionTattooer tattooer) {
    HapticFeedback.mediumImpact();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConventionBookingPage(
          conventionId: widget.conventionId,
          tattooerId: tattooer.id,
        ),
      ),
    );
  }
}

// Modèle pour les tatoueurs de convention
class ConventionTattooer {
  final String id;
  final String name;
  final String bio;
  final TattooStyle style;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final String standNumber;
  final bool isAvailable;
  final bool isPremium;
  final bool isNewParticipant;
  final String priceRange;
  final List<String> gallery;
  final List<String> specialties;
  final List<String> availableSlots;
  final Map<String, String> social;

  ConventionTattooer({
    required this.id,
    required this.name,
    required this.bio,
    required this.style,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    required this.standNumber,
    required this.isAvailable,
    required this.isPremium,
    required this.isNewParticipant,
    required this.priceRange,
    required this.gallery,
    required this.specialties,
    required this.availableSlots,
    required this.social,
  });
}