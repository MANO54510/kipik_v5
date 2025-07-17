// lib/core/firestore_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Helper pour gestion centralisée de Firestore avec la base Kipik
class FirestoreHelper {
  static FirebaseFirestore? _instance;
  
  /// Instance Firestore pour la base 'kipik'
  static FirebaseFirestore get instance {
    _instance ??= FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'kipik',
    );
    return _instance!;
  }

  /// Pour les nouveaux services (plus explicite)
  static FirebaseFirestore get database {
    return instance;
  }

  /// Obtenir une base spécifique si nécessaire
  static FirebaseFirestore getDatabaseByName(String databaseName) {
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: databaseName,
    );
  }

  /// Information sur la base active
  static Map<String, String> get info {
    return {
      'name': 'Kipik Database',
      'id': 'kipik',
      'type': 'production',
      'description': 'Base de données principale Kipik pour tatoueurs et clients',
    };
  }

  /// Vérifier la connexion à la base
  static Future<bool> checkConnection() async {
    try {
      await instance.collection('_health_check').limit(1).get();
      print('✅ Connexion Firestore Kipik OK');
      return true;
    } catch (e) {
      print('❌ Erreur connexion Firestore Kipik: $e');
      return false;
    }
  }

  /// Debug de la configuration
  static Future<void> debugFirestore() async {
    try {
      print('🔍 Debug Firestore:');
      print('  - Database ID: kipik');
      print('  - App: ${Firebase.app().name}');
      
      final healthCheck = await checkConnection();
      print('  - Connexion: ${healthCheck ? "OK" : "ERREUR"}');
      
    } catch (e) {
      print('❌ Erreur debug Firestore: $e');
    }
  }
}