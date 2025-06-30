// lib/pages/admin/admin_setup_page.dart
import 'package:flutter/material.dart';
import 'package:kipik_v5/utils/auth_helper.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({Key? key}) : super(key: key);

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  final _emailController = TextEditingController(text: 'mano@kipik.ink');
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(text: 'Mano Admin');
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createAdminAccount() async {
    if (_emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      setState(() => _message = '❌ Veuillez remplir tous les champs');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Création du compte admin...';
    });

    try {
      final success = await AuthService.instance.createFirstAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );

      if (success) {
        setState(() => _message = '✅ Compte admin créé avec succès !');
        
        // Attendre 2 secondes puis rediriger vers la connexion
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/connexion');
        }
      } else {
        setState(() => _message = '❌ Erreur lors de la création du compte');
      }
    } catch (e) {
      setState(() => _message = '❌ Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTestAccounts() async {
    setState(() {
      _isLoading = true;
      _message = 'Création des comptes de test...';
    });

    try {
      await createTestAccounts();
      setState(() => _message = '✅ Comptes de test créés !');
    } catch (e) {
      setState(() => _message = '❌ Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuration Admin Kipik',
          style: TextStyle(fontFamily: 'PermanentMarker'),
        ),
        backgroundColor: KipikTheme.rouge,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Center(
              child: Image.asset('assets/logo_kipik.png', width: 150),
            ),
            const SizedBox(height: 32),
            
            // Titre
            const Text(
              '🔧 Configuration initiale',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'PermanentMarker',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              'Créez votre compte administrateur pour gérer Kipik',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Formulaire
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Compte administrateur principal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PermanentMarker',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nom
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        labelStyle: TextStyle(fontFamily: 'Roboto'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email admin',
                        labelStyle: TextStyle(fontFamily: 'Roboto'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Mot de passe
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe sécurisé',
                        labelStyle: TextStyle(fontFamily: 'Roboto'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        hintText: 'Min. 8 caractères',
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Bouton créer admin
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createAdminAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KipikTheme.rouge,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Créer le compte admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton comptes de test (optionnel)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Comptes de test (optionnel)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PermanentMarker',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créer des comptes pour tester l\'application',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createTestAccounts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Créer les comptes de test',
                        style: TextStyle(fontFamily: 'Roboto'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Message de statut
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message.startsWith('✅') 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _message.startsWith('✅') ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.startsWith('✅') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}