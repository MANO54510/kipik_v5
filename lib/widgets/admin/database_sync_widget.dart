// lib/widgets/admin/database_sync_widget.dart
import 'package:flutter/material.dart';
import '../../core/database_manager.dart';
import '../../utils/database_sync_manager.dart';

class DatabaseSyncWidget extends StatefulWidget {
  const DatabaseSyncWidget({Key? key}) : super(key: key);

  @override
  State<DatabaseSyncWidget> createState() => _DatabaseSyncWidgetState();
}

class _DatabaseSyncWidgetState extends State<DatabaseSyncWidget> {
  bool _isSyncing = false;
  Map<String, dynamic>? _syncStats;
  Map<String, dynamic>? _lastSyncResult;

  @override
  void initState() {
    super.initState();
    _loadSyncStats();
  }

  Future<void> _loadSyncStats() async {
    try {
      final stats = await DatabaseSyncManager.instance.getSyncStats();
      setState(() {
        _syncStats = stats;
      });
    } catch (e) {
      print('Erreur chargement stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(Icons.sync, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Synchronisation des bases',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Dupliquer Production → Démo/Test',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (_isSyncing)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Statistiques actuelles
            if (_syncStats != null) ...[
              Text(
                'État actuel:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(child: _buildStatsCard('Démo', _syncStats!['demo'])),
                  SizedBox(width: 12),
                  Expanded(child: _buildStatsCard('Test', _syncStats!['test'])),
                ],
              ),
              
              SizedBox(height: 20),
            ],
            
            // Actions rapides
            Text(
              'Actions:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : () => _syncAll(false),
                    icon: Icon(Icons.sync),
                    label: Text('Sync rapide'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : () => _syncAll(true),
                    icon: Icon(Icons.refresh),
                    label: Text('Sync complète'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
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
                    onPressed: _isSyncing ? null : _cleanDatabases,
                    icon: Icon(Icons.delete_sweep),
                    label: Text('Nettoyer démo/test'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadSyncStats,
                    icon: Icon(Icons.refresh),
                    label: Text('Actualiser'),
                  ),
                ),
              ],
            ),
            
            // Résultat de la dernière sync
            if (_lastSyncResult != null) ...[
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lastSyncResult!['success'] == true 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  border: Border.all(
                    color: _lastSyncResult!['success'] == true 
                        ? Colors.green 
                        : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dernière synchronisation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _lastSyncResult!['success'] == true 
                            ? _getColorShade(Colors.green, 700)  // ✅ CORRIGÉ
                            : _getColorShade(Colors.red, 700),   // ✅ CORRIGÉ
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _buildSyncResultText(),
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, Map<String, dynamic>? stats) {
    if (stats == null) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Chargement...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    final lastSync = stats['lastSync'] as String?;
    final hoursSince = stats['hoursSinceSync'] as int?;
    final collections = stats['collectionsCount'] as int? ?? 0;
    final documents = stats['documentsCount'] as int? ?? 0;

    String syncStatus;
    Color statusColor;
    
    if (lastSync == null) {
      syncStatus = 'Jamais synchronisé';
      statusColor = Colors.orange;
    } else if (hoursSince != null && hoursSince < 1) {
      syncStatus = 'À jour';
      statusColor = Colors.green;
    } else if (hoursSince != null && hoursSince < 24) {
      syncStatus = '${hoursSince}h';
      statusColor = Colors.blue;
    } else {
      syncStatus = 'Ancien';
      statusColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getColorShade(statusColor, 700), // ✅ CORRIGÉ
            ),
          ),
          SizedBox(height: 4),
          Text(
            syncStatus,
            style: TextStyle(
              fontSize: 12,
              color: _getColorShade(statusColor, 600), // ✅ CORRIGÉ
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$collections collections\n$documents documents',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _buildSyncResultText() {
    if (_lastSyncResult!['success'] == true) {
      final demo = _lastSyncResult!['demo'] as Map<String, dynamic>?;
      final test = _lastSyncResult!['test'] as Map<String, dynamic>?;
      final duration = _lastSyncResult!['duration'] as String? ?? '';
      
      return 'Synchronisation réussie en $duration\n'
             'Démo: ${demo?['collectionsSync'] ?? 0} collections, ${demo?['documentsSync'] ?? 0} docs\n'
             'Test: ${test?['collectionsSync'] ?? 0} collections, ${test?['documentsSync'] ?? 0} docs';
    } else {
      return 'Erreur: ${_lastSyncResult!['error'] ?? 'Inconnue'}';
    }
  }

  Future<void> _syncAll(bool forceSync) async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _lastSyncResult = null;
    });

    try {
      final result = await DatabaseSyncManager.instance.syncAllFromProduction(
        forceSync: forceSync,
      );

      setState(() {
        _lastSyncResult = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Synchronisation réussie !'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Recharger les stats
      await _loadSyncStats();

    } catch (e) {
      setState(() {
        _lastSyncResult = {
          'success': false,
          'error': e.toString(),
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erreur: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _cleanDatabases() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Nettoyer les bases'),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer toutes les données des bases démo et test ?\n\n'
          'Cette action est irréversible.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Nettoyer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      await DatabaseSyncManager.instance.cleanTargetDatabases();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bases démo/test nettoyées'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadSyncStats();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur nettoyage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  // ✅ Helper pour obtenir les nuances de couleur compatibles
  Color _getColorShade(Color color, int shade) {
    // Pour les couleurs MaterialColor, utiliser les shades
    if (color == Colors.red) return Colors.red[shade] ?? Colors.red;
    if (color == Colors.green) return Colors.green[shade] ?? Colors.green;
    if (color == Colors.blue) return Colors.blue[shade] ?? Colors.blue;
    if (color == Colors.orange) return Colors.orange[shade] ?? Colors.orange;
    if (color == Colors.grey) return Colors.grey[shade] ?? Colors.grey;
    
    // Pour les autres couleurs, retourner la couleur de base
    return color;
  }
}