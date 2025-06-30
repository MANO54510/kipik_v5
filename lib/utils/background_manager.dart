import 'dart:math';
import 'package:intl/intl.dart'; // On va utiliser ça pour la gestion des dates.

class BackgroundManager {
  static final List<String> _defaultBackgrounds = [
    'assets/background1.png',
    'assets/background2.png',
    'assets/background3.png',
    'assets/background4.png',
  ];

  static final Map<String, String> _eventBackgrounds = {
    'halloween': 'assets/background_halloween.png',
    'noel': 'assets/background_noel.png',
  };

  static String? _forcedBackground; // Ici si on force manuellement

  /// Permet de forcer un fond d'écran (option admin)
  static void forceBackground(String backgroundAssetPath) {
    _forcedBackground = backgroundAssetPath;
  }

  /// Permet d'annuler le fond forcé
  static void clearForcedBackground() {
    _forcedBackground = null;
  }

  /// Retourne l'image du background à utiliser
  static String getBackgroundImage() {
    if (_forcedBackground != null) {
      return _forcedBackground!;
    }

    // Gestion des événements spéciaux
    final now = DateTime.now();
    final today = DateFormat('MM-dd').format(now); // Format Mois-Jour

    if (today.compareTo('10-25') >= 0 && today.compareTo('10-31') <= 0) {
      return _eventBackgrounds['halloween'] ?? _randomDefaultBackground();
    } else if (today.compareTo('12-20') >= 0 && today.compareTo('12-26') <= 0) {
      return _eventBackgrounds['noel'] ?? _randomDefaultBackground();
    }

    // Sinon, on prend un fond aléatoire
    return _randomDefaultBackground();
  }

  static String _randomDefaultBackground() {
    final random = Random();
    return _defaultBackgrounds[random.nextInt(_defaultBackgrounds.length)];
  }
}
