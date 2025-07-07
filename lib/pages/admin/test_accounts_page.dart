// lib/pages/admin/test_accounts_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kipik_v5/utils/auth_helper.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';

class TestAccountsPage extends StatefulWidget {
  const TestAccountsPage({Key? key}) : super(key: key);

  @override
  State<TestAccountsPage> createState() => _TestAccountsPageState();
}

class _TestAccountsPageState extends State<TestAccountsPage> {
  bool _isCreating = false;
  bool _accountsExist = false;

  final List<TestAccount> _testAccounts = [
    TestAccount(
      role: UserRole.client,
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
    _checkAccountsExistence();
  }

  Future<void> _checkAccountsExistence() async {
    // Vérifier si les comptes existent déjà
    // Cette logique dépend de votre implémentation
    setState(() {
      _accountsExist = true; // À implémenter selon vos besoins
    });
  }

  Future<void> _createAllTestAccounts() async {
    if (_isCreating) return;
    
    setState(() {
      _isCreating = true;
    });

    try {
      await createTestAccounts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Comptes de test créés avec succès !'),
          backgroundColor: Colors.green,
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
          content: Text('Voulez-vous vous connecter avec le compte ${account.email} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Connexion'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Déconnexion actuelle
      await signOut();

      // Connexion avec le compte de test
      final role = await checkUserCredentials(account.email, account.password);
      
      if (role != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Connecté en tant que ${account.name}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirection vers l'interface appropriée
        _navigateToUserInterface(role);
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

  void _navigateToUserInterface(UserRole role) {
    // Redirection selon le rôle
    switch (role) {
      case UserRole.client:
        Navigator.pushReplacementNamed(context, '/client-home');
        break;
      case UserRole.tatoueur:
        Navigator.pushReplacementNamed(context, '/tatoueur-home');
        break;
      case UserRole.organisateur:
        Navigator.pushReplacementNamed(context, '/organisateur-home');
        break;
      case UserRole.admin:
        Navigator.pushReplacementNamed(context, '/admin-home');
        break;
    }
  }

  void _copyCredentials(TestAccount account) {
    final credentials = 'Email: ${account.email}\nMot de passe: ${account.password}';
    Clipboard.setData(ClipboardData(text: credentials));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Identifiants copiés dans le presse-papier'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comptes de Test'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _checkAccountsExistence,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Padding(
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.indigo, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Gestion des Comptes de Test',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez et gérez les comptes de test pour tester chaque interface utilisateur. '
              'Vous pouvez vous connecter rapidement à n\'importe quel type de compte.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAccountsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isCreating ? null : _createAllTestAccounts,
        icon: _isCreating 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_circle),
        label: Text(_isCreating ? 'Création en cours...' : 'Créer tous les comptes de test'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: account.color,
                  child: Icon(account.icon, color: Colors.white),
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
                        ),
                      ),
                      Text(
                        account.role.name,
                        style: TextStyle(
                          color: account.color,
                          fontWeight: FontWeight.w500,
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
                      'Créé',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              account.description,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📧 ${account.email}', style: const TextStyle(fontSize: 12)),
                      Text('🔐 ${account.password}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
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
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _copyCredentials(account),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copier identifiants',
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