// lib/widgets/common/drawers/secure_drawer_components.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ SEUL SERVICE UTILISÉ
import 'package:kipik_v5/models/user_role.dart';

// Mixin de sécurité pour les drawers
mixin SecureDrawerMixin {
  /// Méthode de déconnexion sécurisée
  Future<void> secureSignOut(BuildContext context) async {
    try {
      // Afficher un dialogue de confirmation
      final shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Déconnexion',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Déconnecter'),
            ),
          ],
        ),
      );

      if (shouldSignOut == true) {
        // Afficher un indicateur de chargement
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
          );
        }

        // ✅ CHANGÉ : Déconnexion uniquement via SecureAuthService
        await SecureAuthService.instance.signOut();

        // Navigation vers la page de connexion
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login', // Remplacez par votre route de connexion
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Fermer le dialog de chargement si ouvert
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Gestion d'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () => secureSignOut(context),
            ),
          ),
        );
      }
    }
  }

  /// Méthode pour naviguer en sécurité
  void secureNavigate(BuildContext context, Widget page) {
    // Vérifier l'authentification avant navigation
    if (!SecureAuthService.instance.isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Méthode pour afficher un message de développement
  void showDevelopmentMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature en cours de développement'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// ✅ NOUVEAU : Vérifier si l'utilisateur a le bon rôle
  bool hasRequiredRole(UserRole requiredRole) {
    final currentRole = SecureAuthService.instance.currentUserRole;
    return currentRole == requiredRole;
  }

  /// ✅ NOUVEAU : Obtenir les informations utilisateur de manière sécurisée
  Map<String, dynamic>? get currentUserData {
    return SecureAuthService.instance.currentUser;
  }

  /// ✅ NOUVEAU : Vérifier l'état d'authentification
  bool get isAuthenticated {
    return SecureAuthService.instance.isAuthenticated;
  }
}

// Factory pour créer des drawers de secours
class SecureDrawerFactory {
  SecureDrawerFactory._(); // Constructeur privé

  /// Construit un drawer de secours en cas de problème de sécurité
  static Widget buildFallbackDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.security,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Accès non autorisé',
              style: TextStyle(
                fontSize: 20,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Un problème d\'authentification a été détecté. Veuillez vous reconnecter pour accéder à votre espace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // ✅ CHANGÉ : Force la déconnexion uniquement via SecureAuthService
                  try {
                    await SecureAuthService.instance.signOut();
                    // Navigation sera gérée par les listeners d'auth
                  } catch (e) {
                    // En cas d'erreur, forcer la navigation
                    // Cette logique peut être adaptée selon votre architecture
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Retour à la connexion',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // Option alternative pour contacter le support
                // Vous pouvez intégrer votre système de support ici
              },
              icon: const Icon(Icons.info_outline, color: Colors.grey, size: 16),
              label: const Text(
                'Contacter le support',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un drawer de chargement temporaire
  static Widget buildLoadingDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vérification des autorisations',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un drawer d'erreur de connexion
  static Widget buildConnectionErrorDrawer({VoidCallback? onRetry}) {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Problème de connexion',
              style: TextStyle(
                fontSize: 18,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Impossible de vérifier vos autorisations. Vérifiez votre connexion internet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry ?? () {
                  // ✅ AMÉLIORÉ : Callback personnalisable pour retry
                  // Logique de retry par défaut si aucun callback fourni
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ NOUVEAU : Drawer spécifique pour le mode démo
  static Widget buildDemoModeDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.preview,
                size: 64,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mode Démonstration',
              style: TextStyle(
                fontSize: 20,
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Vous utilisez actuellement l\'application en mode démonstration avec des données factices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Retour au mode production ou page de connexion
                  await SecureAuthService.instance.signOut();
                },
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: const Text(
                  'Quitter la démo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ NOUVEAU : Drawer pour rôle insuffisant
  static Widget buildInsufficientRoleDrawer({required UserRole currentRole, required UserRole requiredRole}) {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 64,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Accès limité',
              style: TextStyle(
                fontSize: 20,
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Votre rôle actuel ($currentRole) ne permet pas d\'accéder à cet espace. Rôle requis: $requiredRole.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigation vers l'espace approprié selon le rôle
                },
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text(
                  'Retour à mon espace',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}