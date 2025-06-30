// lib/pages/admin/admin_referrals_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kipik_v5/services/promo/promo_code_service.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class AdminReferralsPage extends StatefulWidget {
  const AdminReferralsPage({Key? key}) : super(key: key);

  @override
  State<AdminReferralsPage> createState() => _AdminReferralsPageState();
}

class _AdminReferralsPageState extends State<AdminReferralsPage> with TickerProviderStateMixin {
  List<Referral> _referrals = [];
  List<PromoCode> _referralCodes = [];
  bool _isLoading = true;
  late TabController _tabController;

  // Statistiques globales
  Map<String, int> _globalStats = {
    'totalReferrals': 0,
    'completedReferrals': 0,
    'pendingReferrals': 0,
    'totalRewards': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger tous les parrainages
      final referrals = await PromoCodeService.getAllReferrals();
      
      // Charger tous les codes de parrainage
      final allCodes = await PromoCodeService.getAllPromoCodes();
      final referralCodes = allCodes.where((code) => code.isReferralCode).toList();
      
      // Calculer les statistiques globales
      final stats = {
        'totalReferrals': referrals.length,
        'completedReferrals': referrals.where((r) => r.status == 'completed').length,
        'pendingReferrals': referrals.where((r) => r.status == 'pending').length,
        'totalRewards': referrals.where((r) => r.rewardGranted).length,
      };
      
      setState(() {
        _referrals = referrals;
        _referralCodes = referralCodes;
        _globalStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarKipik(
        title: 'Gestion des parrainages',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistiques globales
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Row(
                    children: [
                      Expanded(
                        child: _GlobalStatCard(
                          title: 'Total parrainages',
                          value: '${_globalStats['totalReferrals']}',
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GlobalStatCard(
                          title: 'Validés',
                          value: '${_globalStats['completedReferrals']}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GlobalStatCard(
                          title: 'En attente',
                          value: '${_globalStats['pendingReferrals']}',
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GlobalStatCard(
                          title: 'Récompenses',
                          value: '${_globalStats['totalRewards']}',
                          icon: Icons.emoji_events,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Onglets
                TabBar(
                  controller: _tabController,
                  labelColor: KipikTheme.rouge,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: KipikTheme.rouge,
                  tabs: const [
                    Tab(text: 'Parrainages actifs'),
                    Tab(text: 'Codes de parrainage'),
                    Tab(text: 'Statistiques'),
                  ],
                ),
                
                // Contenu des onglets
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReferralsTab(),
                      _buildCodesTab(),
                      _buildStatsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReferralsTab() {
    if (_referrals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun parrainage pour le moment',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _referrals.length,
        itemBuilder: (context, index) {
          final referral = _referrals[index];
          return _ReferralCard(referral: referral);
        },
      ),
    );
  }

  Widget _buildCodesTab() {
    if (_referralCodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun code de parrainage généré',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _referralCodes.length,
        itemBuilder: (context, index) {
          final code = _referralCodes[index];
          return _ReferralCodeCard(code: code);
        },
      ),
    );
  }

  Widget _buildStatsTab() {
    // Analyser les données pour les statistiques
    final userStats = <String, Map<String, dynamic>>{};
    
    for (final referral in _referrals) {
      final email = referral.referrerEmail;
      if (!userStats.containsKey(email)) {
        userStats[email] = {
          'totalReferrals': 0,
          'completedReferrals': 0,
          'pendingReferrals': 0,
          'totalRewards': 0,
        };
      }
      
      userStats[email]!['totalReferrals']++;
      
      if (referral.status == 'completed') {
        userStats[email]!['completedReferrals']++;
      } else if (referral.status == 'pending') {
        userStats[email]!['pendingReferrals']++;
      }
      
      if (referral.rewardGranted) {
        userStats[email]!['totalRewards']++;
      }
    }

    if (userStats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucune statistique disponible',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Trier par nombre de parrainages
    final sortedUsers = userStats.entries.toList()
      ..sort((a, b) => b.value['totalReferrals'].compareTo(a.value['totalReferrals']));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedUsers.length + 1, // +1 pour le header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top des parrains',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PermanentMarker',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Classement des tatoueurs par nombre de parrainages',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        final userEntry = sortedUsers[index - 1];
        final email = userEntry.key;
        final stats = userEntry.value;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: KipikTheme.rouge,
              child: Text(
                '#$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              email,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _StatChip(
                    label: '${stats['totalReferrals']} parrainages',
                    color: Colors.blue,
                  ),
                  _StatChip(
                    label: '${stats['completedReferrals']} validés',
                    color: Colors.green,
                  ),
                  _StatChip(
                    label: '${stats['totalRewards']} récompenses',
                    color: Colors.amber,
                  ),
                ],
              ),
            ),
            trailing: stats['totalReferrals'] >= 5
                ? const Icon(Icons.star, color: Colors.amber)
                : null,
          ),
        );
      },
    );
  }
}

class _GlobalStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _GlobalStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final Referral referral;

  const _ReferralCard({required this.referral});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (referral.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Validé';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'En attente';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Inconnu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${referral.referrerEmail} → ${referral.referredEmail}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code utilisé: ${referral.promoCode}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Parrainage: ${referral.referralDate.day}/${referral.referralDate.month}/${referral.referralDate.year}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (referral.subscriptionDate != null)
                        Text(
                          'Abonnement ${referral.subscriptionType}: ${referral.subscriptionDate!.day}/${referral.subscriptionDate!.month}/${referral.subscriptionDate!.year}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (referral.rewardGranted)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.green, size: 20),
                        SizedBox(height: 4),
                        Text(
                          'Récompense\naccordée',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  final PromoCode code;

  const _ReferralCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                code.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PARRAINAGE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Propriétaire: ${code.referrerEmail ?? 'Inconnu'}'),
            const SizedBox(height: 4),
            Text('Utilisations: ${code.currentUses}/${code.maxUses ?? '∞'}'),
            if (code.description != null && code.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                code.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copié !')),
                );
              },
            ),
            Icon(
              code.isValid ? Icons.check_circle : Icons.cancel,
              color: code.isValid ? Colors.green : Colors.red,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}