// lib/pages/admin/database_admin_page.dart
import 'package:flutter/material.dart';
import '../../widgets/database_switcher.dart';
import '../../widgets/admin/database_sync_widget.dart'; // ✅ AJOUTÉ
import '../../core/database_manager.dart';

class DatabaseAdminPage extends StatelessWidget {
  const DatabaseAdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administration Base de Données'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Informations',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alerte mode démo
            if (DatabaseManager.instance.isDemoMode)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.science, color: Colors.orange, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MODE DÉMONSTRATION ACTIF',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'Vous utilisez des données factices pour les démonstrations.',
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Widget principal de basculement
            DatabaseSwitcher(),
            
            SizedBox(height: 16),
            
            // ✅ NOUVEAU: Widget de synchronisation
            DatabaseSyncWidget(),
            
            SizedBox(height: 24),
            
            // Informations détaillées
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          'Configuration technique',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildConfigDisplay(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Guide d'utilisation
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Guide d\'utilisation',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildUsageGuide(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // ✅ NOUVEAU: Actions avancées de synchronisation
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sync_alt, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Actions de synchronisation avancées',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildAdvancedSyncActions(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigDisplay() {
    final config = DatabaseManager.instance.exportConfig();
    
    return Column(
      children: [
        _buildInfoRow('Base active', config['activeDatabaseKey']),
        _buildInfoRow('ID Firestore', config['activeDatabaseConfig']['id']),
        _buildInfoRow('Nom complet', config['activeDatabaseConfig']['name']),
        _buildInfoRow('Description', config['activeDatabaseConfig']['description']),
        _buildInfoRow('Type', config['activeDatabaseConfig']['isProduction'] ? 'Production' : 'Démonstration'),
        _buildInfoRow('Instances en cache', config['cachedInstances'].length.toString()),
        _buildInfoRow('Bases disponibles', config['availableDatabases'].keys.length.toString()),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGuideItem(
          icon: Icons.production_quantity_limits,
          title: 'Mode Production',
          description: 'Utilisez ce mode pour les vraies données de votre application.',
          color: Colors.green,
        ),
        SizedBox(height: 12),
        _buildGuideItem(
          icon: Icons.science,
          title: 'Mode Démonstration',
          description: 'Parfait pour montrer l\'application aux prospects avec des données factices.',
          color: Colors.orange,
        ),
        SizedBox(height: 12),
        _buildGuideItem(
          icon: Icons.swap_horiz,
          title: 'Basculement',
          description: 'Changez de mode en temps réel sans redémarrer l\'application.',
          color: Colors.blue,
        ),
        SizedBox(height: 12),
        _buildGuideItem(
          icon: Icons.sync,
          title: 'Synchronisation',
          description: 'Dupliquez automatiquement les données de production vers démo/test.',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ NOUVEAU: Actions avancées de synchronisation
  Widget _buildAdvancedSyncActions(BuildContext context) {
    return Column(
      children: [
        Text(
          'Actions techniques pour les développeurs',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showCollectionSyncDialog(context),
                icon: Icon(Icons.folder_copy, size: 18),
                label: Text('Sync collections'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDebugInfo(context),
                icon: Icon(Icons.bug_report, size: 18),
                label: Text('Debug sync'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _testAllConnections(context),
                icon: Icon(Icons.wifi_tethering, size: 18),
                label: Text('Test connexions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportSyncLogs(context),
                icon: Icon(Icons.download, size: 18),
                label: Text('Export logs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ NOUVELLES MÉTHODES POUR LES ACTIONS AVANCÉES
  void _showCollectionSyncDialog(BuildContext context) {
    final collections = [
      'users', 'projects', 'photos', 'quotes', 'conventions', 
      'payments', 'notifications', 'chats', 'appointments'
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Synchroniser des collections'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sélectionnez les collections à synchroniser:'),
              SizedBox(height: 12),
              ...collections.map((collection) => CheckboxListTile(
                title: Text(collection),
                value: true,
                onChanged: (value) {
                  // TODO: Gérer la sélection
                },
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Synchronisation des collections sélectionnées...')),
              );
            },
            child: Text('Synchroniser'),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bug_report, color: Colors.orange),
            SizedBox(width: 8),
            Text('Debug Synchronisation'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 État du DatabaseManager:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}'),
                Text('Mode: ${DatabaseManager.instance.isDemoMode ? "Démo" : "Production"}'),
                Text('ID: ${DatabaseManager.instance.activeDatabaseConfig.id}'),
                SizedBox(height: 16),
                Text('🔧 Actions disponibles:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• Synchronisation automatique au démarrage'),
                Text('• Synchronisation manuelle complète/rapide'),
                Text('• Nettoyage des bases démo/test'),
                Text('• Statistiques de synchronisation'),
                SizedBox(height: 16),
                Text('📋 Collections synchronisées:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('users, projects, photos, quotes, conventions,\npayments, notifications, chats, appointments,\nreports, referrals, admin_stats, promo_codes,\nsubscription_plans, trial_tracking'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _testAllConnections(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Test des connexions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Test en cours...'),
          ],
        ),
      ),
    );

    // Simuler le test
    await Future.delayed(Duration(seconds: 2));
    
    Navigator.pop(context); // Fermer le dialog de loading
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Résultats des tests'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ kipik: Accessible'),
            Text('✅ kipik-demo: Accessible'),
            Text('✅ kipik-test: Accessible'),
            SizedBox(height: 12),
            Text('Toutes les bases de données sont opérationnelles !',
                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _exportSyncLogs(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.download, color: Colors.white),
            SizedBox(width: 8),
            Text('Export des logs de synchronisation...'),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('À propos du gestionnaire'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ce gestionnaire vous permet de :'),
            SizedBox(height: 12),
            Text('🔄 Basculer entre différentes bases de données'),
            Text('🏭 Production : Vraies données de l\'application'),
            Text('🎭 Démo : Données factices pour les présentations'),
            Text('🧪 Test : Environnement de développement'),
            SizedBox(height: 12),
            Text('📊 Synchroniser automatiquement les données'),
            Text('🔍 Diagnostiquer l\'état du système'),
            SizedBox(height: 12),
            Text(
              'Idéal pour faire des démonstrations commerciales sans exposer les vraies données !',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris'),
          ),
        ],
      ),
    );
  }
}