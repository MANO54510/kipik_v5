// lib/pages/particulier/detail_tattooist_page.dart

import 'package:flutter/material.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../models/tatoueur_summary.dart';
import '../../services/tattooist/firebase_tattooist_service.dart';
import '../../services/inspiration/firebase_inspiration_service.dart';
import '../../services/auth/secure_auth_service.dart';
import '../../core/database_manager.dart';
import '../../theme/kipik_theme.dart';
import '../shared/inspirations/detail_inspiration_page.dart';

class DetailTattooistPage extends StatefulWidget {
  final TatoueurSummary tatoueur;
  final String? tattooistId;
  
  const DetailTattooistPage({
    Key? key,
    required this.tatoueur,
    this.tattooistId,
  }) : super(key: key);

  @override
  State<DetailTattooistPage> createState() => _DetailTattooistPageState();
}

class _DetailTattooistPageState extends State<DetailTattooistPage> {
  late TatoueurSummary _tatoueur;
  final FirebaseTattooistService _tattooistService = FirebaseTattooistService.instance;
  final FirebaseInspirationService _inspirationService = FirebaseInspirationService.instance;
  
  List<Map<String, dynamic>> _tattooistPosts = [];
  Map<String, dynamic>? _detailedProfile;
  bool _isLoadingPosts = false;
  bool _isLoadingProfile = false;
  bool _isFavorite = false;
  
  @override
  void initState() {
    super.initState();
    _tatoueur = widget.tatoueur;
    _loadTattooistData();
  }
  
  Future<void> _loadTattooistData() async {
    await Future.wait([
      _loadDetailedProfile(),
      _loadTattooistPosts(),
      _checkFavoriteStatus(),
    ]);
  }
  
  Future<void> _loadDetailedProfile() async {
    setState(() => _isLoadingProfile = true);
    
    try {
      final profileData = await _tattooistService.getTattooistProfile(
        widget.tattooistId ?? _tatoueur.id
      );
      
      setState(() {
        _detailedProfile = profileData;
        _isLoadingProfile = false;
      });
    } catch (e) {
      print('❌ Erreur chargement profil détaillé: $e');
      setState(() => _isLoadingProfile = false);
    }
  }
  
  Future<void> _loadTattooistPosts() async {
    setState(() => _isLoadingPosts = true);
    
    try {
      if (DatabaseManager.instance.isDemoMode) {
        // Mode démo - Générer des posts factices
        await Future.delayed(const Duration(milliseconds: 800));
        _tattooistPosts = _generateDemoPosts();
      } else {
        // Mode production - Récupérer les vraies inspirations du tatoueur
        final posts = await _inspirationService.getInspirations(
          authorId: widget.tattooistId ?? _tatoueur.id,
          limit: 12,
        );
        _tattooistPosts = posts;
      }
      
      setState(() => _isLoadingPosts = false);
    } catch (e) {
      print('❌ Erreur chargement posts: $e');
      setState(() => _isLoadingPosts = false);
      
      // Fallback vers des données démo en cas d'erreur
      _tattooistPosts = _generateDemoPosts();
    }
  }
  
  Future<void> _checkFavoriteStatus() async {
    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      final isFav = await _tattooistService.isFavorite(
        tattooistId: widget.tattooistId ?? _tatoueur.id,
        userId: currentUser.uid,
      );
      
      setState(() => _isFavorite = isFav);
    } catch (e) {
      print('❌ Erreur vérification favori: $e');
    }
  }
  
  Future<void> _toggleFavorite() async {
    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser == null) {
      _showLoginRequired();
      return;
    }
    
    try {
      final newFavoriteStatus = await _tattooistService.toggleFavorite(
        tattooistId: widget.tattooistId ?? _tatoueur.id,
        userId: currentUser.uid,
      );
      
      setState(() => _isFavorite = newFavoriteStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFavoriteStatus 
                ? 'Ajouté aux tatoueurs favoris' 
                : 'Retiré des tatoueurs favoris'
            ),
            backgroundColor: newFavoriteStatus ? Colors.green : Colors.grey[700],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur toggle favori: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connectez-vous pour ajouter des favoris'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  List<Map<String, dynamic>> _generateDemoPosts() {
    final styles = _tatoueur.specialties.isNotEmpty 
        ? _tatoueur.specialties 
        : ['Réalisme', 'Traditionnel'];
    
    return List.generate(6, (index) {
      final style = styles[index % styles.length];
      return {
        'id': 'demo_post_${_tatoueur.id}_$index',
        'title': '$style par ${_tatoueur.name}',
        'imageUrl': 'https://picsum.photos/seed/${_tatoueur.id}_$index/400/600',
        'description': '[DÉMO] Réalisation $style par ${_tatoueur.name}. Œuvre unique et personnalisée.',
        'style': style,
        'category': 'Tatouage',
        'authorName': _tatoueur.name,
        'authorId': _tatoueur.id,
        'likes': (index + 1) * 12 + 8,
        'views': (index + 1) * 45 + 23,
        'createdAt': DateTime.now().subtract(Duration(days: index * 7 + 2)).toIso8601String(),
        '_source': 'demo',
      };
    });
  }
  
  // Getters pour données combinées
  String get _displayName => _detailedProfile?['name'] ?? _tatoueur.name;
  String get _displayLocation => _detailedProfile?['location'] ?? _tatoueur.location;
  double get _displayRating => (_detailedProfile?['rating'] as num?)?.toDouble() ?? _tatoueur.rating ?? 4.5;
  int get _displayReviewsCount => _detailedProfile?['reviewCount'] as int? ?? _tatoueur.reviewsCount ?? 0;
  String get _displayBio => _detailedProfile?['bio'] ?? 'Tatoueur professionnel passionné par l\'art du tatouage.';
  List<String> get _displayStyles => (_detailedProfile?['specialties'] as List<dynamic>?)?.cast<String>() ?? _tatoueur.specialties;
  String get _profileImageUrl => _detailedProfile?['profileImage'] ?? _tatoueur.avatarUrl;
  String get _coverImageUrl => _detailedProfile?['coverImage'] ?? 'https://picsum.photos/seed/${_tatoueur.id}_cover/800/400';
  
  @override
  Widget build(BuildContext context) {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ✅ AppBar avec image de couverture et indicateur mode
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de couverture
                  Image.network(
                    _coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: KipikTheme.rouge.withOpacity(0.8),
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  // Dégradé pour meilleure lisibilité
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // ✅ Badge mode démo
                  if (isDemoMode)
                    Positioned(
                      top: 60,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🎭 ${DatabaseManager.instance.activeDatabaseConfig.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                _displayName,
                style: const TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 22,
                ),
              ),
              centerTitle: true,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite 
                      ? (isDemoMode ? Colors.orange : KipikTheme.rouge)
                      : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Implémenter le partage
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
                  );
                },
              ),
            ],
          ),
          
          // ✅ Contenu principal
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profil du tatoueur
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar et infos principales
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'avatar_${_tatoueur.id}',
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(_profileImageUrl),
                              child: _isLoadingProfile 
                                  ? const CircularProgressIndicator(strokeWidth: 2)
                                  : null,
                            ),
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
                                        _displayName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isDemoMode)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
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
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on, 
                                      size: 16, 
                                      color: isDemoMode ? Colors.orange : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _displayLocation,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star, 
                                      size: 16, 
                                      color: isDemoMode ? Colors.orange : Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_displayRating.toStringAsFixed(1)} ($_displayReviewsCount avis)',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                if (_tatoueur.distanceText.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.near_me, 
                                        size: 16, 
                                        color: isDemoMode ? Colors.orange : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _tatoueur.distanceText,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description/Bio
                      Text(
                        _displayBio,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Styles de tatouage
                      const Text(
                        'Spécialités',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _displayStyles.map((style) {
                          return Chip(
                            label: Text(style),
                            backgroundColor: isDemoMode 
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.grey[200],
                            side: BorderSide(
                              color: isDemoMode ? Colors.orange : Colors.grey,
                              width: 0.5,
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Boutons d'action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.message,
                            label: 'Message',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Messagerie à implémenter')),
                              );
                            },
                            isDemoMode: isDemoMode,
                          ),
                          _buildActionButton(
                            icon: Icons.calendar_today,
                            label: 'Réserver',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Réservation à implémenter')),
                              );
                            },
                            isPrimary: true,
                            isDemoMode: isDemoMode,
                          ),
                          _buildActionButton(
                            icon: Icons.info_outline,
                            label: 'Infos',
                            onTap: () {
                              _showStudioInfo();
                            },
                            isDemoMode: isDemoMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Séparateur
                Container(
                  height: 8,
                  color: Colors.grey[200],
                ),
                
                // ✅ Réalisations du tatoueur
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Réalisations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isDemoMode) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
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
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (_isLoadingPosts)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              color: isDemoMode ? Colors.orange : KipikTheme.rouge,
                            ),
                          ),
                        )
                      else if (_tattooistPosts.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isDemoMode 
                                      ? 'Aucune réalisation en démo'
                                      : 'Aucune réalisation pour le moment',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: _tattooistPosts.length,
                          itemBuilder: (context, index) {
                            final post = _tattooistPosts[index];
                            return _buildRealisationItem(post, isDemoMode);
                          },
                        ),
                      
                      if (_tattooistPosts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Center(
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Galerie complète à implémenter')),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: isDemoMode ? Colors.orange : KipikTheme.rouge,
                              ),
                              child: const Text('Voir toutes les réalisations'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Séparateur
                Container(
                  height: 8,
                  color: Colors.grey[200],
                ),
                
                // ✅ Section avis avec mode démo
                _buildReviewsSection(isDemoMode),
                
                // Espace en bas
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
      // ✅ Bouton flottant adapté au mode
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isDemoMode 
                  ? 'Contact simulé en mode démo' 
                  : 'Contacter le tatoueur'),
            ),
          );
        },
        backgroundColor: isDemoMode ? Colors.orange : KipikTheme.rouge,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDemoMode = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: isPrimary 
                ? (isDemoMode ? Colors.orange : KipikTheme.rouge)
                : Colors.grey[200],
            foregroundColor: isPrimary ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRealisationItem(Map<String, dynamic> post, bool isDemoMode) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDemoMode 
                ? 'Navigation démo vers: ${post['title']}'
                : 'Ouverture de ${post['title']}'),
          ),
        );
      },
      child: Hero(
        tag: 'inspiration_${post['id']}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: isDemoMode 
                ? Border.all(color: Colors.orange, width: 1)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  post['imageUrl'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
                if (isDemoMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'D',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildReviewsSection(bool isDemoMode) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Avis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDemoMode ? Colors.orange : Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _displayRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($_displayReviewsCount)',
                style: const TextStyle(color: Colors.grey),
              ),
              if (isDemoMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
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
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Avis factices pour la démo
          _buildReviewItem(
            name: 'Sophie L.',
            date: 'Il y a 2 semaines',
            rating: 5,
            text: isDemoMode 
                ? '[DÉMO] Super expérience ! Le tatoueur a parfaitement compris ma demande.'
                : 'Super expérience ! Le tatoueur a parfaitement compris ma demande et le résultat est magnifique.',
            avatarUrl: 'https://i.pravatar.cc/150?img=5',
            isDemoMode: isDemoMode,
          ),
          
          const Divider(),
          
          _buildReviewItem(
            name: 'Thomas B.',
            date: 'Il y a 1 mois',
            rating: 4,
            text: isDemoMode
                ? '[DÉMO] Très bon travail, je suis satisfait du résultat.'
                : 'Très bon travail, je suis satisfait du résultat. Le seul bémol est le temps d\'attente.',
            avatarUrl: 'https://i.pravatar.cc/150?img=12',
            isDemoMode: isDemoMode,
          ),
          
          const Divider(),
          
          _buildReviewItem(
            name: 'Marie D.',
            date: 'Il y a 3 mois',
            rating: 5,
            text: isDemoMode
                ? '[DÉMO] C\'était mon premier tatouage et j\'étais stressée, mais tout s\'est bien passé !'
                : 'C\'était mon premier tatouage et j\'étais un peu stressée, mais le tatoueur a su me mettre à l\'aise.',
            avatarUrl: 'https://i.pravatar.cc/150?img=9',
            isDemoMode: isDemoMode,
          ),
          
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isDemoMode 
                        ? 'Tous les avis (mode démo)' 
                        : 'Voir tous les avis'),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: isDemoMode ? Colors.orange : KipikTheme.rouge,
              ),
              child: const Text('Voir tous les avis'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewItem({
    required String name,
    required String date,
    required int rating,
    required String text,
    required String avatarUrl,
    bool isDemoMode = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: isDemoMode ? Colors.orange : Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  void _showStudioInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Informations du studio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_detailedProfile?['studioName'] != null) ...[
              Text('Studio: ${_detailedProfile!['studioName']}'),
              const SizedBox(height: 8),
            ],
            if (_detailedProfile?['address'] != null) ...[
              Text('Adresse: ${_detailedProfile!['address']}'),
              const SizedBox(height: 8),
            ],
            if (_detailedProfile?['phone'] != null) ...[
              Text('Téléphone: ${_detailedProfile!['phone']}'),
              const SizedBox(height: 8),
            ],
            Text('Disponibilité: ${_tatoueur.availability}'),
            if (DatabaseManager.instance.isDemoMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  '🎭 Ces informations sont simulées en mode démo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}