// lib/pages/particulier/detail_tattooist_page.dart

import 'package:flutter/material.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../models/tattooist.dart';
import '../../models/inspiration_post.dart';
import '../../services/tattooist/tattooist_service.dart';
import '../../services/inspiration/inspiration_service.dart';
import 'detail_inspiration_page.dart';

class DetailTattooistPage extends StatefulWidget {
  final Tattooist tattooist;
  
  const DetailTattooistPage({
    Key? key,
    required this.tattooist,
  }) : super(key: key);

  @override
  State<DetailTattooistPage> createState() => _DetailTattooistPageState();
}

class _DetailTattooistPageState extends State<DetailTattooistPage> {
  late Tattooist _tattooist;
  final TattooistService _tattooistService = TattooistService();
  final InspirationService _inspirationService = InspirationService();
  List<InspirationPost> _tattooistPosts = [];
  bool _isLoadingPosts = false;
  
  @override
  void initState() {
    super.initState();
    _tattooist = widget.tattooist;
    _loadTattooistPosts();
  }
  
  Future<void> _loadTattooistPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });
    
    try {
      // Dans un vrai service, vous filtreriez par l'ID du tatoueur
      final posts = await _inspirationService.getPosts();
      
      // Simulons que certains posts sont de ce tatoueur (dans un système réel, ils seraient filtrés par l'API)
      final filteredPosts = posts.where((post) => 
        post.authorName == _tattooist.name || 
        post.id.hashCode % 3 == 0  // Juste pour avoir quelques résultats en mode démo
      ).toList();
      
      setState(() {
        _tattooistPosts = filteredPosts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPosts = false;
      });
      // Gérer l'erreur
    }
  }
  
  Future<void> _toggleFavorite() async {
    try {
      final updatedTattooist = await _tattooistService.toggleFavorite(_tattooist.id);
      setState(() {
        _tattooist = updatedTattooist;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tattooist.isFavorite 
            ? 'Ajouté aux tatoueurs favoris' 
            : 'Retiré des tatoueurs favoris'),
          backgroundColor: Colors.black87,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Gérer l'erreur
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar personnalisée avec image de couverture
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de couverture
                  Image.network(
                    _tattooist.coverImageUrl,
                    fit: BoxFit.cover,
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
                ],
              ),
              title: Text(
                _tattooist.name,
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
                  _tattooist.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _tattooist.isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Partager le profil du tatoueur
                },
              ),
            ],
          ),
          
          // Contenu principal
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
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(_tattooist.avatarUrl),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tattooist.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      _tattooist.location,
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
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_tattooist.rating.toStringAsFixed(1)} (${_tattooist.reviewsCount} avis)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description fictive (à remplacer par une vraie description du tatoueur)
                      const Text(
                        'Tatoueur professionnel spécialisé dans les designs créatifs et personnalisés. '
                        'Mon studio offre un environnement propre et accueillant pour tous vos projets de tatouage.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Styles de tatouage
                      const Text(
                        'Styles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tattooist.styles.map((style) {
                          return Chip(
                            label: Text(style),
                            backgroundColor: Colors.grey[200],
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
                              // Ouvrir la messagerie
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.calendar_today,
                            label: 'Réserver',
                            onTap: () {
                              // Ouvrir la page de réservation
                            },
                            isPrimary: true,
                          ),
                          _buildActionButton(
                            icon: Icons.info_outline,
                            label: 'Infos',
                            onTap: () {
                              // Afficher les informations du studio
                            },
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
                
                // Réalisations du tatoueur
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Réalisations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (_isLoadingPosts)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
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
                                  'Aucune réalisation pour le moment',
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
                            return _buildRealisationItem(post);
                          },
                        ),
                      
                      if (_tattooistPosts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Center(
                            child: TextButton(
                              onPressed: () {
                                // Voir toutes les réalisations
                              },
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
                
                // Section avis
                Container(
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
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  _tattooist.rating.toStringAsFixed(1),
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
                            '(${_tattooist.reviewsCount})',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Liste des avis fictifs
                      _buildReviewItem(
                        name: 'Sophie L.',
                        date: 'Il y a 2 semaines',
                        rating: 5,
                        text: 'Super expérience ! Le tatoueur a parfaitement compris ma demande et le résultat est magnifique. Très professionnel et studio impeccable.',
                        avatarUrl: 'https://i.pravatar.cc/150?img=5',
                      ),
                      
                      const Divider(),
                      
                      _buildReviewItem(
                        name: 'Thomas B.',
                        date: 'Il y a 1 mois',
                        rating: 4,
                        text: 'Très bon travail, je suis satisfait du résultat. Le seul bémol est le temps d\'attente un peu long pour obtenir un rendez-vous.',
                        avatarUrl: 'https://i.pravatar.cc/150?img=12',
                      ),
                      
                      const Divider(),
                      
                      _buildReviewItem(
                        name: 'Marie D.',
                        date: 'Il y a 3 mois',
                        rating: 5,
                        text: 'C\'était mon premier tatouage et j\'étais un peu stressée, mais le tatoueur a su me mettre à l\'aise. Je suis ravie du résultat !',
                        avatarUrl: 'https://i.pravatar.cc/150?img=9',
                      ),
                      
                      Center(
                        child: TextButton(
                          onPressed: () {
                            // Voir tous les avis
                          },
                          child: const Text('Voir tous les avis'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Espace en bas
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
      // Bouton flottant pour contacter
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action pour contacter le tatoueur
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: isPrimary 
              ? Theme.of(context).colorScheme.primary 
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
            Icon(icon),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRealisationItem(InspirationPost post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailInspirationPage(post: post)),
        );
      },
      child: Hero(
        tag: 'inspiration_${post.id}',
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(post.imageUrl),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
  
  Widget _buildReviewItem({
    required String name,
    required String date,
    required int rating,
    required String text,
    required String avatarUrl,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
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
                    color: Colors.amber,
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
}