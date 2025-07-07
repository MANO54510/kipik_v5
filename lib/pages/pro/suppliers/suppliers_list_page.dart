// lib/pages/pro/suppliers/suppliers_list_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/models/supplier_model.dart';
import 'package:kipik_v5/models/category.dart' as CategoryModel;
import 'package:kipik_v5/services/supplier/supplier_service.dart'; // ✅ CORRIGÉ
import 'package:kipik_v5/core/database_manager.dart'; // ✅ AJOUTÉ pour mode démo
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/pages/pro/suppliers/supplier_detail_page.dart';

class SuppliersListPage extends StatefulWidget {
  const SuppliersListPage({Key? key}) : super(key: key);

  @override
  _SuppliersListPageState createState() => _SuppliersListPageState();
}

class _SuppliersListPageState extends State<SuppliersListPage> {
  // ✅ CORRIGÉ : Utilisation directe de SupplierService
  final SupplierService _supplierService = SupplierService();
  
  List<SupplierModel> _suppliers = [];
  List<CategoryModel.Category> _categories = [];
  String _selectedCategoryId = 'all';
  bool _showOnlyFavorites = false;
  bool _showOnlyPartners = true;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les catégories d'abord
      final categories = await _supplierService.getSupplierCategories();
      
      // ✅ CORRIGÉ : Ajouter la catégorie "Tous" en premier avec tous les paramètres requis
      final allCategories = [
        CategoryModel.Category(
          id: 'all',
          name: 'Tous',
          description: 'Tous les fournisseurs',
          iconData: Icons.all_inclusive,
          itemCount: 0, // Sera mis à jour après
          createdAt: DateTime.now(), // ✅ AJOUTÉ
          updatedAt: DateTime.now(), // ✅ AJOUTÉ
        ),
        ...categories,
      ];

      // Charger les fournisseurs
      final suppliers = await _supplierService.getSuppliers(
        categoryId: _selectedCategoryId == 'all' ? null : _selectedCategoryId,
        favoritesOnly: _showOnlyFavorites,
        partnersOnly: _showOnlyPartners,
        query: _searchQuery.isEmpty ? null : _searchQuery,
        onlyActive: true,
        onlyVerified: true,
      );

      // Mettre à jour le compteur pour "Tous"
      allCategories[0] = allCategories[0].copyWith(itemCount: suppliers.length);

      setState(() {
        _categories = allCategories;
        _suppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              DatabaseManager.instance.isDemoMode 
                  ? 'Erreur lors du chargement des fournisseurs de démonstration: $e'
                  : 'Erreur lors du chargement des fournisseurs: $e'
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _filterSuppliers() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DatabaseManager.instance.isDemoMode ? const Color(0xFF0A0A0A) : null,
      appBar: AppBar(
        backgroundColor: DatabaseManager.instance.isDemoMode ? Colors.transparent : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Fournisseurs partenaires',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                color: Colors.white,
              ),
            ),
            // ✅ Indicateur mode démo
            if (DatabaseManager.instance.isDemoMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DÉMO',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SupplierSearchDelegate(
                  (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                    _filterSuppliers();
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
              color: _showOnlyFavorites ? KipikTheme.rouge : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
              });
              _filterSuppliers();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Section filtres améliorée
            Container(
              color: DatabaseManager.instance.isDemoMode 
                  ? Colors.grey[900] 
                  : Colors.grey[50],
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre avec compteur
                  Row(
                    children: [
                      Text(
                        'Filtrer par catégorie',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: DatabaseManager.instance.isDemoMode 
                              ? Colors.white 
                              : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (_suppliers.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: KipikTheme.rouge.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_suppliers.length} fournisseur${_suppliers.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: KipikTheme.rouge,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Filtres de catégories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = category.id == _selectedCategoryId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (category.iconData != null) ...[
                                  Icon(
                                    category.iconData,
                                    size: 16,
                                    color: isSelected ? Colors.white : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(category.name),
                                if (category.itemCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white.withOpacity(0.3) : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${category.itemCount}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected ? Colors.white : Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = category.id;
                              });
                              _filterSuppliers();
                            },
                            backgroundColor: DatabaseManager.instance.isDemoMode 
                                ? Colors.grey[800] 
                                : Colors.grey[100],
                            selectedColor: KipikTheme.rouge,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected 
                                  ? Colors.white 
                                  : (DatabaseManager.instance.isDemoMode ? Colors.white70 : Colors.grey[800]),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Toggle partenaires
                  SwitchListTile(
                    title: Text(
                      'Afficher uniquement les partenaires',
                      style: TextStyle(
                        color: DatabaseManager.instance.isDemoMode 
                            ? Colors.white 
                            : Colors.black87,
                      ),
                    ),
                    value: _showOnlyPartners,
                    activeColor: KipikTheme.rouge,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyPartners = value;
                      });
                      _filterSuppliers();
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  // ✅ Info mode démo
                  if (DatabaseManager.instance.isDemoMode) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.science, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '🎭 Mode ${DatabaseManager.instance.activeDatabaseConfig.name} - Fournisseurs de démonstration',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Liste des fournisseurs
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _suppliers.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: KipikTheme.rouge,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _suppliers.length,
                            itemBuilder: (context, index) {
                              final supplier = _suppliers[index];
                              return SupplierListItem(
                                supplier: supplier,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SupplierDetailPage(supplierId: supplier.id),
                                    ),
                                  ).then((_) => _loadData());
                                },
                                onFavoriteToggle: () async {
                                  await _supplierService.toggleFavorite(supplier.id);
                                  _loadData();
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ État de chargement
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            DatabaseManager.instance.isDemoMode 
                ? 'Chargement des fournisseurs de démonstration...'
                : 'Chargement des fournisseurs...',
            style: TextStyle(
              color: DatabaseManager.instance.isDemoMode 
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey[600],
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ État vide
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: DatabaseManager.instance.isDemoMode 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun fournisseur trouvé',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'PermanentMarker',
                color: DatabaseManager.instance.isDemoMode 
                    ? Colors.white
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DatabaseManager.instance.isDemoMode 
                  ? 'Essayez de modifier vos filtres ou rechargez les données de démonstration'
                  : 'Essayez de modifier vos filtres',
              style: TextStyle(
                fontSize: 14,
                color: DatabaseManager.instance.isDemoMode 
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupplierListItem extends StatelessWidget {
  final SupplierModel supplier;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const SupplierListItem({
    Key? key,
    required this.supplier,
    required this.onTap,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6.0),
      elevation: isDemoMode ? 8 : 2,
      color: isDemoMode ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: supplier.isPartner
            ? BorderSide(
                color: KipikTheme.rouge.withOpacity(0.3),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar/Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDemoMode ? Colors.grey[700] : Colors.grey[100],
                      image: supplier.logoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(supplier.logoUrl!),
                              fit: BoxFit.cover,
                              onError: (error, stackTrace) {},
                            )
                          : null,
                    ),
                    child: supplier.logoUrl == null
                        ? Text(
                            supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDemoMode ? Colors.white : Colors.grey[600],
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Informations principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom et badges
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                supplier.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  fontFamily: 'PermanentMarker',
                                  color: isDemoMode ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (supplier.isPartner) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: KipikTheme.rouge,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Partenaire',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (isDemoMode) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'DÉMO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        // Note - ✅ CORRIGÉ : Gestion du null
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (supplier.rating ?? 0.0).toStringAsFixed(1), // ✅ CORRIGÉ
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDemoMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (supplier.verified) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 2),
                              const Text(
                                'Vérifié',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Bouton favori
                  IconButton(
                    icon: Icon(
                      supplier.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: supplier.isFavorite ? KipikTheme.rouge : (isDemoMode ? Colors.white54 : Colors.grey[400]),
                    ),
                    onPressed: onFavoriteToggle,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              
              // Description
              if (supplier.description != null && supplier.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  supplier.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDemoMode ? Colors.white70 : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Catégories et avantages
              const SizedBox(height: 12),
              Row(
                children: [
                  // Catégories
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: supplier.categories.take(2).map((category) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDemoMode ? Colors.grey[700] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDemoMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                  
                  // Avantages principaux
                  if (supplier.isPartner && supplier.benefits != null && supplier.benefits!.isNotEmpty) ...[
                    Row(
                      children: supplier.benefits!.take(2).map((benefit) {
                        final iconData = _getIconFromName(benefit.iconName);
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Tooltip(
                            message: benefit.description,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: KipikTheme.rouge.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    iconData,
                                    size: 12,
                                    color: KipikTheme.rouge,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getBenefitShortText(benefit),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: KipikTheme.rouge,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'percent':
        return Icons.percent;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'loyalty':
        return Icons.loyalty;
      case 'stars':
        return Icons.stars;
      case 'card_giftcard':
        return Icons.card_giftcard;
      default:
        return Icons.local_offer;
    }
  }

  String _getBenefitShortText(PartnershipBenefit benefit) {
    switch (benefit.type) {
      case BenefitType.discount:
        return '${(benefit.value ?? 0.0).toStringAsFixed(0)}% off'; // ✅ CORRIGÉ
      case BenefitType.cashback:
        return '${(benefit.value ?? 0.0).toStringAsFixed(0)}% back'; // ✅ CORRIGÉ
      case BenefitType.freeShipping:
        return 'Livraison gratuite';
      case BenefitType.loyalty:
        return 'Fidélité';
      case BenefitType.exclusiveAccess:
        return 'Exclusif';
      case BenefitType.gift:
        return 'Cadeau';
      default:
        return benefit.title.length > 15 
            ? '${benefit.title.substring(0, 12)}...' 
            : benefit.title;
    }
  }
}

class SupplierSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;

  SupplierSearchDelegate(this.onSearch);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    
    final suggestions = [
      'Machines',
      'Encres',
      'Aiguilles',
      'Hygiène',
      'Mobilier',
      'Accessoires',
      'Consommables',
    ];

    final filteredSuggestions = suggestions
        .where((suggestion) => suggestion.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      color: isDemoMode ? const Color(0xFF0A0A0A) : Colors.white,
      child: ListView(
        children: [
          if (query.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(
                'Rechercher "$query"',
                style: TextStyle(
                  color: isDemoMode ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                onSearch(query);
                close(context, query);
              },
            ),
          ...filteredSuggestions.map((suggestion) => ListTile(
            leading: const Icon(Icons.category),
            title: Text(
              suggestion,
              style: TextStyle(
                color: isDemoMode ? Colors.white : Colors.black87,
              ),
            ),
            onTap: () {
              query = suggestion;
              onSearch(query);
              close(context, query);
            },
          )),
          if (isDemoMode && query.isEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🎭 Mode ${DatabaseManager.instance.activeDatabaseConfig.name}\nRecherchez parmi les fournisseurs de démonstration',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}