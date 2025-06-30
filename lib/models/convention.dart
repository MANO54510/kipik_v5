// lib/models/convention.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Convention {
  final String id;
  final String title;
  final String location;
  final String description;
  final String? website;
  final DateTime start;
  final DateTime end;
  final bool isPremium;
  final bool isOpen;
  final String imageUrl;
  final List<String>? artists;

  // Ajout des coordonnées géographiques
  final double? latitude;
  final double? longitude;
 
  // Champs supplémentaires pour l'interface organisateur
  final int? proSpots;
  final int? merchandiseSpots;
  final double? dayTicketPrice;
  final double? weekendTicketPrice;
  final List<String>? events;
 
  Convention({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    this.website,
    required this.start,
    required this.end,
    required this.isPremium,
    required this.isOpen,
    required this.imageUrl,
    this.artists,
    this.latitude,
    this.longitude,
    this.proSpots,
    this.merchandiseSpots,
    this.dayTicketPrice,
    this.weekendTicketPrice,
    this.events,
  });
 
  // Factory pour créer une Convention à partir d'un Map (à adapter pour Firestore plus tard)
  factory Convention.fromJson(Map<String, dynamic> json) {
    return Convention(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      description: json['description'] as String,
      website: json['website'] as String?,
      // Utiliser des DateTime directement pour l'instant
      start: json['start'] is DateTime
           ? json['start'] as DateTime
           : DateTime.parse(json['start'].toString()),
      end: json['end'] is DateTime
           ? json['end'] as DateTime
           : DateTime.parse(json['end'].toString()),
      isPremium: json['isPremium'] as bool,
      isOpen: json['isOpen'] as bool,
      imageUrl: json['imageUrl'] as String,
      artists: (json['artists'] as List?)?.map((e) => e as String).toList(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      proSpots: json['proSpots'] as int?,
      merchandiseSpots: json['merchandiseSpots'] as int?,
      dayTicketPrice: (json['dayTicketPrice'] as num?)?.toDouble(),
      weekendTicketPrice: (json['weekendTicketPrice'] as num?)?.toDouble(),
      events: (json['events'] as List?)?.map((e) => e as String).toList(),
    );
  }

  // ✅ AJOUTÉ: Factory pour créer depuis Firestore
  factory Convention.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Convention(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      website: data['website'],
      start: (data['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      end: (data['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPremium: data['isPremium'] ?? false,
      isOpen: data['isOpen'] ?? true,
      imageUrl: data['imageUrl'] ?? '',
      artists: data['artists'] != null ? List<String>.from(data['artists']) : null,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      proSpots: data['proSpots'] as int?,
      merchandiseSpots: data['merchandiseSpots'] as int?,
      dayTicketPrice: (data['dayTicketPrice'] as num?)?.toDouble(),
      weekendTicketPrice: (data['weekendTicketPrice'] as num?)?.toDouble(),
      events: data['events'] != null ? List<String>.from(data['events']) : null,
    );
  }
 
  // Méthode pour convertir la Convention en Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'description': description,
      if (website != null) 'website': website,
      'start': start.toIso8601String(), // Stocker les dates comme des chaînes ISO
      'end': end.toIso8601String(),
      'isPremium': isPremium,
      'isOpen': isOpen,
      'imageUrl': imageUrl,
      if (artists != null) 'artists': artists,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (proSpots != null) 'proSpots': proSpots,
      if (merchandiseSpots != null) 'merchandiseSpots': merchandiseSpots,
      if (dayTicketPrice != null) 'dayTicketPrice': dayTicketPrice,
      if (weekendTicketPrice != null) 'weekendTicketPrice': weekendTicketPrice,
      if (events != null) 'events': events,
    };
  }

  // ✅ AJOUTÉ: Méthode pour convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'location': location,
      'description': description,
      'website': website,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'isPremium': isPremium,
      'isOpen': isOpen,
      'imageUrl': imageUrl,
      'artists': artists,
      'latitude': latitude,
      'longitude': longitude,
      'proSpots': proSpots,
      'merchandiseSpots': merchandiseSpots,
      'dayTicketPrice': dayTicketPrice,
      'weekendTicketPrice': weekendTicketPrice,
      'events': events,
    };
  }

  // ✅ AJOUTÉ: Méthode copyWith pour faciliter les modifications
  Convention copyWith({
    String? id,
    String? title,
    String? location,
    String? description,
    String? website,
    DateTime? start,
    DateTime? end,
    bool? isPremium,
    bool? isOpen,
    String? imageUrl,
    List<String>? artists,
    double? latitude,
    double? longitude,
    int? proSpots,
    int? merchandiseSpots,
    double? dayTicketPrice,
    double? weekendTicketPrice,
    List<String>? events,
  }) {
    return Convention(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      description: description ?? this.description,
      website: website ?? this.website,
      start: start ?? this.start,
      end: end ?? this.end,
      isPremium: isPremium ?? this.isPremium,
      isOpen: isOpen ?? this.isOpen,
      imageUrl: imageUrl ?? this.imageUrl,
      artists: artists ?? this.artists,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      proSpots: proSpots ?? this.proSpots,
      merchandiseSpots: merchandiseSpots ?? this.merchandiseSpots,
      dayTicketPrice: dayTicketPrice ?? this.dayTicketPrice,
      weekendTicketPrice: weekendTicketPrice ?? this.weekendTicketPrice,
      events: events ?? this.events,
    );
  }

  // ✅ AJOUTÉ: Getters utiles
  bool get isUpcoming => start.isAfter(DateTime.now());
  bool get isActive => isOpen && isUpcoming;
  
  String get formattedDate {
    return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';
  }
  
  String get formattedDateRange {
    if (start.day == end.day && start.month == end.month && start.year == end.year) {
      return formattedDate;
    }
    return '$formattedDate - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
  }
  
  String get formattedPrice {
    if (dayTicketPrice != null && weekendTicketPrice != null) {
      return '${dayTicketPrice!.toStringAsFixed(0)}€ - ${weekendTicketPrice!.toStringAsFixed(0)}€';
    } else if (dayTicketPrice != null) {
      return '${dayTicketPrice!.toStringAsFixed(0)}€';
    } else if (weekendTicketPrice != null) {
      return '${weekendTicketPrice!.toStringAsFixed(0)}€';
    }
    return 'Gratuit';
  }
}