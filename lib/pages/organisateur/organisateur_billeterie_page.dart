// lib/pages/organisateur/organisateur_billeterie_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:intl/intl.dart';

class OrganisateurBilleteriePage extends StatefulWidget {
  const OrganisateurBilleteriePage({Key? key}) : super(key: key);

  @override
  _OrganisateurBilleteriePageState createState() => _OrganisateurBilleteriePageState();
}

class _OrganisateurBilleteriePageState extends State<OrganisateurBilleteriePage> {
  bool _isLoading = false;
  
  // Filtres
  String _selectedConvention = 'Toutes les conventions';
  String _selectedTicketType = 'Tous les types';
  
  // Données fictives
  final List<Map<String, dynamic>> _tickets = [
    {
      'id': '1',
      'conventionName': 'Tattoo Expo Paris 2025',
      'ticketType': 'Jour',
      'price': 15.0,
      'soldCount': 124,
      'availableCount': 500,
      'revenue': 1860.0,
      'startDate': DateTime(2025, 7, 15),
      'endDate': DateTime(2025, 7, 17),
    },
    {
      'id': '2',
      'conventionName': 'Tattoo Expo Paris 2025',
      'ticketType': 'Week-end',
      'price': 25.0,
      'soldCount': 75,
      'availableCount': 300,
      'revenue': 1875.0,
      'startDate': DateTime(2025, 7, 15),
      'endDate': DateTime(2025, 7, 17),
    },
    {
      'id': '3',
      'conventionName': 'Ink Festival Lyon',
      'ticketType': 'Jour',
      'price': 12.0,
      'soldCount': 87,
      'availableCount': 400,
      'revenue': 1044.0,
      'startDate': DateTime(2025, 9, 5),
      'endDate': DateTime(2025, 9, 7),
    },
    {
      'id': '4',
      'conventionName': 'Ink Festival Lyon',
      'ticketType': 'Week-end',
      'price': 20.0,
      'soldCount': 54,
      'availableCount': 200,
      'revenue': 1080.0,
      'startDate': DateTime(2025, 9, 5),
      'endDate': DateTime(2025, 9, 7),
    },
    {
      'id': '5',
      'conventionName': 'Tattoo Art Show Marseille',
      'ticketType': 'Jour',
      'price': 10.0,
      'soldCount': 45,
      'availableCount': 300,
      'revenue': 450.0,
      'startDate': DateTime(2025, 10, 12),
      'endDate': DateTime(2025, 10, 13),
    },
    {
      'id': '6',
      'conventionName': 'Tattoo Art Show Marseille',
      'ticketType': 'Week-end',
      'price': 18.0,
      'soldCount': 32,
      'availableCount': 150,
      'revenue': 576.0,
      'startDate': DateTime(2025, 10, 12),
      'endDate': DateTime(2025, 10, 13),
    },
  ];
  
  final List<String> _conventions = [
    'Toutes les conventions',
    'Tattoo Expo Paris 2025',
    'Ink Festival Lyon',
    'Tattoo Art Show Marseille',
  ];
  
  final List<String> _ticketTypes = [
    'Tous les types',
    'Jour',
    'Week-end',
  ];
  
  List<Map<String, dynamic>> get _filteredTickets {
    return _tickets.where((ticket) {
      final matchesConvention = _selectedConvention == 'Toutes les conventions' || 
                              ticket['conventionName'] == _selectedConvention;
      final matchesType = _selectedTicketType == 'Tous les types' || 
                        ticket['ticketType'] == _selectedTicketType;
      
      return matchesConvention && matchesType;
    }).toList();
  }
  
  double get _totalRevenue {
    if (_selectedConvention == 'Toutes les conventions') {
      return _filteredTickets.fold(0, (sum, ticket) => sum + (ticket['revenue'] as double));
    } else {
      return _filteredTickets.fold(0, (sum, ticket) => sum + (ticket['revenue'] as double));
    }
  }
  
  int get _totalTicketsSold {
    if (_selectedConvention == 'Toutes les conventions') {
      return _filteredTickets.fold(0, (sum, ticket) => sum + (ticket['soldCount'] as int));
    } else {
      return _filteredTickets.fold(0, (sum, ticket) => sum + (ticket['soldCount'] as int));
    }
  }
  
  Future<void> _editTicketSettings(Map<String, dynamic> ticket) async {
    final priceController = TextEditingController(text: ticket['price'].toString());
    final availableController = TextEditingController(text: ticket['availableCount'].toString());
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier les paramètres de billeterie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Prix (€)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: availableController,
              decoration: InputDecoration(
                labelText: 'Nombre de billets disponibles',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
            ),
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        final newPrice = double.parse(priceController.text);
        final newAvailable = int.parse(availableController.text);
        
        setState(() {
          // Mettre à jour les données
          final index = _tickets.indexWhere((t) => t['id'] == ticket['id']);
          if (index != -1) {
            _tickets[index] = {
              ..._tickets[index],
              'price': newPrice,
              'availableCount': newAvailable,
            };
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paramètres de billeterie mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Valeurs incorrectes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Billeterie',
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
                              value: _selectedTicketType,
                              decoration: InputDecoration(
                                labelText: 'Type de billet',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[900],
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              style: TextStyle(color: Colors.white),
                              dropdownColor: Colors.grey[800],
                              items: _ticketTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedTicketType = value;
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
                
                // Résumé des ventes
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Résumé des ventes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PermanentMarker',
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Billets vendus', _totalTicketsSold.toString()),
                          _buildStatItem('Revenus', '${_totalRevenue.toStringAsFixed(2)} €'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Liste des billets
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: KipikTheme.rouge))
                      : _filteredTickets.isEmpty
                          ? Center(
                              child: Text(
                                'Aucun billet trouvé',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _filteredTickets.length,
                              itemBuilder: (context, index) {
                                final ticket = _filteredTickets[index];
                                return _buildTicketCard(ticket);
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
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: KipikTheme.rouge,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final soldPercentage = (ticket['soldCount'] / (ticket['soldCount'] + ticket['availableCount'])) * 100;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                      ticket['conventionName'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM', 'fr_FR').format(ticket['startDate']) + ' - ' + 
                      DateFormat('d MMM yyyy', 'fr_FR').format(ticket['endDate']),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ticket['ticketType'] == 'Jour' ? Colors.amber.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Billet ' + ticket['ticketType'],
                    style: TextStyle(
                      color: ticket['ticketType'] == 'Jour' ? Colors.amber : Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTicketInfo('Prix', '${ticket['price'].toStringAsFixed(2)} €'),
                _buildTicketInfo('Vendus', '${ticket['soldCount']}'),
                _buildTicketInfo('Disponibles', '${ticket['availableCount']}'),
                _buildTicketInfo('Revenus', '${ticket['revenue'].toStringAsFixed(2)} €'),
              ],
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression des ventes',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${soldPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: soldPercentage / 100,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editTicketSettings(ticket),
                  icon: Icon(Icons.edit, size: 16),
                  label: Text('Modifier'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTicketInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}