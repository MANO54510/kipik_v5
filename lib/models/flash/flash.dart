// lib/models/flash/flash.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle Flash pour le système de tatouages flash - VERSION CORRIGÉE
class Flash {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> additionalImages; // ✅ Typé correctement
  final String tattooArtistId;
  final String tattooArtistName; // ✅ Ajouté
  final String studioName;
  final String style;
  final String size;
  final String sizeDescription;
  final double price;
  final double? discountedPrice;
  final String? priceNote;
  final List<String> bodyPlacements; // ✅ Typé correctement
  final List<String> colors; // ✅ Typé correctement
  final List<String> tags; // ✅ Typé correctement
  final List<DateTime> availableTimeSlots; // ✅ Typé correctement
  final FlashType flashType;
  final FlashStatus status;
  final bool isMinuteFlash;
  final DateTime? minuteFlashDeadline;
  final String? urgencyReason;
  final int likes;
  final int saves;
  final int views;
  final int bookingRequests;
  final bool isVerified;
  final bool isOriginalWork;
  final double qualityScore;
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Flash({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.additionalImages = const [],
    required this.tattooArtistId,
    required this.tattooArtistName, // ✅ Requis
    required this.studioName,
    required this.style,
    required this.size,
    required this.sizeDescription,
    required this.price,
    this.discountedPrice,
    this.priceNote,
    this.bodyPlacements = const [],
    this.colors = const [],
    this.tags = const [],
    this.availableTimeSlots = const [],
    this.flashType = FlashType.standard,
    this.status = FlashStatus.draft,
    this.isMinuteFlash = false,
    this.minuteFlashDeadline,
    this.urgencyReason,
    this.likes = 0,
    this.saves = 0,
    this.views = 0,
    this.bookingRequests = 0,
    this.isVerified = false,
    this.isOriginalWork = true,
    this.qualityScore = 0.0,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor depuis Firebase
  factory Flash.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>; // ✅ Typé correctement
    return Flash.fromMap(data, doc.id);
  }

  /// Factory constructor depuis Map
  factory Flash.fromMap(Map<String, dynamic> map, String id) { // ✅ Typé correctement
    return Flash(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      additionalImages: List<String>.from(map['additionalImages'] ?? []), // ✅ Cast explicite
      tattooArtistId: map['tattooArtistId'] ?? '',
      tattooArtistName: map['tattooArtistName'] ?? '', // ✅ Ajouté
      studioName: map['studioName'] ?? '',
      style: map['style'] ?? '',
      size: map['size'] ?? '',
      sizeDescription: map['sizeDescription'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      discountedPrice: map['discountedPrice']?.toDouble(),
      priceNote: map['priceNote'],
      bodyPlacements: List<String>.from(map['bodyPlacements'] ?? []), // ✅ Cast explicite
      colors: List<String>.from(map['colors'] ?? []), // ✅ Cast explicite
      tags: List<String>.from(map['tags'] ?? []), // ✅ Cast explicite
      availableTimeSlots: (map['availableTimeSlots'] as List<dynamic>? ?? [])
          .map((timestamp) => DateTime.parse(timestamp.toString()))
          .toList(),
      flashType: FlashType.values.firstWhere(
        (type) => type.name == (map['flashType'] ?? 'standard'),
        orElse: () => FlashType.standard,
      ),
      status: FlashStatus.values.firstWhere(
        (status) => status.name == (map['status'] ?? 'draft'),
        orElse: () => FlashStatus.draft,
      ),
      isMinuteFlash: map['isMinuteFlash'] ?? false,
      minuteFlashDeadline: map['minuteFlashDeadline'] != null
          ? DateTime.parse(map['minuteFlashDeadline'])
          : null,
      urgencyReason: map['urgencyReason'],
      likes: map['likes'] ?? 0,
      saves: map['saves'] ?? 0,
      views: map['views'] ?? 0,
      bookingRequests: map['bookingRequests'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      isOriginalWork: map['isOriginalWork'] ?? true,
      qualityScore: (map['qualityScore'] ?? 0.0).toDouble(),
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convertir en Map pour Firebase
  Map<String, dynamic> toMap() { // ✅ Typé correctement
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages,
      'tattooArtistId': tattooArtistId,
      'tattooArtistName': tattooArtistName, // ✅ Ajouté
      'studioName': studioName,
      'style': style,
      'size': size,
      'sizeDescription': sizeDescription,
      'price': price,
      'discountedPrice': discountedPrice,
      'priceNote': priceNote,
      'bodyPlacements': bodyPlacements,
      'colors': colors,
      'tags': tags,
      'availableTimeSlots': availableTimeSlots.map((date) => date.toIso8601String()).toList(),
      'flashType': flashType.name,
      'status': status.name,
      'isMinuteFlash': isMinuteFlash,
      'minuteFlashDeadline': minuteFlashDeadline?.toIso8601String(),
      'urgencyReason': urgencyReason,
      'likes': likes,
      'saves': saves,
      'views': views,
      'bookingRequests': bookingRequests,
      'isVerified': isVerified,
      'isOriginalWork': isOriginalWork,
      'qualityScore': qualityScore,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Calculer le prix effectif (avec réduction si applicable)
  double get effectivePrice => discountedPrice ?? price;

  /// Calculer le pourcentage de réduction
  double? get discountPercentage {
    if (discountedPrice == null) return null;
    return ((price - discountedPrice!) / price * 100);
  }

  /// Vérifier si le flash est disponible pour réservation
  bool get isBookable {
    return status == FlashStatus.published && 
           availableTimeSlots.isNotEmpty &&
           (!isMinuteFlash || (minuteFlashDeadline != null && DateTime.now().isBefore(minuteFlashDeadline!)));
  }

  /// Vérifier si le flash expire bientôt (Flash Minute)
  bool get isExpiringSoon {
    if (!isMinuteFlash || minuteFlashDeadline == null) return false;
    final timeLeft = minuteFlashDeadline!.difference(DateTime.now());
    return timeLeft.inHours <= 6;
  }

  /// Temps restant pour Flash Minute
  Duration? get timeRemaining {
    if (!isMinuteFlash || minuteFlashDeadline == null) return null;
    final remaining = minuteFlashDeadline!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Calculer la distance depuis une position
  double distanceFrom(double lat, double lon) {
    // Calcul simplifié de distance (Haversine formula pourrait être utilisée pour plus de précision)
    final deltaLat = (latitude - lat) * 111; // 1 degré ≈ 111 km
    final deltaLon = (longitude - lon) * 111 * 0.7; // Approximation pour les longitudes
    return (deltaLat * deltaLat + deltaLon * deltaLon).abs();
  }

  /// CopyWith pour modifications
  Flash copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? additionalImages,
    String? tattooArtistId,
    String? tattooArtistName,
    String? studioName,
    String? style,
    String? size,
    String? sizeDescription,
    double? price,
    double? discountedPrice,
    String? priceNote,
    List<String>? bodyPlacements,
    List<String>? colors,
    List<String>? tags,
    List<DateTime>? availableTimeSlots,
    FlashType? flashType,
    FlashStatus? status,
    bool? isMinuteFlash,
    DateTime? minuteFlashDeadline,
    String? urgencyReason,
    int? likes,
    int? saves,
    int? views,
    int? bookingRequests,
    bool? isVerified,
    bool? isOriginalWork,
    double? qualityScore,
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flash(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      tattooArtistId: tattooArtistId ?? this.tattooArtistId,
      tattooArtistName: tattooArtistName ?? this.tattooArtistName,
      studioName: studioName ?? this.studioName,
      style: style ?? this.style,
      size: size ?? this.size,
      sizeDescription: sizeDescription ?? this.sizeDescription,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      priceNote: priceNote ?? this.priceNote,
      bodyPlacements: bodyPlacements ?? this.bodyPlacements,
      colors: colors ?? this.colors,
      tags: tags ?? this.tags,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      flashType: flashType ?? this.flashType,
      status: status ?? this.status,
      isMinuteFlash: isMinuteFlash ?? this.isMinuteFlash,
      minuteFlashDeadline: minuteFlashDeadline ?? this.minuteFlashDeadline,
      urgencyReason: urgencyReason ?? this.urgencyReason,
      likes: likes ?? this.likes,
      saves: saves ?? this.saves,
      views: views ?? this.views,
      bookingRequests: bookingRequests ?? this.bookingRequests,
      isVerified: isVerified ?? this.isVerified,
      isOriginalWork: isOriginalWork ?? this.isOriginalWork,
      qualityScore: qualityScore ?? this.qualityScore,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Flash(id: $id, title: $title, price: $price, status: $status, isMinuteFlash: $isMinuteFlash)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Flash && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Types de flashs
enum FlashType {
  standard,    // Flash normal
  minute,      // Flash Minute (urgence)
  exclusive,   // Flash exclusif (unique)
  collab,      // Flash collaboration
  custom,      // Flash personnalisable
}

/// Statuts des flashs
enum FlashStatus {
  draft,       // Brouillon
  published,   // Publié et disponible
  reserved,    // Réservé par un client
  booked,      // RDV confirmé
  completed,   // Tatouage terminé
  withdrawn,   // Retiré par le tatoueur
  expired,     // Expiré (Flash Minute)
  rejected,    // Rejeté par modération
}

/// Extensions pour les enums
extension FlashTypeExtension on FlashType {
  String get displayName {
    switch (this) {
      case FlashType.standard:
        return 'Standard';
      case FlashType.minute:
        return 'Flash Minute';
      case FlashType.exclusive:
        return 'Exclusif';
      case FlashType.collab:
        return 'Collaboration';
      case FlashType.custom:
        return 'Personnalisable';
    }
  }

  String get description {
    switch (this) {
      case FlashType.standard:
        return 'Flash classique disponible';
      case FlashType.minute:
        return 'Offre last-minute à prix réduit';
      case FlashType.exclusive:
        return 'Design unique, une seule réalisation';
      case FlashType.collab:
        return 'Collaboration entre artistes';
      case FlashType.custom:
        return 'Adaptable selon vos souhaits';
    }
  }
}

extension FlashStatusExtension on FlashStatus {
  String get displayName {
    switch (this) {
      case FlashStatus.draft:
        return 'Brouillon';
      case FlashStatus.published:
        return 'Disponible';
      case FlashStatus.reserved:
        return 'Réservé';
      case FlashStatus.booked:
        return 'RDV Confirmé';
      case FlashStatus.completed:
        return 'Terminé';
      case FlashStatus.withdrawn:
        return 'Retiré';
      case FlashStatus.expired:
        return 'Expiré';
      case FlashStatus.rejected:
        return 'Rejeté';
    }
  }

  bool get isActive => this == FlashStatus.published;
  bool get isBooked => [FlashStatus.reserved, FlashStatus.booked].contains(this);
  bool get isFinished => [FlashStatus.completed, FlashStatus.withdrawn, FlashStatus.expired].contains(this);
}