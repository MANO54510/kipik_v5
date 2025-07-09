// lib/models/shop_model.dart - VERSION MANUELLE (sans build_runner)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 🏪 Modèle pour les boutiques de tatoueurs
/// Visible par clients (recherche) et organisateurs (validation)
class Shop {
  final String id;
  final String tattooistId; // Propriétaire du shop
  final String name;
  final String? description;
  final ShopAddress address;
  final ShopContact? contact;
  final List<String> specialties;
  final List<ShopService> services;
  final ShopSchedule schedule;
  final ShopSettings settings;
  final ShopStats? stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Shop({
    required this.id,
    required this.tattooistId,
    required this.name,
    this.description,
    required this.address,
    this.contact,
    required this.specialties,
    required this.services,
    required this.schedule,
    required this.settings,
    this.stats,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory pour création depuis Firestore
  factory Shop.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Shop.fromJson({
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

  /// JSON serialization MANUELLE
  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      tattooistId: json['tattooistId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: ShopAddress.fromJson(json['address'] as Map<String, dynamic>),
      contact: json['contact'] != null 
          ? ShopContact.fromJson(json['contact'] as Map<String, dynamic>) 
          : null,
      specialties: List<String>.from(json['specialties'] as List),
      services: (json['services'] as List)
          .map((e) => ShopService.fromJson(e as Map<String, dynamic>))
          .toList(),
      schedule: ShopSchedule.fromJson(json['schedule'] as Map<String, dynamic>),
      settings: ShopSettings.fromJson(json['settings'] as Map<String, dynamic>),
      stats: json['stats'] != null 
          ? ShopStats.fromJson(json['stats'] as Map<String, dynamic>) 
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tattooistId': tattooistId,
      'name': name,
      'description': description,
      'address': address.toJson(),
      'contact': contact?.toJson(),
      'specialties': specialties,
      'services': services.map((e) => e.toJson()).toList(),
      'schedule': schedule.toJson(),
      'settings': settings.toJson(),
      'stats': stats?.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with pour immutabilité
  Shop copyWith({
    String? id,
    String? tattooistId,
    String? name,
    String? description,
    ShopAddress? address,
    ShopContact? contact,
    List<String>? specialties,
    List<ShopService>? services,
    ShopSchedule? schedule,
    ShopSettings? settings,
    ShopStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      tattooistId: tattooistId ?? this.tattooistId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      specialties: specialties ?? this.specialties,
      services: services ?? this.services,
      schedule: schedule ?? this.schedule,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Getters utilitaires
  bool get isPublic => settings.isPublic;
  bool get acceptsWalkIns => settings.acceptsWalkIns;
  bool get allowsBooking => settings.allowsBooking;
  bool get allowsGuests => settings.allowsGuests; // Premium feature
  
  /// Validation business
  bool get isComplete {
    return name.isNotEmpty &&
           specialties.isNotEmpty &&
           services.isNotEmpty &&
           address.isComplete;
  }

  /// Note moyenne calculée
  double get averageRating => stats?.rating ?? 0.0;
  int get totalReviews => stats?.reviewCount ?? 0;
  
  @override
  String toString() => 'Shop(id: $id, name: $name, tattooistId: $tattooistId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shop && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 📍 Adresse du shop
class ShopAddress {
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final ShopCoordinates? coordinates;

  const ShopAddress({
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    this.coordinates,
  });

  factory ShopAddress.fromJson(Map<String, dynamic> json) {
    return ShopAddress(
      street: json['street'] as String,
      city: json['city'] as String,
      postalCode: json['postalCode'] as String,
      country: json['country'] as String,
      coordinates: json['coordinates'] != null 
          ? ShopCoordinates.fromJson(json['coordinates'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'coordinates': coordinates?.toJson(),
    };
  }

  /// Adresse complète formatée
  String get fullAddress => '$street, $postalCode $city, $country';
  
  /// Validation de complétude
  bool get isComplete {
    return street.isNotEmpty &&
           city.isNotEmpty &&
           postalCode.isNotEmpty &&
           country.isNotEmpty;
  }

  ShopAddress copyWith({
    String? street,
    String? city,
    String? postalCode,
    String? country,
    ShopCoordinates? coordinates,
  }) {
    return ShopAddress(
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

/// 🗺️ Coordonnées GPS
class ShopCoordinates {
  final double latitude;
  final double longitude;

  const ShopCoordinates({
    required this.latitude,
    required this.longitude,
  });

  factory ShopCoordinates.fromJson(Map<String, dynamic> json) {
    return ShopCoordinates(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  ShopCoordinates copyWith({
    double? latitude,
    double? longitude,
  }) {
    return ShopCoordinates(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// 📞 Contact du shop
class ShopContact {
  final String? phone;
  final String? email;
  final String? website;
  final ShopSocialMedia? socialMedia;

  const ShopContact({
    this.phone,
    this.email,
    this.website,
    this.socialMedia,
  });

  factory ShopContact.fromJson(Map<String, dynamic> json) {
    return ShopContact(
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      socialMedia: json['socialMedia'] != null 
          ? ShopSocialMedia.fromJson(json['socialMedia'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'website': website,
      'socialMedia': socialMedia?.toJson(),
    };
  }

  ShopContact copyWith({
    String? phone,
    String? email,
    String? website,
    ShopSocialMedia? socialMedia,
  }) {
    return ShopContact(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      socialMedia: socialMedia ?? this.socialMedia,
    );
  }
}

/// 📱 Réseaux sociaux
class ShopSocialMedia {
  final String? instagram;
  final String? facebook;
  final String? tiktok;
  final String? youtube;

  const ShopSocialMedia({
    this.instagram,
    this.facebook,
    this.tiktok,
    this.youtube,
  });

  factory ShopSocialMedia.fromJson(Map<String, dynamic> json) {
    return ShopSocialMedia(
      instagram: json['instagram'] as String?,
      facebook: json['facebook'] as String?,
      tiktok: json['tiktok'] as String?,
      youtube: json['youtube'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instagram': instagram,
      'facebook': facebook,
      'tiktok': tiktok,
      'youtube': youtube,
    };
  }

  ShopSocialMedia copyWith({
    String? instagram,
    String? facebook,
    String? tiktok,
    String? youtube,
  }) {
    return ShopSocialMedia(
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      tiktok: tiktok ?? this.tiktok,
      youtube: youtube ?? this.youtube,
    );
  }
}

/// 💼 Service proposé par le shop
class ShopService {
  final String name;
  final String? description;
  final ShopPriceRange priceRange;

  const ShopService({
    required this.name,
    this.description,
    required this.priceRange,
  });

  factory ShopService.fromJson(Map<String, dynamic> json) {
    return ShopService(
      name: json['name'] as String,
      description: json['description'] as String?,
      priceRange: ShopPriceRange.fromJson(json['priceRange'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'priceRange': priceRange.toJson(),
    };
  }

  ShopService copyWith({
    String? name,
    String? description,
    ShopPriceRange? priceRange,
  }) {
    return ShopService(
      name: name ?? this.name,
      description: description ?? this.description,
      priceRange: priceRange ?? this.priceRange,
    );
  }
}

/// 💰 Fourchette de prix
class ShopPriceRange {
  final int min;
  final int max;
  final PriceUnit unit;

  const ShopPriceRange({
    required this.min,
    required this.max,
    required this.unit,
  });

  factory ShopPriceRange.fromJson(Map<String, dynamic> json) {
    return ShopPriceRange(
      min: json['min'] as int,
      max: json['max'] as int,
      unit: PriceUnit.values.firstWhere(
        (e) => e.name == json['unit'],
        orElse: () => PriceUnit.hour,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'unit': unit.name,
    };
  }

  /// Formatage du prix
  String get formattedRange {
    final unitText = unit.displayName;
    if (min == max) {
      return '$min€/$unitText';
    }
    return '$min€ - $max€/$unitText';
  }

  ShopPriceRange copyWith({
    int? min,
    int? max,
    PriceUnit? unit,
  }) {
    return ShopPriceRange(
      min: min ?? this.min,
      max: max ?? this.max,
      unit: unit ?? this.unit,
    );
  }
}

/// 📅 Planning du shop - VERSION SIMPLIFIÉE
class ShopSchedule {
  final Map<String, ShopDaySchedule> days;

  const ShopSchedule({required this.days});

  factory ShopSchedule.fromJson(Map<String, dynamic> json) {
    final Map<String, ShopDaySchedule> days = {};
    json.forEach((key, value) {
      days[key] = ShopDaySchedule.fromJson(value as Map<String, dynamic>);
    });
    return ShopSchedule(days: days);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    days.forEach((key, value) {
      json[key] = value.toJson();
    });
    return json;
  }

  /// Get schedule for specific day
  ShopDaySchedule? getDaySchedule(String day) => days[day];

  /// Factory pour créer un planning standard
  factory ShopSchedule.standard() {
    const standardDay = ShopDaySchedule(
      open: '09:00',
      close: '18:00',
      closed: false,
    );
    const sunday = ShopDaySchedule(
      open: '00:00',
      close: '00:00',
      closed: true,
    );
    
    return ShopSchedule(days: {
      'monday': standardDay,
      'tuesday': standardDay,
      'wednesday': standardDay,
      'thursday': standardDay,
      'friday': standardDay,
      'saturday': standardDay,
      'sunday': sunday,
    });
  }
}

/// 📅 Planning d'une journée
class ShopDaySchedule {
  final String open;
  final String close;
  final bool closed;

  const ShopDaySchedule({
    required this.open,
    required this.close,
    required this.closed,
  });

  factory ShopDaySchedule.fromJson(Map<String, dynamic> json) {
    return ShopDaySchedule(
      open: json['open'] as String,
      close: json['close'] as String,
      closed: json['closed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'close': close,
      'closed': closed,
    };
  }

  /// Formatage des heures
  String get formattedHours {
    if (closed) return 'Fermé';
    return '$open - $close';
  }
}

/// ⚙️ Paramètres du shop
class ShopSettings {
  final bool isPublic;
  final bool acceptsWalkIns;
  final bool allowsBooking;
  final bool allowsGuests; // Premium feature
  final int? maxGuestsPerMonth; // Premium feature

  const ShopSettings({
    required this.isPublic,
    required this.acceptsWalkIns,
    required this.allowsBooking,
    required this.allowsGuests,
    this.maxGuestsPerMonth,
  });

  factory ShopSettings.fromJson(Map<String, dynamic> json) {
    return ShopSettings(
      isPublic: json['isPublic'] as bool,
      acceptsWalkIns: json['acceptsWalkIns'] as bool,
      allowsBooking: json['allowsBooking'] as bool,
      allowsGuests: json['allowsGuests'] as bool,
      maxGuestsPerMonth: json['maxGuestsPerMonth'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPublic': isPublic,
      'acceptsWalkIns': acceptsWalkIns,
      'allowsBooking': allowsBooking,
      'allowsGuests': allowsGuests,
      'maxGuestsPerMonth': maxGuestsPerMonth,
    };
  }

  /// Factory pour settings par défaut
  factory ShopSettings.defaultSettings() {
    return const ShopSettings(
      isPublic: true,
      acceptsWalkIns: false,
      allowsBooking: true,
      allowsGuests: false, // Nécessite Premium
      maxGuestsPerMonth: null,
    );
  }

  ShopSettings copyWith({
    bool? isPublic,
    bool? acceptsWalkIns,
    bool? allowsBooking,
    bool? allowsGuests,
    int? maxGuestsPerMonth,
  }) {
    return ShopSettings(
      isPublic: isPublic ?? this.isPublic,
      acceptsWalkIns: acceptsWalkIns ?? this.acceptsWalkIns,
      allowsBooking: allowsBooking ?? this.allowsBooking,
      allowsGuests: allowsGuests ?? this.allowsGuests,
      maxGuestsPerMonth: maxGuestsPerMonth ?? this.maxGuestsPerMonth,
    );
  }
}

/// 📊 Statistiques du shop
class ShopStats {
  final int totalTattoos;
  final double rating;
  final int reviewCount;

  const ShopStats({
    required this.totalTattoos,
    required this.rating,
    required this.reviewCount,
  });

  factory ShopStats.fromJson(Map<String, dynamic> json) {
    return ShopStats(
      totalTattoos: json['totalTattoos'] as int,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTattoos': totalTattoos,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  /// Factory pour stats vides
  factory ShopStats.empty() {
    return const ShopStats(
      totalTattoos: 0,
      rating: 0.0,
      reviewCount: 0,
    );
  }

  /// Formatage de la note
  String get formattedRating => rating.toStringAsFixed(1);

  ShopStats copyWith({
    int? totalTattoos,
    double? rating,
    int? reviewCount,
  }) {
    return ShopStats(
      totalTattoos: totalTattoos ?? this.totalTattoos,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

/// 💰 Unités de prix
enum PriceUnit {
  hour,
  session,
  piece,
  day;

  String get displayName {
    switch (this) {
      case PriceUnit.hour:
        return 'h';
      case PriceUnit.session:
        return 'séance';
      case PriceUnit.piece:
        return 'pièce';
      case PriceUnit.day:
        return 'jour';
    }
  }
}