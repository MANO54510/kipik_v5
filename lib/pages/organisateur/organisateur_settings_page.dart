// lib/pages/organisateur/organisateur_settings_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ MIGRATION
import 'package:kipik_v5/models/user_role.dart'; // ✅ MIGRATION
import 'package:shared_preferences/shared_preferences.dart';

class OrganisateurSettingsPage extends StatefulWidget {
  const OrganisateurSettingsPage({Key? key}) : super(key: key);

  @override
  _OrganisateurSettingsPageState createState() => _OrganisateurSettingsPageState();
}

class _OrganisateurSettingsPageState extends State<OrganisateurSettingsPage> {
  bool _isLoading = false;
  
  // ✅ MIGRATION: Service sécurisé centralisé
  SecureAuthService get _authService => SecureAuthService.instance;
  
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
    
    // ✅ Vérification d'authentification et de rôle
    if (!_authService.isAuthenticated || _authService.currentUserRole != UserRole.organisateur) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }
    
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
      // ✅ MIGRATION: Nouveau format utilisateur
      final currentUser = _authService.currentUser;
      final prefs = await SharedPreferences.getInstance();
      
      if (currentUser != null && mounted) {
        setState(() {
          // Charger les données utilisateur
          _nameController.text = currentUser['displayName'] ?? currentUser['name'] ?? '';
          _emailController.text = currentUser['email'] ?? '';
          _phoneController.text = prefs.getString('user_phone') ?? '';
          
          // Charger les préférences
          _isDarkMode = prefs.getBool('dark_mode') ?? true;
          _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
          _emailNotifications = prefs.getBool('email_notifications') ?? true;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement paramètres: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement des paramètres'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _saveSettings() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ Mettre à jour les préférences locales
      await prefs.setBool('dark_mode', _isDarkMode);
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setString('user_phone', _phoneController.text.trim());
      
      // ✅ MIGRATION: Nouveau format de mise à jour utilisateur
      await _authService.updateUserProfile(
        displayName: _nameController.text.trim(),
        additionalData: {
          'phone': _phoneController.text.trim(),
          'preferences': {
            'darkMode': _isDarkMode,
            'notificationsEnabled': _notificationsEnabled,
            'emailNotifications': _emailNotifications,
          },
          'lastSettingsUpdate': DateTime.now().toIso8601String(),
        },
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paramètres enregistrés avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur sauvegarde paramètres: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'enregistrement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Déconnexion',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        print('❌ Erreur déconnexion: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la déconnexion'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// ✅ NOUVEAU: Confirmation de suppression de compte
  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '⚠️ Supprimer le compte',
          style: TextStyle(color: Colors.red),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est irréversible et supprimera:',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text('• Toutes vos conventions organisées', style: TextStyle(color: Colors.white70)),
            Text('• Vos données de profil', style: TextStyle(color: Colors.white70)),
            Text('• Votre historique d\'activité', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 16),
            Text(
              'Êtes-vous absolument certain(e)?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // TODO: Implémenter la suppression de compte
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fonction de suppression de compte en cours de développement'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // ✅ Vérification d'authentification dans le build
    if (!_authService.isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ NOUVEAU: Info utilisateur connecté
                        _buildUserInfoCard(),
                        const SizedBox(height: 24),
                        
                        // Profil
                        _buildSectionTitle('Profil organisateur'),
                        _buildProfileCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Préférences de l'application
                        _buildSectionTitle('Préférences de l\'application'),
                        _buildPreferencesCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Notifications
                        _buildSectionTitle('Notifications'),
                        _buildNotificationsCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Sécurité
                        _buildSectionTitle('Sécurité et compte'),
                        _buildSecurityCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Bouton d'enregistrement
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KipikTheme.rouge,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Enregistrer les modifications',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Déconnexion
                        OutlinedButton.icon(
                          onPressed: _confirmLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Déconnexion'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
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

  /// ✅ NOUVEAU: Card d'information utilisateur connecté
  Widget _buildUserInfoCard() {
    final currentUser = _authService.currentUser;
    final userRole = _authService.currentUserRole;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connecté en tant qu\'organisateur',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  currentUser?['displayName'] ?? currentUser?['email'] ?? 'Organisateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rôle: ${userRole?.name ?? 'organisateur'}',
                  style: TextStyle(
                    color: Colors.green.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image de profil
            CircleAvatar(
              radius: 40,
              backgroundColor: KipikTheme.rouge,
              child: Text(
                _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'O',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Formulaire
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nom',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[800],
                helperText: 'L\'email ne peut pas être modifié',
                helperStyle: TextStyle(color: Colors.orange[300], fontSize: 11),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              enabled: false, // ✅ Email non modifiable pour sécurité
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implémenter changement photo de profil
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Changement de photo en cours de développement'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.photo_camera),
              label: const Text('Changer la photo de profil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.grey[700]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
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
            title: const Text(
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
            title: const Text(
              'Langue',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Français',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            onTap: () {
              // TODO: Ouvrir la sélection de langue
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sélection de langue en cours de développement'),
                  backgroundColor: Colors.orange,
                ),
              );
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
            title: const Text(
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
            title: const Text(
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
            title: const Text(
              'Changer le mot de passe',
              style: TextStyle(color: Colors.white),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            onTap: () {
              // TODO: Ouvrir la page de changement de mot de passe
              Navigator.pushNamed(context, '/change-password');
            },
          ),
          Divider(color: Colors.grey[800]),
          ListTile(
            title: const Text(
              'Données et confidentialité',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Gérer vos données personnelles',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            onTap: () {
              // TODO: Ouvrir la page de gestion des données
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gestion des données en cours de développement'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
          Divider(color: Colors.grey[800]),
          ListTile(
            title: const Text(
              'Supprimer mon compte',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: Text(
              'Action irréversible',
              style: TextStyle(color: Colors.red[300], fontSize: 12),
            ),
            trailing: const Icon(Icons.warning, size: 16, color: Colors.red),
            onTap: _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }
}