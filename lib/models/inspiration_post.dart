// lib/models/inspiration_post.dart

class InspirationPost {
  final String id;
  final String imageUrl;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final bool isFromProfessional;
  final String description;
  final List<String> tags;
  final List<String> tattooPlacements;
  final List<String> tattooStyles;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isFavorite;

  InspirationPost({
    required this.id,
    required this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.isFromProfessional,
    required this.description,
    required this.tags,
    required this.tattooPlacements,
    required this.tattooStyles,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isFavorite,
  });

  InspirationPost copyWith({
    String? id,
    String? imageUrl,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    bool? isFromProfessional,
    String? description,
    List<String>? tags,
    List<String>? tattooPlacements,
    List<String>? tattooStyles,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    bool? isFavorite,
  }) {
    return InspirationPost(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isFromProfessional: isFromProfessional ?? this.isFromProfessional,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      tattooPlacements: tattooPlacements ?? this.tattooPlacements,
      tattooStyles: tattooStyles ?? this.tattooStyles,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}