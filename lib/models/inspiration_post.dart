// lib/models/inspiration_post.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les posts d'inspiration (réalisations, dessins, flashs partagés)
class InspirationPost {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> additionalImages;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final bool isFromProfessional;
  final int likes;
  final int views;
  final int comments;
  final List<String> tags;
  final List<String> tattooPlacements;  // Emplacements du tatouage
  final List<String> tattooStyles;      // Styles de tatouage
  final String category;                // Catégorie (Réalisation, Dessin, Flash, etc.)
  final bool isFavorite;                // Si l'utilisateur actuel l'a en favori
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata; // Données supplémentaires

  const InspirationPost({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.additionalImages = const [],
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    this.isFromProfessional = false,
    this.likes = 0,
    this.views = 0,
    this.comments = 0,
    this.tags = const [],
    this.tattooPlacements = const [],
    this.tattooStyles = const [],
    this.category = 'Général',
    this.isFavorite = false,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Factory constructor depuis Firebase
  factory InspirationPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InspirationPost.fromMap(data, doc.id);
  }

  /// Factory constructor depuis Map
  factory InspirationPost.fromMap(Map<String, dynamic> map, String id) {
    return InspirationPost(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? 'https://picsum.photos/400/600',
      additionalImages: List<String>.from(map['additionalImages'] ?? []),
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Artiste',
      authorAvatarUrl: map['authorAvatarUrl'] ?? 'https://picsum.photos/100/100',
      isFromProfessional: map['isFromProfessional'] ?? false,
      likes: map['likes'] ?? 0,
      views: map['views'] ?? 0,
      comments: map['comments'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      tattooPlacements: List<String>.from(map['tattooPlacements'] ?? []),
      tattooStyles: List<String>.from(map['tattooStyles'] ?? []),
      category: map['category'] ?? 'Général',
      isFavorite: map['isFavorite'] ?? false,
      isPublic: map['isPublic'] ?? true,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// Factory depuis les données du FirebaseInspirationService
  factory InspirationPost.fromFirebaseData(Map<String, dynamic> data) {
    return InspirationPost(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? 'https://picsum.photos/400/600',
      additionalImages: List<String>.from(data['additionalImages'] ?? []),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Artiste',
      authorAvatarUrl: data['authorAvatarUrl'] ?? 'https://picsum.photos/100/100',
      isFromProfessional: data['isFromProfessional'] ?? false,
      likes: data['likes'] ?? 0,
      views: data['views'] ?? 0,
      comments: data['comments'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      tattooPlacements: List<String>.from(data['tattooPlacements'] ?? []),
      tattooStyles: List<String>.from(data['tattooStyles'] ?? []),
      category: data['category'] ?? 'Général',
      isFavorite: data['isFavorite'] ?? false,
      isPublic: data['isPublic'] ?? true,
      createdAt: data['createdAt'] is String 
          ? DateTime.parse(data['createdAt'])
          : data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt: data['updatedAt'] is String 
          ? DateTime.parse(data['updatedAt'])
          : data['updatedAt'] is Timestamp 
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'isFromProfessional': isFromProfessional,
      'likes': likes,
      'views': views,
      'comments': comments,
      'tags': tags,
      'tattooPlacements': tattooPlacements,
      'tattooStyles': tattooStyles,
      'category': category,
      'isFavorite': isFavorite,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Créer une copie avec modifications
  InspirationPost copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? additionalImages,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    bool? isFromProfessional,
    int? likes,
    int? views,
    int? comments,
    List<String>? tags,
    List<String>? tattooPlacements,
    List<String>? tattooStyles,
    String? category,
    bool? isFavorite,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return InspirationPost(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isFromProfessional: isFromProfessional ?? this.isFromProfessional,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      comments: comments ?? this.comments,
      tags: tags ?? this.tags,
      tattooPlacements: tattooPlacements ?? this.tattooPlacements,
      tattooStyles: tattooStyles ?? this.tattooStyles,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Incrémenter le nombre de vues
  InspirationPost incrementViews() {
    return copyWith(
      views: views + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Incrémenter/décrémenter les likes
  InspirationPost updateLikes(int delta) {
    return copyWith(
      likes: (likes + delta).clamp(0, double.infinity).toInt(),
      updatedAt: DateTime.now(),
    );
  }

  /// Incrémenter le nombre de commentaires
  InspirationPost incrementComments() {
    return copyWith(
      comments: comments + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Vérifier si le post appartient à l'utilisateur actuel
  bool belongsToUser(String? userId) {
    return userId != null && authorId == userId;
  }

  /// Obtenir un résumé du post
  String get summary {
    if (description.length <= 100) return description;
    return '${description.substring(0, 97)}...';
  }

  /// Obtenir les tags formatés pour l'affichage
  String get formattedTags {
    if (tags.isEmpty) return '';
    return tags.map((tag) => '#$tag').join(' ');
  }

  /// Vérifier si c'est un post récent (moins de 24h)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  /// Obtenir la catégorie d'affichage
  String get displayCategory {
    switch (category.toLowerCase()) {
      case 'realisation':
      case 'réalisation':
        return 'Réalisation';
      case 'dessin':
      case 'design':
        return 'Dessin';
      case 'flash':
        return 'Flash';
      case 'inspiration':
        return 'Inspiration';
      default:
        return category;
    }
  }

  @override
  String toString() {
    return 'InspirationPost(id: $id, title: $title, author: $authorName, likes: $likes)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspirationPost && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}