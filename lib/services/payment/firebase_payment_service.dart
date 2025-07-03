// lib/services/payment/firebase_payment_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kipik_v5/models/user_role.dart';
import '../auth/secure_auth_service.dart'; // ✅ CHANGÉ: SecureAuthService au lieu d'AuthService

/// Service de paiement sécurisé utilisant Firebase Functions
/// TOUTES les opérations Stripe sont côté serveur pour la sécurité
class FirebasePaymentService {
  static FirebasePaymentService? _instance;
  static FirebasePaymentService get instance => _instance ??= FirebasePaymentService._();
  FirebasePaymentService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  static const double _platformFeePercentage = 1.0; // 1% commission KIPIK

  /// Payer un abonnement - SÉCURISÉ
  Future<Map<String, dynamic>> paySubscription({
    required String planKey, 
    required bool promoMode
  }) async {
    try {
      // ✅ CHANGÉ: Utiliser SecureAuthService
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Appel sécurisé vers Cloud Function
      final result = await _functions
          .httpsCallable('createSubscriptionPayment')
          .call({
        'planKey': planKey,
        'promoMode': promoMode,
        'userId': user['uid'] ?? user['id'], // ✅ Adaptation pour SecureAuthService
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur paiement abonnement: $e');
    }
  }

  /// Paiement projet - SÉCURISÉ
  Future<Map<String, dynamic>> payProject({
    required String projectId,
    required double amount,
    required String tattooistId,
    String? description,
  }) async {
    try {
      // ✅ CHANGÉ: Utiliser SecureAuthService
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Validation côté client basique
      if (amount <= 0) throw Exception('Montant invalide');
      if (projectId.isEmpty || tattooistId.isEmpty) {
        throw Exception('Données projet invalides');
      }

      // Appel sécurisé vers Cloud Function
      final result = await _functions
          .httpsCallable('createProjectPayment')
          .call({
        'projectId': projectId,
        'amount': amount,
        'tattooistId': tattooistId,
        'description': description ?? 'Paiement projet tatouage',
        'userId': user['uid'] ?? user['id'], // ✅ Adaptation pour SecureAuthService
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur paiement projet: $e');
    }
  }

  /// Paiement acompte (30%) - SÉCURISÉ
  Future<Map<String, dynamic>> payDeposit({
    required String projectId,
    required double totalAmount,
    required String tattooistId,
    double depositPercentage = 0.3,
  }) async {
    final depositAmount = totalAmount * depositPercentage;
    
    return await payProject(
      projectId: projectId,
      amount: depositAmount,
      tattooistId: tattooistId,
      description: 'Acompte ${(depositPercentage * 100).round()}% - Projet $projectId',
    );
  }

  /// Paiement solde final - SÉCURISÉ
  Future<Map<String, dynamic>> payFinalBalance({
    required String projectId,
    required double totalAmount,
    required double depositAmount,
    required String tattooistId,
  }) async {
    final finalAmount = totalAmount - depositAmount;
    
    if (finalAmount <= 0) {
      throw Exception('Solde final invalide');
    }
    
    return await payProject(
      projectId: projectId,
      amount: finalAmount,
      tattooistId: tattooistId,
      description: 'Solde final - Projet $projectId',
    );
  }

  /// Créer compte Stripe Connect - SÉCURISÉ
  Future<Map<String, dynamic>> createTattooistAccount({
    required String email,
    required String businessName,
    String country = 'FR',
  }) async {
    try {
      // ✅ CHANGÉ: Utiliser SecureAuthService
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final result = await _functions
          .httpsCallable('createStripeAccount')
          .call({
        'email': email,
        'businessName': businessName,
        'country': country,
        'userId': user['uid'] ?? user['id'], // ✅ Adaptation pour SecureAuthService
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur création compte: $e');
    }
  }

  /// Créer lien d'onboarding - SÉCURISÉ
  Future<String> createOnboardingLink({
    String? returnUrl,
    String? refreshUrl,
  }) async {
    try {
      // ✅ CHANGÉ: Utiliser SecureAuthService
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final result = await _functions
          .httpsCallable('createOnboardingLink')
          .call({
        'returnUrl': returnUrl ?? 'https://kipik.app/onboarding/success',
        'refreshUrl': refreshUrl ?? 'https://kipik.app/onboarding/refresh',
        'userId': user['uid'] ?? user['id'], // ✅ Adaptation pour SecureAuthService
      });

      return result.data['url'] as String;
    } catch (e) {
      throw Exception('Erreur lien onboarding: $e');
    }
  }

  /// Dashboard Stripe Connect - SÉCURISÉ
  Future<String> createDashboardLink() async {
    try {
      // ✅ CHANGÉ: Utiliser SecureAuthService
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final result = await _functions
          .httpsCallable('createDashboardLink')
          .call({'userId': user['uid'] ?? user['id']}); // ✅ Adaptation pour SecureAuthService

      return result.data['url'] as String;
    } catch (e) {
      throw Exception('Erreur dashboard: $e');
    }
  }

  /// Statut compte Stripe - SÉCURISÉ (lecture seule)
  Future<Map<String, dynamic>?> getAccountStatus() async {
    try {
      // ✅ CHANGÉ: Utiliser SecureAuthService
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return null;

      final userId = user['uid'] ?? user['id'];
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'hasStripeAccount': data['stripeAccountId'] != null,
        'accountStatus': data['stripeAccountStatus'] ?? 'none',
        'accountCreatedAt': data['stripeAccountCreatedAt'],
        'canReceivePayments': data['stripeAccountStatus'] == 'active',
      };
    } catch (e) {
      return null;
    }
  }

  /// Remboursement - SÉCURISÉ
  Future<void> requestRefund({
    required String paymentId,
    String? reason,
    double? amount,
  }) async {
    try {
      // ✅ CHANGÉ: Utiliser SecureAuthService
      final user = SecureAuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _functions
          .httpsCallable('requestRefund')
          .call({
        'paymentId': paymentId,
        'reason': reason ?? 'requested_by_customer',
        'amount': amount,
        'userId': user['uid'] ?? user['id'], // ✅ Adaptation pour SecureAuthService
      });
    } catch (e) {
      throw Exception('Erreur demande remboursement: $e');
    }
  }

  /// Historique paiements utilisateur - SÉCURISÉ
  Future<List<Map<String, dynamic>>> getUserPayments({int limit = 20}) async {
    try {
      // ✅ CHANGÉ: Utiliser SecureAuthService
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return [];

      final userId = user['uid'] ?? user['id'];
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Conversion sécurisée des timestamps
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        
        // Masquer les données sensibles
        data.remove('stripePaymentIntentId');
        data.remove('stripeAccountId');
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur historique paiements: $e');
    }
  }

  /// Paiements d'un projet - SÉCURISÉ
  Future<List<Map<String, dynamic>>> getProjectPayments(String projectId) async {
    try {
      // ✅ CHANGÉ: Utiliser SecureAuthService
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return [];

      final userId = user['uid'] ?? user['id'];
      if (userId == null) return [];

      // Vérifier que l'utilisateur a accès au projet
      final projectDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .get();

      if (!projectDoc.exists) throw Exception('Projet introuvable');

      final projectData = projectDoc.data()!;
      final isOwner = projectData['userId'] == userId;
      final isTattooist = projectData['tattooistId'] == userId;

      if (!isOwner && !isTattooist) {
        throw Exception('Accès non autorisé');
      }

      final snapshot = await _firestore
          .collection('transactions')
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        
        // Masquer données sensibles
        data.remove('stripePaymentIntentId');
        data.remove('stripeAccountId');
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur paiements projet: $e');
    }
  }

  /// Statistiques tatoueur - SÉCURISÉ
  Future<Map<String, dynamic>?> getTattooistStats() async {
    try {
      // ✅ CHANGÉ: Utiliser SecureAuthService
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return null;

      final result = await _functions
          .httpsCallable('getTattooistStats')
          .call({'userId': user['uid'] ?? user['id']}); // ✅ Adaptation pour SecureAuthService

      return result.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Revenus mensuels - SÉCURISÉ
  Future<List<Map<String, dynamic>>> getMonthlyEarnings(int year) async {
    try {
      // ✅ CHANGÉ: Utiliser SecureAuthService
      final user = SecureAuthService.instance.currentUser;
      if (user == null) return [];

      final result = await _functions
          .httpsCallable('getMonthlyEarnings')
          .call({
        'userId': user['uid'] ?? user['id'], // ✅ Adaptation pour SecureAuthService
        'year': year,
      });

      return List<Map<String, dynamic>>.from(result.data['earnings']);
    } catch (e) {
      return [];
    }
  }

  /// Écouter les changements de statut de paiement
  Stream<Map<String, dynamic>?> watchPaymentStatus(String paymentId) {
    return _firestore
        .collection('transactions')
        .doc(paymentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      
      // Masquer données sensibles
      data.remove('stripePaymentIntentId');
      data.remove('stripeAccountId');
      
      return data;
    });
  }

  /// Vérifier si l'utilisateur peut recevoir des paiements
  Future<bool> canReceivePayments() async {
    try {
      final status = await getAccountStatus();
      return status?['canReceivePayments'] == true;
    } catch (e) {
      return false;
    }
  }

  /// ✅ NOUVEAU: Obtenir l'ID utilisateur actuel de manière sécurisée
  String? _getCurrentUserId() {
    final user = SecureAuthService.instance.currentUser;
    if (user == null) return null;
    return user['uid'] ?? user['id'];
  }

  /// ✅ NOUVEAU: Vérifier si l'utilisateur est connecté
  bool get isUserAuthenticated {
    return SecureAuthService.instance.isAuthenticated;
  }

  /// ✅ NOUVEAU: Obtenir le rôle de l'utilisateur pour les permissions
  UserRole? get currentUserRole {
    return SecureAuthService.instance.currentUserRole;
  }

  /// Calculer les frais de la plateforme
  static double calculatePlatformFee(double amount) {
    return (amount * _platformFeePercentage / 100);
  }

  /// Calculer le montant que recevra le tatoueur
  static double calculateTattooistAmount(double totalAmount) {
    return totalAmount - calculatePlatformFee(totalAmount);
  }

  /// ✅ NOUVEAU: Validation des permissions pour les paiements
  bool canProcessPayments() {
    if (!isUserAuthenticated) return false;
    
    final role = currentUserRole;
    return role == UserRole.client || 
           role == UserRole.tatoueur || 
           role == UserRole.admin;
  }

  /// ✅ NOUVEAU: Validation des permissions pour les statistiques
  bool canViewStats() {
    if (!isUserAuthenticated) return false;
    
    final role = currentUserRole;
    return role == UserRole.tatoueur || 
           role == UserRole.admin;
  }

  /// ✅ NOUVEAU: Validation des permissions pour les comptes Stripe
  bool canManageStripeAccount() {
    if (!isUserAuthenticated) return false;
    
    final role = currentUserRole;
    return role == UserRole.tatoueur || 
           role == UserRole.admin;
  }
}