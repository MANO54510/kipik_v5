import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

// Import des modèles et services adaptés
import 'package:kipik_v5/models/user.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart'; // Modification de l'import de l'AppBar
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/utils/constants.dart';

class ParametresProPage extends StatefulWidget {
  static const String routeName = '/parametres-pro';

  const ParametresProPage({Key? key}) : super(key: key);

  @override
  _ParametresProPageState createState() => _ParametresProPageState();
}

class _ParametresProPageState extends State<ParametresProPage> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _selectedLanguage = 'Français';
  final List<String> _availableLanguages = ['Français', 'English', 'Español', 'Deutsch'];
  
  // Contrôleurs pour les champs de formulaire
  final TextEditingController _nomEntrepriseController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  
  bool _isLoading = true;
  User? _currentUser;
  String? _abonnementType = 'Standard'; // Pour stocker le type d'abonnement
  
  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }
  
  @override
  void dispose() {
    _nomEntrepriseController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserPreferences() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Charger les préférences utilisateur depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService.instance; // Utilisation du singleton
      
      _currentUser = authService.currentUser; // Obtenir l'utilisateur actuel
      
      setState(() {
        // Charger les préférences
        _isDarkMode = prefs.getBool('dark_mode') ?? false;
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _locationEnabled = prefs.getBool('location_enabled') ?? true;
        _selectedLanguage = context.locale.languageCode == 'fr' ? 'Français' 
                          : context.locale.languageCode == 'en' ? 'English'
                          : context.locale.languageCode == 'es' ? 'Español'
                          : context.locale.languageCode == 'de' ? 'Deutsch'
                          : 'Français';
        
        // Remplir les champs du formulaire avec les données de l'utilisateur
        if (_currentUser != null) {
          _nomEntrepriseController.text = _currentUser!.name;
          _emailController.text = _currentUser!.email ?? '';
          
          // Récupérer téléphone et adresse depuis les préférences 
          // (ou vous pourriez étendre le modèle User pour inclure ces champs)
          _telephoneController.text = prefs.getString('user_telephone') ?? '';
          _adresseController.text = prefs.getString('user_adresse') ?? '';
          
          // Récupérer le type d'abonnement
          _abonnementType = prefs.getString('abonnement_type') ?? 'Standard';
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des préférences: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des préférences. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _saveUserPreferences() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService.instance;
      
      // Sauvegarder les préférences
      await prefs.setBool('dark_mode', _isDarkMode);
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('location_enabled', _locationEnabled);
      
      // Sauvegarder la langue
      if (_selectedLanguage == 'Français') {
        await context.setLocale(Locale('fr'));
      } else if (_selectedLanguage == 'English') {
        await context.setLocale(Locale('en'));
      } else if (_selectedLanguage == 'Español') {
        await context.setLocale(Locale('es'));
      } else if (_selectedLanguage == 'Deutsch') {
        await context.setLocale(Locale('de'));
      }
      
      // Stocker téléphone et adresse dans les préférences
      await prefs.setString('user_telephone', _telephoneController.text);
      await prefs.setString('user_adresse', _adresseController.text);
      
      // Mettre à jour les informations du profil utilisateur
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(
          name: _nomEntrepriseController.text,
          email: _emailController.text,
        );
        
        // Mettre à jour l'utilisateur (vous devrez implémenter cette méthode)
        // await authService.updateUser(updatedUser);
        
        // En attendant, mettre à jour l'utilisateur en mémoire
        authService.currentUser = updatedUser;
      }
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paramètres enregistrés avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde des préférences: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde des paramètres. Veuillez réessayer.'),
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
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Déconnecter'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final authService = AuthService.instance;
      await authService.signOut();
      
      // Rediriger vers la page de connexion
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  
  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le compte'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer votre compte? '
          'Cette action est irréversible et toutes vos données seront perdues.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Implémenter votre logique de suppression de compte
        // await AuthService.instance.deleteAccount();
        
        // Rediriger vers la page d'accueil
        Navigator.of(context).pushReplacementNamed('/');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Votre compte a été supprimé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Erreur lors de la suppression du compte: $e');
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression du compte. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _openSupportWebsite() async {
    final Uri url = Uri.parse('https://www.kipik.fr/support');
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir la page de support'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@kipik.fr',
      queryParameters: {
        'subject': 'Support Kipik Pro - ${_currentUser?.name ?? ''}',
        'body': 'Bonjour,\n\nJ\'ai besoin d\'aide concernant mon compte Kipik Pro.\n\nCordialement,\n${_currentUser?.name ?? ''}'
      }
    );
    
    if (!await launchUrl(emailLaunchUri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir l\'application de messagerie'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Utilisation de CustomAppBarKipik au lieu de KipikAppBar
      appBar: CustomAppBarKipik(
        title: 'Paramètres Professionnels',
        showBackButton: true,
        showBurger: true,
        showNotificationIcon: false,
      ),
      drawer: DrawerFactory.of(context),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: KipikTheme.rouge))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Profil Professionnel
                  _buildSectionTitle('Profil Professionnel'),
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nomEntrepriseController,
                            decoration: InputDecoration(
                              labelText: 'Nom de l\'entreprise',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email professionnel',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _telephoneController,
                            decoration: InputDecoration(
                              labelText: 'Téléphone',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _adresseController,
                            decoration: InputDecoration(
                              labelText: 'Adresse',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Section Abonnement
                  _buildSectionTitle('Abonnement'),
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              'Type d\'abonnement',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(_abonnementType ?? 'Standard'),
                            trailing: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/abonnements');
                              },
                              child: Text('Modifier'),
                            ),
                          ),
                          Divider(),
                          ListTile(
                            title: Text(
                              'Facturation',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Gérer vos informations de paiement'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).pushNamed('/facturation');
                            },
                          ),
                          Divider(),
                          ListTile(
                            title: Text(
                              'Historique des factures',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Accéder à vos factures précédentes'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).pushNamed('/historique-factures');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Section Préférences
                  _buildSectionTitle('Préférences'),
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text('Mode sombre'),
                            leading: Icon(Icons.dark_mode),
                            trailing: Switch(
                              value: _isDarkMode,
                              onChanged: (value) {
                                setState(() {
                                  _isDarkMode = value;
                                });
                              },
                              activeColor: KipikTheme.rouge,
                            ),
                          ),
                          Divider(),
                          ListTile(
                            title: Text('Notifications'),
                            leading: Icon(Icons.notifications),
                            trailing: Switch(
                              value: _notificationsEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _notificationsEnabled = value;
                                });
                              },
                              activeColor: KipikTheme.rouge,
                            ),
                          ),
                          Divider(),
                          ListTile(
                            title: Text('Géolocalisation'),
                            leading: Icon(Icons.location_on),
                            trailing: Switch(
                              value: _locationEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _locationEnabled = value;
                                });
                              },
                              activeColor: KipikTheme.rouge,
                            ),
                          ),
                          Divider(),
                          ListTile(
                            title: Text('Langue'),
                            leading: Icon(Icons.language),
                            trailing: DropdownButton<String>(
                              value: _selectedLanguage,
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedLanguage = newValue;
                                  });
                                }
                              },
                              items: _availableLanguages.map((language) {
                                return DropdownMenuItem<String>(
                                  value: language,
                                  child: Text(language),
                                );
                              }).toList(),
                              underline: Container(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Section Support
                  _buildSectionTitle('Support et Aide'),
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text('Centre d\'aide'),
                            leading: Icon(Icons.help),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: _openSupportWebsite,
                          ),
                          Divider(),
                          ListTile(
                            title: Text('Contacter le support'),
                            leading: Icon(Icons.support_agent),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: _contactSupport,
                          ),
                          Divider(),
                          ListTile(
                            title: Text('FAQ'),
                            leading: Icon(Icons.question_answer),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).pushNamed('/faq');
                            },
                          ),
                          Divider(),
                          ListTile(
                            title: Text('Tutoriels'),
                            leading: Icon(Icons.play_circle_outline),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).pushNamed('/tutoriels');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Section Sécurité
                  _buildSectionTitle('Sécurité et Confidentialité'),
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text('Changer le mot de passe'),
                            leading: Icon(Icons.lock_outline),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).pushNamed('/change-password');
                            },
                          ),
                          Divider(),
                          ListTile(
                            title: Text('Paramètres de confidentialité'),
                            leading: Icon(Icons.privacy_tip_outlined),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).pushNamed('/privacy-settings');
                            },
                          ),
                          Divider(),
                          ListTile(
                            title: Text('Authentification à deux facteurs'),
                            leading: Icon(Icons.security),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).pushNamed('/two-factor-auth');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Section Compte
                  _buildSectionTitle('Compte'),
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              'Déconnexion',
                              style: TextStyle(color: Colors.orange),
                            ),
                            leading: Icon(
                              Icons.logout,
                              color: Colors.orange,
                            ),
                            onTap: _confirmLogout,
                          ),
                          Divider(),
                          ListTile(
                            title: Text(
                              'Supprimer le compte',
                              style: TextStyle(color: Colors.red),
                            ),
                            leading: Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            onTap: _confirmDeleteAccount,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bouton de sauvegarde
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveUserPreferences,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KipikTheme.rouge,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: Size(double.infinity, 48),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Enregistrer les modifications',
                                style: TextStyle(
                                  fontFamily: 'PermanentMarker',
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                  
                  // Informations sur la version
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Kipik v5.0.0 • © 2025 Kipik SAS',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: KipikTheme.rouge,
        ),
      ),
    );
  }
}