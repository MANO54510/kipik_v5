// lib/pages/temp/first_setup_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/pages/admin/admin_setup_page.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class FirstSetupPage extends StatefulWidget {
  const FirstSetupPage({Key? key}) : super(key: key);

  @override
  State<FirstSetupPage> createState() => _FirstSetupPageState();
}

class _FirstSetupPageState extends State<FirstSetupPage> {
  bool _isLoading = true;
  bool _firstAdminExists = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _checkFirstAdmin();
  }

  Future<void> _checkFirstAdmin() async {
    try {
      final exists = await SecureAuthService.instance.checkFirstAdminExists();
      setState(() {
        _firstAdminExists = exists;
        _isLoading = false;
        _message = exists 
            ? '✅ Application déjà configurée'
            : '🔧 Configuration initiale requise';
      });
    } catch (e) {
      setState(() {
        _firstAdminExists = false;
        _isLoading = false;
        _message = '⚙️ Configuration initiale disponible';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              KipikTheme.rouge.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo KIPIK
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo_kipik.png',
                      width: 150,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Titre
                  Text(
                    'KIPIK V5',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: KipikTheme.rouge,
                      fontFamily: 'PermanentMarker',
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Plateforme de gestion tatouage',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Contenu selon l'état
                  if (_isLoading) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: KipikTheme.rouge),
                          const SizedBox(height: 16),
                          Text(
                            'Vérification de la configuration...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_firstAdminExists) ...[
                    // Admin déjà créé - Redirection vers connexion
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 64,
                            color: Colors.green[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Application configurée',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontFamily: 'PermanentMarker',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'L\'administrateur principal a déjà été créé.\nVous pouvez maintenant vous connecter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green[600],
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pushReplacementNamed('/connexion'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.login),
                            label: const Text(
                              'Aller à la connexion',
                              style: TextStyle(fontFamily: 'Roboto'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Premier setup requis
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 64,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Configuration initiale',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                              fontFamily: 'PermanentMarker',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créez votre compte super administrateur pour commencer à utiliser KIPIK.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.amber[600],
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Informations importantes
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Important',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• Cette configuration n\'est possible qu\'une seule fois\n'
                                  '• Vous serez le seul super administrateur\n'
                                  '• reCAPTCHA avec score 80% minimum requis\n'
                                  '• Conservez précieusement vos identifiants',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminSetupPage(),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KipikTheme.rouge,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.security),
                            label: const Text(
                              'Configurer le Super Admin',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Message de statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _message.startsWith('✅')
                          ? Colors.green.withOpacity(0.1)
                          : _message.startsWith('🔧')
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _message,
                      style: TextStyle(
                        color: _message.startsWith('✅')
                            ? Colors.green[700]
                            : _message.startsWith('🔧')
                                ? Colors.blue[700]
                                : Colors.orange[700],
                        fontSize: 12,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Liens de navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/welcome'),
                        icon: Icon(Icons.home, color: Colors.grey[600], size: 16),
                        label: Text(
                          'Accueil',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: 'Roboto',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      
                      if (_firstAdminExists) ...[
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/connexion'),
                          icon: Icon(Icons.login, color: KipikTheme.rouge, size: 16),
                          label: Text(
                            'Connexion',
                            style: TextStyle(
                              color: KipikTheme.rouge,
                              fontFamily: 'Roboto',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}