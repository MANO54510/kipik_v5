// lib/pages/organisateur/organisateur_settings_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrganisateurSettingsPage extends StatefulWidget {
  const OrganisateurSettingsPage({Key? key}) : super(key: key);

  @override
  _OrganisateurSettingsPageState createState() => _OrganisateurSettingsPageState();
}

class _OrganisateurSettingsPageState extends State<OrganisateurSettingsPage> {
  bool _isLoading = false;
  
  // Formulaires
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Préférences
  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = AuthService.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        // Charger les données utilisateur
        _nameController.text = user.name;
        _emailController.text = user.email ?? '';
        _phoneController.text = prefs.getString('user_phone') ?? '';
        
        // Charger les préférences
        _isDarkMode = prefs.getBool('dark_mode') ?? true;
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des paramètres'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = AuthService.instance.currentUser;
      
      // Mettre à jour les préférences
      await prefs.setBool('dark_mode', _isDarkMode);
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setString('user_phone', _phoneController.text);
      
      // Mettre à jour les données utilisateur
      final updatedUser = user.copyWith(
        name: _nameController.text,
        email: _emailController.text,
      );
      
      // TODO: Mettre à jour l'utilisateur dans la base de données
      
      // Mettre à jour l'utilisateur en mémoire
      AuthService.instance.currentUser = updatedUser;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paramètres enregistrés avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement des paramètres'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion'),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Déconnecter'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await AuthService.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Paramètres',
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
                        // Profil
                        _buildSectionTitle('Profil organisateur'),
                        _buildProfileCard(),
                        
                        SizedBox(height: 24),
                        
                        // Préférences de l'application
                        _buildSectionTitle('Préférences de l\'application'),
                        _buildPreferencesCard(),
                        
                        SizedBox(height: 24),
                        
                        // Notifications
                        _buildSectionTitle('Notifications'),
                        _buildNotificationsCard(),
                        
                        SizedBox(height: 24),
                        
                        // Sécurité
                        _buildSectionTitle('Sécurité et compte'),
                        _buildSecurityCard(),
                        
                        SizedBox(height: 24),
                        
                        // Bouton d'enregistrement
                        ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KipikTheme.rouge,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            minimumSize: Size(double.infinity, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Enregistrer les modifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Déconnexion
                        OutlinedButton.icon(
                          onPressed: _confirmLogout,
                          icon: Icon(Icons.logout),
                          label: Text('Déconnexion'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            minimumSize: Size(double.infinity, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Version de l'application
                        Center(
                          child: Text(
                            'Kipik v5.0.0 • © 2025 Kipik SAS',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
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
  
  Widget _buildProfileCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Image de profil
            CircleAvatar(
              radius: 40,
              backgroundColor: KipikTheme.rouge,
              child: Text(
                _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'O',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Formulaire
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nom',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.photo_camera),
              label: Text('Changer la photo de profil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.grey[700]!),
                padding: EdgeInsets.symmetric(vertical: 12),
                minimumSize: Size(double.infinity, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreferencesCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Mode sombre',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Utiliser l\'interface sombre',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
            },
            activeColor: KipikTheme.rouge,
          ),
          Divider(color: Colors.grey[800]),
          ListTile(
            title: Text(
              'Langue',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Français',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            onTap: () {
              // Ouvrir la sélection de langue
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationsCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Notifications push',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Recevoir des notifications sur l\'application',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: KipikTheme.rouge,
          ),
          Divider(color: Colors.grey[800]),
          SwitchListTile(
            title: Text(
              'Notifications par email',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Recevoir des notifications par email',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
            activeColor: KipikTheme.rouge,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecurityCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Changer le mot de passe',
              style: TextStyle(color: Colors.white),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            onTap: () {
              // Ouvrir la page de changement de mot de passe
              Navigator.pushNamed(context, '/change-password');
            },
          ),
          Divider(color: Colors.grey[800]),
          ListTile(
            title: Text(
              'Supprimer mon compte',
              style: TextStyle(color: Colors.red),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
            onTap: () {
              // Ouvrir la confirmation de suppression de compte
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Supprimer le compte'),
                  content: Text(
                    'Êtes-vous sûr de vouloir supprimer votre compte? Cette action est irréversible et toutes vos données seront perdues.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Supprimer le compte
                        Navigator.pop(context);
                      },
                      child: Text('Supprimer'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}