// lib/models/tattooist.dart

class Tattooist {
  final String id;
  final String name;
  final String avatarUrl;
  final String coverImageUrl;
  final String location;
  final List<String> styles;
  final double rating;
  final int reviewsCount;
  final bool isFavorite;

  Tattooist({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.coverImageUrl,
    required this.location,
    required this.styles,
    required this.rating,
    required this.reviewsCount,
    required this.isFavorite,
  });

  Tattooist copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? coverImageUrl,
    String? location,
    List<String>? styles,
    double? rating,
    int? reviewsCount,
    bool? isFavorite,
  }) {
    return Tattooist(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      location: location ?? this.location,
      styles: styles ?? this.styles,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}