// lib/pages/organisateur/organisateur_marketing_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class OrganisateurMarketingPage extends StatefulWidget {
  const OrganisateurMarketingPage({Key? key}) : super(key: key);

  @override
  _OrganisateurMarketingPageState createState() => _OrganisateurMarketingPageState();
}

class _OrganisateurMarketingPageState extends State<OrganisateurMarketingPage> {
  bool _isLoading = false;
  String _selectedConvention = 'Tattoo Expo Paris 2025';
  
  final List<String> _conventions = [
    'Tattoo Expo Paris 2025',
    'Ink Festival Lyon',
    'Tattoo Art Show Marseille',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Marketing',
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
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: KipikTheme.rouge))
                : SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sélecteur d'événement
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedConvention,
                            decoration: InputDecoration(
                              labelText: 'Sélectionner une convention',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[800],
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
                        
                        SizedBox(height: 24),
                        
                        // Statistiques de marketing
                        _buildSectionTitle('Statistiques de marketing'),
                        _buildStatsCard(),
                        
                        SizedBox(height: 24),
                        
                        // Outils de promotion
                        _buildSectionTitle('Outils de promotion'),
                        _buildMarketingTools(),
                        
                        SizedBox(height: 24),
                        
                        // Médias sociaux
                        _buildSectionTitle('Médias sociaux'),
                        _buildSocialMediaCard(),
                        
                        SizedBox(height: 24),
                        
                        // Marketing par email
                        _buildSectionTitle('Marketing par email'),
                        _buildEmailMarketingCard(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: KipikTheme.rouge,
          fontFamily: 'PermanentMarker',
        ),
      ),
    );
  }
  
  Widget _buildStatsCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Visiteurs du site', '1,254'),
                _buildStatItem('Partages sociaux', '876'),
                _buildStatItem('Emails envoyés', '540'),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Nouveaux inscrits', '68'),
                _buildStatItem('Taux de conversion', '5.4%'),
                _buildStatItem('Taux d\'ouverture', '32%'),
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
  
  Widget _buildMarketingTools() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMarketingTool(
            icon: Icons.link,
            title: 'Lien d\'invitation',
            description: 'Générer un lien d\'invitation pour promouvoir votre événement',
            onTap: () {},
          ),
          Divider(color: Colors.grey[800], height: 1),
          _buildMarketingTool(
            icon: Icons.discount,
            title: 'Codes promo',
            description: 'Créer et gérer des codes promotionnels pour les billets',
            onTap: () {},
          ),
          Divider(color: Colors.grey[800], height: 1),
          _buildMarketingTool(
            icon: Icons.qr_code,
            title: 'QR Code',
            description: 'Générer un QR code pour l\'événement',
            onTap: () {},
          ),
          Divider(color: Colors.grey[800], height: 1),
          _buildMarketingTool(
            icon: Icons.print,
            title: 'Matériel imprimable',
            description: 'Affiches, flyers et autres supports imprimables',
            onTap: () {},
          ),
        ],
      ),
    );
  }
  
  Widget _buildMarketingTool({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KipikTheme.rouge.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: KipikTheme.rouge),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSocialMediaCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSocialMediaButton(
              icon: Icons.facebook,
              title: 'Partager sur Facebook',
              color: Colors.blue,
              onTap: () {},
            ),
            SizedBox(height: 12),
            _buildSocialMediaButton(
              icon: Icons.camera_alt,
              title: 'Partager sur Instagram',
              color: Colors.purple,
              onTap: () {},
            ),
            SizedBox(height: 12),
            _buildSocialMediaButton(
              icon: Icons.send,
              title: 'Partager sur Twitter',
              color: Colors.lightBlue,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSocialMediaButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12),
        minimumSize: Size(double.infinity, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  Widget _buildEmailMarketingCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campagnes email',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            // Liste des campagnes
            _buildEmailCampaign(
              title: 'Annonce de l\'événement',
              date: '10/05/2025',
              status: 'Envoyé',
              stats: '245 envoyés, 78 ouverts',
            ),
            Divider(color: Colors.grey[800]),
            _buildEmailCampaign(
              title: 'Rappel inscription tatoueurs',
              date: '01/06/2025',
              status: 'Planifié',
              stats: '-',
            ),
            Divider(color: Colors.grey[800]),
            _buildEmailCampaign(
              title: 'Programme du week-end',
              date: '25/06/2025',
              status: 'Brouillon',
              stats: '-',
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add),
              label: Text('Nouvelle campagne'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                minimumSize: Size(double.infinity, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmailCampaign({
    required String title,
    required String date,
    required String status,
    required String stats,
  }) {
    Color statusColor;
    
    switch (status) {
      case 'Envoyé':
        statusColor = Colors.green;
        break;
      case 'Planifié':
        statusColor = Colors.orange;
        break;
      case 'Brouillon':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        stats,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            date,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      onTap: () {},
    );
  }
}