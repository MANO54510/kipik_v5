// lib/pages/organisateur/organisateur_inscriptions_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:intl/intl.dart';

class OrganisateurInscriptionsPage extends StatefulWidget {
  const OrganisateurInscriptionsPage({Key? key}) : super(key: key);

  @override
  _OrganisateurInscriptionsPageState createState() => _OrganisateurInscriptionsPageState();
}

class _OrganisateurInscriptionsPageState extends State<OrganisateurInscriptionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  // Filtres
  String _selectedConvention = 'Toutes les conventions';
  String _status = 'Tous';
  
  // Données fictives
  final List<Map<String, dynamic>> _inscriptions = [
    {
      'id': '1',
      'artistName': 'Jean Dumont',
      'studioName': 'Ink Masters Paris',
      'conventionName': 'Tattoo Expo Paris 2025',
      'submissionDate': DateTime.now().subtract(Duration(days: 5)),
      'status': 'En attente',
      'email': 'jean.dumont@example.com',
      'phone': '+33 6 12 34 56 78',
      'category': 'Tatoueur',
      'portfolio': 'https://example.com/portfolio',
    },
    {
      'id': '2',
      'artistName': 'Sophie Martin',
      'studioName': 'Art Ink Studio',
      'conventionName': 'Tattoo Expo Paris 2025',
      'submissionDate': DateTime.now().subtract(Duration(days: 10)),
      'status': 'Accepté',
      'email': 'sophie.martin@example.com',
      'phone': '+33 6 98 76 54 32',
      'category': 'Tatoueur',
      'portfolio': 'https://example.com/portfolio',
    },
    {
      'id': '3',
      'artistName': 'MicroNeedle France',
      'studioName': 'N/A',
      'conventionName': 'Ink Festival Lyon',
      'submissionDate': DateTime.now().subtract(Duration(days: 3)),
      'status': 'En attente',
      'email': 'contact@microneedle.fr',
      'phone': '+33 4 56 78 90 12',
      'category': 'Vendeur',
      'portfolio': null,
    },
    {
      'id': '4',
      'artistName': 'Lucie Dupont',
      'studioName': 'Electric Needle',
      'conventionName': 'Tattoo Art Show Marseille',
      'submissionDate': DateTime.now().subtract(Duration(days: 15)),
      'status': 'Refusé',
      'email': 'lucie@electricneedle.com',
      'phone': '+33 7 12 34 56 78',
      'category': 'Tatoueur',
      'portfolio': 'https://example.com/portfolio',
    },
  ];
  
  final List<String> _conventions = [
    'Toutes les conventions',
    'Tattoo Expo Paris 2025',
    'Ink Festival Lyon',
    'Tattoo Art Show Marseille',
  ];
  
  final List<String> _statuses = [
    'Tous',
    'En attente',
    'Accepté',
    'Refusé',
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  List<Map<String, dynamic>> get _filteredInscriptions {
    return _inscriptions.where((inscription) {
      final matchesConvention = _selectedConvention == 'Toutes les conventions' || 
                              inscription['conventionName'] == _selectedConvention;
      final matchesStatus = _status == 'Tous' || 
                          inscription['status'] == _status;
      
      if (_tabController.index == 0) {
        // Onglet Tatoueurs
        return matchesConvention && matchesStatus && inscription['category'] == 'Tatoueur';
      } else {
        // Onglet Vendeurs
        return matchesConvention && matchesStatus && inscription['category'] == 'Vendeur';
      }
    }).toList();
  }
  
  void _showInscriptionDetails(Map<String, dynamic> inscription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.all(16),
            child: ListView(
              controller: controller,
              children: [
                // Barre de glissement
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                
                // Entête
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: KipikTheme.rouge,
                      child: Text(
                        inscription['artistName'][0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inscription['artistName'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PermanentMarker',
                            ),
                          ),
                          Text(
                            inscription['studioName'] != 'N/A' ? inscription['studioName'] : '',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(inscription['status']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              inscription['status'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Détails de la demande
                _buildDetailSection('Informations de contact'),
                _buildDetailRow('Email', inscription['email']),
                _buildDetailRow('Téléphone', inscription['phone']),
                _buildDetailRow('Convention', inscription['conventionName']),
                _buildDetailRow('Date de demande', DateFormat('dd/MM/yyyy').format(inscription['submissionDate'])),
                
                SizedBox(height: 24),
                
                if (inscription['portfolio'] != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Ouvrir le portfolio
                    },
                    icon: Icon(Icons.photo_library),
                    label: Text('Voir le portfolio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                
                SizedBox(height: 24),
                
                // Boutons d'action
                if (inscription['status'] == 'En attente')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Accepter la demande
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Demande acceptée'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Accepter'),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Refuser la demande
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Demande refusée'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Refuser'),
                        ),
                      ),
                    ],
                  ),
                
                if (inscription['status'] != 'En attente')
                  ElevatedButton(
                    onPressed: () {
                      // Contacter le participant
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KipikTheme.rouge,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Contacter'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente':
        return Colors.orange;
      case 'Accepté':
        return Colors.green;
      case 'Refusé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildDetailSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: KipikTheme.rouge,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'PermanentMarker',
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Inscriptions',
        showBackButton: true,
        showBurger: true,
        showNotificationIcon: true,
      ),
      drawer: DrawerFactory.of(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arrière-plan
          Image.asset(
            'assets/background_charbon.png',
            fit: BoxFit.cover,
          ),
          
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // Onglets (Tatoueurs / Vendeurs)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'Tatoueurs'),
                      Tab(text: 'Vendeurs'),
                    ],
                    labelColor: KipikTheme.rouge,
                    unselectedLabelColor: Colors.grey[400],
                    indicatorColor: KipikTheme.rouge,
                    onTap: (_) {
                      setState(() {
                        // Mise à jour de la liste filtrée
                      });
                    },
                  ),
                ),
                
                // Filtres
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedConvention,
                              decoration: InputDecoration(
                                labelText: 'Convention',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[900],
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              style: TextStyle(color: Colors.white),
                              dropdownColor: Colors.grey[800],
                              items: _conventions.map((convention) {
                                return DropdownMenuItem<String>(
                                  value: convention,
                                  child: Text(convention),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedConvention = value;
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: InputDecoration(
                                labelText: 'Statut',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[900],
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              style: TextStyle(color: Colors.white),
                              dropdownColor: Colors.grey[800],
                              items: _statuses.map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _status = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Liste des inscriptions
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: KipikTheme.rouge))
                      : _filteredInscriptions.isEmpty
                          ? Center(
                              child: Text(
                                'Aucune inscription trouvée',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _filteredInscriptions.length,
                              itemBuilder: (context, index) {
                                final inscription = _filteredInscriptions[index];
                                return _buildInscriptionCard(inscription);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInscriptionCard(Map<String, dynamic> inscription) {
    final statusColor = _getStatusColor(inscription['status']);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showInscriptionDetails(inscription),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: KipikTheme.rouge,
                    child: Text(
                      inscription['artistName'][0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inscription['artistName'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          inscription['studioName'] != 'N/A' ? inscription['studioName'] : '',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      inscription['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey[400]),
                  SizedBox(width: 4),
                  Text(
                    inscription['conventionName'],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                  SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(inscription['submissionDate']),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}