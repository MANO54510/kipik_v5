// lib/widgets/database_switcher.dart
import 'package:flutter/material.dart';
import '../core/database_manager.dart';

class DatabaseSwitcher extends StatefulWidget {
  const DatabaseSwitcher({Key? key}) : super(key: key);

  @override
  State<DatabaseSwitcher> createState() => _DatabaseSwitcherState();
}

class _DatabaseSwitcherState extends State<DatabaseSwitcher> {
  final DatabaseManager _dbManager = DatabaseManager.instance;
  bool _isCreatingDemo = false;

  @override
  Widget build(BuildContext context) {
    final info = _dbManager.getDatabaseInfo();
    final databases = _dbManager.getAvailableDatabases();

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
                Icon(Icons.storage, color: Colors.indigo, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestionnaire de base de données',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Basculez entre production et démo',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Indicateur mode démo
                if (info['isProduction'] == false)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('MODE DÉMO', style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        )),
                      ],
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Base active
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: info['isProduction'] == true 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                border: Border.all(
                  color: info['isProduction'] == true ? Colors.green : Colors.orange
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        info['isProduction'] == true ? Icons.production_quantity_limits : Icons.science,
                        color: info['isProduction'] == true ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Base active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: info['isProduction'] == true ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    info['activeName'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${info['activeId']} - ${info['description']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Actions rapides
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCreatingDemo ? null : _createDemoDatabase,
                    icon: _isCreatingDemo 
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.science),
                    label: Text(_isCreatingDemo ? 'Création...' : 'Créer base démo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: info['isProduction'] == true ? null : () => _switchDatabase('kipik'),
                    icon: Icon(Icons.production_quantity_limits),
                    label: Text('Mode Production'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: info['isProduction'] == true ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Liste des bases disponibles
            Text(
              'Bases de données disponibles:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            
            ...databases.map((config) {
              final isActive = config.id == info['activeId'];
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive 
                        ? (config.isProduction ? Colors.green : Colors.orange)
                        : Colors.grey[300],
                    child: Icon(
                      config.isProduction ? Icons.production_quantity_limits : Icons.science,
                      color: isActive ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    config.name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('${config.id} • ${config.description}'),
                  trailing: isActive 
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  onTap: isActive ? null : () => _switchDatabase(config.id),
                  tileColor: isActive 
                      ? (config.isProduction ? Colors.green : Colors.orange).withOpacity(0.1)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isActive 
                          ? (config.isProduction ? Colors.green : Colors.orange)
                          : Colors.transparent,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _switchDatabase(String newDatabaseId) async {
    try {
      final databases = _dbManager.getAvailableDatabases();
      final config = databases.firstWhere((c) => c.id == newDatabaseId);
      
      // Confirmation pour basculer vers la production
      if (config.isProduction && !_dbManager.isProductionMode) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Mode Production'),
              ],
            ),
            content: Text(
              'Vous allez basculer vers la base de production avec les vraies données.\n\n'
              'Êtes-vous sûr de vouloir continuer ?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Confirmer'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
      }

      await _dbManager.switchDatabase(_getDatabaseKey(newDatabaseId));
      setState(() {}); // Rafraîchir l'interface
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                config.isProduction ? Icons.production_quantity_limits : Icons.science,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text('✅ Basculé vers "${config.name}"'),
            ],
          ),
          backgroundColor: config.isProduction ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDatabaseKey(String databaseId) {
    switch (databaseId) {
      case 'kipik':
        return 'kipik';
      case 'kipik-demo':
        return 'demo';
      case 'kipik-test':
        return 'test';
      default:
        return 'kipik';
    }
  }

  void _createDemoDatabase() async {
    setState(() {
      _isCreatingDemo = true;
    });

    try {
      await _dbManager.createDemoDatabase();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.science, color: Colors.white),
              SizedBox(width: 8),
              Text('✅ Base de démo créée avec succès !'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );

      setState(() {}); // Rafraîchir l'interface
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur création démo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreatingDemo = false;
      });
    }
  }
}