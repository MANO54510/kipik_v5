// lib/services/inspiration/firebase_inspiration_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore_helper.dart';
import '../../core/database_manager.dart';
import '../auth/secure_auth_service.dart';

/// Service d'inspirations unifié (Production + Démo)
/// En mode démo : utilise des posts d'inspiration factices
/// En mode production : utilise Firebase Firestore réel
class FirebaseInspirationService {
  static FirebaseInspirationService? _instance;
  static FirebaseInspirationService get instance => _instance ??= FirebaseInspirationService._();
  FirebaseInspirationService._();

  final FirebaseFirestore _firestore = FirestoreHelper.instance;

  // ✅ DONNÉES MOCK POUR LES DÉMOS
  final List<Map<String, dynamic>> _mockInspirations = [];
  final Map<String, List<Map<String, dynamic>>> _mockInspirationsByAuthor = {};

  /// ✅ MÉTHODE PRINCIPALE - Détection automatique du mode
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  /// ✅ OBTENIR INSPIRATIONS (mode auto) - AVEC SUPPORT authorId
  Future<List<Map<String, dynamic>>> getInspirations({
    String? style,
    String? category,
    String? authorId, // ✅ AJOUTÉ pour filtrer par auteur
    int limit = 20,
  }) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Récupération inspirations factices');
      return await _getInspirationsMock(
        style: style,
        category: category,
        authorId: authorId,
        limit: limit,
      );
    } else {
      print('🏭 Mode production - Récupération inspirations réelles');
      return await _getInspirationsFirebase(
        style: style,
        category: category,
        authorId: authorId,
        limit: limit,
      );
    }
  }

  /// ✅ FIREBASE - Inspirations réelles
  Future<List<Map<String, dynamic>>> _getInspirationsFirebase({
    String? style,
    String? category,
    String? authorId,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('inspirations');

      if (authorId != null) {
        query = query.where('authorId', isEqualTo: authorId);
      }

      if (style != null) {
        query = query.where('style', isEqualTo: style);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      query = query
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_source'] = 'firebase';
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération inspirations Firebase: $e');
    }
  }

  /// ✅ MOCK - Inspirations factices
  Future<List<Map<String, dynamic>>> _getInspirationsMock({
    String? style,
    String? category,
    String? authorId,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simuler latence

    // Générer les inspirations démo si nécessaire
    if (_mockInspirations.isEmpty) {
      _generateMockInspirations();
    }

    // Filtrer selon les critères
    var filteredInspirations = List<Map<String, dynamic>>.from(_mockInspirations);

    if (authorId != null && authorId.isNotEmpty) {
      filteredInspirations = filteredInspirations
          .where((inspiration) => inspiration['authorId'] == authorId)
          .toList();
    }

    if (style != null && style.isNotEmpty) {
      filteredInspirations = filteredInspirations
          .where((inspiration) => inspiration['style']?.toString().toLowerCase().contains(style.toLowerCase()) ?? false)
          .toList();
    }

    if (category != null && category.isNotEmpty) {
      filteredInspirations = filteredInspirations
          .where((inspiration) => inspiration['category']?.toString().toLowerCase().contains(category.toLowerCase()) ?? false)
          .toList();
    }

    // Limiter les résultats
    if (filteredInspirations.length > limit) {
      filteredInspirations = filteredInspirations.take(limit).toList();
    }

    return filteredInspirations;
  }

  /// ✅ AJOUTER INSPIRATION (mode auto)
  Future<void> addInspiration({
    required String title,
    required String imageUrl,
    required String style,
    required String category,
    String? description,
    List<String>? tags,
    String? authorId,
    String? authorName,
  }) async {
    if (_isDemoMode) {
      await _addInspirationMock(
        title: title,
        imageUrl: imageUrl,
        style: style,
        category: category,
        description: description,
        tags: tags,
        authorId: authorId,
        authorName: authorName,
      );
    } else {
      await _addInspirationFirebase(
        title: title,
        imageUrl: imageUrl,
        style: style,
        category: category,
        description: description,
        tags: tags,
        authorId: authorId,
        authorName: authorName,
      );
    }
  }

  /// ✅ FIREBASE - Ajout réel
  Future<void> _addInspirationFirebase({
    required String title,
    required String imageUrl,
    required String style,
    required String category,
    String? description,
    List<String>? tags,
    String? authorId,
    String? authorName,
  }) async {
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      
      await _firestore.collection('inspirations').add({
        'title': title,
        'imageUrl': imageUrl,
        'style': style,
        'category': category,
        'description': description ?? '',
        'tags': tags ?? [],
        'authorId': authorId ?? currentUser?.uid,
        'authorName': authorName ?? currentUser?.name ?? 'Utilisateur',
        'isPublic': true,
        'likes': 0,
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur ajout inspiration Firebase: $e');
    }
  }

  /// ✅ MOCK - Ajout factice
  Future<void> _addInspirationMock({
    required String title,
    required String imageUrl,
    required String style,
    required String category,
    String? description,
    List<String>? tags,
    String? authorId,
    String? authorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final currentUser = SecureAuthService.instance.currentUser;
    final newInspiration = {
      'id': 'demo_inspiration_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'imageUrl': imageUrl,
      'style': style,
      'category': category,
      'description': description ?? '',
      'tags': tags ?? [],
      'authorId': authorId ?? currentUser?.uid ?? 'demo_user',
      'authorName': authorName ?? currentUser?.name ?? '[DÉMO] Utilisateur',
      'isPublic': true,
      'likes': Random().nextInt(50),
      'views': Random().nextInt(200) + 50,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      '_source': 'mock',
      '_demoData': true,
    };

    _mockInspirations.insert(0, newInspiration); // Ajouter au début
    print('✅ Inspiration démo ajoutée: $title');
  }

  // ========================
  // ✅ MÉTHODES DE FAVORIS
  // ========================

  /// ✅ OBTENIR INSPIRATIONS FAVORITES
  Future<List<Map<String, dynamic>>> getFavoriteInspirations({
    required String userId,
    int limit = 50,
  }) async {
    try {
      if (DatabaseManager.instance.isDemoMode) {
        // Mode démo - Simuler les favoris
        await Future.delayed(const Duration(milliseconds: 600));
        return _generateDemoFavoriteInspirations();
      }

      // Mode production - Firebase réel
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favoriteInspirations')
          .limit(limit)
          .get();

      if (favoritesSnapshot.docs.isEmpty) return [];

      // Récupérer les IDs des inspirations favorites
      final favoriteIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();

      // Récupérer les détails des inspirations
      final inspirationsData = <Map<String, dynamic>>[];
      
      for (final id in favoriteIds) {
        final inspirationDoc = await _firestore
            .collection('inspirations')
            .doc(id)
            .get();
            
        if (inspirationDoc.exists) {
          final data = inspirationDoc.data()!;
          data['id'] = inspirationDoc.id;
          data['isFavorite'] = true;
          inspirationsData.add(data);
        }
      }

      return inspirationsData;
    } catch (e) {
      throw Exception('Erreur récupération inspirations favorites: $e');
    }
  }

  /// ✅ TOGGLE FAVORI INSPIRATION
  Future<bool> toggleFavorite({
    required String inspirationId,
    required String userId,
  }) async {
    try {
      if (DatabaseManager.instance.isDemoMode) {
        // Mode démo - Simulation
        await Future.delayed(const Duration(milliseconds: 300));
        print('🎭 Toggle favori inspiration simulé: $inspirationId');
        return false; // Simuler la suppression du favori
      }

      // Mode production - Firebase réel
      final favoriteRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favoriteInspirations')
          .doc(inspirationId);

      final favoriteDoc = await favoriteRef.get();

      if (favoriteDoc.exists) {
        // Retirer des favoris
        await favoriteRef.delete();
        
        // Décrémenter le compteur de likes
        await _firestore.collection('inspirations').doc(inspirationId).update({
          'likes': FieldValue.increment(-1),
        });
        
        return false;
      } else {
        // Ajouter aux favoris
        await favoriteRef.set({
          'addedAt': FieldValue.serverTimestamp(),
          'inspirationId': inspirationId,
        });
        
        // Incrémenter le compteur de likes
        await _firestore.collection('inspirations').doc(inspirationId).update({
          'likes': FieldValue.increment(1),
        });
        
        return true;
      }
    } catch (e) {
      throw Exception('Erreur toggle favori inspiration: $e');
    }
  }

  /// ✅ VÉRIFIER SI FAVORI
  Future<bool> isFavorite({
    required String inspirationId,
    required String userId,
  }) async {
    try {
      if (DatabaseManager.instance.isDemoMode) {
        return false; // En mode démo, pas de favoris persistants
      }

      final favoriteDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favoriteInspirations')
          .doc(inspirationId)
          .get();

      return favoriteDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// ✅ RECHERCHER INSPIRATIONS
  Future<List<Map<String, dynamic>>> searchInspirations({
    required String query,
    String? style,
    String? category,
    int limit = 20,
  }) async {
    if (_isDemoMode) {
      return await _searchInspirationsMock(
        query: query,
        style: style,
        category: category,
        limit: limit,
      );
    } else {
      return await _searchInspirationsFirebase(
        query: query,
        style: style,
        category: category,
        limit: limit,
      );
    }
  }

  /// ✅ FIREBASE - Recherche réelle
  Future<List<Map<String, dynamic>>> _searchInspirationsFirebase({
    required String query,
    String? style,
    String? category,
    int limit = 20,
  }) async {
    try {
      Query baseQuery = _firestore
          .collection('inspirations')
          .where('isPublic', isEqualTo: true);

      if (style != null) {
        baseQuery = baseQuery.where('style', isEqualTo: style);
      }

      if (category != null) {
        baseQuery = baseQuery.where('category', isEqualTo: category);
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
      return results.where((inspiration) {
        final title = (inspiration['title'] ?? '').toString().toLowerCase();
        final description = (inspiration['description'] ?? '').toString().toLowerCase();
        final tags = (inspiration['tags'] as List<dynamic>? ?? [])
            .map((t) => t.toString().toLowerCase()).toList();

        return title.contains(queryLower) ||
               description.contains(queryLower) ||
               tags.any((t) => t.contains(queryLower));
      }).toList();
    } catch (e) {
      throw Exception('Erreur recherche inspirations Firebase: $e');
    }
  }

  /// ✅ MOCK - Recherche factice
  Future<List<Map<String, dynamic>>> _searchInspirationsMock({
    required String query,
    String? style,
    String? category,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    if (_mockInspirations.isEmpty) {
      _generateMockInspirations();
    }

    var results = List<Map<String, dynamic>>.from(_mockInspirations);

    // Filtrer par recherche textuelle
    if (query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      results = results.where((inspiration) {
        final title = inspiration['title'].toString().toLowerCase();
        final description = (inspiration['description'] ?? '').toString().toLowerCase();
        final tags = (inspiration['tags'] as List<dynamic>? ?? [])
            .map((t) => t.toString().toLowerCase()).toList();

        return title.contains(queryLower) ||
               description.contains(queryLower) ||
               tags.any((t) => t.contains(queryLower));
      }).toList();
    }

    // Filtrer par style
    if (style != null && style.isNotEmpty) {
      results = results.where((i) => 
          i['style'].toString().toLowerCase() == style.toLowerCase()).toList();
    }

    // Filtrer par catégorie
    if (category != null && category.isNotEmpty) {
      results = results.where((i) => 
          i['category'].toString().toLowerCase() == category.toLowerCase()).toList();
    }

    return results.take(limit).toList();
  }

  /// ✅ OBTENIR INSPIRATIONS POPULAIRES
  Future<List<Map<String, dynamic>>> getPopularInspirations({int limit = 10}) async {
    if (_isDemoMode) {
      return await _getPopularInspirationsMock(limit: limit);
    } else {
      return await _getPopularInspirationsFirebase(limit: limit);
    }
  }

  /// ✅ FIREBASE - Populaires réelles
  Future<List<Map<String, dynamic>>> _getPopularInspirationsFirebase({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('inspirations')
          .where('isPublic', isEqualTo: true)
          .orderBy('likes', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['_source'] = 'firebase';
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur inspirations populaires Firebase: $e');
    }
  }

  /// ✅ MOCK - Populaires factices
  Future<List<Map<String, dynamic>>> _getPopularInspirationsMock({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_mockInspirations.isEmpty) {
      _generateMockInspirations();
    }

    // Trier par likes et prendre les plus populaires
    final popular = List<Map<String, dynamic>>.from(_mockInspirations);
    popular.sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));

    return popular.take(limit).toList();
  }

  /// ✅ MÉTHODE DE DIAGNOSTIC
  Future<void> debugInspirationService() async {
    print('🔍 Debug FirebaseInspirationService:');
    print('  - Mode démo: $_isDemoMode');
    print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');

    if (_isDemoMode) {
      print('  - Inspirations mock générées: ${_mockInspirations.length}');
    }

    final inspirations = await getInspirations(limit: 5);
    print('  - Total inspirations récupérées: ${inspirations.length}');

    if (inspirations.isNotEmpty) {
      final firstInspiration = inspirations.first;
      print('  - Première inspiration: ${firstInspiration['title']} (${firstInspiration['style']})');
      print('  - Likes: ${firstInspiration['likes']}');
      print('  - Auteur: ${firstInspiration['authorName']}');
    }
  }

  // ========================
  // MÉTHODES PRIVÉES - GÉNÉRATION DONNÉES DÉMO
  // ========================

  /// ✅ GÉNÉRATION DONNÉES DÉMO FAVORIS
  List<Map<String, dynamic>> _generateDemoFavoriteInspirations() {
    final styles = ['Réalisme', 'Japonais', 'Géométrique', 'Minimaliste', 'Traditionnel', 'Aquarelle'];
    final authors = ['Alex Ink', 'Maya Tattoo', 'Vincent Arts', 'Sarah Design', 'Lucas Black', 'Emma Style'];

    return List.generate(6, (i) {
      final style = styles[i % styles.length];
      final author = authors[i % authors.length];

      return {
        'id': 'demo_fav_inspiration_$i',
        'title': '$style Favori ${i + 1}',
        'imageUrl': 'https://picsum.photos/seed/fav_inspiration$i/400/600',
        'description': '[DÉMO FAVORI] Magnifique œuvre de $style par $author. Design unique et créatif.',
        'style': style,
        'category': 'Tatouage',
        'authorId': 'demo_author_$i',
        'authorName': '$author Favori',
        'tags': [style, 'Favori', 'Démo'],
        'likes': (i + 1) * 15 + 25, // Entre 40 et 115 likes
        'views': (i + 1) * 40 + 80,
        'isPublic': true,
        'isFavorite': true,
        'createdAt': DateTime.now().subtract(Duration(days: (i + 1) * 5)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(Duration(days: i + 1)).toIso8601String(),
        '_source': 'demo_favorite',
      };
    });
  }

  void _generateMockInspirations() {
    final styles = ['Réalisme', 'Japonais', 'Géométrique', 'Minimaliste', 'Traditionnel', 'Old School', 'Biomécanique', 'Aquarelle'];
    final categories = ['Tatouage', 'Design', 'Art', 'Illustration'];
    final authors = ['Alex Ink', 'Maya Tattoo', 'Vincent Arts', 'Sarah Designs', 'Lucas Black', 'Emma Style', 'Théo Créatif', 'Léa Vision'];

    // Générer 20 inspirations générales
    for (int i = 0; i < 20; i++) {
      final style = styles[Random().nextInt(styles.length)];
      final category = categories[Random().nextInt(categories.length)];
      final author = authors[Random().nextInt(authors.length)];

      final inspiration = {
        'id': 'demo_inspiration_$i',
        'title': '$style par $author',
        'imageUrl': 'https://picsum.photos/seed/inspiration$i/400/600',
        'description': '[DÉMO] Magnifique œuvre de $style réalisée par $author. Design unique et créatif.',
        'style': style,
        'category': category,
        'authorId': 'demo_author_${i % authors.length}',
        'authorName': author,
        'tags': [style, category, 'Art'],
        'likes': Random().nextInt(100) + 20,
        'views': Random().nextInt(500) + 100,
        'isPublic': true,
        'createdAt': DateTime.now().subtract(Duration(days: Random().nextInt(30) + 1)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(Duration(days: Random().nextInt(7))).toIso8601String(),
        '_source': 'mock',
        '_demoData': true,
      };

      _mockInspirations.add(inspiration);

      // Grouper par auteur pour faciliter la recherche
      final authorId = inspiration['authorId'] as String;
      if (!_mockInspirationsByAuthor.containsKey(authorId)) {
        _mockInspirationsByAuthor[authorId] = [];
      }
      _mockInspirationsByAuthor[authorId]!.add(inspiration);
    }

    // Ajouter des inspirations pour des tatoueurs spécifiques (ceux utilisés dans l'app)
    final specificTattooists = [
      {'id': 'demotatoueur1', 'name': 'Alex Dubois', 'style': 'Réaliste'},
      {'id': 'demotatoueur2', 'name': 'Sophie Martinez', 'style': 'Minimaliste'},
      {'id': 'demotatoueur3', 'name': 'Marc Dubois', 'style': 'Black & Grey'},
    ];

    for (final tattooist in specificTattooists) {
      for (int j = 0; j < 4; j++) {
        final inspiration = {
          'id': 'demo_inspiration_${tattooist['id']}_$j',
          'title': '${tattooist['style']} par ${tattooist['name']}',
          'imageUrl': 'https://picsum.photos/seed/${tattooist['id']}_$j/400/600',
          'description': '[DÉMO] Réalisation ${tattooist['style']} par ${tattooist['name']}. Œuvre professionnelle et créative.',
          'style': tattooist['style']!,
          'category': 'Tatouage',
          'authorId': tattooist['id']!,
          'authorName': tattooist['name']!,
          'tags': [tattooist['style']!, 'Professionnel', 'Démo'],
          'likes': Random().nextInt(80) + 30,
          'views': Random().nextInt(300) + 150,
          'isPublic': true,
          'createdAt': DateTime.now().subtract(Duration(days: j * 3 + 1)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(Duration(days: j + 1)).toIso8601String(),
          '_source': 'mock',
          '_demoData': true,
        };

        _mockInspirations.add(inspiration);

        // Grouper par auteur
        final authorId = inspiration['authorId'] as String;
        if (!_mockInspirationsByAuthor.containsKey(authorId)) {
          _mockInspirationsByAuthor[authorId] = [];
        }
        _mockInspirationsByAuthor[authorId]!.add(inspiration);
      }
    }

    print('✅ ${_mockInspirations.length} inspirations démo générées');
    print('✅ ${_mockInspirationsByAuthor.length} auteurs avec inspirations');
  }
}