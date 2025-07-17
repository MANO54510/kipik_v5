// lib/widgets/organisateur/revenue_chart_widget.dart

import 'package:flutter/material.dart';
import '../../services/payment/firebase_payment_service.dart';
import '../../theme/kipik_theme.dart';

class RevenueChartWidget extends StatelessWidget {
  final String organizerId;
  final String period; // 'week', 'month', 'year'

  const RevenueChartWidget({
    Key? key,
    required this.organizerId,
    this.period = 'month',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _getRevenueData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur', style: TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final revenueData = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Revenus - ${_getPeriodLabel()}',
                    style: TextStyle(
                      fontFamily: KipikTheme.fontTitle,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Montant total
              Text(
                '${(revenueData['total'] ?? 0.0).toStringAsFixed(0)}€',
                style: TextStyle(
                  fontFamily: KipikTheme.fontTitle,
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Évolution
              Row(
                children: [
                  Icon(
                    (revenueData['growth'] ?? 0.0) >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: (revenueData['growth'] ?? 0.0) >= 0 ? Colors.green[300] : Colors.red[300],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(revenueData['growth'] ?? 0.0).abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: (revenueData['growth'] ?? 0.0) >= 0 ? Colors.green[300] : Colors.red[300],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'vs période précédente',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Graphique simple
              SizedBox(
                height: 60,
                child: Row(
                  children: _buildSimpleChart(revenueData['daily_data'] as List<dynamic>? ?? []),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getRevenueData() async {
    try {
      // Utilise votre FirebasePaymentService existant
      final paymentService = FirebasePaymentService.instance;
      
      // Obtient les stats du tatoueur (qui incluent les revenus)
      final stats = await paymentService.getTattooistStats();
      
      if (stats != null) {
        return {
          'total': stats['totalEarnings'] ?? 0.0,
          'growth': 12.5, // Peut être calculé en comparant avec le mois précédent
          'daily_data': _generateDailyData(stats['totalEarnings'] ?? 0.0),
        };
      }
      
      return {
        'total': 0.0,
        'growth': 0.0,
        'daily_data': <double>[],
      };
    } catch (e) {
      return {
        'total': 0.0,
        'growth': 0.0,
        'daily_data': <double>[],
      };
    }
  }

  List<double> _generateDailyData(double total) {
    // Génère des données quotidiennes simulées basées sur le total
    final dailyData = <double>[];
    for (int i = 0; i < 30; i++) {
      dailyData.add((total / 30) + (i % 3) * 50);
    }
    return dailyData;
  }

  String _getPeriodLabel() {
    switch (period) {
      case 'week':
        return 'Semaine';
      case 'month':
        return 'Mois';
      case 'year':
        return 'Année';
      default:
        return 'Mois';
    }
  }

  List<Widget> _buildSimpleChart(List<dynamic> data) {
    if (data.isEmpty) return <Widget>[];

    // ✅ CORRECTION: Conversion sécurisée List<dynamic> vers List<double>
    final doubleData = data.map<double>((item) {
      if (item is double) return item;
      if (item is int) return item.toDouble();
      if (item is String) return double.tryParse(item) ?? 0.0;
      return 0.0;
    }).toList();

    if (doubleData.isEmpty) return <Widget>[];

    final maxValue = doubleData.reduce((a, b) => a > b ? a : b);
    
    return doubleData.map((value) {
      final height = maxValue > 0 ? (value / maxValue) * 60 : 0.0;
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

// ===== WIDGET POUR STATS ORGANISATEUR =====

class OrganizatorStatsWidget extends StatelessWidget {
  final String organizerId;

  const OrganizatorStatsWidget({
    Key? key,
    required this.organizerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getOrganizatorStats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard();
        }

        if (!snapshot.hasData) {
          return _buildLoadingCard();
        }

        final stats = snapshot.data!;
        return _buildStatsCard(stats);
      },
    );
  }

  Future<Map<String, dynamic>> _getOrganizatorStats() async {
    try {
      final paymentService = FirebasePaymentService.instance;
      
      // Obtient les commissions (adaptées pour organisateur)
      final commissionStats = await paymentService.getCommissionStats(organizerId);
      
      // Obtient l'historique des paiements
      final payments = await paymentService.getUserPayments(limit: 50);
      
      // Calcule les stats organisateur
      final totalRevenue = commissionStats['total_revenue'] ?? 0.0;
      final totalCommissions = commissionStats['total_commissions'] ?? 0.0;
      final netRevenue = totalRevenue - totalCommissions;
      
      final activeConventions = payments.where((p) => 
        p['status'] == 'succeeded' && 
        p['type'] == 'convention'
      ).length;
      
      return {
        'total_revenue': totalRevenue,
        'net_revenue': netRevenue,
        'total_commissions': totalCommissions,
        'active_conventions': activeConventions,
        'total_transactions': payments.length,
        'average_transaction': payments.isNotEmpty ? totalRevenue / payments.length : 0.0,
      };
    } catch (e) {
      throw Exception('Erreur stats organisateur: $e');
    }
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Statistiques Organisateur',
                style: TextStyle(
                  fontFamily: KipikTheme.fontTitle,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Revenus nets',
                '${(stats['net_revenue'] ?? 0.0).toStringAsFixed(0)}€',
                Icons.euro,
              ),
              _buildStatItem(
                'Conventions',
                '${stats['active_conventions'] ?? 0}',
                Icons.event,
              ),
              _buildStatItem(
                'Transactions',
                '${stats['total_transactions'] ?? 0}',
                Icons.payment,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: KipikTheme.fontTitle,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 10,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Erreur de chargement',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

// ===== WIDGET POUR PAIEMENTS FRACTIONNÉS =====

class FractionalPaymentWidget extends StatelessWidget {
  final String organizerId;

  const FractionalPaymentWidget({
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
              Icon(Icons.schedule, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              Text(
                'Paiements Fractionnés',
                style: TextStyle(
                  fontFamily: KipikTheme.fontTitle,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getFractionalPayments(),
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
                  'Aucun paiement fractionné',
                  style: TextStyle(color: Colors.grey),
                );
              }

              return Column(
                children: payments.take(3).map((payment) {
                  return _buildFractionalPaymentItem(payment);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getFractionalPayments() async {
    try {
      final paymentService = FirebasePaymentService.instance;
      return await paymentService.getUserFractionalPayments();
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  }

  Widget _buildFractionalPaymentItem(Map<String, dynamic> payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['description'] ?? 'Paiement fractionné',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${payment['amount']}€ / ${payment['totalAmount'] ?? payment['amount']}€',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(payment['status']),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusLabel(payment['status']),
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
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'succeeded':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'succeeded':
        return 'Payé';
      case 'processing':
        return 'En cours';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }
}