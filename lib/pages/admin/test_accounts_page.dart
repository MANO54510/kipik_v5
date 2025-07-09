// lib/pages/admin/test_accounts_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/utils/auth_helper.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/services/auth/captcha_manager.dart';
import '../particulier/accueil_particulier_page.dart';
import '../pro/home_page_pro.dart';
import '../organisateur/organisateur_dashboard_page.dart';
import 'admin_dashboard_home.dart';

class TestAccountsPage extends StatefulWidget {
  const TestAccountsPage({Key? key}) : super(key: key);

  @override
  State<TestAccountsPage> createState() => _TestAccountsPageState();
}

class _TestAccountsPageState extends State<TestAccountsPage> {
  bool _isCreating = false;
  bool _accountsExist = false;
  bool _isLoading = true;

  // Services sécurisés
  SecureAuthService get _authService => SecureAuthService.instance;
  CaptchaManager get _captchaManager => CaptchaManager.instance;

  final List<TestAccount> _testAccounts = [
    TestAccount(
      role: UserRole.particulier, // ✅ CORRIGÉ: Utilise particulier directement
      email: 'client@kipik.ink',
      password: 'Client123!',
      name: 'Client Test',
      description: 'Tester l\'espace client, réservations, portfolio',
      color: Colors.blue,
      icon: Icons.person,
    ),
    TestAccount(
      role: UserRole.tatoueur,
      email: 'tatoueur@kipik.ink',
      password: 'Tatoueur123!',
      name: 'Tatoueur Test',
      description: 'Tester l\'espace pro, portfolio, rendez-vous',
      color: Colors.purple,
      icon: Icons.brush,
    ),
    TestAccount(
      role: UserRole.organisateur,
      email: 'organisateur@kipik.ink',
      password: 'Orga123!',
      name: 'Organisateur Test',
      description: 'Tester gestion conventions, événements',
      color: Colors.orange,
      icon: Icons.event,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  // Initialisation sécurisée
  Future<void> _initializePage() async {
    // Vérifier les accès admin
    final userRole = _authService.currentUserRole;
    
    if (userRole != UserRole.admin) {
      // Rediriger si pas admin
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
      }
      return;
    }
    
    await _checkAccountsExistence();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkAccountsExistence() async {
    try {
      // Vérifier réellement l'existence des comptes
      bool allExist = true;
      
      for (final account in _testAccounts) {
        try {
          final user = await _authService.getUserById(account.email);
          if (user == null) {
            allExist = false;
            break;
          }
        } catch (e) {
          allExist = false;
          break;
        }
      }
      
      setState(() {
        _accountsExist = allExist;
      });
    } catch (e) {
      print('❌ Erreur vérification comptes: $e');
      setState(() {
        _accountsExist = false;
      });
    }
  }

  Future<void> _createAllTestAccounts() async {
    if (_isCreating) return;
    
    // SÉCURITÉ: Vérifier les privilèges super admin
    if (!_authService.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Action réservée aux super administrateurs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isCreating = true;
    });

    try {
      int created = 0;
      int errors = 0;
      
      for (final account in _testAccounts) {
        try {
          // Utiliser SecureAuthService au lieu d'auth_helper
          final user = await _authService.createUserWithEmailAndPassword(
            email: account.email,
            password: account.password,
            displayName: account.name,
            userRole: account.role.value, // ✅ CORRIGÉ: Utilise .value au lieu de .name
          );
          
          if (user != null) {
            created++;
            print('✅ Compte créé: ${account.email}');
          } else {
            errors++;
            print('❌ Échec création: ${account.email}');
          }
        } catch (e) {
          errors++;
          print('❌ Erreur création ${account.email}: $e');
        }
      }
      
      final message = created > 0 
          ? '✅ $created comptes créés avec succès${errors > 0 ? " ($errors erreurs)" : ""}'
          : '❌ Aucun compte créé ($errors erreurs)';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: created > 0 ? Colors.green : Colors.red,
        ),
      );
      
      await _checkAccountsExistence();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Future<void> _switchToAccount(TestAccount account) async {
    try {
      // Afficher un dialog de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Se connecter en tant que ${account.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voulez-vous vous connecter avec le compte ${account.email} ?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ceci va vous déconnecter de votre session admin actuelle',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: account.color,
                foregroundColor: Colors.white,
              ),
              child: const Text('Connexion'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Utiliser SecureAuthService
      await _authService.signOut();

      // Connexion avec le compte de test
      final success = await _authService.signInWithEmailAndPassword(
        account.email, 
        account.password,
      );
      
      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Connecté en tant que ${account.name}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Obtenir le rôle depuis SecureAuthService
        final role = _authService.currentUserRole;
        if (role != null) {
          _navigateToUserInterface(role);
        }
      } else {
        throw Exception('Échec de la connexion');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur connexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ CORRIGÉ: Switch exhaustif pour la navigation
  void _navigateToUserInterface(UserRole role) {
    Widget destination;
    
    switch (role) {
      case UserRole.client:
      case UserRole.particulier: // ✅ AJOUTÉ: Gestion du cas particulier
        destination = const AccueilParticulierPage();
        break;
      case UserRole.tatoueur:
        destination = const HomePagePro();
        break;
      case UserRole.organisateur:
        destination = const OrganisateurDashboardPage();
        break;
      case UserRole.admin:
        destination = const AdminDashboardHome();
        break;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _copyCredentials(TestAccount account) {
    final credentials = 'Email: ${account.email}\nMot de passe: ${account.password}';
    Clipboard.setData(ClipboardData(text: credentials));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Identifiants copiés dans le presse-papier'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Background aléatoire comme les autres pages
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final bg = backgrounds[DateTime.now().millisecond % backgrounds.length];

    return Scaffold(
      // extendBodyBehindAppBar pour background complet
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Comptes de Test',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(bg, fit: BoxFit.cover),
          
          // SafeArea pour éviter les débordements
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildCreateAccountsButton(),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildAccountsList(),
                        ),
                        // Padding bottom pour éviter overflow
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.science, color: Colors.indigo, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Gestion des Comptes de Test',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PermanentMarker',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Créez et gérez les comptes de test pour tester chaque interface utilisateur. '
              'Vous pouvez vous connecter rapidement à n\'importe quel type de compte.',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Roboto',
              ),
            ),
            
            // Indicateur de sécurité
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode développement - ${_authService.isSuperAdmin ? "Super Admin" : "Admin Standard"}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAccountsButton() {
    final canCreate = _authService.isSuperAdmin;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_isCreating || !canCreate) ? null : _createAllTestAccounts,
        icon: _isCreating 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.add_circle),
        label: Text(
          _isCreating 
              ? 'Création en cours...' 
              : !canCreate
                  ? 'Privilèges Super Admin requis'
                  : 'Créer tous les comptes de test',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canCreate ? Colors.green : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsList() {
    return ListView.builder(
      itemCount: _testAccounts.length,
      itemBuilder: (context, index) {
        final account = _testAccounts[index];
        return _buildAccountCard(account);
      },
    );
  }

  Widget _buildAccountCard(TestAccount account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: account.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(account.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PermanentMarker',
                        ),
                      ),
                      Text(
                        account.role.name.toUpperCase(),
                        style: TextStyle(
                          color: account.color,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Roboto',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_accountsExist)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✅ CRÉÉ',
                      style: TextStyle(
                        color: Colors.green, 
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              account.description,
              style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 16),
            
            // Meilleur affichage des identifiants
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          account.email, 
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.lock, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          account.password, 
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _switchToAccount(account),
                    icon: const Icon(Icons.login),
                    label: const Text('Se connecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: account.color,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontFamily: 'PermanentMarker',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: account.color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _copyCredentials(account),
                    icon: Icon(Icons.copy, color: account.color),
                    tooltip: 'Copier identifiants',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TestAccount {
  final UserRole role;
  final String email;
  final String password;
  final String name;
  final String description;
  final Color color;
  final IconData icon;

  TestAccount({
    required this.role,
    required this.email,
    required this.password,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
  });
}