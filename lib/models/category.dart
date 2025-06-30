// Fichier: models/category.dart

import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String? description;
  final IconData? iconData;
  final String? iconName; // Nom de l'icône pour la sérialisation
  final Color? color;
  final int itemCount; // Nombre d'éléments dans cette catégorie
  final bool isActive;
  final int sortOrder; // Ordre d'affichage
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.iconData,
    this.iconName,
    this.color,
    this.itemCount = 0,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconData: json['iconName'] != null 
          ? _getIconDataFromName(json['iconName'] as String) 
          : null,
      iconName: json['iconName'] as String?,
      color: json['color'] != null 
          ? Color(json['color'] as int) 
          : null,
      itemCount: json['itemCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (iconName != null) 'iconName': iconName,
      if (color != null) 'color': color!.value,
      'itemCount': itemCount,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Méthode pour convertir un nom d'icône en IconData
  static IconData? _getIconDataFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      // Catégories de fournisseurs tatouage
      case 'build':
      case 'tools':
        return Icons.build;
      case 'color_lens':
      case 'palette':
        return Icons.color_lens;
      case 'settings':
      case 'gear':
        return Icons.settings;
      case 'local_shipping':
      case 'shipping':
        return Icons.local_shipping;
      case 'sanitizer':
      case 'clean_hands':
        return Icons.sanitizer;
      case 'chair':
      case 'furniture':
        return Icons.chair;
      case 'inventory':
      case 'stock':
        return Icons.inventory;
      
      // Icônes génériques
      case 'category':
        return Icons.category;
      case 'label':
        return Icons.label;
      case 'folder':
        return Icons.folder;
      case 'tag':
        return Icons.local_offer;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'shop':
      case 'store':
        return Icons.store;
      case 'medical':
        return Icons.medical_services;
      case 'art':
        return Icons.brush;
      
      // Icônes spécifiques au tatouage
      case 'tattoo':
      case 'tattoo_machine':
        return Icons.brush; // Pas d'icône tattoo native, on utilise brush
      case 'needle':
        return Icons.straighten;
      case 'ink':
        return Icons.water_drop;
      case 'machine':
        return Icons.precision_manufacturing;
      
      default:
        return Icons.category; // Icône par défaut
    }
  }

  // Méthode pour créer une copie avec des modifications
  Category copyWith({
    String? id,
    String? name,
    String? description,
    IconData? iconData,
    String? iconName,
    Color? color,
    int? itemCount,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconData: iconData ?? this.iconData,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      itemCount: itemCount ?? this.itemCount,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, itemCount: $itemCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Classe pour gérer les catégories prédéfinies
class CategoryHelper {
  // Catégories par défaut pour les fournisseurs de tatouage
  static List<Category> getDefaultSupplierCategories() {
    final now = DateTime.now();
    
    return [
      Category(
        id: 'all',
        name: 'Tous',
        description: 'Toutes les catégories',
        iconData: Icons.apps,
        iconName: 'apps',
        itemCount: 0, // Sera calculé dynamiquement
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'machines',
        name: 'Machines',
        description: 'Machines de tatouage rotatives et bobines',
        iconData: Icons.precision_manufacturing,
        iconName: 'machine',
        color: Colors.blue,
        itemCount: 0,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'needles',
        name: 'Aiguilles',
        description: 'Aiguilles et cartouches de tatouage',
        iconData: Icons.straighten,
        iconName: 'needle',
        color: Colors.orange,
        itemCount: 0,
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'inks',
        name: 'Encres',
        description: 'Encres de tatouage professionnelles',
        iconData: Icons.color_lens,
        iconName: 'color_lens',
        color: Colors.purple,
        itemCount: 0,
        sortOrder: 3,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'accessories',
        name: 'Accessoires',
        description: 'Grips, tubes, alimentations...',
        iconData: Icons.build,
        iconName: 'build',
        color: Colors.green,
        itemCount: 0,
        sortOrder: 4,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'hygiene',
        name: 'Hygiène',
        description: 'Produits de désinfection et stérilisation',
        iconData: Icons.sanitizer,
        iconName: 'sanitizer',
        color: Colors.teal,
        itemCount: 0,
        sortOrder: 5,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'furniture',
        name: 'Mobilier',
        description: 'Fauteuils, tabourets, lampes...',
        iconData: Icons.chair,
        iconName: 'chair',
        color: Colors.brown,
        itemCount: 0,
        sortOrder: 6,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'consumables',
        name: 'Consommables',
        description: 'Gants, films, lingettes...',
        iconData: Icons.inventory,
        iconName: 'inventory',
        color: Colors.grey,
        itemCount: 0,
        sortOrder: 7,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // Méthode pour mettre à jour les compteurs d'items
  static List<Category> updateItemCounts(
    List<Category> categories, 
    List<dynamic> items,
    String Function(dynamic) getCategoryId,
  ) {
    // Compter les items par catégorie
    final Map<String, int> counts = {};
    for (final item in items) {
      final categoryId = getCategoryId(item);
      counts[categoryId] = (counts[categoryId] ?? 0) + 1;
    }

    // Mettre à jour les catégories
    return categories.map((category) {
      if (category.id == 'all') {
        // Pour "Tous", compter tous les items
        return category.copyWith(itemCount: items.length);
      } else {
        return category.copyWith(itemCount: counts[category.id] ?? 0);
      }
    }).toList();
  }

  // Méthode pour filtrer les catégories actives avec des items
  static List<Category> getActiveCategories(List<Category> categories) {
    return categories
        .where((cat) => cat.isActive && (cat.id == 'all' || cat.itemCount > 0))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}