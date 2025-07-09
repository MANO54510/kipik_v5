// lib/models/portfolio_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'portfolio_model.g.dart';

/// 🎨 Modèle pour les portfolios/réalisations des tatoueurs
/// Visible par clients (navigation) et organisateurs (validation)
@JsonSerializable()
class Portfolio {
  final String id;
  final String tattooistId; // Propriétaire du portfolio
  final String? shopId; // Shop associé (optionnel)
  final String title;
  final String? description;
  final List<PortfolioImage> images;
  final List<String> tags;
  final String category;
  final String style;
  final String bodyPart;
  final int? duration; // en heures
  final PortfolioSize? size;
  final PortfolioSettings settings;
  final PortfolioStats? stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Portfolio({
    required this.id,
    required this.tattooistId,
    this.shopId,
    required this.title,
    this.description,
    required this.images,
    required this.tags,
    required this.category,
    required this.style,
    required this.bodyPart,
    this.duration,
    this.size,
    required this.settings,
    this.stats,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory pour création depuis Firestore
  factory Portfolio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Portfolio.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Conversion vers Firestore (sans l'ID)
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  /// JSON serialization
  factory Portfolio.fromJson(Map<String, dynamic> json) => _$PortfolioFromJson(json);
  Map<String, dynamic> toJson() => _$PortfolioToJson(this);

  /// Copy with pour immutabilité
  Portfolio copyWith({
    String? id,
    String? tattooistId,
    String? shopId,
    String? title,
    String? description,
    List<PortfolioImage>? images,
    List<String>? tags,
    String? category,
    String? style,
    String? bodyPart,
    int? duration,
    PortfolioSize? size,
    PortfolioSettings? settings,
    PortfolioStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Portfolio(
      id: id ?? this.id,
      tattooistId: tattooistId ?? this.tattooistId,
      shopId: shopId ?? this.shopId,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      style: style ?? this.style,
      bodyPart: bodyPart ?? this.bodyPart,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Getters utilitaires
  bool get isPublic => settings.isPublic;
  bool get allowComments => settings.allowComments;
  bool get isFeatured => settings.isFeatured;
  
  /// Image principale (première de la liste)
  PortfolioImage? get mainImage => images.isNotEmpty ? images.first : null;
  
  /// Miniature principale
  String? get thumbnailUrl => mainImage?.thumbnailUrl ?? mainImage?.url;
  
  /// Validation business
  bool get isComplete {
    return title.isNotEmpty &&
           images.isNotEmpty &&
           category.isNotEmpty &&
           style.isNotEmpty &&
           bodyPart.isNotEmpty;
  }

  /// Statistiques
  int get totalViews => stats?.views ?? 0;
  int get totalLikes => stats?.likes ?? 0;
  int get totalShares => stats?.shares ?? 0;
  
  /// Durée formatée
  String get formattedDuration {
    if (duration == null) return 'Non spécifiée';
    if (duration! == 1) return '1 heure';
    return '$duration heures';
  }

  /// Taille formatée
  String get formattedSize {
    if (size == null) return 'Non spécifiée';
    return '${size!.width}cm × ${size!.height}cm';
  }

  @override
  String toString() => 'Portfolio(id: $id, title: $title, tattooistId: $tattooistId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Portfolio && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 📸 Image du portfolio
@JsonSerializable()
class PortfolioImage {
  final String url;
  final String? thumbnailUrl;
  final int order;
  final String? caption;
  final String? alt;

  const PortfolioImage({
    required this.url,
    this.thumbnailUrl,
    required this.order,
    this.caption,
    this.alt,
  });

  factory PortfolioImage.fromJson(Map<String, dynamic> json) => _$PortfolioImageFromJson(json);
  Map<String, dynamic> toJson() => _$PortfolioImageToJson(this);

  /// URL à utiliser pour l'affichage (thumbnail en priorité)
  String get displayUrl => thumbnailUrl ?? url;

  PortfolioImage copyWith({
    String? url,
    String? thumbnailUrl,
    int? order,
    String? caption,
    String? alt,
  }) {
    return PortfolioImage(
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      order: order ?? this.order,
      caption: caption ?? this.caption,
      alt: alt ?? this.alt,
    );
  }
}

/// 📏 Dimensions du tatouage
@JsonSerializable()
class PortfolioSize {
  final int width; // en cm
  final int height; // en cm

  const PortfolioSize({
    required this.width,
    required this.height,
  });

  factory PortfolioSize.fromJson(Map<String, dynamic> json) => _$PortfolioSizeFromJson(json);
  Map<String, dynamic> toJson() => _$PortfolioSizeToJson(this);

  /// Surface en cm²
  int get area => width * height;

  /// Catégorie de taille
  SizeCategory get category {
    if (area <= 25) return SizeCategory.small; // 5x5cm
    if (area <= 100) return SizeCategory.medium; // 10x10cm
    if (area <= 400) return SizeCategory.large; // 20x20cm
    return SizeCategory.extraLarge;
  }

  PortfolioSize copyWith({
    int? width,
    int? height,
  }) {
    return PortfolioSize(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

/// ⚙️ Paramètres du portfolio
@JsonSerializable()
class PortfolioSettings {
  final bool isPublic;
  final bool allowComments;
  final bool isFeatured;

  const PortfolioSettings({
    required this.isPublic,
    required this.allowComments,
    required this.isFeatured,
  });

  factory PortfolioSettings.fromJson(Map<String, dynamic> json) => _$PortfolioSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$PortfolioSettingsToJson(this);

  /// Factory pour settings par défaut
  factory PortfolioSettings.defaultSettings() {
    return const PortfolioSettings(
      isPublic: true,
      allowComments: true,
      isFeatured: false,
    );
  }

  PortfolioSettings copyWith({
    bool? isPublic,
    bool? allowComments,
    bool? isFeatured,
  }) {
    return PortfolioSettings(
      isPublic: isPublic ?? this.isPublic,
      allowComments: allowComments ?? this.allowComments,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}

/// 📊 Statistiques du portfolio
@JsonSerializable()
class PortfolioStats {
  final int views;
  final int likes;
  final int shares;

  const PortfolioStats({
    required this.views,
    required this.likes,
    required this.shares,
  });

  factory PortfolioStats.fromJson(Map<String, dynamic> json) => _$PortfolioStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PortfolioStatsToJson(this);

  /// Factory pour stats vides
  factory PortfolioStats.empty() {
    return const PortfolioStats(
      views: 0,
      likes: 0,
      shares: 0,
    );
  }

  /// Score d'engagement
  double get engagementScore {
    if (views == 0) return 0.0;
    return ((likes + shares) / views) * 100;
  }

  PortfolioStats copyWith({
    int? views,
    int? likes,
    int? shares,
  }) {
    return PortfolioStats(
      views: views ?? this.views,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
    );
  }
}

/// 📏 Catégories de taille
enum SizeCategory {
  @JsonValue('small')
  small,
  @JsonValue('medium')
  medium,
  @JsonValue('large')
  large,
  @JsonValue('extra_large')
  extraLarge;

  String get displayName {
    switch (this) {
      case SizeCategory.small:
        return 'Petit';
      case SizeCategory.medium:
        return 'Moyen';
      case SizeCategory.large:
        return 'Grand';
      case SizeCategory.extraLarge:
        return 'Très grand';
    }
  }
}

/// 🎨 Styles de tatouage prédéfinis
class TattooStyles {
  static const List<String> all = [
    'Réalisme',
    'Traditionnel',
    'Neo-traditionnel',
    'Japonais',
    'Tribal',
    'Géométrique',
    'Aquarelle',
    'Minimaliste',
    'Blackwork',
    'Dotwork',
    'Portrait',
    'Biomécanique',
    'Old School',
    'New School',
    'Chicano',
    'Celtic',
    'Mandala',
    'Fine Line',
    'Ornementale',
    'Illustratif',
    'Abstrait',
    'Noir et gris',
    'Coloré',
  ];

  static List<String> search(String query) {
    return all
        .where((style) => style.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

/// 🎯 Parties du corps prédéfinies
class BodyParts {
  static const List<String> all = [
    'Bras',
    'Avant-bras',
    'Épaule',
    'Poitrine',
    'Dos',
    'Jambe',
    'Mollet',
    'Cuisse',
    'Main',
    'Pied',
    'Poignet',
    'Cheville',
    'Cou',
    'Nuque',
    'Torse',
    'Ventre',
    'Côtes',
    'Doigt',
    'Visage',
    'Tête',
    'Biceps',
    'Triceps',
    'Omoplate',
    'Fessier',
    'Genou',
  ];

  static List<String> search(String query) {
    return all
        .where((part) => part.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

/// 🏷️ Catégories de tatouage prédéfinies
class TattooCategories {
  static const List<String> all = [
    'Réalisme',
    'Traditionnel',
    'Japonais',
    'Tribal',
    'Géométrique',
    'Minimaliste',
    'Portrait',
    'Animalier',
    'Floral',
    'Religieux',
    'Mythologique',
    'Musique',
    'Sport',
    'Voyage',
    'Nature',
    'Abstrait',
    'Lettrage',
    'Symboles',
    'Culturel',
    'Artistique',
  ];

  static List<String> search(String query) {
    return all
        .where((category) => category.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

/// 🏷️ Extensions utilitaires
extension PortfolioListExtensions on List<Portfolio> {
  /// Filtrer par style
  List<Portfolio> filterByStyle(String style) {
    return where((portfolio) => 
      portfolio.style.toLowerCase().contains(style.toLowerCase())
    ).toList();
  }

  /// Filtrer par catégorie
  List<Portfolio> filterByCategory(String category) {
    return where((portfolio) => 
      portfolio.category.toLowerCase().contains(category.toLowerCase())
    ).toList();
  }

  /// Filtrer par partie du corps
  List<Portfolio> filterByBodyPart(String bodyPart) {
    return where((portfolio) => 
      portfolio.bodyPart.toLowerCase().contains(bodyPart.toLowerCase())
    ).toList();
  }

  /// Filtrer par tags
  List<Portfolio> filterByTag(String tag) {
    return where((portfolio) => 
      portfolio.tags.any((t) => 
        t.toLowerCase().contains(tag.toLowerCase())
      )
    ).toList();
  }

  /// Filtrer par tatoueur
  List<Portfolio> filterByTattooistId(String tattooistId) {
    return where((portfolio) => portfolio.tattooistId == tattooistId).toList();
  }

  /// Trier par popularité (vues + likes + shares)
  List<Portfolio> sortByPopularity() {
    final sorted = List<Portfolio>.from(this);
    sorted.sort((a, b) {
      final aPopularity = a.totalViews + a.totalLikes + a.totalShares;
      final bPopularity = b.totalViews + b.totalLikes + b.totalShares;
      return bPopularity.compareTo(aPopularity);
    });
    return sorted;
  }

  /// Trier par date (plus récent en premier)
  List<Portfolio> sortByDate() {
    final sorted = List<Portfolio>.from(this);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Filtrer les portfolios publics
  List<Portfolio> get publicPortfolios {
    return where((portfolio) => portfolio.isPublic).toList();
  }

  /// Filtrer les portfolios mis en avant
  List<Portfolio> get featuredPortfolios {
    return where((portfolio) => portfolio.isFeatured).toList();
  }

  /// Grouper par style
  Map<String, List<Portfolio>> groupByStyle() {
    final Map<String, List<Portfolio>> grouped = {};
    for (final portfolio in this) {
      grouped.putIfAbsent(portfolio.style, () => []).add(portfolio);
    }
    return grouped;
  }

  /// Grouper par catégorie
  Map<String, List<Portfolio>> groupByCategory() {
    final Map<String, List<Portfolio>> grouped = {};
    for (final portfolio in this) {
      grouped.putIfAbsent(portfolio.category, () => []).add(portfolio);
    }
    return grouped;
  }

  /// Recherche textuelle
  List<Portfolio> searchText(String query) {
    final lowerQuery = query.toLowerCase();
    return where((portfolio) =>
        portfolio.title.toLowerCase().contains(lowerQuery) ||
        (portfolio.description?.toLowerCase().contains(lowerQuery) ?? false) ||
        portfolio.style.toLowerCase().contains(lowerQuery) ||
        portfolio.category.toLowerCase().contains(lowerQuery) ||
        portfolio.bodyPart.toLowerCase().contains(lowerQuery) ||
        portfolio.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }
}