// Fichier: pages/pro/suppliers/supplier_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kipik_v5/models/supplier_model.dart';
import 'package:kipik_v5/services/supplier/supplier_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SupplierDetailPage extends StatefulWidget {
  final String supplierId;

  const SupplierDetailPage({Key? key, required this.supplierId}) : super(key: key);

  @override
  _SupplierDetailPageState createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage> with SingleTickerProviderStateMixin {
  final SupplierService _supplierService = SupplierService();
  SupplierModel? _supplier;
  bool _isLoading = true;
  Map<String, dynamic>? _savingsSummary;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSupplier();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSupplier() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suppliers = await _supplierService.getSuppliers();
      final supplier = suppliers.firstWhere((s) => s.id == widget.supplierId);
      final savingsSummary = await _supplierService.getSavingsSummary(widget.supplierId);

      setState(() {
        _supplier = supplier;
        _savingsSummary = savingsSummary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement du fournisseur: $e')),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail du fournisseur')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_supplier == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail du fournisseur')),
        body: const Center(child: Text('Fournisseur non trouvé')),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(_supplier!.name),
                background: _supplier!.coverImageUrl != null
                    ? Image.network(
                        _supplier!.coverImageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: _supplier!.logoUrl != null
                              ? Image.network(
                                  _supplier!.logoUrl!,
                                  width: 100,
                                  height: 100,
                                )
                              : Icon(
                                  Icons.business,
                                  size: 80,
                                  color: Colors.grey[600],
                                ),
                        ),
                      ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _supplier!.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _supplier!.isFavorite ? Colors.red : null,
                  ),
                  onPressed: () async {
                    await _supplierService.toggleFavorite(_supplier!.id);
                    _loadSupplier(); // Recharger
                  },
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'INFORMATIONS'),
                    Tab(text: 'AVANTAGES'),
                    Tab(text: 'ÉCONOMIES'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInformationTab(),
            _buildBenefitsTab(),
            _buildSavingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: _supplier!.isPartner
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_supplier!.website != null) {
                            _launchURL(_supplier!.website!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Aucun site web disponible')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('VISITER LE SITE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => _OrderFormBottomSheet(
                              supplier: _supplier!,
                            ),
                          );
                        },
                        child: const Text('COMMANDER'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInformationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_supplier!.description != null) ...[
            const Text(
              'À propos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_supplier!.description!),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coordonnées',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_supplier!.address != null) ...[
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(_supplier!.formattedAddress),
                      onTap: () {
                        final mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_supplier!.formattedAddress)}';
                        _launchURL(mapUrl);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  if (_supplier!.phone != null) ...[
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(_supplier!.phone!),
                      onTap: () {
                        _launchURL('tel:${_supplier!.phone}');
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  if (_supplier!.email != null) ...[
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text(_supplier!.email!),
                      onTap: () {
                        _launchURL('mailto:${_supplier!.email}');
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  if (_supplier!.website != null) ...[
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(_supplier!.website!),
                      onTap: () {
                        _launchURL(_supplier!.website!);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Catégories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _supplier!.categories.map((category) {
              return Chip(
                label: Text(category),
                backgroundColor: Colors.grey[200],
              );
            }).toList(),
          ),
          if (_supplier!.tags != null && _supplier!.tags!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _supplier!.tags!.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Colors.blue[100],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitsTab() {
    if (!_supplier!.isPartner) {
      return const Center(
        child: Text('Ce fournisseur n\'est pas un partenaire Kipik.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_supplier!.partnershipDescription != null) ...[
            Text(
              _supplier!.partnershipDescription!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
          ],
          if (_supplier!.promoCode != null) ...[
            const Text(
              'Code promo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Code à utiliser sur le site',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _supplier!.promoCode!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _supplier!.promoCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code promo copié dans le presse-papier')),
                        );
                      },
                      child: const Text('COPIER'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_supplier!.benefits != null && _supplier!.benefits!.isNotEmpty) ...[
            const Text(
              'Avantages exclusifs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(_supplier!.benefits!.map((benefit) {
              IconData iconData;
              Color iconColor;
              
              switch (benefit.type) {
                case BenefitType.discount:
                  iconData = Icons.percent;
                  iconColor = Colors.green;
                  break;
                case BenefitType.cashback:
                  iconData = Icons.savings;
                  iconColor = Colors.amber;
                  break;
                case BenefitType.freeShipping:
                  iconData = Icons.local_shipping;
                  iconColor = Colors.blue;
                  break;
                case BenefitType.loyalty:
                  iconData = Icons.loyalty;
                  iconColor = Colors.purple;
                  break;
                case BenefitType.exclusiveAccess:
                  iconData = Icons.stars;
                  iconColor = Colors.orange;
                  break;
                default:
                  iconData = Icons.tag;
                  iconColor = Colors.grey;
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(iconData, color: iconColor, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              benefit.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(benefit.description),
                            if (benefit.thresholdDescription != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                benefit.thresholdDescription!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList()),
          ],
          if (_supplier!.currentPromotions != null && 
              _supplier!.currentPromotions!.isNotEmpty &&
              _supplier!.currentPromotions!.any((p) => p.isActive)) ...[
            const SizedBox(height: 24),
            const Text(
              'Promotions en cours',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(_supplier!.currentPromotions!
                .where((p) => p.isActive)
                .map((promo) {
              return Card(
                color: Colors.orange[50],
                margin: const EdgeInsets.only(bottom: 12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_offer, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              promo.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(promo.description),
                      if (promo.conditions != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Conditions: ${promo.conditions}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Valable jusqu\'au ${promo.endDate.day}/${promo.endDate.month}/${promo.endDate.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (promo.promoCode != null)
                            Chip(
                              label: Text(
                                promo.promoCode!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.orange[100],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildSavingsTab() {
    if (!_supplier!.isPartner) {
      return const Center(
        child: Text('Ce fournisseur n\'est pas un partenaire Kipik.'),
      );
    }

    if (_savingsSummary == null) {
      return const Center(
        child: Text('Aucune donnée d\'économies disponible.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Total des économies réalisées',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_savingsSummary!['totalSavings'].toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Soit ${_savingsSummary!['savingsPercentage'].toStringAsFixed(1)}% d\'économies sur vos achats',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Détail de vos économies',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSavingCard(
            title: 'Remises obtenues',
            amount: _savingsSummary!['savedThroughDiscounts'],
            icon: Icons.percent,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildSavingCard(
            title: 'Cashback gagné',
            amount: _savingsSummary!['earnedCashback'],
            icon: Icons.savings,
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildSavingCard(
            title: 'Frais de livraison économisés',
            amount: _savingsSummary!['savedOnShipping'],
            icon: Icons.local_shipping,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résumé de vos achats',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    label: 'Nombre de commandes',
                    value: '${_savingsSummary!['totalOrders']}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    label: 'Montant total dépensé',
                    value: '${_savingsSummary!['totalSpent'].toStringAsFixed(2)} €',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    label: 'Montant réel (après économies)',
                    value: '${(_savingsSummary!['totalSpent'] - _savingsSummary!['totalSavings']).toStringAsFixed(2)} €',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context, 
                '/pro/suppliers/orders/${_supplier!.id}',
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('VOIR L\'HISTORIQUE DES COMMANDES'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Text(
              '${amount.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// Widget OrderFormBottomSheet intégré
class _OrderFormBottomSheet extends StatefulWidget {
  final SupplierModel supplier;

  const _OrderFormBottomSheet({
    Key? key,
    required this.supplier,
  }) : super(key: key);

  @override
  __OrderFormBottomSheetState createState() => __OrderFormBottomSheetState();
}

class __OrderFormBottomSheetState extends State<_OrderFormBottomSheet> {
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _promoApplied = false;
  
  // Simuler un panier
  final List<Map<String, dynamic>> _cartItems = [
    {
      'id': 'prod1',
      'name': 'Machine Sol Nova',
      'price': 349.99,
      'quantity': 1,
    },
    {
      'id': 'prod2',
      'name': 'Cartouches 9RL (lot de 20)',
      'price': 39.99,
      'quantity': 2,
    },
    {
      'id': 'prod3',
      'name': 'Grip jetable (lot de 5)',
      'price': 14.50,
      'quantity': 1,
    },
  ];
  
  double get _subtotal => _cartItems.fold(
    0,
    (sum, item) => sum + (item['price'] * item['quantity']),
  );
  
  double get _discountAmount => _promoApplied ? _subtotal * 0.15 : 0;
  double get _shippingCost => _subtotal > 200 || _promoApplied ? 0 : 9.99;
  double get _totalAmount => _subtotal - _discountAmount + _shippingCost;
  double get _cashback => _totalAmount * (_promoApplied ? 0.03 : 0);

  @override
  void initState() {
    super.initState();
    if (widget.supplier.promoCode != null) {
      _promoController.text = widget.supplier.promoCode!;
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyPromoCode() {
    // Simuler l'application d'un code promo
    if (_promoController.text.isNotEmpty) {
      setState(() {
        _promoApplied = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code promo appliqué avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _submitOrder() async {
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Simuler l'envoi de la commande
      await Future.delayed(const Duration(seconds: 1));
      
      final orderData = {
        'items': _cartItems,
        'subtotal': _subtotal,
        'discount': _discountAmount,
        'shipping': _shippingCost,
        'totalAmount': _totalAmount,
        'notes': _notesController.text,
        'promoCode': _promoApplied ? _promoController.text : null,
      };
      
      final result = await SupplierService().placeOrder(
        widget.supplier.id,
        orderData,
      );
      
      // Fermer la bottom sheet
      Navigator.pop(context);
      
      // Afficher une confirmation
      _showOrderConfirmation(result);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _showOrderConfirmation(Map<String, dynamic> orderResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commande confirmée !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Commande ${orderResult['orderId']} passée avec succès',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Livraison estimée le ${orderResult['estimatedDelivery'].substring(0, 10)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Vous avez économisé ${orderResult['appliedBenefits']['discount'].toStringAsFixed(2)} € grâce à vos avantages partenaires !',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (orderResult['appliedBenefits']['cashback'] > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${orderResult['appliedBenefits']['cashback'].toStringAsFixed(2)} € de cashback ont été crédités sur votre compte',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Votre commande',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Liste des articles
            ...List.generate(_cartItems.length, (index) {
              final item = _cartItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${item['price'].toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              if (item['quantity'] > 1) {
                                item['quantity']--;
                              } else {
                                _cartItems.removeAt(index);
                              }
                            });
                          },
                        ),
                        Text(
                          '${item['quantity']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() {
                              item['quantity']++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(),
            
            // Code promo
            const Text(
              'Code promo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      hintText: 'Entrez votre code promo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _promoApplied ? null : _applyPromoCode,
                  child: Text(_promoApplied ? 'Appliqué' : 'Appliquer'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Notes de commande
            const Text(
              'Notes pour la commande (optionnel)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Instructions spéciales, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            // Résumé de la commande
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sous-total'),
                      Text('${_subtotal.toStringAsFixed(2)} €'),
                    ],
                  ),
                  if (_promoApplied) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Remise partenaire (15%)',
                          style: TextStyle(
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '- ${_discountAmount.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Frais de livraison',
                        style: TextStyle(
                          color: _shippingCost == 0 ? Colors.green : null,
                        ),
                      ),
                      Text(
                        _shippingCost == 0
                            ? 'Gratuit'
                            : '${_shippingCost.toStringAsFixed(2)} €',
                        style: TextStyle(
                          color: _shippingCost == 0 ? Colors.green : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_totalAmount.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_cashback > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.savings,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vous recevrez ${_cashback.toStringAsFixed(2)} € de cashback sur votre compte Kipik',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
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
            
            const SizedBox(height: 24),
            
            // Bouton de commande
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirmer la commande',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Termes et conditions
            Center(
              child: TextButton(
                onPressed: () {
                  // Naviguer vers les termes et conditions
                },
                child: const Text(
                  'En passant commande, vous acceptez nos termes et conditions',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}