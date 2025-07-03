// lib/pages/admin/admin_test_recaptcha_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/services/auth/captcha_manager.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/widgets/auth/recaptcha_widget.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/models/user_role.dart';

class AdminTestRecaptchaPage extends StatefulWidget {
  @override
  _AdminTestRecaptchaPageState createState() => _AdminTestRecaptchaPageState();
}

class _AdminTestRecaptchaPageState extends State<AdminTestRecaptchaPage> {
  final _emailController = TextEditingController(text: 'admin@kipik.ink');
  final _passwordController = TextEditingController(text: 'Test123!');
  bool _isLoading = false;
  CaptchaResult? _lastCaptchaResult;
  List<String> _logs = [];

  // ✅ CORRECTION: Services sécurisés
  SecureAuthService get _authService => SecureAuthService.instance;
  CaptchaManager get _captchaManager => CaptchaManager.instance;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    // ✅ CORRECTION: Vérification admin avec SecureAuthService
    final currentRole = _authService.currentUserRole;
    final isAuthenticated = _authService.isAuthenticated;
    
    if (!isAuthenticated || currentRole != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/admin');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accès réservé aux administrateurs'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'Admin - Test reCAPTCHA',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amber[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avertissement admin
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[700]?.withOpacity(0.2),
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panneau Administrateur',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Page de test et debug reCAPTCHA - Accès restreint',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info configuration
            _buildConfigCard(),
            
            const SizedBox(height: 20),
            
            // Section test connexion
            _buildLoginTestSection(),
            
            const SizedBox(height: 20),
            
            // Section admin actions
            _buildAdminActionsSection(),
            
            const SizedBox(height: 20),
            
            // Logs
            _buildLogsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Configuration reCAPTCHA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // ✅ CORRECTION: Utiliser les propriétés existantes
            _buildInfoRow('Site Key', CaptchaManager.siteKey.isNotEmpty 
                ? "✅ Configuré (${CaptchaManager.siteKey.substring(0, 20)}...)" 
                : "❌ Manquant"),
            _buildInfoRow('Score minimum général', '${CaptchaManager.captchaMinScore}'),
            _buildInfoRow('Score paiement', '${CaptchaManager.paymentMinScore}'),
            _buildInfoRow('Score inscription', '${CaptchaManager.signupMinScore}'),
            _buildInfoRow('Score réservation', '${CaptchaManager.bookingMinScore}'),
            _buildInfoRow('Max tentatives', '${CaptchaManager.maxLoginAttempts}'),
            _buildInfoRow('Durée blocage', '${CaptchaManager.lockoutDuration} min'),
            
            Divider(color: Colors.grey[700]),
            
            // ✅ CORRECTION: Stats globales avec méthode existante
            FutureBuilder<SecurityStats>(
              future: Future.value(_captchaManager.getSecurityStats()),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final stats = snapshot.data!;
                  return Column(
                    children: [
                      _buildInfoRow('Tentatives échouées totales', '${stats.totalFailedAttempts}'),
                      _buildInfoRow('Appareils bloqués', '${stats.lockedDevices}'),
                      _buildInfoRow('Appareils uniques', '${stats.uniqueDevices}'),
                    ],
                  );
                }
                return const Text('Chargement stats...', style: TextStyle(color: Colors.grey));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLoginTestSection() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.login, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Test Connexion Sécurisée',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Champs de test
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email de test',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mot de passe de test',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // ✅ CORRECTION: Widget reCAPTCHA conditionnel
            if (_shouldShowCaptcha()) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'reCAPTCHA Admin Test',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ReCaptchaWidget(
                      action: 'admin_login_test',
                      useInvisible: true,
                      onValidated: (result) {
                        setState(() {
                          _lastCaptchaResult = result;
                        });
                        _addLog('Admin reCAPTCHA validé - Score: ${(result.score * 100).round()}%');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bouton test connexion
            ElevatedButton(
              onPressed: _isLoading ? null : _testSecureLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Test en cours...'),
                      ],
                    )
                  : const Text('Tester Connexion Sécurisée'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionsSection() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Actions Administrateur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Boutons admin
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _testCaptchaAction('payment'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Test Paiement'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _testCaptchaAction('signup'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Test Inscription'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _simulateFailedAttempt,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Simuler Échec'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showDetailedStats,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    child: const Text('Stats Détaillées'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _debugCaptchaManager,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                    child: const Text('🔍 Debug Info'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _adminResetAllAttempts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('🗑️ Reset Global'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsSection() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.terminal, color: Colors.cyan),
                    SizedBox(width: 8),
                    Text(
                      'Logs Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => setState(() => _logs.clear()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _logs.isEmpty
                      ? [const Text('Aucun log admin', style: TextStyle(color: Colors.grey))]
                      : _logs.map((log) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            '[ADMIN] $log',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber[200],
                              fontFamily: 'monospace',
                            ),
                          ),
                        )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
      // Garder seulement les 50 derniers logs
      if (_logs.length > 50) {
        _logs.removeAt(0);
      }
    });
  }

  /// ✅ CORRECTION: Vérifier si CAPTCHA nécessaire
  bool _shouldShowCaptcha() {
    return _captchaManager.shouldShowCaptcha(
      'login',
      identifier: _emailController.text.trim(),
    );
  }

  Future<void> _testSecureLogin() async {
    setState(() => _isLoading = true);
    _addLog('ADMIN: Test connexion sécurisée...');

    try {
      // ✅ CORRECTION: Utiliser SecureAuthService directement
      final user = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        captchaResult: _lastCaptchaResult,
      );

      if (user != null) {
        final role = _authService.currentUserRole;
        _addLog('✅ ADMIN: Connexion réussie - Rôle: ${role?.name ?? 'unknown'}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion admin réussie !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _addLog('❌ ADMIN: Connexion échouée');
      }

    } catch (e) {
      _addLog('❌ ADMIN: Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur admin: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testCaptchaAction(String action) async {
    _addLog('ADMIN: Test reCAPTCHA pour action: $action');
    
    try {
      // ✅ CORRECTION: Utiliser CaptchaManager directement
      final result = await _captchaManager.validateInvisibleCaptcha(action);
      _addLog('ADMIN: Action $action - Score: ${(result.score * 100).round()}% - Valide: ${result.isValid}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin test $action - Score: ${(result.score * 100).round()}%'),
            backgroundColor: result.isValid ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ ADMIN: Erreur test $action: $e');
    }
  }

  void _simulateFailedAttempt() {
    // ✅ CORRECTION: Utiliser CaptchaManager
    _captchaManager.recordFailedAttempt('login', identifier: _emailController.text.trim());
    _addLog('ADMIN: Tentative échouée simulée');
    
    final lockout = _captchaManager.getRemainingLockout(identifier: _emailController.text.trim());
    if (lockout != null) {
      _addLog('⚠️ ADMIN: Compte bloqué pour ${lockout.inMinutes} minutes');
    }
    
    setState(() {}); // Refresh pour mettre à jour les stats
  }

  void _showDetailedStats() {
    final stats = _captchaManager.getSecurityStats();
    _addLog('ADMIN: Stats - Tentatives: ${stats.totalFailedAttempts}, Bloqués: ${stats.lockedDevices}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.amber),
            SizedBox(width: 8),
            Text('Statistiques Admin', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔢 Tentatives échouées: ${stats.totalFailedAttempts}', style: const TextStyle(color: Colors.white)),
            Text('🔒 Appareils bloqués: ${stats.lockedDevices}', style: const TextStyle(color: Colors.white)),
            Text('📱 Appareils uniques: ${stats.uniqueDevices}', style: const TextStyle(color: Colors.white)),
            Divider(color: Colors.grey[700]),
            Text('⚙️ Score minimum: ${CaptchaManager.captchaMinScore}', style: TextStyle(color: Colors.grey[400])),
            Text('💰 Score paiement: ${CaptchaManager.paymentMinScore}', style: TextStyle(color: Colors.grey[400])),
            Text('📝 Score inscription: ${CaptchaManager.signupMinScore}', style: TextStyle(color: Colors.grey[400])),
            Text('⏱️ Durée blocage: ${CaptchaManager.lockoutDuration} min', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  /// ✅ NOUVEAU: Debug du CaptchaManager
  void _debugCaptchaManager() {
    _addLog('ADMIN: Début debug CaptchaManager...');
    
    // Utiliser la méthode de debug du service
    _captchaManager.debugPrintState();
    
    _addLog('ADMIN: Debug terminé - Voir console pour détails');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug info affiché dans la console'),
          backgroundColor: Colors.cyan,
        ),
      );
    }
  }

  void _adminResetAllAttempts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmation Admin', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment réinitialiser TOUTES les tentatives de sécurité ?\n\nCette action est irréversible.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // ✅ CORRECTION: Utiliser CaptchaManager
              _captchaManager.resetAllAttempts();
              _addLog('🔄 ADMIN: Reset global effectué');
              setState(() {}); // Refresh stats
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset global admin effectué'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
            child: const Text('Confirmer Reset'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}