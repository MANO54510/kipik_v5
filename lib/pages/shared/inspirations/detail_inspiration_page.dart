// lib/pages/shared/inspirations/detail_inspiration_page.dart

import 'package:flutter/material.dart';
import '../../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../../models/inspiration_post.dart';
import '../../../services/inspiration/firebase_inspiration_service.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../../models/user_role.dart';
import '../../../models/comment.dart';
import '../../../theme/kipik_theme.dart';

class DetailInspirationPage extends StatefulWidget {
  final InspirationPost post;
  
  const DetailInspirationPage({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<DetailInspirationPage> createState() => _DetailInspirationPageState();
}

class _DetailInspirationPageState extends State<DetailInspirationPage> {
  late InspirationPost _post;
  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  final TextEditingController _commentController = TextEditingController();
  final FirebaseInspirationService _inspirationService = FirebaseInspirationService.instance;
  
  // ✅ NOUVEAU : Détection du rôle utilisateur
  UserRole? _currentUserRole;
  
  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _initializeUserRole();
    _loadComments();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// ✅ NOUVEAU : Initialiser le rôle utilisateur
  void _initializeUserRole() {
    final currentUser = SecureAuthService.instance.currentUser;
    _currentUserRole = currentUser?.role;
  }
  
  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });
    
    try {
      // ✅ NOUVEAU : Utiliser FirebaseInspirationService pour les commentaires
      // Pour l'instant, on utilise des commentaires de démo
      // TODO: Implémenter getComments dans FirebaseInspirationService
      await Future.delayed(const Duration(milliseconds: 500)); // Simuler le chargement
      
      setState(() {
        _comments = _generateDemoComments();
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des commentaires');
    }
  }

  /// ✅ TEMPORAIRE : Générer des commentaires de démo
  List<Comment> _generateDemoComments() {
    return [
      Comment(
        id: 'demo_comment_1',
        postId: _post.id,
        authorId: 'demo_user_1',
        authorName: 'Alex Martin',
        authorAvatar: 'https://picsum.photos/seed/user1/100/100',
        text: 'Magnifique travail ! Le style est vraiment unique.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Comment(
        id: 'demo_comment_2',
        postId: _post.id,
        authorId: 'demo_user_2',
        authorName: 'Sophie Dubois',
        authorAvatar: 'https://picsum.photos/seed/user2/100/100',
        text: 'J\'adore les détails, très inspirant pour mon prochain tatouage !',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }
  
  Future<void> _toggleFavorite() async {
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Vous devez être connecté pour ajouter aux favoris');
        return;
      }

      final newFavoriteStatus = await _inspirationService.toggleFavorite(
        inspirationId: _post.id,
        userId: currentUser.uid,
      );
      
      setState(() {
        _post = _post.copyWith(isFavorite: newFavoriteStatus);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newFavoriteStatus 
            ? 'Ajouté aux favoris' 
            : 'Retiré des favoris'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la mise à jour des favoris');
    }
  }
  
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    try {
      // ✅ NOUVEAU : Ajouter commentaire avec FirebaseInspirationService
      // Pour l'instant, on simule l'ajout
      // TODO: Implémenter addComment dans FirebaseInspirationService
      
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Vous devez être connecté pour commenter');
        return;
      }

      final newComment = Comment(
        id: 'demo_comment_${DateTime.now().millisecondsSinceEpoch}',
        postId: _post.id,
        authorId: currentUser.uid,
        authorName: currentUser.name ?? 'Utilisateur',
        authorAvatar: 'https://picsum.photos/seed/${currentUser.uid}/100/100',
        text: _commentController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      setState(() {
        _comments.add(newComment);
        _commentController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commentaire ajouté !'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'ajout du commentaire');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// ✅ NOUVEAU : Actions spécifiques selon le rôle
  void _handleRoleSpecificAction() {
    if (_currentUserRole == UserRole.tatoueur) {
      // Action pour tatoueur : Contacter pour collaboration, voir profil, etc.
      _showContactDialog();
    } else {
      // Action pour particulier : Réserver si c'est un flash, voir portfolio, etc.
      _showBookingDialog();
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacter l\'artiste'),
        content: const Text('Voulez-vous contacter cet artiste pour une collaboration ou des informations ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter contact entre tatoueurs
              _showInfoSnackBar('Contact artiste - Bientôt disponible');
            },
            style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
            child: const Text('Contacter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réserver ce tatouage'),
        content: const Text('Cette œuvre vous inspire ? Contactez l\'artiste pour réaliser un tatouage similaire.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter système de réservation
              _showInfoSnackBar('Réservation - Bientôt disponible');
            },
            style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
            child: const Text('Réserver', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KipikTheme.rouge,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: 'Détail inspiration',
        showBackButton: true,
      ),
      body: Stack(
        children: [
          Image.asset(
            'assets/background_charbon.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image principale
                        Hero(
                          tag: 'inspiration_${_post.id}',
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              _post.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        
                        // Informations sur l'auteur et actions
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Auteur et actions
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(_post.authorAvatarUrl),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _post.authorName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (_post.isFromProfessional)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.verified,
                                                size: 14,
                                                color: KipikTheme.rouge,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Professionnel',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: KipikTheme.rouge,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _toggleFavorite,
                                    icon: Icon(
                                      _post.isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: _post.isFavorite ? KipikTheme.rouge : Colors.grey,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      // TODO: Implémenter partage
                                      _showInfoSnackBar('Partage - Bientôt disponible');
                                    },
                                    icon: const Icon(Icons.share, color: Colors.grey),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Description
                              if (_post.description.isNotEmpty)
                                Text(
                                  _post.description,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              
                              const SizedBox(height: 8),
                              
                              // Hashtags
                              if (_post.tags.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  children: _post.tags.map((tag) {
                                    return Text(
                                      '#$tag',
                                      style: TextStyle(
                                        color: KipikTheme.rouge,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              
                              const SizedBox(height: 16),
                              
                              // Informations supplémentaires
                              if (_post.tattooPlacements.isNotEmpty || _post.tattooStyles.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_post.tattooPlacements.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.place, size: 18, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Emplacement: ${_post.tattooPlacements.join(", ")}',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      
                                      if (_post.tattooStyles.isNotEmpty)
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.style, size: 18, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Style: ${_post.tattooStyles.join(", ")}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),

                              // ✅ NOUVEAU : Bouton d'action selon le rôle
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _handleRoleSpecificAction,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: KipikTheme.rouge,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _currentUserRole == UserRole.tatoueur 
                                      ? 'Contacter l\'artiste' 
                                      : 'Réserver ce style',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                        
                        // Section commentaires
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Commentaires',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              if (_isLoadingComments)
                                const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
                                  ),
                                )
                              else if (_comments.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Soyez le premier à commenter',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _comments.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final comment = _comments[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundImage: NetworkImage(comment.authorAvatar),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      comment.authorName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      _formatCommentDate(comment.createdAt),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(comment.text),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Barre de commentaire
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addComment,
                        icon: Icon(
                          Icons.send,
                          color: KipikTheme.rouge,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatCommentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}