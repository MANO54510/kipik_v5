// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Favorite _$FavoriteFromJson(Map<String, dynamic> json) => Favorite(
  id: json['id'] as String,
  userId: json['userId'] as String,
  tattooistId: json['tattooistId'] as String,
  shopId: json['shopId'] as String?,
  addedAt: DateTime.parse(json['addedAt'] as String),
  notes: json['notes'] as String?,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  priority: $enumDecode(_$FavoritePriorityEnumMap, json['priority']),
);

Map<String, dynamic> _$FavoriteToJson(Favorite instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'tattooistId': instance.tattooistId,
  'shopId': instance.shopId,
  'addedAt': instance.addedAt.toIso8601String(),
  'notes': instance.notes,
  'tags': instance.tags,
  'priority': _$FavoritePriorityEnumMap[instance.priority]!,
};

const _$FavoritePriorityEnumMap = {
  FavoritePriority.high: 1,
  FavoritePriority.medium: 2,
  FavoritePriority.low: 3,
};

FavoriteStats _$FavoriteStatsFromJson(Map<String, dynamic> json) =>
    FavoriteStats(
      totalFavorites: (json['totalFavorites'] as num).toInt(),
      highPriorityCount: (json['highPriorityCount'] as num).toInt(),
      mediumPriorityCount: (json['mediumPriorityCount'] as num).toInt(),
      lowPriorityCount: (json['lowPriorityCount'] as num).toInt(),
      topTags:
          (json['topTags'] as List<dynamic>).map((e) => e as String).toList(),
      mostFavoritedTattooistId: json['mostFavoritedTattooistId'] as String?,
      lastAddedAt:
          json['lastAddedAt'] == null
              ? null
              : DateTime.parse(json['lastAddedAt'] as String),
    );

Map<String, dynamic> _$FavoriteStatsToJson(FavoriteStats instance) =>
    <String, dynamic>{
      'totalFavorites': instance.totalFavorites,
      'highPriorityCount': instance.highPriorityCount,
      'mediumPriorityCount': instance.mediumPriorityCount,
      'lowPriorityCount': instance.lowPriorityCount,
      'topTags': instance.topTags,
      'mostFavoritedTattooistId': instance.mostFavoritedTattooistId,
      'lastAddedAt': instance.lastAddedAt?.toIso8601String(),
    };

FavoriteSearchFilters _$FavoriteSearchFiltersFromJson(
  Map<String, dynamic> json,
) => FavoriteSearchFilters(
  priority: $enumDecodeNullable(_$FavoritePriorityEnumMap, json['priority']),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  addedAfter:
      json['addedAfter'] == null
          ? null
          : DateTime.parse(json['addedAfter'] as String),
  addedBefore:
      json['addedBefore'] == null
          ? null
          : DateTime.parse(json['addedBefore'] as String),
  hasNotes: json['hasNotes'] as bool?,
  textQuery: json['textQuery'] as String?,
);

Map<String, dynamic> _$FavoriteSearchFiltersToJson(
  FavoriteSearchFilters instance,
) => <String, dynamic>{
  'priority': _$FavoritePriorityEnumMap[instance.priority],
  'tags': instance.tags,
  'addedAfter': instance.addedAfter?.toIso8601String(),
  'addedBefore': instance.addedBefore?.toIso8601String(),
  'hasNotes': instance.hasNotes,
  'textQuery': instance.textQuery,
};
