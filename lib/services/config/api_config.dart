// lib/services/config/api_config.dart - Version complète

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String? _cachedApiKey;
  static bool _isInitialized = false;

  /// Initialiser la configuration au démarrage de l'app
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Charger le fichier .env
      await dotenv.load(fileName: ".env");
      print('✅ Fichier .env chargé avec succès');
      _isInitialized = true;
    } catch (e) {
      print('❌ Erreur chargement .env: $e');
      throw Exception('Fichier .env non trouvé ou invalide');
    }
  }

  /// Récupérer la clé API Google depuis .env
  static Future<String> get googleApiKey async {
    if (_cachedApiKey != null) return _cachedApiKey!;

    await initialize();

    // Essayer GOOGLE_API_KEY d'abord, puis GOOGLE_MAPS_API_KEY
    final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? dotenv.env['GOOGLE_MAPS_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw Exception(
        'Clé API Google non trouvée dans .env\n'
        'Ajoutez GOOGLE_API_KEY ou GOOGLE_MAPS_API_KEY dans votre fichier .env'
      );
    }

    if (!apiKey.startsWith('AIza')) {
      throw Exception('Clé API Google invalide (doit commencer par "AIza")');
    }

    _cachedApiKey = apiKey;
    print('✅ Clé API Google chargée depuis .env: ${apiKey.substring(0, 10)}...');
    return apiKey;
  }

  /// Même clé pour tous les services Google
  static Future<String> get googleVisionApiKey => googleApiKey;
  static Future<String> get googleMapsApiKey => googleApiKey;
  static Future<String> get googlePlacesApiKey => googleApiKey;

  /// URL de base pour Google Vision API
  static const String googleVisionBaseUrl = 'https://vision.googleapis.com/v1';

  /// Vérifier si Google Vision est configuré
  static Future<bool> get isGoogleVisionConfigured async {
    try {
      final key = await googleApiKey;
      return key.isNotEmpty && key.startsWith('AIza');
    } catch (e) {
      return false;
    }
  }

  /// ✅ NOUVELLE MÉTHODE - Vérifier si la configuration est valide
  static Future<bool> get isConfigurationValid async {
    try {
      final key = await googleApiKey;
      return key.isNotEmpty && key.startsWith('AIza');
    } catch (e) {
      return false;
    }
  }

  /// Debug: Afficher l'état de la configuration
  static Future<void> debugConfiguration() async {
    print('🔍 DEBUG Configuration API:');
    print('   - .env initialisé: $_isInitialized');
    
    final envKey = dotenv.env['GOOGLE_API_KEY'];
    final mapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    
    print('   - GOOGLE_API_KEY: ${envKey?.substring(0, 10) ?? 'Non définie'}...');
    print('   - GOOGLE_MAPS_API_KEY: ${mapsKey?.substring(0, 10) ?? 'Non définie'}...');
    
    final isValid = await isConfigurationValid;
    print('   - Configuration valide: $isValid');
  }

  /// Nettoyer le cache (pour les tests)
  static void clearCache() {
    _cachedApiKey = null;
    _isInitialized = false;
  }
}