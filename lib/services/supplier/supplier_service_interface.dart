// Fichier: services/supplier_service_interface.dart

import 'package:kipik_v5/models/supplier_model.dart';
import 'package:kipik_v5/models/category.dart' as CategoryModel;

abstract class ISupplierService {
  // Méthodes principales
  Future<List<SupplierModel>> getSuppliers({
    bool forceRefresh = false,
    bool onlyActive = true,
    bool onlyVerified = false,
    String? categoryId,
    String? query,
    bool favoritesOnly = false,
    bool partnersOnly = false,
    bool includeDiscounts = true,
  });

  // Méthodes de catégories
  Future<List<CategoryModel.Category>> getSupplierCategories({bool forceRefresh = false});
  Future<List<CategoryModel.Category>> getActiveCategoriesWithItems();
  Future<List<CategoryModel.Category>> searchCategories(String query);

  // Méthodes utilitaires
  Future<SupplierModel?> getSupplierById(String id);
  Future<List<SupplierModel>> searchSuppliers(String query);
  Future<List<SupplierModel>> getFeaturedSuppliers();
  Future<List<SupplierModel>> getSuppliersByCategory(String categoryId);

  // Méthodes de commande
  Future<Map<String, dynamic>> placeOrder(String supplierId, Map<String, dynamic> orderData);
  Future<List<Map<String, dynamic>>> getOrderHistory(String supplierId);
  Future<Map<String, dynamic>> getSavingsSummary(String supplierId);
  Future<bool> toggleFavorite(String supplierId);
}