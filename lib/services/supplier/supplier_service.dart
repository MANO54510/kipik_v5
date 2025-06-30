// Fichier: services/supplier_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kipik_v5/models/supplier_model.dart';
import 'package:kipik_v5/models/category.dart' as CategoryModel; // Alias pour éviter le conflit
import 'package:kipik_v5/utils/constants.dart';
import 'package:kipik_v5/utils/api_constants.dart';
import 'supplier_service_interface.dart'; // ✅ Ajout de l'import interface

class SupplierService with ChangeNotifier implements ISupplierService { // ✅ Implémente l'interface
  final String _baseUrl = '${ApiConstants.baseUrl}/suppliers';
  
  // Cache des données
  List<SupplierModel>? _cachedSuppliers;
  List<CategoryModel.Category>? _cachedCategories; // Utilisation de l'alias
  DateTime? _lastFetchTime;
  
  // Durée de validité du cache (en heures)
  final int _cacheDuration = 2;

  // ========================
  // MÉTHODES PRINCIPALES
  // ========================

  @override
  Future<List<SupplierModel>> getSuppliers({
    bool forceRefresh = false,
    bool onlyActive = true,
    bool onlyVerified = false,
    String? categoryId,
    String? query,
    bool favoritesOnly = false,
    bool partnersOnly = false,
    bool includeDiscounts = true,
  }) async {
    // Vérifier cache d'abord
    if (!forceRefresh && 
        _cachedSuppliers != null && 
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inHours < _cacheDuration) {
      return _filterSuppliers(
        _cachedSuppliers!,
        onlyActive: onlyActive,
        onlyVerified: onlyVerified,
        categoryId: categoryId,
        query: query,
        favoritesOnly: favoritesOnly,
        partnersOnly: partnersOnly,
      );
    }
    
    try {
      // Tenter le cache local
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('suppliers_cache');
      
      if (cachedData != null && !forceRefresh) {
        final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(
          prefs.getInt('suppliers_last_fetch') ?? 0
        );
        
        if (DateTime.now().difference(lastFetchTime).inHours < _cacheDuration) {
          final List<dynamic> decodedData = jsonDecode(cachedData);
          final List<SupplierModel> suppliers = decodedData
              .map((item) => SupplierModel.fromJson(item as Map<String, dynamic>))
              .toList();
          
          _cachedSuppliers = suppliers;
          _lastFetchTime = lastFetchTime;
          
          return _filterSuppliers(
            suppliers,
            onlyActive: onlyActive,
            onlyVerified: onlyVerified,
            categoryId: categoryId,
            query: query,
            favoritesOnly: favoritesOnly,
            partnersOnly: partnersOnly,
          );
        }
      }
      
      // Requête API en dernier recours
      final queryParams = <String, String>{};
      if (!includeDiscounts) queryParams['include_discounts'] = 'false';
      
      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<SupplierModel> suppliers = data
            .map((item) => SupplierModel.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Mettre à jour le cache
        prefs.setString('suppliers_cache', response.body);
        prefs.setInt('suppliers_last_fetch', DateTime.now().millisecondsSinceEpoch);
        
        _cachedSuppliers = suppliers;
        _lastFetchTime = DateTime.now();
        
        return _filterSuppliers(
          suppliers,
          onlyActive: onlyActive,
          onlyVerified: onlyVerified,
          categoryId: categoryId,
          query: query,
          favoritesOnly: favoritesOnly,
          partnersOnly: partnersOnly,
        );
      } else {
        throw Exception('Échec du chargement des fournisseurs: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des fournisseurs: $e');
      }
      
      // En cas d'erreur, utiliser les données de démo enrichies
      return _getEnhancedDemoSuppliers();
    }
  }

  // ========================
  // MÉTHODES DE CATÉGORIES
  // ========================

  @override
  Future<List<CategoryModel.Category>> getSupplierCategories({bool forceRefresh = false}) async {
    // Vérifier si on a des données en cache
    if (!forceRefresh && _cachedCategories != null) {
      return _cachedCategories!;
    }
    
    try {
      // Faire une requête API
      final response = await http.get(
        Uri.parse('${_baseUrl}-categories'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<CategoryModel.Category> categories = data
            .map((item) => CategoryModel.Category.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Mettre à jour le cache
        _cachedCategories = categories;
        
        return categories;
      } else {
        throw Exception('Échec du chargement des catégories: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des catégories: $e');
      }
      
      // En cas d'erreur, retourner des catégories de démo
      return _getDemoCategories();
    }
  }

  @override
  Future<List<CategoryModel.Category>> getActiveCategoriesWithItems() async {
    final allCategories = await getSupplierCategories();
    return CategoryModel.CategoryHelper.getActiveCategories(allCategories);
  }

  @override
  Future<List<CategoryModel.Category>> searchCategories(String query) async {
    final allCategories = await getSupplierCategories();
    
    if (query.isEmpty) return allCategories;
    
    final queryLower = query.toLowerCase();
    return allCategories.where((category) =>
      category.name.toLowerCase().contains(queryLower) ||
      (category.description?.toLowerCase().contains(queryLower) ?? false)
    ).toList();
  }

  // ========================
  // MÉTHODES UTILITAIRES
  // ========================

  @override
  Future<SupplierModel?> getSupplierById(String id) async {
    try {
      if (_cachedSuppliers != null) {
        try {
          return _cachedSuppliers!.firstWhere((s) => s.id == id);
        } catch (_) {}
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SupplierModel.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Échec de la récupération du fournisseur: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération du fournisseur: $e');
      }
      
      final demoSuppliers = _getEnhancedDemoSuppliers();
      try {
        return demoSuppliers.firstWhere((s) => s.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<List<SupplierModel>> searchSuppliers(String query) async {
    if (query.isEmpty) {
      return getSuppliers();
    }
    
    final allSuppliers = await getSuppliers(onlyActive: true);
    final lowercaseQuery = query.toLowerCase();
    
    return allSuppliers.where((supplier) {
      return supplier.name.toLowerCase().contains(lowercaseQuery) ||
          (supplier.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          supplier.categories.any((cat) => cat.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  @override
  Future<List<SupplierModel>> getFeaturedSuppliers() async {
    final allSuppliers = await getSuppliers(onlyActive: true, onlyVerified: true);
    return allSuppliers.where((supplier) => supplier.featured).toList();
  }

  @override
  Future<List<SupplierModel>> getSuppliersByCategory(String categoryId) async {
    return getSuppliers(onlyActive: true, categoryId: categoryId);
  }

  // ========================
  // MÉTHODES DE COMMANDE
  // ========================

  @override
  Future<Map<String, dynamic>> placeOrder(String supplierId, Map<String, dynamic> orderData) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final suppliers = await getSuppliers();
    final supplier = suppliers.firstWhere((s) => s.id == supplierId);
    
    double discountPercentage = 0.0;
    double cashbackPercentage = 0.0;
    bool hasFreeShipping = false;
    
    if (supplier.benefits != null) {
      for (final benefit in supplier.benefits!) {
        if (benefit.type == BenefitType.discount) {
          discountPercentage = benefit.value;
        } else if (benefit.type == BenefitType.cashback) {
          cashbackPercentage = benefit.value;
        } else if (benefit.type == BenefitType.freeShipping) {
          if (benefit.thresholdDescription != null) {
            final threshold = double.tryParse(
              benefit.thresholdDescription!.replaceAll(RegExp(r'[^0-9.]'), '')
            ) ?? 0.0;
            hasFreeShipping = orderData['totalAmount'] >= threshold;
          } else {
            hasFreeShipping = true;
          }
        }
      }
    }
    
    final discountAmount = orderData['totalAmount'] * (discountPercentage / 100);
    final cashbackAmount = orderData['totalAmount'] * (cashbackPercentage / 100);
    
    return {
      'orderId': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      'status': 'success',
      'message': 'Commande passée avec succès',
      'appliedBenefits': {
        'discount': discountAmount,
        'discountPercentage': discountPercentage,
        'cashback': cashbackAmount,
        'cashbackPercentage': cashbackPercentage,
        'hasFreeShipping': hasFreeShipping,
      },
      'totalAmount': orderData['totalAmount'],
      'finalAmount': orderData['totalAmount'] - discountAmount,
      'estimatedDelivery': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String supplierId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    return [
      {
        'orderId': 'ORD-123456',
        'date': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'amount': 349.99,
        'status': 'delivered',
        'items': [
          {
            'name': 'Cheyenne Sol Nova',
            'quantity': 1,
            'price': 349.99,
          }
        ],
        'appliedBenefits': {
          'discount': 52.50,
          'discountPercentage': 15.0,
          'cashback': 10.50,
          'cashbackPercentage': 3.0,
          'hasFreeShipping': true,
        },
      },
      {
        'orderId': 'ORD-123123',
        'date': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
        'amount': 124.50,
        'status': 'delivered',
        'items': [
          {
            'name': 'Cartouches 9RL (lot de 20)',
            'quantity': 2,
            'price': 39.99 * 2,
          },
          {
            'name': 'Cartouches 5RS (lot de 20)',
            'quantity': 1,
            'price': 44.52,
          },
        ],
        'appliedBenefits': {
          'discount': 18.68,
          'discountPercentage': 15.0,
          'cashback': 3.74,
          'cashbackPercentage': 3.0,
          'hasFreeShipping': false,
        },
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> getSavingsSummary(String supplierId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'totalOrders': 8,
      'totalSpent': 1245.67,
      'savedThroughDiscounts': 186.85,
      'earnedCashback': 37.37,
      'savedOnShipping': 29.99,
      'totalSavings': 254.21,
      'savingsPercentage': 20.4,
    };
  }

  @override
  Future<bool> toggleFavorite(String supplierId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Mettre à jour le cache local si possible
    if (_cachedSuppliers != null) {
      final index = _cachedSuppliers!.indexWhere((s) => s.id == supplierId);
      if (index != -1) {
        _cachedSuppliers![index] = _cachedSuppliers![index].copyWith(
          isFavorite: !_cachedSuppliers![index].isFavorite,
        );
        notifyListeners(); // Notifier les widgets qui écoutent
      }
    }
    
    return true;
  }

  // ========================
  // MÉTHODES PRIVÉES
  // ========================

  List<SupplierModel> _filterSuppliers(
    List<SupplierModel> suppliers, {
    bool onlyActive = true,
    bool onlyVerified = false,
    String? categoryId,
    String? query,
    bool favoritesOnly = false,
    bool partnersOnly = false,
  }) {
    return suppliers.where((supplier) {
      if (onlyActive && !supplier.isActive) return false;
      if (onlyVerified && !supplier.verified) return false;
      if (favoritesOnly && !supplier.isFavorite) return false;
      if (partnersOnly && !supplier.isPartner) return false;
      
      if (categoryId != null && categoryId != 'all') {
        // Mapper les IDs de catégories vers les noms
        String categoryName = _mapCategoryIdToName(categoryId);
        if (categoryName != 'Tous' && !supplier.categories.contains(categoryName)) {
          return false;
        }
      }
      
      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        if (!supplier.name.toLowerCase().contains(queryLower) &&
            !(supplier.description?.toLowerCase().contains(queryLower) ?? false) &&
            !(supplier.tags?.any((tag) => tag.toLowerCase().contains(queryLower)) ?? false)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  String _mapCategoryIdToName(String categoryId) {
    switch (categoryId) {
      case 'machines': return 'Machines';
      case 'needles': return 'Aiguilles';
      case 'inks': return 'Encres';
      case 'accessories': return 'Accessoires';
      case 'hygiene': return 'Hygiène';
      case 'furniture': return 'Mobilier';
      case 'consumables': return 'Consommables';
      default: return 'Tous';
    }
  }

  List<CategoryModel.Category> _getDemoCategories() {
    final categories = CategoryModel.CategoryHelper.getDefaultSupplierCategories();
    
    // Mettre à jour les compteurs en fonction des fournisseurs de démo
    final demoSuppliers = _getEnhancedDemoSuppliers();
    
    return CategoryModel.CategoryHelper.updateItemCounts(
      categories,
      demoSuppliers,
      (supplier) {
        // Mapper les catégories string vers les IDs
        final supplierModel = supplier as SupplierModel;
        if (supplierModel.categories.contains('Machines')) return 'machines';
        if (supplierModel.categories.contains('Aiguilles')) return 'needles';
        if (supplierModel.categories.contains('Encres')) return 'inks';
        if (supplierModel.categories.contains('Accessoires')) return 'accessories';
        if (supplierModel.categories.contains('Hygiène')) return 'hygiene';
        if (supplierModel.categories.contains('Mobilier')) return 'furniture';
        if (supplierModel.categories.contains('Consommables')) return 'consumables';
        return 'all';
      },
    );
  }

  List<SupplierModel> _getEnhancedDemoSuppliers() {
    return [
      SupplierModel(
        id: '1',
        name: 'Cheyenne Professional',
        description: 'Leader mondial des machines de tatouage rotatives. Qualité allemande.',
        logoUrl: 'https://example.com/logos/cheyenne.png',
        website: 'https://www.cheyennetattoo.com',
        email: 'contact@cheyennetattoo.com',
        phone: '+33 1 23 45 67 89',
        address: '55 Rue du Faubourg Saint-Honoré',
        zipCode: '75008',
        city: 'Paris',
        country: 'France',
        categories: ['Machines', 'Aiguilles'],
        isFavorite: true,
        rating: 4.8,
        tags: ['Premium', 'Rotative'],
        isPartner: true,
        partnershipType: 'discount_and_cashback',
        partnershipDescription: 'Partenaire officiel Kipik avec des conditions exclusives.',
        promoCode: 'KIPIK15',
        cashbackPercentage: 3,
        featured: true,
        verified: true,
        isActive: true,
        benefits: [
          PartnershipBenefit(
            id: 'b1',
            title: 'Remise permanente de 15%',
            description: 'Bénéficiez d\'une remise de 15% sur toutes vos commandes sans minimum d\'achat.',
            type: BenefitType.discount,
            value: 15.0,
            isUnlimited: true,
            iconName: 'percent',
          ),
          PartnershipBenefit(
            id: 'b2',
            title: 'Livraison gratuite',
            description: 'Livraison gratuite sur toutes vos commandes à partir de 200€ d\'achat.',
            type: BenefitType.freeShipping,
            value: 0.0,
            thresholdDescription: 'À partir de 200€ d\'achat',
            iconName: 'local_shipping',
          ),
          PartnershipBenefit(
            id: 'b3',
            title: '3% de cashback',
            description: 'Gagnez 3% du montant de vos achats en crédits Kipik.',
            type: BenefitType.cashback,
            value: 3.0,
            isUnlimited: true,
            iconName: 'savings',
          ),
        ],
        currentPromotions: [
          SupplierPromotion(
            id: 'p1',
            title: 'Offre de lancement Sol Nova',
            description: 'Profitez de 10% de remise supplémentaire sur la nouvelle machine Sol Nova.',
            startDate: DateTime.now().subtract(const Duration(days: 5)),
            endDate: DateTime.now().add(const Duration(days: 25)),
            discountValue: 10.0,
            isPercentage: true,
            conditions: 'Valable uniquement sur le modèle Sol Nova 2025.',
            promoCode: 'SOLNOVA2025',
          ),
        ],
        commission: SupplierCommission(
          id: 'c1', 
          percentage: 5.0,
          minAmount: 100.0,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      
      SupplierModel(
        id: '2',
        name: 'Dynamic Color',
        description: 'Encres de tatouage de haute qualité. Large palette de couleurs vives.',
        logoUrl: 'https://example.com/logos/dynamic.png',
        website: 'https://www.dynamiccolor.com',
        email: 'info@dynamiccolor.com',
        phone: '+33 1 98 76 54 32',
        address: '23 Avenue Montaigne',
        zipCode: '75008',
        city: 'Paris',
        country: 'France',
        categories: ['Encres'],
        isFavorite: false,
        rating: 4.5,
        tags: ['Organique', 'Vegan'],
        isPartner: true,
        partnershipType: 'discount_and_cashback',
        partnershipDescription: 'Découvrez les encres Dynamic Color avec des avantages exclusifs.',
        cashbackPercentage: 5,
        verified: true,
        isActive: true,
        benefits: [
          PartnershipBenefit(
            id: 'b4',
            title: 'Remise progressive',
            description: 'Obtenez 10% de remise sur votre première commande, puis 12% sur les suivantes.',
            type: BenefitType.discount,
            value: 10.0,
            iconName: 'trending_up',
          ),
          PartnershipBenefit(
            id: 'b5',
            title: '5% de cashback',
            description: 'Gagnez 5% du montant de vos achats en crédits Kipik.',
            type: BenefitType.cashback,
            value: 5.0,
            isUnlimited: true,
            iconName: 'savings',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),

      SupplierModel(
        id: '3',
        name: 'Sterile Supply',
        description: 'Spécialiste des produits d\'hygiène et de stérilisation pour tatoueurs.',
        logoUrl: 'https://example.com/logos/sterile.png',
        website: 'https://www.sterilesupply.com',
        email: 'contact@sterilesupply.com',
        phone: '+33 1 87 65 43 21',
        categories: ['Hygiène', 'Consommables'],
        isFavorite: false,
        rating: 4.6,
        tags: ['Stérile', 'Médical'],
        isPartner: true,
        partnershipType: 'discount',
        verified: true,
        isActive: true,
        benefits: [
          PartnershipBenefit(
            id: 'b6',
            title: 'Remise volume',
            description: '12% de remise sur toutes les commandes supérieures à 150€.',
            type: BenefitType.discount,
            value: 12.0,
            thresholdDescription: 'À partir de 150€ d\'achat',
            iconName: 'percent',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),

      SupplierModel(
        id: '4',
        name: 'Tattoo Furniture Pro',
        description: 'Mobilier professionnel pour studios de tatouage. Fauteuils, éclairage, rangement.',
        logoUrl: 'https://example.com/logos/furniture.png',
        website: 'https://www.tattoofurniturepro.com',
        categories: ['Mobilier'],
        isFavorite: false,
        rating: 4.3,
        tags: ['Professionnel', 'Design'],
        isPartner: false,
        verified: true,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}