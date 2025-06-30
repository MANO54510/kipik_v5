// lib/models/user.dart

import 'user_role.dart';

class User {
  final String uid;
  final String name;
  final String? email;
  final String? phone;
  final String? profileImageUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, dynamic>? additionalData;

  const User({
    required this.uid,
    required this.name,
    this.email,
    this.phone,
    this.profileImageUrl,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.additionalData,
  });

  // Factory pour créer depuis Firestore
  factory User.fromFirestore(Map<String, dynamic> data, String uid) {
    return User(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'],
      phone: data['phone'],
      profileImageUrl: data['profileImageUrl'],
      role: UserRoleExtension.fromString(data['role'] ?? 'client'),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastLoginAt: data['lastLoginAt']?.toDate(),
      isActive: data['isActive'] ?? true,
      additionalData: data['additionalData'],
    );
  }

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'role': role.value,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'isActive': isActive,
      'additionalData': additionalData,
    };
  }

  // Méthode copyWith pour modifications
  User copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    Map<String, dynamic>? additionalData,
  }) {
    return User(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Méthodes utilitaires
  bool isClient() => role == UserRole.client;
  bool isTatoueur() => role == UserRole.tatoueur;
  bool isAdmin() => role == UserRole.admin;
  bool isOrganisateur() => role == UserRole.organisateur;

  // Méthode pour vérifier si particulier (client)
  bool isParticulier() => role == UserRole.client;

  String get displayName => name.isNotEmpty ? name : email ?? 'Utilisateur';
  
  String get initials {
    if (name.isEmpty) return 'U';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  String toString() {
    return 'User(uid: $uid, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}