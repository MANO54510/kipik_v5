// lib/models/comment.dart

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.text,
    required this.createdAt,
  });
}