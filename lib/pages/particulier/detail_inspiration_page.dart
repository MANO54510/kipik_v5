import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../widgets/common/app_bars/custom_app_bar_particulier.dart'; // Correction de l'import
import '../../models/inspiration_post.dart';
import '../../services/inspiration/inspiration_service.dart';
import '../../models/comment.dart';

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
  final InspirationService _inspirationService = InspirationService();
  
  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });
    
    try {
      final comments = await _inspirationService.getComments(_post.id);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
      // Gérer l'erreur
    }
  }
  
  Future<void> _toggleFavorite() async {
    try {
      final updatedPost = await _inspirationService.toggleFavorite(_post.id);
      setState(() {
        _post = updatedPost;
      });
    } catch (e) {
      // Gérer l'erreur
    }
  }
  
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    try {
      final newComment = await _inspirationService.addComment(
        _post.id, 
        _commentController.text.trim()
      );
      
      setState(() {
        _comments.add(newComment);
        _commentController.clear();
      });
    } catch (e) {
      // Gérer l'erreur
    }
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
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Professionnel',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.primary,
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
                                      color: _post.isFavorite ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      // Partager le post
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
                                  style: const TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                              
                              const SizedBox(height: 8),
                              
                              // Hashtags
                              Wrap(
                                spacing: 8,
                                children: _post.tags.map((tag) {
                                  return Text(
                                    '#$tag',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
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
                                  child: CircularProgressIndicator(),
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
                          color: Theme.of(context).colorScheme.primary,
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