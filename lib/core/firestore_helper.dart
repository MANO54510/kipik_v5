// lib/core/firestore_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_manager.dart';

/// Helper pour migration transparente des services existants
class FirestoreHelper {
  /// Remplace FirebaseFirestore.instance dans tous vos services
  static FirebaseFirestore get instance {
    return DatabaseManager.instance.firestore;
  }

  /// Pour les nouveaux services (plus explicite)
  static FirebaseFirestore get database {
    return DatabaseManager.instance.firestore;
  }

  /// Obtenir une base spécifique temporairement
  static FirebaseFirestore getDatabase(String databaseKey) {
    return DatabaseManager.instance.getFirestoreInstance(databaseKey);
  }

  /// Information sur la base active
  static Map<String, dynamic> info() {
    return DatabaseManager.instance.getDatabaseInfo();
  }

  /// Vérifier si on est en mode démo
  static bool get isDemoMode => DatabaseManager.instance.isDemoMode;
  static bool get isProductionMode => DatabaseManager.instance.isProductionMode;

  /// Obtenir le nom de la base active
  static String get activeDatabaseName => DatabaseManager.instance.activeDatabaseConfig.name;

  /// Obtenir l'ID de la base active
  static String get activeDatabaseId => DatabaseManager.instance.activeDatabaseConfig.id;
}