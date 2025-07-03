// lib/widgets/drawer_factory.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_organizer.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_admin.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_particulier.dart';
import 'package:kipik_v5/widgets/common/drawers/secure_drawer_components.dart';

class DrawerFactory {
  // Ne pas instancier, on utilise uniquement la méthode statique
  DrawerFactory._();

  static Widget of(BuildContext context) {
    // ✅ Utiliser le SecureAuthService en priorité
    if (!SecureAuthService.instance.isAuthenticated) {
      return _UnauthenticatedDrawer();
    }

    final currentRole = SecureAuthService.instance.currentUserRole;
    
    // ✅ Vérifier que le rôle est défini
    if (currentRole == null) {
      return SecureDrawerFactory.buildFallbackDrawer();
    }

    // ✅ Retourner le drawer approprié selon le rôle
    switch (currentRole) {
      case UserRole.admin:
        return const CustomDrawerAdmin();
      case UserRole.organisateur:
        return const CustomDrawerOrganizer();
      case UserRole.tatoueur:
        return const CustomDrawerKipik();
      case UserRole.client:
        return const CustomDrawerParticulier();
      default:
        return SecureDrawerFactory.buildFallbackDrawer();
    }
  }

  /// Méthode pour débugger le drawer affiché
  static String getDrawerTypeDebug() {
    if (!SecureAuthService.instance.isAuthenticated) {
      return 'Unauthenticated';
    }
    
    final role = SecureAuthService.instance.currentUserRole;
    return role?.name ?? 'Unknown';
  }

  /// Méthode pour forcer le refresh du drawer
  static void refreshDrawer(BuildContext context) {
    // Fermer le drawer actuel
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
    
    // Attendre un frame puis rouvrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Scaffold.of(context).openDrawer();
    });
  }
}

/// ✅ Drawer pour utilisateur non connecté (classe séparée)
class _UnauthenticatedDrawer extends StatelessWidget {
  const _UnauthenticatedDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ou icône principale
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.person_off,
                size: 64,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Titre principal
            const Text(
              'Non connecté',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'PermanentMarker',
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            const Text(
              'Connectez-vous pour accéder à votre espace personnalisé et découvrir toutes les fonctionnalités de Kipik.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Bouton de connexion principal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/login');
                },
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  'Se connecter',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Bouton d'inscription
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/register');
                },
                icon: const Icon(Icons.person_add, color: Colors.white70),
                label: const Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.white30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Divider avec texte
            Row(
              children: [
                Expanded(child: Container(height: 1, color: Colors.grey.withOpacity(0.3))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OU',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: Colors.grey.withOpacity(0.3))),
              ],
            ),
            const SizedBox(height: 24),
            
            // Actions de navigation publique
            _PublicMenuItem(
              icon: Icons.map_outlined,
              title: 'Carte des conventions',
              subtitle: 'Découvrir les événements tatouage',
              onTap: () {
                Navigator.of(context).pushNamed('/conventions/public');
              },
            ),
            const SizedBox(height: 12),
            _PublicMenuItem(
              icon: Icons.search_outlined,
              title: 'Trouver un tatoueur',
              subtitle: 'Rechercher des professionnels',
              onTap: () {
                Navigator.of(context).pushNamed('/search/tattooers');
              },
            ),
            const SizedBox(height: 12),
            _PublicMenuItem(
              icon: Icons.info_outline,
              title: 'À propos de Kipik',
              subtitle: 'Découvrir la plateforme',
              onTap: () {
                Navigator.of(context).pushNamed('/about');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Widget pour les éléments de menu public
class _PublicMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PublicMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}