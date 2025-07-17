// lib/services/recommendation/recommendation_engine.dart

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/flash/flash.dart';
import '../../models/user_profile.dart';
import '../../services/auth/secure_auth_service.dart';
import '../../services/flash/flash_service.dart';

/// Moteur de recommandation intelligent basé sur ML/IA
/// Analyse les préférences utilisateur et propose des flashs personnalisés
class RecommendationEngine {
  static final RecommendationEngine _instance = RecommendationEngine._internal();
  static RecommendationEngine get instance => _instance;
  RecommendationEngine._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SecureAuthService _authService = SecureAuthService.instance;
  final FlashService _flashService = FlashService.instance;

  // Collections
  static const String _interactionsCollection = 'user_interactions';
  static const String _userProfilesCollection = 'user_profiles';
  static const String _recommendationsCollection = 'recommendations_cache';
  static const String _trendsCollection = 'flash_trends';

  // Configuration algorithme
  static const int _maxRecommendations = 50;
  static const double _minimumScore = 0.1;
  static const Duration _cacheValidityDuration = Duration(hours: 6);

  // Poids des facteurs de recommandation
  static const double _styleCompatibilityWeight = 0.25;
  static const double _priceCompatibilityWeight = 0.20;
  static const double _locationProximityWeight = 0.15;
  static const double _popularityWeight = 0.15;
  static const double _artistCompatibilityWeight = 0.10;
  static const double _timePreferenceWeight = 0.10;
  static const double _socialSignalWeight = 0.05;

  /// ✅ ALGORITHME PRINCIPAL - Obtenir flashs personnalisés
  Future<List<Flash>> getPersonalizedFlashs(String userId, {int limit = 20}) async {
    try {
      print('🎯 Génération de recommandations pour $userId...');

      // 1. Vérifier le cache
      final cachedRecommendations = await _getCachedRecommendations(userId);
      if (cachedRecommendations.isNotEmpty) {
        print('💾 Utilisation cache (${cachedRecommendations.length} flashs)');
        return cachedRecommendations.take(limit).toList();
      }

      // 2. Charger le profil utilisateur
      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) {
        print('⚠️ Profil utilisateur non trouvé, recommandations par défaut');
        return await _getDefaultRecommendations(limit);
      }

      // 3. Obtenir tous les flashs disponibles
      final availableFlashs = await _flashService.getAvailableFlashs(limit: 200);
      if (availableFlashs.isEmpty) {
        return await _generateDemoRecommendations(limit);
      }

      // 4. Calculer les scores de compatibilité
      final scoredFlashs = await _calculateCompatibilityScores(userProfile, availableFlashs);

      // 5. Filtrer et trier par score
      final recommendations = scoredFlashs
          .where((item) => item.score >= _minimumScore)
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      final finalRecommendations = recommendations
          .take(_maxRecommendations)
          .map((item) => item.flash)
          .toList();

      // 6. Mettre en cache
      await _cacheRecommendations(userId, finalRecommendations);

      // 7. Enregistrer la génération
      await _trackRecommendationGeneration(userId, finalRecommendations.length);

      print('✅ ${finalRecommendations.length} recommandations générées');
      return finalRecommendations.take(limit).toList();
    } catch (e) {
      print('❌ Erreur getPersonalizedFlashs: $e');
      return await _generateDemoRecommendations(limit);
    }
  }

  /// ✅ MISE À JOUR PROFIL - Enregistrer les actions utilisateur
  Future<void> updateUserPreferences(String userId, UserAction action) async {
    try {
      final interaction = UserInteraction(
        userId: userId,
        action: action,
        timestamp: DateTime.now(),
        flashId: action.flashId,
        value: action.value,
        metadata: action.metadata,
      );

      // Sauvegarder l'interaction
      await _firestore.collection(_interactionsCollection).add(interaction.toMap());

      // Mettre à jour le profil utilisateur
      await _updateUserProfileFromInteraction(userId, interaction);

      // Invalider le cache de recommandations
      await _invalidateRecommendationsCache(userId);

      print('📊 Préférences mises à jour pour $userId: ${action.type}');
    } catch (e) {
      print('❌ Erreur updateUserPreferences: $e');
    }
  }

  /// ✅ CALCUL SCORE - Analyser compatibilité flash/utilisateur
  Future<double> calculateCompatibilityScore(Flash flash, UserProfile profile) async {
    try {
      double totalScore = 0.0;

      // 1. Compatibilité de style
      final styleScore = _calculateStyleCompatibility(flash, profile);
      totalScore += styleScore * _styleCompatibilityWeight;

      // 2. Compatibilité de prix
      final priceScore = _calculatePriceCompatibility(flash, profile);
      totalScore += priceScore * _priceCompatibilityWeight;

      // 3. Proximité géographique
      final locationScore = _calculateLocationProximity(flash, profile);
      totalScore += locationScore * _locationProximityWeight;

      // 4. Popularité générale
      final popularityScore = _calculatePopularityScore(flash);
      totalScore += popularityScore * _popularityWeight;

      // 5. Compatibilité avec l'artiste
      final artistScore = await _calculateArtistCompatibility(flash, profile);
      totalScore += artistScore * _artistCompatibilityWeight;

      // 6. Préférences temporelles
      final timeScore = _calculateTimePreference(flash, profile);
      totalScore += timeScore * _timePreferenceWeight;

      // 7. Signaux sociaux
      final socialScore = _calculateSocialSignals(flash, profile);
      totalScore += socialScore * _socialSignalWeight;

      return totalScore.clamp(0.0, 1.0);
    } catch (e) {
      print('❌ Erreur calculateCompatibilityScore: $e');
      return 0.0;
    }
  }

  /// ✅ MACHINE LEARNING - Entraîner le modèle
  Future<void> trainModel(List<UserInteraction> interactions) async {
    try {
      print('🤖 Entraînement du modèle ML...');
      
      // 1. Analyser les patterns d'interaction
      final patterns = _analyzeInteractionPatterns(interactions);
      
      // 2. Mettre à jour les poids des facteurs
      await _updateAlgorithmWeights(patterns);
      
      // 3. Identifier les tendances
      final trends = _identifyTrends(interactions);
      await _updateTrendsDatabase(trends);
      
      // 4. Optimiser les seuils de recommandation
      await _optimizeRecommendationThresholds(interactions);
      
      print('✅ Modèle ML mis à jour');
    } catch (e) {
      print('❌ Erreur trainModel: $e');
    }
  }

  /// ✅ ANALYTICS - Analyser comportement utilisateur
  Future<UserProfile> analyzeUserBehavior(String userId) async {
    try {
      // Récupérer les interactions récentes
      final interactions = await _getUserInteractions(userId, limit: 100);
      
      if (interactions.isEmpty) {
        return _createDefaultUserProfile(userId);
      }

      // Analyser les préférences
      final stylePreferences = _analyzeStylePreferences(interactions);
      final priceRange = _analyzePriceRange(interactions);
      final locationPreferences = _analyzeLocationPreferences(interactions);
      final timePreferences = _analyzeTimePreferences(interactions);
      final artistPreferences = _analyzeArtistPreferences(interactions);

      final profile = UserProfile(
        userId: userId,
        preferredStyles: stylePreferences,
        priceRangeMin: priceRange.min,
        priceRangeMax: priceRange.max,
        preferredLocation: locationPreferences,
        preferredTimeSlots: timePreferences,
        favoriteArtists: artistPreferences,
        lastAnalyzed: DateTime.now(),
        interactionCount: interactions.length,
      );

      // Sauvegarder le profil
      await _saveUserProfile(profile);
      
      return profile;
    } catch (e) {
      print('❌ Erreur analyzeUserBehavior: $e');
      return _createDefaultUserProfile(userId);
    }
  }

  /// ✅ MÉTHODES PRIVÉES - Calculs de compatibilité

  double _calculateStyleCompatibility(Flash flash, UserProfile profile) {
    if (profile.preferredStyles.isEmpty) return 0.5;
    
    final styleMatch = profile.preferredStyles.contains(flash.style.toLowerCase());
    if (styleMatch) return 1.0;
    
    // Styles similaires (mapping basique)
    final similarStyles = _getSimilarStyles(flash.style);
    final similarityMatch = profile.preferredStyles.any((style) => 
        similarStyles.contains(style.toLowerCase()));
    
    return similarityMatch ? 0.7 : 0.2;
  }

  double _calculatePriceCompatibility(Flash flash, UserProfile profile) {
    final price = flash.discountedPrice ?? flash.price;
    
    if (profile.priceRangeMin == null || profile.priceRangeMax == null) {
      return 0.5; // Score neutre sans préférences
    }
    
    if (price >= profile.priceRangeMin! && price <= profile.priceRangeMax!) {
      return 1.0; // Prix parfaitement dans la fourchette
    }
    
    // Calculer la distance par rapport à la fourchette
    if (price < profile.priceRangeMin!) {
      final distance = (profile.priceRangeMin! - price) / profile.priceRangeMin!;
      return (1.0 - distance).clamp(0.0, 1.0);
    } else {
      final distance = (price - profile.priceRangeMax!) / profile.priceRangeMax!;
      return (1.0 - distance * 0.5).clamp(0.0, 1.0);
    }
  }

  double _calculateLocationProximity(Flash flash, UserProfile profile) {
    if (profile.preferredLocation == null) return 0.5;
    
    // Calcul simple de distance (à améliorer avec vraie géolocalisation)
    if (flash.city.toLowerCase() == profile.preferredLocation!.toLowerCase()) {
      return 1.0;
    }
    
    // Bonus pour le même pays
    if (flash.country.toLowerCase() == 'france') {
      return 0.6;
    }
    
    return 0.3;
  }

  double _calculatePopularityScore(Flash flash) {
    final totalEngagement = flash.likes + flash.saves + (flash.views / 10);
    final qualityBonus = flash.qualityScore / 5.0;
    
    // Normaliser sur une échelle de 0-1
    final popularityScore = (totalEngagement / 100).clamp(0.0, 0.8);
    return (popularityScore + qualityBonus * 0.2).clamp(0.0, 1.0);
  }

  Future<double> _calculateArtistCompatibility(Flash flash, UserProfile profile) async {
    if (profile.favoriteArtists.isEmpty) return 0.5;
    
    if (profile.favoriteArtists.contains(flash.tattooArtistId)) {
      return 1.0;
    }
    
    // Analyser les artistes similaires basé sur le style
    final similarArtists = await _findSimilarArtists(flash.tattooArtistId, flash.style);
    final hasSimilarArtist = profile.favoriteArtists.any((artistId) => 
        similarArtists.contains(artistId));
    
    return hasSimilarArtist ? 0.7 : 0.3;
  }

  double _calculateTimePreference(Flash flash, UserProfile profile) {
    if (profile.preferredTimeSlots.isEmpty || flash.availableTimeSlots.isEmpty) {
      return 0.5;
    }
    
    // Vérifier si les créneaux disponibles correspondent aux préférences
    final hasMatchingSlot = flash.availableTimeSlots.any((slot) {
      final hour = slot.hour;
      return profile.preferredTimeSlots.any((preferred) {
        final preferredHour = int.tryParse(preferred.split(':')[0]) ?? 12;
        return (hour - preferredHour).abs() <= 2; // ±2h de tolérance
      });
    });
    
    return hasMatchingSlot ? 1.0 : 0.4;
  }

  double _calculateSocialSignals(Flash flash, UserProfile profile) {
    // Signaux sociaux basiques (à améliorer avec vraies données sociales)
    final isVerified = flash.isVerified ? 0.3 : 0.0;
    final isOriginal = flash.isOriginalWork ? 0.3 : 0.0;
    final engagementRate = (flash.likes + flash.saves) / (flash.views + 1);
    final engagementScore = (engagementRate * 0.4).clamp(0.0, 0.4);
    
    return isVerified + isOriginal + engagementScore;
  }

  /// ✅ MÉTHODES UTILITAIRES

  List<String> _getSimilarStyles(String style) {
    final styleGroups = {
      'minimaliste': ['géométrique', 'linéaire', 'simple'],
      'géométrique': ['minimaliste', 'mandala', 'abstrait'],
      'réalisme': ['portrait', 'noir et gris', 'photoréalisme'],
      'traditionnel': ['old school', 'american traditional', 'bold'],
      'aquarelle': ['coloré', 'artistique', 'moderne'],
    };
    
    return styleGroups[style.toLowerCase()] ?? [];
  }

  Future<List<String>> _findSimilarArtists(String artistId, String style) async {
    try {
      // Rechercher des artistes avec un style similaire
      final querySnapshot = await _firestore
          .collection('flashs')
          .where('style', isEqualTo: style)
          .limit(20)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data()['tattooArtistId'] as String)
          .where((id) => id != artistId)
          .toSet()
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ScoredFlash>> _calculateCompatibilityScores(
      UserProfile profile, List<Flash> flashs) async {
    final scoredFlashs = <ScoredFlash>[];
    
    for (final flash in flashs) {
      final score = await calculateCompatibilityScore(flash, profile);
      scoredFlashs.add(ScoredFlash(flash: flash, score: score));
    }
    
    return scoredFlashs;
  }

  /// ✅ GESTION CACHE ET PERSISTANCE

  Future<List<Flash>> _getCachedRecommendations(String userId) async {
    try {
      final doc = await _firestore
          .collection(_recommendationsCollection)
          .doc(userId)
          .get();
      
      if (!doc.exists) return [];
      
      final data = doc.data()!;
      final cachedAt = (data['cachedAt'] as Timestamp).toDate();
      
      // Vérifier validité du cache
      if (DateTime.now().difference(cachedAt) > _cacheValidityDuration) {
        return [];
      }
      
      final flashIds = List<String>.from(data['flashIds'] ?? []);
      final flashs = <Flash>[];
      
      for (final flashId in flashIds) {
        try {
          final flash = await _flashService.getFlashById(flashId);
          flashs.add(flash);
        } catch (e) {
          // Flash supprimé ou inaccessible
          continue;
        }
      }
      
      return flashs;
    } catch (e) {
      return [];
    }
  }

  Future<void> _cacheRecommendations(String userId, List<Flash> flashs) async {
    try {
      await _firestore.collection(_recommendationsCollection).doc(userId).set({
        'flashIds': flashs.map((f) => f.id).toList(),
        'cachedAt': Timestamp.now(),
        'count': flashs.length,
      });
    } catch (e) {
      print('❌ Erreur _cacheRecommendations: $e');
    }
  }

  Future<void> _invalidateRecommendationsCache(String userId) async {
    try {
      await _firestore.collection(_recommendationsCollection).doc(userId).delete();
    } catch (e) {
      print('❌ Erreur _invalidateRecommendationsCache: $e');
    }
  }

  /// ✅ GESTION PROFIL UTILISATEUR

  Future<UserProfile?> _getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_userProfilesCollection).doc(userId).get();
      if (!doc.exists) {
        return await analyzeUserBehavior(userId);
      }
      return UserProfile.fromMap(doc.data()!, userId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_userProfilesCollection)
          .doc(profile.userId)
          .set(profile.toMap());
    } catch (e) {
      print('❌ Erreur _saveUserProfile: $e');
    }
  }

  UserProfile _createDefaultUserProfile(String userId) {
    return UserProfile(
      userId: userId,
      preferredStyles: ['minimaliste', 'géométrique'],
      priceRangeMin: 50.0,
      priceRangeMax: 200.0,
      preferredLocation: 'Paris',
      preferredTimeSlots: ['14:00', '16:00'],
      favoriteArtists: [],
      lastAnalyzed: DateTime.now(),
      interactionCount: 0,
    );
  }

  /// ✅ ANALYSE COMPORTEMENT UTILISATEUR

  Future<List<UserInteraction>> _getUserInteractions(String userId, {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_interactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserInteraction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<String> _analyzeStylePreferences(List<UserInteraction> interactions) {
    final styleCounts = <String, int>{};
    
    for (final interaction in interactions) {
      final style = interaction.metadata?['style'] as String?;
      if (style != null && interaction.action.type == UserActionType.like) {
        styleCounts[style.toLowerCase()] = (styleCounts[style.toLowerCase()] ?? 0) + 1;
      }
    }
    
    return styleCounts.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toList();
  }

  PriceRange _analyzePriceRange(List<UserInteraction> interactions) {
    final prices = <double>[];
    
    for (final interaction in interactions) {
      if (interaction.action.type == UserActionType.view || 
          interaction.action.type == UserActionType.like) {
        final price = interaction.metadata?['price'] as double?;
        if (price != null) prices.add(price);
      }
    }
    
    if (prices.isEmpty) {
      return PriceRange(min: 50.0, max: 200.0);
    }
    
    prices.sort();
    final percentile25 = prices[(prices.length * 0.25).floor()];
    final percentile75 = prices[(prices.length * 0.75).floor()];
    
    return PriceRange(min: percentile25, max: percentile75);
  }

  String? _analyzeLocationPreferences(List<UserInteraction> interactions) {
    final locationCounts = <String, int>{};
    
    for (final interaction in interactions) {
      if (interaction.action.type == UserActionType.view ||
          interaction.action.type == UserActionType.like) {
        final city = interaction.metadata?['city'] as String?;
        if (city != null) {
          locationCounts[city] = (locationCounts[city] ?? 0) + 1;
        }
      }
    }
    
    if (locationCounts.isEmpty) return null;
    
    return locationCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<String> _analyzeTimePreferences(List<UserInteraction> interactions) {
    final timeCounts = <String, int>{};
    
    for (final interaction in interactions) {
      final hour = interaction.timestamp.hour;
      final timeSlot = '${hour.toString().padLeft(2, '0')}:00';
      timeCounts[timeSlot] = (timeCounts[timeSlot] ?? 0) + 1;
    }
    
    return timeCounts.entries
        .where((entry) => entry.value >= 3)
        .map((entry) => entry.key)
        .toList();
  }

  List<String> _analyzeArtistPreferences(List<UserInteraction> interactions) {
    final artistCounts = <String, int>{};
    
    for (final interaction in interactions) {
      if (interaction.action.type == UserActionType.like ||
          interaction.action.type == UserActionType.save) {
        final artistId = interaction.metadata?['tattooArtistId'] as String?;
        if (artistId != null) {
          artistCounts[artistId] = (artistCounts[artistId] ?? 0) + 1;
        }
      }
    }
    
    return artistCounts.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toList();
  }

  /// ✅ MACHINE LEARNING AVANCÉ

  InteractionPatterns _analyzeInteractionPatterns(List<UserInteraction> interactions) {
    // Analyser les patterns d'interaction pour optimiser l'algorithme
    final patterns = InteractionPatterns();
    
    for (final interaction in interactions) {
      patterns.addInteraction(interaction);
    }
    
    return patterns;
  }

  Future<void> _updateAlgorithmWeights(InteractionPatterns patterns) async {
    // Mettre à jour les poids de l'algorithme basé sur les patterns
    // TODO: Implémenter l'optimisation des poids
  }

  List<TrendData> _identifyTrends(List<UserInteraction> interactions) {
    // Identifier les tendances dans les interactions
    final trends = <TrendData>[];
    
    // Analyser les styles tendance
    final styleFrequency = <String, int>{};
    for (final interaction in interactions) {
      final style = interaction.metadata?['style'] as String?;
      if (style != null) {
        styleFrequency[style] = (styleFrequency[style] ?? 0) + 1;
      }
    }
    
    for (final entry in styleFrequency.entries) {
      trends.add(TrendData(
        type: 'style',
        value: entry.key,
        frequency: entry.value,
        score: entry.value / interactions.length,
      ));
    }
    
    return trends;
  }

  Future<void> _updateTrendsDatabase(List<TrendData> trends) async {
    try {
      for (final trend in trends) {
        await _firestore.collection(_trendsCollection).add(trend.toMap());
      }
    } catch (e) {
      print('❌ Erreur _updateTrendsDatabase: $e');
    }
  }

  Future<void> _optimizeRecommendationThresholds(List<UserInteraction> interactions) async {
    // Optimiser les seuils de recommandation basé sur les résultats
    // TODO: Implémenter l'optimisation des seuils
  }

  Future<void> _updateUserProfileFromInteraction(String userId, UserInteraction interaction) async {
    try {
      final profile = await _getUserProfile(userId);
      if (profile == null) return;
      
      // Mettre à jour le profil basé sur l'interaction
      final updatedProfile = profile.copyWith(
        lastInteraction: interaction.timestamp,
        interactionCount: profile.interactionCount + 1,
      );
      
      await _saveUserProfile(updatedProfile);
    } catch (e) {
      print('❌ Erreur _updateUserProfileFromInteraction: $e');
    }
  }

  Future<void> _trackRecommendationGeneration(String userId, int count) async {
    try {
      await _firestore.collection('recommendation_logs').add({
        'userId': userId,
        'recommendationCount': count,
        'timestamp': Timestamp.now(),
        'algorithmVersion': '1.0',
      });
    } catch (e) {
      print('❌ Erreur _trackRecommendationGeneration: $e');
    }
  }

  /// ✅ FALLBACKS ET DONNÉES DÉMO

  Future<List<Flash>> _getDefaultRecommendations(int limit) async {
    try {
      return await _flashService.getAvailableFlashs(limit: limit);
    } catch (e) {
      return await _generateDemoRecommendations(limit);
    }
  }

  Future<List<Flash>> _generateDemoRecommendations(int limit) async {
    // Génération de flashs de démo pour la phase de développement
    final demoFlashs = <Flash>[];
    final random = Random();
    
    final styles = ['Minimaliste', 'Géométrique', 'Réalisme', 'Aquarelle', 'Old School'];
    final titles = ['Rose Délicate', 'Mandala Sacré', 'Dragon Mystique', 'Fleur de Lotus', 'Géométrie Pure'];
    
    for (int i = 0; i < limit; i++) {
      final style = styles[random.nextInt(styles.length)];
      final title = titles[random.nextInt(titles.length)];
      
      demoFlashs.add(Flash(
        id: 'demo_rec_$i',
        title: '$title $i',
        description: 'Flash recommandé par l\'IA',
        imageUrl: 'https://picsum.photos/400/600?random=${200 + i}',
        tattooArtistId: 'demo_artist_${random.nextInt(5)}',
        tattooArtistName: 'Artiste Recommandé ${i % 5 + 1}',
        studioName: 'Studio IA',
        style: style,
        size: '${6 + random.nextInt(4)}x${6 + random.nextInt(4)}cm',
        sizeDescription: 'Taille optimale',
        price: 80.0 + (random.nextInt(120)),
        discountedPrice: null,
        qualityScore: 4.0 + random.nextDouble(),
        latitude: 48.8566 + (random.nextDouble() - 0.5) * 0.1,
        longitude: 2.3522 + (random.nextDouble() - 0.5) * 0.1,
        city: 'Paris',
        country: 'France',
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        updatedAt: DateTime.now(),
      ));
    }
    
    return demoFlashs;
  }
}

/// ✅ MODÈLES DE DONNÉES SPÉCIFIQUES AU RECOMMENDATION ENGINE

class ScoredFlash {
  final Flash flash;
  final double score;
  
  ScoredFlash({required this.flash, required this.score});
}

class UserInteraction {
  final String userId;
  final UserAction action;
  final DateTime timestamp;
  final String? flashId;
  final double? value;
  final Map<String, dynamic>? metadata;
  
  UserInteraction({
    required this.userId,
    required this.action,
    required this.timestamp,
    this.flashId,
    this.value,
    this.metadata,
  });
  
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'action': action.toMap(),
    'timestamp': Timestamp.fromDate(timestamp),
    'flashId': flashId,
    'value': value,
    'metadata': metadata,
  };
  
  static UserInteraction fromMap(Map<String, dynamic> map) => UserInteraction(
    userId: map['userId'],
    action: UserAction.fromMap(map['action']),
    timestamp: (map['timestamp'] as Timestamp).toDate(),
    flashId: map['flashId'],
    value: map['value']?.toDouble(),
    metadata: map['metadata'],
  );
}

class PriceRange {
  final double min;
  final double max;
  
  PriceRange({required this.min, required this.max});
}

class InteractionPatterns {
  final Map<UserActionType, int> actionCounts = {};
  final Map<String, int> styleCounts = {};
  
  void addInteraction(UserInteraction interaction) {
    actionCounts[interaction.action.type] = (actionCounts[interaction.action.type] ?? 0) + 1;
    
    final style = interaction.metadata?['style'] as String?;
    if (style != null) {
      styleCounts[style] = (styleCounts[style] ?? 0) + 1;
    }
  }
}

class TrendData {
  final String type;
  final String value;
  final int frequency;
  final double score;
  
  TrendData({
    required this.type,
    required this.value,
    required this.frequency,
    required this.score,
  });
  
  Map<String, dynamic> toMap() => {
    'type': type,
    'value': value,
    'frequency': frequency,
    'score': score,
    'timestamp': Timestamp.now(),
  };
}