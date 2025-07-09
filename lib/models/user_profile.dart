// lib/models/user_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle du profil utilisateur pour le système de recommandation IA
/// Contient les préférences et comportements analysés par l'algorithme ML
class UserProfile {
  final String userId;
  final List<String> preferredStyles;
  final double? priceRangeMin;
  final double? priceRangeMax;
  final String? preferredLocation;
  final List<String> preferredTimeSlots;
  final List<String> favoriteArtists;
  final List<String> favoriteStudioIds;
  final Map<String, double> styleAffinityScores;
  final Map<String, int> bodyPlacementPreferences;
  final List<String> colorPreferences;
  final DateTime lastAnalyzed;
  final DateTime? lastInteraction;
  final int interactionCount;
  final int totalLikes;
  final int totalSaves;
  final int totalViews;
  final int totalBookings;
  final double averageSessionDuration;
  final List<String> searchHistory;
  final Map<String, dynamic> customPreferences;

  const UserProfile({
    required this.userId,
    this.preferredStyles = const [],
    this.priceRangeMin,
    this.priceRangeMax,
    this.preferredLocation,
    this.preferredTimeSlots = const [],
    this.favoriteArtists = const [],
    this.favoriteStudioIds = const [],
    this.styleAffinityScores = const {},
    this.bodyPlacementPreferences = const {},
    this.colorPreferences = const [],
    required this.lastAnalyzed,
    this.lastInteraction,
    this.interactionCount = 0,
    this.totalLikes = 0,
    this.totalSaves = 0,
    this.totalViews = 0,
    this.totalBookings = 0,
    this.averageSessionDuration = 0.0,
    this.searchHistory = const [],
    this.customPreferences = const {},
  });

  /// Factory constructor depuis Firestore
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile.fromMap(data, doc.id);
  }

  /// Factory constructor depuis Map
  factory UserProfile.fromMap(Map<String, dynamic> map, String userId) {
    return UserProfile(
      userId: userId,
      preferredStyles: List<String>.from(map['preferredStyles'] ?? []),
      priceRangeMin: map['priceRangeMin']?.toDouble(),
      priceRangeMax: map['priceRangeMax']?.toDouble(),
      preferredLocation: map['preferredLocation'],
      preferredTimeSlots: List<String>.from(map['preferredTimeSlots'] ?? []),
      favoriteArtists: List<String>.from(map['favoriteArtists'] ?? []),
      favoriteStudioIds: List<String>.from(map['favoriteStudioIds'] ?? []),
      styleAffinityScores: Map<String, double>.from(
        (map['styleAffinityScores'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      bodyPlacementPreferences: Map<String, int>.from(
        map['bodyPlacementPreferences'] ?? {},
      ),
      colorPreferences: List<String>.from(map['colorPreferences'] ?? []),
      lastAnalyzed: map['lastAnalyzed'] is Timestamp 
          ? (map['lastAnalyzed'] as Timestamp).toDate()
          : DateTime.parse(map['lastAnalyzed'] ?? DateTime.now().toIso8601String()),
      lastInteraction: map['lastInteraction'] != null
          ? (map['lastInteraction'] is Timestamp 
              ? (map['lastInteraction'] as Timestamp).toDate()
              : DateTime.parse(map['lastInteraction']))
          : null,
      interactionCount: map['interactionCount'] ?? 0,
      totalLikes: map['totalLikes'] ?? 0,
      totalSaves: map['totalSaves'] ?? 0,
      totalViews: map['totalViews'] ?? 0,
      totalBookings: map['totalBookings'] ?? 0,
      averageSessionDuration: (map['averageSessionDuration'] ?? 0.0).toDouble(),
      searchHistory: List<String>.from(map['searchHistory'] ?? []),
      customPreferences: Map<String, dynamic>.from(map['customPreferences'] ?? {}),
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'preferredStyles': preferredStyles,
      'priceRangeMin': priceRangeMin,
      'priceRangeMax': priceRangeMax,
      'preferredLocation': preferredLocation,
      'preferredTimeSlots': preferredTimeSlots,
      'favoriteArtists': favoriteArtists,
      'favoriteStudioIds': favoriteStudioIds,
      'styleAffinityScores': styleAffinityScores,
      'bodyPlacementPreferences': bodyPlacementPreferences,
      'colorPreferences': colorPreferences,
      'lastAnalyzed': Timestamp.fromDate(lastAnalyzed),
      'lastInteraction': lastInteraction != null ? Timestamp.fromDate(lastInteraction!) : null,
      'interactionCount': interactionCount,
      'totalLikes': totalLikes,
      'totalSaves': totalSaves,
      'totalViews': totalViews,
      'totalBookings': totalBookings,
      'averageSessionDuration': averageSessionDuration,
      'searchHistory': searchHistory,
      'customPreferences': customPreferences,
    };
  }

  /// CopyWith pour modifications
  UserProfile copyWith({
    String? userId,
    List<String>? preferredStyles,
    double? priceRangeMin,
    double? priceRangeMax,
    String? preferredLocation,
    List<String>? preferredTimeSlots,
    List<String>? favoriteArtists,
    List<String>? favoriteStudioIds,
    Map<String, double>? styleAffinityScores,
    Map<String, int>? bodyPlacementPreferences,
    List<String>? colorPreferences,
    DateTime? lastAnalyzed,
    DateTime? lastInteraction,
    int? interactionCount,
    int? totalLikes,
    int? totalSaves,
    int? totalViews,
    int? totalBookings,
    double? averageSessionDuration,
    List<String>? searchHistory,
    Map<String, dynamic>? customPreferences,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      preferredStyles: preferredStyles ?? this.preferredStyles,
      priceRangeMin: priceRangeMin ?? this.priceRangeMin,
      priceRangeMax: priceRangeMax ?? this.priceRangeMax,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      preferredTimeSlots: preferredTimeSlots ?? this.preferredTimeSlots,
      favoriteArtists: favoriteArtists ?? this.favoriteArtists,
      favoriteStudioIds: favoriteStudioIds ?? this.favoriteStudioIds,
      styleAffinityScores: styleAffinityScores ?? this.styleAffinityScores,
      bodyPlacementPreferences: bodyPlacementPreferences ?? this.bodyPlacementPreferences,
      colorPreferences: colorPreferences ?? this.colorPreferences,
      lastAnalyzed: lastAnalyzed ?? this.lastAnalyzed,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      interactionCount: interactionCount ?? this.interactionCount,
      totalLikes: totalLikes ?? this.totalLikes,
      totalSaves: totalSaves ?? this.totalSaves,
      totalViews: totalViews ?? this.totalViews,
      totalBookings: totalBookings ?? this.totalBookings,
      averageSessionDuration: averageSessionDuration ?? this.averageSessionDuration,
      searchHistory: searchHistory ?? this.searchHistory,
      customPreferences: customPreferences ?? this.customPreferences,
    );
  }

  /// ✅ MÉTHODES UTILITAIRES POUR L'IA

  /// Vérifier si l'utilisateur est nouveau (peu d'interactions)
  bool get isNewUser => interactionCount < 10;

  /// Vérifier si l'utilisateur est actif
  bool get isActiveUser => interactionCount > 50 && 
      (lastInteraction?.isAfter(DateTime.now().subtract(const Duration(days: 7))) ?? false);

  /// Obtenir le style favori
  String? get favoriteStyle {
    if (styleAffinityScores.isEmpty) return null;
    return styleAffinityScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Obtenir le budget moyen
  double? get averageBudget {
    if (priceRangeMin == null || priceRangeMax == null) return null;
    return (priceRangeMin! + priceRangeMax!) / 2;
  }

  /// Vérifier si un style est dans les préférences
  bool isStylePreferred(String style) {
    return preferredStyles.contains(style.toLowerCase()) ||
           (styleAffinityScores[style.toLowerCase()] ?? 0.0) > 0.5;
  }

  /// Vérifier si un prix est dans la fourchette
  bool isPriceInRange(double price) {
    if (priceRangeMin == null || priceRangeMax == null) return true;
    return price >= priceRangeMin! && price <= priceRangeMax!;
  }

  /// Vérifier si un artiste est favori
  bool isArtistFavorite(String artistId) {
    return favoriteArtists.contains(artistId);
  }

  /// Calculer le taux d'engagement
  double get engagementRate {
    if (totalViews == 0) return 0.0;
    return (totalLikes + totalSaves) / totalViews;
  }

  /// Calculer le taux de conversion
  double get conversionRate {
    if (totalViews == 0) return 0.0;
    return totalBookings / totalViews;
  }

  /// Obtenir les créneaux horaires préférés
  List<int> get preferredHours {
    return preferredTimeSlots.map((slot) {
      final parts = slot.split(':');
      return int.tryParse(parts[0]) ?? 12;
    }).toList();
  }

  /// Vérifier si l'utilisateur préfère un créneau horaire
  bool isTimeSlotPreferred(DateTime dateTime) {
    if (preferredTimeSlots.isEmpty) return true;
    final preferredHours = this.preferredHours;
    return preferredHours.any((hour) => (dateTime.hour - hour).abs() <= 2);
  }

  /// Ajouter une recherche à l'historique
  UserProfile addSearchToHistory(String searchTerm) {
    final updatedHistory = List<String>.from(searchHistory);
    updatedHistory.insert(0, searchTerm);
    
    // Garder seulement les 50 dernières recherches
    if (updatedHistory.length > 50) {
      updatedHistory.removeRange(50, updatedHistory.length);
    }
    
    return copyWith(searchHistory: updatedHistory);
  }

  /// Mettre à jour le score d'affinité pour un style
  UserProfile updateStyleAffinity(String style, double score) {
    final updatedScores = Map<String, double>.from(styleAffinityScores);
    final currentScore = updatedScores[style.toLowerCase()] ?? 0.0;
    
    // Moyenne pondérée avec le score existant
    final newScore = (currentScore * 0.7) + (score * 0.3);
    updatedScores[style.toLowerCase()] = newScore.clamp(0.0, 1.0);
    
    return copyWith(styleAffinityScores: updatedScores);
  }

  /// Ajouter un artiste aux favoris
  UserProfile addFavoriteArtist(String artistId) {
    if (favoriteArtists.contains(artistId)) return this;
    
    final updatedFavorites = List<String>.from(favoriteArtists);
    updatedFavorites.add(artistId);
    
    return copyWith(favoriteArtists: updatedFavorites);
  }

  /// Retirer un artiste des favoris
  UserProfile removeFavoriteArtist(String artistId) {
    final updatedFavorites = List<String>.from(favoriteArtists);
    updatedFavorites.remove(artistId);
    
    return copyWith(favoriteArtists: updatedFavorites);
  }

  /// Mettre à jour les préférences de placement corporel
  UserProfile updateBodyPlacementPreference(String placement) {
    final updatedPreferences = Map<String, int>.from(bodyPlacementPreferences);
    updatedPreferences[placement] = (updatedPreferences[placement] ?? 0) + 1;
    
    return copyWith(bodyPlacementPreferences: updatedPreferences);
  }

  /// Créer un profil par défaut pour un nouvel utilisateur
  static UserProfile createDefault(String userId) {
    return UserProfile(
      userId: userId,
      preferredStyles: [],
      priceRangeMin: 50.0,
      priceRangeMax: 300.0,
      preferredLocation: null,
      preferredTimeSlots: ['14:00', '16:00', '18:00'],
      favoriteArtists: [],
      favoriteStudioIds: [],
      styleAffinityScores: {},
      bodyPlacementPreferences: {},
      colorPreferences: ['noir', 'gris'],
      lastAnalyzed: DateTime.now(),
      lastInteraction: null,
      interactionCount: 0,
      totalLikes: 0,
      totalSaves: 0,
      totalViews: 0,
      totalBookings: 0,
      averageSessionDuration: 0.0,
      searchHistory: [],
      customPreferences: {},
    );
  }

  /// Créer un profil basé sur les préférences explicites de l'utilisateur
  static UserProfile createFromPreferences({
    required String userId,
    required List<String> preferredStyles,
    required double minBudget,
    required double maxBudget,
    String? location,
    List<String>? timeSlots,
    List<String>? colors,
  }) {
    return UserProfile(
      userId: userId,
      preferredStyles: preferredStyles.map((s) => s.toLowerCase()).toList(),
      priceRangeMin: minBudget,
      priceRangeMax: maxBudget,
      preferredLocation: location,
      preferredTimeSlots: timeSlots ?? ['14:00', '16:00', '18:00'],
      favoriteArtists: [],
      favoriteStudioIds: [],
      styleAffinityScores: Map.fromEntries(
        preferredStyles.map((style) => MapEntry(style.toLowerCase(), 0.8)),
      ),
      bodyPlacementPreferences: {},
      colorPreferences: colors ?? ['noir'],
      lastAnalyzed: DateTime.now(),
      lastInteraction: DateTime.now(),
      interactionCount: 1,
      totalLikes: 0,
      totalSaves: 0,
      totalViews: 0,
      totalBookings: 0,
      averageSessionDuration: 0.0,
      searchHistory: [],
      customPreferences: {},
    );
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, styles: $preferredStyles, '
           'budget: $priceRangeMin-$priceRangeMax, interactions: $interactionCount)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && runtimeType == other.runtimeType && userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}

/// ✅ CLASSES AUXILIAIRES

/// Modèle pour les actions utilisateur dans le système de recommandation
class UserAction {
  final UserActionType type;
  final String? flashId;
  final String? artistId;
  final double? value;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  UserAction({
    required this.type,
    this.flashId,
    this.artistId,
    this.value,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(); // ✅ Corrigé: DateTime.now() au lieu de Duration()

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'flashId': flashId,
      'artistId': artistId,
      'value': value,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static UserAction fromMap(Map<String, dynamic> map) {
    return UserAction(
      type: UserActionType.values.byName(map['type']),
      flashId: map['flashId'],
      artistId: map['artistId'],
      value: map['value']?.toDouble(),
      metadata: map['metadata'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  @override
  String toString() => 'UserAction(type: $type, flashId: $flashId)';
}

/// Types d'actions utilisateur pour l'analyse comportementale
enum UserActionType {
  /// Consulter un flash
  view,
  
  /// Aimer un flash
  like,
  
  /// Sauvegarder un flash
  save,
  
  /// Partager un flash
  share,
  
  /// Réserver un flash
  book,
  
  /// Passer un flash (swipe gauche)
  skip,
  
  /// Rechercher un terme
  search,
  
  /// Cliquer sur un artiste
  artistClick,
  
  /// Signaler un contenu
  report,
  
  /// Consulter un profil d'artiste
  artistProfile,
  
  /// Filtrer par style
  filterStyle,
  
  /// Filtrer par prix
  filterPrice,
  
  /// Filtrer par localisation
  filterLocation,
}

/// Extension pour les types d'action
extension UserActionTypeExtension on UserActionType {
  /// Poids de l'action dans l'algorithme de recommandation
  double get weight {
    switch (this) {
      case UserActionType.view:
        return 0.1;
      case UserActionType.like:
        return 0.8;
      case UserActionType.save:
        return 1.0;
      case UserActionType.share:
        return 0.9;
      case UserActionType.book:
        return 1.5;
      case UserActionType.skip:
        return -0.3;
      case UserActionType.search:
        return 0.4;
      case UserActionType.artistClick:
        return 0.6;
      case UserActionType.report:
        return -1.0;
      case UserActionType.artistProfile:
        return 0.5;
      case UserActionType.filterStyle:
        return 0.7;
      case UserActionType.filterPrice:
        return 0.3;
      case UserActionType.filterLocation:
        return 0.2;
    }
  }

  /// Vérifier si l'action est positive
  bool get isPositive => weight > 0;
  
  /// Vérifier si l'action est fortement indicative des préférences
  bool get isStrongSignal => weight.abs() >= 0.8;
}