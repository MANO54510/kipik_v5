// lib/utils/database_sync_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/database_manager.dart';

/// Gestionnaire de synchronisation entre les bases de données
/// Permet de dupliquer automatiquement kipik vers demo et test
class DatabaseSyncManager {
  static DatabaseSyncManager? _instance;
  static DatabaseSyncManager get instance => _instance ??= DatabaseSyncManager._();
  DatabaseSyncManager._();

  /// Collections à synchroniser (toutes sauf les collections système)
  static const List<String> _collectionsToSync = [
    'users',
    'projects', 
    'photos',
    'quotes',
    'conventions',
    'payments',
    'notifications',
    'chats',
    'appointments',
    'reports',
    'referrals',
    'admin_stats',
    'promo_codes',
    'subscription_plans',
    'trial_tracking',
    'promo_tracking',
    'counters',
    // Ajoutez vos autres collections ici
  ];

  /// Collections système à ne PAS synchroniser
  static const List<String> _systemCollections = [
    'admin_first_setup', // Différent par base
    '_connectivity_test', // Temporaire
    '_demo_config', // Spécifique démo
    '_test_config', // Spécifique test
  ];

  /// Synchroniser toutes les bases (demo + test) depuis production
  Future<Map<String, dynamic>> syncAllFromProduction({
    bool forceSync = false,
    List<String>? specificCollections,
  }) async {
    final results = <String, dynamic>{};
    
    print('🔄 Début synchronisation depuis KIPIK Production...');
    final startTime = DateTime.now();

    try {
      // 1. Synchroniser vers demo
      results['demo'] = await syncToDatabase(
        targetDatabase: 'demo',
        forceSync: forceSync,
        specificCollections: specificCollections,
      );

      // 2. Synchroniser vers test  
      results['test'] = await syncToDatabase(
        targetDatabase: 'test',
        forceSync: forceSync,
        specificCollections: specificCollections,
      );

      final duration = DateTime.now().difference(startTime);
      results['duration'] = '${duration.inSeconds}s';
      results['success'] = true;
      
      print('✅ Synchronisation complète terminée en ${duration.inSeconds}s');
      return results;

    } catch (e) {
      results['success'] = false;
      results['error'] = e.toString();
      print('❌ Erreur synchronisation: $e');
      rethrow;
    }
  }

  /// Synchronisation rapide : Collections principales seulement (méthode de convenance)
  Future<Map<String, dynamic>> quickSyncFromProduction({
    bool forceSync = false,
  }) async {
    print('⚡ Synchronisation rapide - Collections principales seulement...');
    
    // Collections principales pour sync rapide
    const quickCollections = [
      'users',
      'projects', 
      'conventions',
      'photos',
    ];
    
    return await syncAllFromProduction(
      forceSync: forceSync,
      specificCollections: quickCollections,
    );
  }

  /// Synchroniser vers une base spécifique
  Future<Map<String, dynamic>> syncToDatabase({
    required String targetDatabase,
    bool forceSync = false,
    List<String>? specificCollections,
  }) async {
    final result = <String, dynamic>{
      'targetDatabase': targetDatabase,
      'collectionsSync': 0,
      'documentsSync': 0,
      'errors': <String>[],
    };

    try {
      // Instances Firestore
      final sourceFirestore = DatabaseManager.instance.getFirestoreInstance('kipik');
      final targetFirestore = DatabaseManager.instance.getFirestoreInstance(targetDatabase);

      print('🎯 Synchronisation vers ${_getDatabaseName(targetDatabase)}...');

      // Collections à synchroniser
      final collections = specificCollections ?? _collectionsToSync;

      for (final collectionName in collections) {
        try {
          print('  📁 Synchronisation collection: $collectionName');
          
          // Vérifier si la collection nécessite une sync
          if (!forceSync && await _isCollectionUpToDate(
            sourceFirestore, 
            targetFirestore, 
            collectionName
          )) {
            print('    ✅ $collectionName déjà à jour');
            continue;
          }

          // Synchroniser la collection
          final docCount = await _syncCollection(
            sourceFirestore, 
            targetFirestore, 
            collectionName,
            targetDatabase,
          );

          result['collectionsSync'] = (result['collectionsSync'] as int) + 1;
          result['documentsSync'] = (result['documentsSync'] as int) + docCount;
          
          print('    ✅ $collectionName: $docCount documents synchronisés');

        } catch (e) {
          final error = 'Erreur collection $collectionName: $e';
          result['errors'].add(error);
          print('    ❌ $error');
        }
      }

      // Marquer la dernière synchronisation
      await _markLastSync(targetFirestore, targetDatabase);

      print('✅ ${_getDatabaseName(targetDatabase)}: ${result['collectionsSync']} collections, ${result['documentsSync']} documents');
      return result;

    } catch (e) {
      result['errors'].add('Erreur générale: $e');
      rethrow;
    }
  }

  /// Synchroniser une collection spécifique
  Future<int> _syncCollection(
    FirebaseFirestore source,
    FirebaseFirestore target,
    String collectionName,
    String targetDatabase,
  ) async {
    int docCount = 0;

    try {
      // 1. Obtenir tous les documents de la collection source
      final sourceSnapshot = await source.collection(collectionName).get();
      
      if (sourceSnapshot.docs.isEmpty) {
        print('    📭 Collection $collectionName vide');
        return 0;
      }

      // 2. Préparer le batch pour la cible
      WriteBatch batch = target.batch();
      int batchCount = 0;
      const int batchLimit = 500; // Limite Firestore

      for (final doc in sourceSnapshot.docs) {
        try {
          Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
          
          // Adapter les données pour la base cible
          data = _adaptDataForTarget(data, targetDatabase);
          
          // Ajouter au batch
          batch.set(target.collection(collectionName).doc(doc.id), data);
          batchCount++;
          docCount++;

          // Exécuter le batch si limite atteinte
          if (batchCount >= batchLimit) {
            await batch.commit();
            batch = target.batch();
            batchCount = 0;
            print('    💾 Batch de $batchLimit documents committed');
          }

        } catch (e) {
          print('    ⚠️ Erreur document ${doc.id}: $e');
        }
      }

      // Exécuter le dernier batch
      if (batchCount > 0) {
        await batch.commit();
        print('    💾 Dernier batch de $batchCount documents committed');
      }

      return docCount;

    } catch (e) {
      print('    ❌ Erreur synchronisation collection $collectionName: $e');
      rethrow;
    }
  }

  /// Adapter les données pour la base cible
  Map<String, dynamic> _adaptDataForTarget(
    Map<String, dynamic> data, 
    String targetDatabase
  ) {
    final adaptedData = Map<String, dynamic>.from(data);

    // Adapter les emails pour démo/test
    if (targetDatabase != 'kipik') {
      final suffix = targetDatabase == 'demo' ? '@demo.kipik.ink' : '@test.kipik.ink';
      
      if (adaptedData['email'] != null) {
        String email = adaptedData['email'];
        if (!email.contains('@demo.') && !email.contains('@test.')) {
          // Extraire le nom avant @ et ajouter le bon suffixe
          final username = email.split('@')[0];
          adaptedData['email'] = '$username$suffix';
        }
      }
    }

    // Marquer l'origine
    adaptedData['_syncedFrom'] = 'kipik';
    adaptedData['_syncedAt'] = FieldValue.serverTimestamp();
    adaptedData['_targetDatabase'] = targetDatabase;

    return adaptedData;
  }

  /// Vérifier si une collection est à jour
  Future<bool> _isCollectionUpToDate(
    FirebaseFirestore source,
    FirebaseFirestore target,
    String collectionName,
  ) async {
    try {
      // Compter les documents dans chaque base
      final sourceCount = await _getCollectionCount(source, collectionName);
      final targetCount = await _getCollectionCount(target, collectionName);

      // Si les comptes diffèrent, pas à jour
      if (sourceCount != targetCount) {
        print('    📊 $collectionName: source=$sourceCount, target=$targetCount → Sync nécessaire');
        return false;
      }

      // Si comptes identiques et pas de documents, considérer à jour
      if (sourceCount == 0) {
        return true;
      }

      // Vérifier les timestamps de dernière modification
      final sourceLastModified = await _getLastModified(source, collectionName);
      final targetLastSync = await _getLastSync(target);

      if (sourceLastModified != null && targetLastSync != null) {
        return sourceLastModified.millisecondsSinceEpoch <= targetLastSync.millisecondsSinceEpoch;
      }

      // Si pas d'info de timestamp, considérer pas à jour
      return false;

    } catch (e) {
      print('    ⚠️ Erreur vérification $collectionName: $e');
      return false; // En cas d'erreur, forcer la sync
    }
  }

  /// Obtenir le nombre de documents dans une collection
  Future<int> _getCollectionCount(FirebaseFirestore firestore, String collectionName) async {
    try {
      final snapshot = await firestore.collection(collectionName).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      // Fallback si count() n'est pas disponible
      final snapshot = await firestore.collection(collectionName).get();
      return snapshot.docs.length;
    }
  }

  /// Obtenir la dernière modification d'une collection
  Future<DateTime?> _getLastModified(FirebaseFirestore firestore, String collectionName) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final timestamp = snapshot.docs.first.data()['createdAt'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Marquer la dernière synchronisation
  Future<void> _markLastSync(FirebaseFirestore firestore, String targetDatabase) async {
    try {
      await firestore.collection('_sync_info').doc('last_sync').set({
        'lastSyncAt': FieldValue.serverTimestamp(),
        'targetDatabase': targetDatabase,
        'syncedFrom': 'kipik',
        'version': '1.0',
      });
    } catch (e) {
      print('⚠️ Erreur marquage sync: $e');
    }
  }

  /// Obtenir la dernière synchronisation
  Future<DateTime?> _getLastSync(FirebaseFirestore firestore) async {
    try {
      final doc = await firestore.collection('_sync_info').doc('last_sync').get();
      if (doc.exists) {
        final timestamp = doc.data()?['lastSyncAt'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtenir le nom lisible d'une base
  String _getDatabaseName(String databaseKey) {
    switch (databaseKey) {
      case 'demo': return 'KIPIK Démo';
      case 'test': return 'KIPIK Test';
      case 'kipik': return 'KIPIK Production';
      default: return 'Base $databaseKey';
    }
  }

  /// Synchronisation automatique au démarrage (mode dev)
  Future<void> autoSyncOnStartup() async {
    print('🔄 Synchronisation automatique au démarrage...');
    
    try {
      // Vérifier si une sync récente a eu lieu (moins de 1h)
      final demoFirestore = DatabaseManager.instance.getFirestoreInstance('demo');
      final lastSync = await _getLastSync(demoFirestore);
      
      if (lastSync != null) {
        final hoursSinceSync = DateTime.now().difference(lastSync).inHours;
        if (hoursSinceSync < 1) {
          print('✅ Sync récente (${hoursSinceSync}h), pas de re-sync nécessaire');
          return;
        }
      }

      // Synchronisation légère (collections principales seulement)
      final coreCollections = ['users', 'projects', 'conventions', 'photos'];
      await syncAllFromProduction(specificCollections: coreCollections);
      
    } catch (e) {
      print('⚠️ Sync automatique échouée: $e');
    }
  }

  /// Obtenir les statistiques de synchronisation
  Future<Map<String, dynamic>> getSyncStats() async {
    final stats = <String, dynamic>{};
    
    try {
      for (final dbKey in ['demo', 'test']) {
        final firestore = DatabaseManager.instance.getFirestoreInstance(dbKey);
        final lastSync = await _getLastSync(firestore);
        
        stats[dbKey] = {
          'lastSync': lastSync?.toIso8601String(),
          'hoursSinceSync': lastSync != null 
              ? DateTime.now().difference(lastSync).inHours 
              : null,
          'collectionsCount': 0,
          'documentsCount': 0,
        };

        // Compter collections et documents
        int totalDocs = 0;
        int totalCols = 0;
        
        for (final collection in _collectionsToSync) {
          try {
            final count = await _getCollectionCount(firestore, collection);
            if (count > 0) {
              totalCols++;
              totalDocs += count;
            }
          } catch (e) {
            // Ignorer les collections qui n'existent pas encore
          }
        }
        
        stats[dbKey]['collectionsCount'] = totalCols;
        stats[dbKey]['documentsCount'] = totalDocs;
      }
      
    } catch (e) {
      stats['error'] = e.toString();
    }
    
    return stats;
  }

  /// Nettoyer les bases démo/test (remettre à zéro)
  Future<void> cleanTargetDatabases() async {
    print('🧹 Nettoyage des bases démo/test...');
    
    for (final dbKey in ['demo', 'test']) {
      try {
        final firestore = DatabaseManager.instance.getFirestoreInstance(dbKey);
        
        for (final collection in _collectionsToSync) {
          try {
            final snapshot = await firestore.collection(collection).get();
            
            if (snapshot.docs.isNotEmpty) {
              final batch = firestore.batch();
              for (final doc in snapshot.docs) {
                batch.delete(doc.reference);
              }
              await batch.commit();
              print('  🗑️ ${_getDatabaseName(dbKey)}: Collection $collection nettoyée');
            }
          } catch (e) {
            print('  ⚠️ Erreur nettoyage $collection: $e');
          }
        }
        
      } catch (e) {
        print('❌ Erreur nettoyage ${_getDatabaseName(dbKey)}: $e');
      }
    }
    
    print('✅ Nettoyage terminé');
  }

  /// Debug du service de synchronisation
  void debugSyncManager() {
    print('🔍 Debug DatabaseSyncManager:');
    print('  - Collections à synchroniser: ${_collectionsToSync.length}');
    print('  - Collections système ignorées: ${_systemCollections.length}');
    print('  - Instance active: ${instance.runtimeType}');
    print('📋 Collections synchronisées:');
    for (final collection in _collectionsToSync) {
      print('  ✅ $collection');
    }
    print('📋 Collections système ignorées:');
    for (final collection in _systemCollections) {
      print('  ❌ $collection');
    }
  }
}