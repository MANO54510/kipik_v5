// lib/pages/particulier/favoris_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../theme/kipik_theme.dart';
import '../../core/database_manager.dart'; // ✅ AJOUTÉ
import '../../services/auth/secure_auth_service.dart'; // ✅ AJOUTÉ
import '../../services/inspiration/firebase_inspiration_service.dart'; // ✅ AJOUTÉ
import '../../services/tattooist/firebase_tattooist_service.dart'; // ✅ AJOUTÉ
import '../../models/tatoueur_summary.dart'; // ✅ AJOUTÉ
import '../pro/profil_tatoueur.dart'; // ✅ Pour navigation vers profils
import '../../models/user_role.dart'; // ✅ Pour mode client

class FavorisPage extends StatefulWidget {
  const FavorisPage({Key? key}) : super(key: key);

  @override
  State<FavorisPage> createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // ✅ SERVICES MODERNES
  final FirebaseInspirationService _inspirationService = FirebaseInspirationService.instance;
  final FirebaseTattooistService _tattooistService = FirebaseTattooistService.instance;

  // ✅ DONNÉES TYPÉES
  List<Map<String, dynamic>> _favoriteInspirations = [];
  List<TatoueurSummary> _favoriteTattooists = [];
  bool _isLoadingInspirations = false;
  bool _isLoadingTattooists = false;
  String? _errorMessage;

  final List<String> _backgroundImages = [
    'assets/background_charbon.png',
    'assets/background_tatoo2.png',
    'assets/background1.png',
    'assets/background2.png',
  ];

  late String _selectedBackground;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedBackground = _backgroundImages[Random().nextInt(_backgroundImages.length)];
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ✅ CHARGER TOUS LES FAVORIS
  Future<void> _loadFavorites() async {
    await Future.wait([
      _loadFavoriteInspirations(),
      _loadFavoriteTattooists(),
    ]);
  }

  /// ✅ CHARGER INSPIRATIONS FAVORITES
  Future<void> _loadFavoriteInspirations() async {
    setState(() {
      _isLoadingInspirations = true;
      _errorMessage = null;
    });

    try {
      if (DatabaseManager.instance.isDemoMode) {
        // ✅ MODE DÉMO - Données factices
        await Future.delayed(const Duration(milliseconds: 800));
        _favoriteInspirations = _generateDemoInspirations();
        print('🎭 ${_favoriteInspirations.length} inspirations démo chargées');
      } else {
        // ✅ MODE PRODUCTION - Firebase réel
        final currentUser = SecureAuthService.instance.currentUser;
        if (currentUser != null) {
          _favoriteInspirations = await _inspirationService.getFavoriteInspirations(
            userId: currentUser.uid,
          );
          print('🏭 ${_favoriteInspirations.length} inspirations favorites chargées');
        } else {
          _favoriteInspirations = [];
        }
      }
    } catch (e) {
      print('❌ Erreur chargement inspirations: $e');
      setState(() => _errorMessage = 'Erreur chargement inspirations: $e');
      
      // Fallback en cas d'erreur
      if (DatabaseManager.instance.isDemoMode) {
        _favoriteInspirations = _generateDemoInspirations();
      }
    } finally {
      setState(() => _isLoadingInspirations = false);
    }
  }

  /// ✅ CHARGER TATOUEURS FAVORIS
  Future<void> _loadFavoriteTattooists() async {
    setState(() {
      _isLoadingTattooists = true;
      _errorMessage = null;
    });

    try {
      if (DatabaseManager.instance.isDemoMode) {
        // ✅ MODE DÉMO - Données factices
        await Future.delayed(const Duration(milliseconds: 600));
        _favoriteTattooists = _generateDemoTattooists();
        print('🎭 ${_favoriteTattooists.length} tatoueurs démo chargés');
      } else {
        // ✅ MODE PRODUCTION - Firebase réel
        final currentUser = SecureAuthService.instance.currentUser;
        if (currentUser != null) {
          final rawTattooists = await _tattooistService.getFavoriteTattooists(
            userId: currentUser.uid,
          );
          
          // Convertir en TatoueurSummary
          _favoriteTattooists = rawTattooists.map((data) => 
            TatoueurSummary.fromFirestore(data, data['id'])
          ).toList();
          
          print('🏭 ${_favoriteTattooists.length} tatoueurs favoris chargés');
        } else {
          _favoriteTattooists = [];
        }
      }
    } catch (e) {
      print('❌ Erreur chargement tatoueurs: $e');
      setState(() => _errorMessage = 'Erreur chargement tatoueurs: $e');
      
      // Fallback en cas d'erreur
      if (DatabaseManager.instance.isDemoMode) {
        _favoriteTattooists = _generateDemoTattooists();
      }
    } finally {
      setState(() => _isLoadingTattooists = false);
    }
  }

  /// ✅ GÉNÉRER INSPIRATIONS DÉMO
  List<Map<String, dynamic>> _generateDemoInspirations() {
    final styles = ['Réalisme', 'Japonais', 'Géométrique', 'Minimaliste', 'Traditionnel', 'Aquarelle'];
    final authors = ['Alex Ink', 'Maya Art', 'Vincent Style', 'Sarah Design', 'Lucas Black', 'Emma Vision'];
    
    return List.generate(8, (i) {
      final style = styles[Random().nextInt(styles.length)];
      final author = authors[Random().nextInt(authors.length)];
      
      return {
        'id': 'demo_inspiration_$i',
        'title': 'Inspiration $style ${i + 1}',
        'imageUrl': 'https://picsum.photos/seed/inspiration$i/${300 + (i * 50)}/${400 + (i * 30)}',
        'style': style,
        'category': 'Tatouage',
        'description': '[DÉMO] Une magnifique œuvre de style $style créée par notre artiste $author.',
        'authorName': author,
        'authorAvatarUrl': 'https://picsum.photos/seed/author$i/100/100',
        'isFromProfessional': Random().nextBool(),
        'isFavorite': true,
        'likes': Random().nextInt(150) + 20,
        'views': Random().nextInt(500) + 100,
        'tags': [style, 'Inspirant', 'Créatif'],
        'createdAt': DateTime.now().subtract(Duration(days: Random().nextInt(30))).toIso8601String(),
        '_source': 'demo',
      };
    });
  }

  /// ✅ GÉNÉRER TATOUEURS DÉMO
  List<TatoueurSummary> _generateDemoTattooists() {
    // Utiliser les données de démonstration du modèle TatoueurSummary
    final demoTattooists = TatoueurSummaryDemo.generateDemoList(count: 6);
    
    // Marquer tous comme favoris en mode démo
    return demoTattooists.map((tatoueur) => tatoueur.copyWith()).toList();
  }

  /// ✅ TOGGLE FAVORI INSPIRATION
  Future<void> _toggleInspirationFavorite(Map<String, dynamic> inspiration) async {
    try {
      if (DatabaseManager.instance.isDemoMode) {
        // ✅ MODE DÉMO - Simulation
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _favoriteInspirations.removeWhere((p) => p['id'] == inspiration['id']);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎭 Favori retiré (mode démo)'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // ✅ MODE PRODUCTION - Firebase réel
        final currentUser = SecureAuthService.instance.currentUser;
        if (currentUser != null) {
          await _inspirationService.toggleFavorite(
            inspirationId: inspiration['id'],
            userId: currentUser.uid,
          );
          
          // Recharger la liste
          await _loadFavoriteInspirations();
        }
      }
    } catch (e) {
      print('❌ Erreur toggle favori inspiration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ TOGGLE FAVORI TATOUEUR
  Future<void> _toggleTattooistFavorite(TatoueurSummary tatoueur) async {
    try {
      if (DatabaseManager.instance.isDemoMode) {
        // ✅ MODE DÉMO - Simulation
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _favoriteTattooists.removeWhere((t) => t.id == tatoueur.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎭 Tatoueur retiré des favoris (mode démo)'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // ✅ MODE PRODUCTION - Firebase réel
        final currentUser = SecureAuthService.instance.currentUser;
        if (currentUser != null) {
          await _tattooistService.toggleFavorite(
            tattooistId: tatoueur.id,
            userId: currentUser.uid,
          );
          
          // Recharger la liste
          await _loadFavoriteTattooists();
        }
      }
    } catch (e) {
      print('❌ Erreur toggle favori tatoueur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: isDemoMode ? 'Mes favoris 🎭' : 'Mes favoris',
        showBackButton: true,
        redirectToHome: true,
        showNotificationIcon: true,
      ),
      body: Stack(
        children: [
          // Fond aléatoire
          Image.asset(
            _selectedBackground,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // ✅ Indicateur mode démo
          if (isDemoMode) ...[
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🎭 Mode ${DatabaseManager.instance.activeDatabaseConfig.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

          Column(
            children: [
              Container(
                color: Colors.black.withOpacity(0.7),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: isDemoMode ? Colors.orange : KipikTheme.rouge,
                  labelColor: isDemoMode ? Colors.orange : KipikTheme.rouge,
                  unselectedLabelColor: Colors.white,
                  tabs: const [
                    Tab(icon: Icon(Icons.image), text: 'Inspirations'),
                    Tab(icon: Icon(Icons.person), text: 'Tatoueurs'),
                  ],
                ),
              ),
              
              // ✅ Message d'erreur si nécessaire
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withOpacity(0.1),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInspirationsTab(),
                    _buildTattooersTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationsTab() {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    
    if (_isLoadingInspirations) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: isDemoMode ? Colors.orange : KipikTheme.rouge,
            ),
            const SizedBox(height: 16),
            Text(
              isDemoMode 
                  ? 'Chargement des inspirations démo...'
                  : 'Chargement de vos inspirations...',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    
    if (_favoriteInspirations.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border, 
                size: 64, 
                color: (isDemoMode ? Colors.orange : KipikTheme.rouge).withOpacity(0.5)
              ),
              const SizedBox(height: 16),
              Text(
                isDemoMode 
                    ? 'Pas d\'inspirations en mode démo'
                    : 'Pas encore d\'inspirations favorites',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 20,
                  color: KipikTheme.noir,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isDemoMode
                    ? 'Explorez les inspirations pour voir le contenu démo'
                    : 'Explorez les inspirations et ajoutez-les à vos favoris',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/inspirations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDemoMode ? Colors.orange : KipikTheme.rouge,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Explorer les inspirations'),
              ),
            ],
          ),
        ),
      );
    }

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(8),
      itemCount: _favoriteInspirations.length,
      itemBuilder: (_, i) => _buildInspirationCard(_favoriteInspirations[i]),
    );
  }

  Widget _buildTattooersTab() {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    
    if (_isLoadingTattooists) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: isDemoMode ? Colors.orange : KipikTheme.rouge,
            ),
            const SizedBox(height: 16),
            Text(
              isDemoMode 
                  ? 'Chargement des tatoueurs démo...'
                  : 'Chargement de vos tatoueurs favoris...',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    
    if (_favoriteTattooists.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border, 
                size: 64, 
                color: (isDemoMode ? Colors.orange : KipikTheme.rouge).withOpacity(0.5)
              ),
              const SizedBox(height: 16),
              Text(
                isDemoMode
                    ? 'Pas de tatoueurs en mode démo'
                    : 'Pas encore de tatoueurs favoris',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 20,
                  color: KipikTheme.noir,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isDemoMode
                    ? 'Explorez les tatoueurs pour voir le contenu démo'
                    : 'Explorez les tatoueurs et ajoutez-les à vos favoris',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/recherche_tatoueur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDemoMode ? Colors.orange : KipikTheme.rouge,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Découvrir des tatoueurs'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteTattooists.length,
      itemBuilder: (_, i) => _buildTattooistCard(_favoriteTattooists[i]),
    );
  }

  /// ✅ CARTE INSPIRATION MODERNE
  Widget _buildInspirationCard(Map<String, dynamic> inspiration) {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    final cardHeight = 150 + (inspiration['id'].hashCode % 100).toDouble();
    
    return GestureDetector(
      onTap: () {
        // TODO: Navigation vers détail inspiration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDemoMode 
                  ? '🎭 Détail inspiration "${inspiration['title']}" (démo)'
                  : 'Détail inspiration "${inspiration['title']}"'
            ),
            backgroundColor: isDemoMode ? Colors.orange : KipikTheme.rouge,
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: (isDemoMode ? Colors.orange : KipikTheme.rouge).withOpacity(0.3), 
            width: 1
          ),
        ),
        elevation: 4,
        child: Stack(
          children: [
            SizedBox(
              height: cardHeight,
              width: double.infinity,
              child: Hero(
                tag: 'inspiration_${inspiration['id']}',
                child: Image.network(
                  inspiration['imageUrl'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, size: 50),
                    );
                  },
                ),
              ),
            ),
            
            // Informations auteur
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16, 
                      backgroundImage: NetworkImage(inspiration['authorAvatarUrl']),
                      onBackgroundImageError: (error, stackTrace) {},
                      child: inspiration['authorAvatarUrl'] == null 
                          ? const Icon(Icons.person, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            inspiration['authorName'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'PermanentMarker',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            inspiration['style'] ?? 'Style',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bouton favori
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _toggleInspirationFavorite(inspiration),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite, 
                    color: isDemoMode ? Colors.orange : KipikTheme.rouge, 
                    size: 20
                  ),
                ),
              ),
            ),
            
            // Badge PRO ou DÉMO
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDemoMode ? Colors.orange : KipikTheme.rouge,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isDemoMode 
                      ? 'DÉMO'
                      : (inspiration['isFromProfessional'] == true ? 'PRO' : 'USER'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ CARTE TATOUEUR MODERNE
  Widget _buildTattooistCard(TatoueurSummary tatoueur) {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDemoMode ? Colors.orange : KipikTheme.rouge, 
          width: 1.5
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilTatoueur(
              tatoueurId: tatoueur.id,
              forceMode: UserRole.client,
              name: tatoueur.name,
              studio: tatoueur.studioName ?? 'Studio indépendant',
              style: tatoueur.specialtiesText,
              location: tatoueur.location,
              availability: tatoueur.availability,
              note: tatoueur.rating ?? 4.5,
              instagram: tatoueur.instagram ?? '@tatoueur',
              distance: tatoueur.distanceText,
              address: 'Adresse du studio',
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de couverture simulée
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[800]!,
                          Colors.grey[600]!,
                        ],
                      ),
                    ),
                    child: tatoueur.avatarUrl.isNotEmpty
                        ? Image.network(
                            tatoueur.avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 50),
                              );
                            },
                          )
                        : const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        Icons.favorite, 
                        color: isDemoMode ? Colors.orange : KipikTheme.rouge, 
                        size: 28
                      ),
                      onPressed: () => _toggleTattooistFavorite(tatoueur),
                    ),
                  ),
                  if (isDemoMode) ...[
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DÉMO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Infos tatoueur
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: tatoueur.avatarUrl.isNotEmpty 
                        ? NetworkImage(tatoueur.avatarUrl)
                        : null,
                    child: tatoueur.avatarUrl.isEmpty 
                        ? Text(
                            tatoueur.name.isNotEmpty ? tatoueur.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tatoueur.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  fontFamily: 'PermanentMarker',
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  tatoueur.ratingText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tatoueur.location,
                                style: TextStyle(color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.style, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tatoueur.specialtiesText,
                                style: TextStyle(color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              tatoueur.availability,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
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