// lib/services/auth/captcha_manager.dart - Version améliorée avec scores par action

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class CaptchaManager {
  static CaptchaManager? _instance;
  static CaptchaManager get instance => _instance ??= CaptchaManager._();
  CaptchaManager._();

  // Configuration reCAPTCHA depuis .env
  static String get siteKey => dotenv.env['RECAPTCHA_SITE_KEY'] ?? '';
  static String get secretKey => dotenv.env['RECAPTCHA_SECRET_KEY'] ?? '';
  static String get validationUrl => dotenv.env['RECAPTCHA_VALIDATION_URL'] ?? '';
  
  // ✅ SCORES SPÉCIFIQUES PAR ACTION (comme votre config précédente)
  static double get captchaMinScore => double.tryParse(dotenv.env['CAPTCHA_MIN_SCORE'] ?? '0.5') ?? 0.5;
  static double get paymentMinScore => double.tryParse(dotenv.env['PAYMENT_MIN_SCORE'] ?? '0.8') ?? 0.8;
  static double get bookingMinScore => double.tryParse(dotenv.env['BOOKING_MIN_SCORE'] ?? '0.6') ?? 0.6;
  static double get signupMinScore => double.tryParse(dotenv.env['SIGNUP_MIN_SCORE'] ?? '0.7') ?? 0.7;
  
  // Sécurité générale
  static int get maxLoginAttempts => int.tryParse(dotenv.env['MAX_LOGIN_ATTEMPTS'] ?? '3') ?? 3;
  static int get lockoutDuration => int.tryParse(dotenv.env['LOCKOUT_DURATION_MINUTES'] ?? '15') ?? 15;
  static int get sessionTimeout => int.tryParse(dotenv.env['SESSION_TIMEOUT_MINUTES'] ?? '60') ?? 60;
  
  // Cache des tentatives par IP/appareil
  final Map<String, LoginAttemptData> _attempts = {};

  /// Initialiser le manager (charger les tentatives sauvegardées)
  Future<void> initialize() async {
    await loadAttemptsFromStorage();
    cleanupOldAttempts();
    
    print('🔐 CaptchaManager initialisé:');
    print('  - Payment: ${paymentMinScore}');
    print('  - Booking: ${bookingMinScore}');
    print('  - Signup: ${signupMinScore}');
    print('  - Default: ${captchaMinScore}');
  }

  /// ✅ NOUVEAU: Obtenir le score minimum requis selon l'action
  double getRequiredScoreForAction(String action) {
    switch (action.toLowerCase()) {
      case 'payment':
      case 'paiement':
      case 'pay':
        return paymentMinScore; // 0.8 par défaut
        
      case 'booking':
      case 'reservation':
      case 'rendez_vous':
        return bookingMinScore; // 0.6 par défaut
        
      case 'signup':
      case 'inscription':
      case 'register':
      case 'registration_particulier':
      case 'registration_pro':
        return signupMinScore; // 0.7 par défaut
        
      case 'login':
      case 'connexion':
        return captchaMinScore; // 0.5 par défaut
        
      case 'password_reset':
      case 'forgot_password':
        return captchaMinScore; // 0.5 par défaut
        
      default:
        return captchaMinScore; // Score par défaut
    }
  }

  /// ✅ MÉTHODE PRINCIPALE: Validation d'action utilisateur avec contexte
  Future<CaptchaResult> validateUserAction({
    required String action,
    BuildContext? context,
    String? identifier,
  }) async {
    try {
      // Normaliser l'action pour compatibilité
      final normalizedAction = _normalizeAction(action);
      
      // Vérifier si le CAPTCHA est requis
      if (!shouldShowCaptcha(normalizedAction, identifier: identifier)) {
        return CaptchaResult(
          isValid: true,
          score: 1.0, // Score parfait si pas de validation requise
          action: normalizedAction,
          requiredScore: getRequiredScoreForAction(normalizedAction),
          timestamp: DateTime.now(),
          token: 'no_captcha_required',
        );
      }

      // Effectuer la validation invisible
      return await validateInvisibleCaptcha(normalizedAction);
      
    } catch (e) {
      print('❌ Erreur validateUserAction: $e');
      return CaptchaResult(
        isValid: false,
        score: 0.0,
        action: action,
        requiredScore: getRequiredScoreForAction(action),
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// ✅ Normaliser les noms d'actions pour compatibilité
  String _normalizeAction(String action) {
    switch (action.toLowerCase()) {
      case 'registration_particulier':
      case 'registration_pro':
      case 'register':
        return 'signup';
      case 'connexion':
        return 'login';
      case 'paiement':
        return 'payment';
      case 'reservation':
      case 'rendez_vous':
        return 'booking';
      default:
        return action.toLowerCase();
    }
  }

  /// ✅ AMÉLIORÉ: Validation avec score adaptatif selon l'action
  Future<CaptchaResult> validateInvisibleCaptcha(String action) async {
    try {
      final requiredScore = getRequiredScoreForAction(action);
      
      // En mode développement, simuler différents scénarios
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 800));
        
        final random = Random();
        // Simuler des scores plus variés pour tester selon l'action
        final scenarios = _getDebugScenariosForAction(action);
        final score = scenarios[random.nextInt(scenarios.length)];
        
        print('🔍 CAPTCHA simulé - Action: $action, Score: ${score.toStringAsFixed(2)}, Requis: ${requiredScore.toStringAsFixed(2)}');
        
        return CaptchaResult(
          isValid: score >= requiredScore,
          score: score,
          action: action,
          requiredScore: requiredScore,
          timestamp: DateTime.now(),
          token: 'debug_token_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      
      // En production, utiliser votre Cloud Function
      return await _validateWithBackend(action);
      
    } catch (e) {
      print('❌ Erreur validation CAPTCHA: $e');
      return CaptchaResult(
        isValid: false,
        score: 0.0,
        action: action,
        requiredScore: getRequiredScoreForAction(action),
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// ✅ NOUVEAU: Scénarios de debug par action
  List<double> _getDebugScenariosForAction(String action) {
    switch (action.toLowerCase()) {
      case 'payment':
        // Tests paiement: plus de scores élevés car seuil à 0.8
        return [0.3, 0.6, 0.75, 0.85, 0.95];
        
      case 'booking':
        // Tests réservation: seuil moyen à 0.6
        return [0.2, 0.4, 0.65, 0.8, 0.9];
        
      case 'signup':
        // Tests inscription: seuil élevé à 0.7
        return [0.4, 0.6, 0.75, 0.85, 0.9];
        
      default:
        // Tests génériques: seuil bas à 0.5
        return [0.1, 0.3, 0.6, 0.8, 0.9];
    }
  }

  /// Validation côté serveur avec score adaptatif
  Future<CaptchaResult> _validateWithBackend(String action) async {
    try {
      final requiredScore = getRequiredScoreForAction(action);
      
      if (validationUrl.isEmpty) {
        throw Exception('URL de validation reCAPTCHA non configurée');
      }
      
      final response = await http.post(
        Uri.parse(validationUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': action,
          'siteKey': siteKey,
          'requiredScore': requiredScore, // ✅ Envoyer le score requis
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final score = (data['score'] as num?)?.toDouble() ?? 0.0;
        
        return CaptchaResult(
          isValid: score >= requiredScore,
          score: score,
          action: action,
          requiredScore: requiredScore,
          timestamp: DateTime.now(),
          token: data['token'] as String?,
        );
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur validation backend: $e');
      return CaptchaResult(
        isValid: false,
        score: 0.0,
        action: action,
        requiredScore: getRequiredScoreForAction(action),
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// ✅ AMÉLIORÉ: Vérifier si le CAPTCHA est requis pour cette action
  bool shouldShowCaptcha(String context, {String? identifier}) {
    identifier ??= _getDeviceIdentifier();
    
    switch (context.toLowerCase()) {
      case 'signup':
      case 'inscription':
      case 'registration_particulier':
      case 'registration_pro':
        return true; // Toujours pour l'inscription
        
      case 'login':
      case 'connexion':
        return _shouldShowCaptchaForLogin(identifier);
        
      case 'password_reset':
      case 'forgot_password':
        return true; // Toujours pour reset mot de passe
        
      case 'payment':
      case 'paiement':
        return true; // Toujours pour les paiements (score 0.8)
        
      case 'booking':
      case 'reservation':
        return true; // Toujours pour les réservations (score 0.6)
        
      default:
        return false;
    }
  }

  /// ✅ NOUVEAU: Obtenir le niveau de sécurité selon l'action
  SecurityLevel getSecurityLevelForAction(String action) {
    final requiredScore = getRequiredScoreForAction(action);
    
    if (requiredScore >= 0.8) return SecurityLevel.high;
    if (requiredScore >= 0.6) return SecurityLevel.medium;
    return SecurityLevel.low;
  }

  /// ✅ NOUVEAU: Validation express pour actions critiques
  Future<bool> validateCriticalAction(String action) async {
    final result = await validateInvisibleCaptcha(action);
    
    // Actions critiques nécessitent un score parfait
    final isCritical = ['payment', 'admin_action', 'delete_account'].contains(action.toLowerCase());
    if (isCritical) {
      return result.isValid && result.score >= 0.9;
    }
    
    return result.isValid;
  }

  /// ✅ NOUVEAU: Méthode de commodité pour l'inscription
  Future<CaptchaResult> validateSignup({
    required String userType, // 'particulier' ou 'pro'
    BuildContext? context,
  }) async {
    final action = 'registration_$userType';
    return await validateUserAction(
      action: action,
      context: context,
    );
  }

  /// ✅ NOUVEAU: Méthode de commodité pour la connexion
  Future<CaptchaResult> validateLogin({
    String? identifier,
    BuildContext? context,
  }) async {
    return await validateUserAction(
      action: 'login',
      context: context,
      identifier: identifier,
    );
  }

  /// ✅ NOUVEAU: Méthode de commodité pour les paiements
  Future<CaptchaResult> validatePayment({
    required String paymentType,
    BuildContext? context,
  }) async {
    return await validateUserAction(
      action: 'payment',
      context: context,
    );
  }

  // ========================================
  // MÉTHODES EXISTANTES (inchangées)
  // ========================================

  bool _shouldShowCaptchaForLogin(String identifier) {
    final attempts = _attempts[identifier];
    if (attempts == null) return false;
    
    if (attempts.isLockedOut) return true;
    return attempts.failedCount >= maxLoginAttempts;
  }

  void recordFailedAttempt(String context, {String? identifier}) {
    identifier ??= _getDeviceIdentifier();
    
    final attempts = _attempts[identifier] ?? LoginAttemptData();
    attempts.recordFailure();
    _attempts[identifier] = attempts;
    
    _saveAttemptsToStorage();
  }

  void recordSuccessfulAttempt(String context, {String? identifier}) {
    identifier ??= _getDeviceIdentifier();
    _attempts.remove(identifier);
    _saveAttemptsToStorage();
  }

  Duration? getRemainingLockout({String? identifier}) {
    identifier ??= _getDeviceIdentifier();
    
    final attempts = _attempts[identifier];
    if (attempts?.isLockedOut == true) {
      final remaining = attempts!.lockoutEnd!.difference(DateTime.now());
      return remaining.isNegative ? null : remaining;
    }
    return null;
  }

  String _getDeviceIdentifier() {
    final now = DateTime.now();
    return 'device_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveAttemptsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _attempts.map((key, value) => MapEntry(key, value.toJson()));
      final jsonString = json.encode(data);
      await prefs.setString('captcha_attempts', jsonString);
    } catch (e) {
      print('Erreur sauvegarde tentatives: $e');
    }
  }

  Future<void> loadAttemptsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('captcha_attempts');
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _attempts[key] = LoginAttemptData.fromJson(value);
          }
        });
        print('✅ ${_attempts.length} tentatives chargées depuis le cache');
      }
    } catch (e) {
      print('Erreur chargement tentatives: $e');
      _attempts.clear();
    }
  }

  void cleanupOldAttempts() {
    final now = DateTime.now();
    final before = _attempts.length;
    _attempts.removeWhere((key, attempts) {
      return attempts.lastAttempt.isBefore(now.subtract(const Duration(hours: 24)));
    });
    final after = _attempts.length;
    if (before != after) {
      print('🧹 ${before - after} anciennes tentatives supprimées');
      _saveAttemptsToStorage();
    }
  }

  void resetAllAttempts() {
    _attempts.clear();
    _saveAttemptsToStorage();
    print('🔄 Toutes les tentatives réinitialisées');
  }

  SecurityStats getSecurityStats() {
    final totalAttempts = _attempts.values
        .map((a) => a.failedCount)
        .fold(0, (sum, count) => sum + count);
    
    final lockedDevices = _attempts.values
        .where((a) => a.isLockedOut)
        .length;
    
    return SecurityStats(
      totalFailedAttempts: totalAttempts,
      lockedDevices: lockedDevices,
      uniqueDevices: _attempts.length,
    );
  }

  void debugPrintState() {
    print('🔍 État CaptchaManager:');
    print('  - Site Key: ${siteKey.isNotEmpty ? "${siteKey.substring(0, 10)}..." : "MANQUANTE"}');
    print('  - Payment Score: $paymentMinScore');
    print('  - Booking Score: $bookingMinScore');
    print('  - Signup Score: $signupMinScore');
    print('  - Default Score: $captchaMinScore');
    print('  - Max tentatives: $maxLoginAttempts');
    print('  - Durée blocage: ${lockoutDuration}min');
    print('  - Tentatives en cache: ${_attempts.length}');
  }
}

// ========================================
// CLASSES EXISTANTES MISES À JOUR
// ========================================

class LoginAttemptData {
  int failedCount;
  DateTime lastAttempt;
  DateTime? lockoutEnd;

  LoginAttemptData({
    this.failedCount = 0,
    DateTime? lastAttempt,
    this.lockoutEnd,
  }) : lastAttempt = lastAttempt ?? DateTime.now();

  void recordFailure() {
    failedCount++;
    lastAttempt = DateTime.now();
    
    if (failedCount >= CaptchaManager.maxLoginAttempts) {
      lockoutEnd = DateTime.now().add(
        Duration(minutes: CaptchaManager.lockoutDuration),
      );
    }
  }

  bool get isLockedOut {
    if (lockoutEnd == null) return false;
    return DateTime.now().isBefore(lockoutEnd!);
  }

  Map<String, dynamic> toJson() {
    return {
      'failedCount': failedCount,
      'lastAttempt': lastAttempt.toIso8601String(),
      'lockoutEnd': lockoutEnd?.toIso8601String(),
    };
  }

  factory LoginAttemptData.fromJson(Map<String, dynamic> json) {
    return LoginAttemptData(
      failedCount: json['failedCount'] ?? 0,
      lastAttempt: json['lastAttempt'] != null ? DateTime.parse(json['lastAttempt']) : null,
      lockoutEnd: json['lockoutEnd'] != null ? DateTime.parse(json['lockoutEnd']) : null,
    );
  }
}

/// ✅ AMÉLIORÉ: Résultat de validation CAPTCHA avec score requis
class CaptchaResult {
  final bool isValid;
  final double score;
  final double requiredScore;
  final String action;
  final DateTime timestamp;
  final String? error;
  final String? token;

  CaptchaResult({
    required this.isValid,
    required this.score,
    required this.action,
    required this.requiredScore,
    required this.timestamp,
    this.error,
    this.token,
  });

  bool get isHighConfidence => score >= 0.8;
  bool get isMediumConfidence => score >= 0.6;
  bool get isLowConfidence => score < 0.6;
  
  /// ✅ NOUVEAU: Niveau de confiance adaptatif selon le score requis
  bool get meetsRequirement => score >= requiredScore;
  double get scoreMargin => score - requiredScore;
  
  /// ✅ NOUVEAU: Niveau de sécurité atteint
  SecurityLevel get achievedLevel {
    if (score >= 0.8) return SecurityLevel.high;
    if (score >= 0.6) return SecurityLevel.medium;
    return SecurityLevel.low;
  }

  @override
  String toString() {
    return 'CaptchaResult(valid: $isValid, score: $score/$requiredScore, action: $action)';
  }
}

/// ✅ NOUVEAU: Énumération des niveaux de sécurité
enum SecurityLevel {
  low,    // Score < 0.6
  medium, // Score 0.6-0.79
  high,   // Score >= 0.8
}

class SecurityStats {
  final int totalFailedAttempts;
  final int lockedDevices;
  final int uniqueDevices;

  SecurityStats({
    required this.totalFailedAttempts,
    required this.lockedDevices,
    required this.uniqueDevices,
  });
}