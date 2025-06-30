// lib/widgets/drawer_factory.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_organizer.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_admin.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_particulier.dart';

class DrawerFactory {
  // Ne pas instancier, on utilise uniquement la méthode statique
  DrawerFactory._();

  static Widget of(BuildContext context) {
    final user = AuthService.instance.currentUser;
    
    // Si pas d'utilisateur connecté, retourner un drawer par défaut ou vide
    if (user == null) {
      return const Drawer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Non connecté',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Veuillez vous connecter',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Maintenant on peut utiliser user! en toute sécurité
    if (AuthService.instance.isAdmin()) {
      return const CustomDrawerAdmin();
    } else if (AuthService.instance.isOrganisateur()) {
      return const CustomDrawerOrganizer();
    } else if (AuthService.instance.isTatoueur()) {
      return const CustomDrawerKipik();
    } else {
      // Client particulier par défaut
      return const CustomDrawerParticulier();
    }
  }
}
