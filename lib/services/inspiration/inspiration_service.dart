// lib/services/inspiration_service.dart

import 'dart:math';
import '../../models/inspiration_post.dart';
import '../../models/comment.dart';

class InspirationService {
  // Mock data pour le développement
  final List<InspirationPost> _mockPosts = List.generate(
    30,
    (index) => InspirationPost(
      id: 'post_$index',
      imageUrl: 'https://picsum.photos/seed/${Random().nextInt(1000)}/500/800',
      authorId: 'user_${Random().nextInt(10)}',
      authorName: ['InkMaster', 'TattooArtist', 'InkDreamer', 'NeedleArtist', 'ArtInked'][Random().nextInt(5)],
      authorAvatarUrl: 'https://i.pravatar.cc/150?img=${Random().nextInt(70)}',
      isFromProfessional: Random().nextBool(),
      description: index % 3 == 0 
          ? 'Ma nouvelle création ! Ce tatouage a été réalisé en utilisant des techniques traditionnelles. Le client était super content du résultat final !'
          : '',
      tags: List.generate(
        Random().nextInt(5) + 1,
        (i) => ['tatouage', 'inkart', 'tattoodesign', 'blackwork', 'traditionaltattoo', 'minimalist', 'colortattoo'][Random().nextInt(7)],
      ),
      tattooPlacements: Random().nextBool() 
          ? [['Bras', 'Jambe', 'Dos', 'Poignet', 'Cheville'][Random().nextInt(5)]]
          : [],
      tattooStyles: Random().nextBool()
          ? [['Traditionnel', 'Réaliste', 'Minimaliste', 'BlackWork', 'Géométrique'][Random().nextInt(5)]]
          : [],
      createdAt: DateTime.now().subtract(Duration(days: Random().nextInt(30))),
      likesCount: Random().nextInt(100),
      commentsCount: Random().nextInt(10),
      isFavorite: Random().nextBool(),
    ),
  );

  final Map<String, List<Comment>> _mockComments = {};

  // Méthodes pour récupérer les posts
  Future<List<InspirationPost>> getPosts({String? category}) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Filtrer par catégorie si nécessaire
    if (category == null || category == 'Tous') {
      return _mockPosts.take(10).toList();
    } else if (category == 'Professionnels') {
      return _mockPosts.where((post) => post.isFromProfessional).take(10).toList();
    } else if (category == 'Clients') {
      return _mockPosts.where((post) => !post.isFromProfessional).take(10).toList();
    } else if (category == 'Dessins') {
      return _mockPosts.where((post) => post.tags.contains('tattoodesign')).take(10).toList();
    } else if (category == 'Réalisations') {
      return _mockPosts.where((post) => !post.tags.contains('tattoodesign')).take(10).toList();
    }
    
    return _mockPosts.take(10).toList();
  }

  Future<List<InspirationPost>> getMorePosts({String? lastPostId, String? category}) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Trouver l'index du dernier post chargé
    int startIndex = 0;
    if (lastPostId != null) {
      final lastIndex = _mockPosts.indexWhere((post) => post.id == lastPostId);
      if (lastIndex != -1) {
        startIndex = lastIndex + 1;
      }
    }
    
    // Retourner les 10 posts suivants
    List<InspirationPost> filteredPosts = _mockPosts;
    
    if (category != null && category != 'Tous') {
      if (category == 'Professionnels') {
        filteredPosts = _mockPosts.where((post) => post.isFromProfessional).toList();
      } else if (category == 'Clients') {
        filteredPosts = _mockPosts.where((post) => !post.isFromProfessional).toList();
      } else if (category == 'Dessins') {
        filteredPosts = _mockPosts.where((post) => post.tags.contains('tattoodesign')).toList();
      } else if (category == 'Réalisations') {
        filteredPosts = _mockPosts.where((post) => !post.tags.contains('tattoodesign')).toList();
      }
    }
    
    final endIndex = min(startIndex + 10, filteredPosts.length);
    return filteredPosts.sublist(startIndex, endIndex);
  }

  // Méthode pour ajouter/retirer des favoris
  Future<InspirationPost> toggleFavorite(String postId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _mockPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final post = _mockPosts[index];
      final updatedPost = post.copyWith(
        isFavorite: !post.isFavorite,
      );
      _mockPosts[index] = updatedPost;
      return updatedPost;
    }
    
    throw Exception('Post not found');
  }

  // Méthodes pour les commentaires
  Future<List<Comment>> getComments(String postId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (!_mockComments.containsKey(postId)) {
      // Générer des commentaires aléatoires
      _mockComments[postId] = List.generate(
        Random().nextInt(5),
        (index) => Comment(
          id: 'comment_$postId\_$index',
          postId: postId,
          authorId: 'user_${Random().nextInt(10)}',
          authorName: ['Sophie', 'Thomas', 'Julie', 'Marc', 'Emma'][Random().nextInt(5)],
          authorAvatar: 'https://i.pravatar.cc/150?img=${Random().nextInt(70)}',
          text: [
            'Superbe travail ! J\'adore les détails.',
            'Très beau tatouage, j\'aimerais avoir le même.',
            'Quel est le nom du tatoueur ? J\'aimerais prendre RDV.',
            'La technique est impressionnante !',
            'Depuis combien de temps es-tu tatoueur ?',
            'Les couleurs sont magnifiques !',
          ][Random().nextInt(6)],
          createdAt: DateTime.now().subtract(Duration(hours: Random().nextInt(72))),
        ),
      );
    }
    
    return _mockComments[postId] ?? [];
  }

  Future<Comment> addComment(String postId, String text) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (!_mockComments.containsKey(postId)) {
      _mockComments[postId] = [];
    }
    
    final newComment = Comment(
      id: 'comment_$postId\_${_mockComments[postId]!.length}',
      postId: postId,
      authorId: 'current_user',
      authorName: 'Vous',
      authorAvatar: 'https://i.pravatar.cc/150?img=5',
      text: text,
      createdAt: DateTime.now(),
    );
    
    _mockComments[postId]!.add(newComment);
    
    // Mettre à jour le nombre de commentaires sur le post
    final postIndex = _mockPosts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _mockPosts[postIndex];
      _mockPosts[postIndex] = post.copyWith(
        commentsCount: post.commentsCount + 1,
      );
    }
    
    return newComment;
  }
}