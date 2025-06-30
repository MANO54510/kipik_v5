// lib/pages/particulier/inspirations_page.dart

import 'package:flutter/material.dart';
import 'dart:math';  // Import pour Random
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../theme/kipik_theme.dart';
import '../../models/inspiration_post.dart';
import '../../services/inspiration/inspiration_service.dart';
import 'detail_inspiration_page.dart';

class InspirationsPage extends StatefulWidget {
  const InspirationsPage({Key? key}) : super(key: key);

  @override
  State<InspirationsPage> createState() => _InspirationsPageState();
}

class _InspirationsPageState extends State<InspirationsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<InspirationPost> _posts = [];
  final InspirationService _inspirationService = InspirationService();
  
  // Filtres
  final List<String> _categories = ['Tous', 'Clients', 'Professionnels', 'Dessins', 'Réalisations'];
  String _selectedCategory = 'Tous';
  
  // Liste des images de fond disponibles
  final List<String> _backgroundImages = [
    'assets/background_charbon.png',
    'assets/background_tatoo1.png',
    'assets/background_tatoo2.png',
    'assets/background_tatoo3.png',
    // Ajoutez d'autres chemins d'images selon vos besoins
  ];
  
  // Variable pour stocker l'image de fond sélectionnée aléatoirement
  late String _selectedBackground;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    
    // Ajouter la pagination infinie
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoading) {
        _loadMorePosts();
      }
    });
    
    // Sélection aléatoire de l'image de fond
    _selectedBackground = _backgroundImages[Random().nextInt(_backgroundImages.length)];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final posts = await _inspirationService.getPosts(category: _selectedCategory == 'Tous' ? null : _selectedCategory);
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Gérer l'erreur
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final morePosts = await _inspirationService.getMorePosts(
        lastPostId: _posts.isNotEmpty ? _posts.last.id : null,
        category: _selectedCategory == 'Tous' ? null : _selectedCategory
      );
      
      setState(() {
        _posts.addAll(morePosts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Gérer l'erreur
    }
  }

  Future<void> _toggleFavorite(InspirationPost post) async {
    try {
      final updatedPost = await _inspirationService.toggleFavorite(post.id);
      
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedPost.isFavorite 
            ? 'Ajouté aux favoris' 
            : 'Retiré des favoris'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );
    } catch (e) {
      // Gérer l'erreur
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Utilisation de CustomAppBarParticulier avec redirectToHome à true
      appBar: CustomAppBarParticulier(
        title: 'Inspirations',
        showBackButton: true,
        redirectToHome: true, // Ajout de cette ligne pour rediriger vers l'accueil
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
          
          // Contenu principal
          Column(
            children: [
              // Barre de filtres par catégorie
              Container(
                height: 60,
                color: Colors.black.withOpacity(0.7),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      child: ElevatedButton(
                        onPressed: () {
                          if (category != _selectedCategory) {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _loadPosts();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected 
                              ? KipikTheme.rouge  // Utiliser le rouge de Kipik
                              : Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          elevation: isSelected ? 4 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(category),
                      ),
                    );
                  },
                ),
              ),
              
              // Grille d'images
              Expanded(
                child: _posts.isEmpty && !_isLoading
                    ? Center(
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
                                Icons.image_search,
                                size: 64,
                                color: Colors.grey[800],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Aucune inspiration trouvée',
                                style: TextStyle(
                                  fontFamily: 'PermanentMarker',
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Essayez une autre catégorie ou revenez plus tard',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPosts,
                        color: KipikTheme.rouge,  // Utiliser le rouge de Kipik
                        child: MasonryGridView.count(
                          controller: _scrollController,
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          padding: const EdgeInsets.all(8),
                          itemCount: _posts.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _posts.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),  // Utiliser le rouge de Kipik
                                  ),
                                ),
                              );
                            }
                            
                            final post = _posts[index];
                            
                            return _buildInspirationCard(post);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
      // Bouton pour ajouter une nouvelle inspiration
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Naviguer vers la page d'ajout d'inspiration
        },
        backgroundColor: KipikTheme.rouge,  // Utiliser le rouge de Kipik
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInspirationCard(InspirationPost post) {
    final double cardHeight = 150 + (post.id.hashCode % 100); // Hauteur variable pour effet Pinterest
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (_) => DetailInspirationPage(post: post),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: KipikTheme.rouge.withOpacity(0.3), width: 1),  // Bordure rouge Kipik
        ),
        elevation: 4,
        child: Stack(
          children: [
            // Image
            SizedBox(
              height: cardHeight,
              width: double.infinity,
              child: Hero(
                tag: 'inspiration_${post.id}',
                child: Image.network(
                  post.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / 
                              loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(KipikTheme.rouge),  // Utiliser le rouge de Kipik
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Informations superposées
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
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(post.authorAvatarUrl),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'PermanentMarker',  // Utiliser la police Kipik
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                onTap: () => _toggleFavorite(post),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    post.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: post.isFavorite ? KipikTheme.rouge : Colors.white,  // Utiliser le rouge de Kipik
                    size: 20,
                  ),
                ),
              ),
            ),
            
            // Badge "Pro" si c'est un professionnel
            if (post.isFromProfessional)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: KipikTheme.rouge,  // Utiliser le rouge de Kipik
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
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
}