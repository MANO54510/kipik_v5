import 'dart:convert';

class ProUser {
  final String id;
  final String email;
  final String? nomEntreprise;
  final String? siret;
  final String? telephone;
  final String? adresse;
  final String? codePostal;
  final String? ville;
  final String? pays;
  final String? siteWeb;
  final String? logo;
  final String? abonnementType;
  final DateTime? abonnementDateDebut;
  final DateTime? abonnementDateFin;
  final bool isActive;
  final List<String> roles;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  ProUser({
    required this.id,
    required this.email,
    this.nomEntreprise,
    this.siret,
    this.telephone,
    this.adresse,
    this.codePostal,
    this.ville,
    this.pays,
    this.siteWeb,
    this.logo,
    this.abonnementType,
    this.abonnementDateDebut,
    this.abonnementDateFin,
    this.isActive = true,
    this.roles = const ['user'],
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory ProUser.fromJson(Map<String, dynamic> json) {
    return ProUser(
      id: json['id'] as String,
      email: json['email'] as String,
      nomEntreprise: json['nomEntreprise'] as String?,
      siret: json['siret'] as String?,
      telephone: json['telephone'] as String?,
      adresse: json['adresse'] as String?,
      codePostal: json['codePostal'] as String?,
      ville: json['ville'] as String?,
      pays: json['pays'] as String?,
      siteWeb: json['siteWeb'] as String?,
      logo: json['logo'] as String?,
      abonnementType: json['abonnementType'] as String?,
      abonnementDateDebut: json['abonnementDateDebut'] != null 
          ? DateTime.parse(json['abonnementDateDebut'] as String) 
          : null,
      abonnementDateFin: json['abonnementDateFin'] != null 
          ? DateTime.parse(json['abonnementDateFin'] as String) 
          : null,
      isActive: json['isActive'] as bool? ?? true,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? ['user'],
      preferences: json['preferences'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nomEntreprise': nomEntreprise,
      'siret': siret,
      'telephone': telephone,
      'adresse': adresse,
      'codePostal': codePostal,
      'ville': ville,
      'pays': pays,
      'siteWeb': siteWeb,
      'logo': logo,
      'abonnementType': abonnementType,
      'abonnementDateDebut': abonnementDateDebut?.toIso8601String(),
      'abonnementDateFin': abonnementDateFin?.toIso8601String(),
      'isActive': isActive,
      'roles': roles,
      'preferences': preferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'ProUser(id: $id, email: $email, nomEntreprise: $nomEntreprise, abonnementType: $abonnementType)';
  }
  
  bool hasRole(String role) {
    return roles.contains(role);
  }
  
  bool get isAbonnementActif {
    if (abonnementDateFin == null) {
      return false;
    }
    return abonnementDateFin!.isAfter(DateTime.now());
  }
  
  int get joursRestantsAbonnement {
    if (abonnementDateFin == null) {
      return 0;
    }
    return abonnementDateFin!.difference(DateTime.now()).inDays;
  }
  
  ProUser copyWith({
    String? id,
    String? email,
    String? nomEntreprise,
    String? siret,
    String? telephone,
    String? adresse,
    String? codePostal,
    String? ville,
    String? pays,
    String? siteWeb,
    String? logo,
    String? abonnementType,
    DateTime? abonnementDateDebut,
    DateTime? abonnementDateFin,
    bool? isActive,
    List<String>? roles,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProUser(
      id: id ?? this.id,
      email: email ?? this.email,
      nomEntreprise: nomEntreprise ?? this.nomEntreprise,
      siret: siret ?? this.siret,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      codePostal: codePostal ?? this.codePostal,
      ville: ville ?? this.ville,
      pays: pays ?? this.pays,
      siteWeb: siteWeb ?? this.siteWeb,
      logo: logo ?? this.logo,
      abonnementType: abonnementType ?? this.abonnementType,
      abonnementDateDebut: abonnementDateDebut ?? this.abonnementDateDebut,
      abonnementDateFin: abonnementDateFin ?? this.abonnementDateFin,
      isActive: isActive ?? this.isActive,
      roles: roles ?? this.roles,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}