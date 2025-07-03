// lib/routes/router.dart
import 'package:flutter/material.dart';

// Authentification
import 'package:kipik_v5/pages/auth/welcome_page.dart';
import 'package:kipik_v5/pages/auth/connexion_page.dart';
import 'package:kipik_v5/pages/auth/inscription_page.dart';

// Partie Particulier
import 'package:kipik_v5/pages/particulier/accueil_particulier_page.dart';
import 'package:kipik_v5/pages/particulier/recherche_tatoueur_page.dart';
import 'package:kipik_v5/pages/particulier/mes_devis_page.dart';
import 'package:kipik_v5/pages/particulier/mes_projets_particulier_page.dart';
import 'package:kipik_v5/pages/particulier/messages_particulier_page.dart';
import 'package:kipik_v5/pages/particulier/profil_particulier_page.dart';
import 'package:kipik_v5/pages/particulier/inspirations_page.dart';
import 'package:kipik_v5/pages/particulier/favoris_page.dart';
import 'package:kipik_v5/pages/particulier/notifications_page.dart';
import 'package:kipik_v5/pages/particulier/parametres_page.dart';
import 'package:kipik_v5/pages/particulier/aide_support_page.dart';

// Partie Pro - Pages principales
import 'package:kipik_v5/pages/pro/home_page_pro.dart';
import 'package:kipik_v5/pages/pro/dashboard_page.dart';
import 'package:kipik_v5/pages/pro/profil_tatoueur.dart';
import 'package:kipik_v5/pages/pro/inscription_pro_page.dart';
import 'package:kipik_v5/pages/pro/notifications_pro_page.dart';
import 'package:kipik_v5/pages/pro/parametres_pro_page.dart';
import 'package:kipik_v5/pages/pro/aide_pro_page.dart';

// Partie Pro - Modules fonctionnels
import 'package:kipik_v5/pages/pro/agenda/pro_agenda_home_page.dart';
import 'package:kipik_v5/pages/pro/comptabilite/comptabilite_page.dart';
import 'package:kipik_v5/pages/pro/mes_realisations_page.dart';
import 'package:kipik_v5/pages/pro/mon_shop_page.dart';

// Partie Pro - Module Fournisseurs
import 'package:kipik_v5/pages/pro/suppliers/suppliers_list_page.dart';
import 'package:kipik_v5/pages/pro/suppliers/supplier_detail_page.dart';
import 'package:kipik_v5/pages/pro/suppliers/order_history_page.dart';

// Conventions
import 'package:kipik_v5/pages/conventions/convention_list_page.dart';
import 'package:kipik_v5/pages/conventions/convention_admin_page.dart';

// Partie Organisateur
import 'package:kipik_v5/pages/organisateur/organisateur_dashboard_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_conventions_page.dart';
import 'package:kipik_v5/pages/organisateur/event_edit_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_inscriptions_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_billeterie_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_marketing_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_settings_page.dart';

// Administration - Dashboard principal et espaces spécialisés
import 'package:kipik_v5/pages/admin/admin_dashboard_home.dart';
import 'package:kipik_v5/pages/admin/admin_setup_page.dart';
import 'package:kipik_v5/pages/admin/pros/admin_pros_management_page.dart';
import 'package:kipik_v5/pages/admin/clients/admin_clients_management_page.dart';
import 'package:kipik_v5/pages/admin/organizers/admin_organizers_management_page.dart';
import 'package:kipik_v5/pages/admin/users/admin_user_search_page.dart';
import 'package:kipik_v5/pages/admin/users/admin_user_detail_page.dart';
import 'package:kipik_v5/pages/admin/admin_free_codes_page.dart';
import 'package:kipik_v5/pages/admin/admin_referrals_page.dart';

// ✅ NOUVEAU: Page de setup temporaire pour premier admin
import 'package:kipik_v5/pages/temp/first_setup_page.dart';

// ✅ AJOUTÉ: Import pour AdminRouteGuard
import 'package:kipik_v5/services/auth/secure_auth_service.dart';

// Pages légales
import 'package:kipik_v5/pages/legal/cgu_page.dart';
import 'package:kipik_v5/pages/legal/cgv_page.dart';

// Définition des routes statiques
final Map<String, WidgetBuilder> appRoutes = {
  // ===== AUTHENTIFICATION =====
  '/welcome': (_) => const WelcomePage(),
  '/connexion': (_) => const ConnexionPage(),
  '/inscription': (_) => const InscriptionPage(),
  '/pro/inscriptionPro': (_) => InscriptionProPage(),

  // ===== SETUP INITIAL (TEMPORAIRE) =====
  '/first-setup': (_) => const FirstSetupPage(), // ✅ NOUVEAU: Page de setup initiale

  // ===== PARTICULIER =====
  // Pages principales
  '/home': (_) => const AccueilParticulierPage(),
  '/profil': (_) => const ProfilParticulierPage(),
  '/notifications': (_) => const NotificationsPage(),
  '/paramètres': (_) => const ParametresPage(),
  '/aide': (_) => const AideSupportPage(),
  
  // Fonctionnalités
  '/recherche_tatoueur': (_) => const RechercheTatoueurPage(),
  '/suivi_devis': (_) => const MesDevisPage(),
  '/mes_projets': (_) => const MesProjetsParticulierPage(),
  '/messages': (_) => const MessagesParticulierPage(),
  '/inspirations': (_) => const InspirationsPage(),
  '/favoris': (_) => const FavorisPage(),

  // ===== PROFESSIONNEL =====
  // Pages principales
  '/pro': (_) => const HomePagePro(),
  '/pro/dashboard': (_) => const DashboardPage(),
  '/pro/profil': (_) => const ProfilTatoueur(),
  '/pro/notifications': (_) => const NotificationsProPage(),
  '/pro/parametres': (_) => const ParametresProPage(),
  '/pro/aide': (_) => const AideProPage(),
  
  // Fonctionnalités de base
  '/pro/agenda': (_) => const ProAgendaHomePage(),
  '/pro/comptabilite': (_) => const ComptabilitePage(),
  '/pro/realisations': (_) => const MesRealisationsPage(),
  '/pro/shop': (_) => const MonShopPage(),
  
  // Module Fournisseurs
  '/pro/suppliers': (_) => const SuppliersListPage(),
  
  // ===== CONVENTIONS =====
  '/conventions': (_) => const ConventionListPage(),
  '/conventions/admin': (_) => const ConventionAdminPage(),
  
  // ===== ADMINISTRATION =====
  // Dashboard principal et navigation
  '/admin': (_) => const AdminDashboardHome(),
  '/admin/dashboard': (_) => const AdminDashboardHome(),
  '/admin/setup': (_) => const AdminSetupPage(), // ✅ Page de setup admin sécurisée
  
  // Espaces de gestion spécialisés
  '/admin/pros': (_) => const AdminProsManagementPage(),
  '/admin/clients': (_) => const AdminClientsManagementPage(),
  '/admin/organizers': (_) => const AdminOrganizersManagementPage(),
  
  // Recherche et gestion utilisateurs
  '/admin/users/search': (_) => const AdminUserSearchPage(),
  
  // Codes promo et parrainages
  '/admin/free-codes': (_) => const AdminFreeCodesPage(),
  '/admin/referrals': (_) => const AdminReferralsPage(),

  // ===== PAGES LÉGALES =====
  '/cgu': (_) => const CGUPage(),
  '/cgv': (_) => const CGVPage(),

  // ===== ORGANISATEUR =====
  '/organisateur/dashboard': (_) => const OrganisateurDashboardPage(),
  '/organisateur/conventions': (_) => const OrganisateurConventionsPage(),
  '/organisateur/conventions/create': (_) => const EventEditPage(),
  '/organisateur/inscriptions': (_) => const OrganisateurInscriptionsPage(),
  '/organisateur/billeterie': (_) => const OrganisateurBilleteriePage(),
  '/organisateur/marketing': (_) => const OrganisateurMarketingPage(),
  '/organisateur/settings': (_) => const OrganisateurSettingsPage(),
};

// ✅ NOUVEAU: Guard de sécurité pour les routes admin
class AdminRouteGuard {
  static Future<bool> canAccessAdminSetup() async {
    try {
      // Import direct de SecureAuthService
      final exists = await SecureAuthService.instance.checkFirstAdminExists();
      return !exists; // Accessible seulement si aucun admin n'existe
    } catch (e) {
      return true; // En cas d'erreur, permettre l'accès (première installation)
    }
  }
}

// Gestion des routes dynamiques
Route<dynamic>? generateRoute(RouteSettings settings) {
  // Analyse du nom de la route
  final uri = Uri.parse(settings.name ?? '');
  final pathSegments = uri.pathSegments;
  
  // ✅ NOUVEAU: Sécurité spéciale pour la route admin setup
  if (settings.name == '/admin/setup') {
    return MaterialPageRoute(
      builder: (context) => FutureBuilder<bool>(
        future: AdminRouteGuard.canAccessAdminSetup(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Vérification accès admin...'),
                  ],
                ),
              ),
            );
          }
          
          if (snapshot.data == true) {
            // Accès autorisé - aucun admin n'existe encore
            return const AdminSetupPage();
          } else {
            // Accès refusé - admin déjà créé
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/connexion');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('L\'administrateur principal a déjà été créé'),
                  backgroundColor: Colors.orange,
                ),
              );
            });
            return Scaffold(
              body: Center(
                child: Text('Redirection...'),
              ),
            );
          }
        },
      ),
    );
  }
  
  // ===== ROUTES DYNAMIQUES - FOURNISSEURS =====
  if (pathSegments.length >= 3 && pathSegments[0] == 'pro' && pathSegments[1] == 'suppliers') {
    final action = pathSegments[2];
    final id = pathSegments.length > 3 ? pathSegments[3] : '';
    
    switch (action) {
      case 'details':
        return MaterialPageRoute(
          builder: (_) => SupplierDetailPage(supplierId: id),
        );
      case 'orders':
        return MaterialPageRoute(
          builder: (_) => OrderHistoryPage(supplierId: id),
        );
    }
  }
  
  // ===== ROUTES DYNAMIQUES - ADMINISTRATION =====
  if (pathSegments.length >= 2 && pathSegments[0] == 'admin') {
    final section = pathSegments[1];
    
    // Routes dynamiques pour les détails utilisateurs
    if (section == 'users' && pathSegments.length >= 4 && pathSegments[2] == 'detail') {
      final userId = pathSegments[3];
      final userType = uri.queryParameters['type'] ?? 'client';
      
      return MaterialPageRoute(
        builder: (_) => AdminUserDetailPage(
          userId: userId,
          userType: userType,
        ),
      );
    }
  }
  
  // ===== ROUTES DYNAMIQUES - ORGANISATEUR =====
  if (pathSegments.length >= 3 && pathSegments[0] == 'organisateur' && pathSegments[1] == 'conventions') {
    final action = pathSegments[2];
    
    if (action == 'edit') {
      // Récupérer les arguments pour la convention à éditer
      final args = settings.arguments;
      
      // Approche sécuritaire sans cast direct
      return MaterialPageRoute(
        builder: (_) => EventEditPage(convention: args),
      );
    }
  }
  
  // Si aucune route correspondante n'est trouvée
  return null;
}