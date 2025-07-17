// lib/screens/subscription/subscription_dashboard.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/models/user_subscription.dart';
import 'package:kipik_v5/services/subscription/firebase_subscription_service.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/services/features/premium_feature_guard.dart';
import 'package:kipik_v5/screens/subscription/subscription_selection_screen.dart';
import 'package:kipik_v5/screens/subscription/widgets/subscription_card.dart';
import 'package:kipik_v5/screens/subscription/widgets/break_even_calculator.dart';

class SubscriptionDashboard extends StatefulWidget {
  const SubscriptionDashboard({super.key});

  @override
  State<SubscriptionDashboard> createState() => _SubscriptionDashboardState();
}

class _SubscriptionDashboardState extends State<SubscriptionDashboard> {
  final _subscriptionService = FirebaseSubscriptionService.instance;
  UserSubscription? _currentSubscription;
  Map<String, dynamic>? _commissionStats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger abonnement actuel
      _currentSubscription = _subscriptionService.currentSubscription;
      
      if (_currentSubscription != null) {
        // Charger stats commissions
        _commissionStats = await _subscriptionService.getCommissionStats(
          _currentSubscription!.userId,
          months: 1,
        );
      }
    } catch (e) {
      _errorMessage = 'Erreur chargement données: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildDashboardContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
      title: const Text(
        'Mon Abonnement',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadDashboardData,
        ),
        if (_currentSubscription != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'upgrade',
                child: Row(
                  children: [
                    Icon(Icons.upgrade),
                    SizedBox(width: 8),
                    Text('Changer d\'abonnement'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'billing',
                child: Row(
                  children: [
                    Icon(Icons.receipt),
                    SizedBox(width: 8),
                    Text('Facturation'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'support',
                child: Row(
                  children: [
                    Icon(Icons.help),
                    SizedBox(width: 8),
                    Text('Support'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Chargement de votre abonnement...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Une erreur est survenue',
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_currentSubscription == null) {
      return _buildNoSubscriptionState();
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentSubscriptionCard(),
            const SizedBox(height: 24),
            _buildCommissionStatsCard(),
            const SizedBox(height: 24),
            _buildFeaturesCard(),
            const SizedBox(height: 24),
            _buildUpgradeRecommendation(),
            const SizedBox(height: 24),
            _buildTrialStatusCard(),
            const SizedBox(height: 24),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.star_outline,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun abonnement actif',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choisissez un abonnement pour accéder aux fonctionnalités premium',
                    style: TextStyle(color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _navigateToSubscriptionSelection(),
                      child: const Text(
                        '🚀 Choisir un abonnement',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    final subscription = _currentSubscription!;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            subscription.type.subscriptionColor.withOpacity(0.8),
            subscription.type.subscriptionColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: subscription.type.subscriptionColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KIPIK ${subscription.type.displayName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subscription.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${subscription.type.monthlyPrice.toStringAsFixed(0)}€/mois',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Commission
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.percent, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Commission sur vos paiements',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${(subscription.commissionRate * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (subscription.type == SubscriptionType.premium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'RÉDUITE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (subscription.endDate != null) ...[
            const SizedBox(height: 12),
            Text(
              'Renouvellement: ${_formatDate(subscription.endDate!)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommissionStatsCard() {
    if (_commissionStats == null) return const SizedBox.shrink();
    
    final stats = _commissionStats!;
    final totalRevenue = stats['total_revenue'] ?? 0.0;
    final totalCommissions = stats['total_commissions'] ?? 0.0;
    final paymentsCount = stats['payments_count'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Statistiques du mois',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (stats['demo_mode'] == true)
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
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Chiffre d\'affaires',
                  '${totalRevenue.toStringAsFixed(0)}€',
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Commissions KIPIK',
                  '${totalCommissions.toStringAsFixed(2)}€',
                  Colors.orange,
                  Icons.percent,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Paiements',
                  paymentsCount.toString(),
                  Colors.blue,
                  Icons.payment,
                ),
              ),
            ],
          ),
          
          if (totalRevenue > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vous gardez:',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    '${(totalRevenue - totalCommissions).toStringAsFixed(2)}€',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final subscription = _currentSubscription!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✨ Vos fonctionnalités',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...subscription.enabledFeatures.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  feature.icon,
                  color: subscription.type.subscriptionColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        feature.description,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTrialStatusCard() {
    final subscription = _currentSubscription!;
    
    if (!subscription.trialActive) return const SizedBox.shrink();
    
    final daysLeft = subscription.trialEndDate?.difference(DateTime.now()).inDays ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Période d\'essai',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            daysLeft > 0 
                ? '$daysLeft jours restants dans votre essai gratuit'
                : 'Votre essai se termine aujourd\'hui',
            style: TextStyle(
              color: daysLeft > 7 ? Colors.orange : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            subscription.targetType != null 
                ? 'Prélèvement automatique ${subscription.targetType!.displayName} programmé'
                : 'Aucun prélèvement programmé',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          
          if (daysLeft <= 7) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: daysLeft > 0 ? Colors.orange : Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _navigateToSubscriptionSelection(),
                child: Text(
                  daysLeft > 0 ? 'Confirmer mon abonnement' : 'Choisir un abonnement',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpgradeRecommendation() {
    final subscription = _currentSubscription!;
    
    if (subscription.type != SubscriptionType.standard) {
      return const SizedBox.shrink();
    }
    
    return BreakEvenCalculator(
      currentType: SubscriptionType.standard,
      targetType: SubscriptionType.premium,
      onUpgradeRecommended: () => _navigateToSubscriptionSelection(),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ Actions rapides',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Changer d\'abonnement',
                  Icons.upgrade,
                  Colors.blue,
                  () => _navigateToSubscriptionSelection(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Historique paiements',
                  Icons.history,
                  Colors.green,
                  () => _showPaymentHistory(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Support',
                  Icons.help_outline,
                  Colors.orange,
                  () => _showSupport(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Facturation',
                  Icons.receipt_long,
                  Colors.purple,
                  () => _showBilling(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onPressed,
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'upgrade':
        _navigateToSubscriptionSelection();
        break;
      case 'billing':
        _showBilling();
        break;
      case 'support':
        _showSupport();
        break;
    }
  }

  void _navigateToSubscriptionSelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SubscriptionSelectionScreen(),
      ),
    );
  }

  void _showPaymentHistory() {
    // TODO: Implémenter historique paiements
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historique des paiements - À implémenter')),
    );
  }

  void _showBilling() {
    // TODO: Implémenter page facturation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Facturation - À implémenter')),
    );
  }

  void _showSupport() {
    // TODO: Implémenter support
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support - À implémenter')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}