// Fichier: models/supplier_model.dart

import 'dart:convert';

// Types d'avantages partenaires
enum BenefitType {
  discount,     // Remise sur les prix
  cashback,     // Remboursement partiel
  freeShipping, // Livraison gratuite
  loyalty,      // Programme de fidélité
  exclusiveAccess, // Accès à des produits exclusifs
  gift,         // ✅ AJOUTÉ - Cadeau offert
}

class PartnershipBenefit {
  final String id;
  final String title;
  final String description;
  final BenefitType type;
  final double value; // Valeur (pourcentage ou montant)
  final bool isUnlimited; // Si l'avantage est illimité dans le temps
  final String? thresholdDescription; // Description du seuil (ex: "À partir de 200€")
  final String iconName; // Nom de l'icône à afficher
  final DateTime? expiryDate; // ✅ AJOUTÉ - Date d'expiration de l'avantage

  PartnershipBenefit({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    this.isUnlimited = false,
    this.thresholdDescription,
    required this.iconName,
    this.expiryDate, // ✅ AJOUTÉ
  });

  factory PartnershipBenefit.fromJson(Map<String, dynamic> json) {
    return PartnershipBenefit(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: BenefitType.values.firstWhere(
        (e) => e.toString() == 'BenefitType.${json['type']}',
        orElse: () => BenefitType.discount,
      ),
      value: (json['value'] as num).toDouble(),
      isUnlimited: json['isUnlimited'] as bool? ?? false,
      thresholdDescription: json['thresholdDescription'] as String?,
      iconName: json['iconName'] as String,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate'] as String) 
          : null, // ✅ AJOUTÉ
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'value': value,
      'isUnlimited': isUnlimited,
      if (thresholdDescription != null) 'thresholdDescription': thresholdDescription,
      'iconName': iconName,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(), // ✅ AJOUTÉ
    };
  }
}

class SupplierPromotion {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double discountValue;
  final bool isPercentage;
  final String? conditions;
  final String? promoCode;

  SupplierPromotion({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.discountValue,
    required this.isPercentage,
    this.conditions,
    this.promoCode,
  });

  factory SupplierPromotion.fromJson(Map<String, dynamic> json) {
    return SupplierPromotion(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      discountValue: (json['discountValue'] as num).toDouble(),
      isPercentage: json['isPercentage'] as bool,
      conditions: json['conditions'] as String?,
      promoCode: json['promoCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'discountValue': discountValue,
      'isPercentage': isPercentage,
      if (conditions != null) 'conditions': conditions,
      if (promoCode != null) 'promoCode': promoCode,
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

class SupplierCommission {
  final String id;
  final double percentage; // Pourcentage de commission pour Kipik
  final double? minAmount; // Montant minimum d'achat pour obtenir la commission
  final double? maxAmount; // Plafond de commission
  final bool isActive;

  SupplierCommission({
    required this.id,
    required this.percentage,
    this.minAmount,
    this.maxAmount,
    this.isActive = true,
  });

  factory SupplierCommission.fromJson(Map<String, dynamic> json) {
    return SupplierCommission(
      id: json['id'] as String,
      percentage: (json['percentage'] as num).toDouble(),
      minAmount: json['minAmount'] != null ? (json['minAmount'] as num).toDouble() : null,
      maxAmount: json['maxAmount'] != null ? (json['maxAmount'] as num).toDouble() : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'percentage': percentage,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'isActive': isActive,
    };
  }
}

class SupplierModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? website;
  final String? email;
  final String? phone;
  final String? address;
  final String? zipCode;
  final String? city;
  final String? country;
  final List<String> categories;
  final bool isFavorite;
  final double? rating;
  final List<String>? tags;
  
  // Données de partenariat
  final bool isPartner;
  final String? partnershipDescription;
  final String? promoCode;
  final bool? hasExclusiveAccess;
  final double? cashbackPercentage;
  final List<PartnershipBenefit>? benefits;
  final List<SupplierPromotion>? currentPromotions;
  final SupplierCommission? commission;
  
  // Méta-données
  final bool featured; // Fournisseur mis en avant
  final bool verified; // Fournisseur vérifié par Kipik
  final bool isActive; // Fournisseur actif
  final String? partnershipType; // Type de partenariat (affiliation, commission, remise...)
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes; // Notes internes
  final Map<String, dynamic>? additionalInfo; // Informations complémentaires

  SupplierModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    this.website,
    this.email,
    this.phone,
    this.address,
    this.zipCode,
    this.city,
    this.country,
    this.categories = const [],
    this.isFavorite = false,
    this.rating,
    this.tags,
    
    this.isPartner = false,
    this.partnershipDescription,
    this.promoCode,
    this.hasExclusiveAccess,
    this.cashbackPercentage,
    this.benefits,
    this.currentPromotions,
    this.commission,
    
    this.featured = false,
    this.verified = false,
    this.isActive = true,
    this.partnershipType,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.additionalInfo,
  });
  
  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      zipCode: json['zipCode'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isFavorite: json['isFavorite'] as bool? ?? false,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      
      isPartner: json['isPartner'] as bool? ?? false,
      partnershipDescription: json['partnershipDescription'] as String?,
      promoCode: json['promoCode'] as String?,
      hasExclusiveAccess: json['hasExclusiveAccess'] as bool?,
      cashbackPercentage: json['cashbackPercentage'] != null ? (json['cashbackPercentage'] as num).toDouble() : null,
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((e) => PartnershipBenefit.fromJson(e as Map<String, dynamic>))
              .toList(),
      currentPromotions: (json['currentPromotions'] as List<dynamic>?)
              ?.map((e) => SupplierPromotion.fromJson(e as Map<String, dynamic>))
              .toList(),
      commission: json['commission'] != null
          ? SupplierCommission.fromJson(json['commission'] as Map<String, dynamic>)
          : null,
      
      featured: json['featured'] as bool? ?? false,
      verified: json['verified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      partnershipType: json['partnershipType'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      notes: json['notes'] as String?,
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      if (website != null) 'website': website,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (zipCode != null) 'zipCode': zipCode,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      'categories': categories,
      'isFavorite': isFavorite,
      if (rating != null) 'rating': rating,
      if (tags != null) 'tags': tags,
      
      'isPartner': isPartner,
      if (partnershipDescription != null) 'partnershipDescription': partnershipDescription,
      if (promoCode != null) 'promoCode': promoCode,
      if (hasExclusiveAccess != null) 'hasExclusiveAccess': hasExclusiveAccess,
      if (cashbackPercentage != null) 'cashbackPercentage': cashbackPercentage,
      if (benefits != null) 'benefits': benefits!.map((e) => e.toJson()).toList(),
      if (currentPromotions != null) 'currentPromotions': currentPromotions!.map((e) => e.toJson()).toList(),
      if (commission != null) 'commission': commission!.toJson(),
      
      'featured': featured,
      'verified': verified,
      'isActive': isActive,
      if (partnershipType != null) 'partnershipType': partnershipType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
    };
  }
  
  // Méthodes utilitaires
  String get formattedAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  bool get hasCommission => commission != null && commission!.isActive;
  bool get hasActivePromotions => currentPromotions != null && 
      currentPromotions!.isNotEmpty && 
      currentPromotions!.any((p) => p.isActive);

  List<PartnershipBenefit> get discountBenefits {
    if (benefits == null) return [];
    return benefits!.where((b) => b.type == BenefitType.discount).toList();
  }

  double get maxDiscountPercentage {
    if (discountBenefits.isEmpty) return 0.0;
    return discountBenefits.map((b) => b.value).reduce((a, b) => a > b ? a : b);
  }
  
  SupplierModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    String? website,
    String? email,
    String? phone,
    String? address,
    String? zipCode,
    String? city,
    String? country,
    List<String>? categories,
    bool? isFavorite,
    double? rating,
    List<String>? tags,
    bool? isPartner,
    String? partnershipDescription,
    String? promoCode,
    bool? hasExclusiveAccess,
    double? cashbackPercentage,
    List<PartnershipBenefit>? benefits,
    List<SupplierPromotion>? currentPromotions,
    SupplierCommission? commission,
    bool? featured,
    bool? verified,
    bool? isActive,
    String? partnershipType,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    Map<String, dynamic>? additionalInfo,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      website: website ?? this.website,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      zipCode: zipCode ?? this.zipCode,
      city: city ?? this.city,
      country: country ?? this.country,
      categories: categories ?? this.categories,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      isPartner: isPartner ?? this.isPartner,
      partnershipDescription: partnershipDescription ?? this.partnershipDescription,
      promoCode: promoCode ?? this.promoCode,
      hasExclusiveAccess: hasExclusiveAccess ?? this.hasExclusiveAccess,
      cashbackPercentage: cashbackPercentage ?? this.cashbackPercentage,
      benefits: benefits ?? this.benefits,
      currentPromotions: currentPromotions ?? this.currentPromotions,
      commission: commission ?? this.commission,
      featured: featured ?? this.featured,
      verified: verified ?? this.verified,
      isActive: isActive ?? this.isActive,
      partnershipType: partnershipType ?? this.partnershipType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}