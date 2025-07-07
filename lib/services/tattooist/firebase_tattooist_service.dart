// lib/services/tattooist/firebase_tattooist_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore_helper.dart';
import '../../core/database_manager.dart';
import '../auth/secure_auth_service.dart';

/// Service de tatoueurs unifié (Production + Démo)
/// En mode démo : utilise des profils de tatoueurs factices réalistes
/// En mode production : utilise Firebase Firestore réel
class FirebaseTattooistService {
  static FirebaseTattooistService? _instance;
  static FirebaseTattooistService get instance => _instance ??= FirebaseTattooistService._();
  FirebaseTattooistService._();

  final FirebaseFirestore _firestore = FirestoreHelper.instance;

  // ✅ DONNÉES MOCK POUR LES DÉMOS
  final List<Map<String, dynamic>> _mockTattooists = [];
  final Map<String, Map<String, dynamic>> _mockProfiles = {};

  /// ✅ MÉTHODE PRINCIPALE - Détection automatique du mode
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  /// ✅ OBTENIR TATOUEURS (mode auto)
  Future<List<Map<String, dynamic>>> getTattooists({
    String? city,
    String? style,
    double? maxDistance,
    int limit = 20,
  }) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Récupération tatoueurs factices');
      return await _getTattooistsMock(
        city: city,
        style: style,
        maxDistance: maxDistance,
        limit: limit,
      );
    } else {
      print('🏭 Mode production - Récupération tatoueurs réels');
      return await _getTattooistsFirebase(
        city: city,
        style: style,
        maxDistance: maxDistance,
        limit: limit,
      );
    }
  }

  /// ✅ FIREBASE - Tatoueurs réels
  Future<List<Map<String, dynamic>>> _getTattooistsFirebase({
    String? city,
    String? style,
    double? maxDistance,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'tattooist')
          .where('isActive', isEqualTo: true);

      if (city != null) {
        query = query.where('city', isEqualTo: city);
      }

      if (style != null) {
        query = query.where('specialties', arrayContains: style);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_source'] = 'firebase';
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération tatoueurs Firebase: $e');
    }
  }

  /// ✅ MOCK - Tatoueurs factices
  Future<List<Map<String, dynamic>>> _getTattooistsMock({
    String? city,
    String? style,
    double? maxDistance,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simuler latence

    // Générer les tatoueurs démo si nécessaire
    if (_mockTattooists.isEmpty) {
      _generateMockTattooists();
    }

    // Filtrer selon les critères
    var filteredTattooists = List<Map<String, dynamic>>.from(_mockTattooists);

    if (city != null && city.isNotEmpty) {
      filteredTattooists = filteredTattooists
          .where((t) => t['city'].toString().toLowerCase().contains(city.toLowerCase()))
          .toList();
    }

    if (style != null && style.isNotEmpty) {
      filteredTattooists = filteredTattooists
          .where((t) => (t['specialties'] as List<String>).any(
              (s) => s.toLowerCase().contains(style.toLowerCase())))
          .toList();
    }

    if (maxDistance != null) {
      // Simuler le filtrage par distance (tous les tatoueurs démo sont "proches")
      filteredTattooists = filteredTattooists
          .where((t) => (t['distance'] as double) <= maxDistance)
          .toList();
    }

    // Limiter les résultats
    if (filteredTattooists.length > limit) {
      filteredTattooists = filteredTattooists.take(limit).toList();
    }

    return filteredTattooists;
  }

  /// ✅ OBTENIR PROFIL TATOUEUR (mode auto)
  Future<Map<String, dynamic>?> getTattooistProfile(String tattooistId) async {
    if (_isDemoMode) {
      return await _getTattooistProfileMock(tattooistId);
    } else {
      return await _getTattooistProfileFirebase(tattooistId);
    }
  }

  /// ✅ FIREBASE - Profil réel
  Future<Map<String, dynamic>?> _getTattooistProfileFirebase(String tattooistId) async {
    try {
      final doc = await _firestore.collection('users').doc(tattooistId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      data['_source'] = 'firebase';
      return data;
    } catch (e) {
      print('Erreur récupération profil Firebase: $e');
      return null;
    }
  }

  /// ✅ MOCK - Profil factice
  Future<Map<String, dynamic>?> _getTattooistProfileMock(String tattooistId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Générer les profils si nécessaire
    if (_mockProfiles.isEmpty) {
      _generateMockProfiles();
    }

    return _mockProfiles[tattooistId];
  }

  /// ✅ METTRE À JOUR PROFIL (mode auto)
  Future<void> updateTattooistProfile(Map<String, dynamic> profileData) async {
    if (_isDemoMode) {
      await _updateTattooistProfileMock(profileData);
    } else {
      await _updateTattooistProfileFirebase(profileData);
    }
  }

  /// ✅ FIREBASE - Mise à jour réelle
  Future<void> _updateTattooistProfileFirebase(Map<String, dynamic> profileData) async {
    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final userId = user.uid;
      if (userId == null) throw Exception('ID utilisateur invalide');

      profileData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(userId).update(profileData);
      print('✅ Profil tatoueur mis à jour Firebase: $userId');
    } catch (e) {
      throw Exception('Erreur mise à jour profil Firebase: $e');
    }
  }

  /// ✅ MOCK - Mise à jour factice
  Future<void> _updateTattooistProfileMock(Map<String, dynamic> profileData) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final user = SecureAuthService.instance.currentUser;
    if (user == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final userId = user.uid;
    if (userId == null) throw Exception('[DÉMO] ID utilisateur invalide');

    // Mettre à jour le profil en mémoire
    if (_mockProfiles.containsKey(userId)) {
      _mockProfiles[userId]!.addAll(profileData);
      _mockProfiles[userId]!['updatedAt'] = DateTime.now().toIso8601String();
    } else {
      // Créer un nouveau profil
      _mockProfiles[userId] = {
        'id': userId,
        'role': 'tattooist',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        '_source': 'mock',
        '_demoData': true,
        ...profileData,
      };
    }

    print('✅ Profil tatoueur démo mis à jour: $userId');
  }

  /// ✅ OBTENIR TATOUEURS PAR PROXIMITÉ (mode auto)
  Future<List<Map<String, dynamic>>> getTattooistsByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 10,
  }) async {
    if (_isDemoMode) {
      return await _getTattooistsByLocationMock(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );
    } else {
      return await _getTattooistsByLocationFirebase(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );
    }
  }

  /// ✅ FIREBASE - Proximité réelle
  Future<List<Map<String, dynamic>>> _getTattooistsByLocationFirebase({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 10,
  }) async {
    try {
      // Pour Firebase, on récupère tous les tatoueurs actifs
      // La géolocalisation précise nécessiterait GeoFlutterFire ou similar
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'tattooist')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['distance'] = Random().nextDouble() * radiusKm; // Distance simulée
        data['_source'] = 'firebase';
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur géolocalisation Firebase: $e');
    }
  }

  /// ✅ MOCK - Proximité factice
  Future<List<Map<String, dynamic>>> _getTattooistsByLocationMock({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (_mockTattooists.isEmpty) {
      _generateMockTattooists();
    }

    // Filtrer par rayon et trier par distance
    final nearbyTattooists = _mockTattooists
        .where((t) => (t['distance'] as double) <= radiusKm)
        .toList();

    nearbyTattooists.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    return nearbyTattooists.take(limit).toList();
  }

  /// ✅ RECHERCHER TATOUEURS (mode auto)
  Future<List<Map<String, dynamic>>> searchTattooists({
    required String query,
    String? city,
    List<String>? styles,
    int limit = 20,
  }) async {
    if (_isDemoMode) {
      return await _searchTattooistsMock(
        query: query,
        city: city,
        styles: styles,
        limit: limit,
      );
    } else {
      return await _searchTattooistsFirebase(
        query: query,
        city: city,
        styles: styles,
        limit: limit,
      );
    }
  }

  /// ✅ FIREBASE - Recherche réelle
  Future<List<Map<String, dynamic>>> _searchTattooistsFirebase({
    required String query,
    String? city,
    List<String>? styles,
    int limit = 20,
  }) async {
    try {
      Query baseQuery = _firestore
          .collection('users')
          .where('role', isEqualTo: 'tattooist')
          .where('isActive', isEqualTo: true);

      if (city != null) {
        baseQuery = baseQuery.where('city', isEqualTo: city);
      }

      baseQuery = baseQuery.limit(limit);

      final snapshot = await baseQuery.get();
      final results = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_source'] = 'firebase';
        return data;
      }).toList();

      // Filtrer côté client pour la recherche textuelle
      final queryLower = query.toLowerCase();
      return results.where((tattooist) {
        final name = (tattooist['name'] ?? '').toString().toLowerCase();
        final bio = (tattooist['bio'] ?? '').toString().toLowerCase();
        final specialties = (tattooist['specialties'] as List<dynamic>? ?? [])
            .map((s) => s.toString().toLowerCase()).toList();

        return name.contains(queryLower) ||
               bio.contains(queryLower) ||
               specialties.any((s) => s.contains(queryLower));
      }).toList();
    } catch (e) {
      throw Exception('Erreur recherche tatoueurs Firebase: $e');
    }
  }

  /// ✅ MOCK - Recherche factice
  Future<List<Map<String, dynamic>>> _searchTattooistsMock({
    required String query,
    String? city,
    List<String>? styles,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    if (_mockTattooists.isEmpty) {
      _generateMockTattooists();
    }

    var results = List<Map<String, dynamic>>.from(_mockTattooists);

    // Filtrer par recherche textuelle
    if (query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      results = results.where((tattooist) {
        final name = tattooist['name'].toString().toLowerCase();
        final bio = (tattooist['bio'] ?? '').toString().toLowerCase();
        final specialties = (tattooist['specialties'] as List<String>)
            .map((s) => s.toLowerCase()).toList();

        return name.contains(queryLower) ||
               bio.contains(queryLower) ||
               specialties.any((s) => s.contains(queryLower));
      }).toList();
    }

    // Filtrer par ville
    if (city != null && city.isNotEmpty) {
      results = results.where((t) => 
          t['city'].toString().toLowerCase() == city.toLowerCase()).toList();
    }

    // Filtrer par styles
    if (styles != null && styles.isNotEmpty) {
      results = results.where((t) {
        final tattooistStyles = (t['specialties'] as List<String>)
            .map((s) => s.toLowerCase()).toList();
        return styles.any((style) => 
            tattooistStyles.contains(style.toLowerCase()));
      }).toList();
    }

    return results.take(limit).toList();
  }

  /// ✅ OBTENIR TATOUEURS POPULAIRES (mode auto)
  Future<List<Map<String, dynamic>>> getPopularTattooists({int limit = 10}) async {
    if (_isDemoMode) {
      return await _getPopularTattooistsMock(limit: limit);
    } else {
      return await _getPopularTattooistsFirebase(limit: limit);
    }
  }

  /// ✅ FIREBASE - Populaires réels
  Future<List<Map<String, dynamic>>> _getPopularTattooistsFirebase({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'tattooist')
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['_source'] = 'firebase';
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur tatoueurs populaires Firebase: $e');
    }
  }

  /// ✅ MOCK - Populaires factices
  Future<List<Map<String, dynamic>>> _getPopularTattooistsMock({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_mockTattooists.isEmpty) {
      _generateMockTattooists();
    }

    // Trier par rating et prendre les meilleurs
    final popular = List<Map<String, dynamic>>.from(_mockTattooists);
    popular.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));

    return popular.take(limit).toList();
  }

  // ========================
  // ✅ MÉTHODES DE FAVORIS
  // ========================

  /// ✅ OBTENIR TATOUEURS FAVORIS
  Future<List<Map<String, dynamic>>> getFavoriteTattooists({
    required String userId,
    int limit = 50,
  }) async {
    try {
      if (DatabaseManager.instance.isDemoMode) {
        // Mode démo - Simuler les favoris
        await Future.delayed(const Duration(milliseconds: 600));
        return _generateDemoFavoriteTattooists();
      }

      // Mode production - Firebase réel
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favoriteTattooists')
          .limit(limit)
          .get();

      if (favoritesSnapshot.docs.isEmpty) return [];

      // Récupérer les IDs des tatoueurs favoris
      final favoriteIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();

      // Récupérer les détails des tatoueurs
      final tattooistsData = <Map<String, dynamic>>[];
      
      for (final id in favoriteIds) {
        final tattooistDoc = await _firestore
            .collection('users')
            .doc(id)
            .get();
            
        if (tattooistDoc.exists) {
          final data = tattooistDoc.data()!;
          data['id'] = tattooistDoc.id;
          data['isFavorite'] = true;
          tattooistsData.add(data);
        }
      }

      return tattooistsData;
    } catch (e) {
      throw Exception('Erreur récupération tatoueurs favoris: $e');
    }
  }

  /// ✅ TOGGLE FAVORI TATOUEUR
  Future<bool> toggleFavorite({
    required String tattooistId,
    required String userId,
  }) async {
    try {
      if (DatabaseManager.instance.isDemoMode) {
        // Mode démo - Simulation
        await Future.delayed(const Duration(milliseconds: 300));
        print('🎭 Toggle favori tatoueur simulé: $tattooistId');
        return false; // Simuler la suppression du favori
      }

      // Mode production - Firebase réel
      final favoriteRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favoriteTattooists')
          .doc(tattooistId);

      final favoriteDoc = await favoriteRef.get();

      if (favoriteDoc.exists) {
        // Retirer des favoris
        await favoriteRef.delete();
        return false;
      } else {
        // Ajouter aux favoris
        await favoriteRef.set({
          'addedAt': FieldValue.serverTimestamp(),
          'tattooistId': tattooistId,
        });
        return true;
      }
    } catch (e) {
      throw Exception('Erreur toggle favori tatoueur: $e');
    }
  }

  /// ✅ VÉRIFIER SI FAVORI
  Future<bool> isFavorite({
    required String tattooistId,
    required String userId,
  }) async {
    try {
      if (DatabaseManager.instance.isDemoMode) {
        return false; // En mode démo, pas de favoris persistants
      }

      final favoriteDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favoriteTattooists')
          .doc(tattooistId)
          .get();

      return favoriteDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// ✅ MÉTHODE DE DIAGNOSTIC
  Future<void> debugTattooistService() async {
    print('🔍 Debug FirebaseTattooistService:');
    print('  - Mode démo: $_isDemoMode');
    print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');

    if (_isDemoMode) {
      print('  - Tatoueurs mock générés: ${_mockTattooists.length}');
      print('  - Profils mock en cache: ${_mockProfiles.length}');
    }

    final tattooists = await getTattooists(limit: 5);
    print('  - Total tatoueurs récupérés: ${tattooists.length}');

    if (tattooists.isNotEmpty) {
      final firstTattooist = tattooists.first;
      print('  - Premier tatoueur: ${firstTattooist['name']} (${firstTattooist['city']})');
      print('  - Rating: ${firstTattooist['rating']}/5');
      print('  - Spécialités: ${firstTattooist['specialties']}');
    }

    final currentUser = SecureAuthService.instance.currentUser;
    print('  - Utilisateur connecté: ${currentUser != null ? 'Oui' : 'Non'}');
  }

  // ========================
  // MÉTHODES PRIVÉES - GÉNÉRATION DONNÉES DÉMO
  // ========================

  /// ✅ GÉNÉRATION DONNÉES DÉMO FAVORIS
  List<Map<String, dynamic>> _generateDemoFavoriteTattooists() {
    final cities = ['Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice', 'Nancy'];
    final styles = ['Réalisme', 'Japonais', 'Géométrique', 'Minimaliste', 'Traditionnel', 'Aquarelle'];
    final names = ['Alex Ink', 'Maya Tattoo', 'Vincent Arts', 'Sarah Design', 'Lucas Black', 'Emma Style'];

    return List.generate(4, (i) {
      final city = cities[i % cities.length];
      final name = names[i % names.length];
      final selectedStyles = [styles[i % styles.length], styles[(i + 1) % styles.length]];

      return {
        'id': 'demo_fav_tattooist_$i',
        'name': '$name Favori',
        'email': '${name.toLowerCase().replaceAll(' ', '.')}@demo-fav.com',
        'role': 'tattooist',
        'isActive': true,
        'city': city,
        'address': '${Random().nextInt(200) + 1} Rue Favorite',
        'zipCode': '${Random().nextInt(90000) + 10000}',
        'phone': '+33 6 ${Random().nextInt(90) + 10} ${Random().nextInt(90) + 10} ${Random().nextInt(90) + 10} ${Random().nextInt(90) + 10}',
        'bio': '[DÉMO FAVORI] Tatoueur spécialisé en ${selectedStyles.join(', ')}. Artiste de talent ajouté à vos favoris.',
        'specialties': selectedStyles,
        'rating': (4.2 + (i * 0.2)).clamp(4.2, 4.9),
        'reviewCount': (i + 1) * 25 + 50,
        'experience': (i + 1) * 3 + 5,
        'hourlyRate': (90 + (i * 15)).toDouble(),
        'portfolioImages': [
          'https://picsum.photos/seed/fav_tattoo$i-1/400/600',
          'https://picsum.photos/seed/fav_tattoo$i-2/400/600',
        ],
        'profileImage': 'https://picsum.photos/seed/fav_profile$i/300/300',
        'verified': true,
        'distance': (i + 1) * 2.5,
        'isAvailable': true,
        'isFavorite': true,
        'studioName': '$name Studio Favori',
        'createdAt': DateTime.now().subtract(Duration(days: (i + 1) * 30)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(Duration(days: i + 1)).toIso8601String(),
        '_source': 'demo_favorite',
      };
    });
  }

  void _generateMockTattooists() {
    final cities = ['Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice', 'Nantes', 'Strasbourg', 'Montpellier'];
    final styles = ['Traditionnel', 'Réalisme', 'Japonais', 'Géométrique', 'Minimaliste', 'Old School', 'Biomécanique', 'Aquarelle'];
    final names = ['Alex Ink', 'Maya Tattoo', 'Vincent Arts', 'Sarah Designs', 'Lucas Black', 'Emma Style', 'Théo Créatif', 'Léa Vision'];

    for (int i = 0; i < 12; i++) {
      final city = cities[Random().nextInt(cities.length)];
      final name = names[Random().nextInt(names.length)];
      final selectedStyles = <String>[];
      
      // Chaque tatoueur a 2-4 spécialités
      final numStyles = Random().nextInt(3) + 2;
      while (selectedStyles.length < numStyles) {
        final style = styles[Random().nextInt(styles.length)];
        if (!selectedStyles.contains(style)) {
          selectedStyles.add(style);
        }
      }

      _mockTattooists.add({
        'id': 'demo_tattooist_$i',
        'name': '$name ${i + 1}',
        'email': '${name.toLowerCase().replaceAll(' ', '.')}$i@demo.com',
        'role': 'tattooist',
        'isActive': true,
        'city': city,
        'address': '${Random().nextInt(200) + 1} Rue de l\'Art',
        'zipCode': '${Random().nextInt(90000) + 10000}',
        'phone': '+33 6 ${Random().nextInt(90) + 10} ${Random().nextInt(90) + 10} ${Random().nextInt(90) + 10} ${Random().nextInt(90) + 10}',
        'bio': '[DÉMO] Tatoueur passionné spécialisé en ${selectedStyles.join(', ')}. Plus de ${Random().nextInt(10) + 3} ans d\'expérience.',
        'specialties': selectedStyles,
        'rating': (Random().nextDouble() * 1.5 + 3.5).clamp(3.5, 5.0), // Entre 3.5 et 5.0
        'reviewCount': Random().nextInt(150) + 20,
        'experience': Random().nextInt(15) + 3,
        'hourlyRate': (Random().nextInt(50) + 80).toDouble(), // 80-130€/h
        'portfolioImages': [
          'https://picsum.photos/seed/tattoo$i-1/400/600',
          'https://picsum.photos/seed/tattoo$i-2/400/600',
          'https://picsum.photos/seed/tattoo$i-3/400/600',
          'https://picsum.photos/seed/tattoo$i-4/400/600',
        ],
        'profileImage': 'https://picsum.photos/seed/profile$i/300/300',
        'verified': Random().nextBool(),
        'certifications': Random().nextBool() ? ['Hygiène et Salubrité', 'Formation Professionnelle'] : [],
        'workingHours': {
          'monday': '09:00-18:00',
          'tuesday': '09:00-18:00',
          'wednesday': '09:00-18:00',
          'thursday': '09:00-18:00',
          'friday': '09:00-20:00',
          'saturday': '10:00-19:00',
          'sunday': 'Fermé',
        },
        'socialMedia': {
          'instagram': '@${name.toLowerCase().replaceAll(' ', '_')}_tattoo',
          'facebook': '$name Tattoo Studio',
        },
        'distance': Random().nextDouble() * 45 + 2, // 2-47 km
        'isAvailable': Random().nextBool(),
        'nextAvailableDate': DateTime.now().add(Duration(days: Random().nextInt(14) + 1)).toIso8601String(),
        'studioName': '$name Studio',
        'equipment': ['Machine rotative', 'Machine bobine', 'Équipement stérilisé'],
        'languages': ['Français', if (Random().nextBool()) 'Anglais', if (Random().nextBool()) 'Espagnol'],
        'createdAt': DateTime.now().subtract(Duration(days: Random().nextInt(365) + 30)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(Duration(days: Random().nextInt(7))).toIso8601String(),
        '_source': 'mock',
        '_demoData': true,
      });
    }

    print('✅ ${_mockTattooists.length} tatoueurs démo générés');
  }

  void _generateMockProfiles() {
    for (final tattooist in _mockTattooists) {
      _mockProfiles[tattooist['id']] = Map<String, dynamic>.from(tattooist);
    }

    // Ajouter le profil de l'utilisateur connecté s'il est tatoueur
    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser != null) {
      final userId = currentUser.uid;
      if (userId != null && !_mockProfiles.containsKey(userId)) {
        _mockProfiles[userId] = {
          'id': userId,
          'name': '[DÉMO] Votre Profil',
          'email': currentUser.email ?? 'demo@kipik.app',
          'role': 'tattooist',
          'isActive': true,
          'city': 'Paris',
          'bio': '[DÉMO] Votre profil de tatoueur professionnel. Personnalisez vos informations.',
          'specialties': ['Traditionnel', 'Réalisme'],
          'rating': 4.2,
          'reviewCount': 15,
          'experience': 5,
          'hourlyRate': 100.0,
          'portfolioImages': [
            'https://picsum.photos/seed/demo-portfolio-1/400/600',
            'https://picsum.photos/seed/demo-portfolio-2/400/600',
          ],
          'profileImage': 'https://picsum.photos/seed/demo-profile/300/300',
          'verified': false,
          'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          '_source': 'mock',
          '_demoData': true,
        };
      }
    }

    print('✅ ${_mockProfiles.length} profils de tatoueurs générés');
  }
}