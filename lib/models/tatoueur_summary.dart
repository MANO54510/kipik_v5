// lib/models/tatoueur_summary.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

/// Modèle léger pour afficher les tatoueurs dans les listes
/// Contient seulement les informations essentielles pour l'affichage
class TatoueurSummary {
  final String id;
  final String name;
  final String? displayName;
  final String avatarUrl;
  final String? studioName; // ✅ CORRIGÉ : Renommé de studio
  final String? style;
  final String location; // ✅ REQUIS
  final double? rating;
  final int? reviewsCount;
  final String availability; // ✅ REQUIS
  final double? distanceKm; // ✅ AJOUTÉ : Distance en kilomètres
  final double latitude; // ✅ AJOUTÉ : Coordonnées requises
  final double longitude; // ✅ AJOUTÉ : Coordonnées requises
  final bool isActive;
  final bool isVerified;
  final List<String> specialties;
  final String? instagram;
  final DateTime? createdAt;
  final DateTime? lastActive;

  const TatoueurSummary({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.location, // ✅ REQUIS
    required this.availability, // ✅ REQUIS
    required this.latitude, // ✅ AJOUTÉ
    required this.longitude, // ✅ AJOUTÉ
    this.displayName,
    this.studioName,
    this.style,
    this.rating,
    this.reviewsCount,
    this.distanceKm,
    this.isActive = true,
    this.isVerified = false,
    this.specialties = const [],
    this.instagram,
    this.createdAt,
    this.lastActive,
  });

  /// Factory pour créer depuis Firestore
  factory TatoueurSummary.fromFirestore(Map<String, dynamic> data, String id) {
    return TatoueurSummary(
      id: id,
      name: data['name'] ?? data['displayName'] ?? 'Tatoueur',
      displayName: data['displayName'],
      avatarUrl: data['profileImageUrl'] ?? data['avatar'] ?? 'assets/avatars/avatar_profil_pro.jpg',
      studioName: data['studio'] ?? data['studioName'],
      style: data['style'],
      location: data['location'] ?? data['city'] ?? 'Localisation inconnue',
      latitude: (data['latitude'] ?? data['lat'] ?? 48.8566).toDouble(),
      longitude: (data['longitude'] ?? data['lng'] ?? 2.3522).toDouble(),
      rating: (data['rating'] as num?)?.toDouble() ?? (data['note'] as num?)?.toDouble(),
      reviewsCount: data['reviewsCount'] as int? ?? data['reviews_count'] as int?,
      availability: data['availability'] ?? data['avail'] ?? 'Disponibilité inconnue',
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      isActive: data['isActive'] ?? true,
      isVerified: data['isVerified'] ?? false,
      specialties: _parseSpecialties(data['specialties'] ?? data['style']),
      instagram: data['instagram'],
      createdAt: data['createdAt']?.toDate(),
      lastActive: data['lastActive']?.toDate() ?? data['lastLoginAt']?.toDate(),
    );
  }

  /// Factory pour créer depuis les données démo/test
  factory TatoueurSummary.fromDemoData(Map<String, dynamic> data, String id) {
    return TatoueurSummary(
      id: id,
      name: data['name'] ?? 'Tatoueur Démo',
      displayName: data['displayName'] ?? data['name'],
      avatarUrl: data['avatar'] ?? data['profileImageUrl'] ?? 'assets/avatars/avatar_profil_pro.jpg',
      studioName: data['studio'] ?? data['studioName'],
      style: data['style'],
      location: data['location'] ?? 'Nancy, France',
      latitude: (data['latitude'] ?? data['lat'] ?? 48.6921).toDouble(),
      longitude: (data['longitude'] ?? data['lng'] ?? 6.1844).toDouble(),
      rating: (data['note'] as num?)?.toDouble() ?? (data['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: data['reviewsCount'] as int? ?? 100,
      availability: data['availability'] ?? data['avail'] ?? '2-3 semaines',
      distanceKm: (data['distance'] as num?)?.toDouble() ?? 2.5,
      isActive: data['isActive'] ?? true,
      isVerified: data['isVerified'] ?? true, // En démo, tous sont vérifiés
      specialties: _parseSpecialties(data['specialties'] ?? data['style']),
      instagram: data['instagram'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now().subtract(const Duration(days: 365)),
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  /// Parser les spécialités depuis différents formats
  static List<String> _parseSpecialties(dynamic specialties) {
    if (specialties == null) return [];
    
    if (specialties is List) {
      return specialties.map((s) => s.toString()).toList();
    } else if (specialties is String) {
      // Séparer par virgules ou tirets
      return specialties
          .split(RegExp(r'[,\-]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    return [];
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'displayName': displayName,
      'profileImageUrl': avatarUrl,
      'studioName': studioName,
      'style': style,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'availability': availability,
      'isActive': isActive,
      'isVerified': isVerified,
      'specialties': specialties,
      'instagram': instagram,
      'createdAt': createdAt,
      'lastActive': lastActive,
      'role': UserRole.tatoueur.value,
    };
  }

  /// Méthode copyWith pour modifications
  TatoueurSummary copyWith({
    String? id,
    String? name,
    String? displayName,
    String? avatarUrl,
    String? studioName,
    String? style,
    String? location,
    double? latitude,
    double? longitude,
    double? rating,
    int? reviewsCount,
    String? availability,
    double? distanceKm,
    bool? isActive,
    bool? isVerified,
    List<String>? specialties,
    String? instagram,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return TatoueurSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      studioName: studioName ?? this.studioName,
      style: style ?? this.style,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      availability: availability ?? this.availability,
      distanceKm: distanceKm ?? this.distanceKm,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      specialties: specialties ?? this.specialties,
      instagram: instagram ?? this.instagram,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  /// Getters utilitaires
  String get displayNameOrName => displayName ?? name;
  String get primarySpecialty => specialties.isNotEmpty ? specialties.first : style ?? 'Tatouage';
  String get specialtiesText => specialties.isNotEmpty ? specialties.join(', ') : (style ?? 'Tatouage');
  
  /// Note formatée avec une décimale
  String get ratingText => rating != null ? rating!.toStringAsFixed(1) : '4.5';
  
  /// Nombre d'avis formaté
  String get reviewsText {
    if (reviewsCount == null) return 'Nouveaux avis';
    if (reviewsCount! < 1000) return '$reviewsCount avis';
    return '${(reviewsCount! / 1000).toStringAsFixed(1)}k avis';
  }
  
  /// Distance formatée
  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).round()} m';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }
  
  /// Statut de dernière activité
  String get lastActiveText {
    if (lastActive == null) return 'Activité inconnue';
    
    final now = DateTime.now();
    final difference = now.difference(lastActive!);
    
    if (difference.inMinutes < 5) return 'En ligne';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours}h';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays}j';
    return 'Il y a plus d\'une semaine';
  }
  
  /// Statut actif avec couleur
  Color get statusColor {
    if (!isActive) return const Color(0xFF9CA3AF); // Gris
    
    if (lastActive == null) return const Color(0xFFFBBF24); // Jaune
    
    final now = DateTime.now();
    final difference = now.difference(lastActive!);
    
    if (difference.inMinutes < 5) return const Color(0xFF10B981); // Vert (en ligne)
    if (difference.inHours < 2) return const Color(0xFFFBBF24); // Jaune (récemment)
    return const Color(0xFF9CA3AF); // Gris (inactif)
  }
  
  /// Vérifie si le tatoueur correspond à une recherche
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    
    final searchQuery = query.toLowerCase();
    
    return name.toLowerCase().contains(searchQuery) ||
           (displayName?.toLowerCase().contains(searchQuery) ?? false) ||
           (studioName?.toLowerCase().contains(searchQuery) ?? false) ||
           (style?.toLowerCase().contains(searchQuery) ?? false) ||
           location.toLowerCase().contains(searchQuery) ||
           specialties.any((s) => s.toLowerCase().contains(searchQuery));
  }
  
  /// Vérifie si le tatoueur a une spécialité
  bool hasSpecialty(String specialty) {
    return specialties.any((s) => s.toLowerCase() == specialty.toLowerCase()) ||
           (style?.toLowerCase().contains(specialty.toLowerCase()) ?? false);
  }

  /// ✅ AJOUTÉ : Vérifie si le tatoueur a l'une des spécialités dans la liste
  bool hasAnySpecialty(List<String> stylesList) {
    if (stylesList.isEmpty) return true;
    
    return stylesList.any((styleFilter) => hasSpecialty(styleFilter));
  }

  @override
  String toString() {
    return 'TatoueurSummary(id: $id, name: $name, studioName: $studioName, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TatoueurSummary && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Extension pour générer des données de démonstration
extension TatoueurSummaryDemo on TatoueurSummary {
  /// Générer une liste de tatoueurs de démonstration
  static List<TatoueurSummary> generateDemoList({int count = 10}) {
    final List<Map<String, dynamic>> demoProfiles = [
      {
        'name': 'Alex Dubois',
        'displayName': 'Alex Dubois',
        'studio': 'Studio Ink Paris',
        'style': 'Réaliste, Japonais',
        'location': 'Paris (75)',
        'latitude': 48.8566,
        'longitude': 2.3522,
        'rating': 4.8,
        'reviewsCount': 156,
        'availability': '2-3 semaines',
        'distance': 1.2,
        'specialties': ['Réalisme', 'Japonais traditionnel', 'Portraits'],
        'instagram': '@alex_ink_paris',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
      {
        'name': 'Sophie Martinez',
        'displayName': 'Sophie Martinez',
        'studio': 'Atelier Luna',
        'style': 'Minimaliste, Géométrique',
        'location': 'Lyon (69)',
        'latitude': 45.7640,
        'longitude': 4.8357,
        'rating': 4.9,
        'reviewsCount': 203,
        'availability': "Aujourd'hui",
        'distance': 2.5,
        'specialties': ['Minimaliste', 'Géométrique', 'Fine line'],
        'instagram': '@luna_tattoo_lyon',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
      {
        'name': 'Marc Dubois',
        'displayName': 'Marc Dubois',
        'studio': 'Black & Grey Studio',
        'style': 'Blackwork, Tribal',
        'location': 'Marseille (13)',
        'latitude': 43.2965,
        'longitude': 5.3698,
        'rating': 4.7,
        'reviewsCount': 89,
        'availability': '3 jours',
        'distance': 5.1,
        'specialties': ['Blackwork', 'Tribal', 'Biomécanique'],
        'instagram': '@marc_blackwork',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
      {
        'name': 'Emma Laurent',
        'displayName': 'Emma Laurent',
        'studio': 'Ink & Colors',
        'style': 'Aquarelle, Floral',
        'location': 'Toulouse (31)',
        'latitude': 43.6043,
        'longitude': 1.4437,
        'rating': 4.6,
        'reviewsCount': 142,
        'availability': '2 semaines',
        'distance': 3.8,
        'specialties': ['Aquarelle', 'Floral', 'Couleur'],
        'instagram': '@emma_ink_colors',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
      {
        'name': 'Thomas Moreau',
        'displayName': 'Thomas Moreau',
        'studio': 'Old School Tattoo',
        'style': 'Traditionnel, Pin-up',
        'location': 'Nantes (44)',
        'latitude': 47.2184,
        'longitude': -1.5536,
        'rating': 4.5,
        'reviewsCount': 267,
        'availability': '1 mois',
        'distance': 7.2,
        'specialties': ['Traditionnel', 'Pin-up', 'Old School'],
        'instagram': '@thomas_oldschool',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
      {
        'name': 'Léa Petit',
        'displayName': 'Léa Petit',
        'studio': 'Dotwork Studio',
        'style': 'Pointillisme, Mandala',
        'location': 'Bordeaux (33)',
        'latitude': 44.8378,
        'longitude': -0.5792,
        'rating': 4.9,
        'reviewsCount': 178,
        'availability': "Plus d'1 mois",
        'distance': 4.3,
        'specialties': ['Pointillisme', 'Mandala', 'Géométrique'],
        'instagram': '@lea_dotwork',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
      {
        'name': 'Julien Rousseau',
        'displayName': 'Julien Rousseau',
        'studio': 'Neo Traditional Art',
        'style': 'Néo-traditionnel',
        'location': 'Lille (59)',
        'latitude': 50.6292,
        'longitude': 3.0573,
        'rating': 4.7,
        'reviewsCount': 195,
        'availability': '2-3 semaines',
        'distance': 6.7,
        'specialties': ['Néo-traditionnel', 'Couleur', 'Illustratif'],
        'instagram': '@julien_neotrad',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
      {
        'name': 'Camille Durand',
        'displayName': 'Camille Durand',
        'studio': 'Blackwork Atelier',
        'style': 'Blackwork, Ornemental',
        'location': 'Strasbourg (67)',
        'latitude': 48.5734,
        'longitude': 7.7521,
        'rating': 4.8,
        'reviewsCount': 123,
        'availability': "Plus de 6 mois",
        'distance': 8.9,
        'specialties': ['Blackwork', 'Ornemental', 'Tribal'],
        'instagram': '@camille_blackwork',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
      {
        'name': 'Antoine Moreau',
        'displayName': 'Antoine Moreau',
        'studio': 'Réalisme Studio',
        'style': 'Réaliste, Portrait',
        'location': 'Nancy (54)',
        'latitude': 48.6921,
        'longitude': 6.1844,
        'rating': 4.9,
        'reviewsCount': 234,
        'availability': "Aujourd'hui",
        'distance': 0.8,
        'specialties': ['Réaliste', 'Portrait', 'Micro-réalisme'],
        'instagram': '@antoine_realism',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
      {
        'name': 'Clara Fontaine',
        'displayName': 'Clara Fontaine',
        'studio': 'Fine Line Studio',
        'style': 'Line fin, Minimaliste',
        'location': 'Metz (57)',
        'latitude': 49.1193,
        'longitude': 6.1757,
        'rating': 4.6,
        'reviewsCount': 167,
        'availability': '3 jours',
        'distance': 1.5,
        'specialties': ['Line fin', 'Minimaliste', 'Esquisse'],
        'instagram': '@clara_fineline',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
      {
        'name': 'Vincent Roy',
        'displayName': 'Vincent Roy',
        'studio': 'Horror Ink',
        'style': 'Horreur, Surréalisme',
        'location': 'Reims (51)',
        'latitude': 49.2583,
        'longitude': 4.0317,
        'rating': 4.4,
        'reviewsCount': 98,
        'availability': '2 semaines',
        'distance': 3.2,
        'specialties': ['Horreur', 'Surréalisme', 'Noir et gris'],
        'instagram': '@vincent_horror',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
      {
        'name': 'Manon Leroy',
        'displayName': 'Manon Leroy',
        'studio': 'Anime Tattoo',
        'style': 'Anime, Illustratif',
        'location': 'Dijon (21)',
        'latitude': 47.3220,
        'longitude': 5.0415,
        'rating': 4.7,
        'reviewsCount': 145,
        'availability': '1 mois',
        'distance': 4.7,
        'specialties': ['Anime', 'Illustratif', 'Couleur'],
        'instagram': '@manon_anime',
        'avatar': 'assets/avatars/avatar_profil_pro.jpg',
      },
    ];

    final List<TatoueurSummary> result = [];
    
    for (int i = 0; i < count && i < demoProfiles.length; i++) {
      final profile = demoProfiles[i];
      result.add(TatoueurSummary.fromDemoData(profile, 'demo_tatoueur_${i + 1}'));
    }
    
    // Si on veut plus que ce qu'on a, on duplique et modifie
    while (result.length < count) {
      final baseProfile = demoProfiles[result.length % demoProfiles.length];
      final modifiedProfile = Map<String, dynamic>.from(baseProfile);
      modifiedProfile['name'] = '${modifiedProfile['name']} ${result.length + 1}';
      modifiedProfile['distance'] = (result.length * 1.5) + 1.0;
      
      result.add(TatoueurSummary.fromDemoData(
        modifiedProfile, 
        'demo_tatoueur_${result.length + 1}'
      ));
    }
    
    return result;
  }
}

/// Extension pour le tri et filtrage
extension TatoueurSummaryFilters on List<TatoueurSummary> {
  /// Trier par distance (plus proche en premier)
  List<TatoueurSummary> sortByDistance() {
    final filtered = where((t) => t.distanceKm != null).toList();
    filtered.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    return filtered;
  }
  
  /// Trier par note (meilleure en premier)
  List<TatoueurSummary> sortByRating() {
    final filtered = where((t) => t.rating != null).toList();
    filtered.sort((a, b) => b.rating!.compareTo(a.rating!));
    return filtered;
  }
  
  /// Trier par disponibilité (plus disponible en premier)
  List<TatoueurSummary> sortByAvailability() {
    return toList()..sort((a, b) {
      final aAvail = _parseAvailabilityDays(a.availability);
      final bAvail = _parseAvailabilityDays(b.availability);
      return aAvail.compareTo(bAvail);
    });
  }
  
  /// Filtrer par spécialité
  List<TatoueurSummary> filterBySpecialty(String specialty) {
    return where((t) => t.hasSpecialty(specialty)).toList();
  }
  
  /// Filtrer par distance maximum
  List<TatoueurSummary> filterByMaxDistance(double maxDistance) {
    return where((t) => t.distanceKm != null && t.distanceKm! <= maxDistance).toList();
  }
  
  /// Filtrer par note minimum
  List<TatoueurSummary> filterByMinRating(double minRating) {
    return where((t) => t.rating != null && t.rating! >= minRating).toList();
  }
  
  /// Filtrer par recherche textuelle
  List<TatoueurSummary> search(String query) {
    return where((t) => t.matchesSearch(query)).toList();
  }
  
  /// Helper pour parser les jours de disponibilité
  static int _parseAvailabilityDays(String availability) {
    final dispValues = {
      "Aujourd'hui": 0,
      '3 jours': 3,
      '2 semaines': 14,
      '1 mois': 30,
      'Plus d\'1 mois': 31,
      'Plus de 6 mois': 180
    };
    
    return dispValues[availability] ?? 999;
  }
}