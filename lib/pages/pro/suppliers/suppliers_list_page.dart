// Fichier: pages/pro/suppliers/suppliers_list_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/models/supplier_model.dart';
import 'package:kipik_v5/models/category.dart' as CategoryModel;
import 'package:kipik_v5/services/supplier/supplier_service_interface.dart';
import 'package:kipik_v5/locator.dart'; // ✅ Utilisation du locator
import 'package:kipik_v5/pages/pro/suppliers/supplier_detail_page.dart';

class SuppliersListPage extends StatefulWidget {
  const SuppliersListPage({Key? key}) : super(key: key);

  @override
  _SuppliersListPageState createState() => _SuppliersListPageState();
}

class _SuppliersListPageState extends State<SuppliersListPage> {
  // ✅ Utilisation de l'interface via le locator
  final ISupplierService _supplierService = locator<ISupplierService>();
  
  List<SupplierModel> _suppliers = [];
  List<CategoryModel.Category> _categories = []; // ✅ Type correct
  String _selectedCategoryId = 'all'; // ✅ Changé en ID
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
      // ✅ Nouvelles signatures de méthodes
      final categories = await _supplierService.getSupplierCategories();
      final suppliers = await _supplierService.getSuppliers(
        categoryId: _selectedCategoryId == 'all' ? null : _selectedCategoryId,
        favoritesOnly: _showOnlyFavorites,
        partnersOnly: _showOnlyPartners,
        query: _searchQuery.isEmpty ? null : _searchQuery,
        onlyActive: true,
        onlyVerified: true,
      );

      setState(() {
        _categories = categories;
        _suppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des fournisseurs: $e')),
      );
    }
  }

  void _filterSuppliers() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fournisseurs partenaires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
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
            icon: Icon(_showOnlyFavorites ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
              });
              _filterSuppliers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrer par catégorie:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // ✅ Gestion améliorée des catégories
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
                          backgroundColor: Colors.grey[100],
                          selectedColor: Theme.of(context).primaryColor,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Afficher uniquement les partenaires'),
                  value: _showOnlyPartners,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyPartners = value;
                    });
                    _filterSuppliers();
                  },
                  dense: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suppliers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun fournisseur trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Essayez de modifier vos filtres',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator( // ✅ Pull to refresh ajouté
                        onRefresh: _loadData,
                        child: ListView.builder(
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: supplier.isPartner
            ? BorderSide(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar/Logo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Informations principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et badge partenaire
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supplier.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (supplier.isPartner) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Partenaire',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Description
                    if (supplier.description != null && supplier.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        supplier.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Catégories
                    if (supplier.categories.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: supplier.categories.take(3).map((category) => // ✅ Limite à 3 catégories
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ],
                    
                    // Avantages partenaires
                    if (supplier.isPartner && supplier.benefits != null && supplier.benefits!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: supplier.benefits!.take(2).map((benefit) { // ✅ Limite à 2 avantages
                          IconData iconData = _getIconFromName(benefit.iconName);
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                iconData,
                                size: 12,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getBenefitShortText(benefit),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Bouton favori
              IconButton(
                icon: Icon(
                  supplier.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: supplier.isFavorite ? Colors.red : Colors.grey[400],
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
        ),
      ),
    );
  }

  // ✅ Méthode helper pour les icônes
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

  // ✅ Méthode helper pour le texte court des avantages
  String _getBenefitShortText(PartnershipBenefit benefit) {
    switch (benefit.type) {
      case BenefitType.discount:
        return '${benefit.value.toStringAsFixed(0)}% off';
      case BenefitType.cashback:
        return '${benefit.value.toStringAsFixed(0)}% back';
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
    close(context, query); // ✅ Fermer automatiquement
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // ✅ Suggestions améliorées
    final suggestions = [
      'Machines',
      'Encres',
      'Aiguilles',
      'Hygiène',
      'Mobilier',
    ];

    final filteredSuggestions = suggestions
        .where((suggestion) => suggestion.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView(
      children: [
        if (query.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.search),
            title: Text('Rechercher "$query"'),
            onTap: () {
              onSearch(query);
              close(context, query);
            },
          ),
        ...filteredSuggestions.map((suggestion) => ListTile(
          leading: const Icon(Icons.category),
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            onSearch(query);
            close(context, query);
          },
        )),
      ],
    );
  }
}