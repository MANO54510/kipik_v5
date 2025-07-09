// lib/models/inspiration_post.dart

/// Modèle pour les posts d'inspiration (compatibilité avec l'existant)
class InspirationPost {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final bool isFromProfessional;
  final int likes;
  final int views;
  final List<String> tags;
  final List<String> tattooPlacements;
  final List<String> tattooStyles;
  final bool isFavorite;
  final DateTime createdAt;

  const InspirationPost({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    this.isFromProfessional = false,
    this.likes = 0,
    this.views = 0,
    this.tags = const [],
    this.tattooPlacements = const [],
    this.tattooStyles = const [],
    this.isFavorite = false,
    required this.createdAt,
  });

  /// Factory constructor depuis les données Firebase
  factory InspirationPost.fromFirebaseData(Map<String, dynamic> data) {
    return InspirationPost(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? 'https://picsum.photos/400/600',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Artiste',
      authorAvatarUrl: data['authorAvatarUrl'] ?? 'https://picsum.photos/100/100',
      isFromProfessional: data['isFromProfessional'] ?? false,
      likes: data['likes'] ?? 0,
      views: data['views'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      tattooPlacements: List<String>.from(data['tattooPlacements'] ?? []),
      tattooStyles: List<String>.from(data['tattooStyles'] ?? []),
      isFavorite: data['isFavorite'] ?? false,
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'isFromProfessional': isFromProfessional,
      'likes': likes,
      'views': views,
      'tags': tags,
      'tattooPlacements': tattooPlacements,
      'tattooStyles': tattooStyles,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// CopyWith pour modifications
  InspirationPost copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    bool? isFromProfessional,
    int? likes,
    int? views,
    List<String>? tags,
    List<String>? tattooPlacements,
    List<String>? tattooStyles,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return InspirationPost(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isFromProfessional: isFromProfessional ?? this.isFromProfessional,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      tags: tags ?? this.tags,
      tattooPlacements: tattooPlacements ?? this.tattooPlacements,
      tattooStyles: tattooStyles ?? this.tattooStyles,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'InspirationPost(id: $id, title: $title, authorName: $authorName)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspirationPost && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}