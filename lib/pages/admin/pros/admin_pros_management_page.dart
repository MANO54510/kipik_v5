// lib/pages/admin/pros/admin_pros_management_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class AdminProsManagementPage extends StatefulWidget {
  const AdminProsManagementPage({Key? key}) : super(key: key);

  @override
  State<AdminProsManagementPage> createState() => _AdminProsManagementPageState();
}

class _AdminProsManagementPageState extends State<AdminProsManagementPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Données simulées (à remplacer par de vraies données)
  List<Map<String, dynamic>> _recentPros = [
    {
      'name': 'Studio Ink Paris',
      'owner': 'Marie Dubois',
      'email': 'marie@studioink.com',
      'phone': '06 12 34 56 78',
      'subscriptionType': 'annual',
      'registrationDate': DateTime(2025, 1, 15),
      'lastLogin': DateTime(2025, 1, 22),
      'status': 'active',
      'revenue': 948.0,
      'projectsCount': 23,
      'avgResponseTime': '1.2h',
      'quotesAccepted': 16,
      'quotesTotal': 23,
      'rating': 4.8,
      'reportsCount': 0,
    },
    {
      'name': 'Black Needle Studio',
      'owner': 'Thomas Martin',
      'email': 'thomas@blackneedle.fr',
      'phone': '06 98 76 54 32',
      'subscriptionType': 'trial',
      'registrationDate': DateTime(2025, 1, 20),
      'lastLogin': DateTime(2025, 1, 23),
      'status': 'active',
      'revenue': 0.0,
      'projectsCount': 5,
      'avgResponseTime': '4.1h',
      'quotesAccepted': 2,
      'quotesTotal': 5,
      'rating': 4.2,
      'reportsCount': 0,
    },
    {
      'name': 'Tattoo Express',
      'owner': 'Jean Durand',
      'email': 'jean@tattooexpress.com',
      'phone': '06 11 22 33 44',
      'subscriptionType': 'annual',
      'registrationDate': DateTime(2024, 11, 10),
      'lastLogin': DateTime(2025, 1, 20),
      'status': 'warning',
      'revenue': 1205.0,
      'projectsCount': 45,
      'avgResponseTime': '8.5h',
      'quotesAccepted': 20,
      'quotesTotal': 45,
      'rating': 3.2,
      'reportsCount': 3,
    },
  ];

  Map<String, dynamic> _prosStats = {
    'total': 89,
    'active': 76,
    'trial': 13,
    'suspended': 2,
    'newThisMonth': 12,
    'totalRevenue': 8940.0,
    'avgResponseTime': 2.4,
    'avgQuoteAcceptance': 68.5,
    'avgRating': 4.3,
    'reportedAccounts': 2,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarKipik(
        title: 'Gestion Tatoueurs Pros',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: true,
      ),
      body: Column(
        children: [
          // Header avec statistiques
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Pros',
                        '${_prosStats['total']}',
                        Icons.brush,
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Actifs',
                        '${_prosStats['active']}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Essai',
                        '${_prosStats['trial']}',
                        Icons.hourglass_empty,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Suspendus',
                        '${_prosStats['suspended']}',
                        Icons.block,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Revenus totaux',
                        '${_prosStats['totalRevenue']}€',
                        Icons.euro,
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Temps réponse moy.',
                        '${_prosStats['avgResponseTime']}h',
                        Icons.schedule,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Taux acceptation',
                        '${_prosStats['avgQuoteAcceptance']}%',
                        Icons.thumb_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Note moyenne',
                        '${_prosStats['avgRating']}/5',
                        Icons.star,
                        Colors.amber,
                      ),
                    ),
                  ],
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
            labelStyle: const TextStyle(fontFamily: 'Roboto'), // AJOUTÉ: Roboto pour les onglets
            unselectedLabelStyle: const TextStyle(fontFamily: 'Roboto'), // AJOUTÉ: Roboto pour les onglets
            tabs: const [
              Tab(text: 'Vue d\'ensemble'),
              Tab(text: 'Liste complète'),
              Tab(text: 'Signalements'),
              Tab(text: 'SAV & Support'),
            ],
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCompleteListTab(),
                _buildReportsTab(),
                _buildSupportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto', // CHANGÉ: Roboto pour les valeurs
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontFamily: 'Roboto', // CHANGÉ: Roboto pour les labels
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actions rapides
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Codes gratuits',
                  'Générer des codes promo',
                  Icons.card_giftcard,
                  Colors.green,
                  () {
                    Navigator.pushNamed(context, '/admin/free-codes');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Notifications',
                  'Envoyer aux tatoueurs',
                  Icons.notifications,
                  Colors.blue,
                  () {
                    // Navigation vers notifications
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Rapports',
                  'Exporter les données',
                  Icons.assessment,
                  Colors.purple,
                  () {
                    // Navigation vers rapports
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Derniers inscrits
          const Text(
            'Derniers tatoueurs inscrits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'PermanentMarker', // GARDÉ: PermanentMarker pour les titres
            ),
          ),
          const SizedBox(height: 12),

          ..._recentPros.map((pro) => _buildProCard(pro)).toList(),

          const SizedBox(height: 24),

          // Graphiques et métriques
          _buildMetricsSection(),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Roboto', // CHANGÉ: Roboto pour les actions
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontFamily: 'Roboto', // CHANGÉ: Roboto pour les descriptions
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProCard(Map<String, dynamic> pro) {
    Color statusColor = pro['status'] == 'active' ? Colors.green : 
                       pro['status'] == 'warning' ? Colors.orange : Colors.red;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.brush, color: statusColor),
        ),
        title: Text(
          pro['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto', // CHANGÉ: Roboto pour les noms
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pro['owner']} • ${pro['email']}',
              style: const TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip(
                  '${pro['subscriptionType']}',
                  pro['subscriptionType'] == 'annual' ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  '${pro['projectsCount']} projets',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  '${pro['rating']}/5 ⭐',
                  Colors.amber,
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Métriques détaillées
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailMetric(
                        'Revenus générés',
                        '${pro['revenue']}€',
                        Icons.euro,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailMetric(
                        'Temps de réponse',
                        '${pro['avgResponseTime']}',
                        Icons.schedule,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailMetric(
                        'Devis acceptés',
                        '${pro['quotesAccepted']}/${pro['quotesTotal']}',
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewProDetails(pro),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text(
                          'Détails',
                          style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _contactPro(pro),
                        icon: const Icon(Icons.message, size: 16),
                        label: const Text(
                          'Contacter',
                          style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (pro['reportsCount'] > 0)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleReports(pro),
                          icon: const Icon(Icons.warning, size: 16),
                          label: const Text(
                            'Signalements',
                            style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
                          ),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _suspendPro(pro),
                          icon: const Icon(Icons.block, size: 16),
                          label: const Text(
                            'Suspendre',
                            style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
                          ),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto', // CHANGÉ: Roboto pour les chips
        ),
      ),
    );
  }

  Widget _buildDetailMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto', // CHANGÉ: Roboto pour les valeurs
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontFamily: 'Roboto', // CHANGÉ: Roboto pour les labels
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMetricsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Métriques de performance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'PermanentMarker', // GARDÉ: PermanentMarker pour les titres
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Les métriques détaillées et graphiques seront disponibles ici :\n'
              '• Évolution des inscriptions\n'
              '• Taux de rétention\n'
              '• Revenus par tatoueur\n'
              '• Temps de réponse moyens\n'
              '• Satisfaction client',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Roboto', // CHANGÉ: Roboto pour les listes
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteListTab() {
    return const Center(
      child: Text(
        'Liste complète des tatoueurs avec filtres et recherche',
        style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
      ),
    );
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Text(
        'Gestion des signalements et comptes problématiques',
        style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
      ),
    );
  }

  Widget _buildSupportTab() {
    return const Center(
      child: Text(
        'Interface SAV et support client',
        style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
      ),
    );
  }

  void _viewProDetails(Map<String, dynamic> pro) {
    // Navigation vers la page détaillée du tatoueur
  }

  void _contactPro(Map<String, dynamic> pro) {
    // Interface de contact/message
  }

  void _handleReports(Map<String, dynamic> pro) {
    // Gestion des signalements
  }

  void _suspendPro(Map<String, dynamic> pro) {
    // Dialog de confirmation de suspension
  }
}