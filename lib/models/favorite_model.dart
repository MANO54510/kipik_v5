// lib/models/favorite_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'favorite_model.g.dart';

/// ⭐ Modèle pour les favoris des clients
/// Système de favoris personnel pour chaque client
@JsonSerializable()
class Favorite {
  final String id;
  final String userId; // Client qui ajoute le favori
  final String tattooistId; // Tatoueur favorisé
  final String? shopId; // Shop associé (optionnel)
  final DateTime addedAt;
  final String? notes; // Notes privées du client
  final List<String> tags; // Tags personnels
  final FavoritePriority priority;

  const Favorite({
    required this.id,
    required this.userId,
    required this.tattooistId,
    this.shopId,
    required this.addedAt,
    this.notes,
    required this.tags,
    required this.priority,
  });

  /// Factory pour création depuis Firestore
  factory Favorite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Favorite.fromJson({
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
  factory Favorite.fromJson(Map<String, dynamic> json) => _$FavoriteFromJson(json);
  Map<String, dynamic> toJson() => _$FavoriteToJson(this);

  /// Copy with pour immutabilité
  Favorite copyWith({
    String? id,
    String? userId,
    String? tattooistId,
    String? shopId,
    DateTime? addedAt,
    String? notes,
    List<String>? tags,
    FavoritePriority? priority,
  }) {
    return Favorite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tattooistId: tattooistId ?? this.tattooistId,
      shopId: shopId ?? this.shopId,
      addedAt: addedAt ?? this.addedAt,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
    );
  }

  /// Getters utilitaires
  bool get hasNotes => notes != null && notes!.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
  bool get hasShop => shopId != null;
  
  /// Ancienneté du favori
  Duration get age => DateTime.now().difference(addedAt);
  int get ageInDays => age.inDays;
  
  /// Validation business
  bool get isValid {
    return userId.isNotEmpty && tattooistId.isNotEmpty;
  }

  @override
  String toString() => 'Favorite(id: $id, userId: $userId, tattooistId: $tattooistId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Favorite && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 🎯 Priorité des favoris
enum FavoritePriority {
  @JsonValue(1)
  high,
  @JsonValue(2)
  medium,
  @JsonValue(3)
  low;

  int get value {
    switch (this) {
      case FavoritePriority.high:
        return 1;
      case FavoritePriority.medium:
        return 2;
      case FavoritePriority.low:
        return 3;
    }
  }

  String get displayName {
    switch (this) {
      case FavoritePriority.high:
        return 'Haute';
      case FavoritePriority.medium:
        return 'Moyenne';
      case FavoritePriority.low:
        return 'Basse';
    }
  }

  Color get color {
    switch (this) {
      case FavoritePriority.high:
        return Colors.red;
      case FavoritePriority.medium:
        return Colors.orange;
      case FavoritePriority.low:
        return Colors.green;
    }
  }

  IconData get icon {
    switch (this) {
      case FavoritePriority.high:
        return Icons.priority_high;
      case FavoritePriority.medium:
        return Icons.remove;
      case FavoritePriority.low:
        return Icons.keyboard_arrow_down;
    }
  }

  static FavoritePriority fromValue(int value) {
    switch (value) {
      case 1:
        return FavoritePriority.high;
      case 2:
        return FavoritePriority.medium;
      case 3:
        return FavoritePriority.low;
      default:
        return FavoritePriority.medium;
    }
  }
}

/// 📊 Modèle pour les statistiques de favoris
@JsonSerializable()
class FavoriteStats {
  final int totalFavorites;
  final int highPriorityCount;
  final int mediumPriorityCount;
  final int lowPriorityCount;
  final List<String> topTags;
  final String? mostFavoritedTattooistId;
  final DateTime? lastAddedAt;

  const FavoriteStats({
    required this.totalFavorites,
    required this.highPriorityCount,
    required this.mediumPriorityCount,
    required this.lowPriorityCount,
    required this.topTags,
    this.mostFavoritedTattooistId,
    this.lastAddedAt,
  });

  factory FavoriteStats.fromJson(Map<String, dynamic> json) => _$FavoriteStatsFromJson(json);
  Map<String, dynamic> toJson() => _$FavoriteStatsToJson(this);

  /// Factory pour stats vides
  factory FavoriteStats.empty() {
    return const FavoriteStats(
      totalFavorites: 0,
      highPriorityCount: 0,
      mediumPriorityCount: 0,
      lowPriorityCount: 0,
      topTags: [],
      mostFavoritedTattooistId: null,
      lastAddedAt: null,
    );
  }

  /// Pourcentage par priorité
  double get highPriorityPercentage {
    if (totalFavorites == 0) return 0.0;
    return (highPriorityCount / totalFavorites) * 100;
  }

  double get mediumPriorityPercentage {
    if (totalFavorites == 0) return 0.0;
    return (mediumPriorityCount / totalFavorites) * 100;
  }

  double get lowPriorityPercentage {
    if (totalFavorites == 0) return 0.0;
    return (lowPriorityCount / totalFavorites) * 100;
  }

  /// Tag le plus utilisé
  String? get topTag => topTags.isNotEmpty ? topTags.first : null;

  FavoriteStats copyWith({
    int? totalFavorites,
    int? highPriorityCount,
    int? mediumPriorityCount,
    int? lowPriorityCount,
    List<String>? topTags,
    String? mostFavoritedTattooistId,
    DateTime? lastAddedAt,
  }) {
    return FavoriteStats(
      totalFavorites: totalFavorites ?? this.totalFavorites,
      highPriorityCount: highPriorityCount ?? this.highPriorityCount,
      mediumPriorityCount: mediumPriorityCount ?? this.mediumPriorityCount,
      lowPriorityCount: lowPriorityCount ?? this.lowPriorityCount,
      topTags: topTags ?? this.topTags,
      mostFavoritedTattooistId: mostFavoritedTattooistId ?? this.mostFavoritedTattooistId,
      lastAddedAt: lastAddedAt ?? this.lastAddedAt,
    );
  }
}

/// 🏷️ Collection de tags prédéfinis pour favoris
class FavoriteTags {
  static const List<String> suggested = [
    'Réalisme',
    'Traditionnel',
    'Japonais',
    'Géométrique',
    'Minimaliste',
    'Portrait',
    'Couleur',
    'Noir et gris',
    'Fine line',
    'Aquarelle',
    'Projet en cours',
    'Futur projet',
    'Style unique',
    'Tarifs corrects',
    'Bon contact',
    'Recommandé',
    'Portfolio impressionnant',
    'Disponible',
    'Proche de chez moi',
    'Expérimenté',
  ];

  static List<String> search(String query) {
    return suggested
        .where((tag) => tag.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Suggestions basées sur des mots-clés
  static List<String> getSuggestionsFor(String style) {
    final Map<String, List<String>> styleTags = {
      'réalisme': ['Réalisme', 'Portrait', 'Détaillé', 'Précis'],
      'traditionnel': ['Traditionnel', 'Old school', 'Couleur', 'Classique'],
      'japonais': ['Japonais', 'Traditional japonais', 'Irezumi', 'Couleur'],
      'géométrique': ['Géométrique', 'Précis', 'Minimaliste', 'Moderne'],
      'minimaliste': ['Minimaliste', 'Fine line', 'Délicat', 'Moderne'],
    };

    final lowerStyle = style.toLowerCase();
    return styleTags.entries
        .where((entry) => lowerStyle.contains(entry.key))
        .expand((entry) => entry.value)
        .toSet()
        .toList();
  }
}

/// 🔍 Modèle pour la recherche dans les favoris
@JsonSerializable()
class FavoriteSearchFilters {
  final FavoritePriority? priority;
  final List<String> tags;
  final DateTime? addedAfter;
  final DateTime? addedBefore;
  final bool? hasNotes;
  final String? textQuery;

  const FavoriteSearchFilters({
    this.priority,
    this.tags = const [],
    this.addedAfter,
    this.addedBefore,
    this.hasNotes,
    this.textQuery,
  });

  factory FavoriteSearchFilters.fromJson(Map<String, dynamic> json) => _$FavoriteSearchFiltersFromJson(json);
  Map<String, dynamic> toJson() => _$FavoriteSearchFiltersToJson(this);

  /// Factory pour filtres vides
  factory FavoriteSearchFilters.empty() {
    return const FavoriteSearchFilters();
  }

  /// Check si des filtres sont appliqués
  bool get hasFilters {
    return priority != null ||
           tags.isNotEmpty ||
           addedAfter != null ||
           addedBefore != null ||
           hasNotes != null ||
           (textQuery != null && textQuery!.isNotEmpty);
  }

  /// Applique les filtres à une liste de favoris
  List<Favorite> applyTo(List<Favorite> favorites) {
    var filtered = favorites;

    if (priority != null) {
      filtered = filtered.where((f) => f.priority == priority).toList();
    }

    if (tags.isNotEmpty) {
      filtered = filtered.where((f) => 
        tags.any((tag) => f.tags.contains(tag))
      ).toList();
    }

    if (addedAfter != null) {
      filtered = filtered.where((f) => f.addedAt.isAfter(addedAfter!)).toList();
    }

    if (addedBefore != null) {
      filtered = filtered.where((f) => f.addedAt.isBefore(addedBefore!)).toList();
    }

    if (hasNotes != null) {
      filtered = filtered.where((f) => f.hasNotes == hasNotes).toList();
    }

    if (textQuery != null && textQuery!.isNotEmpty) {
      final query = textQuery!.toLowerCase();
      filtered = filtered.where((f) =>
        (f.notes?.toLowerCase().contains(query) ?? false) ||
        f.tags.any((tag) => tag.toLowerCase().contains(query))
      ).toList();
    }

    return filtered;
  }

  FavoriteSearchFilters copyWith({
    FavoritePriority? priority,
    List<String>? tags,
    DateTime? addedAfter,
    DateTime? addedBefore,
    bool? hasNotes,
    String? textQuery,
  }) {
    return FavoriteSearchFilters(
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      addedAfter: addedAfter ?? this.addedAfter,
      addedBefore: addedBefore ?? this.addedBefore,
      hasNotes: hasNotes ?? this.hasNotes,
      textQuery: textQuery ?? this.textQuery,
    );
  }
}

/// 🏷️ Extensions utilitaires
extension FavoriteListExtensions on List<Favorite> {
  /// Filtrer par priorité
  List<Favorite> filterByPriority(FavoritePriority priority) {
    return where((favorite) => favorite.priority == priority).toList();
  }

  /// Filtrer par tag
  List<Favorite> filterByTag(String tag) {
    return where((favorite) => 
      favorite.tags.any((t) => 
        t.toLowerCase().contains(tag.toLowerCase())
      )
    ).toList();
  }

  /// Filtrer par tatoueur
  List<Favorite> filterByTattooistId(String tattooistId) {
    return where((favorite) => favorite.tattooistId == tattooistId).toList();
  }

  /// Filtrer par shop
  List<Favorite> filterByShopId(String shopId) {
    return where((favorite) => favorite.shopId == shopId).toList();
  }

  /// Filtrer avec notes
  List<Favorite> get withNotes {
    return where((favorite) => favorite.hasNotes).toList();
  }

  /// Filtrer sans notes
  List<Favorite> get withoutNotes {
    return where((favorite) => !favorite.hasNotes).toList();
  }

  /// Trier par priorité (haute en premier)
  List<Favorite> sortByPriority() {
    final sorted = List<Favorite>.from(this);
    sorted.sort((a, b) => a.priority.value.compareTo(b.priority.value));
    return sorted;
  }

  /// Trier par date d'ajout (plus récent en premier)
  List<Favorite> sortByDate() {
    final sorted = List<Favorite>.from(this);
    sorted.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted;
  }

  /// Favoris haute priorité
  List<Favorite> get highPriority {
    return filterByPriority(FavoritePriority.high);
  }

  /// Favoris priorité moyenne
  List<Favorite> get mediumPriority {
    return filterByPriority(FavoritePriority.medium);
  }

  /// Favoris priorité basse
  List<Favorite> get lowPriority {
    return filterByPriority(FavoritePriority.low);
  }

  /// Grouper par priorité
  Map<FavoritePriority, List<Favorite>> groupByPriority() {
    final Map<FavoritePriority, List<Favorite>> grouped = {};
    for (final favorite in this) {
      grouped.putIfAbsent(favorite.priority, () => []).add(favorite);
    }
    return grouped;
  }

  /// Grouper par tags
  Map<String, List<Favorite>> groupByTags() {
    final Map<String, List<Favorite>> grouped = {};
    for (final favorite in this) {
      for (final tag in favorite.tags) {
        grouped.putIfAbsent(tag, () => []).add(favorite);
      }
    }
    return grouped;
  }

  /// Tous les tags utilisés
  List<String> get allTags {
    final Set<String> allTags = {};
    for (final favorite in this) {
      allTags.addAll(favorite.tags);
    }
    return allTags.toList()..sort();
  }

  /// Tags les plus utilisés
  List<String> getTopTags({int limit = 10}) {
    final Map<String, int> tagCounts = {};
    for (final favorite in this) {
      for (final tag in favorite.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  /// Recherche textuelle
  List<Favorite> searchText(String query) {
    final lowerQuery = query.toLowerCase();
    return where((favorite) =>
        (favorite.notes?.toLowerCase().contains(lowerQuery) ?? false) ||
        favorite.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  /// Statistiques des favoris
  FavoriteStats get stats {
    final total = length;
    final high = highPriority.length;
    final medium = mediumPriority.length;
    final low = lowPriority.length;
    final topTags = getTopTags(limit: 5);
    
    final tattooistCounts = <String, int>{};
    for (final favorite in this) {
      tattooistCounts[favorite.tattooistId] = 
          (tattooistCounts[favorite.tattooistId] ?? 0) + 1;
    }
    
    final mostFavorited = tattooistCounts.entries
        .where((entry) => entry.value > 0)
        .fold<MapEntry<String, int>?>(null, (prev, curr) => 
            prev == null || curr.value > prev.value ? curr : prev)
        ?.key;

    final lastAdded = isNotEmpty 
        ? sortByDate().first.addedAt 
        : null;

    return FavoriteStats(
      totalFavorites: total,
      highPriorityCount: high,
      mediumPriorityCount: medium,
      lowPriorityCount: low,
      topTags: topTags,
      mostFavoritedTattooistId: mostFavorited,
      lastAddedAt: lastAdded,
    );
  }

  /// Favoris récents (dernière semaine)
  List<Favorite> get recent {
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    return where((favorite) => favorite.addedAt.isAfter(oneWeekAgo)).toList();
  }

  /// Favoris anciens (plus de 6 mois)
  List<Favorite> get old {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    return where((favorite) => favorite.addedAt.isBefore(sixMonthsAgo)).toList();
  }
}