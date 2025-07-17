// test/test_helpers.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../lib/models/user_subscription.dart';

/// Helper pour initialiser Firebase dans les tests
class TestFirebaseHelper {
  static bool _initialized = false;
  
  static Future<void> initializeFirebase() async {
    if (_initialized) return;
    
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock Firebase initialization
    const MethodChannel('plugins.flutter.io/firebase_core')
        .setMockMethodCallHandler((methodCall) async {
      return true;
    });
    
    _initialized = true;
  }
}

/// Factory pour créer des données de test
class TestDataFactory {
  
  /// Créer un abonnement de test
  static UserSubscription createTestSubscription({
    String userId = 'test_user_123',
    SubscriptionType type = SubscriptionType.premium,
    SubscriptionStatus status = SubscriptionStatus.active,
    bool trialActive = false,
    DateTime? startDate,
    DateTime? endDate,
    List<PremiumFeature>? features,
  }) {
    startDate ??= DateTime.now().subtract(const Duration(days: 5));
    endDate ??= DateTime.now().add(const Duration(days: 25));
    features ??= _getFeaturesForType(type);
    
    return UserSubscription(
      userId: userId,
      type: type,
      status: status,
      startDate: startDate,
      endDate: endDate,
      trialActive: trialActive,
      enabledFeatures: features,
      stripeCustomerId: 'cus_test_$userId',
      createdAt: startDate,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Créer un trial de test
  static UserSubscription createTestTrial({
    String userId = 'trial_user_123',
    SubscriptionType targetType = SubscriptionType.premium,
  }) {
    return UserSubscription.createTrial(
      userId: userId,
      targetType: targetType,
      stripeCustomerId: 'cus_trial_$userId',
      sepaSetupIntentId: 'seti_trial_$userId',
    );
  }
  
  /// Créer des détails SEPA de test
  static Map<String, String> createTestSepaDetails({
    String email = 'test@example.com',
    String name = 'Test User',
    String iban = 'FR7630004000031234567890143',
  }) {
    return {
      'email': email,
      'name': name,
      'iban': iban,
    };
  }
  
  /// Features selon le type
  static List<PremiumFeature> _getFeaturesForType(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.free:
        return [];
      case SubscriptionType.standard:
        return [
          PremiumFeature.professionalAgenda,
          PremiumFeature.fractionalPayments,
          PremiumFeature.clientManagement,
          PremiumFeature.advancedAnalytics,
          PremiumFeature.advancedFilters,
        ];
      case SubscriptionType.premium:
        return [
          PremiumFeature.professionalAgenda,
          PremiumFeature.fractionalPayments,
          PremiumFeature.clientManagement,
          PremiumFeature.advancedAnalytics,
          PremiumFeature.advancedFilters,
          PremiumFeature.conventions,
          PremiumFeature.guestApplications,
          PremiumFeature.guestOffers,
          PremiumFeature.flashMinute,
        ];
      case SubscriptionType.enterprise:
        return PremiumFeature.values;
    }
  }
}

/// Matchers personnalisés pour les tests
class CustomMatchers {
  
  /// Matcher pour vérifier qu'un abonnement est valide
  static Matcher isValidSubscription() {
    return predicate<UserSubscription>((subscription) {
      return subscription.hasValidSubscription &&
             subscription.userId.isNotEmpty &&
             subscription.createdAt.isBefore(DateTime.now());
    }, 'is a valid subscription');
  }
  
  /// Matcher pour vérifier qu'un paiement est valide
  static Matcher isValidPaymentResult() {
    return predicate<Map<String, dynamic>>((result) {
      return result['success'] == true &&
             result['totalAmount'] != null &&
             result['kipikCommission'] != null &&
             result['receiverAmount'] != null;
    }, 'is a valid payment result');
  }
  
  /// Matcher pour vérifier les commissions
  static Matcher hasCorrectCommission(double expectedRate) {
    return predicate<Map<String, dynamic>>((result) {
      final total = result['totalAmount'] as double;
      final commission = result['kipikCommission'] as double;
      final actualRate = commission / total;
      
      return (actualRate - expectedRate).abs() < 0.001; // Tolérance de 0.1%
    }, 'has commission rate of ${(expectedRate * 100).toStringAsFixed(1)}%');
  }
}

/// Groupe de tests de performance
class PerformanceTestHelper {
  
  /// Mesurer le temps d'exécution d'une fonction
  static Future<Duration> measureTime(Future<void> Function() action) async {
    final stopwatch = Stopwatch()..start();
    await action();
    stopwatch.stop();
    return stopwatch.elapsed;
  }
  
  /// Tester les performances d'une opération
  static Future<void> testPerformance({
    required String description,
    required Future<void> Function() action,
    required Duration maxDuration,
  }) async {
    final duration = await measureTime(action);
    
    if (duration > maxDuration) {
      throw Exception(
        '$description took ${duration.inMilliseconds}ms, '
        'expected less than ${maxDuration.inMilliseconds}ms'
      );
    }
    
    print('✅ $description: ${duration.inMilliseconds}ms');
  }
}

/// Helper pour les tests de données
class DataTestHelper {
  
  /// Générer des montants de test variés
  static List<double> generateTestAmounts() {
    return [
      0.01,   // Minimum
      1.0,    // Petit
      50.0,   // Moyen petit
      100.0,  // Moyen
      500.0,  // Grand
      1000.0, // Très grand
      5000.0, // Énorme
      9999.99, // Maximum pratique
    ];
  }
  
  /// Générer des utilisateurs de test
  static List<String> generateTestUserIds(int count) {
    return List.generate(count, (index) => 'test_user_${index + 1}');
  }
  
  /// Calculer les statistiques d'un ensemble de paiements
  static Map<String, double> calculatePaymentStats(List<Map<String, dynamic>> payments) {
    if (payments.isEmpty) {
      return {'total': 0.0, 'average': 0.0, 'commission_total': 0.0};
    }
    
    final total = payments.fold(0.0, (sum, p) => sum + (p['amount'] ?? 0.0));
    final commissionTotal = payments.fold(0.0, (sum, p) => sum + (p['commission'] ?? 0.0));
    
    return {
      'total': total,
      'average': total / payments.length,
      'commission_total': commissionTotal,
      'commission_rate': total > 0 ? commissionTotal / total : 0.0,
    };
  }
}

/// Helper pour simuler des erreurs réseau
class NetworkErrorSimulator {
  static bool _shouldSimulateError = false;
  static String? _errorMessage;
  
  static void enableError(String message) {
    _shouldSimulateError = true;
    _errorMessage = message;
  }
  
  static void disableError() {
    _shouldSimulateError = false;
    _errorMessage = null;
  }
  
  static void throwIfEnabled() {
    if (_shouldSimulateError) {
      throw Exception(_errorMessage ?? 'Simulated network error');
    }
  }
}

/// Extension pour les tests
extension UserSubscriptionTestExtension on UserSubscription {
  
  /// Vérifier si l'abonnement est dans un état cohérent
  bool get isStateConsistent {
    // Vérifications de cohérence
    if (trialActive && status != SubscriptionStatus.trial) return false;
    if (status == SubscriptionStatus.active && startDate == null) return false;
    if (status == SubscriptionStatus.expired && endDate != null && endDate!.isAfter(DateTime.now())) return false;
    if (type == SubscriptionType.free && !trialActive && status != SubscriptionStatus.cancelled) return false;
    
    return true;
  }
  
  /// Obtenir un résumé pour les tests
  String get testSummary {
    return '${type.displayName} - ${status.name} - '
           '${trialActive ? "Trial" : "Active"} - '
           '${enabledFeatures.length} features';
  }
}

/// Constantes pour les tests
class TestConstants {
  static const String testUserId = 'test_user_123';
  static const String testTatoueurId = 'tatoueur_456';
  static const String testClientId = 'client_789';
  static const String testOrganisateurId = 'orga_321';
  
  static const double smallAmount = 50.0;
  static const double mediumAmount = 500.0;
  static const double largeAmount = 2000.0;
  
  static const Map<String, String> testSepaDetails = {
    'email': 'test@kipik.com',
    'name': 'Test KIPIK User',
    'iban': 'FR7630004000031234567890143',
  };
  
  static const Duration shortTimeout = Duration(seconds: 1);
  static const Duration mediumTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(seconds: 10);
}