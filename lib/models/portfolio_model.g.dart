// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Portfolio _$PortfolioFromJson(Map<String, dynamic> json) => Portfolio(
  id: json['id'] as String,
  tattooistId: json['tattooistId'] as String,
  shopId: json['shopId'] as String?,
  title: json['title'] as String,
  description: json['description'] as String?,
  images:
      (json['images'] as List<dynamic>)
          .map((e) => PortfolioImage.fromJson(e as Map<String, dynamic>))
          .toList(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  category: json['category'] as String,
  style: json['style'] as String,
  bodyPart: json['bodyPart'] as String,
  duration: (json['duration'] as num?)?.toInt(),
  size:
      json['size'] == null
          ? null
          : PortfolioSize.fromJson(json['size'] as Map<String, dynamic>),
  settings: PortfolioSettings.fromJson(
    json['settings'] as Map<String, dynamic>,
  ),
  stats:
      json['stats'] == null
          ? null
          : PortfolioStats.fromJson(json['stats'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PortfolioToJson(Portfolio instance) => <String, dynamic>{
  'id': instance.id,
  'tattooistId': instance.tattooistId,
  'shopId': instance.shopId,
  'title': instance.title,
  'description': instance.description,
  'images': instance.images,
  'tags': instance.tags,
  'category': instance.category,
  'style': instance.style,
  'bodyPart': instance.bodyPart,
  'duration': instance.duration,
  'size': instance.size,
  'settings': instance.settings,
  'stats': instance.stats,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

PortfolioImage _$PortfolioImageFromJson(Map<String, dynamic> json) =>
    PortfolioImage(
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      order: (json['order'] as num).toInt(),
      caption: json['caption'] as String?,
      alt: json['alt'] as String?,
    );

Map<String, dynamic> _$PortfolioImageToJson(PortfolioImage instance) =>
    <String, dynamic>{
      'url': instance.url,
      'thumbnailUrl': instance.thumbnailUrl,
      'order': instance.order,
      'caption': instance.caption,
      'alt': instance.alt,
    };

PortfolioSize _$PortfolioSizeFromJson(Map<String, dynamic> json) =>
    PortfolioSize(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$PortfolioSizeToJson(PortfolioSize instance) =>
    <String, dynamic>{'width': instance.width, 'height': instance.height};

PortfolioSettings _$PortfolioSettingsFromJson(Map<String, dynamic> json) =>
    PortfolioSettings(
      isPublic: json['isPublic'] as bool,
      allowComments: json['allowComments'] as bool,
      isFeatured: json['isFeatured'] as bool,
    );

Map<String, dynamic> _$PortfolioSettingsToJson(PortfolioSettings instance) =>
    <String, dynamic>{
      'isPublic': instance.isPublic,
      'allowComments': instance.allowComments,
      'isFeatured': instance.isFeatured,
    };

PortfolioStats _$PortfolioStatsFromJson(Map<String, dynamic> json) =>
    PortfolioStats(
      views: (json['views'] as num).toInt(),
      likes: (json['likes'] as num).toInt(),
      shares: (json['shares'] as num).toInt(),
    );

Map<String, dynamic> _$PortfolioStatsToJson(PortfolioStats instance) =>
    <String, dynamic>{
      'views': instance.views,
      'likes': instance.likes,
      'shares': instance.shares,
    };
