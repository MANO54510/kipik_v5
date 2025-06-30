class Tutorial {
  final String id;
  final String title;
  final String description;
  final String? content;
  final String category;
  final String? videoUrl;
  final String? thumbnailUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isPremium;
  final int viewCount;
  
  Tutorial({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    required this.category,
    this.videoUrl,
    this.thumbnailUrl,
    this.createdAt,
    this.updatedAt,
    this.isPremium = false,
    this.viewCount = 0,
  });
  
  factory Tutorial.fromJson(Map<String, dynamic> json) {
    return Tutorial(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      content: json['content'] as String?,
      category: json['category'] as String,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      isPremium: json['isPremium'] as bool? ?? false,
      viewCount: json['viewCount'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'category': category,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPremium': isPremium,
      'viewCount': viewCount,
    };
  }
  
  @override
  String toString() {
    return 'Tutorial(id: $id, title: $title, category: $category)';
  }
}