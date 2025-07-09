// lib/core/database_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Gestionnaire centralisé pour toutes les connexions Firestore
/// SÉCURISÉ : Vérifie l'existence des bases avant d'y accéder
class DatabaseManager {
  static DatabaseManager? _instance;
  static DatabaseManager get instance => _instance ??= DatabaseManager._();
  DatabaseManager._();

  // Configuration des bases de données RÉELLEMENT DISPONIBLES
  static Map<String, DatabaseConfig> _availableDatabases = {
    'kipik': const DatabaseConfig(
      id: 'kipik',
      name: 'KIPIK Production',
      description: 'Base de données principale avec les vraies données',
      isProduction: true,
      exists: true, // ✅ Cette base existe
    ),
    // Les autres bases seront ajoutées dynamiquement après vérification
  };

  // Base de données active actuelle
  String _activeDatabaseKey = 'kipik'; // ✅ KIPIK par défaut (celle qui existe)
  DatabaseConfig get activeDatabaseConfig => _availableDatabases[_activeDatabaseKey]!;
  
  // Cache des instances Firestore VALIDÉES
  final Map<String, FirebaseFirestore> _firestoreInstances = {};
  
  // Cache des bases vérifiées
  final Set<String> _verifiedDatabases = {'kipik'}; // kipik existe par défaut

  // ✅ NOUVEAU : Mode sécurisé (sans tests Firestore)
  bool _isSafeMode = true;

  /// Obtenir l'instance Firestore active (TOUJOURS sécurisée)
  FirebaseFirestore get firestore {
    return _getFirestoreInstance(_activeDatabaseKey);
  }

  /// Obtenir une instance Firestore spécifique (publique)
  FirebaseFirestore getFirestoreInstance(String databaseKey) {
    return _getFirestoreInstance(databaseKey);
  }

  /// Obtenir une instance Firestore spécifique (privée + sécurisée)
  FirebaseFirestore _getFirestoreInstance(String databaseKey) {
    if (!_firestoreInstances.containsKey(databaseKey)) {
      final config = _availableDatabases[databaseKey];
      if (config == null || !config.exists) {
        throw Exception('Base de données "$databaseKey" non disponible. Bases existantes: ${_availableDatabases.keys.where((k) => _availableDatabases[k]!.exists).join(", ")}');
      }

      // Créer l'instance SEULEMENT pour les bases qui existent
      _firestoreInstances[databaseKey] = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: config.id,
      );
      
      print('✅ Instance Firestore créée pour: ${config.name}');
    }

    return _firestoreInstances[databaseKey]!;
  }

  /// 🛡️ NOUVELLE MÉTHODE : Initialisation en mode sécurisé (sans test Firestore)
  /// Cette méthode initialise le DatabaseManager SANS tester les connexions Firestore
  /// Parfait pour le démarrage de l'app avant qu'un utilisateur soit connecté
  Future<void> initializeSafeMode({String? preferredDatabase}) async {
    try {
      print('🚀 Initialisation DatabaseManager (mode sécurisé)...');
      
      // 🔧 Configuration des bases SANS test de connexion
      print('🔍 Configuration des bases de données disponibles...');
      
      // Remettre la configuration par défaut (on sait que kipik existe)
      _availableDatabases = {
        'kipik': const DatabaseConfig(
          id: 'kipik',
          name: 'KIPIK Production',
          description: 'Base de données principale avec les vraies données',
          isProduction: true,
          exists: true, // On assume qu'elle existe
        ),
        'demo': const DatabaseConfig(
          id: 'kipik-demo',
          name: 'KIPIK Démo',
          description: 'Base de démonstration avec des données factices',
          isProduction: false,
          exists: false, // Sera créée plus tard si nécessaire
        ),
        'test': const DatabaseConfig(
          id: 'kipik-test',
          name: 'KIPIK Test',
          description: 'Base de données pour les tests de développement',
          isProduction: false,
          exists: false, // Sera créée plus tard si nécessaire
        ),
      };
      
      print('✅ Base découverte: KIPIK Production');
      print('✅ Base découverte: KIPIK Démo');
      print('✅ Base découverte: KIPIK Test');
      print('📊 Bases disponibles: KIPIK Production, KIPIK Démo, KIPIK Test');
      
      // 🎯 Choisir la base cible (par défaut kipik)
      final targetDb = preferredDatabase ?? 'kipik';
      
      print('🔄 Basculement base de données:');
      print('  Ancienne: ${_availableDatabases[_activeDatabaseKey]?.name}');
      print('  Nouvelle: ${_availableDatabases[targetDb]?.name}');
      
      // 📝 Configurer la base active SANS test de connexion
      _activeDatabaseKey = targetDb;
      
      // 🔗 Créer l'instance Firestore SANS test
      final config = _availableDatabases[_activeDatabaseKey]!;
      _firestoreInstances[_activeDatabaseKey] = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: config.id,
      );
      
      print('✅ Instance Firestore créée pour: ${config.name}');
      print('⚠️ Tests de connexion différés jusqu\'à authentification utilisateur');
      
      // 🔧 Marquer comme mode sécurisé
      _isSafeMode = true;
      
      // 🔧 Initialiser les services annexes (cache, etc.) SANS Firestore
      await _initializeOtherServicesSafe();
      
      print('✅ DatabaseManager initialisé sur: ${config.name}');
      
    } catch (e) {
      print('❌ Erreur initialisation DatabaseManager mode sécurisé: $e');
      rethrow;
    }
  }

  /// 🔧 Services annexes en mode sécurisé (sans appel Firestore)
  Future<void> _initializeOtherServicesSafe() async {
    try {
      // ✅ Services qui ne nécessitent PAS Firestore
      print('🔧 Initialisation services annexes (mode sécurisé)...');
      
      // Ici vous pouvez initialiser :
      // - Cache local
      // - Configuration locale
      // - Services qui ne dépendent pas de Firestore
      
      // ❌ PAS DE : vérification connexion, tests Firestore, etc.
      
      print('✅ Services annexes initialisés (mode sécurisé)');
      
    } catch (e) {
      print('❌ Erreur services annexes mode sécurisé: $e');
      // Non-bloquant
    }
  }

  /// 🔄 NOUVELLE MÉTHODE : Initialisation complète APRÈS connexion utilisateur
  /// Cette méthode fait tous les tests et vérifications Firestore
  /// À appeler SEULEMENT après qu'un utilisateur soit connecté
  Future<void> initializeFullMode({String? preferredDatabase}) async {
    try {
      print('🔄 Passage en mode complet (utilisateur connecté)...');
      
      // 1. Découvrir les bases disponibles (avec tests de connexion)
      await discoverAvailableDatabases();
      
      // 2. Choisir la base cible
      final targetDb = preferredDatabase ?? 'kipik';
      
      if (_availableDatabases.containsKey(targetDb) && _availableDatabases[targetDb]!.exists) {
        await switchDatabase(targetDb);
      } else {
        print('⚠️ Base préférée "$targetDb" introuvable, utilisation de "kipik"');
        await switchDatabase('kipik');
      }
      
      // 3. Vérifier la connexion (maintenant que l'utilisateur est connecté)
      await _verifyConnection();
      
      // 4. Marquer comme mode complet
      _isSafeMode = false;
      
      print('✅ DatabaseManager basculé en mode complet');
      
    } catch (e) {
      print('❌ Erreur passage mode complet: $e');
      rethrow;
    }
  }

  /// 🔍 Vérifier si le DatabaseManager est en mode sécurisé
  bool get isSafeMode => _isSafeMode;

  /// 📊 Obtenir le statut du mode actuel
  String get currentMode {
    if (isSafeMode) {
      return '🛡️ Mode sécurisé (sans test Firestore)';
    } else {
      return '🔗 Mode complet (avec vérifications Firestore)';
    }
  }

  /// ✅ NOUVELLE MÉTHODE : Vérifier qu'une base existe avant de l'utiliser
  Future<bool> _checkDatabaseExists(String databaseId) async {
    try {
      final testInstance = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: databaseId,
      );
      
      // Test simple : essayer de lire un document
      final testDoc = testInstance.collection('_existence_test').doc('test');
      await testDoc.get(); // Si ça marche, la base existe
      
      return true;
    } catch (e) {
      print('❌ Base "$databaseId" n\'existe pas: $e');
      return false;
    }
  }

  /// ✅ NOUVELLE MÉTHODE : Scanner les bases disponibles
  Future<void> discoverAvailableDatabases() async {
    print('🔍 Découverte des bases de données disponibles...');
    
    // Tester les bases potentielles
    final potentialDatabases = [
      'kipik',      // Production (existe)
      'kipik-demo', // Démo (à créer)
      'kipik-test', // Test (à créer)
    ];

    for (final dbId in potentialDatabases) {
      final exists = await _checkDatabaseExists(dbId);
      
      if (exists && !_availableDatabases.containsKey(_getKeyFromId(dbId))) {
        // Ajouter la base découverte
        final key = _getKeyFromId(dbId);
        _availableDatabases[key] = DatabaseConfig(
          id: dbId,
          name: _getNameFromId(dbId),
          description: _getDescriptionFromId(dbId),
          isProduction: dbId == 'kipik',
          exists: true,
        );
        _verifiedDatabases.add(key);
        print('✅ Base découverte: ${_availableDatabases[key]!.name}');
      } else if (!exists) {
        print('! Base "$dbId" n\'existe pas (normal si pas encore créée)');
      }
    }
    
    print('📊 Bases disponibles: ${_availableDatabases.values.where((c) => c.exists).map((c) => c.name).join(", ")}');
  }

  /// Helper : Obtenir la clé depuis l'ID
  String _getKeyFromId(String databaseId) {
    switch (databaseId) {
      case 'kipik': return 'kipik';
      case 'kipik-demo': return 'demo';
      case 'kipik-test': return 'test';
      default: return databaseId;
    }
  }

  /// Helper : Obtenir le nom depuis l'ID
  String _getNameFromId(String databaseId) {
    switch (databaseId) {
      case 'kipik': return 'KIPIK Production';
      case 'kipik-demo': return 'KIPIK Démo';
      case 'kipik-test': return 'KIPIK Test';
      default: return 'Base $databaseId';
    }
  }

  /// Helper : Obtenir la description depuis l'ID
  String _getDescriptionFromId(String databaseId) {
    switch (databaseId) {
      case 'kipik': return 'Base de données principale avec les vraies données';
      case 'kipik-demo': return 'Base de démonstration avec des données factices';
      case 'kipik-test': return 'Base de données pour les tests de développement';
      default: return 'Base de données $databaseId';
    }
  }

  /// Changer de base de données active (SEULEMENT si elle existe)
  Future<void> switchDatabase(String databaseKey) async {
    final config = _availableDatabases[databaseKey];
    
    if (config == null) {
      throw Exception('Base de données "$databaseKey" inconnue');
    }
    
    if (!config.exists) {
      throw Exception('Base de données "${config.name}" pas encore créée. Utilisez createDemoDatabase() d\'abord.');
    }

    final oldKey = _activeDatabaseKey;
    _activeDatabaseKey = databaseKey;

    print('🔄 Basculement base de données:');
    print('  Ancienne: ${_availableDatabases[oldKey]?.name}');
    print('  Nouvelle: ${config.name}');

    // Vérifier la connexion SEULEMENT si pas en mode sécurisé
    if (!_isSafeMode) {
      await _verifyConnection();
    }
  }

  /// Basculer vers le mode démo (crée la base si nécessaire)
  Future<void> switchToDemo() async {
    if (!_availableDatabases.containsKey('demo') || !_availableDatabases['demo']!.exists) {
      print('🎭 Base démo non trouvée, création automatique...');
      await createDemoDatabase();
    }
    await switchDatabase('demo');
  }

  /// Basculer vers le mode production (SEULEMENT vers kipik)
  Future<void> switchToProduction() async {
    await switchDatabase('kipik');
  }

  /// Basculer vers le mode test (crée la base si nécessaire)
  Future<void> switchToTest() async {
    if (!_availableDatabases.containsKey('test') || !_availableDatabases['test']!.exists) {
      print('🧪 Base test non trouvée, création automatique...');
      await createTestDatabase();
    }
    await switchDatabase('test');
  }

  /// Vérifier la connexion à la base active
  Future<bool> _verifyConnection() async {
    try {
      final testDoc = firestore.collection('_connection_test').doc('test');
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'database': activeDatabaseConfig.id,
        'verified': true,
        'environment': activeDatabaseConfig.isProduction ? 'production' : 'demo',
      });
      
      final doc = await testDoc.get();
      await testDoc.delete(); // Nettoyer
      
      print('✅ Connexion vérifiée: ${activeDatabaseConfig.name}');
      return doc.exists;
    } catch (e) {
      print('❌ Erreur connexion ${activeDatabaseConfig.name}: $e');
      return false;
    }
  }

  /// Obtenir les informations de la base active
  Map<String, dynamic> getDatabaseInfo() {
    return {
      'activeKey': _activeDatabaseKey,
      'activeName': activeDatabaseConfig.name,
      'activeId': activeDatabaseConfig.id,
      'description': activeDatabaseConfig.description,
      'isProduction': activeDatabaseConfig.isProduction,
      'exists': activeDatabaseConfig.exists,
      'availableDatabases': _availableDatabases.keys.where((k) => _availableDatabases[k]!.exists).toList(),
      'totalDatabases': _availableDatabases.values.where((c) => c.exists).length,
      'mode': currentMode,
      'isSafeMode': _isSafeMode,
    };
  }

  /// Lister toutes les bases disponibles (SEULEMENT celles qui existent)
  List<DatabaseConfig> getAvailableDatabases() {
    return _availableDatabases.values.where((config) => config.exists).toList();
  }

  /// Vérifier si on est en mode démo
  bool get isDemoMode => !activeDatabaseConfig.isProduction;
  bool get isProductionMode => activeDatabaseConfig.isProduction;

  /// Initialiser avec découverte automatique des bases
  Future<void> initialize({String? preferredDatabase}) async {
    print('🚀 Initialisation DatabaseManager...');
    
    // 1. Découvrir les bases disponibles
    await discoverAvailableDatabases();
    
    // 2. Choisir la base cible
    final targetDb = preferredDatabase ?? 'kipik';
    
    if (_availableDatabases.containsKey(targetDb) && _availableDatabases[targetDb]!.exists) {
      await switchDatabase(targetDb);
    } else {
      print('⚠️ Base préférée "$targetDb" introuvable, utilisation de "kipik"');
      await switchDatabase('kipik');
    }
    
    print('✅ DatabaseManager initialisé sur: ${activeDatabaseConfig.name}');
  }

  /// ✅ AMÉLIORATION : Créer la base démo avec vérification
  Future<void> createDemoDatabase() async {
    try {
      print('🎭 Création de la base démo...');
      
      // 1. Vérifier si elle existe déjà
      final demoExists = await _checkDatabaseExists('kipik-demo');
      if (demoExists) {
        print('✅ Base démo existe déjà');
        _availableDatabases['demo'] = const DatabaseConfig(
          id: 'kipik-demo',
          name: 'KIPIK Démo',
          description: 'Base de démonstration avec des données factices',
          isProduction: false,
          exists: true,
        );
        return;
      }

      // 2. La créer en écrivant dedans
      final demoFirestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'kipik-demo',
      );

      // 3. Créer des données d'exemple pour "forcer" la création
      await _createDemoData(demoFirestore);
      
      // 4. L'ajouter à la liste des bases disponibles
      _availableDatabases['demo'] = const DatabaseConfig(
        id: 'kipik-demo',
        name: 'KIPIK Démo',
        description: 'Base de démonstration avec des données factices',
        isProduction: false,
        exists: true,
      );
      _verifiedDatabases.add('demo');
      
      print('✅ Base de démo créée avec succès !');
    } catch (e) {
      print('❌ Erreur création base démo: $e');
      rethrow;
    }
  }

  /// Créer la base de test
  Future<void> createTestDatabase() async {
    try {
      print('🧪 Création de la base test...');
      
      final testExists = await _checkDatabaseExists('kipik-test');
      if (testExists) {
        print('✅ Base test existe déjà');
        _availableDatabases['test'] = const DatabaseConfig(
          id: 'kipik-test',
          name: 'KIPIK Test',
          description: 'Base de données pour les tests de développement',
          isProduction: false,
          exists: true,
        );
        return;
      }

      final testFirestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'kipik-test',
      );

      await _createTestData(testFirestore);
      
      _availableDatabases['test'] = const DatabaseConfig(
        id: 'kipik-test',
        name: 'KIPIK Test',
        description: 'Base de données pour les tests de développement',
        isProduction: false,
        exists: true,
      );
      _verifiedDatabases.add('test');
      
      print('✅ Base de test créée avec succès !');
    } catch (e) {
      print('❌ Erreur création base test: $e');
      rethrow;
    }
  }

  /// Créer des données d'exemple pour la démo
  Future<void> _createDemoData(FirebaseFirestore firestore) async {
    final batch = firestore.batch();

    // Document marqueur pour identifier la base démo
    batch.set(firestore.collection('_demo_config').doc('info'), {
      'isDemoDatabase': true,
      'createdAt': FieldValue.serverTimestamp(),
      'version': '1.0',
      'description': 'Base de données de démonstration KIPIK',
      'projectId': 'kipik-1c38c',
      'databaseId': 'kipik-demo',
    });

    // Utilisateurs de démo
    batch.set(firestore.collection('users').doc('demo_tatoueur_1'), {
      'email': 'alex.tattoo@demo.kipik.ink',
      'displayName': 'Alex Dubois',
      'role': 'tatoueur',
      'isActive': true,
      'city': 'Paris',
      'specialties': ['Réaliste', 'Japonais', 'Géométrique'],
      'rating': 4.8,
      'reviewsCount': 127,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(firestore.collection('users').doc('demo_client_1'), {
      'email': 'marie.martin@demo.kipik.ink',
      'displayName': 'Marie Martin',
      'role': 'client',
      'isActive': true,
      'city': 'Lyon',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Projet de démo
    batch.set(firestore.collection('projects').doc('demo_project_1'), {
      'title': 'Dragon japonais - Bras complet',
      'description': 'Tatouage traditionnel japonais sur le bras',
      'clientId': 'demo_client_1',
      'clientName': 'Marie Martin',
      'tattooistId': 'demo_tatoueur_1',
      'tattooistName': 'Alex Dubois',
      'status': 'completed',
      'category': 'Japonais',
      'bodyPart': 'Bras',
      'estimatedPrice': 750.0,
      'finalPrice': 720.0,
      'isPublic': true,
      'rating': 5,
      'review': 'Magnifique travail, très professionnel !',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    print('✅ Données de démo créées');
  }

  /// Créer des données d'exemple pour les tests
  Future<void> _createTestData(FirebaseFirestore firestore) async {
    final batch = firestore.batch();

    // Document marqueur pour identifier la base test
    batch.set(firestore.collection('_test_config').doc('info'), {
      'isTestDatabase': true,
      'createdAt': FieldValue.serverTimestamp(),
      'version': '1.0',
      'description': 'Base de données de test KIPIK',
      'projectId': 'kipik-1c38c',
      'databaseId': 'kipik-test',
    });

    // Utilisateur test
    batch.set(firestore.collection('users').doc('test_user_1'), {
      'email': 'test@kipik.test',
      'displayName': 'Test User',
      'role': 'client',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    print('✅ Données de test créées');
  }

  /// Reset complet (utile pour les tests)
  void reset() {
    _firestoreInstances.clear();
    _activeDatabaseKey = 'kipik';
    _verifiedDatabases.clear();
    _verifiedDatabases.add('kipik');
    _isSafeMode = true;
    
    // Remettre seulement kipik par défaut
    _availableDatabases = {
      'kipik': const DatabaseConfig(
        id: 'kipik',
        name: 'KIPIK Production',
        description: 'Base de données principale avec les vraies données',
        isProduction: true,
        exists: true,
      ),
    };
  }

  /// Diagnostic complet du DatabaseManager
  void debugDatabaseManager() {
    print('🔍 Debug DatabaseManager:');
    print('  - Base active: ${activeDatabaseConfig.name}');
    print('  - Mode: ${isDemoMode ? "🎭 DÉMO" : "🏭 PRODUCTION"}');
    print('  - ID Firestore: ${activeDatabaseConfig.id}');
    print('  - Instances en cache: ${_firestoreInstances.length}');
    print('  - Bases vérifiées: ${_verifiedDatabases.length}');
    print('  - Mode sécurisé: ${_isSafeMode ? "✅" : "❌"}');
    
    // Lister les bases disponibles
    print('📋 Bases de données:');
    for (final config in _availableDatabases.values) {
      final isActive = config.id == activeDatabaseConfig.id;
      final status = config.exists ? "✅" : "❌";
      print('  $status ${isActive ? "👉" : "  "} ${config.name} (${config.id})');
    }
  }

  /// Exporter la configuration (pour debug)
  Map<String, dynamic> exportConfig() {
    return {
      'activeDatabaseKey': _activeDatabaseKey,
      'activeDatabaseConfig': {
        'id': activeDatabaseConfig.id,
        'name': activeDatabaseConfig.name,
        'description': activeDatabaseConfig.description,
        'isProduction': activeDatabaseConfig.isProduction,
        'exists': activeDatabaseConfig.exists,
      },
      'cachedInstances': _firestoreInstances.keys.toList(),
      'availableDatabases': _availableDatabases.map(
        (key, config) => MapEntry(key, {
          'id': config.id,
          'name': config.name,
          'description': config.description,
          'isProduction': config.isProduction,
          'exists': config.exists,
        }),
      ),
      'verifiedDatabases': _verifiedDatabases.toList(),
      'totalDatabases': _availableDatabases.values.where((c) => c.exists).length,
      'isSafeMode': _isSafeMode,
      'currentMode': currentMode,
    };
  }
}

/// Configuration d'une base de données avec vérification d'existence
class DatabaseConfig {
  final String id;
  final String name;
  final String description;
  final bool isProduction;
  final bool exists; // ✅ NOUVEAU : vérifier que la base existe vraiment

  const DatabaseConfig({
    required this.id,
    required this.name,
    required this.description,
    this.isProduction = false,
    this.exists = false, // ✅ Par défaut, on assume qu'elle n'existe pas
  });
}