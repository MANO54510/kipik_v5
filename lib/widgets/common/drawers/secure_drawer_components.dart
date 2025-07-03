// lib/widgets/common/drawers/secure_drawer_components.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
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

        // Déconnexion sécurisée via les deux services
        await Future.wait([
          AuthService.instance.signOut(),
          SecureAuthService.instance.signOut(),
        ]);

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
                onPressed: () {
                  // Force la déconnexion et redirection
                  AuthService.instance.signOut();
                  SecureAuthService.instance.signOut();
                  // Navigation sera gérée par les listeners d'auth
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
                // Option alternative pour fermer l'app
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
  static Widget buildConnectionErrorDrawer() {
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
                onPressed: () {
                  // Retry logic
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
}