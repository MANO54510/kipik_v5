// supplier_model.dart

class SupplierModel {
  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final String website;
  final String email;
  final String phone;
  final String address;
  final List<String> categories;
  final bool isFavorite;
  final double? rating;
  final List<String>? tags;
  
  // Nouveaux champs pour les partenariats
  final bool isPartner;
  final List<PartnershipBenefit>? benefits;
  final String? partnershipDescription;
  final String? promoCode;
  final DateTime? partnershipExpiryDate;
  final String? partnerLogoUrl;
  final int? cashbackPercentage;
  final bool? hasExclusiveAccess;
  final List<SupplierPromotion>? currentPromotions;

  final DateTime createdAt;
  final DateTime updatedAt;

  SupplierModel({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.website,
    required this.email,
    required this.phone,
    required this.address,
    required this.categories,
    required this.isFavorite,
    this.rating,
    this.tags,
    
    // Nouveaux champs pour les partenariats
    this.isPartner = false,
    this.benefits,
    this.partnershipDescription,
    this.promoCode,
    this.partnershipExpiryDate,
    this.partnerLogoUrl,
    this.cashbackPercentage,
    this.hasExclusiveAccess,
    this.currentPromotions,

    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      logoUrl: json['logoUrl'],
      website: json['website'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      categories: List<String>.from(json['categories']),
      isFavorite: json['isFavorite'],
      rating: json['rating'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      
      // Nouveaux champs pour les partenariats
      isPartner: json['isPartner'] ?? false,
      benefits: json['benefits'] != null
          ? List<PartnershipBenefit>.from(
              json['benefits'].map((x) => PartnershipBenefit.fromJson(x)))
          : null,
      partnershipDescription: json['partnershipDescription'],
      promoCode: json['promoCode'],
      partnershipExpiryDate: json['partnershipExpiryDate'] != null
          ? DateTime.parse(json['partnershipExpiryDate'])
          : null,
      partnerLogoUrl: json['partnerLogoUrl'],
      cashbackPercentage: json['cashbackPercentage'],
      hasExclusiveAccess: json['hasExclusiveAccess'],
      currentPromotions: json['currentPromotions'] != null
          ? List<SupplierPromotion>.from(
              json['currentPromotions'].map((x) => SupplierPromotion.fromJson(x)))
          : null,

      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// Modèle pour les avantages partenaires
class PartnershipBenefit {
  final String id;
  final String title;
  final String description;
  final BenefitType type;
  final double value; // Pourcentage, montant, etc.
  final String? thresholdDescription; // Ex: "À partir de 100€ d'achat"
  final bool isUnlimited;
  final DateTime? expiryDate;
  final String? iconName;

  PartnershipBenefit({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    this.thresholdDescription,
    this.isUnlimited = false,
    this.expiryDate,
    this.iconName,
  });

  factory PartnershipBenefit.fromJson(Map<String, dynamic> json) {
    return PartnershipBenefit(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: BenefitTypeExtension.fromString(json['type']),
      value: json['value'],
      thresholdDescription: json['thresholdDescription'],
      isUnlimited: json['isUnlimited'] ?? false,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      iconName: json['iconName'],
    );
  }
}

// Types d'avantages
enum BenefitType {
  discount,    // Remise directe sur les achats
  cashback,    // Remise en argent après achat
  loyalty,     // Points de fidélité
  freeShipping, // Livraison gratuite
  exclusiveAccess, // Accès à des produits exclusifs
  gift,        // Cadeau à partir d'un certain montant
  other        // Autre type d'avantage
}

// Extension pour faciliter la conversion string <-> enum
extension BenefitTypeExtension on BenefitType {
  static BenefitType fromString(String value) {
    return BenefitType.values.firstWhere(
      (type) => type.toString().split('.').last == value,
      orElse: () => BenefitType.other,
    );
  }

  String get displayName {
    switch (this) {
      case BenefitType.discount:
        return 'Remise';
      case BenefitType.cashback:
        return 'Cashback';
      case BenefitType.loyalty:
        return 'Points fidélité';
      case BenefitType.freeShipping:
        return 'Livraison gratuite';
      case BenefitType.exclusiveAccess:
        return 'Accès exclusif';
      case BenefitType.gift:
        return 'Cadeau';
      case BenefitType.other:
        return 'Autre avantage';
    }
  }
}

// Modèle pour les promotions temporaires
class SupplierPromotion {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final String? promoCode;
  final double discountValue;
  final bool isPercentage;
  final String? conditions;

  SupplierPromotion({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    this.promoCode,
    required this.discountValue,
    required this.isPercentage,
    this.conditions,
  });

  factory SupplierPromotion.fromJson(Map<String, dynamic> json) {
    return SupplierPromotion(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      imageUrl: json['imageUrl'],
      promoCode: json['promoCode'],
      discountValue: json['discountValue'],
      isPercentage: json['isPercentage'],
      conditions: json['conditions'],
    );
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}