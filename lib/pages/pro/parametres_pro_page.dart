import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

// Import des modèles et services adaptés
import 'package:kipik_v5/models/user.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
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
  String? _abonnementType = 'Standard';
  
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
      final secureAuth = context.read<SecureAuthService>();
      
      // Vérifier si l'utilisateur est connecté
      if (!secureAuth.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed(Constants.routeLogin);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      
      // Utilisation du modèle User
      final currentUserData = secureAuth.currentUser;
      if (currentUserData != null) {
        _currentUser = UserFromDynamic.fromDynamic(currentUserData);
      }
      
      setState(() {
        // Charger les préférences avec CONSTANTS
        _isDarkMode = prefs.getBool(Constants.prefsDarkMode) ?? false;
        _notificationsEnabled = prefs.getBool(kPrefNotificationsEnabled) ?? true;
        _locationEnabled = prefs.getBool(kPrefLocationEnabled) ?? true;
        
        _selectedLanguage = context.locale.languageCode == 'fr' ? 'Français' 
                          : context.locale.languageCode == 'en' ? 'English'
                          : context.locale.languageCode == 'es' ? 'Español'
                          : context.locale.languageCode == 'de' ? 'Deutsch'
                          : 'Français';
        
        // Utilisation du modèle User
        if (_currentUser != null) {
          _nomEntrepriseController.text = _currentUser!.name;
          _emailController.text = _currentUser!.email ?? '';
          
          // Récupérer téléphone et adresse depuis les préférences 
          _telephoneController.text = prefs.getString('user_telephone') ?? _currentUser!.phone ?? '';
          _adresseController.text = prefs.getString('user_adresse') ?? '';
          
          // Récupérer le type d'abonnement
          _abonnementType = prefs.getString('abonnement_type') ?? kSubscriptionTypes[0];
        }
        
        _isLoading = false;
      });
      
      print('✅ Préférences chargées pour: ${_currentUser?.displayName ?? 'Utilisateur'}');
      
    } catch (e) {
      print('❌ Erreur lors du chargement des préférences: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Constants.errorMessageGeneric),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _saveUserPreferences() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureAuth = context.read<SecureAuthService>();
      
      // Sauvegarder les préférences avec CONSTANTS
      await prefs.setBool(Constants.prefsDarkMode, _isDarkMode);
      await prefs.setBool(kPrefNotificationsEnabled, _notificationsEnabled);
      await prefs.setBool(kPrefLocationEnabled, _locationEnabled);
      
      // Sauvegarder la langue
      if (_selectedLanguage == 'Français') {
        await context.setLocale(const Locale('fr'));
        await prefs.setString(Constants.prefsLanguage, 'fr');
      } else if (_selectedLanguage == 'English') {
        await context.setLocale(const Locale('en'));
        await prefs.setString(Constants.prefsLanguage, 'en');
      } else if (_selectedLanguage == 'Español') {
        await context.setLocale(const Locale('es'));
        await prefs.setString(Constants.prefsLanguage, 'es');
      } else if (_selectedLanguage == 'Deutsch') {
        await context.setLocale(const Locale('de'));
        await prefs.setString(Constants.prefsLanguage, 'de');
      }
      
      // Stocker téléphone et adresse dans les préférences
      await prefs.setString('user_telephone', _telephoneController.text);
      await prefs.setString('user_adresse', _adresseController.text);
      await prefs.setString('abonnement_type', _abonnementType ?? kSubscriptionTypes[0]);
      
      // Mettre à jour les informations du profil utilisateur
      if (_currentUser != null) {
        try {
          await secureAuth.updateUserProfile(
            displayName: _nomEntrepriseController.text,
            additionalData: {
              'phone': _telephoneController.text,
              'address': _adresseController.text,
              'subscriptionType': _abonnementType,
            },
          );
          
          // Mettre à jour l'objet User local
          _currentUser = _currentUser!.copyWith(
            name: _nomEntrepriseController.text,
            phone: _telephoneController.text,
          );
          
          print('✅ Profil utilisateur mis à jour avec succès');
          
        } catch (updateError) {
          print('⚠️ Erreur mise à jour profil: $updateError');
        }
      }
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check, color: Colors.white),
                const SizedBox(width: 8),
                Text(kSaveSuccessMessage),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des préférences: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${kNetworkErrorMessage}: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _saveUserPreferences,
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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
        await context.read<SecureAuthService>().signOut();
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            Constants.routeLogin,
            (route) => false,
          );
        }
      } catch (e) {
        print('❌ Erreur lors de la déconnexion: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${kAuthErrorMessage}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte? '
          'Cette action est irréversible et toutes vos données seront perdues.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await context.read<SecureAuthService>().signOut();
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            Constants.routeHome,
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Déconnexion effectuée. Contactez le support pour supprimer définitivement votre compte.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        
      } catch (e) {
        print('❌ Erreur lors de la suppression du compte: $e');
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${kUnknownErrorMessage}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  void _openSupportWebsite() async {
    final Uri url = Uri.parse(Constants.urlSupport);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la page de support'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _contactSupport() async {
    final userName = _currentUser?.displayName ?? 'Utilisateur';
    
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@kipik.fr',
      queryParameters: {
        'subject': 'Support ${Constants.appName} Pro - $userName',
        'body': 'Bonjour,\n\nJ\'ai besoin d\'aide concernant mon compte ${Constants.appName} Pro.\n\nCordialement,\n$userName'
      }
    );
    
    if (!await launchUrl(emailLaunchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application de messagerie'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarKipik(
        title: 'Paramètres Professionnels',
        showBackButton: true,
        showBurger: true,
        showNotificationIcon: false,
      ),
      drawer: DrawerFactory.of(context),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: KipikTheme.rouge),
                  const SizedBox(height: 16),
                  Text(Constants.loadingMessage),
                ],
              ),
            )
          : Consumer<SecureAuthService>(
              builder: (context, authService, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section d'informations utilisateur
                      if (_currentUser != null) ...[
                        Card(
                          elevation: Constants.cardElevation,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: KipikTheme.rouge,
                                  backgroundImage: _currentUser!.profileImageUrl != null
                                      ? NetworkImage(_currentUser!.profileImageUrl!)
                                      : null,
                                  child: _currentUser!.profileImageUrl == null
                                      ? Text(
                                          _currentUser!.initials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentUser!.displayName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentUser!.email ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: KipikTheme.rouge.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(Constants.borderRadius),
                                        ),
                                        child: Text(
                                          _currentUser!.role.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: KipikTheme.rouge,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Badge super admin si applicable
                                if (_currentUser!.isSuperAdmin) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(Constants.borderRadius),
                                      border: Border.all(color: Colors.purple),
                                    ),
                                    child: const Text(
                                      '👑 SUPER',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.purple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      // Section Profil Professionnel
                      _buildSectionTitle('Profil Professionnel'),
                      Card(
                        elevation: Constants.cardElevation,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nomEntrepriseController,
                                decoration: const InputDecoration(
                                  labelText: 'Nom de l\'entreprise',
                                  prefixIcon: Icon(Icons.business),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email professionnel',
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                enabled: false, // Email non modifiable
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _telephoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Téléphone',
                                  prefixIcon: Icon(Icons.phone),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _adresseController,
                                decoration: const InputDecoration(
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
                        elevation: Constants.cardElevation,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: const Text(
                                  'Type d\'abonnement',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(_abonnementType ?? kSubscriptionTypes[0]),
                                trailing: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/abonnements');
                                  },
                                  child: const Text('Modifier'),
                                ),
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text(
                                  'Facturation',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: const Text('Gérer vos informations de paiement'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.of(context).pushNamed('/facturation');
                                },
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text(
                                  'Historique des factures',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: const Text('Accéder à vos factures précédentes'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                        elevation: Constants.cardElevation,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: const Text('Mode sombre'),
                                leading: const Icon(Icons.dark_mode),
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
                              const Divider(),
                              ListTile(
                                title: const Text('Notifications'),
                                leading: const Icon(Icons.notifications),
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
                              const Divider(),
                              ListTile(
                                title: const Text('Géolocalisation'),
                                leading: const Icon(Icons.location_on),
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
                              const Divider(),
                              ListTile(
                                title: const Text('Langue'),
                                leading: const Icon(Icons.language),
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
                      
                      // Section Admin (seulement pour les admins)
                      if (_currentUser?.isAdmin() == true) ...[
                        _buildSectionTitle('Administration'),
                        Card(
                          elevation: Constants.cardElevation,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: const Text('Panel Administrateur'),
                                  leading: const Icon(Icons.admin_panel_settings),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    Navigator.of(context).pushNamed('/admin/dashboard');
                                  },
                                ),
                                if (_currentUser?.isSuperAdmin == true) ...[
                                  const Divider(),
                                  ListTile(
                                    title: const Text('Gestion des Admins'),
                                    leading: const Icon(Icons.supervised_user_circle),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () {
                                      Navigator.of(context).pushNamed('/admin/manage-admins');
                                    },
                                  ),
                                  const Divider(),
                                  ListTile(
                                    title: const Text('Logs de Sécurité'),
                                    leading: const Icon(Icons.security),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () {
                                      Navigator.of(context).pushNamed('/admin/security-logs');
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      // Section Support
                      _buildSectionTitle('Support et Aide'),
                      Card(
                        elevation: Constants.cardElevation,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: const Text('Centre d\'aide'),
                                leading: const Icon(Icons.help),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: _openSupportWebsite,
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('Contacter le support'),
                                leading: const Icon(Icons.support_agent),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: _contactSupport,
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('FAQ'),
                                leading: const Icon(Icons.question_answer),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.of(context).pushNamed('/faq');
                                },
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('Tutoriels'),
                                leading: const Icon(Icons.play_circle_outline),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                        elevation: Constants.cardElevation,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: const Text('Changer le mot de passe'),
                                leading: const Icon(Icons.lock_outline),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.of(context).pushNamed('/change-password');
                                },
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('Paramètres de confidentialité'),
                                leading: const Icon(Icons.privacy_tip_outlined),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.of(context).pushNamed('/privacy-settings');
                                },
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('Authentification à deux facteurs'),
                                leading: const Icon(Icons.security),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                        elevation: Constants.cardElevation,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: const Text(
                                  'Déconnexion',
                                  style: TextStyle(color: Colors.orange),
                                ),
                                leading: const Icon(
                                  Icons.logout,
                                  color: Colors.orange,
                                ),
                                onTap: _confirmLogout,
                              ),
                              // Masquer suppression compte pour super admin
                              if (_currentUser?.isSuperAdmin != true) ...[
                                const Divider(),
                                ListTile(
                                  title: const Text(
                                    'Supprimer le compte',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  leading: const Icon(
                                    Icons.delete_forever,
                                    color: Colors.red,
                                  ),
                                  onTap: _confirmDeleteAccount,
                                ),
                              ],
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
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Constants.borderRadius),
                              ),
                              minimumSize: const Size(double.infinity, Constants.buttonHeight),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
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
                            '${Constants.appName} v${Constants.appVersion} • © 2025 Kipik SAS',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
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