// lib/models/payment_models.dart

import 'package:flutter/material.dart';
import 'user_subscription.dart';

/// Modèles pour le système de paiement KIPIK
/// Support: Paiement simple, fractionné, SEPA, Stripe

// ===== PAIEMENTS FRACTIONNÉS =====

/// Option de paiement fractionné disponible
class FractionalPaymentOption {
  final int installments; // 2, 3, ou 4 fois
  final double installmentAmount; // Montant par échéance
  final double totalAmount; // Montant total
  final List<PaymentSchedule> paymentSchedule; // Planning des paiements
  final bool isRecommended; // Option recommandée
  final SubscriptionType minimumSubscriptionRequired; // Abonnement minimum requis

  FractionalPaymentOption({
    required this.installments,
    required this.installmentAmount,
    required this.totalAmount,
    required this.paymentSchedule,
    this.isRecommended = false,
    required this.minimumSubscriptionRequired,
  });

  factory FractionalPaymentOption.fromJson(Map<String, dynamic> json) {
    return FractionalPaymentOption(
      installments: json['installments'] ?? 2,
      installmentAmount: (json['installmentAmount'] ?? 0.0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      paymentSchedule: (json['paymentSchedule'] as List?)
          ?.map((e) => PaymentSchedule.fromJson(e))
          .toList() ?? [],
      isRecommended: json['isRecommended'] ?? false,
      minimumSubscriptionRequired: SubscriptionType.values.firstWhere(
        (type) => type.name == json['minimumSubscriptionRequired'],
        orElse: () => SubscriptionType.standard,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'installments': installments,
      'installmentAmount': installmentAmount,
      'totalAmount': totalAmount,
      'paymentSchedule': paymentSchedule.map((e) => e.toJson()).toList(),
      'isRecommended': isRecommended,
      'minimumSubscriptionRequired': minimumSubscriptionRequired.name,
    };
  }

  /// Génère les options de paiement selon l'abonnement du tatoueur
  static List<FractionalPaymentOption> generateOptions({
    required double totalAmount,
    required SubscriptionType artistSubscription,
    double minimumAmount = 50.0,
  }) {
    final options = <FractionalPaymentOption>[];
    
    // Vérifier montant minimum
    if (totalAmount < minimumAmount) return options;

    // 2x - Disponible dès Standard
    if (artistSubscription.index >= SubscriptionType.standard.index) {
      options.add(_createOption(
        totalAmount: totalAmount,
        installments: 2,
        minimumSubscription: SubscriptionType.standard,
        isRecommended: true,
      ));
    }

    // 3x - Disponible dès Premium
    if (artistSubscription.index >= SubscriptionType.premium.index) {
      options.add(_createOption(
        totalAmount: totalAmount,
        installments: 3,
        minimumSubscription: SubscriptionType.premium,
      ));
    }

    // 4x - Disponible dès Premium (montant > 200€)
    if (artistSubscription.index >= SubscriptionType.premium.index && totalAmount >= 200.0) {
      options.add(_createOption(
        totalAmount: totalAmount,
        installments: 4,
        minimumSubscription: SubscriptionType.premium,
      ));
    }

    return options;
  }

  static FractionalPaymentOption _createOption({
    required double totalAmount,
    required int installments,
    required SubscriptionType minimumSubscription,
    bool isRecommended = false,
  }) {
    final installmentAmount = totalAmount / installments;
    final schedule = <PaymentSchedule>[];
    final now = DateTime.now();

    for (int i = 0; i < installments; i++) {
      schedule.add(PaymentSchedule(
        installmentNumber: i + 1,
        amount: installmentAmount,
        dueDate: i == 0 ? now : now.add(Duration(days: 30 * i)),
        status: i == 0 ? PaymentScheduleStatus.pending : PaymentScheduleStatus.scheduled,
      ));
    }

    return FractionalPaymentOption(
      installments: installments,
      installmentAmount: installmentAmount,
      totalAmount: totalAmount,
      paymentSchedule: schedule,
      isRecommended: isRecommended,
      minimumSubscriptionRequired: minimumSubscription,
    );
  }
}

/// Planning d'un paiement fractionné
class PaymentSchedule {
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final PaymentScheduleStatus status;
  final String? transactionId;
  final DateTime? paidAt;

  PaymentSchedule({
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.transactionId,
    this.paidAt,
  });

  factory PaymentSchedule.fromJson(Map<String, dynamic> json) {
    return PaymentSchedule(
      installmentNumber: json['installmentNumber'] ?? 1,
      amount: (json['amount'] ?? 0.0).toDouble(),
      dueDate: DateTime.parse(json['dueDate']),
      status: PaymentScheduleStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PaymentScheduleStatus.scheduled,
      ),
      transactionId: json['transactionId'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'installmentNumber': installmentNumber,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'transactionId': transactionId,
      'paidAt': paidAt?.toIso8601String(),
    };
  }
}

enum PaymentScheduleStatus {
  scheduled,   // Programmé
  pending,     // En attente de paiement
  processing,  // En cours de traitement
  paid,        // Payé
  failed,      // Échec
  cancelled,   // Annulé
}

// ===== RÉSULTATS DE PAIEMENT =====

/// Résultat d'un processus de paiement
class PaymentResult {
  final bool success;
  final String transactionId;
  final double totalAmount;
  final String currency;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  PaymentResult({
    required this.success,
    required this.transactionId,
    required this.totalAmount,
    this.currency = 'EUR',
    required this.status,
    required this.createdAt,
    this.errorMessage,
    this.metadata,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] ?? false,
      transactionId: json['transactionId'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      status: PaymentStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PaymentStatus.failed,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      errorMessage: json['errorMessage'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transactionId': transactionId,
      'totalAmount': totalAmount,
      'currency': currency,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }
}

enum PaymentStatus {
  pending,      // En attente
  processing,   // En cours
  succeeded,    // Réussi
  failed,       // Échec
  cancelled,    // Annulé
  refunded,     // Remboursé
}

// ===== COMPTES STRIPE =====

/// Informations du compte Stripe d'un tatoueur
class StripeAccount {
  final String accountId;
  final String email;
  final String businessName;
  final String country;
  final StripeAccountStatus status;
  final bool canReceivePayments;
  final DateTime createdAt;
  final Map<String, dynamic>? requirements;
  final StripeAccountMetrics? metrics;

  StripeAccount({
    required this.accountId,
    required this.email,
    required this.businessName,
    this.country = 'FR',
    required this.status,
    required this.canReceivePayments,
    required this.createdAt,
    this.requirements,
    this.metrics,
  });

  factory StripeAccount.fromJson(Map<String, dynamic> json) {
    return StripeAccount(
      accountId: json['accountId'] ?? '',
      email: json['email'] ?? '',
      businessName: json['businessName'] ?? '',
      country: json['country'] ?? 'FR',
      status: StripeAccountStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => StripeAccountStatus.pending,
      ),
      canReceivePayments: json['canReceivePayments'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      requirements: json['requirements'],
      metrics: json['metrics'] != null 
          ? StripeAccountMetrics.fromJson(json['metrics'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'email': email,
      'businessName': businessName,
      'country': country,
      'status': status.name,
      'canReceivePayments': canReceivePayments,
      'createdAt': createdAt.toIso8601String(),
      'requirements': requirements,
      'metrics': metrics?.toJson(),
    };
  }
}

enum StripeAccountStatus {
  none,         // Pas de compte
  pending,      // En cours de création
  restricted,   // Restreint (onboarding incomplet)
  active,       // Actif
  suspended,    // Suspendu
}

/// Métriques d'un compte Stripe
class StripeAccountMetrics {
  final double totalEarnings;
  final double thisMonthEarnings;
  final int totalTransactions;
  final int thisMonthTransactions;
  final double averageOrderValue;
  final DateTime lastUpdated;

  StripeAccountMetrics({
    required this.totalEarnings,
    required this.thisMonthEarnings,
    required this.totalTransactions,
    required this.thisMonthTransactions,
    required this.averageOrderValue,
    required this.lastUpdated,
  });

  factory StripeAccountMetrics.fromJson(Map<String, dynamic> json) {
    return StripeAccountMetrics(
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      thisMonthEarnings: (json['thisMonthEarnings'] ?? 0.0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      thisMonthTransactions: json['thisMonthTransactions'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEarnings': totalEarnings,
      'thisMonthEarnings': thisMonthEarnings,
      'totalTransactions': totalTransactions,
      'thisMonthTransactions': thisMonthTransactions,
      'averageOrderValue': averageOrderValue,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

// ===== TRANSACTIONS =====

/// Transaction de paiement complète
class PaymentTransaction {
  final String id;
  final String userId;
  final String? projectId;
  final String? artistId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentType type;
  final String description;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? stripePaymentIntentId;
  final String? stripeAccountId;
  final double platformFee;
  final double artistAmount;
  final Map<String, dynamic>? metadata;

  PaymentTransaction({
    required this.id,
    required this.userId,
    this.projectId,
    this.artistId,
    required this.amount,
    this.currency = 'EUR',
    required this.status,
    required this.type,
    required this.description,
    required this.createdAt,
    this.paidAt,
    this.stripePaymentIntentId,
    this.stripeAccountId,
    required this.platformFee,
    required this.artistAmount,
    this.metadata,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      projectId: json['projectId'],
      artistId: json['artistId'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      status: PaymentStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      type: PaymentType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => PaymentType.project,
      ),
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      stripePaymentIntentId: json['stripePaymentIntentId'],
      stripeAccountId: json['stripeAccountId'],
      platformFee: (json['platformFee'] ?? 0.0).toDouble(),
      artistAmount: (json['artistAmount'] ?? 0.0).toDouble(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'projectId': projectId,
      'artistId': artistId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'type': type.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeAccountId': stripeAccountId,
      'platformFee': platformFee,
      'artistAmount': artistAmount,
      'metadata': metadata,
    };
  }
}

enum PaymentType {
  project,      // Paiement de projet
  subscription, // Abonnement
  deposit,      // Acompte
  balance,      // Solde
  fractional,   // Paiement fractionné
  refund,       // Remboursement
}

// ===== GESTION SEPA =====

/// Informations SEPA pour prélèvements automatiques
class SepaMandate {
  final String mandateId;
  final String userId;
  final String iban;
  final String bic;
  final String accountHolderName;
  final SepaMandateStatus status;
  final DateTime createdAt;
  final DateTime? signedAt;
  final DateTime? revokedAt;
  final String? revokeReason;

  SepaMandate({
    required this.mandateId,
    required this.userId,
    required this.iban,
    required this.bic,
    required this.accountHolderName,
    required this.status,
    required this.createdAt,
    this.signedAt,
    this.revokedAt,
    this.revokeReason,
  });

  factory SepaMandate.fromJson(Map<String, dynamic> json) {
    return SepaMandate(
      mandateId: json['mandateId'] ?? '',
      userId: json['userId'] ?? '',
      iban: json['iban'] ?? '',
      bic: json['bic'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      status: SepaMandateStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => SepaMandateStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      signedAt: json['signedAt'] != null ? DateTime.parse(json['signedAt']) : null,
      revokedAt: json['revokedAt'] != null ? DateTime.parse(json['revokedAt']) : null,
      revokeReason: json['revokeReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mandateId': mandateId,
      'userId': userId,
      'iban': iban,
      'bic': bic,
      'accountHolderName': accountHolderName,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'signedAt': signedAt?.toIso8601String(),
      'revokedAt': revokedAt?.toIso8601String(),
      'revokeReason': revokeReason,
    };
  }

  /// Masquer l'IBAN pour l'affichage (ne montrer que les 4 derniers chiffres)
  String get maskedIban {
    if (iban.length <= 4) return iban;
    return '****${iban.substring(iban.length - 4)}';
  }
}

enum SepaMandateStatus {
  pending,      // En attente de signature
  active,       // Actif
  revoked,      // Révoqué
  expired,      // Expiré
}

// ===== UTILITAIRES =====

/// Utilitaires pour les calculs de paiement
class PaymentUtils {
  /// Commission KIPIK selon l'abonnement
  static double getCommissionRate(SubscriptionType subscriptionType) {
    switch (subscriptionType) {
      case SubscriptionType.free:
        return 0.025; // 2.5%
      case SubscriptionType.standard:
        return 0.02;  // 2%
      case SubscriptionType.premium:
        return 0.01;  // 1%
      case SubscriptionType.enterprise:
        return 0.005; // 0.5%
    }
  }

  /// Calculer la commission KIPIK
  static double calculatePlatformFee(double amount, SubscriptionType subscriptionType) {
    return amount * getCommissionRate(subscriptionType);
  }

  /// Calculer le montant pour l'artiste
  static double calculateArtistAmount(double amount, SubscriptionType subscriptionType) {
    return amount - calculatePlatformFee(amount, subscriptionType);
  }

  /// Valider un IBAN
  static bool isValidIban(String iban) {
    final cleanIban = iban.replaceAll(' ', '').toUpperCase();
    if (cleanIban.length < 15 || cleanIban.length > 34) return false;
    
    // Vérification basique du format français
    if (cleanIban.startsWith('FR')) {
      return cleanIban.length == 27;
    }
    
    return true; // Validation basique pour les autres pays
  }

  /// Formater un IBAN pour l'affichage
  static String formatIban(String iban) {
    final cleanIban = iban.replaceAll(' ', '').toUpperCase();
    final formatted = StringBuffer();
    
    for (int i = 0; i < cleanIban.length; i += 4) {
      if (i > 0) formatted.write(' ');
      final end = (i + 4 < cleanIban.length) ? i + 4 : cleanIban.length;
      formatted.write(cleanIban.substring(i, end));
    }
    
    return formatted.toString();
  }

  /// Vérifier si un montant est éligible au paiement fractionné
  static bool isEligibleForFractionalPayment(double amount, SubscriptionType artistSubscription) {
    if (amount < 50.0) return false; // Montant minimum
    return artistSubscription.index >= SubscriptionType.standard.index;
  }

  /// Calculer les frais de traitement (si applicable)
  static double calculateProcessingFee(double amount) {
    // 0.3€ + 2.9% pour Stripe (exemple)
    return 0.30 + (amount * 0.029);
  }
}