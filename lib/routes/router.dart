// lib/routes/router.dart
import 'package:flutter/material.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';

// Authentification
import 'package:kipik_v5/pages/auth/welcome_page.dart';
import 'package:kipik_v5/pages/auth/connexion_page.dart';
import 'package:kipik_v5/pages/auth/inscription_page.dart';
import 'package:kipik_v5/pages/temp/first_setup_page.dart';

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

// Partie Pro
import 'package:kipik_v5/pages/pro/home_page_pro.dart';
import 'package:kipik_v5/pages/pro/dashboard_page.dart';
import 'package:kipik_v5/pages/pro/profil_tatoueur.dart';
import 'package:kipik_v5/pages/pro/inscription_pro_page.dart';
import 'package:kipik_v5/pages/pro/notifications_pro_page.dart';
import 'package:kipik_v5/pages/pro/parametres_pro_page.dart';
import 'package:kipik_v5/pages/pro/aide_pro_page.dart';
import 'package:kipik_v5/pages/pro/agenda/pro_agenda_home_page.dart';
import 'package:kipik_v5/pages/pro/comptabilite/comptabilite_page.dart';
import 'package:kipik_v5/pages/pro/mes_realisations_page.dart';
import 'package:kipik_v5/pages/pro/mon_shop_page.dart';
import 'package:kipik_v5/pages/pro/suppliers/suppliers_list_page.dart';
import 'package:kipik_v5/pages/pro/suppliers/supplier_detail_page.dart';
import 'package:kipik_v5/pages/pro/suppliers/order_history_page.dart';

// Conventions
import 'package:kipik_v5/pages/conventions/convention_list_page.dart';
import 'package:kipik_v5/pages/conventions/convention_admin_page.dart';

// Organisateur
import 'package:kipik_v5/pages/organisateur/organisateur_dashboard_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_conventions_page.dart';
import 'package:kipik_v5/pages/organisateur/event_edit_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_inscriptions_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_billeterie_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_marketing_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_settings_page.dart';

// Administration
import 'package:kipik_v5/pages/admin/admin_dashboard_home.dart';
import 'package:kipik_v5/pages/admin/admin_setup_page.dart';
import 'package:kipik_v5/pages/admin/pros/admin_pros_management_page.dart';
import 'package:kipik_v5/pages/admin/clients/admin_clients_management_page.dart';
import 'package:kipik_v5/pages/admin/organizers/admin_organizers_management_page.dart';
import 'package:kipik_v5/pages/admin/users/admin_user_search_page.dart';
import 'package:kipik_v5/pages/admin/users/admin_user_detail_page.dart';
import 'package:kipik_v5/pages/admin/admin_free_codes_page.dart';
import 'package:kipik_v5/pages/admin/admin_referrals_page.dart';

// Pages légales
import 'package:kipik_v5/pages/legal/cgu_page.dart';
import 'package:kipik_v5/pages/legal/cgv_page.dart';

// Routes statiques
final Map<String, WidgetBuilder> appRoutes = {
  // Auth
  '/welcome': (_) => const WelcomePage(),
  '/connexion': (_) => const ConnexionPage(),
  '/inscription': (_) => const InscriptionPage(),
  '/first-setup': (_) => const FirstSetupPage(),

  // Particulier
  '/home': (_) => const AccueilParticulierPage(),
  '/profil': (_) => const ProfilParticulierPage(),
  '/notifications': (_) => const NotificationsPage(),
  '/parametres': (_) => const ParametresPage(),
  '/aide': (_) => const AideSupportPage(),
  '/recherche': (_) => const RechercheTatoueurPage(),
  '/devis': (_) => const MesDevisPage(),
  '/mes-projets': (_) => const MesProjetsParticulierPage(),
  '/messages': (_) => const MessagesParticulierPage(),
  '/inspirations': (_) => const InspirationsPage(),
  '/favoris': (_) => const FavorisPage(),

  // Pro
  '/pro': (_) => const HomePagePro(),
  '/pro/dashboard': (_) => const DashboardPage(),
  '/pro/profil': (_) => const ProfilTatoueur(),
  '/pro/inscription': (_) =>  InscriptionProPage(),
  '/pro/notifications': (_) => const NotificationsProPage(),
  '/pro/parametres': (_) => const ParametresProPage(),  '/pro/aide': (_) => const AideProPage(),
  '/pro/agenda': (_) => const ProAgendaHomePage(),
  '/pro/comptabilite': (_) => const ComptabilitePage(),
  '/pro/realisations': (_) => const MesRealisationsPage(),
  '/pro/shop': (_) => const MonShopPage(),
  '/pro/suppliers': (_) => const SuppliersListPage(),

  // Conventions
  '/conventions': (_) => const ConventionListPage(),
  '/conventions/admin': (_) => const ConventionAdminPage(),

  // Organisateur
  '/organisateur/dashboard': (_) => const OrganisateurDashboardPage(),
  '/organisateur/conventions': (_) => const OrganisateurConventionsPage(),
  '/organisateur/conventions/create': (_) => const EventEditPage(),
  '/organisateur/inscriptions': (_) => const OrganisateurInscriptionsPage(),
  '/organisateur/billeterie': (_) => const OrganisateurBilleteriePage(),
  '/organisateur/marketing': (_) => const OrganisateurMarketingPage(),
  '/organisateur/settings': (_) => const OrganisateurSettingsPage(),

  // Administration
  '/admin': (_) => const AdminDashboardHome(),
  '/admin/dashboard': (_) => const AdminDashboardHome(),
  '/admin/setup': (_) => const AdminSetupPage(),
  '/admin/pros': (_) => const AdminProsManagementPage(),
  '/admin/clients': (_) => const AdminClientsManagementPage(),
  '/admin/organizers': (_) => const AdminOrganizersManagementPage(),
  '/admin/users/search': (_) => const AdminUserSearchPage(),
  '/admin/users/detail': (_) => const AdminUserDetailPage(userId: '', userType: ''),
  '/admin/free-codes': (_) => const AdminFreeCodesPage(),
  '/admin/referrals': (_) => const AdminReferralsPage(),

  // Légal
  '/cgu': (_) => const CGUPage(),
  '/cgv': (_) => const CGVPage(),
};

// Guard pour l'accès à la configuration initiale admin
class AdminRouteGuard {
  static Future<bool> canAccessAdminSetup() async {
    try {
      final exists = await SecureAuthService.instance.checkFirstAdminExists();
      return !exists;
    } catch (_) {
      return true;
    }
  }
}

// Gestion des routes dynamiques
Route<dynamic>? generateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '');
  final parts = uri.pathSegments;

  // Accès sécurisé à /admin/setup
  if (settings.name == '/admin/setup') {
    return MaterialPageRoute(
      builder: (ctx) => FutureBuilder<bool>(
        future: AdminRouteGuard.canAccessAdminSetup(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snap.data == true) {
            return const AdminSetupPage();
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(ctx).pushReplacementNamed('/connexion');
            });
            return const Scaffold(
              body: Center(child: Text('Redirection...')),
            );
          }
        },
      ),
    );
  }

  // Détail fournisseur
  if (parts.length >= 3 && parts[0] == 'pro' && parts[1] == 'suppliers') {
    final action = parts[2];
    final id = parts.length > 3 ? parts[3] : '';
    switch (action) {
      case 'details':
        return MaterialPageRoute(
          builder: (_) => SupplierDetailPage(supplierId: id),
        );
      case 'orders':
        return MaterialPageRoute(
          builder: (_) => OrderHistoryPage(supplierId: id),
        );
      default:
        break;
    }
  }

  // Détail utilisateur admin
  if (parts.length == 4 && parts[0] == 'admin' && parts[1] == 'users' && parts[2] == 'detail') {
    final userId = parts[3];
    final userType = uri.queryParameters['type'] ?? 'client';
    return MaterialPageRoute(
      builder: (_) => AdminUserDetailPage(
        userId: userId,
        userType: userType,
      ),
    );
  }

  return null;
}
