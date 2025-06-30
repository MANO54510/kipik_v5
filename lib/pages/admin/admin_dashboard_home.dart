// lib/pages/admin/admin_dashboard_home.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_admin.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

// Import des espaces de gestion
import 'package:kipik_v5/pages/admin/pros/admin_pros_management_page.dart';
import 'package:kipik_v5/pages/admin/clients/admin_clients_management_page.dart';
import 'package:kipik_v5/pages/admin/organizers/admin_organizers_management_page.dart';
import 'package:kipik_v5/pages/admin/admin_free_codes_page.dart';

class AdminDashboardHome extends StatefulWidget {
  const AdminDashboardHome({Key? key}) : super(key: key);

  @override
  State<AdminDashboardHome> createState() => _AdminDashboardHomeState();
}

class _AdminDashboardHomeState extends State<AdminDashboardHome> {
  bool _isLoading = true;
  
  // Statistiques globales (à remplacer par de vraies données)
  Map<String, dynamic> _globalStats = {
    'totalUsers': 1247,
    'activePros': 89,
    'activeClients': 1156,
    'activeOrganizers': 2,
    'monthlyRevenue': 12450.50,
    'newUsersThisMonth': 156,
    'reportsThisMonth': 3,
  };

  // Stats détaillées par profil
  Map<String, dynamic> _proStats = {
    'total': 89,
    'newThisMonth': 12,
    'activeSubscriptions': 76,
    'avgResponseTime': '2.4h',
    'avgQuoteAcceptance': '68%',
    'totalRevenue': 8940.00,
    'reportedAccounts': 2,
  };

  Map<String, dynamic> _clientStats = {
    'total': 1156,
    'newThisMonth': 142,
    'activeProjects': 234,
    'avgProjectValue': 285.50,
    'satisfactionRate': '92%',
    'reportedAccounts': 8,
    'flaggedAccounts': 3,
  };

  Map<String, dynamic> _organizerStats = {
    'total': 2,
    'activeConventions': 3,
    'upcomingEvents': 7,
    'totalRevenue': 15600.00,
    'avgEventSize': 45,
    'bookingRate': '78%',
    'reportedAccounts': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simuler le chargement des données
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarKipik(
        title: 'Dashboard Administrateur',
        showBackButton: false,
        showBurger: true,
        showNotificationIcon: true,
      ),
      drawer: const CustomDrawerAdmin(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header avec statistiques globales
                      _buildGlobalStatsHeader(),
                      
                      const SizedBox(height: 24),
                      
                      // Section des 3 profils principaux
                      const Text(
                        'Gestion des profils utilisateurs',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PermanentMarker',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cliquez sur un profil pour accéder à sa gestion complète',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Les 3 cartes principales
                      _buildProfileCard(
                        title: 'TATOUEURS PROFESSIONNELS',
                        subtitle: 'Gestion des comptes pros, abonnements, SAV',
                        stats: _proStats,
                        color: KipikTheme.rouge,
                        icon: Icons.brush,
                        onTap: () => _navigateToProManagement(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildProfileCard(
                        title: 'CLIENTS PARTICULIERS',
                        subtitle: 'Gestion des comptes clients, projets, signalements',
                        stats: _clientStats,
                        color: Colors.blue,
                        icon: Icons.person,
                        onTap: () => _navigateToClientManagement(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildProfileCard(
                        title: 'ORGANISATEURS ÉVÉNEMENTS',
                        subtitle: 'Gestion conventions, événements, revenus',
                        stats: _organizerStats,
                        color: Colors.purple,
                        icon: Icons.event,
                        onTap: () => _navigateToOrganizerManagement(),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Actions rapides
                      _buildQuickActions(),
                      
                      const SizedBox(height: 32),
                      
                      // Alertes et notifications importantes
                      _buildAlertsSection(),
                      
                      // Padding bottom pour SafeArea
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildGlobalStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: KipikTheme.rouge.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vue d\'ensemble Kipik',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'PermanentMarker',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGlobalStatItem(
                  'Utilisateurs totaux',
                  '${_globalStats['totalUsers']}',
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildGlobalStatItem(
                  'Revenus mensuel',
                  '${_globalStats['monthlyRevenue']}€',
                  Icons.euro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGlobalStatItem(
                  'Nouveaux ce mois',
                  '${_globalStats['newUsersThisMonth']}',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildGlobalStatItem(
                  'Signalements',
                  '${_globalStats['reportsThisMonth']}',
                  Icons.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStatItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto', // CHANGÉ: Roboto pour les chiffres
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: 'Roboto', // CHANGÉ: Roboto pour les labels
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required String subtitle,
    required Map<String, dynamic> stats,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la carte
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontFamily: 'PermanentMarker', // GARDÉ: PermanentMarker pour les titres
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontFamily: 'Roboto', // CHANGÉ: Roboto pour les sous-titres descriptifs
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Statistiques en grille
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatChip('Total: ${stats['total']}', color),
                  _buildStatChip('Nouveaux: ${stats['newThisMonth']}', Colors.green),
                  if (stats.containsKey('activeSubscriptions'))
                    _buildStatChip('Abonnés: ${stats['activeSubscriptions']}', Colors.blue),
                  if (stats.containsKey('activeProjects'))
                    _buildStatChip('Projets actifs: ${stats['activeProjects']}', Colors.blue),
                  if (stats.containsKey('activeConventions'))
                    _buildStatChip('Conventions: ${stats['activeConventions']}', Colors.blue),
                  if (stats['reportedAccounts'] > 0)
                    _buildStatChip('⚠️ Signalés: ${stats['reportedAccounts']}', Colors.orange),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Métriques importantes
              if (stats.containsKey('avgResponseTime') || stats.containsKey('satisfactionRate'))
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (stats.containsKey('avgResponseTime')) ...[
                        Expanded(
                          child: Text(
                            'Temps réponse moyen\n${stats['avgResponseTime']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Roboto', // CHANGÉ: Roboto pour les métriques
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      if (stats.containsKey('satisfactionRate')) ...[
                        Expanded(
                          child: Text(
                            'Satisfaction\n${stats['satisfactionRate']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Roboto', // CHANGÉ: Roboto pour les métriques
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      if (stats.containsKey('avgQuoteAcceptance')) ...[
                        Expanded(
                          child: Text(
                            'Taux acceptation\n${stats['avgQuoteAcceptance']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Roboto', // CHANGÉ: Roboto pour les métriques
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      if (stats.containsKey('bookingRate')) ...[
                        Expanded(
                          child: Text(
                            'Taux réservation\n${stats['bookingRate']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Roboto', // CHANGÉ: Roboto pour les métriques
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto', // CHANGÉ: Roboto pour les chips
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'PermanentMarker', // GARDÉ: PermanentMarker pour les titres
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Codes gratuits',
                'Générer des codes promo',
                Icons.card_giftcard,
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminFreeCodesPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Push notification',
                'Envoyer une notification',
                Icons.notifications_active,
                Colors.orange,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Page en cours de développement')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Nouvelle convention',
                'Créer un événement',
                Icons.add_circle,
                Colors.blue,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Page en cours de développement')),
                  );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Page en cours de développement')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
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
                style: const TextStyle(
                  color: Colors.grey,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertes et notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'PermanentMarker', // GARDÉ: PermanentMarker pour les titres
          ),
        ),
        const SizedBox(height: 16),
        
        // Alerte signalements
        if (_globalStats['reportsThisMonth'] > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Signalements à traiter',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto', // CHANGÉ: Roboto pour le texte
                        ),
                      ),
                      Text(
                        '${_globalStats['reportsThisMonth']} nouveaux signalements ce mois nécessitent votre attention',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Roboto', // CHANGÉ: Roboto pour le texte
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Page en cours de développement')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
      ],
    );
  }

  void _navigateToProManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminProsManagementPage()),
    );
  }

  void _navigateToClientManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminClientsManagementPage()),
    );
  }

  void _navigateToOrganizerManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminOrganizersManagementPage()),
    );
  }
}