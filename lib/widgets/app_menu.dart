// lib/widgets/app_menu.dart

import 'package:flutter/material.dart';
import '../utils/auth_helper.dart'; // votre enum UserRole et méthode de récupération du rôle

/// Un item de menu générique
class MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const MenuItem({required this.icon, required this.label, required this.onTap});
}

/// Menu latéral configurable selon le rôle
class AppMenu extends StatelessWidget {
  final UserRole role;
  /// Si false, le menu ne s'affichera pas
  final bool enabled;
  const AppMenu({Key? key, required this.role, this.enabled = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    // Construire dynamiquement la liste
    final items = <MenuItem>[
      MenuItem(
        icon: Icons.home,
        label: 'Accueil',
        onTap: () {
          Navigator.of(context).pushReplacementNamed('/home');
        },
      ),
      MenuItem(
        icon: Icons.logout,
        label: 'Se déconnecter',
        onTap: () {
          // TODO: ajouter la logique de logout
          Navigator.of(context).pushReplacementNamed('/login');
        },
      ),
      if (role == UserRole.client) ...[
        MenuItem(
          icon: Icons.work_outline,
          label: 'Mes projets en cours',
          onTap: () => Navigator.pushNamed(context, '/particulier/projets'),
        ),
        MenuItem(
          icon: Icons.history,
          label: 'Recherches réalisées',
          onTap: () =>
              Navigator.pushNamed(context, '/particulier/recherches'),
        ),
      ],
      if (role == UserRole.tatoueur) ...[
        MenuItem(
          icon: Icons.receipt_long,
          label: 'Devis reçus',
          onTap: () => Navigator.pushNamed(context, '/pro/devis'),
        ),
        MenuItem(
          icon: Icons.calendar_today,
          label: 'Agenda',
          onTap: () => Navigator.pushNamed(context, '/pro/agenda'),
        ),
        MenuItem(
          icon: Icons.account_balance_wallet,
          label: 'Comptabilité',
          onTap: () => Navigator.pushNamed(context, '/pro/compta'),
        ),
      ],
      if (role == UserRole.admin) ...[
        MenuItem(
          icon: Icons.supervisor_account,
          label: 'Gestion utilisateurs',
          onTap: () => Navigator.pushNamed(context, '/admin/users'),
        ),
        MenuItem(
          icon: Icons.analytics,
          label: 'Statistiques',
          onTap: () => Navigator.pushNamed(context, '/admin/stats'),
        ),
      ],
    ];

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black87),
              child: Text(
                'Menu Kipik',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            for (final it in items)
              ListTile(
                leading: Icon(it.icon, color: Colors.white),
                title: Text(it.label, style: const TextStyle(color: Colors.white)),
                onTap: it.onTap,
              ),
          ],
        ),
      ),
    );
  }
}
