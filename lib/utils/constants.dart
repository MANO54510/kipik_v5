// Fichier : lib/utils/constants.dart
// Description : Constantes non visuelles pour l'application Kipik

// ✅ SUPPRIMÉ : enum UserRole et UserRoleExtension (définis dans models/user_role.dart)
// ❌ ÉVITER LES DOUBLONS : Ces définitions sont maintenant dans models/user_role.dart

class Constants {
  // URL de base de l'API
  static const String apiBaseUrl = 'https://api.kipik.fr/v5';
  
  // Durées en millisecondes
  static const int snackBarDuration = 3000;
  static const int splashScreenDuration = 2000;
  static const int animationDuration = 300;
  
  // Tailles
  static const double appBarHeight = 56.0;
  static const double drawerWidth = 280.0;
  static const double borderRadius = 8.0;
  static const double cardElevation = 2.0;
  static const double buttonHeight = 48.0;
  
  // Textes génériques
  static const String appName = 'Kipik';
  static const String errorMessageGeneric = 'Une erreur est survenue. Veuillez réessayer.';
  static const String loadingMessage = 'Chargement en cours...';
  static const String noDataMessage = 'Aucune donnée disponible.';
  
  // Préférences utilisateur - clés
  static const String prefsDarkMode = 'dark_mode';
  static const String prefsLanguage = 'language';
  static const String prefsUserToken = 'user_token';
  static const String prefsRefreshToken = 'refresh_token';
  static const String prefsUserType = 'user_type';
  static const String prefsFirstLogin = 'first_login';
  
  // Routes principales
  static const String routeHome = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';
  static const String routePro = '/pro';
  static const String routeClient = '/client';
  static const String routeAidePro = '/aide-pro';
  static const String routeAideClient = '/aide-client';
  
  // Couleurs - Noms des couleurs pour référence (les couleurs réelles seront dans les thèmes)
  static const String primaryColorName = 'bleu_kipik';
  static const String secondaryColorName = 'vert_kipik';
  static const String accentColorName = 'orange_kipik';
  static const String errorColorName = 'rouge_kipik';
  
  // Versions
  static const String appVersion = '5.0.0';
  static const int appBuild = 500;
  
  // URLs externes
  static const String urlCGV = 'https://www.kipik.fr/conditions-generales-vente';
  static const String urlCGU = 'https://www.kipik.fr/conditions-generales-utilisation';
  static const String urlPrivacy = 'https://www.kipik.fr/politique-confidentialite';
  static const String urlSupport = 'https://support.kipik.fr';
  static const String urlWebsite = 'https://www.kipik.fr';
  static const String urlFacebook = 'https://www.facebook.com/kipikapp';
  static const String urlTwitter = 'https://www.twitter.com/kipikapp';
  static const String urlInstagram = 'https://www.instagram.com/kipikapp';
  
  // Paramètres techniques
  static const int apiTimeoutSeconds = 30;
  static const int maxUploadSizeMB = 10;
  static const int maxImageResolution = 2048;
  static const int paginationLimit = 20;
  
  // Valeurs par défaut
  static const String defaultLanguage = 'fr';
  static const String defaultCountry = 'FR';
  static const String defaultCurrency = 'EUR';
  static const String defaultDateFormat = 'dd/MM/yyyy';
  static const String defaultTimeFormat = 'HH:mm';
}

// Constantes de préférences utilisateur pour compatibilité avec votre nouveau style k*
const String kPrefUserId = 'userId';
const String kPrefAuthToken = 'authToken';
const String kPrefRefreshToken = 'refreshToken';
const String kPrefIsLoggedIn = 'isLoggedIn';
const String kPrefIsDarkMode = 'isDarkMode';
const String kPrefLanguage = 'language';
const String kPrefNotificationsEnabled = 'notificationsEnabled';
const String kPrefLocationEnabled = 'locationEnabled';
const String kPrefLastSync = 'lastSync';
const String kPrefOnboardingCompleted = 'onboardingCompleted';
const String kPrefUserType = 'userType'; // 'client', 'pro', 'admin'
const String kPrefSelectedCategories = 'selectedCategories';
const String kPrefSearchRadius = 'searchRadius';

// ✅ Types d'utilisateurs (compatibilité avec les anciennes constantes)
// Ces constantes font référence aux valeurs string, pas aux enums
const String kUserTypeClient = 'client';
const String kUserTypePro = 'tatoueur'; // CORRECTION : était 'pro'
const String kUserTypeAdmin = 'admin';
const String kUserTypeOrganisateur = 'organisateur'; // AJOUT

// Paramètres de pagination
const int kMaxItemsPerPage = 50;
const int kDefaultItemsPerPage = 20;

// Paramètres de géolocalisation
const double kDefaultRadius = 10.0; // km
const double kMinRadius = 1.0; // km
const double kMaxRadius = 50.0; // km

// Délais de rafraîchissement
const Duration kLocationRefreshInterval = Duration(minutes: 5);
const Duration kDataRefreshInterval = Duration(minutes: 15);
const Duration kTokenRefreshInterval = Duration(hours: 1);

// Paramètres des fichiers
const int kMaxFileSize = 10 * 1024 * 1024; // 10 Mo
const List<String> kAllowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif'];
const List<String> kAllowedDocumentExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'];

// Paramètres de notifications
const String kFcmTopicAllUsers = 'all_users';
const String kFcmTopicProUsers = 'pro_users';
const String kFcmTopicClientUsers = 'client_users';

// Messages d'erreur
const String kNetworkErrorMessage = 'Erreur de connexion. Vérifiez votre connexion Internet et réessayez.';
const String kServerErrorMessage = 'Erreur serveur. Veuillez réessayer plus tard.';
const String kTimeoutErrorMessage = 'Délai d\'attente dépassé. Veuillez réessayer.';
const String kAuthErrorMessage = 'Erreur d\'authentification. Veuillez vous reconnecter.';
const String kUnknownErrorMessage = 'Une erreur s\'est produite. Veuillez réessayer.';
const String kPermissionDeniedMessage = 'Permission refusée. Vérifiez vos paramètres d\'autorisation.';

// Messages de succès
const String kSaveSuccessMessage = 'Enregistré avec succès';
const String kUpdateSuccessMessage = 'Mis à jour avec succès';
const String kDeleteSuccessMessage = 'Supprimé avec succès';
const String kCreateSuccessMessage = 'Créé avec succès';

// Dates et formats
const String kDateFormat = 'dd/MM/yyyy';
const String kTimeFormat = 'HH:mm';
const String kDateTimeFormat = 'dd/MM/yyyy HH:mm';
const String kDayMonthFormat = 'dd MMM';
const String kMonthYearFormat = 'MMM yyyy';

// Paramètres d'abonnement
const List<String> kSubscriptionTypes = ['Standard', 'Premium', 'Enterprise'];
const double kStandardSubscriptionPrice = 29.99;
const double kPremiumSubscriptionPrice = 59.99;
const double kEnterpriseSubscriptionPrice = 199.99;

// États des commandes
const String kOrderStatusPending = 'pending';
const String kOrderStatusConfirmed = 'confirmed';
const String kOrderStatusInProgress = 'in_progress';
const String kOrderStatusCompleted = 'completed';
const String kOrderStatusCancelled = 'cancelled';
const String kOrderStatusRefunded = 'refunded';

// Paramètres de recherche
const int kMinSearchLength = 2;
const int kSearchHistoryLimit = 10;
const int kMaxRecentSearches = 5;

// Paramètres de filtre
const double kMinPriceFilter = 0.0;
const double kMaxPriceFilter = 1000.0;
const double kInitialMinPrice = 0.0;
const double kInitialMaxPrice = 500.0;

// Paramètres d'authentification
const int kPasswordMinLength = 8;
const int kOtpLength = 6;
const Duration kOtpValidityDuration = Duration(minutes: 5);

// ✅ ENUMS SÉPARÉS (pas de conflit avec UserRole)
// Ces enums sont différents de UserRole et peuvent rester ici

enum ProjectStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}

enum NotificationType {
  info,
  warning,
  error,
  success,
  appointment,
  payment,
  message,
}

// ✅ HELPERS POUR CONVERSION USEROLE (si nécessaire)
// Fonctions utilitaires pour travailler avec les rôles depuis ce fichier

class UserRoleConstants {
  // Constantes string pour les rôles (compatibilité)
  static const String client = 'client';
  static const String tatoueur = 'tatoueur';
  static const String organisateur = 'organisateur';
  static const String admin = 'admin';
  
  // Liste de tous les rôles disponibles
  static const List<String> allRoles = [client, tatoueur, organisateur, admin];
  
  // Vérifier si un string est un rôle valide
  static bool isValidRole(String role) {
    return allRoles.contains(role.toLowerCase());
  }
  
  // Obtenir le nom d'affichage d'un rôle
  static String getDisplayName(String role) {
    switch (role.toLowerCase()) {
      case client:
        return 'Client';
      case tatoueur:
        return 'Tatoueur';
      case organisateur:
        return 'Organisateur';
      case admin:
        return 'Administrateur';
      default:
        return 'Utilisateur';
    }
  }
}