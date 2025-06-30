// lib/models/user_role.dart

enum UserRole {
  client,
  tatoueur,
  admin,
  organisateur,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.client:
        return 'Client';
      case UserRole.tatoueur:
        return 'Tatoueur';
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.organisateur:
        return 'Organisateur';
    }
  }

  String get value {
    switch (this) {
      case UserRole.client:
        return 'client';
      case UserRole.tatoueur:
        return 'tatoueur';
      case UserRole.admin:
        return 'admin';
      case UserRole.organisateur:
        return 'organisateur';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'client':
        return UserRole.client;
      case 'tatoueur':
        return UserRole.tatoueur;
      case 'admin':
        return UserRole.admin;
      case 'organisateur':
        return UserRole.organisateur;
      default:
        return UserRole.client; // Par défaut
    }
  }
}