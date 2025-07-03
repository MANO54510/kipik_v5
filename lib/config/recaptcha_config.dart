// Configuration corrigée pour votre domaine

import 'package:flutter/foundation.dart'; // ✅ AJOUT: Import manquant

class ReCaptchaConfig {
  // 🔑 VOS CLÉS reCAPTCHA (à remplacer par les vraies)
  static const String siteKey = '6LeKWXQrAAAAALlP79kajYo_r1k6_H1Wi3arfseJ';
  static const String secretKey = '6LeKWXQrAAAAAOb2UL7I5x75H-nnK4dNKzjREFz0';
  
  // 🌐 Configuration par environnement - CORRIGÉE
  static String get currentDomain {
    // En production Firebase
    if (kReleaseMode) {  // ✅ CORRIGÉ: kReleaseMode avec import
      return 'kipik-1c38c.web.app';
    }
    // En développement
    return 'localhost';
  }
  
  // 🎯 DOMAINES pour reCAPTCHA (à configurer sur Google)
  static const List<String> allowedDomains = [
    // 🔥 FIREBASE (actuel)
    'kipik-1c38c.web.app',
    'kipik-1c38c.firebaseapp.com',
    
    // 🛠️ DÉVELOPPEMENT
    'localhost',
    '127.0.0.1',
    '192.168.1.100',
    
    // 🎯 FUTUR (quand kipik.imk sera récupéré)
    'kipik.imk',
    'www.kipik.imk',
  ];
  
  // 🎭 Actions spécifiques KIPIK
  static const Map<String, String> actions = {
    'login': 'kipik_login',
    'signup': 'kipik_signup',
    'payment': 'kipik_payment',
    'booking': 'kipik_booking',
    'profile': 'kipik_profile',
  };
  
  // 📊 Scores minimum par action
  static const Map<String, double> minScores = {
    'login': 0.5,
    'signup': 0.7,
    'payment': 0.8,    // Très strict pour paiements
    'booking': 0.6,
    'profile': 0.6,
  };
  
  /// Obtenir le score minimum pour une action
  static double getMinScore(String action) {
    return minScores[action] ?? 0.5;
  }
  
  /// Obtenir l'action reCAPTCHA
  static String getAction(String context) {
    return actions[context] ?? 'kipik_general';
  }
  
  /// Vérifier si un score est acceptable
  static bool isScoreAcceptable(String action, double score) {
    return score >= getMinScore(action);
  }
}