// lib/services/portfolio_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/models/portfolio_model.dart';
import '../core/database_manager.dart';

/// 🎨 Service pour la gestion des portfolios/réalisations des tatoueurs
/// Gère toutes les opérations CRUD et business logic des portfolios
class PortfolioService {
  static const String collectionName = 'portfolios';
  
  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _collection;

  PortfolioService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? DatabaseManager.instance.firestore {
    _collection = _firestore.collection(collectionName);
  }

  // ===== OPÉRATIONS CRUD =====

  /// Créer un nouveau portfolio
  Future<Portfolio> createPortfolio(Portfolio portfolio) async {
    try {
      final newPortfolio = portfolio.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _collection.add(newPortfolio.toFirestore());
      
      return newPortfolio.copyWith(id: docRef.id);
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la création du portfolio: $e');
    }
  }

  /// Récupérer un portfolio par ID
  Future<Portfolio?> getPortfolioById(String portfolioId) async {
    try {
      final doc = await _collection.doc(portfolioId).get();
      
      if (!doc.exists) return null;
      
      return Portfolio.fromFirestore(doc);
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la récupération du portfolio: $e');
    }
  }

  /// Mettre à jour un portfolio
  Future<Portfolio> updatePortfolio(Portfolio portfolio) async {
    try {
      final updatedPortfolio = portfolio.copyWith(updatedAt: DateTime.now());
      
      await _collection.doc(portfolio.id).update(updatedPortfolio.toFirestore());
      
      return updatedPortfolio;
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la mise à jour du portfolio: $e');
    }
  }

  /// Supprimer un portfolio
  Future<void> deletePortfolio(String portfolioId) async {
    try {
      await _collection.doc(portfolioId).delete();
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la suppression du portfolio: $e');
    }
  }

  // ===== REQUÊTES BUSINESS =====

  /// Récupérer les portfolios d'un tatoueur
  Future<List<Portfolio>> getPortfoliosByTattooistId(String tattooistId, {bool onlyPublic = false}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('tattooistId', isEqualTo: tattooistId);

      if (onlyPublic) {
        query = query.where('settings.isPublic', isEqualTo: true);
      }

      query = query.orderBy('createdAt', descending: true);

      final result = await query.get();
      return result.docs.map((doc) => Portfolio.fromFirestore(doc)).toList();
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la récupération des portfolios du tatoueur: $e');
    }
  }

  /// Récupérer les portfolios publics (pour clients et organisateurs)
  Future<List<Portfolio>> getPublicPortfolios({
    String? style,
    String? category,
    String? bodyPart,
    List<String>? tags,
    bool? isFeatured,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true);

      // Filtrer par style si spécifié
      if (style != null && style.isNotEmpty) {
        query = query.where('style', isEqualTo: style);
      }

      // Filtrer par catégorie si spécifiée
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Filtrer par partie du corps si spécifiée
      if (bodyPart != null && bodyPart.isNotEmpty) {
        query = query.where('bodyPart', isEqualTo: bodyPart);
      }

      // Filtrer par portfolios mis en avant
      if (isFeatured == true) {
        query = query.where('settings.isFeatured', isEqualTo: true);
      }

      // Ordonner par date de création (plus récent en premier)
      query = query.orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query.get();
      var portfolios = result.docs.map((doc) => Portfolio.fromFirestore(doc)).toList();

      // Filtrer par tags côté client (Firestore ne supporte pas les array-contains-any avec d'autres where)
      if (tags != null && tags.isNotEmpty) {
        portfolios = portfolios.where((portfolio) =>
          tags.any((tag) =>
            portfolio.tags.any((portfolioTag) =>
              portfolioTag.toLowerCase().contains(tag.toLowerCase())
            )
          )
        ).toList();
      }

      return portfolios;
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la récupération des portfolios publics: $e');
    }
  }

  /// Rechercher des portfolios
  Future<List<Portfolio>> searchPortfolios({
    required String query,
    String? style,
    String? category,
    String? bodyPart,
    bool onlyPublic = true,
    int? limit,
  }) async {
    try {
      // Récupérer tous les portfolios publics puis filtrer côté client
      final portfolios = await getPublicPortfolios(
        style: style,
        category: category,
        bodyPart: bodyPart,
        limit: limit,
      );

      final lowerQuery = query.toLowerCase();
      
      return portfolios.where((portfolio) =>
        portfolio.title.toLowerCase().contains(lowerQuery) ||
        (portfolio.description?.toLowerCase().contains(lowerQuery) ?? false) ||
        portfolio.style.toLowerCase().contains(lowerQuery) ||
        portfolio.category.toLowerCase().contains(lowerQuery) ||
        portfolio.bodyPart.toLowerCase().contains(lowerQuery) ||
        portfolio.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
      ).toList();
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la recherche de portfolios: $e');
    }
  }

  /// Récupérer portfolios par style
  Future<List<Portfolio>> getPortfoliosByStyle(String style, {bool onlyPublic = true}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('style', isEqualTo: style);

      if (onlyPublic) {
        query = query.where('settings.isPublic', isEqualTo: true);
      }

      query = query.orderBy('createdAt', descending: true);

      final result = await query.get();
      return result.docs.map((doc) => Portfolio.fromFirestore(doc)).toList();
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la récupération des portfolios par style: $e');
    }
  }

  /// Récupérer portfolios par catégorie
  Future<List<Portfolio>> getPortfoliosByCategory(String category, {bool onlyPublic = true}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('category', isEqualTo: category);

      if (onlyPublic) {
        query = query.where('settings.isPublic', isEqualTo: true);
      }

      query = query.orderBy('createdAt', descending: true);

      final result = await query.get();
      return result.docs.map((doc) => Portfolio.fromFirestore(doc)).toList();
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la récupération des portfolios par catégorie: $e');
    }
  }

  /// Récupérer portfolios par partie du corps
  Future<List<Portfolio>> getPortfoliosByBodyPart(String bodyPart, {bool onlyPublic = true}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('bodyPart', isEqualTo: bodyPart);

      if (onlyPublic) {
        query = query.where('settings.isPublic', isEqualTo: true);
      }

      query = query.orderBy('createdAt', descending: true);

      final result = await query.get();
      return result.docs.map((doc) => Portfolio.fromFirestore(doc)).toList();
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la récupération des portfolios par partie du corps: $e');
    }
  }

  /// Récupérer portfolios par tag
  Future<List<Portfolio>> getPortfoliosByTag(String tag, {bool onlyPublic = true}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('tags', arrayContains: tag);

      if (onlyPublic) {
        query = query.where('settings.isPublic', isEqualTo: true);
      }

      query = query.orderBy('createdAt', descending: true);

      final result = await query.get();
      return result.docs.map((doc) => Portfolio.fromFirestore(doc)).toList();
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la récupération des portfolios par tag: $e');
    }
  }

  /// Récupérer portfolios mis en avant
  Future<List<Portfolio>> getFeaturedPortfolios({int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('settings.isPublic', isEqualTo: true)
          .where('settings.isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query.get();
      return result.docs.map((doc) => Portfolio.fromFirestore(doc)).toList();
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la récupération des portfolios mis en avant: $e');
    }
  }

  /// Récupérer portfolios par shop
  Future<List<Portfolio>> getPortfoliosByShopId(String shopId, {bool onlyPublic = true}) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('shopId', isEqualTo: shopId);

      if (onlyPublic) {
        query = query.where('settings.isPublic', isEqualTo: true);
      }

      query = query.orderBy('createdAt', descending: true);

      final result = await query.get();
      return result.docs.map((doc) => Portfolio.fromFirestore(doc)).toList();
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la récupération des portfolios par shop: $e');
    }
  }

  // ===== STREAMS TEMPS RÉEL =====

  /// Stream des portfolios d'un tatoueur
  Stream<List<Portfolio>> watchPortfoliosByTattooistId(String tattooistId, {bool onlyPublic = false}) {
    Query<Map<String, dynamic>> query = _collection
        .where('tattooistId', isEqualTo: tattooistId);

    if (onlyPublic) {
      query = query.where('settings.isPublic', isEqualTo: true);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => Portfolio.fromFirestore(doc)).toList()
        );
  }

  /// Stream des portfolios publics
  Stream<List<Portfolio>> watchPublicPortfolios({String? style, int? limit}) {
    Query<Map<String, dynamic>> query = _collection
        .where('settings.isPublic', isEqualTo: true);

    if (style != null && style.isNotEmpty) {
      query = query.where('style', isEqualTo: style);
    }

    query = query.orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => Portfolio.fromFirestore(doc)).toList()
    );
  }

  /// Stream d'un portfolio spécifique
  Stream<Portfolio?> watchPortfolio(String portfolioId) {
    return _collection
        .doc(portfolioId)
        .snapshots()
        .map((doc) => doc.exists ? Portfolio.fromFirestore(doc) : null);
  }

  // ===== OPÉRATIONS BUSINESS =====

  /// Mettre à jour les statistiques d'un portfolio
  Future<void> updatePortfolioStats(String portfolioId, {
    int? views,
    int? likes,
    int? shares,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (views != null) {
        updates['stats.views'] = views;
      }
      if (likes != null) {
        updates['stats.likes'] = likes;
      }
      if (shares != null) {
        updates['stats.shares'] = shares;
      }
      
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _collection.doc(portfolioId).update(updates);
      }
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la mise à jour des stats: $e');
    }
  }

  /// Incrémenter les vues d'un portfolio
  Future<void> incrementViews(String portfolioId) async {
    try {
      await _collection.doc(portfolioId).update({
        'stats.views': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de l\'incrémentation des vues: $e');
    }
  }

  /// Incrémenter les likes d'un portfolio
  Future<void> incrementLikes(String portfolioId) async {
    try {
      await _collection.doc(portfolioId).update({
        'stats.likes': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de l\'incrémentation des likes: $e');
    }
  }

  /// Incrémenter les partages d'un portfolio
  Future<void> incrementShares(String portfolioId) async {
    try {
      await _collection.doc(portfolioId).update({
        'stats.shares': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de l\'incrémentation des partages: $e');
    }
  }

  /// Activer/désactiver la visibilité publique
  Future<void> togglePublicVisibility(String portfolioId, bool isPublic) async {
    try {
      await _collection.doc(portfolioId).update({
        'settings.isPublic': isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw PortfolioServiceException('Erreur lors du changement de visibilité: $e');
    }
  }

  /// Activer/désactiver la mise en avant
  Future<void> toggleFeatured(String portfolioId, bool isFeatured) async {
    try {
      await _collection.doc(portfolioId).update({
        'settings.isFeatured': isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw PortfolioServiceException('Erreur lors du changement de mise en avant: $e');
    }
  }

  /// Ajouter un tag
  Future<void> addTag(String portfolioId, String tag) async {
    try {
      await _collection.doc(portfolioId).update({
        'tags': FieldValue.arrayUnion([tag]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de l\'ajout de tag: $e');
    }
  }

  /// Supprimer un tag
  Future<void> removeTag(String portfolioId, String tag) async {
    try {
      await _collection.doc(portfolioId).update({
        'tags': FieldValue.arrayRemove([tag]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la suppression de tag: $e');
    }
  }

  // ===== STATISTIQUES =====

  /// Obtenir le nombre de portfolios par style
  Future<Map<String, int>> getPortfoliosCountByStyle() async {
    try {
      final portfolios = await getPublicPortfolios();
      final Map<String, int> styleCount = {};
      
      for (final portfolio in portfolios) {
        final style = portfolio.style;
        styleCount[style] = (styleCount[style] ?? 0) + 1;
      }
      
      return styleCount;
    } catch (e) {
      throw PortfolioServiceException('Erreur lors du calcul des stats par style: $e');
    }
  }

  /// Obtenir le nombre de portfolios par catégorie
  Future<Map<String, int>> getPortfoliosCountByCategory() async {
    try {
      final portfolios = await getPublicPortfolios();
      final Map<String, int> categoryCount = {};
      
      for (final portfolio in portfolios) {
        final category = portfolio.category;
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
      
      return categoryCount;
    } catch (e) {
      throw PortfolioServiceException('Erreur lors du calcul des stats par catégorie: $e');
    }
  }

  /// Obtenir les portfolios les plus populaires
  Future<List<Portfolio>> getPopularPortfolios({int limit = 10}) async {
    try {
      final portfolios = await getPublicPortfolios();
      
      // Trier par score d'engagement (vues + likes + shares)
      portfolios.sort((a, b) {
        final aScore = a.totalViews + a.totalLikes + a.totalShares;
        final bScore = b.totalViews + b.totalLikes + b.totalShares;
        return bScore.compareTo(aScore);
      });
      
      return portfolios.take(limit).toList();
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la récupération des portfolios populaires: $e');
    }
  }

  /// Obtenir les tags les plus utilisés
  Future<Map<String, int>> getPopularTags({int limit = 20}) async {
    try {
      final portfolios = await getPublicPortfolios();
      final Map<String, int> tagCount = {};
      
      for (final portfolio in portfolios) {
        for (final tag in portfolio.tags) {
          tagCount[tag] = (tagCount[tag] ?? 0) + 1;
        }
      }
      
      // Trier par utilisation et limiter
      final sortedTags = tagCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return Map.fromEntries(sortedTags.take(limit));
    } catch (e) {
      throw PortfolioServiceException('Erreur lors de la récupération des tags populaires: $e');
    }
  }

  // ===== VALIDATION =====

  /// Valider qu'un portfolio peut être créé/modifié
  Future<bool> validatePortfolio(Portfolio portfolio) async {
    try {
      // Vérifier que le portfolio a au moins une image
      if (portfolio.images.isEmpty) {
        throw PortfolioServiceException('Un portfolio doit contenir au moins une image');
      }

      // Vérifier que le titre n'est pas vide
      if (portfolio.title.trim().isEmpty) {
        throw PortfolioServiceException('Le titre du portfolio ne peut pas être vide');
      }

      // Vérifier que les champs obligatoires sont remplis
      if (portfolio.category.trim().isEmpty ||
          portfolio.style.trim().isEmpty ||
          portfolio.bodyPart.trim().isEmpty) {
        throw PortfolioServiceException('Les champs catégorie, style et partie du corps sont obligatoires');
      }

      return true;
    } catch (e) {
      if (e is PortfolioServiceException) rethrow;
      throw PortfolioServiceException('Erreur lors de la validation du portfolio: $e');
    }
  }
}

/// Exception personnalisée pour le PortfolioService
class PortfolioServiceException implements Exception {
  final String message;
  PortfolioServiceException(this.message);
  
  @override
  String toString() => 'PortfolioServiceException: $message';
}