// lib/services/payment/firebase_payment_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/auth_service.dart';

class FirebasePaymentService {
  static FirebasePaymentService? _instance;
  static FirebasePaymentService get instance => _instance ??= FirebasePaymentService._();
  FirebasePaymentService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? '';
  
  static const String _baseUrl = 'https://api.stripe.com/v1';
  static const double _platformFeePercentage = 1.0; // 1% de commission KIPIK

  /// Payer un abonnement
  Future<bool> pay({required String planKey, required bool promoMode}) async {
    try {
      // Récupérer les infos du plan/abonnement
      final planData = await _getPlanData(planKey);
      final amount = promoMode ? planData['promoPrice'] : planData['price'];
      
      // Créer le Payment Intent pour l'abonnement
      final paymentIntent = await _createPaymentIntent(
        amount: (amount * 100).round(), // Stripe utilise les centimes
        currency: 'eur',
        description: 'Abonnement KIPIK - $planKey',
        metadata: {
          'plan_key': planKey,
          'promo_mode': promoMode.toString(),
          'type': 'subscription',
        },
      );
      
      // Enregistrer la transaction
      await _recordTransaction({
        'type': 'subscription',
        'planKey': planKey,
        'amount': amount,
        'promoMode': promoMode,
        'stripePaymentIntentId': paymentIntent['id'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return paymentIntent['status'] == 'succeeded';
    } catch (e) {
      throw Exception('Erreur paiement abonnement: $e');
    }
  }

  /// Paiement projet avec répartition automatique tatoueur
  Future<Map<String, dynamic>> payProject({
    required String projectId,
    required double totalAmount,
    required String tattooistId,
    String description = 'Paiement projet tatouage',
  }) async {
    try {
      // Récupérer le compte Stripe du tatoueur
      final tattooistData = await _getTattooistData(tattooistId);
      final stripeAccountId = tattooistData['stripeAccountId'] as String?;
      
      if (stripeAccountId == null) {
        throw Exception('Le tatoueur doit d\'abord configurer son compte de paiement');
      }

      // Calculer la commission KIPIK (1%)
      final platformFee = (totalAmount * _platformFeePercentage / 100 * 100).round();
      
      // Créer le Payment Intent avec transfert automatique
      final paymentIntent = await _createPaymentIntentWithTransfer(
        amount: (totalAmount * 100).round(),
        currency: 'eur',
        description: description,
        destinationAccountId: stripeAccountId,
        applicationFeeAmount: platformFee,
        metadata: {
          'project_id': projectId,
          'tattooist_id': tattooistId,
          'type': 'project_payment',
          'platform_fee': (platformFee / 100).toString(),
        },
      );

      // Enregistrer la transaction
      await _recordTransaction({
        'type': 'project_payment',
        'projectId': projectId,
        'tattooistId': tattooistId,
        'totalAmount': totalAmount,
        'platformFee': platformFee / 100,
        'tattooistAmount': (totalAmount - (platformFee / 100)),
        'stripePaymentIntentId': paymentIntent['id'],
        'stripeAccountId': stripeAccountId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return paymentIntent;
    } catch (e) {
      throw Exception('Erreur paiement projet: $e');
    }
  }

  /// Créer un paiement d'acompte (30% du projet)
  Future<Map<String, dynamic>> payDeposit({
    required String projectId,
    required double totalAmount,
    required String tattooistId,
    double depositPercentage = 0.3, // 30% par défaut
  }) async {
    final depositAmount = totalAmount * depositPercentage;
    
    return await payProject(
      projectId: projectId,
      totalAmount: depositAmount,
      tattooistId: tattooistId,
      description: 'Acompte projet tatouage (${(depositPercentage * 100).round()}%)',
    );
  }

  /// Paiement solde final d'un projet
  Future<Map<String, dynamic>> payFinalBalance({
    required String projectId,
    required double totalAmount,
    required double depositAmount,
    required String tattooistId,
  }) async {
    final finalAmount = totalAmount - depositAmount;
    
    if (finalAmount <= 0) {
      throw Exception('Le solde final doit être positif');
    }
    
    return await payProject(
      projectId: projectId,
      totalAmount: finalAmount,
      tattooistId: tattooistId,
      description: 'Solde final projet tatouage',
    );
  }

  /// Créer un compte Stripe Connect pour un tatoueur
  Future<String> createTattooistStripeAccount({
    required String tattooistId,
    required String email,
    required String businessName,
    required String country = 'FR',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/accounts'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'type': 'express',
          'country': country,
          'email': email,
          'business_type': 'individual',
          'business_profile[name]': businessName,
          'business_profile[mcc]': '7230', // MCC pour services de beauté/tatouage
          'capabilities[card_payments][requested]': 'true',
          'capabilities[transfers][requested]': 'true',
          'metadata[tattooist_id]': tattooistId,
          'metadata[platform]': 'kipik',
        },
      );

      if (response.statusCode == 200) {
        final accountData = json.decode(response.body);
        final accountId = accountData['id'];

        // Sauvegarder dans Firestore
        await _firestore.collection('users').doc(tattooistId).update({
          'stripeAccountId': accountId,
          'stripeAccountStatus': 'pending',
          'stripeAccountCreatedAt': FieldValue.serverTimestamp(),
        });

        return accountId;
      } else {
        throw Exception('Erreur création compte Stripe: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur création compte Connect: $e');
    }
  }

  /// Créer le lien d'onboarding Stripe pour finaliser le compte
  Future<String> createOnboardingLink(
    String accountId, {
    String? returnUrl,
    String? refreshUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/account_links'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'account': accountId,
          'refresh_url': refreshUrl ?? 'https://kipik.app/stripe/refresh',
          'return_url': returnUrl ?? 'https://kipik.app/stripe/success',
          'type': 'account_onboarding',
        },
      );

      if (response.statusCode == 200) {
        final linkData = json.decode(response.body);
        return linkData['url'];
      } else {
        throw Exception('Erreur lien onboarding: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lien onboarding: $e');
    }
  }

  /// Créer un lien de dashboard pour que le tatoueur gère son compte
  Future<String> createDashboardLink(String accountId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/account_links'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'account': accountId,
          'type': 'account_management',
        },
      );

      if (response.statusCode == 200) {
        final linkData = json.decode(response.body);
        return linkData['url'];
      } else {
        throw Exception('Erreur lien dashboard: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lien dashboard: $e');
    }
  }

  /// Vérifier le statut d'un compte Stripe
  Future<Map<String, dynamic>> getAccountStatus(String accountId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/accounts/$accountId'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur statut compte: ${response.body}');
    }
  }

  /// Obtenir l'historique des paiements d'un tatoueur
  Future<List<Map<String, dynamic>>> getTattooistPayments(String tattooistId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('tattooistId', isEqualTo: tattooistId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Convertir les Timestamps
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération paiements: $e');
    }
  }

  /// Obtenir l'historique des paiements d'un projet
  Future<List<Map<String, dynamic>>> getProjectPayments(String projectId) async {
    try {
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
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération paiements projet: $e');
    }
  }

  /// Créer un remboursement
  Future<void> refundPayment(
    String paymentIntentId, {
    double? amount,
    String? reason,
  }) async {
    try {
      final body = <String, String>{
        'payment_intent': paymentIntentId,
      };

      if (amount != null) {
        body['amount'] = (amount * 100).round().toString();
      }

      if (reason != null) {
        body['reason'] = reason; // 'duplicate', 'fraudulent', 'requested_by_customer'
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/refunds'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final refundData = json.decode(response.body);
        
        // Enregistrer le remboursement
        await _firestore.collection('refunds').add({
          'stripeRefundId': refundData['id'],
          'paymentIntentId': paymentIntentId,
          'amount': (refundData['amount'] as int) / 100,
          'reason': reason ?? 'requested_by_customer',
          'status': refundData['status'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('Erreur remboursement: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur remboursement: $e');
    }
  }

  /// Traiter les webhooks Stripe
  Future<void> handleWebhook(Map<String, dynamic> event) async {
    try {
      final eventType = event['type'] as String;
      final eventData = event['data']['object'] as Map<String, dynamic>;

      switch (eventType) {
        case 'payment_intent.succeeded':
          await _handlePaymentSucceeded(eventData);
          break;
        case 'payment_intent.payment_failed':
          await _handlePaymentFailed(eventData);
          break;
        case 'account.updated':
          await _handleAccountUpdated(eventData);
          break;
        case 'transfer.created':
          await _handleTransferCreated(eventData);
          break;
        case 'invoice.payment_succeeded':
          await _handleInvoicePaymentSucceeded(eventData);
          break;
        case 'customer.subscription.updated':
          await _handleSubscriptionUpdated(eventData);
          break;
        default:
          print('Webhook non géré: $eventType');
      }
    } catch (e) {
      print('Erreur traitement webhook: $e');
    }
  }

  /// Obtenir les statistiques de paiement pour un tatoueur
  Future<Map<String, dynamic>> getTattooistPaymentStats(String tattooistId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('tattooistId', isEqualTo: tattooistId)
          .where('status', isEqualTo: 'succeeded')
          .get();

      double totalEarnings = 0;
      double totalFees = 0;
      int totalTransactions = snapshot.docs.length;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalEarnings += (data['tattooistAmount'] as num?)?.toDouble() ?? 0;
        totalFees += (data['platformFee'] as num?)?.toDouble() ?? 0;
      }

      return {
        'totalEarnings': totalEarnings,
        'totalFees': totalFees,
        'totalTransactions': totalTransactions,
        'averageTransaction': totalTransactions > 0 ? totalEarnings / totalTransactions : 0,
      };
    } catch (e) {
      throw Exception('Erreur statistiques paiement: $e');
    }
  }

  /// Obtenir les revenus mensuels d'un tatoueur
  Future<List<Map<String, dynamic>>> getMonthlyEarnings(String tattooistId, int year) async {
    try {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year + 1, 1, 1);
      
      final snapshot = await _firestore
          .collection('transactions')
          .where('tattooistId', isEqualTo: tattooistId)
          .where('status', isEqualTo: 'succeeded')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfYear))
          .orderBy('createdAt')
          .get();

      final monthlyData = <int, double>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['createdAt'] as Timestamp).toDate();
        final amount = (data['tattooistAmount'] as num?)?.toDouble() ?? 0;
        
        monthlyData[date.month] = (monthlyData[date.month] ?? 0) + amount;
      }

      return List.generate(12, (index) {
        final month = index + 1;
        return {
          'month': month,
          'earnings': monthlyData[month] ?? 0.0,
        };
      });
    } catch (e) {
      throw Exception('Erreur revenus mensuels: $e');
    }
  }

  // MÉTHODES PRIVÉES

  /// Créer un Payment Intent simple (abonnements)
  Future<Map<String, dynamic>> _createPaymentIntent({
    required int amount,
    required String currency,
    required String description,
    Map<String, String>? metadata,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payment_intents'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amount.toString(),
        'currency': currency,
        'description': description,
        'automatic_payment_methods[enabled]': 'true',
        if (metadata != null) 
          ...metadata.entries.map((e) => MapEntry('metadata[${e.key}]', e.value)),
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur Stripe: ${response.body}');
    }
  }

  /// Créer un Payment Intent avec transfert automatique (projets)
  Future<Map<String, dynamic>> _createPaymentIntentWithTransfer({
    required int amount,
    required String currency,
    required String description,
    required String destinationAccountId,
    required int applicationFeeAmount,
    Map<String, String>? metadata,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payment_intents'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amount.toString(),
        'currency': currency,
        'description': description,
        'application_fee_amount': applicationFeeAmount.toString(),
        'transfer_data[destination]': destinationAccountId,
        'automatic_payment_methods[enabled]': 'true',
        if (metadata != null) 
          ...metadata.entries.map((e) => MapEntry('metadata[${e.key}]', e.value)),
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur Stripe Connect: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _getPlanData(String planKey) async {
    final doc = await _firestore.collection('plans').doc(planKey).get();
    if (!doc.exists) throw Exception('Plan introuvable: $planKey');
    return doc.data()!;
  }

  Future<Map<String, dynamic>> _getTattooistData(String tattooistId) async {
    final doc = await _firestore.collection('users').doc(tattooistId).get();
    if (!doc.exists) throw Exception('Tatoueur introuvable: $tattooistId');
    return doc.data()!;
  }

  Future<void> _recordTransaction(Map<String, dynamic> transactionData) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser != null) {
      transactionData['userId'] = currentUser.uid;
    }
    
    await _firestore.collection('transactions').add(transactionData);
  }

  Future<void> _handlePaymentSucceeded(Map<String, dynamic> paymentIntent) async {
    final metadata = paymentIntent['metadata'] as Map<String, dynamic>?;
    
    if (metadata?['type'] == 'project_payment') {
      final projectId = metadata?['project_id'];
      if (projectId != null) {
        await _firestore.collection('projects').doc(projectId).update({
          'paymentStatus': 'paid',
          'paidAt': FieldValue.serverTimestamp(),
        });
      }
    } else if (metadata?['type'] == 'subscription') {
      final userId = AuthService.instance.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'subscriptionStatus': 'active',
          'subscriptionActivatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Mettre à jour la transaction
    await _updateTransactionStatus(paymentIntent['id'], 'succeeded');
  }

  Future<void> _handlePaymentFailed(Map<String, dynamic> paymentIntent) async {
    final metadata = paymentIntent['metadata'] as Map<String, dynamic>?;
    
    if (metadata?['type'] == 'project_payment') {
      final projectId = metadata?['project_id'];
      if (projectId != null) {
        await _firestore.collection('projects').doc(projectId).update({
          'paymentStatus': 'failed',
          'paymentFailedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Mettre à jour la transaction
    await _updateTransactionStatus(paymentIntent['id'], 'failed');
  }

  Future<void> _handleAccountUpdated(Map<String, dynamic> account) async {
    final tattooistId = account['metadata']?['tattooist_id'];
    if (tattooistId != null) {
      await _firestore.collection('users').doc(tattooistId).update({
        'stripeAccountStatus': account['details_submitted'] ? 'active' : 'pending',
        'stripeAccountUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _handleTransferCreated(Map<String, dynamic> transfer) async {
    // Enregistrer le transfert
    await _firestore.collection('transfers').add({
      'stripeTransferId': transfer['id'],
      'amount': (transfer['amount'] as int) / 100,
      'destination': transfer['destination'],
      'description': transfer['description'],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleInvoicePaymentSucceeded(Map<String, dynamic> invoice) async {
    // Gérer les paiements de factures récurrentes
    final customerId = invoice['customer'];
    // Logique pour les abonnements récurrents
  }

  Future<void> _handleSubscriptionUpdated(Map<String, dynamic> subscription) async {
    // Gérer les mises à jour d'abonnements
    final status = subscription['status'];
    // Mettre à jour le statut d'abonnement de l'utilisateur
  }

  Future<void> _updateTransactionStatus(String paymentIntentId, String status) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('stripePaymentIntentId', isEqualTo: paymentIntentId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}