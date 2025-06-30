// lib/pages/admin/clients/admin_clients_management_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class AdminClientsManagementPage extends StatefulWidget {
  const AdminClientsManagementPage({Key? key}) : super(key: key);

  @override
  State<AdminClientsManagementPage> createState() => _AdminClientsManagementPageState();
}

class _AdminClientsManagementPageState extends State<AdminClientsManagementPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Données simulées (à remplacer par de vraies données)
  List<Map<String, dynamic>> _recentClients = [
    {
      'name': 'Sophie Laurent',
      'email': 'sophie.laurent@gmail.com',
      'phone': '06 12 34 56 78',
      'age': 28,
      'location': 'Paris, France',
      'registrationDate': DateTime(2025, 1, 20),
      'lastActivity': DateTime(2025, 1, 23),
      'status': 'active',
      'projectsCount': 3,
      'completedProjects': 1,
      'totalSpent': 450.0,
      'avgProjectValue': 285.0,
      'favoriteStyles': ['Minimaliste', 'Géométrique'],
      'reportsCount': 0,
      'isVerified': true,
      'satisfactionScore': 4.8,
    },
    {
      'name': 'Lucas Martin',
      'email': 'lucas.m.92@outlook.fr',
      'phone': '06 98 76 54 32',
      'age': 25,
      'location': 'Lyon, France',
      'registrationDate': DateTime(2025, 1, 18),
      'lastActivity': DateTime(2025, 1, 22),
      'status': 'active',
      'projectsCount': 1,
      'completedProjects': 0,
      'totalSpent': 0.0,
      'avgProjectValue': 320.0,
      'favoriteStyles': ['Traditionnel', 'Old School'],
      'reportsCount': 0,
      'isVerified': true,
      'satisfactionScore': 0.0,
    },
    {
      'name': 'Emma Dubois',
      'email': 'emma.dubois@yahoo.fr',
      'phone': '06 11 22 33 44',
      'age': 32,
      'location': 'Marseille, France',
      'registrationDate': DateTime(2025, 1, 10),
      'lastActivity': DateTime(2025, 1, 15),
      'status': 'flagged',
      'projectsCount': 5,
      'completedProjects': 2,
      'totalSpent': 180.0,
      'avgProjectValue': 90.0,
      'favoriteStyles': ['Réalisme', 'Portrait'],
      'reportsCount': 2,
      'isVerified': false,
      'satisfactionScore': 2.1,
    },
  ];

  Map<String, dynamic> _clientsStats = {
    'total': 1156,
    'active': 1089,
    'inactive': 45,
    'flagged': 22,
    'newThisMonth': 142,
    'totalSpent': 245680.0,
    'avgProjectValue': 285.50,
    'avgSatisfaction': 4.2,
    'projectsInProgress': 234,
    'completedProjects': 1820,
    'reportedByPros': 8,
    'autoFlagged': 14,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        title: 'Gestion Clients Particuliers',
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
                colors: [Colors.blue, Colors.blue.withOpacity(0.8)],
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
                        'Total Clients',
                        '${_clientsStats['total']}',
                        Icons.people,
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Actifs',
                        '${_clientsStats['active']}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Signalés',
                        '${_clientsStats['flagged']}',
                        Icons.flag,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Nouveaux/mois',
                        '${_clientsStats['newThisMonth']}',
                        Icons.trending_up,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Dépenses totales',
                        '${_clientsStats['totalSpent']}€',
                        Icons.euro,
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Panier moyen',
                        '${_clientsStats['avgProjectValue']}€',
                        Icons.shopping_cart,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Satisfaction',
                        '${_clientsStats['avgSatisfaction']}/5',
                        Icons.star,
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Projets actifs',
                        '${_clientsStats['projectsInProgress']}',
                        Icons.work,
                        Colors.blue,
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
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            isScrollable: true,
            labelStyle: const TextStyle(fontFamily: 'Roboto'), // AJOUTÉ: Roboto pour les onglets
            unselectedLabelStyle: const TextStyle(fontFamily: 'Roboto'), // AJOUTÉ: Roboto pour les onglets
            tabs: const [
              Tab(text: 'Vue d\'ensemble'),
              Tab(text: 'Liste complète'),
              Tab(text: 'Comportements'),
              Tab(text: 'Signalements'),
              Tab(text: 'Support Client'),
            ],
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCompleteListTab(),
                _buildBehaviorTab(),
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
                  'Notifications clients',
                  'Campagne marketing',
                  Icons.campaign,
                  Colors.blue,
                  () {
                    // Navigation vers notifications clients
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Analyse comportements',
                  'Patterns d\'usage',
                  Icons.analytics,
                  Colors.purple,
                  () {
                    // Navigation vers analytics
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Rapports détaillés',
                  'Export données clients',
                  Icons.assessment,
                  Colors.green,
                  () {
                    // Navigation vers rapports
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Alertes importantes
          _buildAlertsSection(),

          const SizedBox(height: 24),

          // Derniers clients inscrits
          const Text(
            'Derniers clients inscrits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'PermanentMarker', // GARDÉ: PermanentMarker pour les titres
            ),
          ),
          const SizedBox(height: 12),

          ..._recentClients.map((client) => _buildClientCard(client)).toList(),

          const SizedBox(height: 24),

          // Métriques et tendances
          _buildTrendsSection(),
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

  Widget _buildAlertsSection() {
    return Column(
      children: [
        if (_clientsStats['reportedByPros'] > 0)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.report_problem, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clients signalés par les tatoueurs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto', // CHANGÉ: Roboto pour les alertes
                        ),
                      ),
                      Text(
                        '${_clientsStats['reportedByPros']} clients ont été signalés par des tatoueurs - intervention requise',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Roboto', // CHANGÉ: Roboto pour les descriptions
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(3),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Traiter', 
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Roboto', // CHANGÉ: Roboto pour les boutons
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_clientsStats['autoFlagged'] > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_fix_high, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comptes auto-flaggés',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto', // CHANGÉ: Roboto pour les alertes
                        ),
                      ),
                      Text(
                        '${_clientsStats['autoFlagged']} comptes détectés avec comportement suspect (prix trop bas, messages inappropriés)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Roboto', // CHANGÉ: Roboto pour les descriptions
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(2),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text(
                    'Analyser', 
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Roboto', // CHANGÉ: Roboto pour les boutons
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    Color statusColor = client['status'] == 'active' ? Colors.green : 
                       client['status'] == 'flagged' ? Colors.red : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            client['isVerified'] ? Icons.verified_user : Icons.person,
            color: statusColor,
          ),
        ),
        title: Text(
          client['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto', // CHANGÉ: Roboto pour les noms
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${client['email']} • ${client['age']} ans • ${client['location']}',
              style: const TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip(
                  '${client['projectsCount']} projets',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  '${client['totalSpent']}€ dépensés',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                if (client['reportsCount'] > 0)
                  _buildChip(
                    '⚠️ ${client['reportsCount']} signalements',
                    Colors.red,
                  ),
                if (client['satisfactionScore'] > 0)
                  _buildChip(
                    '${client['satisfactionScore']}/5 ⭐',
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
                        'Panier moyen',
                        '${client['avgProjectValue']}€',
                        Icons.shopping_cart,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailMetric(
                        'Projets terminés',
                        '${client['completedProjects']}/${client['projectsCount']}',
                        Icons.check_circle,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailMetric(
                        'Dernière activité',
                        '${DateTime.now().difference(client['lastActivity']).inDays}j',
                        Icons.schedule,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Styles préférés
                if (client['favoriteStyles'] != null && client['favoriteStyles'].isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Styles préférés:',
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto', // CHANGÉ: Roboto
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: client['favoriteStyles']
                              .map<Widget>((style) => _buildChip(style, Colors.purple))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewClientDetails(client),
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
                        onPressed: () => _viewClientProjects(client),
                        icon: const Icon(Icons.work, size: 16),
                        label: const Text(
                          'Projets',
                          style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (client['reportsCount'] > 0)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleClientReports(client),
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
                          onPressed: () => _suspendClient(client),
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

  Widget _buildTrendsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendances et insights clients',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'PermanentMarker', // GARDÉ: PermanentMarker pour les titres
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Analytics avancées disponibles :\n'
              '• Évolution des inscriptions par région\n'
              '• Analyse des paniers moyens\n'
              '• Taux de conversion projet → réalisation\n'
              '• Styles de tatouage les plus demandés\n'
              '• Satisfaction par tranche d\'âge\n'
              '• Détection de comportements suspects\n'
              '• Prédiction de churn client',
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
        'Liste complète des clients avec filtres avancés et recherche',
        style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
      ),
    );
  }

  Widget _buildBehaviorTab() {
    return const Center(
      child: Text(
        'Analyse des comportements clients et détection d\'anomalies',
        style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
      ),
    );
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Text(
        'Gestion des signalements clients et modération',
        style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
      ),
    );
  }

  Widget _buildSupportTab() {
    return const Center(
      child: Text(
        'Interface support client et gestion des réclamations',
        style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
      ),
    );
  }

  void _viewClientDetails(Map<String, dynamic> client) {
    // Navigation vers la page détaillée du client
  }

  void _viewClientProjects(Map<String, dynamic> client) {
    // Voir tous les projets du client
  }

  void _handleClientReports(Map<String, dynamic> client) {
    // Gestion des signalements du client
  }

  void _suspendClient(Map<String, dynamic> client) {
    // Dialog de confirmation de suspension
  }
}