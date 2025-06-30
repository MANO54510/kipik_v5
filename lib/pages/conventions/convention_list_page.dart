// lib/pages/conventions/convention_list_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/models/convention.dart';
import 'package:kipik_v5/services/convention/convention_service.dart';
import 'package:kipik_v5/locator.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/widgets/common/buttons/tattoo_assistant_button.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_selector/file_selector.dart';

class ConventionListPage extends StatefulWidget {
  const ConventionListPage({Key? key}) : super(key: key);

  @override
  _ConventionListPageState createState() => _ConventionListPageState();
}

class _ConventionListPageState extends State<ConventionListPage> {
  final ConventionService _service = locator<ConventionService>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Convention> _conventions = [];
  List<Convention> _filteredConventions = [];
  
  // Filtres
  String _selectedFilter = 'Toutes';
  final List<String> _filterOptions = [
    'Toutes',
    'À venir',
    'Inscriptions ouvertes',
    'Premium',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadConventions();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  Future<void> _loadConventions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conventions = await _service.fetchConventions();
      
      setState(() {
        _conventions = conventions;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des conventions: $e');
      
      setState(() {
        _isLoading = false;
        _conventions = [];
        _filteredConventions = [];
      });
      
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des conventions. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final now = DateTime.now();
    
    // Filtrer par le texte de recherche
    var filtered = _conventions.where((convention) {
      final matchesSearch = _searchQuery.isEmpty || 
          convention.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          convention.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          convention.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesSearch;
    }).toList();
    
    // Appliquer les filtres de catégorie
    switch (_selectedFilter) {
      case 'À venir':
        filtered = filtered.where((c) => c.start.isAfter(now)).toList();
        break;
      case 'Inscriptions ouvertes':
        filtered = filtered.where((c) => c.isOpen).toList();
        break;
      case 'Premium':
        filtered = filtered.where((c) => c.isPremium).toList();
        break;
      default:
        // 'Toutes' - pas de filtre supplémentaire
        break;
    }
    
    // Trier par date (plus proches en premier)
    filtered.sort((a, b) => a.start.compareTo(b.start));
    
    setState(() {
      _filteredConventions = filtered;
    });
  }

  void _showConventionDetails(Convention convention) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, -3.0),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Poignée de glissement
                  Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  
                  // Image de la convention
                  SizedBox(
                    height: 200,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          foregroundDecoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                            ),
                          ),
                          child: Image.network(
                            convention.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[800],
                              child: Center(
                                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                convention.title,
                                style: TextStyle(
                                  fontFamily: 'PermanentMarker',
                                  fontSize: 24,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 5.0,
                                      color: Colors.black.withOpacity(0.5),
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    convention.location,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 3.0,
                                          color: Colors.black.withOpacity(0.5),
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (convention.isPremium)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: KipikTheme.rouge,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'PREMIUM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Contenu principal
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: EdgeInsets.all(16),
                      children: [
                        // Dates
                        Card(
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: KipikTheme.rouge),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dates',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDateRange(convention.start, convention.end),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Spacer(),
                                Text(
                                  _getDaysUntil(convention.start),
                                  style: TextStyle(
                                    color: KipikTheme.rouge,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Description
                        Text(
                          'À propos',
                          style: TextStyle(
                            fontFamily: 'PermanentMarker',
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          convention.description,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Artistes
                        if (convention.artists != null && convention.artists!.isNotEmpty) ...[
                          Text(
                            'Artistes confirmés',
                            style: TextStyle(
                              fontFamily: 'PermanentMarker',
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: convention.artists!.map((artist) {
                              return Chip(
                                label: Text(artist),
                                backgroundColor: Colors.grey[800],
                                labelStyle: TextStyle(color: Colors.white),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 24),
                        ],
                        
                        // Informations supplémentaires pour les événements premium
                        if (convention.isPremium && 
                           (convention.proSpots != null || 
                            convention.merchandiseSpots != null || 
                            convention.dayTicketPrice != null || 
                            convention.weekendTicketPrice != null)) ...[
                          Text(
                            'Informations supplémentaires',
                            style: TextStyle(
                              fontFamily: 'PermanentMarker',
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (convention.proSpots != null) ...[
                                    _buildInfoRow(
                                      icon: Icons.person,
                                      label: 'Places pour professionnels',
                                      value: '${convention.proSpots}',
                                    ),
                                    SizedBox(height: 8),
                                  ],
                                  if (convention.merchandiseSpots != null) ...[
                                    _buildInfoRow(
                                      icon: Icons.store,
                                      label: 'Stands marchands',
                                      value: '${convention.merchandiseSpots}',
                                    ),
                                    SizedBox(height: 8),
                                  ],
                                  if (convention.dayTicketPrice != null) ...[
                                    _buildInfoRow(
                                      icon: Icons.calendar_today,
                                      label: 'Ticket journée',
                                      value: '${convention.dayTicketPrice}€',
                                    ),
                                    SizedBox(height: 8),
                                  ],
                                  if (convention.weekendTicketPrice != null) ...[
                                    _buildInfoRow(
                                      icon: Icons.weekend,
                                      label: 'Ticket weekend',
                                      value: '${convention.weekendTicketPrice}€',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        
                        // Événements spéciaux
                        if (convention.events != null && convention.events!.isNotEmpty) ...[
                          Text(
                            'Événements spéciaux',
                            style: TextStyle(
                              fontFamily: 'PermanentMarker',
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Column(
                            children: convention.events!.map((event) {
                              return ListTile(
                                leading: Icon(Icons.event_note, color: KipikTheme.rouge),
                                title: Text(
                                  event,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16),
                        ],
                        
                        // Bouton d'inscription
                        ElevatedButton(
                          onPressed: convention.isOpen ? () {
                            // Naviguer vers la page d'inscription ou ouvrir le site web
                            if (convention.website != null && convention.website!.isNotEmpty) {
                              _launchURL(convention.website!);
                            }
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KipikTheme.rouge,
                            disabledBackgroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            convention.isOpen 
                                ? 'S\'inscrire à cette convention' 
                                : 'Inscriptions fermées',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'PermanentMarker',
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        // Lien vers le site web
                        if (convention.website != null && convention.website!.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              _launchURL(convention.website!);
                            },
                            icon: Icon(Icons.language),
                            label: Text('Visiter le site web'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                          ),
                        SizedBox(height: 16),
                        
                        // Bouton pour voir sur la carte
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context, 
                              '/conventions/map',
                              arguments: {
                                'centerId': convention.id,
                              },
                            );
                          },
                          icon: Icon(Icons.map),
                          label: Text('Voir sur la carte'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.grey[700]!),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        // Partager
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implémenter la fonctionnalité de partage
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
                            );
                          },
                          icon: Icon(Icons.share),
                          label: Text('Partager'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.grey[700]!),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: KipikTheme.rouge, size: 18),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startFormat = DateFormat('d MMM', 'fr_FR').format(start);
    final endFormat = DateFormat('d MMM yyyy', 'fr_FR').format(end);
    return '$startFormat - $endFormat';
  }

  String _getDaysUntil(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'Terminé';
    } else if (difference == 0) {
      return 'Aujourd\'hui !';
    } else if (difference == 1) {
      return 'Demain !';
    } else {
      return 'Dans $difference jours';
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d\'ouvrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: DrawerFactory.of(context), // Utilisation de la factory de drawer
      appBar: const CustomAppBarKipik(
        title: 'Conventions de Tatouage',
        showBackButton: true,
        showBurger: true,
        showNotificationIcon: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arrière-plan
          Image.asset(
            'assets/background_charbon.png',
            fit: BoxFit.cover,
          ),
          
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une convention...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                
                // Filtres
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFilter = filter;
                                _applyFilters();
                              });
                            }
                          },
                          backgroundColor: Colors.grey[900],
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
                
                // Liste des conventions
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: KipikTheme.rouge))
                      : _filteredConventions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aucune convention trouvée',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Essayez de modifier vos critères de recherche',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _filteredConventions.length,
                              itemBuilder: (context, index) {
                                final convention = _filteredConventions[index];
                                return _ConventionCard(
                                  convention: convention,
                                  onTap: () => _showConventionDetails(convention),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Naviguer vers la page d'admin des conventions (si l'utilisateur est admin)
          Navigator.pushNamed(context, '/conventions/admin');
        },
        backgroundColor: KipikTheme.rouge,
        child: Icon(Icons.admin_panel_settings, color: Colors.white),
        tooltip: 'Administration des conventions',
      ),
    );
  }
}

/// Carte représentant une convention dans la liste
class _ConventionCard extends StatelessWidget {
  final Convention convention;
  final VoidCallback onTap;
  
  const _ConventionCard({
    Key? key,
    required this.convention,
    required this.onTap,
  }) : super(key: key);
  
  String _formatDateRange(DateTime start, DateTime end) {
    final startFormat = DateFormat('d MMM', 'fr_FR').format(start);
    final endFormat = DateFormat('d MMM yyyy', 'fr_FR').format(end);
    return '$startFormat - $endFormat';
  }
  
  String _getDaysUntil(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'Terminé';
    } else if (difference == 0) {
      return 'Aujourd\'hui !';
    } else if (difference == 1) {
      return 'Demain !';
    } else {
      return 'Dans $difference jours';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isPast = convention.end.isBefore(DateTime.now());
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: convention.isPremium 
            ? BorderSide(color: KipikTheme.rouge.withOpacity(0.7), width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image de la convention
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network( // Utilisation de Image.network au lieu de Image.asset
                    convention.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  if (isPast)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'TERMINÉ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (convention.isPremium && !isPast)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: KipikTheme.rouge,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Informations de la convention
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et dates
                  Text(
                    convention.title,
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[400], size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          convention.location,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  // Dates et statut d'inscription
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event, color: KipikTheme.rouge, size: 16),
                          SizedBox(width: 4),
                          Text(
                            _formatDateRange(convention.start, convention.end),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (!isPast)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: convention.isOpen 
                                ? Colors.green.withOpacity(0.2) 
                                : Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            convention.isOpen 
                                ? 'Inscriptions ouvertes' 
                                : 'Inscriptions fermées',
                            style: TextStyle(
                              color: convention.isOpen 
                                  ? Colors.green[300] 
                                  : Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Temps restant et bouton
                  if (!isPast)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getDaysUntil(convention.start),
                          style: TextStyle(
                            color: KipikTheme.rouge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: convention.isOpen ? () {
                            // Naviguer vers la page de détails
                            onTap();
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KipikTheme.rouge,
                            disabledBackgroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'En savoir plus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
      ),
    );
  }
}