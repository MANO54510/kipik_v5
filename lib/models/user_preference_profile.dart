// lib/models/flash/user_preference_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Profil de préférences utilisateur pour l'algorithme de recommandation
class UserPreferenceProfile {
  final String userId;
  final Map<String, double> stylePreferences;       // Style → Score (0.0 - 1.0)
  final Map<String, double> colorPreferences;       // Couleur → Score (0.0 - 1.0)
  final Map<String, double> placementPreferences;   // Emplacement → Score (0.0 - 1.0)
  final Map<String, double> sizePreferences;        // Taille → Score (0.0 - 1.0)
  final List<String> likedFlashIds;                 // Flashs likés
  final List<String> savedFlashIds;                 // Flashs sauvegardés
  final List<String> viewedFlashIds;                // Flashs vus (pour éviter répétitions)
  final List<String> swipedLeftFlashIds;            // Flashs rejetés (swipe left)
  final List<String> bookedFlashIds;                // Flashs réservés
  final double maxDistanceKm;                       // Distance max acceptée
  final String? budgetRange;                        // Fourchette de budget
  final bool onlyBookableFlashs;                    // Uniquement flashs réservables
  final bool preferMinuteFlashs;                    // Préférence pour Flash Minute
  final Map<String, int> artistInteractions;       // Artiste → Nombre d'interactions
  final Map<String, double> timePreferences;       // Créneaux préférés (heure → score)
  final DateTime lastUpdated;
  final UserBehaviorStats behaviorStats;

  const UserPreferenceProfile({
    required this.userId,
    this.stylePreferences = const {},
    this.colorPreferences = const {},
    this.placementPreferences = const {},
    this.sizePreferences = const {},
    this.likedFlashIds = const [],
    this.savedFlashIds = const [],
    this.viewedFlashIds = const [],
    this.swipedLeftFlashIds = const [],
    this.bookedFlashIds = const [],
    this.maxDistanceKm = 50.0,
    this.budgetRange,
    this.onlyBookableFlashs = false,
    this.preferMinuteFlashs = false,
    this.artistInteractions = const {},
    this.timePreferences = const {},
    required this.lastUpdated,
    required this.behaviorStats,
  });

  /// Factory constructor depuis Firebase
  factory UserPreferenceProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserPreferenceProfile.fromMap(data, doc.id);
  }

  /// Factory constructor depuis Map
  factory UserPreferenceProfile.fromMap(Map<String, dynamic> map, String userId) {
    return UserPreferenceProfile(
      userId: userId,
      stylePreferences: Map<String, double>.from(map['stylePreferences'] ?? {}),
      colorPreferences: Map<String, double>.from(map['colorPreferences'] ?? {}),
      placementPreferences: Map<String, double>.from(map['placementPreferences'] ?? {}),
      sizePreferences: Map<String, double>.from(map['sizePreferences'] ?? {}),
      likedFlashIds: List<String>.from(map['likedFlashIds'] ?? []),
      savedFlashIds: List<String>.from(map['savedFlashIds'] ?? []),
      viewedFlashIds: List<String>.from(map['viewedFlashIds'] ?? []),
      swipedLeftFlashIds: List<String>.from(map['swipedLeftFlashIds'] ?? []),
      bookedFlashIds: List<String>.from(map['bookedFlashIds'] ?? []),
      maxDistanceKm: (map['maxDistanceKm'] ?? 50.0).toDouble(),
      budgetRange: map['budgetRange'],
      onlyBookableFlashs: map['onlyBookableFlashs'] ?? false,
      preferMinuteFlashs: map['preferMinuteFlashs'] ?? false,
      artistInteractions: Map<String, int>.from(map['artistInteractions'] ?? {}),
      timePreferences: Map<String, double>.from(map['timePreferences'] ?? {}),
      lastUpdated: map['lastUpdated'] is Timestamp 
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
      behaviorStats: UserBehaviorStats.fromMap(map['behaviorStats'] ?? {}),
    );
  }

  /// Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'stylePreferences': stylePreferences,
      'colorPreferences': colorPreferences,
      'placementPreferences': placementPreferences,
      'sizePreferences': sizePreferences,
      'likedFlashIds': likedFlashIds,
      'savedFlashIds': savedFlashIds,
      'viewedFlashIds': viewedFlashIds,
      'swipedLeftFlashIds': swipedLeftFlashIds,
      'bookedFlashIds': bookedFlashIds,
      'maxDistanceKm': maxDistanceKm,
      'budgetRange': budgetRange,
      'onlyBookableFlashs': onlyBookableFlashs,
      'preferMinuteFlashs': preferMinuteFlashs,
      'artistInteractions': artistInteractions,
      'timePreferences': timePreferences,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'behaviorStats': behaviorStats.toMap(),
    };
  }

  /// Créer un profil vide pour un nouvel utilisateur
  factory UserPreferenceProfile.empty(String userId) {
    return UserPreferenceProfile(
      userId: userId,
      lastUpdated: DateTime.now(),
      behaviorStats: UserBehaviorStats.empty(),
    );
  }

  /// Calculer le score de compatibilité avec un flash (0.0 - 1.0)
  double calculateCompatibilityScore({
    required String flashStyle,
    required List<String> flashColors,
    required List<String> flashPlacements,
    required String flashSize,
    required String flashArtistId,
    required double flashPrice,
  }) {
    double score = 0.0;
    double totalWeight = 0.0;

    // Score style (poids: 30%)
    const styleWeight = 0.30;
    final styleScore = stylePreferences[flashStyle] ?? 0.3; // Score neutre par défaut
    score += styleScore * styleWeight;
    totalWeight += styleWeight;

    // Score couleur (poids: 20%)
    const colorWeight = 0.20;
    double colorScore = 0.0;
    for (final color in flashColors) {
      final preference = colorPreferences[color] ?? 0.3;
      colorScore = colorScore > preference ? colorScore : preference; // Prendre le meilleur score
    }
    score += colorScore * colorWeight;
    totalWeight += colorWeight;

    // Score emplacement (poids: 25%)
    const placementWeight = 0.25;
    double placementScore = 0.0;
    for (final placement in flashPlacements) {
      final preference = placementPreferences[placement] ?? 0.3;
      placementScore = placementScore > preference ? placementScore : preference;
    }
    score += placementScore * placementWeight;
    totalWeight += placementWeight;

    // Score taille (poids: 15%)
    const sizeWeight = 0.15;
    final sizeScore = sizePreferences[flashSize] ?? 0.3;
    score += sizeScore * sizeWeight;
    totalWeight += sizeWeight;

    // Score artiste (poids: 10%)
    const artistWeight = 0.10;
    final artistInteractionCount = artistInteractions[flashArtistId] ?? 0;
    final artistScore = (artistInteractionCount / 10.0).clamp(0.0, 1.0); // Normaliser sur 10 interactions
    score += artistScore * artistWeight;
    totalWeight += artistWeight;

    // Bonus/Malus prix
    if (budgetRange != null) {
      final budget = _parseBudgetRange(budgetRange!);
      if (budget != null) {
        if (flashPrice >= budget.min && flashPrice <= budget.max) {
          score += 0.1; // Bonus si dans le budget
        } else if (flashPrice > budget.max) {
          score -= 0.2; // Malus si trop cher
        }
      }
    }

    // Normaliser le score final
    return totalWeight > 0 ? (score / totalWeight).clamp(0.0, 1.0) : 0.3;
  }

  /// Mettre à jour les préférences basées sur une action utilisateur
  UserPreferenceProfile updateFromAction({
    required UserActionType actionType,
    required String flashStyle,
    required List<String> flashColors,
    required List<String> flashPlacements,
    required String flashSize,
    required String flashArtistId,
    required String flashId,
  }) {
    // Facteur d'apprentissage selon l'action
    double learningFactor;
    switch (actionType) {
      case UserActionType.swipeRight:
      case UserActionType.like:
        learningFactor = 0.1;
        break;
      case UserActionType.save:
        learningFactor = 0.15;
        break;
      case UserActionType.book:
        learningFactor = 0.3; // Action forte
        break;
      case UserActionType.swipeLeft:
        learningFactor = -0.05; // Légèrement négatif
        break;
      case UserActionType.view:
        learningFactor = 0.02; // Très faible
        break;
    }

    // Mise à jour des préférences
    final newStylePreferences = Map<String, double>.from(stylePreferences);
    final newColorPreferences = Map<String, double>.from(colorPreferences);
    final newPlacementPreferences = Map<String, double>.from(placementPreferences);
    final newSizePreferences = Map<String, double>.from(sizePreferences);
    final newArtistInteractions = Map<String, int>.from(artistInteractions);

    // Mettre à jour style
    newStylePreferences[flashStyle] = (newStylePreferences[flashStyle] ?? 0.3) + learningFactor;
    newStylePreferences[flashStyle] = newStylePreferences[flashStyle]!.clamp(0.0, 1.0);

    // Mettre à jour couleurs
    for (final color in flashColors) {
      newColorPreferences[color] = (newColorPreferences[color] ?? 0.3) + learningFactor;
      newColorPreferences[color] = newColorPreferences[color]!.clamp(0.0, 1.0);
    }

    // Mettre à jour emplacements
    for (final placement in flashPlacements) {
      newPlacementPreferences[placement] = (newPlacementPreferences[placement] ?? 0.3) + learningFactor;
      newPlacementPreferences[placement] = newPlacementPreferences[placement]!.clamp(0.0, 1.0);
    }

    // Mettre à jour taille
    newSizePreferences[flashSize] = (newSizePreferences[flashSize] ?? 0.3) + learningFactor;
    newSizePreferences[flashSize] = newSizePreferences[flashSize]!.clamp(0.0, 1.0);

    // Mettre à jour interactions artiste
    if (learningFactor > 0) {
      newArtistInteractions[flashArtistId] = (newArtistInteractions[flashArtistId] ?? 0) + 1;
    }

    // Mettre à jour les listes selon l'action
    List<String> newLikedFlashIds = List.from(likedFlashIds);
    List<String> newSavedFlashIds = List.from(savedFlashIds);
    List<String> newViewedFlashIds = List.from(viewedFlashIds);
    List<String> newSwipedLeftFlashIds = List.from(swipedLeftFlashIds);
    List<String> newBookedFlashIds = List.from(bookedFlashIds);

    switch (actionType) {
      case UserActionType.like:
        if (!newLikedFlashIds.contains(flashId)) {
          newLikedFlashIds.add(flashId);
        }
        break;
      case UserActionType.save:
        if (!newSavedFlashIds.contains(flashId)) {
          newSavedFlashIds.add(flashId);
        }
        break;
      case UserActionType.view:
        if (!newViewedFlashIds.contains(flashId)) {
          newViewedFlashIds.add(flashId);
        }
        break;
      case UserActionType.swipeLeft:
        if (!newSwipedLeftFlashIds.contains(flashId)) {
          newSwipedLeftFlashIds.add(flashId);
        }
        break;
      case UserActionType.book:
        if (!newBookedFlashIds.contains(flashId)) {
          newBookedFlashIds.add(flashId);
        }
        break;
      case UserActionType.swipeRight:
        // Swipe right = intérêt mais pas d'action spécifique
        break;
    }

    // Mettre à jour les stats de comportement
    final newBehaviorStats = behaviorStats.updateFromAction(actionType);

    return copyWith(
      stylePreferences: newStylePreferences,
      colorPreferences: newColorPreferences,
      placementPreferences: newPlacementPreferences,
      sizePreferences: newSizePreferences,
      artistInteractions: newArtistInteractions,
      likedFlashIds: newLikedFlashIds,
      savedFlashIds: newSavedFlashIds,
      viewedFlashIds: newViewedFlashIds,
      swipedLeftFlashIds: newSwipedLeftFlashIds,
      bookedFlashIds: newBookedFlashIds,
      lastUpdated: DateTime.now(),
      behaviorStats: newBehaviorStats,
    );
  }

  /// Parser une fourchette de budget "min-max"
  BudgetRange? _parseBudgetRange(String budgetString) {
    try {
      final parts = budgetString.split('-');
      if (parts.length == 2) {
        final min = double.parse(parts[0]);
        final max = double.parse(parts[1]);
        return BudgetRange(min: min, max: max);
      }
    } catch (e) {
      // Ignore les erreurs de parsing
    }
    return null;
  }

  /// CopyWith pour modifications
  UserPreferenceProfile copyWith({
    String? userId,
    Map<String, double>? stylePreferences,
    Map<String, double>? colorPreferences,
    Map<String, double>? placementPreferences,
    Map<String, double>? sizePreferences,
    List<String>? likedFlashIds,
    List<String>? savedFlashIds,
    List<String>? viewedFlashIds,
    List<String>? swipedLeftFlashIds,
    List<String>? bookedFlashIds,
    double? maxDistanceKm,
    String? budgetRange,
    bool? onlyBookableFlashs,
    bool? preferMinuteFlashs,
    Map<String, int>? artistInteractions,
    Map<String, double>? timePreferences,
    DateTime? lastUpdated,
    UserBehaviorStats? behaviorStats,
  }) {
    return UserPreferenceProfile(
      userId: userId ?? this.userId,
      stylePreferences: stylePreferences ?? this.stylePreferences,
      colorPreferences: colorPreferences ?? this.colorPreferences,
      placementPreferences: placementPreferences ?? this.placementPreferences,
      sizePreferences: sizePreferences ?? this.sizePreferences,
      likedFlashIds: likedFlashIds ?? this.likedFlashIds,
      savedFlashIds: savedFlashIds ?? this.savedFlashIds,
      viewedFlashIds: viewedFlashIds ?? this.viewedFlashIds,
      swipedLeftFlashIds: swipedLeftFlashIds ?? this.swipedLeftFlashIds,
      bookedFlashIds: bookedFlashIds ?? this.bookedFlashIds,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      budgetRange: budgetRange ?? this.budgetRange,
      onlyBookableFlashs: onlyBookableFlashs ?? this.onlyBookableFlashs,
      preferMinuteFlashs: preferMinuteFlashs ?? this.preferMinuteFlashs,
      artistInteractions: artistInteractions ?? this.artistInteractions,
      timePreferences: timePreferences ?? this.timePreferences,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      behaviorStats: behaviorStats ?? this.behaviorStats,
    );
  }

  @override
  String toString() {
    return 'UserPreferenceProfile(userId: $userId, styles: ${stylePreferences.length}, lastUpdated: $lastUpdated)';
  }
}

/// Statistiques de comportement utilisateur
class UserBehaviorStats {
  final int totalViews;
  final int totalLikes;
  final int totalSaves;
  final int totalSwipeRights;
  final int totalSwipeLefts;
  final int totalBookings;
  final double avgSessionDuration;      // Durée moyenne des sessions (minutes)
  final double swipeRightRate;          // Taux de swipe right (0.0 - 1.0)
  final double conversionRate;          // Taux de conversion vue → booking (0.0 - 1.0)
  final Map<String, int> styleViews;    // Vues par style
  final DateTime firstInteraction;
  final DateTime lastInteraction;

  const UserBehaviorStats({
    this.totalViews = 0,
    this.totalLikes = 0,
    this.totalSaves = 0,
    this.totalSwipeRights = 0,
    this.totalSwipeLefts = 0,
    this.totalBookings = 0,
    this.avgSessionDuration = 0.0,
    this.swipeRightRate = 0.0,
    this.conversionRate = 0.0,
    this.styleViews = const {},
    required this.firstInteraction,
    required this.lastInteraction,
  });

  factory UserBehaviorStats.empty() {
    final now = DateTime.now();
    return UserBehaviorStats(
      firstInteraction: now,
      lastInteraction: now,
    );
  }

  factory UserBehaviorStats.fromMap(Map<String, dynamic> map) {
    return UserBehaviorStats(
      totalViews: map['totalViews'] ?? 0,
      totalLikes: map['totalLikes'] ?? 0,
      totalSaves: map['totalSaves'] ?? 0,
      totalSwipeRights: map['totalSwipeRights'] ?? 0,
      totalSwipeLefts: map['totalSwipeLefts'] ?? 0,
      totalBookings: map['totalBookings'] ?? 0,
      avgSessionDuration: (map['avgSessionDuration'] ?? 0.0).toDouble(),
      swipeRightRate: (map['swipeRightRate'] ?? 0.0).toDouble(),
      conversionRate: (map['conversionRate'] ?? 0.0).toDouble(),
      styleViews: Map<String, int>.from(map['styleViews'] ?? {}),
      firstInteraction: map['firstInteraction'] is Timestamp 
          ? (map['firstInteraction'] as Timestamp).toDate()
          : DateTime.parse(map['firstInteraction'] ?? DateTime.now().toIso8601String()),
      lastInteraction: map['lastInteraction'] is Timestamp 
          ? (map['lastInteraction'] as Timestamp).toDate()
          : DateTime.parse(map['lastInteraction'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalViews': totalViews,
      'totalLikes': totalLikes,
      'totalSaves': totalSaves,
      'totalSwipeRights': totalSwipeRights,
      'totalSwipeLefts': totalSwipeLefts,
      'totalBookings': totalBookings,
      'avgSessionDuration': avgSessionDuration,
      'swipeRightRate': swipeRightRate,
      'conversionRate': conversionRate,
      'styleViews': styleViews,
      'firstInteraction': Timestamp.fromDate(firstInteraction),
      'lastInteraction': Timestamp.fromDate(lastInteraction),
    };
  }

  /// Mettre à jour depuis une action
  UserBehaviorStats updateFromAction(UserActionType actionType) {
    int newTotalViews = totalViews;
    int newTotalLikes = totalLikes;
    int newTotalSaves = totalSaves;
    int newTotalSwipeRights = totalSwipeRights;
    int newTotalSwipeLefts = totalSwipeLefts;
    int newTotalBookings = totalBookings;

    switch (actionType) {
      case UserActionType.view:
        newTotalViews++;
        break;
      case UserActionType.like:
        newTotalLikes++;
        break;
      case UserActionType.save:
        newTotalSaves++;
        break;
      case UserActionType.swipeRight:
        newTotalSwipeRights++;
        break;
      case UserActionType.swipeLeft:
        newTotalSwipeLefts++;
        break;
      case UserActionType.book:
        newTotalBookings++;
        break;
    }

    // Recalculer les taux
    final totalSwipes = newTotalSwipeRights + newTotalSwipeLefts;
    final newSwipeRightRate = totalSwipes > 0 ? newTotalSwipeRights / totalSwipes : 0.0;
    final newConversionRate = newTotalViews > 0 ? newTotalBookings / newTotalViews : 0.0;

    return UserBehaviorStats(
      totalViews: newTotalViews,
      totalLikes: newTotalLikes,
      totalSaves: newTotalSaves,
      totalSwipeRights: newTotalSwipeRights,
      totalSwipeLefts: newTotalSwipeLefts,
      totalBookings: newTotalBookings,
      avgSessionDuration: avgSessionDuration, // TODO: Calculer vraie durée
      swipeRightRate: newSwipeRightRate,
      conversionRate: newConversionRate,
      styleViews: styleViews, // TODO: Mettre à jour par style
      firstInteraction: firstInteraction,
      lastInteraction: DateTime.now(),
    );
  }
}

/// Types d'actions utilisateur pour l'apprentissage
enum UserActionType {
  view,        // Voir un flash
  like,        // Liker un flash
  save,        // Sauvegarder un flash
  swipeRight,  // Swiper à droite (intéressé)
  swipeLeft,   // Swiper à gauche (pas intéressé)
  book,        // Réserver un flash
}

/// Fourchette de budget
class BudgetRange {
  final double min;
  final double max;

  const BudgetRange({
    required this.min,
    required this.max,
  });

  bool contains(double price) => price >= min && price <= max;

  @override
  String toString() => '$min-$max';
}

/// Extensions pour les actions utilisateur
extension UserActionTypeExtension on UserActionType {
  String get displayName {
    switch (this) {
      case UserActionType.view:
        return 'Vue';
      case UserActionType.like:
        return 'Like';
      case UserActionType.save:
        return 'Sauvegarde';
      case UserActionType.swipeRight:
        return 'Swipe droite';
      case UserActionType.swipeLeft:
        return 'Swipe gauche';
      case UserActionType.book:
        return 'Réservation';
    }
  }

  /// Poids de l'action pour l'apprentissage (plus l'action est forte, plus le poids est élevé)
  double get learningWeight {
    switch (this) {
      case UserActionType.view:
        return 0.1;
      case UserActionType.like:
        return 0.3;
      case UserActionType.save:
        return 0.5;
      case UserActionType.swipeRight:
        return 0.2;
      case UserActionType.swipeLeft:
        return -0.1; // Négatif pour indiquer le rejet
      case UserActionType.book:
        return 1.0; // Action la plus forte
    }
  }

  bool get isPositive => learningWeight > 0;
  bool get isNegative => learningWeight < 0;
}