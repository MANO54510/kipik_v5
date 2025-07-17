// lib/models/user_subscription.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Types d'abonnements disponibles - aligné avec la stratégie KIPIK
enum SubscriptionType {
  free,        // Gratuit (30 jours d'essai)
  standard,    // Standard 99€/mois - Agenda + Fractionné 2%
  premium,     // Premium 149€/mois - Standard + Conventions + Fractionné 1%
  enterprise,  // Entreprise 299€/mois - Tout + Support dédié (non utilisé)
}

/// Fonctionnalités premium disponibles
enum PremiumFeature {
  // Fonctionnalités Standard
  professionalAgenda,   // Agenda professionnel complet
  fractionalPayments,   // Paiement fractionné tatouages (2% ou 1%)
  clientManagement,     // Gestion clients avancée
  advancedAnalytics,    // Analytics avancées
  advancedFilters,      // Filtres avancés recherche
  
  // Fonctionnalités Premium exclusives
  conventions,          // Accès aux conventions/événements
  guestApplications,    // Candidatures guest
  guestOffers,          // Propositions guest
  flashMinute,          // Flash minute créneaux
  
  // Fonctionnalités Enterprise (non utilisées)
  prioritySupport,      // Support prioritaire
  customBranding,       // Personnalisation marque
  bulkOperations,       // Opérations en masse
  apiAccess,            // Accès API
  unlimitedPhotos,      // Photos illimitées
  whiteLabel,           // Marque blanche
}

/// Statut de l'abonnement
enum SubscriptionStatus {
  trial,       // Période d'essai gratuite (30 jours)
  active,      // Abonnement actif et payé
  expired,     // Expiré
  cancelled,   // Annulé
  suspended,   // Suspendu
  pending,     // En attente de paiement
}

class UserSubscription {
  final String userId;
  final SubscriptionType type;
  final SubscriptionType? targetType; // Type cible après trial
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? trialEndDate;
  final bool trialActive;
  final List<PremiumFeature> enabledFeatures;
  final Map<String, int> usageLimits;
  final Map<String, int> currentUsage;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? stripePriceId;
  final String? sepaSetupIntentId;
  final String? stripeAccountId; // Pour transfers
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserSubscription({
    required this.userId,
    required this.type,
    this.targetType,
    required this.status,
    this.startDate,
    this.endDate,
    this.trialEndDate,
    required this.trialActive,
    required this.enabledFeatures,
    this.usageLimits = const {},
    this.currentUsage = const {},
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.stripePriceId,
    this.sepaSetupIntentId,
    this.stripeAccountId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Vérifier si une fonctionnalité est disponible
  bool hasFeature(PremiumFeature feature) {
    // Si en période d'essai, certaines fonctionnalités sont disponibles
    if (trialActive && isInTrialPeriod) {
      return _getTrialFeatures().contains(feature);
    }
    
    // Si abonnement payant actif
    if (status == SubscriptionStatus.active && !isExpired) {
      return enabledFeatures.contains(feature);
    }
    
    return false;
  }

  /// Obtenir le taux de commission pour les tatouages
  double get commissionRate {
    switch (type) {
      case SubscriptionType.free:
        return 0.025; // 2.5% - Incite à l'upgrade
      case SubscriptionType.standard:
        return 0.02;  // 2% - Commission standard
      case SubscriptionType.premium:
        return 0.01;  // 1% - Réduction premium
      case SubscriptionType.enterprise:
        return 0.005; // 0.5% - Taux préférentiel (non utilisé)
    }
  }

  /// Vérifier si peut utiliser le paiement fractionné
  bool get canUseFractionalPayments {
    return hasFeature(PremiumFeature.fractionalPayments);
  }

  /// Limites de paiement fractionné selon abonnement
  Map<String, dynamic> get fractionalPaymentLimits {
    switch (type) {
      case SubscriptionType.free:
        return {
          'max_installments': 2,
          'max_amount': 400.0,
          'per_month': 1,
        };
      case SubscriptionType.standard:
        return {
          'max_installments': 3,
          'max_amount': 1000.0,
          'per_month': 10,
        };
      case SubscriptionType.premium:
        return {
          'max_installments': 4,
          'max_amount': -1, // Illimité
          'per_month': -1,  // Illimité
        };
      case SubscriptionType.enterprise:
        return {
          'max_installments': 6,
          'max_amount': -1,
          'per_month': -1,
        };
    }
  }

  /// Vérifier si l'abonnement est expiré
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Vérifier si encore dans la période d'essai
  bool get isInTrialPeriod {
    if (trialEndDate == null) return false;
    return trialActive && DateTime.now().isBefore(trialEndDate!);
  }

  /// Vérifier si l'utilisateur a un abonnement valide (essai OU payant)
  bool get hasValidSubscription {
    return isInTrialPeriod || 
           (status == SubscriptionStatus.active && !isExpired);
  }

  /// Vérifier si c'est un abonnement premium ou supérieur
  bool get isPremiumOrHigher {
    return type == SubscriptionType.premium || 
           type == SubscriptionType.enterprise;
  }

  /// Vérifier si c'est un abonnement standard ou supérieur
  bool get isStandardOrHigher {
    return type != SubscriptionType.free;
  }

  /// Obtenir la limite d'usage pour une fonctionnalité
  int getUsageLimit(String feature) {
    return usageLimits[feature] ?? _getDefaultLimit(feature);
  }

  /// Obtenir l'usage actuel d'une fonctionnalité
  int getCurrentUsage(String feature) {
    return currentUsage[feature] ?? 0;
  }

  /// Vérifier si la limite d'usage est atteinte
  bool hasUsageRemaining(String feature) {
    final limit = getUsageLimit(feature);
    if (limit == -1) return true; // Illimité
    
    final current = getCurrentUsage(feature);
    return current < limit;
  }

  /// Fonctionnalités disponibles pendant l'essai
  List<PremiumFeature> _getTrialFeatures() {
    final targetFeatures = targetType != null 
        ? _getFeaturesForType(targetType!) 
        : _getFeaturesForType(SubscriptionType.premium);
    
    return targetFeatures;
  }

  /// Limites par défaut selon le type d'abonnement
  int _getDefaultLimit(String feature) {
    switch (type) {
      case SubscriptionType.free:
        return {
          'photos_per_profile': 5,
          'projects_per_month': 3,
          'messages_per_day': 10,
          'fractional_payments_per_month': 1,
          'max_project_amount': 400,
        }[feature] ?? 0;
        
      case SubscriptionType.standard:
        return {
          'photos_per_profile': 25,
          'projects_per_month': 20,
          'messages_per_day': 100,
          'fractional_payments_per_month': 10,
          'max_project_amount': 1000,
          'agenda_sync': 1, // 1 calendrier externe
        }[feature] ?? 15;
        
      case SubscriptionType.premium:
        return {
          'photos_per_profile': -1, // Illimité
          'projects_per_month': -1,
          'messages_per_day': -1,
          'fractional_payments_per_month': -1,
          'max_project_amount': -1,
          'agenda_sync': 3, // 3 calendriers externes
          'conventions_per_month': 10,
          'guest_applications_per_month': 5,
        }[feature] ?? -1;
        
      case SubscriptionType.enterprise:
        return -1; // Tout illimité
    }
  }

  /// Fonctionnalités incluses selon le type d'abonnement
  List<PremiumFeature> _getFeaturesForType(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.free:
        return []; // Aucune fonctionnalité premium
        
      case SubscriptionType.standard:
        return [
          PremiumFeature.professionalAgenda,
          PremiumFeature.fractionalPayments, // 2% commission
          PremiumFeature.clientManagement,
          PremiumFeature.advancedAnalytics,
          PremiumFeature.advancedFilters,
        ];
        
      case SubscriptionType.premium:
        return [
          // Toutes les fonctionnalités Standard
          PremiumFeature.professionalAgenda,
          PremiumFeature.fractionalPayments, // 1% commission
          PremiumFeature.clientManagement,
          PremiumFeature.advancedAnalytics,
          PremiumFeature.advancedFilters,
          // Fonctionnalités Premium exclusives
          PremiumFeature.conventions,
          PremiumFeature.guestApplications,
          PremiumFeature.guestOffers,
          PremiumFeature.flashMinute,
        ];
        
      case SubscriptionType.enterprise:
        return PremiumFeature.values; // Toutes les fonctionnalités
    }
  }

  /// Créer un abonnement d'essai gratuit (30 jours)
  factory UserSubscription.createTrial({
    required String userId,
    required SubscriptionType targetType,
    String? stripeCustomerId,
    String? sepaSetupIntentId,
  }) {
    final now = DateTime.now();
    final trialEnd = now.add(const Duration(days: 30));
    
    return UserSubscription(
      userId: userId,
      type: SubscriptionType.free,
      targetType: targetType,
      status: SubscriptionStatus.trial,
      startDate: now,
      trialEndDate: trialEnd,
      trialActive: true,
      enabledFeatures: _getTrialFeaturesForType(targetType),
      stripeCustomerId: stripeCustomerId,
      sepaSetupIntentId: sepaSetupIntentId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Features d'essai selon le type cible
  static List<PremiumFeature> _getTrialFeaturesForType(SubscriptionType targetType) {
    switch (targetType) {
      case SubscriptionType.standard:
        return [
          PremiumFeature.professionalAgenda,
          PremiumFeature.fractionalPayments,
          PremiumFeature.clientManagement,
          PremiumFeature.advancedAnalytics,
        ];
      case SubscriptionType.premium:
        return [
          // Toutes les fonctionnalités pour essai complet
          PremiumFeature.professionalAgenda,
          PremiumFeature.fractionalPayments,
          PremiumFeature.clientManagement,
          PremiumFeature.advancedAnalytics,
          PremiumFeature.conventions,
          PremiumFeature.flashMinute,
          // Pas encore guest features en trial (trop complexe)
        ];
      default:
        return [];
    }
  }

  /// Factory pour démo Premium
  factory UserSubscription.createPremiumDemo(String userId) {
    final now = DateTime.now();
    
    return UserSubscription(
      userId: userId,
      type: SubscriptionType.premium,
      status: SubscriptionStatus.active,
      startDate: now,
      endDate: now.add(const Duration(days: 365)), // 1 an
      trialActive: false,
      enabledFeatures: PremiumFeature.values, // Toutes les features
      stripeCustomerId: 'demo_customer_$userId',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Factory depuis Firestore
  factory UserSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserSubscription(
      userId: doc.id,
      type: SubscriptionType.values[data['type'] ?? 0],
      targetType: data['targetType'] != null 
          ? SubscriptionType.values[data['targetType']]
          : null,
      status: SubscriptionStatus.values[data['status'] ?? 0],
      startDate: data['startDate']?.toDate(),
      endDate: data['endDate']?.toDate(),
      trialEndDate: data['trialEndDate']?.toDate(),
      trialActive: data['trialActive'] ?? false,
      enabledFeatures: (data['enabledFeatures'] as List<dynamic>?)
          ?.map((e) => PremiumFeature.values[e])
          .toList() ?? [],
      usageLimits: Map<String, int>.from(data['usageLimits'] ?? {}),
      currentUsage: Map<String, int>.from(data['currentUsage'] ?? {}),
      stripeCustomerId: data['stripeCustomerId'],
      stripeSubscriptionId: data['stripeSubscriptionId'],
      stripePriceId: data['stripePriceId'],
      sepaSetupIntentId: data['sepaSetupIntentId'],
      stripeAccountId: data['stripeAccountId'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  /// Factory depuis Map
  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      userId: map['userId'] ?? '',
      type: SubscriptionType.values[map['type'] ?? 0],
      targetType: map['targetType'] != null 
          ? SubscriptionType.values[map['targetType']]
          : null,
      status: SubscriptionStatus.values[map['status'] ?? 0],
      startDate: map['startDate'] != null 
          ? DateTime.parse(map['startDate']) 
          : null,
      endDate: map['endDate'] != null 
          ? DateTime.parse(map['endDate']) 
          : null,
      trialEndDate: map['trialEndDate'] != null 
          ? DateTime.parse(map['trialEndDate']) 
          : null,
      trialActive: map['trialActive'] ?? false,
      enabledFeatures: (map['enabledFeatures'] as List<dynamic>?)
          ?.map((e) => PremiumFeature.values[e])
          .toList() ?? [],
      usageLimits: Map<String, int>.from(map['usageLimits'] ?? {}),
      currentUsage: Map<String, int>.from(map['currentUsage'] ?? {}),
      stripeCustomerId: map['stripeCustomerId'],
      stripeSubscriptionId: map['stripeSubscriptionId'],
      stripePriceId: map['stripePriceId'],
      sepaSetupIntentId: map['sepaSetupIntentId'],
      stripeAccountId: map['stripeAccountId'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.index,
      'targetType': targetType?.index,
      'status': status.index,
      'startDate': startDate,
      'endDate': endDate,
      'trialEndDate': trialEndDate,
      'trialActive': trialActive,
      'enabledFeatures': enabledFeatures.map((e) => e.index).toList(),
      'usageLimits': usageLimits,
      'currentUsage': currentUsage,
      'stripeCustomerId': stripeCustomerId,
      'stripeSubscriptionId': stripeSubscriptionId,
      'stripePriceId': stripePriceId,
      'sepaSetupIntentId': sepaSetupIntentId,
      'stripeAccountId': stripeAccountId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Copie avec modifications
  UserSubscription copyWith({
    String? userId,
    SubscriptionType? type,
    SubscriptionType? targetType,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? trialEndDate,
    bool? trialActive,
    List<PremiumFeature>? enabledFeatures,
    Map<String, int>? usageLimits,
    Map<String, int>? currentUsage,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    String? stripePriceId,
    String? sepaSetupIntentId,
    String? stripeAccountId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSubscription(
      userId: userId ?? this.userId,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      trialActive: trialActive ?? this.trialActive,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      usageLimits: usageLimits ?? this.usageLimits,
      currentUsage: currentUsage ?? this.currentUsage,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      stripePriceId: stripePriceId ?? this.stripePriceId,
      sepaSetupIntentId: sepaSetupIntentId ?? this.sepaSetupIntentId,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserSubscription(userId: $userId, type: $type, status: $status, commissionRate: ${(commissionRate * 100).toStringAsFixed(1)}%, trialActive: $trialActive)';
  }
}

/// Extensions pour faciliter l'utilisation - SEULEMENT 2 ABONNEMENTS
extension SubscriptionTypeExtension on SubscriptionType {
  String get displayName {
    switch (this) {
      case SubscriptionType.free:
        return 'Essai Gratuit';
      case SubscriptionType.standard:
        return 'Standard';
      case SubscriptionType.premium:
        return 'Premium';
      case SubscriptionType.enterprise:
        return 'Enterprise'; // Garde pour compatibilité mais pas utilisé
    }
  }

  String get description {
    switch (this) {
      case SubscriptionType.free:
        return '30 jours d\'essai gratuit complet';
      case SubscriptionType.standard:
        return 'Agenda pro + paiement fractionné (2% commission)';
      case SubscriptionType.premium:
        return 'Standard + conventions + guest (1% commission)';
      case SubscriptionType.enterprise:
        return 'Non disponible'; // Pas utilisé
    }
  }

  double get monthlyPrice {
    switch (this) {
      case SubscriptionType.free:
        return 0.0;   // Gratuit
      case SubscriptionType.standard:
        return 99.0;  // 99€/mois
      case SubscriptionType.premium:
        return 149.0; // 149€/mois
      case SubscriptionType.enterprise:
        return 999.0; // Prix élevé pour décourager
    }
  }

  /// Calculer le break-even vs un autre abonnement
  double calculateBreakEven(SubscriptionType otherType) {
    if (this == otherType) return 0.0;
    
    final priceDiff = monthlyPrice - otherType.monthlyPrice;
    final commissionDiff = commissionRate - otherType.commissionRate;
    
    if (commissionDiff == 0) return double.infinity;
    
    return priceDiff / commissionDiff; // CA mensuel de break-even
  }

  double get commissionRate {
    switch (this) {
      case SubscriptionType.free:
        return 0.025; // 2.5% - Incite à l'upgrade
      case SubscriptionType.standard:
        return 0.02;  // 2% - Commission standard
      case SubscriptionType.premium:
        return 0.01;  // 1% - Réduction premium
      case SubscriptionType.enterprise:
        return 0.005; // Non utilisé
    }
  }

  /// ✅ COULEURS POUR LES 2 ABONNEMENTS PRINCIPAUX
  Color get subscriptionColor {
    switch (this) {
      case SubscriptionType.free:
        return const Color(0xFF6B7280); // Gris pour essai
      case SubscriptionType.standard:
        return const Color(0xFF10B981); // Vert pour Standard
      case SubscriptionType.premium:
        return const Color(0xFF6366F1); // Indigo pour Premium
      case SubscriptionType.enterprise:
        return const Color(0xFF8B5CF6); // Violet (non utilisé)
    }
  }

  /// ✅ FONCTIONNALITÉS POUR LES 2 ABONNEMENTS
  List<String> get keyFeatures {
    switch (this) {
      case SubscriptionType.free:
        return [
          '30 jours d\'essai complet',
          'Toutes les fonctionnalités Premium',
          'Support communauté',
          'Aucun engagement',
        ];
      case SubscriptionType.standard:
        return [
          '✅ Agenda professionnel synchronisé',
          '✅ Paiement fractionné pour clients',
          '✅ Gestion clients avancée',
          '✅ Analytics de base',
          '📊 Commission 2% sur paiements',
          '💬 Support standard',
        ];
      case SubscriptionType.premium:
        return [
          '✅ Toutes fonctionnalités Standard',
          '🎪 Conventions & événements tattoo',
          '🤝 Système Guest (candidatures)',
          '⚡ Flash Minute (créneaux libres)',
          '📊 Commission réduite 1%',
          '🚀 Support prioritaire',
          '📈 Analytics avancées',
        ];
      case SubscriptionType.enterprise:
        return [
          'Non disponible pour le moment',
        ];
    }
  }

  /// ✅ VÉRIFIE SI L'ABONNEMENT EST DISPONIBLE
  bool get isAvailable {
    return this == SubscriptionType.free || 
           this == SubscriptionType.standard || 
           this == SubscriptionType.premium;
  }

  /// ✅ ÉCONOMIES POTENTIELLES
  String get savingsInfo {
    switch (this) {
      case SubscriptionType.free:
        return 'Testez toutes les fonctionnalités gratuitement';
      case SubscriptionType.standard:
        return 'Économisez jusqu\'à 0.5% vs frais bancaires';
      case SubscriptionType.premium:
        return 'Économisez 50€/mois vs Standard si CA > 5000€';
      case SubscriptionType.enterprise:
        return 'Non disponible';
    }
  }

  /// ✅ RECOMMANDATION SELON LE CA
  static SubscriptionType getRecommendedFor(double monthlyRevenue) {
    if (monthlyRevenue == 0) {
      return SubscriptionType.free;
    } else if (monthlyRevenue < 5000) {
      return SubscriptionType.standard;
    } else {
      return SubscriptionType.premium; // Break-even à 5000€ CA/mois
    }
  }

  /// ✅ BADGE POUR L'INTERFACE
  String? get badge {
    switch (this) {
      case SubscriptionType.free:
        return '🆓 GRATUIT';
      case SubscriptionType.standard:
        return null; // Pas de badge
      case SubscriptionType.premium:
        return '⭐ RECOMMANDÉ';
      case SubscriptionType.enterprise:
        return null;
    }
  }

  /// ✅ COULEUR DU BADGE
  Color? get badgeColor {
    switch (this) {
      case SubscriptionType.free:
        return const Color(0xFF10B981); // Vert
      case SubscriptionType.standard:
        return null;
      case SubscriptionType.premium:
        return const Color(0xFFFFB800); // Orange doré
      case SubscriptionType.enterprise:
        return null;
    }
  }

  /// ✅ LISTE DES ABONNEMENTS DISPONIBLES
  static List<SubscriptionType> get availableTypes => [
    SubscriptionType.free,
    SubscriptionType.standard,
    SubscriptionType.premium,
  ];

  /// ✅ CALCUL DU BREAK-EVEN PREMIUM VS STANDARD
  static double get premiumBreakEvenAmount {
    final priceDiff = SubscriptionType.premium.monthlyPrice - 
                     SubscriptionType.standard.monthlyPrice; // 50€
    final commissionDiff = SubscriptionType.standard.commissionRate - 
                          SubscriptionType.premium.commissionRate; // 1%
    
    return priceDiff / commissionDiff; // 5000€ de CA mensuel
  }

  /// ✅ MESSAGE DE BREAK-EVEN
  static String get breakEvenMessage => 
    'Premium rentable dès ${premiumBreakEvenAmount.toInt()}€ de CA mensuel';
}

extension PremiumFeatureExtension on PremiumFeature {
  String get displayName {
    switch (this) {
      case PremiumFeature.professionalAgenda:
        return 'Agenda Professionnel';
      case PremiumFeature.fractionalPayments:
        return 'Paiement Fractionné';
      case PremiumFeature.clientManagement:
        return 'Gestion Clients';
      case PremiumFeature.conventions:
        return 'Conventions & Événements';
      case PremiumFeature.guestApplications:
        return 'Candidatures Guest';
      case PremiumFeature.guestOffers:
        return 'Propositions Guest';
      case PremiumFeature.flashMinute:
        return 'Flash Minute';
      case PremiumFeature.advancedAnalytics:
        return 'Analytics Avancées';
      case PremiumFeature.prioritySupport:
        return 'Support Prioritaire';
      case PremiumFeature.customBranding:
        return 'Personnalisation';
      case PremiumFeature.bulkOperations:
        return 'Opérations en Masse';
      case PremiumFeature.apiAccess:
        return 'Accès API';
      case PremiumFeature.unlimitedPhotos:
        return 'Photos Illimitées';
      case PremiumFeature.advancedFilters:
        return 'Filtres Avancés';
      case PremiumFeature.whiteLabel:
        return 'Marque Blanche';
    }
  }

  String get description {
    switch (this) {
      case PremiumFeature.professionalAgenda:
        return 'Agenda synchronisé avec Google/Apple Calendar';
      case PremiumFeature.fractionalPayments:
        return 'Vos clients peuvent payer en 2, 3 ou 4 fois';
      case PremiumFeature.clientManagement:
        return 'CRM complet pour gérer vos clients';
      case PremiumFeature.conventions:
        return 'Accédez aux conventions et événements tattoo';
      case PremiumFeature.guestApplications:
        return 'Postulez comme tatoueur guest dans d\'autres studios';
      case PremiumFeature.guestOffers:
        return 'Proposez votre studio à des tatoueurs guests';
      case PremiumFeature.flashMinute:
        return 'Proposez vos créneaux libres en dernière minute';
      case PremiumFeature.advancedAnalytics:
        return 'Analyses détaillées de votre activité';
      case PremiumFeature.prioritySupport:
        return 'Support client prioritaire 24/7';
      case PremiumFeature.customBranding:
        return 'Personnalisez votre profil et studio';
      case PremiumFeature.bulkOperations:
        return 'Gérez plusieurs éléments simultanément';
      case PremiumFeature.apiAccess:
        return 'Intégrez avec vos outils existants';
      case PremiumFeature.unlimitedPhotos:
        return 'Ajoutez autant de photos que vous voulez';
      case PremiumFeature.advancedFilters:
        return 'Filtres de recherche avancés';
      case PremiumFeature.whiteLabel:
        return 'Solution sous votre propre marque';
    }
  }

  IconData get icon {
    switch (this) {
      case PremiumFeature.professionalAgenda:
        return Icons.calendar_month;
      case PremiumFeature.fractionalPayments:
        return Icons.payments;
      case PremiumFeature.clientManagement:
        return Icons.people;
      case PremiumFeature.conventions:
        return Icons.event;
      case PremiumFeature.guestApplications:
        return Icons.send;
      case PremiumFeature.guestOffers:
        return Icons.handshake;
      case PremiumFeature.flashMinute:
        return Icons.flash_on;
      case PremiumFeature.advancedAnalytics:
        return Icons.analytics;
      case PremiumFeature.prioritySupport:
        return Icons.support_agent;
      case PremiumFeature.customBranding:
        return Icons.palette;
      case PremiumFeature.bulkOperations:
        return Icons.select_all;
      case PremiumFeature.apiAccess:
        return Icons.api;
      case PremiumFeature.unlimitedPhotos:
        return Icons.photo_library;
      case PremiumFeature.advancedFilters:
        return Icons.filter_alt;
      case PremiumFeature.whiteLabel:
        return Icons.branding_watermark;
    }
  }

  SubscriptionType get minimumRequired {
    switch (this) {
      case PremiumFeature.professionalAgenda:
      case PremiumFeature.fractionalPayments:
      case PremiumFeature.clientManagement:
      case PremiumFeature.advancedAnalytics:
      case PremiumFeature.advancedFilters:
        return SubscriptionType.standard;
        
      case PremiumFeature.conventions:
      case PremiumFeature.guestApplications:
      case PremiumFeature.guestOffers:
      case PremiumFeature.flashMinute:
        return SubscriptionType.premium;
        
      case PremiumFeature.prioritySupport:
      case PremiumFeature.customBranding:
      case PremiumFeature.bulkOperations:
      case PremiumFeature.apiAccess:
      case PremiumFeature.unlimitedPhotos:
      case PremiumFeature.whiteLabel:
        return SubscriptionType.enterprise;
    }
  }
}