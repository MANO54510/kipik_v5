// lib/services/guest/guest_service.dart

import 'dart:async';
import '../../models/guest_mission.dart';
import '../../models/user_profile.dart';

class GuestService {
  static final GuestService _instance = GuestService._internal();
  static GuestService get instance => _instance;
  GuestService._internal();

  // Streams pour temps réel
  final StreamController<List<GuestMission>> _missionsController = 
      StreamController<List<GuestMission>>.broadcast();
  final StreamController<GuestStats> _statsController = 
      StreamController<GuestStats>.broadcast();

  Stream<List<GuestMission>> get missionsStream => _missionsController.stream;
  Stream<GuestStats> get statsStream => _statsController.stream;

  // Cache local
  List<GuestMission> _cachedMissions = [];
  GuestStats _cachedStats = GuestStats.empty();
  DateTime? _lastUpdate;

  // ==================== MISSIONS ====================

  /// Récupère toutes les missions actives pour un utilisateur
  Future<List<GuestMission>> getActiveMissions(String userId) async {
    try {
      // Simulation API call avec données réalistes
      await Future.delayed(const Duration(milliseconds: 800));
      
      final missions = _generateSampleActiveMissions(userId);
      _updateCache(missions);
      
      return missions;
    } catch (e) {
      throw GuestServiceException('Erreur lors du chargement des missions actives: $e');
    }
  }

  /// Récupère les demandes en attente
  Future<List<GuestMission>> getPendingRequests(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      final requests = _generateSamplePendingRequests(userId);
      return requests;
    } catch (e) {
      throw GuestServiceException('Erreur lors du chargement des demandes: $e');
    }
  }

  /// Récupère les demandes reçues
  Future<List<GuestMission>> getIncomingRequests(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      
      final incoming = _generateSampleIncomingRequests(userId);
      return incoming;
    } catch (e) {
      throw GuestServiceException('Erreur lors du chargement des demandes reçues: $e');
    }
  }

  /// Accepte une mission guest
  Future<bool> acceptMission(String missionId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Logique d'acceptation
      _updateMissionStatus(missionId, GuestMissionStatus.accepted);
      
      return true;
    } catch (e) {
      throw GuestServiceException('Erreur lors de l\'acceptation: $e');
    }
  }

  /// Refuse une mission guest
  Future<bool> declineMission(String missionId, String? reason) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Logique de refus
      _updateMissionStatus(missionId, GuestMissionStatus.cancelled);
      
      return true;
    } catch (e) {
      throw GuestServiceException('Erreur lors du refus: $e');
    }
  }

  /// Active une mission (après signature contrat)
  Future<bool> activateMission(String missionId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1200));
      
      // Logique d'activation complète
      _updateMissionStatus(missionId, GuestMissionStatus.active);
      
      // Déclencher intégration calendrier automatique
      await _integrateToCalendar(missionId);
      
      return true;
    } catch (e) {
      throw GuestServiceException('Erreur lors de l\'activation: $e');
    }
  }

  // ==================== OPPORTUNITÉS ====================

  /// Récupère les opportunités suggérées
  Future<List<GuestOpportunity>> getSuggestedOpportunities(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 900));
      
      final opportunities = _generateSampleOpportunities(userId);
      return opportunities;
    } catch (e) {
      throw GuestServiceException('Erreur lors du chargement des opportunités: $e');
    }
  }

  /// Recherche d'opportunités avec filtres
  Future<List<GuestOpportunity>> searchOpportunities({
    String? location,
    List<String>? styles,
    DateTime? availableFrom,
    DateTime? availableTo,
    double? minCommission,
    double? maxCommission,
    bool? accommodationRequired,
    OpportunityType? type,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Logique de recherche avec filtres
      final allOpportunities = _generateSampleOpportunities('current_user');
      
      // Filtrage basique (à améliorer)
      var filtered = allOpportunities.where((opp) {
        if (location != null && !opp.location.toLowerCase().contains(location.toLowerCase())) {
          return false;
        }
        if (styles != null && !styles.any((style) => opp.styles.contains(style))) {
          return false;
        }
        if (type != null && opp.type != type) {
          return false;
        }
        return true;
      }).toList();
      
      return filtered;
    } catch (e) {
      throw GuestServiceException('Erreur lors de la recherche: $e');
    }
  }

  /// Postule à une opportunité
  Future<bool> applyToOpportunity(String opportunityId, Map<String, dynamic> proposal) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Logique de candidature
      return true;
    } catch (e) {
      throw GuestServiceException('Erreur lors de la candidature: $e');
    }
  }

  // ==================== STATISTIQUES ====================

  /// Récupère les statistiques guest
  Future<GuestStats> getGuestStats(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      final stats = _generateSampleStats(userId);
      _cachedStats = stats;
      _statsController.add(stats);
      
      return stats;
    } catch (e) {
      throw GuestServiceException('Erreur lors du chargement des stats: $e');
    }
  }

  /// Refresh complet des données
  Future<void> refreshAll(String userId) async {
    try {
      await Future.wait([
        getActiveMissions(userId),
        getPendingRequests(userId),
        getIncomingRequests(userId),
        getGuestStats(userId),
      ]);
    } catch (e) {
      throw GuestServiceException('Erreur lors du refresh: $e');
    }
  }

  // ==================== INTÉGRATIONS ====================

  /// Intègre automatiquement mission au calendrier
  Future<bool> _integrateToCalendar(String missionId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Logique d'intégration calendrier
      // - Créer événements début/fin mission
      // - Modifier localisation temporaire
      // - Bloquer créneaux conflictuels
      // - Sync calendrier externe
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Met à jour la localisation pour une mission
  Future<bool> updateLocationForMission(String missionId, String newLocation) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Logique de changement localisation
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restore la localisation après mission
  Future<bool> restoreOriginalLocation(String missionId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Logique de restauration
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== CACHE & UTILS ====================

  void _updateCache(List<GuestMission> missions) {
    _cachedMissions = missions;
    _lastUpdate = DateTime.now();
    _missionsController.add(missions);
  }

  void _updateMissionStatus(String missionId, GuestMissionStatus newStatus) {
    final index = _cachedMissions.indexWhere((m) => m.id == missionId);
    if (index != -1) {
      _cachedMissions[index] = _cachedMissions[index].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      _missionsController.add(_cachedMissions);
    }
  }

  bool get isCacheValid {
    if (_lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!).inMinutes < 5;
  }

  void clearCache() {
    _cachedMissions.clear();
    _cachedStats = GuestStats.empty();
    _lastUpdate = null;
  }

  void dispose() {
    _missionsController.close();
    _statsController.close();
  }

  // ==================== DONNÉES SAMPLE ====================

  List<GuestMission> _generateSampleActiveMissions(String userId) {
    return [
      GuestMission(
        id: 'mission_1',
        guestId: 'emma_chen',
        shopId: userId,
        guestName: 'Emma Chen',
        shopName: 'Mon Studio',
        location: 'Mon studio',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 9)),
        type: GuestMissionType.incoming,
        status: GuestMissionStatus.active,
        commissionRate: 0.25,
        accommodationIncluded: false,
        styles: ['Japonais', 'Traditionnel'],
        description: 'Mission guest japonais traditionnel',
        totalRevenue: 1250.0,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      GuestMission(
        id: 'mission_2',
        guestId: userId,
        shopId: 'ink_studio_paris',
        guestName: 'Moi',
        shopName: 'Ink Studio Paris',
        location: 'Paris 9ème',
        startDate: DateTime.now().add(const Duration(days: 20)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        type: GuestMissionType.outgoing,
        status: GuestMissionStatus.accepted,
        commissionRate: 0.20,
        accommodationIncluded: true,
        styles: ['Réalisme', 'Portrait'],
        description: 'Guest dans studio parisien réputé',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  List<GuestMission> _generateSamplePendingRequests(String userId) {
    return [
      GuestMission(
        id: 'pending_1',
        guestId: userId,
        shopId: 'black_art_lyon',
        guestName: 'Moi',
        shopName: 'Black Art Lyon',
        location: 'Lyon',
        startDate: DateTime.now().add(const Duration(days: 45)),
        endDate: DateTime.now().add(const Duration(days: 55)),
        type: GuestMissionType.outgoing,
        status: GuestMissionStatus.pending,
        commissionRate: 0.30,
        accommodationIncluded: false,
        styles: ['Black & Grey'],
        description: 'Demande guest Black & Grey spécialisé',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }

  List<GuestMission> _generateSampleIncomingRequests(String userId) {
    return [
      GuestMission(
        id: 'incoming_1',
        guestId: 'alex_martin',
        shopId: userId,
        guestName: 'Alex Martin',
        shopName: 'Mon Studio',
        location: 'Mon studio',
        startDate: DateTime.now().add(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 25)),
        type: GuestMissionType.incoming,
        status: GuestMissionStatus.pending,
        commissionRate: 0.25,
        accommodationIncluded: true,
        styles: ['Réalisme', 'Portrait'],
        description: 'Guest réalisme expérimenté recherche collaboration',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      GuestMission(
        id: 'incoming_2',
        guestId: 'sofia_rodriguez',
        shopId: userId,
        guestName: 'Sofia Rodriguez',
        shopName: 'Mon Studio',
        location: 'Mon studio',
        startDate: DateTime.now().add(const Duration(days: 60)),
        endDate: DateTime.now().add(const Duration(days: 81)),
        type: GuestMissionType.incoming,
        status: GuestMissionStatus.pending,
        commissionRate: 0.30,
        accommodationIncluded: true,
        styles: ['Couleur', 'Neo-traditionnel'],
        description: 'Artiste couleur recherche studio accueillant',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  List<GuestOpportunity> _generateSampleOpportunities(String userId) {
    return [
      GuestOpportunity(
        id: 'opp_1',
        ownerId: 'studio_nice',
        ownerName: 'Nice Tattoo Studio',
        type: OpportunityType.shop,
        status: OpportunityStatus.open,
        location: 'Nice',
        availableFrom: DateTime.now().add(const Duration(days: 30)),
        availableTo: DateTime.now().add(const Duration(days: 44)),
        styles: ['Tous styles'],
        description: 'Studio en bord de mer recherche guest talentueux pour l\'été',
        commissionRate: 0.20,
        accommodationProvided: true,
        accommodationRequired: false,
        experienceLevel: 'Confirmé',
        rating: 4.8,
        reviewCount: 156,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      GuestOpportunity(
        id: 'opp_2',
        ownerId: 'marie_dubois',
        ownerName: 'Marie Dubois',
        type: OpportunityType.guest,
        status: OpportunityStatus.open,
        location: 'Bordeaux',
        availableFrom: DateTime.now().add(const Duration(days: 20)),
        availableTo: DateTime.now().add(const Duration(days: 27)),
        styles: ['Minimaliste', 'Fine line'],
        description: 'Artiste fine line disponible pour guest d\'une semaine',
        commissionRate: 0.25,
        accommodationProvided: false,
        accommodationRequired: true,
        experienceLevel: 'Expert',
        rating: 4.9,
        reviewCount: 89,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  GuestStats _generateSampleStats(String userId) {
    return GuestStats(
      totalMissions: 8,
      activeMissions: 2,
      completedMissions: 5,
      pendingRequests: 1,
      incomingRequests: 2,
      totalRevenue: 15420.0,
      monthlyRevenue: 1250.0,
      averageRating: 4.7,
      totalReviews: 23,
      missionsByStatus: {
        'completed': 5,
        'active': 2,
        'pending': 1,
      },
      revenueByMonth: {
        'Jan': 980.0,
        'Feb': 1250.0,
        'Mar': 1890.0,
        'Apr': 2100.0,
        'May': 1250.0,
      },
    );
  }
}

// ==================== EXCEPTIONS ====================

class GuestServiceException implements Exception {
  final String message;
  const GuestServiceException(this.message);
  
  @override
  String toString() => 'GuestServiceException: $message';
}