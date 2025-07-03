// lib/pages/admin/admin_setup_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/utils/auth_helper.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/services/auth/captcha_manager.dart';
import 'package:kipik_v5/widgets/auth/recaptcha_widget.dart';
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
  
  // Variables reCAPTCHA pour sécurité admin
  bool _captchaValidated = false;
  CaptchaResult? _captchaResult;

  @override
  void initState() {
    super.initState();
    _checkIfFirstAdminExists();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// ✅ VÉRIFICATION: S'assurer qu'on peut créer le premier admin
  Future<void> _checkIfFirstAdminExists() async {
    try {
      final exists = await SecureAuthService.instance.checkFirstAdminExists();
      if (exists) {
        setState(() => _message = '⚠️ Un administrateur principal existe déjà');
        // Rediriger vers la connexion après 2 secondes
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/connexion');
          }
        });
      }
    } catch (e) {
      // Si erreur, permettre la création (cas initial)
      setState(() => _message = '🔧 Configuration initiale disponible');
    }
  }

  Future<void> _createAdminAccount() async {
    // Validation des champs
    if (_emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      setState(() => _message = '❌ Veuillez remplir tous les champs');
      return;
    }

    // Validation mot de passe
    if (_passwordController.text.length < 8) {
      setState(() => _message = '❌ Le mot de passe doit contenir au moins 8 caractères');
      return;
    }

    // Validation reCAPTCHA
    if (!_captchaValidated || _captchaResult == null) {
      setState(() => _message = '❌ Vérification de sécurité requise pour créer un compte admin');
      return;
    }

    if (_captchaResult!.score < 0.8) {
      setState(() => _message = '❌ Score de sécurité insuffisant pour créer un compte admin (${(_captchaResult!.score * 100).round()}% < 80%)');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Création sécurisée du super admin...';
    });

    try {
      // ✅ CORRIGÉ: Utiliser createFirstSuperAdmin au lieu de createUserWithEmailAndPassword
      final success = await SecureAuthService.instance.createFirstSuperAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
        captchaResult: _captchaResult!,
      );

      if (success) {
        setState(() => _message = '✅ Super admin créé avec succès !\nScore sécurité: ${(_captchaResult!.score * 100).round()}%\nRedirection...');
        
        // Attendre 3 secondes puis rediriger vers la connexion
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/connexion', (route) => false);
        }
      } else {
        setState(() => _message = '❌ Erreur lors de la création du super admin');
      }
    } catch (e) {
      setState(() => _message = '❌ Erreur création super admin: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTestAccounts() async {
    // Validation reCAPTCHA aussi requis pour comptes de test
    if (!_captchaValidated || _captchaResult == null) {
      setState(() => _message = '❌ Vérification de sécurité requise');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Création sécurisée des comptes de test...';
    });

    try {
      // Utiliser la version sécurisée avec reCAPTCHA
      await createTestAccountsSecure(captchaResult: _captchaResult!);
      setState(() => _message = '✅ Comptes de test créés avec sécurité !\nclient@kipik.ink, tatoueur@kipik.ink, organisateur@kipik.ink\nMot de passe: Test123!');
    } catch (e) {
      setState(() => _message = '❌ Erreur comptes de test: $e');
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/welcome'),
        ),
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
              'Créez votre compte super administrateur pour gérer KIPIK',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Section sécurité reCAPTCHA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.amber[700], size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sécurité Super Administrateur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                            fontFamily: 'PermanentMarker',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score de sécurité minimum requis: 80%\nVous serez le seul à pouvoir créer d\'autres admins',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Widget reCAPTCHA obligatoire
                  ReCaptchaWidget(
                    action: 'admin_setup',
                    useInvisible: true,
                    onValidated: (result) {
                      setState(() {
                        _captchaValidated = result.isValid && result.score >= 0.8;
                        _captchaResult = result;
                      });
                      
                      if (result.isValid && result.score >= 0.8) {
                        setState(() => _message = '✅ Sécurité super admin validée - Score: ${(result.score * 100).round()}%');
                      } else if (result.isValid && result.score < 0.8) {
                        setState(() => _message = '⚠️ Score de sécurité insuffisant pour super admin: ${(result.score * 100).round()}% (requis: 80%)');
                      }
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Formulaire
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield, color: KipikTheme.rouge),
                        const SizedBox(width: 8),
                        const Text(
                          'Super Administrateur Principal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PermanentMarker',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Nom
                    TextField(
                      controller: _nameController,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        labelStyle: TextStyle(fontFamily: 'Roboto'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Votre nom complet',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email super admin',
                        labelStyle: TextStyle(fontFamily: 'Roboto'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                        hintText: 'votre@email.com',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Mot de passe
                    TextField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe très sécurisé',
                        labelStyle: TextStyle(fontFamily: 'Roboto'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        hintText: 'Min. 8 caractères, majuscules, chiffres, symboles',
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Bouton créer super admin
                    ElevatedButton(
                      onPressed: (_isLoading || !_captchaValidated) ? null : _createAdminAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _captchaValidated ? KipikTheme.rouge : Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: _captchaValidated ? 4 : 0,
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Création sécurisée...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _captchaValidated ? Icons.verified_user : Icons.lock,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _captchaValidated 
                                      ? 'Créer le Super Admin'
                                      : 'Sécurité requise',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ],
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
                    Row(
                      children: [
                        Icon(Icons.group_add, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Comptes de test (optionnel)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PermanentMarker',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créer des comptes pour tester l\'application',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Comptes créés:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'client@kipik.ink • tatoueur@kipik.ink • organisateur@kipik.ink',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Mot de passe: Test123!',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (_isLoading || !_captchaValidated) ? null : _createTestAccounts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _captchaValidated ? Colors.blue : Colors.grey[400],
                        foregroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _captchaValidated ? Icons.group_add : Icons.lock,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _captchaValidated 
                                ? 'Créer les comptes de test'
                                : 'Sécurité requise',
                            style: TextStyle(fontFamily: 'Roboto'),
                          ),
                        ],
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
                      : _message.startsWith('⚠️')
                          ? Colors.orange.withOpacity(0.1)
                          : _message.startsWith('🔧')
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _message.startsWith('✅') 
                        ? Colors.green 
                        : _message.startsWith('⚠️')
                            ? Colors.orange
                            : _message.startsWith('🔧')
                                ? Colors.blue
                                : Colors.red,
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.startsWith('✅') 
                        ? Colors.green 
                        : _message.startsWith('⚠️')
                            ? Colors.orange
                            : _message.startsWith('🔧')
                                ? Colors.blue
                                : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Informations de sécurité
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Informations importantes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontFamily: 'PermanentMarker',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Cette page ne sera accessible qu\'une seule fois\n'
                    '• Vous serez le SEUL super administrateur\n'
                    '• Vous pourrez promouvoir d\'autres admins depuis votre espace\n'
                    '• Score reCAPTCHA 80% minimum requis\n'
                    '• Conservez ces identifiants en sécurité absolue',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
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
}