// lib/pages/organisateur/organisateur_conventions_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/models/convention.dart';
import 'package:intl/intl.dart';

class OrganisateurConventionsPage extends StatefulWidget {
  const OrganisateurConventionsPage({Key? key}) : super(key: key);

  @override
  _OrganisateurConventionsPageState createState() => _OrganisateurConventionsPageState();
}

class _OrganisateurConventionsPageState extends State<OrganisateurConventionsPage> {
  bool _isLoading = false;
  final List<Convention> _myConventions = []; // Cette liste sera remplie avec les conventions réelles
  
  @override
  void initState() {
    super.initState();
    _loadConventions();
  }
  
  Future<void> _loadConventions() async {
    setState(() {
      _isLoading = true;
    });
    
    // Simuler le chargement des données
    await Future.delayed(Duration(seconds: 1));
    
    // TODO: Obtenir les conventions réelles depuis un service
    // final conventions = await conventionService.getMyConventions();
    
    // Pour l'instant, ajoutons des données de test
    final mockConventions = [
      Convention(
        id: '1',
        title: 'Tattoo Expo Paris 2025',
        location: 'Paris Expo Porte de Versailles',
        description: 'La plus grande convention de tatouage en France',
        start: DateTime(2025, 7, 15),
        end: DateTime(2025, 7, 17),
        isPremium: true,
        isOpen: true,
        imageUrl: 'assets/background1.png',
      ),
      Convention(
        id: '2',
        title: 'Ink Festival Lyon',
        location: 'Eurexpo Lyon',
        description: 'Festival dédié à l\'art du tatouage',
        start: DateTime(2025, 9, 5),
        end: DateTime(2025, 9, 7),
        isPremium: false,
        isOpen: true,
        imageUrl: 'assets/background2.png',
      ),
      Convention(
        id: '3',
        title: 'Tattoo Art Show Marseille',
        location: 'Parc Chanot, Marseille',
        description: 'Convention méditerranéenne des arts corporels',
        start: DateTime(2025, 10, 12),
        end: DateTime(2025, 10, 13),
        isPremium: false,
        isOpen: false,
        imageUrl: 'assets/background3.png',
      ),
    ];
    
    setState(() {
      _myConventions.addAll(mockConventions);
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Mes Conventions',
        showBackButton: true,
        showBurger: true,
        showNotificationIcon: true,
      ),
      drawer: DrawerFactory.of(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/organisateur/conventions/create');
        },
        backgroundColor: KipikTheme.rouge,
        child: Icon(Icons.add, color: Colors.white),
      ),
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
            child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: KipikTheme.rouge))
                : _myConventions.isEmpty 
                    ? _buildEmptyState()
                    : _buildConventionsList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[600],
          ),
          SizedBox(height: 16),
          Text(
            'Aucune convention trouvée',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Créez votre première convention en cliquant sur le bouton +',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/organisateur/conventions/create');
            },
            icon: Icon(Icons.add),
            label: Text('Créer une convention'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConventionsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _myConventions.length,
      itemBuilder: (context, index) {
        final convention = _myConventions[index];
        return _buildConventionCard(convention);
      },
    );
  }
  
  Widget _buildConventionCard(Convention convention) {
    final now = DateTime.now();
    final isUpcoming = convention.start.isAfter(now);
    final isOngoing = convention.start.isBefore(now) && convention.end.isAfter(now);
    final isPast = convention.end.isBefore(now);
    
    Color statusColor;
    String statusText;
    
    if (isUpcoming) {
      statusColor = Colors.blue;
      statusText = 'À venir';
    } else if (isOngoing) {
      statusColor = Colors.green;
      statusText = 'En cours';
    } else {
      statusColor = Colors.grey;
      statusText = 'Terminé';
    }
    
    final dateFormat = DateFormat('d MMM yyyy', 'fr_FR');
    final dateRange = '${dateFormat.format(convention.start)} - ${dateFormat.format(convention.end)}';
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context, 
            '/organisateur/conventions/edit',
            arguments: convention,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image et titre
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.asset(
                      convention.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (convention.isPremium)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: KipikTheme.rouge,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Informations
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    convention.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[400], size: 16),
                      SizedBox(width: 4),
                      Text(
                        convention.location,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[400], size: 16),
                      SizedBox(width: 4),
                      Text(
                        dateRange,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Statistiques
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('42', 'Inscrits'),
                      _buildStat('23', 'Emplacements'),
                      _buildStat('156', 'Tickets'),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context, 
                              '/organisateur/conventions/edit',
                              arguments: convention,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey[700]!),
                          ),
                          child: Text('Modifier'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Naviguer vers la gestion des inscriptions pour cette convention
                            Navigator.pushNamed(
                              context, 
                              '/organisateur/inscriptions',
                              arguments: convention.id,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KipikTheme.rouge,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Inscriptions'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
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