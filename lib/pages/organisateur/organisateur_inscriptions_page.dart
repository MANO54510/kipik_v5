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

  // ✅ OPTIMISÉ: InputDecoration compact avec PermanentMarker
  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'PermanentMarker', // ✅ PermanentMarker conservé
          fontSize: 11, // ✅ Taille réduite mais lisible
          color: Colors.white70,
          height: 0.9, // ✅ Interligne serré
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'PermanentMarker', 
          fontSize: 12, // ✅ Taille contrôlée quand il flotte
          color: Colors.white,
          height: 0.9,
        ),
        filled: true,
        fillColor: Colors.grey[900],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, 
          vertical: 12, // ✅ Padding réduit pour compacter
        ),
        isDense: true, // ✅ CRUCIAL: Réduit la hauteur globale
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: KipikTheme.rouge, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: KipikTheme.rouge, width: 2),
        ),
      );

  // ✅ NOUVEAU: Widget pour les titres de section
  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KipikTheme.rouge, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: KipikTheme.rouge,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
                          fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les initiales
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
                              fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les noms
                            ),
                          ),
                          Text(
                            inscription['studioName'] != 'N/A' ? inscription['studioName'] : '',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontFamily: 'Roboto', // ✅ Roboto pour les détails
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
                                fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les statuts
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
                    label: Text(
                      'Voir le portfolio',
                      style: TextStyle(
                        fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les boutons
                      ),
                    ),
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
                          child: Text(
                            'Accepter',
                            style: TextStyle(
                              fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les boutons
                            ),
                          ),
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
                          child: Text(
                            'Refuser',
                            style: TextStyle(
                              fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les boutons
                            ),
                          ),
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
                    child: Text(
                      'Contacter',
                      style: TextStyle(
                        fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les boutons
                      ),
                    ),
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
            fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les titres de section
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
                fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les labels
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Roboto', // ✅ Roboto pour les valeurs
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
                // ✅ Section Titre avec icône
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _buildSectionTitle('Gestion des inscriptions', Icons.people),
                ),

                // Onglets (Tatoueurs / Vendeurs) - Optimisés
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KipikTheme.rouge, width: 1),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        child: Text(
                          'Tatoueurs',
                          style: TextStyle(
                            fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les onglets
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Vendeurs',
                          style: TextStyle(
                            fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les onglets
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    labelColor: KipikTheme.rouge,
                    unselectedLabelColor: Colors.grey[400],
                    indicatorColor: KipikTheme.rouge,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: KipikTheme.rouge.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: (_) {
                      setState(() {
                        // Mise à jour de la liste filtrée
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // ✅ Filtres optimisés
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KipikTheme.rouge.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: KipikTheme.rouge,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filtres',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'PermanentMarker',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedConvention,
                              decoration: _inputDecoration('Convention'),
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Roboto', // ✅ Roboto pour le contenu
                                fontSize: 14,
                              ),
                              dropdownColor: Colors.grey[800],
                              items: _conventions.map((convention) {
                                return DropdownMenuItem<String>(
                                  value: convention,
                                  child: Text(
                                    convention,
                                    style: TextStyle(
                                      fontFamily: 'Roboto', // ✅ Roboto pour les options
                                    ),
                                  ),
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
                              decoration: _inputDecoration('Statut'),
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Roboto', // ✅ Roboto pour le contenu
                                fontSize: 14,
                              ),
                              dropdownColor: Colors.grey[800],
                              items: _statuses.map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontFamily: 'Roboto', // ✅ Roboto pour les options
                                    ),
                                  ),
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
                
                const SizedBox(height: 16),
                
                // Liste des inscriptions
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: KipikTheme.rouge))
                      : _filteredInscriptions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 64,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune inscription trouvée',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les messages
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Modifiez vos filtres pour voir plus de résultats',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontFamily: 'Roboto', // ✅ Roboto pour les sous-textes
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
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
        side: BorderSide(
          color: KipikTheme.rouge.withOpacity(0.3), // ✅ Bordure Kipik subtile
          width: 1,
        ),
      ),
      elevation: 4, // ✅ Ombre pour plus de profondeur
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
                        fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les initiales
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
                            fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les noms
                          ),
                        ),
                        if (inscription['studioName'] != 'N/A')
                          Text(
                            inscription['studioName'],
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontFamily: 'Roboto', // ✅ Roboto pour les détails
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      inscription['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les statuts
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 16, color: KipikTheme.rouge),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        inscription['conventionName'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Roboto', // ✅ Roboto pour les détails
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                    SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM/yyyy').format(inscription['submissionDate']),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontFamily: 'Roboto', // ✅ Roboto pour les dates
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}