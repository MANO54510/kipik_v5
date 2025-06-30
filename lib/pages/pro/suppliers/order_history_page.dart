// Fichier: pages/pro/suppliers/order_history_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/services/supplier/supplier_service.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatefulWidget {
  final String supplierId;

  const OrderHistoryPage({Key? key, required this.supplierId}) : super(key: key);

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final SupplierService _supplierService = SupplierService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await _supplierService.getOrderHistory(widget.supplierId);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des commandes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des commandes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('Aucune commande trouvée'))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final date = DateTime.parse(order['date']);
                    final formatter = DateFormat('dd/MM/yyyy');
                    final formattedDate = formatter.format(date);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order['orderId'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order['status']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusLabel(order['status']),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Date: $formattedDate'),
                            const SizedBox(height: 8),
                            Text(
                              'Montant: ${order['amount'].toStringAsFixed(2)} €',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 24),
                            const Text(
                              'Articles',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(
                              (order['items'] as List).length,
                              (itemIndex) {
                                final item = order['items'][itemIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    children: [
                                      Text('${item['quantity']} x '),
                                      Expanded(child: Text(item['name'])),
                                      Text('${item['price'].toStringAsFixed(2)} €'),
                                    ],
                                  ),
                                );
                              },
                            ),
                            if (order['appliedBenefits'] != null) ...[
                              const Divider(height: 24),
                              const Text(
                                'Avantages appliqués',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildBenefitRow(
                                label: 'Remise',
                                value: '${order['appliedBenefits']['discount'].toStringAsFixed(2)} €',
                                percentage: order['appliedBenefits']['discountPercentage'] != null
                                    ? '(${order['appliedBenefits']['discountPercentage']}%)'
                                    : null,
                                iconData: Icons.percent,
                                iconColor: Colors.green,
                              ),
                              if (order['appliedBenefits']['cashback'] != null &&
                                  order['appliedBenefits']['cashback'] > 0) ...[
                                const SizedBox(height: 4),
                                _buildBenefitRow(
                                  label: 'Cashback',
                                  value: '${order['appliedBenefits']['cashback'].toStringAsFixed(2)} €',
                                  percentage: order['appliedBenefits']['cashbackPercentage'] != null
                                      ? '(${order['appliedBenefits']['cashbackPercentage']}%)'
                                      : null,
                                  iconData: Icons.savings,
                                  iconColor: Colors.amber,
                                ),
                              ],
                              if (order['appliedBenefits']['hasFreeShipping'] == true) ...[
                                const SizedBox(height: 4),
                                _buildBenefitRow(
                                  label: 'Livraison gratuite',
                                  value: 'Incluse',
                                  iconData: Icons.local_shipping,
                                  iconColor: Colors.blue,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildBenefitRow({
    required String label,
    required String value,
    String? percentage,
    required IconData iconData,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(iconData, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (percentage != null) ...[
          const SizedBox(width: 4),
          Text(
            percentage,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Livré';
      case 'shipped':
        return 'Expédié';
      case 'processing':
        return 'En traitement';
      case 'cancelled':
        return 'Annulé';
      default:
        return status.toUpperCase();
    }
  }
}