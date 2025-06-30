// lib/pages/organisateur/organisateur_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';

class OrganisateurDashboardPage extends StatefulWidget {
  const OrganisateurDashboardPage({Key? key}) : super(key: key);

  @override
  _OrganisateurDashboardPageState createState() => _OrganisateurDashboardPageState();
}

class _OrganisateurDashboardPageState extends State<OrganisateurDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Tableau de bord',
        showBackButton: false,
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre de bienvenue
                  Text(
                    'Bienvenue dans votre espace organisateur',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Carte de statistiques
                  _buildStatsCard(),
                  SizedBox(height: 24),
                  
                  // Grille de fonctionnalités
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildFeatureCard(
                          'Mes conventions',
                          Icons.event,
                          () => Navigator.pushNamed(context, '/organisateur/conventions'),
                        ),
                        _buildFeatureCard(
                          'Créer une convention',
                          Icons.add_circle,
                          () => Navigator.pushNamed(context, '/organisateur/conventions/create'),
                        ),
                        _buildFeatureCard(
                          'Inscriptions',
                          Icons.how_to_reg,
                          () => Navigator.pushNamed(context, '/organisateur/inscriptions'),
                        ),
                        _buildFeatureCard(
                          'Billeterie',
                          Icons.confirmation_number,
                          () => Navigator.pushNamed(context, '/organisateur/billeterie'),
                        ),
                        _buildFeatureCard(
                          'Marketing',
                          Icons.trending_up,
                          () => Navigator.pushNamed(context, '/organisateur/marketing'),
                        ),
                        _buildFeatureCard(
                          'Paramètres',
                          Icons.settings,
                          () => Navigator.pushNamed(context, '/organisateur/settings'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Aperçu',
              style: TextStyle(
                color: KipikTheme.rouge,
                fontFamily: 'PermanentMarker',
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Conventions', '3'),
                _buildStatItem('Inscriptions', '42'),
                _buildStatItem('Tickets vendus', '156'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
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
  
  Widget _buildFeatureCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: KipikTheme.rouge,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}