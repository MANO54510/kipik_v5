// lib/models/guest_mission.dart

enum GuestMissionStatus { pending, accepted, active, completed, cancelled }
enum GuestMissionType { incoming, outgoing }

class GuestMission {
  final String id;
  final String guestId;
  final String shopId;
  final String guestName;
  final String shopName;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final GuestMissionType type;
  final GuestMissionStatus status;
  final double commissionRate;
  final bool accommodationIncluded;
  final List<String> styles;
  final String? description;
  final double? totalRevenue;
  final String? contractId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const GuestMission({
    required this.id,
    required this.guestId,
    required this.shopId,
    required this.guestName,
    required this.shopName,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.status,
    required this.commissionRate,
    required this.accommodationIncluded,
    required this.styles,
    this.description,
    this.totalRevenue,
    this.contractId,
    required this.createdAt,
    this.updatedAt,
  });

  // Getters utiles
  Duration get duration => endDate.difference(startDate);
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
  bool get isActive => status == GuestMissionStatus.active;
  bool get isPending => status == GuestMissionStatus.pending;
  bool get isCompleted => status == GuestMissionStatus.completed;
  bool get isIncoming => type == GuestMissionType.incoming;
  bool get isOutgoing => type == GuestMissionType.outgoing;

  String get statusLabel {
    switch (status) {
      case GuestMissionStatus.pending:
        return 'En attente';
      case GuestMissionStatus.accepted:
        return 'Accepté';
      case GuestMissionStatus.active:
        return 'En cours';
      case GuestMissionStatus.completed:
        return 'Terminé';
      case GuestMissionStatus.cancelled:
        return 'Annulé';
    }
  }

  String get typeLabel => isIncoming ? 'Guest entrant' : 'Guest sortant';

  // Factory methods
  factory GuestMission.fromJson(Map<String, dynamic> json) {
    return GuestMission(
      id: json['id'],
      guestId: json['guestId'],
      shopId: json['shopId'],
      guestName: json['guestName'],
      shopName: json['shopName'],
      location: json['location'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      type: GuestMissionType.values[json['type']],
      status: GuestMissionStatus.values[json['status']],
      commissionRate: json['commissionRate'].toDouble(),
      accommodationIncluded: json['accommodationIncluded'],
      styles: List<String>.from(json['styles']),
      description: json['description'],
      totalRevenue: json['totalRevenue']?.toDouble(),
      contractId: json['contractId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guestId': guestId,
      'shopId': shopId,
      'guestName': guestName,
      'shopName': shopName,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type.index,
      'status': status.index,
      'commissionRate': commissionRate,
      'accommodationIncluded': accommodationIncluded,
      'styles': styles,
      'description': description,
      'totalRevenue': totalRevenue,
      'contractId': contractId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // CopyWith
  GuestMission copyWith({
    String? id,
    String? guestId,
    String? shopId,
    String? guestName,
    String? shopName,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    GuestMissionType? type,
    GuestMissionStatus? status,
    double? commissionRate,
    bool? accommodationIncluded,
    List<String>? styles,
    String? description,
    double? totalRevenue,
    String? contractId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GuestMission(
      id: id ?? this.id,
      guestId: guestId ?? this.guestId,
      shopId: shopId ?? this.shopId,
      guestName: guestName ?? this.guestName,
      shopName: shopName ?? this.shopName,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      status: status ?? this.status,
      commissionRate: commissionRate ?? this.commissionRate,
      accommodationIncluded: accommodationIncluded ?? this.accommodationIncluded,
      styles: styles ?? this.styles,
      description: description ?? this.description,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      contractId: contractId ?? this.contractId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// lib/models/guest_opportunity.dart

enum OpportunityType { guest, shop }
enum OpportunityStatus { open, closed, applied }

class GuestOpportunity {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatar;
  final OpportunityType type;
  final OpportunityStatus status;
  final String location;
  final DateTime availableFrom;
  final DateTime availableTo;
  final List<String> styles;
  final String description;
  final double commissionRate;
  final bool accommodationProvided;
  final bool accommodationRequired;
  final String experienceLevel;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const GuestOpportunity({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatar,
    required this.type,
    required this.status,
    required this.location,
    required this.availableFrom,
    required this.availableTo,
    required this.styles,
    required this.description,
    required this.commissionRate,
    required this.accommodationProvided,
    required this.accommodationRequired,
    required this.experienceLevel,
    required this.rating,
    required this.reviewCount,
    required this.createdAt,
    this.expiresAt,
  });

  // Getters
  Duration get duration => availableTo.difference(availableFrom);
  int get durationInDays => duration.inDays;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isActive => status == OpportunityStatus.open && !isExpired;
  bool get isGuestOffer => type == OpportunityType.guest;
  bool get isShopOffer => type == OpportunityType.shop;

  String get durationLabel {
    if (durationInDays == 1) return '1 jour';
    if (durationInDays < 7) return '$durationInDays jours';
    if (durationInDays < 30) return '${(durationInDays / 7).round()} semaine${(durationInDays / 7).round() > 1 ? 's' : ''}';
    return '${(durationInDays / 30).round()} mois';
  }

  String get typeLabel => isGuestOffer ? 'Guest disponible' : 'Shop recherche';

  factory GuestOpportunity.fromJson(Map<String, dynamic> json) {
    return GuestOpportunity(
      id: json['id'],
      ownerId: json['ownerId'],
      ownerName: json['ownerName'],
      ownerAvatar: json['ownerAvatar'],
      type: OpportunityType.values[json['type']],
      status: OpportunityStatus.values[json['status']],
      location: json['location'],
      availableFrom: DateTime.parse(json['availableFrom']),
      availableTo: DateTime.parse(json['availableTo']),
      styles: List<String>.from(json['styles']),
      description: json['description'],
      commissionRate: json['commissionRate'].toDouble(),
      accommodationProvided: json['accommodationProvided'],
      accommodationRequired: json['accommodationRequired'],
      experienceLevel: json['experienceLevel'],
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerAvatar': ownerAvatar,
      'type': type.index,
      'status': status.index,
      'location': location,
      'availableFrom': availableFrom.toIso8601String(),
      'availableTo': availableTo.toIso8601String(),
      'styles': styles,
      'description': description,
      'commissionRate': commissionRate,
      'accommodationProvided': accommodationProvided,
      'accommodationRequired': accommodationRequired,
      'experienceLevel': experienceLevel,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

// lib/models/guest_stats.dart

class GuestStats {
  final int totalMissions;
  final int activeMissions;
  final int completedMissions;
  final int pendingRequests;
  final int incomingRequests;
  final double totalRevenue;
  final double monthlyRevenue;
  final double averageRating;
  final int totalReviews;
  final Map<String, int> missionsByStatus;
  final Map<String, double> revenueByMonth;

  const GuestStats({
    required this.totalMissions,
    required this.activeMissions,
    required this.completedMissions,
    required this.pendingRequests,
    required this.incomingRequests,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.averageRating,
    required this.totalReviews,
    required this.missionsByStatus,
    required this.revenueByMonth,
  });

  static GuestStats empty() => const GuestStats(
    totalMissions: 0,
    activeMissions: 0,
    completedMissions: 0,
    pendingRequests: 0,
    incomingRequests: 0,
    totalRevenue: 0.0,
    monthlyRevenue: 0.0,
    averageRating: 0.0,
    totalReviews: 0,
    missionsByStatus: {},
    revenueByMonth: {},
  );

  factory GuestStats.fromJson(Map<String, dynamic> json) {
    return GuestStats(
      totalMissions: json['totalMissions'],
      activeMissions: json['activeMissions'],
      completedMissions: json['completedMissions'],
      pendingRequests: json['pendingRequests'],
      incomingRequests: json['incomingRequests'],
      totalRevenue: json['totalRevenue'].toDouble(),
      monthlyRevenue: json['monthlyRevenue'].toDouble(),
      averageRating: json['averageRating'].toDouble(),
      totalReviews: json['totalReviews'],
      missionsByStatus: Map<String, int>.from(json['missionsByStatus']),
      revenueByMonth: Map<String, double>.from(json['revenueByMonth']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMissions': totalMissions,
      'activeMissions': activeMissions,
      'completedMissions': completedMissions,
      'pendingRequests': pendingRequests,
      'incomingRequests': incomingRequests,
      'totalRevenue': totalRevenue,
      'monthlyRevenue': monthlyRevenue,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'missionsByStatus': missionsByStatus,
      'revenueByMonth': revenueByMonth,
    };
  }
}

// lib/models/user_profile.dart

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? shopName;
  final String location;
  final List<String> specialties;
  final String experienceLevel;
  final double rating;
  final int reviewCount;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final Map<String, dynamic> preferences;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.shopName,
    required this.location,
    required this.specialties,
    required this.experienceLevel,
    required this.rating,
    required this.reviewCount,
    required this.isPremium,
    this.premiumExpiresAt,
    required this.preferences,
  });

  bool get hasShop => shopName != null && shopName!.isNotEmpty;
  String get displayName => shopName ?? name;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
      shopName: json['shopName'],
      location: json['location'],
      specialties: List<String>.from(json['specialties']),
      experienceLevel: json['experienceLevel'],
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      isPremium: json['isPremium'],
      premiumExpiresAt: json['premiumExpiresAt'] != null 
          ? DateTime.parse(json['premiumExpiresAt']) 
          : null,
      preferences: Map<String, dynamic>.from(json['preferences']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'shopName': shopName,
      'location': location,
      'specialties': specialties,
      'experienceLevel': experienceLevel,
      'rating': rating,
      'reviewCount': reviewCount,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt?.toIso8601String(),
      'preferences': preferences,
    };
  }
}