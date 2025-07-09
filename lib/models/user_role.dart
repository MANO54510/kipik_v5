// lib/models/user_role.dart

/// Énumération des différents rôles d'utilisateurs dans l'application Kipik
enum UserRole {
  /// Client particulier cherchant un tatoueur
  client,
  
  /// Tatoueur professionnel proposant ses services
  tatoueur,
  
  /// Administrateur de la plateforme
  admin,
  
  /// Organisateur d'événements tattoo (conventions, salons, etc.)
  organisateur,
  
  /// ✅ VALEUR AJOUTÉE : Alias pour compatibilité
  particulier,
}

/// Extension pour ajouter des méthodes utiles à l'énumération UserRole
extension UserRoleExtension on UserRole {
  /// Retourne le nom d'affichage du rôle
  String get name {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return 'Particulier';
      case UserRole.tatoueur:
        return 'Tatoueur';
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.organisateur:
        return 'Organisateur';
    }
  }

  /// Retourne la valeur string du rôle (pour base de données)
  String get value {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return 'particulier';
      case UserRole.tatoueur:
        return 'tatoueur';
      case UserRole.admin:
        return 'admin';
      case UserRole.organisateur:
        return 'organisateur';
    }
  }

  /// Retourne une description du rôle
  String get description {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return 'Particulier recherchant un tatoueur pour ses projets';
      case UserRole.tatoueur:
        return 'Professionnel du tatouage proposant ses services';
      case UserRole.admin:
        return 'Administrateur de la plateforme Kipik';
      case UserRole.organisateur:
        return 'Organisateur d\'événements tattoo (conventions, salons)';
    }
  }

  /// Retourne l'icône associée au rôle
  String get icon {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return '👤';
      case UserRole.tatoueur:
        return '🎨';
      case UserRole.admin:
        return '👑';
      case UserRole.organisateur:
        return '🎪';
    }
  }

  /// Retourne la couleur associée au rôle (hex)
  String get colorHex {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return '#2196F3'; // Bleu
      case UserRole.tatoueur:
        return '#FF9800'; // Orange
      case UserRole.admin:
        return '#F44336'; // Rouge
      case UserRole.organisateur:
        return '#9C27B0'; // Violet
    }
  }

  /// Retourne les permissions du rôle
  List<String> get permissions {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return [
          'create_project',
          'request_quote',
          'book_appointment',
          'rate_tattooer',
          'send_message',
          'view_flash_catalog',
          'manage_favorites',
          'view_booking_history',
        ];
      case UserRole.tatoueur:
        return [
          'create_portfolio',
          'create_flash',
          'send_quote',
          'manage_appointments',
          'receive_payments',
          'create_events',
          'send_message',
          'view_analytics',
          'manage_flash_catalog',
          'accept_bookings',
        ];
      case UserRole.admin:
        return [
          'manage_users',
          'manage_content',
          'view_analytics',
          'moderate_reports',
          'manage_payments',
          'system_settings',
          'manage_platform',
          'view_all_data',
        ];
      case UserRole.organisateur:
        return [
          'create_event',
          'manage_participants',
          'send_invitations',
          'event_analytics',
          'send_message',
          'manage_conventions',
        ];
    }
  }

  /// Vérifie si le rôle a une permission donnée
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  /// Retourne la route de la page d'accueil pour ce rôle
  String get homeRoute {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return '/particulier/dashboard';
      case UserRole.tatoueur:
        return '/pro/dashboard';
      case UserRole.admin:
        return '/admin/dashboard';
      case UserRole.organisateur:
        return '/organisateur/dashboard';
    }
  }

  /// Retourne la route de la page d'inscription pour ce rôle
  String get signupRoute {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return '/inscription/particulier';
      case UserRole.tatoueur:
        return '/inscription/pro';
      case UserRole.admin:
        return '/admin/signup';
      case UserRole.organisateur:
        return '/inscription/organisateur';
    }
  }

  /// Vérifie si le rôle peut accéder à une fonctionnalité premium
  bool get isPremiumRole {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return false;
      case UserRole.tatoueur:
        return true;
      case UserRole.admin:
        return true;
      case UserRole.organisateur:
        return true;
    }
  }

  /// Retourne le niveau de priorité du rôle (pour support, notifications, etc.)
  int get priority {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return 1;
      case UserRole.tatoueur:
        return 2;
      case UserRole.organisateur:
        return 3;
      case UserRole.admin:
        return 4;
    }
  }

  /// Créer un UserRole à partir d'une string
  static UserRole fromString(String role) {
    switch (role.toLowerCase().trim()) {
      case 'client':
      case 'particulier':
        return UserRole.particulier; // ✅ Retourne particulier directement
      case 'tatoueur':
      case 'tattooer':
      case 'pro':
        return UserRole.tatoueur;
      case 'admin':
      case 'administrateur':
        return UserRole.admin;
      case 'organisateur':
      case 'organizer':
      case 'orga':
        return UserRole.organisateur;
      default:
        return UserRole.particulier; // ✅ Par défaut particulier
    }
  }

  /// Créer un UserRole à partir d'un index
  static UserRole fromIndex(int index) {
    switch (index) {
      case 0:
        return UserRole.particulier; // ✅ Retourne particulier
      case 1:
        return UserRole.tatoueur;
      case 2:
        return UserRole.admin;
      case 3:
        return UserRole.organisateur;
      default:
        return UserRole.particulier; // ✅ Par défaut particulier
    }
  }

  /// Retourne l'index du rôle
  int get index {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return 0;
      case UserRole.tatoueur:
        return 1;
      case UserRole.admin:
        return 2;
      case UserRole.organisateur:
        return 3;
    }
  }

  /// Retourne tous les rôles disponibles
  static List<UserRole> get allRoles => UserRole.values;

  /// Retourne les rôles publics (excluant admin)
  static List<UserRole> get publicRoles => [
        UserRole.particulier, // ✅ Utilise particulier
        UserRole.tatoueur,
        UserRole.organisateur,
      ];

  /// Retourne les rôles professionnels
  static List<UserRole> get professionalRoles => [
        UserRole.tatoueur,
        UserRole.organisateur,
      ];

  /// Vérifie si le rôle est un rôle professionnel
  bool get isProfessional => professionalRoles.contains(this);

  /// Vérifie si le rôle est administrateur
  bool get isAdmin => this == UserRole.admin;

  /// Vérifie si le rôle est client/particulier
  bool get isClient => this == UserRole.client || this == UserRole.particulier;

  /// ✅ ALIAS AJOUTÉ : Méthode pour compatibilité
  bool get isParticulier => this == UserRole.client || this == UserRole.particulier;

  /// Vérifie si le rôle est tatoueur
  bool get isTattooer => this == UserRole.tatoueur;

  /// Vérifie si le rôle est organisateur
  bool get isOrganizer => this == UserRole.organisateur;

  /// Retourne un Map pour sérialisation JSON
  Map<String, dynamic> toJson() {
    return {
      'role': value,
      'name': name,
      'description': description,
      'permissions': permissions,
      'priority': priority,
      'isProfessional': isProfessional,
    };
  }

  /// Créer un UserRole à partir d'un Map JSON
  static UserRole fromJson(Map<String, dynamic> json) {
    return fromString(json['role'] ?? 'particulier');
  }

  /// ✅ MÉTHODES UTILITAIRES AJOUTÉES pour Kipik
  
  /// Retourne le thème de couleur pour l'interface utilisateur
  String get primaryColorHex {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return '#E53E3E'; // Rouge Kipik pour particuliers
      case UserRole.tatoueur:
        return '#E53E3E'; // Rouge Kipik pour pros
      case UserRole.admin:
        return '#2D3748'; // Gris foncé pour admin
      case UserRole.organisateur:
        return '#805AD5'; // Violet pour organisateurs
    }
  }

  /// Retourne les fonctionnalités disponibles pour ce rôle
  List<String> get availableFeatures {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return [
          'browse_flashs',
          'book_appointments',
          'chat_with_artists',
          'manage_bookings',
          'rate_experience',
          'save_favorites',
        ];
      case UserRole.tatoueur:
        return [
          'create_flashs',
          'manage_calendar',
          'accept_bookings',
          'chat_with_clients',
          'payment_management',
          'analytics_dashboard',
          'portfolio_management',
        ];
      case UserRole.admin:
        return [
          'user_management',
          'platform_analytics',
          'content_moderation',
          'payment_oversight',
          'system_configuration',
        ];
      case UserRole.organisateur:
        return [
          'event_creation',
          'artist_management',
          'ticket_sales',
          'event_promotion',
        ];
    }
  }

  /// Vérifie si une fonctionnalité est disponible pour ce rôle
  bool hasFeature(String feature) {
    return availableFeatures.contains(feature);
  }

  /// Retourne l'AppBar appropriée selon le rôle
  String get appBarType {
    switch (this) {
      case UserRole.client:
      case UserRole.particulier: // ✅ Cas ajouté
        return 'particulier';
      case UserRole.tatoueur:
        return 'pro';
      case UserRole.admin:
        return 'admin';
      case UserRole.organisateur:
        return 'organisateur';
    }
  }
}