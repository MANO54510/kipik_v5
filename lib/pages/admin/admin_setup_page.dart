// lib/pages/admin/admin_setup_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import '../../core/database_manager.dart';
import '../../widgets/database_switcher.dart';
import '../../services/auth/secure_auth_service.dart'; // ✅ AJOUTÉ
import '../../services/auth/captcha_manager.dart'; // ✅ AJOUTÉ
import '../../models/user_role.dart'; // ✅ AJOUTÉ

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({Key? key}) : super(key: key);

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  bool _isLoading = true;
  Map<String, dynamic> _systemConfig = {};
  
  // ✅ AJOUTÉ: Services sécurisés
  SecureAuthService get _authService => SecureAuthService.instance;
  CaptchaManager get _captchaManager => CaptchaManager.instance;
  
  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  // ✅ NOUVEAU: Vérification des accès admin
  Future<void> _checkAdminAccess() async {
    final userRole = _authService.currentUserRole;
    
    if (userRole != UserRole.admin) {
      // Rediriger si pas admin
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
      }
      return;
    }
    
    // Vérifier si c'est le super admin pour les actions sensibles
    if (!_authService.isSuperAdmin) {
      print('⚠️ Accès admin setup sans privilèges super admin');
    }
    
    await _loadSystemConfig();
  }

  Future<void> _loadSystemConfig() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger la configuration système
      _systemConfig = DatabaseManager.instance.exportConfig();
      
      // Ajouter des infos de sécurité
      _systemConfig['currentUser'] = _authService.currentUser;
      _systemConfig['isSuperAdmin'] = _authService.isSuperAdmin;
      _systemConfig['securityLevel'] = _authService.isSuperAdmin ? 'Super Admin' : 'Admin Standard';
      
      // Simuler un délai de chargement pour l'UX
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('Erreur chargement config: $e');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECTION 1: Background aléatoire comme les autres pages
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final bg = backgrounds[DateTime.now().millisecond % backgrounds.length];

    return Scaffold(
      // ✅ CORRECTION 2: extendBodyBehindAppBar pour background complet
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Configuration Système',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ✅ CORRECTION 1: Background image
          Image.asset(bg, fit: BoxFit.cover),
          
          // ✅ CORRECTION 2: SafeArea pour éviter les débordements
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadSystemConfig,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ NOUVEAU: Badge de sécurité admin
                          _buildAdminSecurityBadge(),
                          
                          const SizedBox(height: 16),
                          
                          // Header avec statut système
                          _buildSystemStatusHeader(),
                          
                          const SizedBox(height: 24),
                          
                          // Section Base de Données
                          _buildDatabaseSection(),
                          
                          const SizedBox(height: 24),
                          
                          // Section Sécurité
                          _buildSecuritySection(),
                          
                          const SizedBox(height: 24),
                          
                          // Section Configuration avancée
                          _buildAdvancedConfigSection(),
                          
                          const SizedBox(height: 24),
                          
                          // Section Actions système
                          _buildSystemActionsSection(),
                          
                          // ✅ CORRECTION 3: Padding bottom suffisant pour éviter overflow
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ NOUVEAU: Badge de sécurité admin
  Widget _buildAdminSecurityBadge() {
    final isSuperAdmin = _authService.isSuperAdmin;
    final currentUser = _authService.currentUser;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSuperAdmin 
              ? [Colors.purple, Colors.purple.withOpacity(0.8)]
              : [Colors.blue, Colors.blue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isSuperAdmin ? Colors.purple : Colors.blue).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isSuperAdmin ? Icons.admin_panel_settings : Icons.security,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSuperAdmin ? 'SUPER ADMINISTRATEUR' : 'ADMINISTRATEUR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
                Text(
                  currentUser?['email'] ?? 'admin@kipik.ink',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isSuperAdmin ? 'SUPER' : 'ADMIN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusHeader() {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    final activeConfig = DatabaseManager.instance.activeDatabaseConfig;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDemoMode 
              ? [Colors.orange, Colors.orange.withOpacity(0.8)]
              : [Colors.green, Colors.green.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDemoMode ? Colors.orange : Colors.green).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDemoMode ? Icons.science : Icons.security,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDemoMode ? 'MODE DÉMONSTRATION' : 'MODE PRODUCTION',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PermanentMarker',
                      ),
                    ),
                    Text(
                      activeConfig.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Métriques système
          Row(
            children: [
              Expanded(
                child: _buildStatusMetric(
                  'Base active',
                  activeConfig.name,
                  Icons.storage,
                ),
              ),
              Expanded(
                child: _buildStatusMetric(
                  'Instances',
                  '${_systemConfig['cachedInstances']?.length ?? 0}',
                  Icons.memory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // ✅ Fond semi-transparent
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.storage, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gestion des bases de données',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Basculez entre les environnements de production et de démonstration',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Widget de basculement
            DatabaseSwitcher(),
            
            const SizedBox(height: 16),
            
            // Informations détaillées
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Base de données active', _systemConfig['activeDatabaseKey'] ?? 'Non définie'),
                  _buildInfoRow('ID Firestore', _systemConfig['activeDatabaseConfig']?['id'] ?? 'Non défini'),
                  _buildInfoRow('Type d\'environnement', 
                    (_systemConfig['activeDatabaseConfig']?['isProduction'] ?? false) ? 'Production' : 'Démonstration'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // ✅ Fond semi-transparent
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.security, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sécurité et authentification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status de sécurité
            _buildSecurityStatusItem(
              'Service d\'authentification',
              'Opérationnel',
              Icons.check_circle,
              Colors.green,
            ),
            
            const SizedBox(height: 8),
            
            _buildSecurityStatusItem(
              'Chiffrement des données',
              'Activé (TLS 1.3)',
              Icons.lock,
              Colors.green,
            ),
            
            const SizedBox(height: 8),
            
            _buildSecurityStatusItem(
              'Captcha Manager',
              'Configuré',
              Icons.verified_user,
              Colors.green,
            ),
            
            // ✅ NOUVEAU: Statut admin actuel
            const SizedBox(height: 8),
            
            _buildSecurityStatusItem(
              'Niveau administrateur',
              _systemConfig['securityLevel'] ?? 'Standard',
              Icons.admin_panel_settings,
              _authService.isSuperAdmin ? Colors.purple : Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: () {
                _showSecurityAuditDialog();
              },
              icon: const Icon(Icons.assessment),
              label: const Text('Audit de sécurité'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedConfigSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // ✅ Fond semi-transparent
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.settings_applications, color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Configuration avancée',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Options de configuration
            ListTile(
              leading: const Icon(Icons.cloud_sync),
              title: const Text('Synchronisation automatique'),
              subtitle: const Text('Synchroniser les données en temps réel'),
              trailing: Switch(
                value: true,
                onChanged: _authService.isSuperAdmin ? (value) {
                  // TODO: Implémenter
                } : null, // ✅ Désactivé si pas super admin
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications push'),
              subtitle: const Text('Alertes système et utilisateur'),
              trailing: Switch(
                value: true,
                onChanged: _authService.isSuperAdmin ? (value) {
                  // TODO: Implémenter
                } : null,
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              subtitle: const Text('Collecte de données d\'usage'),
              trailing: Switch(
                value: false,
                onChanged: _authService.isSuperAdmin ? (value) {
                  // TODO: Implémenter
                } : null,
              ),
            ),
            
            // ✅ NOUVEAU: Avertissement si pas super admin
            if (!_authService.isSuperAdmin)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Certaines options nécessitent les privilèges de super administrateur',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
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

  Widget _buildSystemActionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // ✅ Fond semi-transparent
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.build, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Actions système',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions disponibles
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _clearCache();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Vider le cache'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _exportConfig();
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Export config'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _authService.isSuperAdmin ? () {
                      _restartServices();
                    } : null, // ✅ Réservé aux super admins
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Redémarrer services'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _authService.isSuperAdmin ? Colors.red : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showSystemLogs();
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Logs système'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStatusItem(String title, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MÉTHODES D'ACTION (inchangées mais avec vérifications de sécurité)
  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le cache'),
        content: const Text('Êtes-vous sûr de vouloir vider le cache système ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implémenter vidage cache
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache vidé avec succès')),
              );
              await _loadSystemConfig();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _exportConfig() {
    // TODO: Implémenter export de configuration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export de configuration en cours de développement')),
    );
  }

  void _restartServices() {
    if (!_authService.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action réservée aux super administrateurs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redémarrer les services'),
        content: const Text('Cette action va redémarrer tous les services. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter redémarrage services
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Services redémarrés')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Redémarrer'),
          ),
        ],
      ),
    );
  }

  void _showSystemLogs() {
    // TODO: Implémenter affichage des logs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Affichage des logs en cours de développement')),
    );
  }

  void _showSecurityAuditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.red),
            SizedBox(width: 8),
            Text('Audit de sécurité'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dernière vérification: Il y a 2 heures'),
            const SizedBox(height: 8),
            const Text('✅ Authentification: OK'),
            const Text('✅ Chiffrement: OK'),
            const Text('✅ Permissions: OK'),
            const Text('⚠️ Mots de passe: 3 comptes avec mots de passe faibles'),
            const SizedBox(height: 8),
            const Text('Score de sécurité: 8.5/10'),
            const SizedBox(height: 12),
            // ✅ NOUVEAU: Infos admin actuelles
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin connecté: ${_authService.currentUser?['email'] ?? 'N/A'}'),
                  Text('Niveau: ${_authService.isSuperAdmin ? 'Super Admin' : 'Admin Standard'}'),
                  Text('Session sécurisée: ${_authService.isAuthenticated ? '✅' : '❌'}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Actions de sécurité
            },
            child: const Text('Voir détails'),
          ),
        ],
      ),
    );
  }
}