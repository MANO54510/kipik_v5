// lib/widgets/organisateur/payment_status_widget.dart

import 'package:flutter/material.dart';
import '../../services/payment/firebase_payment_service.dart';
import '../../theme/kipik_theme.dart';

class PaymentStatusWidget extends StatelessWidget {
  final String organizerId;

  const PaymentStatusWidget({
    Key? key,
    required this.organizerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Statut des Paiements',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getRecentPayments(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Erreur de chargement');
              }

              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final payments = snapshot.data!;
              
              if (payments.isEmpty) {
                return const Text(
                  'Aucun paiement récent',
                  style: TextStyle(color: Colors.grey),
                );
              }

              return Column(
                children: payments.take(5).map((payment) {
                  return _buildPaymentItem(payment);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getRecentPayments() async {
    try {
      final paymentService = FirebasePaymentService.instance;
      final payments = await paymentService.getUserPayments(limit: 10);
      
      // Filtre les paiements liés aux conventions/stands
      return payments.where((payment) {
        final description = payment['description']?.toString().toLowerCase() ?? '';
        return description.contains('stand') || 
               description.contains('convention') || 
               description.contains('billet');
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final status = payment['status'] ?? 'unknown';
    final amount = payment['amount'] ?? 0.0;
    final description = payment['description'] ?? 'Paiement';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${amount.toStringAsFixed(2)}€',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 11,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusLabel(status),
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'succeeded':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'succeeded':
        return 'Payé';
      case 'processing':
        return 'En cours';
      case 'failed':
        return 'Échec';
      case 'refunded':
        return 'Remboursé';
      default:
        return 'Inconnu';
    }
  }
}

// ===== WIDGET POUR COMMISSIONS KIPIK =====

class KipikCommissionWidget extends StatelessWidget {
  final String organizerId;

  const KipikCommissionWidget({
    Key? key,
    required this.organizerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Commissions Kipik',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          FutureBuilder<Map<String, dynamic>>(
            future: _getCommissionData(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) {
                return const Text(
                  'Erreur de chargement',
                  style: TextStyle(color: Colors.white70),
                );
              }

              final data = snapshot.data!;
              final totalCommissions = data['total_commissions'] ?? 0.0;
              final commissionRate = data['commission_rate'] ?? 1.0;
              final monthlyCommissions = data['monthly_commissions'] ?? 0.0;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total payé',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '${totalCommissions.toStringAsFixed(2)}€',
                            style: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Taux',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '${commissionRate.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ce mois',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${monthlyCommissions.toStringAsFixed(2)}€',
                          style: const TextStyle(
                            fontFamily: 'PermanentMarker',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getCommissionData() async {
    try {
      final paymentService = FirebasePaymentService.instance;
      
      // Obtient les stats de commission pour l'organisateur
      final stats = await paymentService.getCommissionStats(organizerId, months: 12);
      final monthlyStats = await paymentService.getCommissionStats(organizerId, months: 1);
      
      final totalRevenue = stats['total_revenue'] ?? 0.0;
      final totalCommissions = stats['total_commissions'] ?? 0.0;
      final monthlyCommissions = monthlyStats['total_commissions'] ?? 0.0;
      
      final commissionRate = totalRevenue > 0 ? (totalCommissions / totalRevenue) * 100 : 1.0;

      return {
        'total_commissions': totalCommissions,
        'commission_rate': commissionRate,
        'monthly_commissions': monthlyCommissions,
        'total_revenue': totalRevenue,
      };
    } catch (e) {
      return {
        'total_commissions': 0.0,
        'commission_rate': 1.0,
        'monthly_commissions': 0.0,
        'total_revenue': 0.0,
      };
    }
  }
}

// ===== WIDGET POUR QUICK ACTIONS =====

class OrganizatorQuickActionsWidget extends StatelessWidget {
  final String organizerId;
  final VoidCallback? onCreateConvention;
  final VoidCallback? onViewRequests;
  final VoidCallback? onViewStats;

  const OrganizatorQuickActionsWidget({
    Key? key,
    required this.organizerId,
    this.onCreateConvention,
    this.onViewRequests,
    this.onViewStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Actions Rapides',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildQuickActionButton(
                'Nouvelle Convention',
                Icons.add_box,
                Colors.green,
                onCreateConvention,
              ),
              _buildQuickActionButton(
                'Demandes Stands',
                Icons.inbox,
                Colors.orange,
                onViewRequests,
              ),
              _buildQuickActionButton(
                'Statistiques',
                Icons.analytics,
                Colors.blue,
                onViewStats,
              ),
              _buildQuickActionButton(
                'Paiements',
                Icons.payment,
                Colors.purple,
                () => _viewPayments(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewPayments(BuildContext context) {
    // Navigue vers la page des paiements ou affiche un bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (context) => PaymentHistoryBottomSheet(organizerId: organizerId),
    );
  }
}

// ===== BOTTOM SHEET POUR HISTORIQUE PAIEMENTS =====

class PaymentHistoryBottomSheet extends StatelessWidget {
  final String organizerId;

  const PaymentHistoryBottomSheet({
    Key? key,
    required this.organizerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Historique des Paiements',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getDetailedPaymentHistory(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Erreur de chargement'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final payments = snapshot.data!;
                
                if (payments.isEmpty) {
                  return const Center(child: Text('Aucun paiement trouvé'));
                }

                return ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    return _buildDetailedPaymentItem(payments[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getDetailedPaymentHistory() async {
    try {
      final paymentService = FirebasePaymentService.instance;
      return await paymentService.getUserPayments(limit: 50);
    } catch (e) {
      return [];
    }
  }

  Widget _buildDetailedPaymentItem(Map<String, dynamic> payment) {
    final status = payment['status'] ?? 'unknown';
    final amount = payment['amount'] ?? 0.0;
    final description = payment['description'] ?? 'Paiement';
    final date = payment['created'] ?? DateTime.now().toIso8601String();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${amount.toStringAsFixed(2)}€',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: _getStatusColor(status),
                ),
              ),
              Text(
                _formatDate(date),
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'succeeded':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'succeeded':
        return 'Payé';
      case 'processing':
        return 'En cours';
      case 'failed':
        return 'Échec';
      case 'refunded':
        return 'Remboursé';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Date inconnue';
    }
  }
}