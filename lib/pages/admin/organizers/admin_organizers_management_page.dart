// lib/pages/admin/organizers/admin_organizers_management_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class AdminOrganizersManagementPage extends StatefulWidget {
  const AdminOrganizersManagementPage({Key? key}) : super(key: key);

  @override
  State<AdminOrganizersManagementPage> createState() => _AdminOrganizersManagementPageState();
}

class _AdminOrganizersManagementPageState extends State<AdminOrganizersManagementPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Données simulées (à remplacer par de vraies données)
  List<Map<String, dynamic>> _organizers = [
    {
      'name': 'Convention Tattoo Paris',
      'organizerName': 'Jean-Pierre Moreau',
      'email': 'jp.moreau@tattoo-paris.com',
      'phone': '01 42 33 44 55',
      'company': 'Events & Ink SAS',
      'siret': '12345678901234',
      'registrationDate': DateTime(2024, 6, 15),
      'lastLogin': DateTime(2025, 1, 22),
      'status': 'active',
      'eventsCreated': 8,
      'activeEvents': 2,
      'upcomingEvents': 3,
      'totalRevenue': 45200.0,
      'kipikCommission': 4520.0,
      'avgEventSize': 65,
      'avgTicketPrice': 85.0,
      'bookingRate': 78.5,
      'cancelationRate': 12.0,
      'attendeeRating': 4.6,
      'reportsCount': 0,
      'specialties': ['Conventions', 'Ateliers', 'Concours'],
    },
    {
      'name': 'Ink Festival Lyon',
      'organizerName': 'Marie Dubois',
      'email': 'marie@inkfestival-lyon.fr',
      'phone': '04 72 11 22 33',
      'company': 'Lyon Events SARL',
      'siret': '98765432109876',
      'registrationDate': DateTime(2024, 9, 22),
      'lastLogin': DateTime(2025, 1, 20),
      'status': 'active',
      'eventsCreated': 3,
      'activeEvents': 1,
      'upcomingEvents': 2,
      'totalRevenue': 18900.0,
      'kipikCommission': 1890.0,
      'avgEventSize': 45,
      'avgTicketPrice': 65.0,
      'bookingRate': 85.2,
      'cancelationRate': 8.5,
      'attendeeRating': 4.8,
      'reportsCount': 0,
      'specialties': ['Festivals', 'Expositions'],
    },
  ];

  Map<String, dynamic> _organizersStats = {
    'total': 2,
    'active': 2,
    'suspended': 0,
    'pending': 0,
    'totalEvents': 11,
    'activeEvents': 3,
    'upcomingEvents': 5,
    'totalRevenue': 64100.0,
    'totalCommission': 6410.0,
    'avgEventSize': 55,
    'avgTicketPrice': 75.0,
    'totalAttendees': 1820,
    'avgBookingRate': 81.8,
    'avgAttendeeRating': 4.7,
    'monthlyRevenue': 12450.0,
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
        title: 'Gestion Organisateurs Événements',
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
                colors: [Colors.purple, Colors.purple.withOpacity(0.8)],
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
                        'Organisateurs',
                        '${_organizersStats['total']}',
                        Icons.business,
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Événements actifs',
                        '${_organizersStats['activeEvents']}',
                        Icons.event,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'À venir',
                        '${_organizersStats['upcomingEvents']}',
                        Icons.schedule,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Participants',
                        '${_organizersStats['totalAttendees']}',
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'CA Total',
                        '${_organizersStats['totalRevenue']}€',
                        Icons.euro,
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Commission Kipik',
                        '${_organizersStats['totalCommission']}€',
                        Icons.account_balance,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Taille moy. événement',
                        '${_organizersStats['avgEventSize']}',
                        Icons.group,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Satisfaction',
                        '${_organizersStats['avgAttendeeRating']}/5',
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
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            isScrollable: true,
            labelStyle: const TextStyle(fontFamily: 'Roboto'), // AJOUTÉ: Roboto pour les onglets
            unselectedLabelStyle: const TextStyle(fontFamily: 'Roboto'), // AJOUTÉ: Roboto pour les onglets
            tabs: const [
              Tab(text: 'Vue d\'ensemble'),
              Tab(text: 'Organisateurs'),
              Tab(text: 'Événements'),
              Tab(text: 'Finances'),
              Tab(text: 'Analytics'),
            ],
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildOrganizersTab(),
                _buildEventsTab(),
                _buildFinancesTab(),
                _buildAnalyticsTab(),
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
                  'Nouvel organisateur',
                  'Ajouter un partenaire',
                  Icons.add_business,
                  Colors.green,
                  () {
                    // Navigation vers ajout organisateur
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Validation événements',
                  'Approuver les nouveaux',
                  Icons.check_circle,
                  Colors.blue,
                  () {
                    // Navigation vers validation
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Rapport financier',
                  'Commissions & CA',
                  Icons.assessment,
                  Colors.purple,
                  () => _tabController.animateTo(3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Performance mensuelle
          _buildMonthlyPerformance(),

          const SizedBox(height: 24),

          // Organisateurs actifs
          const Text(
            'Organisateurs partenaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'PermanentMarker', // GARDÉ: PermanentMarker pour les titres
            ),
          ),
          const SizedBox(height: 12),

          ..._organizers.map((organizer) => _buildOrganizerCard(organizer)).toList(),

          const SizedBox(height: 24),

          // Prochains événements
          _buildUpcomingEvents(),
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

  Widget _buildMonthlyPerformance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance mensuelle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'PermanentMarker', // GARDÉ: PermanentMarker pour les titres
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    'CA ce mois',
                    '${_organizersStats['monthlyRevenue']}€',
                    Icons.trending_up,
                    Colors.green,
                    '+15.2%',
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    'Nouveaux événements',
                    '3',
                    Icons.event,
                    Colors.blue,
                    '+2',
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    'Taux de réservation',
                    '${_organizersStats['avgBookingRate']}%',
                    Icons.book,
                    Colors.orange,
                    '+3.1%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(
    String label,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Roboto', // CHANGÉ: Roboto pour les valeurs de performance
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Roboto', // CHANGÉ: Roboto pour les labels
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto', // CHANGÉ: Roboto pour les variations
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerCard(Map<String, dynamic> organizer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.withOpacity(0.2),
          child: Icon(Icons.business, color: Colors.purple),
        ),
        title: Text(
          organizer['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto', // CHANGÉ: Roboto pour les noms
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${organizer['organizerName']} • ${organizer['company']}',
              style: const TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip(
                  '${organizer['eventsCreated']} événements',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  '${organizer['totalRevenue']}€ CA',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  '${organizer['attendeeRating']}/5 ⭐',
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
                        'Commission Kipik',
                        '${organizer['kipikCommission']}€',
                        Icons.account_balance,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailMetric(
                        'Taille moy. événement',
                        '${organizer['avgEventSize']} pers.',
                        Icons.group,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailMetric(
                        'Taux réservation',
                        '${organizer['bookingRate']}%',
                        Icons.book,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailMetric(
                        'Taux annulation',
                        '${organizer['cancelationRate']}%',
                        Icons.cancel,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Spécialités
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
                        'Spécialités:',
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto', // CHANGÉ: Roboto
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: organizer['specialties']
                            .map<Widget>((specialty) => _buildChip(specialty, Colors.purple))
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
                        onPressed: () => _viewOrganizerDetails(organizer),
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
                        onPressed: () => _viewOrganizerEvents(organizer),
                        icon: const Icon(Icons.event, size: 16),
                        label: const Text(
                          'Événements',
                          style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewOrganizerFinances(organizer),
                        icon: const Icon(Icons.euro, size: 16),
                        label: const Text(
                          'Finances',
                          style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
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

  Widget _buildUpcomingEvents() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Prochains événements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker', // GARDÉ: PermanentMarker pour les titres
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _tabController.animateTo(2),
                  child: const Text(
                    'Voir tous',
                    style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '• Tattoo Convention Paris 2025 - 15-17 Mars 2025\n'
              '• Ink Festival Lyon - 22-23 Mars 2025\n'
              '• Workshop Advanced Techniques - 5 Avril 2025',
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

  Widget _buildOrganizersTab() {
    return const Center(
      child: Text(
        'Liste détaillée de tous les organisateurs partenaires',
        style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
      ),
    );
  }

  Widget _buildEventsTab() {
    return const Center(
      child: Text(
        'Calendrier et gestion de tous les événements',
        style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
      ),
    );
  }

  Widget _buildFinancesTab() {
    return const Center(
      child: Text(
        'Rapports financiers, commissions et paiements',
        style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Text(
        'Analytics avancées et insights événements',
        style: TextStyle(fontFamily: 'Roboto'), // CHANGÉ: Roboto
      ),
    );
  }

  void _viewOrganizerDetails(Map<String, dynamic> organizer) {
    // Navigation vers la page détaillée de l'organisateur
  }

  void _viewOrganizerEvents(Map<String, dynamic> organizer) {
    // Voir tous les événements de l'organisateur
  }

  void _viewOrganizerFinances(Map<String, dynamic> organizer) {
    // Voir les finances de l'organisateur
  }
}