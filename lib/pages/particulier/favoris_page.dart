// lib/pages/particulier/favoris_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../theme/kipik_theme.dart';
import '../../models/inspiration_post.dart';
import '../../models/tattooist.dart';
import '../../services/inspiration/inspiration_service.dart';
import '../../services/tattooist/tattooist_service.dart';
import 'detail_inspiration_page.dart';
import 'detail_tattooist_page.dart';

class FavorisPage extends StatefulWidget {
  const FavorisPage({Key? key}) : super(key: key);

  @override
  State<FavorisPage> createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InspirationService _inspirationService = InspirationService();
  final TattooistService _tattooistService = TattooistService();

  List<InspirationPost> _favoriteInspirations = [];
  List<Tattooist> _favoriteTattooists = [];
  bool _isLoadingInspirations = false;
  bool _isLoadingTattooists = false;

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
    _tabController = TabController(length: 2, vsync: this);
    _loadFavoriteInspirations();
    _loadFavoriteTattooists();

    // Sélection aléatoire de l'image de fond
    _selectedBackground = _backgroundImages[Random().nextInt(_backgroundImages.length)];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteInspirations() async {
    setState(() => _isLoadingInspirations = true);
    try {
      final posts = await _inspirationService.getPosts();
      setState(() {
        _favoriteInspirations = posts.where((post) => post.isFavorite).toList();
      });
    } catch (_) {
      // gérer l'erreur si besoin
    } finally {
      setState(() => _isLoadingInspirations = false);
    }
  }

  Future<void> _loadFavoriteTattooists() async {
    setState(() => _isLoadingTattooists = true);
    try {
      final tattooists = await _tattooistService.getFavoriteTattooists();
      setState(() {
        _favoriteTattooists = tattooists;
      });
    } catch (_) {
      // gérer l'erreur si besoin
    } finally {
      setState(() => _isLoadingTattooists = false);
    }
  }

  Future<void> _toggleInspirationFavorite(InspirationPost post) async {
    final updatedPost = await _inspirationService.toggleFavorite(post.id);
    setState(() {
      if (!updatedPost.isFavorite) {
        _favoriteInspirations.removeWhere((p) => p.id == post.id);
      } else {
        final idx = _favoriteInspirations.indexWhere((p) => p.id == post.id);
        if (idx != -1) _favoriteInspirations[idx] = updatedPost;
      }
    });
  }

  Future<void> _toggleTattooistFavorite(Tattooist t) async {
    final updated = await _tattooistService.toggleFavorite(t.id);
    setState(() {
      if (!updated.isFavorite) {
        _favoriteTattooists.removeWhere((tt) => tt.id == t.id);
      } else {
        final idx = _favoriteTattooists.indexWhere((tt) => tt.id == t.id);
        if (idx != -1) _favoriteTattooists[idx] = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: 'Mes favoris',
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

          Column(
            children: [
              Container(
                color: Colors.black.withOpacity(0.7),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: KipikTheme.rouge,
                  labelColor: KipikTheme.rouge,
                  unselectedLabelColor: Colors.white,
                  tabs: const [
                    Tab(icon: Icon(Icons.image), text: 'Inspirations'),
                    Tab(icon: Icon(Icons.person), text: 'Tatoueurs'),
                  ],
                ),
              ),
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
    if (_isLoadingInspirations) {
      return const Center(child: CircularProgressIndicator());
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
              Icon(Icons.favorite_border, size: 64, color: KipikTheme.rouge.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Pas encore d\'inspirations favorites',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 20,
                  color: KipikTheme.noir,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Explorez les inspirations et ajoutez-les à vos favoris',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/inspirations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
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
    if (_isLoadingTattooists) {
      return const Center(child: CircularProgressIndicator());
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
              Icon(Icons.favorite_border, size: 64, color: KipikTheme.rouge.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Pas encore de tatoueurs favoris',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 20,
                  color: KipikTheme.noir,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Explorez les tatoueurs et ajoutez-les à vos favoris',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/recherche_tatoueur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
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
      itemBuilder: (_, i) {
        final t = _favoriteTattooists[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: KipikTheme.rouge, width: 1.5),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailTattooistPage(tattooist: t)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image de couverture
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(t.coverImageUrl, fit: BoxFit.cover),
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
                          icon: Icon(Icons.favorite, color: KipikTheme.rouge, size: 28),
                          onPressed: () => _toggleTattooistFavorite(t),
                        ),
                      ),
                    ],
                  ),
                ),
                // Infos tatoueur
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 30, backgroundImage: NetworkImage(t.avatarUrl)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'PermanentMarker',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(t.location, style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.style, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    t.styles.join(', '),
                                    style: TextStyle(color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInspirationCard(InspirationPost post) {
    final cardHeight = 150 + (post.id.hashCode % 100).toDouble();
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailInspirationPage(post: post)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: KipikTheme.rouge.withOpacity(0.3), width: 1),
        ),
        elevation: 4,
        child: Stack(
          children: [
            SizedBox(
              height: cardHeight,
              width: double.infinity,
              child: Hero(
                tag: 'inspiration_${post.id}',
                child: Image.network(post.imageUrl, fit: BoxFit.cover),
              ),
            ),
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
                    CircleAvatar(radius: 16, backgroundImage: NetworkImage(post.authorAvatarUrl)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'PermanentMarker',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _toggleInspirationFavorite(post),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite, color: KipikTheme.rouge, size: 20),
                ),
              ),
            ),
            if (post.isFromProfessional)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: KipikTheme.rouge,
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
