// lib/pages/admin/users/admin_user_detail_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class AdminUserDetailPage extends StatefulWidget {
  final String userId;
  final String userType; // 'pro', 'client', 'organizer'
  
  const AdminUserDetailPage({
    Key? key,
    required this.userId,
    required this.userType,
  }) : super(key: key);

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // Données utilisateur simulées (à remplacer par API)
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _support_tickets = [];
  Map<String, dynamic> _userStats = {};

  final _responseController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _responseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Simuler le chargement des données utilisateur
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() {
      _userData = _getSimulatedUserData();
      _transactions = _getSimulatedTransactions();
      _projects = _getSimulatedProjects();
      _support_tickets = _getSimulatedSupportTickets();
      _userStats = _getSimulatedUserStats();
      _isLoading = false;
    });
  }

  Map<String, dynamic> _getSimulatedUserData() {
    switch (widget.userType) {
      case 'pro':
        return {
          'name': 'Marie Dubois',
          'email': 'marie@studioink.com',
          'phone': '06 12 34 56 78',
          'shopName': 'Studio Ink Paris',
          'registrationDate': DateTime(2024, 6, 15),
          'lastLogin': DateTime.now().subtract(const Duration(hours: 2)),
          'status': 'active',
          'subscriptionType': 'annual',
          'address': '15 rue de Rivoli, 75001 Paris',
          'siret': '12345678901234',
          'isVerified': true,
        };
      case 'client':
        return {
          'name': 'Lucas Martin',
          'email': 'lucas.martin@gmail.com',
          'phone': '06 98 76 54 32',
          'age': 28,
          'registrationDate': DateTime(2024, 8, 22),
          'lastLogin': DateTime.now().subtract(const Duration(minutes: 30)),
          'status': 'active',
          'address': '42 avenue des Champs, 69000 Lyon',
          'isVerified': true,
        };
      default:
        return {
          'name': 'EventCorp SAS',
          'email': 'contact@eventcorp.fr',
          'phone': '01 42 33 44 55',
          'organizerName': 'Jean-Pierre Moreau',
          'registrationDate': DateTime(2024, 3, 10),
          'lastLogin': DateTime.now().subtract(const Duration(days: 1)),
          'status': 'active',
          'company': 'EventCorp SAS',
          'siret': '98765432109876',
        };
    }
  }

  List<Map<String, dynamic>> _getSimulatedTransactions() {
    return [
      {
        'id': 'TXN_001',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'amount': 285.50,
        'type': 'payment',
        'description': 'Tatouage bras - Studio Ink Paris',
        'status': 'completed',
      },
      {
        'id': 'TXN_002',
        'date': DateTime.now().subtract(const Duration(days: 15)),
        'amount': 150.00,
        'type': 'payment',
        'description': 'Acompte tatouage dos',
        'status': 'completed',
      },
      {
        'id': 'TXN_003',
        'date': DateTime.now().subtract(const Duration(days: 22)),
        'amount': 320.00,
        'type': 'refund',
        'description': 'Remboursement suite annulation',
        'status': 'processed',
      },
    ];
  }

  List<Map<String, dynamic>> _getSimulatedProjects() {
    return [
      {
        'id': 'PRJ_001',
        'title': 'Tatouage bras tribal',
        'tattooist': 'Marie Dubois - Studio Ink',
        'status': 'completed',
        'amount': 285.50,
        'createdDate': DateTime.now().subtract(const Duration(days: 10)),
        'completedDate': DateTime.now().subtract(const Duration(days: 5)),
        'rating': 4.8,
      },
      {
        'id': 'PRJ_002',
        'title': 'Design dos complet',
        'tattooist': 'Thomas Martin - Black Needle',
        'status': 'in_progress',
        'amount': 850.00,
        'createdDate': DateTime.now().subtract(const Duration(days: 3)),
        'estimatedCompletion': DateTime.now().add(const Duration(days: 7)),
        'rating': null,
      },
    ];
  }

  List<Map<String, dynamic>> _getSimulatedSupportTickets() {
    return [
      {
        'id': 'SUP_001',
        'subject': 'Problème de paiement',
        'status': 'open',
        'priority': 'high',
        'createdDate': DateTime.now().subtract(const Duration(hours: 6)),
        'category': 'payment',
        'description': 'Impossible de finaliser le paiement pour mon projet',
        'lastResponse': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': 'SUP_002',
        'subject': 'Question sur les devis',
        'status': 'resolved',
        'priority': 'medium',
        'createdDate': DateTime.now().subtract(const Duration(days: 3)),
        'category': 'general',
        'description': 'Comment modifier un devis envoyé ?',
        'resolvedDate': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];
  }

  Map<String, dynamic> _getSimulatedUserStats() {
    switch (widget.userType) {
      case 'pro':
        return {
          'totalProjects': 45,
          'completedProjects': 38,
          'totalRevenue': 8420.50,
          'avgProjectValue': 185.50,
          'avgResponseTime': '2.1h',
          'customerRating': 4.6,
          'reportCount': 0,
          'subscriptionRevenue': 948.0,
        };
      case 'client':
        return {
          'totalProjects': 3,
          'completedProjects': 1,
          'totalSpent': 755.50,
          'avgProjectValue': 251.83,
          'favoriteStyles': ['Minimaliste', 'Géométrique'],
          'satisfactionScore': 4.8,
          'reportCount': 0,
        };
      default:
        return {
          'totalEvents': 8,
          'activeEvents': 2,
          'totalRevenue': 45200.0,
          'avgEventSize': 65,
          'totalAttendees': 520,
          'bookingRate': 78.5,
          'avgRating': 4.6,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    Color userTypeColor = widget.userType == 'pro' ? KipikTheme.rouge :
                         widget.userType == 'client' ? Colors.blue : Colors.purple;

    return Scaffold(
      appBar: CustomAppBarKipik(
        title: 'Profil ${widget.userType == 'pro' ? 'Tatoueur' : widget.userType == 'client' ? 'Client' : 'Organisateur'}',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header utilisateur
                _buildUserHeader(userTypeColor),
                
                // Onglets
                TabBar(
                  controller: _tabController,
                  labelColor: userTypeColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: userTypeColor,
                  isScrollable: true,
                  labelStyle: const TextStyle(fontFamily: 'Roboto'),
                  tabs: const [
                    Tab(text: 'Vue d\'ensemble'),
                    Tab(text: 'Transactions'),
                    Tab(text: 'Projets/Activité'),
                    Tab(text: 'Support SAV'),
                    Tab(text: 'Actions Admin'),
                  ],
                ),
                
                // Contenu des onglets
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildTransactionsTab(),
                      _buildProjectsTab(),
                      _buildSupportTab(),
                      _buildAdminActionsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserHeader(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              widget.userType == 'pro' ? Icons.brush :
              widget.userType == 'client' ? Icons.person : Icons.business,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userData['name'] ?? 'Nom inconnu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userData['email'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                  ),
                ),
                if (widget.userType == 'pro' && _userData['shopName'] != null)
                  Text(
                    _userData['shopName'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusChip(_userData['status'] ?? 'unknown'),
                    const SizedBox(width: 8),
                    if (_userData['isVerified'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          'Vérifié',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
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

  Widget _buildStatusChip(String status) {
    Color chipColor = status == 'active' ? Colors.green : 
                     status == 'suspended' ? Colors.red : Colors.orange;
    String statusText = status == 'active' ? 'Actif' :
                       status == 'suspended' ? 'Suspendu' : 'Inactif';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques principales
          const Text(
            'Statistiques principales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'PermanentMarker',
            ),
          ),
          const SizedBox(height: 16),
          
          _buildStatsGrid(),
          
          const SizedBox(height: 24),
          
          // Informations détaillées
          const Text(
            'Informations détaillées',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'PermanentMarker',
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDetailedInfo(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    List<Widget> statItems = [];
    
    _userStats.forEach((key, value) {
      String label = _getStatLabel(key);
      String displayValue = _formatStatValue(key, value);
      
      statItems.add(
        _buildStatItem(label, displayValue, _getStatIcon(key), _getStatColor(key))
      );
    });

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: statItems,
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Roboto', // Roboto pour les chiffres
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Email', _userData['email']),
            _buildInfoRow('Téléphone', _userData['phone']),
            if (_userData['address'] != null)
              _buildInfoRow('Adresse', _userData['address']),
            if (_userData['siret'] != null)
              _buildInfoRow('SIRET', _userData['siret']),
            _buildInfoRow('Inscription', _formatDate(_userData['registrationDate'])),
            _buildInfoRow('Dernière connexion', _formatDate(_userData['lastLogin'])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Non renseigné',
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    Color statusColor = transaction['status'] == 'completed' ? Colors.green :
                       transaction['status'] == 'processed' ? Colors.blue : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            transaction['type'] == 'payment' ? Icons.payment : Icons.undo,
            color: statusColor,
          ),
        ),
        title: Text(
          transaction['description'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${transaction['id']} • ${_formatDate(transaction['date'])}',
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 4),
            Text(
              transaction['status'] == 'completed' ? 'Complété' :
              transaction['status'] == 'processed' ? 'Traité' : 'En attente',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        trailing: Text(
          '${transaction['amount']}€',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: transaction['type'] == 'payment' ? Colors.green : Colors.red,
            fontFamily: 'Roboto', // Roboto pour les montants
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    Color statusColor = project['status'] == 'completed' ? Colors.green :
                       project['status'] == 'in_progress' ? Colors.blue : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.brush, color: statusColor),
        ),
        title: Text(
          project['title'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        subtitle: Text(
          project['tattooist'],
          style: const TextStyle(fontFamily: 'Roboto'),
        ),
        trailing: Text(
          '${project['amount']}€',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('ID Projet', project['id']),
                _buildInfoRow('Statut', project['status']),
                _buildInfoRow('Créé le', _formatDate(project['createdDate'])),
                if (project['completedDate'] != null)
                  _buildInfoRow('Terminé le', _formatDate(project['completedDate'])),
                if (project['estimatedCompletion'] != null)
                  _buildInfoRow('Estimation fin', _formatDate(project['estimatedCompletion'])),
                if (project['rating'] != null)
                  _buildInfoRow('Note client', '${project['rating']}/5 ⭐'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTab() {
    return Column(
      children: [
        // Nouveau ticket SAV
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Répondre au client',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PermanentMarker',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _responseController,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'Roboto'),
                decoration: const InputDecoration(
                  labelText: 'Votre réponse',
                  labelStyle: TextStyle(fontFamily: 'Roboto'),
                  border: OutlineInputBorder(),
                  hintText: 'Tapez votre réponse...',
                  hintStyle: TextStyle(fontFamily: 'Roboto'),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _sendResponse,
                icon: const Icon(Icons.send),
                label: const Text(
                  'Envoyer la réponse',
                  style: TextStyle(fontFamily: 'Roboto'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        // Historique tickets
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _support_tickets.length,
            itemBuilder: (context, index) {
              final ticket = _support_tickets[index];
              return _buildSupportTicketCard(ticket);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupportTicketCard(Map<String, dynamic> ticket) {
    Color priorityColor = ticket['priority'] == 'high' ? Colors.red :
                         ticket['priority'] == 'medium' ? Colors.orange : Colors.blue;
    Color statusColor = ticket['status'] == 'resolved' ? Colors.green :
                       ticket['status'] == 'open' ? Colors.red : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          ticket['subject'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket['priority'].toUpperCase(),
                style: TextStyle(
                  color: priorityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket['status'].toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket['description'],
                  style: const TextStyle(fontFamily: 'Roboto'),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('ID Ticket', ticket['id']),
                _buildInfoRow('Catégorie', ticket['category']),
                _buildInfoRow('Créé le', _formatDate(ticket['createdDate'])),
                if (ticket['resolvedDate'] != null)
                  _buildInfoRow('Résolu le', _formatDate(ticket['resolvedDate'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions administrateur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'PermanentMarker',
            ),
          ),
          const SizedBox(height: 16),
          
          // Notes administrateur
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes administrateur',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PermanentMarker',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    style: const TextStyle(fontFamily: 'Roboto'),
                    decoration: const InputDecoration(
                      labelText: 'Ajouter une note interne',
                      labelStyle: TextStyle(fontFamily: 'Roboto'),
                      border: OutlineInputBorder(),
                      hintText: 'Note visible uniquement par les admins...',
                      hintStyle: TextStyle(fontFamily: 'Roboto'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _saveNote,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Sauvegarder la note',
                      style: TextStyle(fontFamily: 'Roboto'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions rapides
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'PermanentMarker',
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                'Contacter par email',
                Icons.email,
                Colors.blue,
                _contactUser,
              ),
              _buildActionButton(
                'Suspendre compte',
                Icons.block,
                Colors.red,
                _suspendUser,
              ),
              _buildActionButton(
                'Réinitialiser mot de passe',
                Icons.lock_reset,
                Colors.orange,
                _resetPassword,
              ),
              _buildActionButton(
                'Exporter données',
                Icons.download,
                Colors.green,
                _exportUserData,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontFamily: 'Roboto'),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Méthodes utilitaires
  String _getStatLabel(String key) {
    final labels = {
      'totalProjects': 'Projets total',
      'completedProjects': 'Projets terminés',
      'totalRevenue': 'Revenus total',
      'totalSpent': 'Dépenses total',
      'avgProjectValue': 'Valeur moyenne',
      'avgResponseTime': 'Temps de réponse',
      'customerRating': 'Note moyenne',
      'satisfactionScore': 'Satisfaction',
      'reportCount': 'Signalements',
      'subscriptionRevenue': 'Revenus abonnement',
      'totalEvents': 'Événements total',
      'activeEvents': 'Événements actifs',
      'avgEventSize': 'Taille moyenne',
      'totalAttendees': 'Participants total',
      'bookingRate': 'Taux réservation',
      'avgRating': 'Note moyenne',
    };
    return labels[key] ?? key;
  }

  String _formatStatValue(String key, dynamic value) {
    if (key.contains('Revenue') || key.contains('Spent') || key.contains('Value')) {
      return '${value}€';
    } else if (key.contains('Rate') || key.contains('Rating') || key.contains('Score')) {
      if (key.contains('Rate')) {
        return '${value}%';
      } else {
        return '${value}/5';
      }
    } else if (key.contains('Time')) {
      return '${value}';
    }
    return value.toString();
  }

  IconData _getStatIcon(String key) {
    if (key.contains('Revenue') || key.contains('Spent')) return Icons.euro;
    if (key.contains('Projects') || key.contains('Events')) return Icons.work;
    if (key.contains('Rating') || key.contains('Score')) return Icons.star;
    if (key.contains('Time')) return Icons.schedule;
    if (key.contains('Report')) return Icons.warning;
    return Icons.analytics;
  }

  Color _getStatColor(String key) {
    if (key.contains('Revenue') || key.contains('Spent')) return Colors.green;
    if (key.contains('Projects') || key.contains('Events')) return Colors.blue;
    if (key.contains('Rating') || key.contains('Score')) return Colors.amber;
    if (key.contains('Report')) return Colors.red;
    return Colors.purple;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non renseigné';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Actions
  void _sendResponse() {
    if (_responseController.text.trim().isNotEmpty) {
      // Logique d'envoi de réponse
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réponse envoyée avec succès')),
      );
      _responseController.clear();
    }
  }

  void _saveNote() {
    if (_noteController.text.trim().isNotEmpty) {
      // Logique de sauvegarde de note
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note sauvegardée')),
      );
      _noteController.clear();
    }
  }

  void _contactUser() {
    // Logique de contact utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email envoyé à l\'utilisateur')),
    );
  }

  void _suspendUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Suspendre le compte',
          style: TextStyle(fontFamily: 'PermanentMarker'),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir suspendre ce compte ?',
          style: TextStyle(fontFamily: 'Roboto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compte suspendu')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Suspendre',
              style: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
            ),
          ),
        ],
      ),
    );
  }

  void _resetPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email de réinitialisation envoyé')),
    );
  }

  void _exportUserData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export des données en cours...')),
    );
  }
}