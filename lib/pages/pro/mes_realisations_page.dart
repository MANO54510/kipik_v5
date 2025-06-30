import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/common/drawers/custom_drawer_particulier.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';

class MesRealisationsPage extends StatefulWidget {
  const MesRealisationsPage({super.key});

  @override
  State<MesRealisationsPage> createState() => _MesRealisationsPageState();
}

class _MesRealisationsPageState extends State<MesRealisationsPage> {
  // Fond aléatoire
  late final String _backgroundImage;
  
  // Exemple de données structurées pour les réalisations
  final List<RealisationItem> _realisations = [
    // Ces données seraient normalement stockées dans Firestore et les images dans Firebase Storage
    RealisationItem(
      id: '1',
      imageUrl: 'assets/pro/shop_gen.jpg', // Utilisation d'un asset pour démonstration
      description: 'Manchette japonaise traditionnelle avec carpe koï et fleurs de cerisier',
      date: DateTime.now().subtract(const Duration(days: 7)),
      hashtags: ['#japonais', '#manchette', '#koï', '#traditionnel'],
      likes: 24,
      isFromClient: false,
      artistName: 'InkMaster',
      artistId: 'artist001',
    ),
    RealisationItem(
      id: '2',
      imageUrl: 'assets/pro/shop_profil_gen.jpg', // Utilisation d'un asset pour démonstration
      description: 'Micro-réalisme floral en noir et gris',
      date: DateTime.now().subtract(const Duration(days: 15)),
      hashtags: ['#microréalisme', '#floral', '#noir&gris'],
      likes: 36,
      isFromClient: true,
      artistName: 'TattooMaster',
      artistId: 'artist002',
    ),
  ];

  // Liste de tous les hashtags disponibles pour le filtrage
  final List<String> _allHashtags = [
    '#japonais', '#manchette', '#koï', '#traditionnel', 
    '#microréalisme', '#floral', '#noir&gris',
    '#old-school', '#minimaliste', '#blackwork', '#dotwork'
  ];

  // Filtres actifs
  List<String> _activeFilters = [];
  
  // Mode d'affichage (grille ou liste)
  bool _gridMode = true;

  // Contrôleur pour l'ajout de description/hashtags
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sélectionner un fond aléatoire
    _backgroundImage = _getRandomBackground();
  }

  String _getRandomBackground() {
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    return backgrounds[Random().nextInt(backgrounds.length)];
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  // Méthode pour ajouter une nouvelle réalisation
  Future<void> _addRealisation() async {
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    
    final XFile? picked = await openFile(acceptedTypeGroups: [typeGroup]);
    if (picked != null) {
      // Ouvrir une boîte de dialogue pour ajouter des détails
      _showAddDetailsDialog(File(picked.path));
      
      // TODO: Uploader sur Firebase Storage + ajouter l'URL à Firestore
    }
  }

  // Dialogue pour ajouter des détails
  Future<void> _showAddDetailsDialog(File imageFile) async {
    _descriptionController.clear();
    _hashtagsController.clear();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Détails de la réalisation',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PermanentMarker',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Ex: Tatouage réaliste d\'un lion...',
                  hintStyle: TextStyle(color: Colors.white30),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: KipikTheme.rouge),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hashtagsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Hashtags (séparés par des espaces)',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Ex: #réaliste #lion #animal',
                  hintStyle: TextStyle(color: Colors.white30),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: KipikTheme.rouge),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber[300]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Les hashtags aident les clients à trouver vos réalisations',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[300],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text(
                  'Réalisation sur un client',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Visible dans le portfolio du client',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: false,
                activeColor: KipikTheme.rouge,
                checkColor: Colors.white,
                onChanged: (value) {
                  // Gérer la logique
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // Ajouter la nouvelle réalisation à la liste
              setState(() {
                List<String> hashtags = _hashtagsController.text
                    .split(' ')
                    .where((tag) => tag.isNotEmpty)
                    .map((tag) => tag.startsWith('#') ? tag : '#$tag')
                    .toList();
                
                _realisations.add(
                  RealisationItem(
                    id: DateTime.now().toString(),
                    imageFile: imageFile,
                    description: _descriptionController.text,
                    date: DateTime.now(),
                    hashtags: hashtags,
                    likes: 0,
                    isFromClient: false,
                    artistName: 'Mon Tatoueur', // À personnaliser
                    artistId: 'currentArtist',
                  ),
                );

                // Ajouter les nouveaux hashtags à la liste globale
                for (var tag in hashtags) {
                  if (!_allHashtags.contains(tag)) {
                    _allHashtags.add(tag);
                  }
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
            ),
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }

  // Ouvrir la vue détaillée d'une réalisation
  void _openRealisationDetail(RealisationItem realisation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RealisationDetailPage(realisation: realisation),
      ),
    );
  }

  // Afficher les filtres de hashtags
  void _showHashtagsFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrer par style',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sélectionnez les hashtags pour filtrer vos réalisations',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allHashtags.map((tag) {
                          final isSelected = _activeFilters.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (selected) {
                              setStateModal(() {
                                if (selected) {
                                  _activeFilters.add(tag);
                                } else {
                                  _activeFilters.remove(tag);
                                }
                              });
                              
                              // Également mettre à jour l'état de la page principale
                              setState(() {});
                            },
                            selectedColor: KipikTheme.rouge,
                            checkmarkColor: Colors.white,
                            backgroundColor: Colors.black45, // Fond sombre pour meilleur contraste
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white, // Texte toujours blanc pour meilleure lisibilité
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Gras quand sélectionné
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? KipikTheme.rouge : Colors.white30, // Bordure visible
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setStateModal(() {
                            _activeFilters.clear();
                          });
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Effacer tous les filtres'),
                        style: TextButton.styleFrom(foregroundColor: Colors.white70),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KipikTheme.rouge,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Appliquer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Filtrer les réalisations en fonction des hashtags sélectionnés
  List<RealisationItem> get _filteredRealisations {
    if (_activeFilters.isEmpty) {
      return _realisations;
    }
    
    return _realisations.where((item) {
      for (var filter in _activeFilters) {
        if (item.hashtags.contains(filter)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Mes Réalisations',
        showBackButton: true,
        showBurger: true,
        showNotificationIcon: true,
      ),
      endDrawer: const CustomDrawerParticulier(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond aléatoire
          Image.asset(_backgroundImage, fit: BoxFit.cover),
          
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // Barre d'outils de filtrage et d'affichage
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    border: const Border(
                      bottom: BorderSide(color: Colors.white10, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Bouton filtrage
                      Expanded(
                        child: GestureDetector(
                          onTap: _showHashtagsFilter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.filter_list, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Filtrer par style',
                                  style: TextStyle(color: Colors.white),
                                ),
                                if (_activeFilters.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: KipikTheme.rouge,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_activeFilters.length}',
                                      style: const TextStyle(
                                        color: Colors.white, 
                                        fontSize: 12, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Bouton de mode d'affichage
                      IconButton(
                        icon: Icon(
                          _gridMode ? Icons.view_list : Icons.grid_view,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() => _gridMode = !_gridMode),
                        tooltip: _gridMode ? 'Vue liste' : 'Vue grille',
                      ),
                      
                      // Bouton d'ajout
                      IconButton(
                        icon: const Icon(Icons.add_a_photo, color: Colors.white),
                        onPressed: _addRealisation,
                        tooltip: 'Ajouter une réalisation',
                      ),
                    ],
                  ),
                ),
                
                // Contenu scrollable (liste ou grille)
                Expanded(
                  child: _filteredRealisations.isEmpty
                      ? _buildEmptyState()
                      : _gridMode 
                          ? _buildGridView() 
                          : _buildListView(),
                ),
              ],
            ),
          ),
        ],
      ),
      // Bouton d'ajout de réalisation et bouton assistant Kipik
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton d'ajout de réalisation
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _addRealisation,
            backgroundColor: KipikTheme.rouge,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 16),
          // Bouton pour l'assistant Kipik - Modifié pour désactiver la génération d'images
          const TattooAssistantButton(
            allowImageGeneration: false,
          ),
        ],
      ),
    );
  }

  // État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_album_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _activeFilters.isEmpty
                ? 'Aucune réalisation pour l\'instant'
                : 'Aucune réalisation ne correspond aux filtres sélectionnés',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addRealisation,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Ajouter une réalisation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vue en grille
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75, // Format portrait pour mettre en valeur les tattoos
      ),
      itemCount: _filteredRealisations.length,
      itemBuilder: (context, index) {
        final item = _filteredRealisations[index];
        return GestureDetector(
          onTap: () => _openRealisationDetail(item),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.imageFile != null 
                  ? Image.file(item.imageFile!, fit: BoxFit.cover)
                  : Image.asset(item.imageUrl!, fit: BoxFit.cover),
              ),
              
              // Dégradé noir en bas pour la lisibilité du texte
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Badges
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    if (item.isFromClient)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Mon Tattoo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Description et hashtags
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Texte tronqué pour la vue grille
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Likes
                        Row(
                          children: [
                            Icon(Icons.favorite, color: KipikTheme.rouge, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${item.likes}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        // Artiste
                        Text(
                          'Par ${item.artistName}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
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
      },
    );
  }

  // Vue en liste
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredRealisations.length,
      itemBuilder: (context, index) {
        final item = _filteredRealisations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.black.withOpacity(0.6),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _openRealisationDetail(item),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image principale
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: item.imageFile != null 
                      ? Image.file(item.imageFile!, fit: BoxFit.cover)
                      : Image.asset(item.imageUrl!, fit: BoxFit.cover),
                  ),
                ),
                
                // Infos
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne artiste et badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Artiste
                          Text(
                            'Par ${item.artistName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          // Badges
                          if (item.isFromClient)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Mon Tatouage',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        item.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Hashtags
                      Wrap(
                        spacing: 4,
                        children: item.hashtags.map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: KipikTheme.rouge.withOpacity(0.7),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Likes et date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.favorite, color: KipikTheme.rouge, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${item.likes}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatDate(item.date),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
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
      },
    );
  }

  // Formater la date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return "Aujourd'hui";
    } else if (difference.inDays < 2) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Classe pour représenter une réalisation
class RealisationItem {
  final String id;
  final String? imageUrl; // URL Firebase Storage
  final File? imageFile; // Fichier local (avant upload)
  final String description;
  final DateTime date;
  final List<String> hashtags;
  int likes;
  final bool isFromClient;
  final String artistName; // Nom du tatoueur
  final String artistId; // ID du tatoueur dans la base de données

  RealisationItem({
    required this.id,
    this.imageUrl,
    this.imageFile,
    required this.description,
    required this.date,
    required this.hashtags,
    required this.likes,
    required this.isFromClient,
    required this.artistName,
    required this.artistId,
  }) : assert(imageUrl != null || imageFile != null);
}

// Page de détail d'une réalisation
class RealisationDetailPage extends StatefulWidget {
  final RealisationItem realisation;

  const RealisationDetailPage({super.key, required this.realisation});

  @override
  State<RealisationDetailPage> createState() => _RealisationDetailPageState();
}

class _RealisationDetailPageState extends State<RealisationDetailPage> {
  bool _isLiked = false;
  bool _isSaved = false;

  void _contactArtist() {
    // Afficher une boîte de dialogue pour contacter l'artiste
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Contacter l\'artiste',
          style: TextStyle(color: Colors.white, fontFamily: 'PermanentMarker'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous allez contacter ${widget.realisation.artistName}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ce style vous plaît? Demandez un devis pour votre propre tatouage!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigation vers la page de demande de devis
              Navigator.pop(context);
              // TODO: Naviguer vers la page de demande de devis
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redirection vers la demande de devis...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
            ),
            child: const Text('Contacter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Détail de la réalisation',
          style: TextStyle(fontFamily: 'PermanentMarker'),
        ),
        centerTitle: true,
        actions: [
          // Bouton partager
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Logique de partage
            },
            tooltip: 'Partager',
          ),
          // Bouton sauvegarder
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              setState(() {
                _isSaved = !_isSaved;
              });
            },
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image principale plein écran
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.infinity,
              child: widget.realisation.imageFile != null
                ? Image.file(
                    widget.realisation.imageFile!,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    widget.realisation.imageUrl!,
                    fit: BoxFit.contain,
                  ),
            ),
            
            // Informations
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artiste et Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Artiste avec bouton de profil
                      GestureDetector(
                        onTap: () {
                          // Navigation vers le profil de l'artiste
                        },
                        child: Text(
                          'Par ${widget.realisation.artistName}',
                          style: TextStyle(
                            color: KipikTheme.rouge,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Date
                      Text(
                        _formatDate(widget.realisation.date),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    widget.realisation.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Hashtags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.realisation.hashtags.map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: KipikTheme.rouge,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Badges
                  if (widget.realisation.isFromClient)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Mon Tatouage',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  // Likes et actions
                  Row(
                    children: [
                      // Like button
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: KipikTheme.rouge,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isLiked) {
                              widget.realisation.likes--;
                            } else {
                              widget.realisation.likes++;
                            }
                            _isLiked = !_isLiked;
                          });
                        },
                      ),
                      Text(
                        '${widget.realisation.likes}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      // Bouton Contacter l'artiste
                      ElevatedButton.icon(
                        onPressed: _contactArtist,
                        icon: const Icon(Icons.person),
                        label: const Text('Contacter l\'artiste'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KipikTheme.rouge,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Suggestion de designs similaires
                  const Text(
                    'Designs similaires',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'PermanentMarker',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5, // Exemple: 5 designs similaires
                      itemBuilder: (context, index) {
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white10,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bouton Assistant Kipik
      floatingActionButton: const TattooAssistantButton(
        allowImageGeneration: false,
      ),
    );
  }

  // Formater la date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return "Aujourd'hui";
    } else if (difference.inDays < 2) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}