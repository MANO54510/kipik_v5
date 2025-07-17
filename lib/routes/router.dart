import 'package:flutter/material.dart';

// IMPORTS PAGES ---------
// AUTH
import 'package:kipik_v5/pages/auth/welcome_page.dart';
import 'package:kipik_v5/pages/auth/connexion_page.dart';
import 'package:kipik_v5/pages/auth/inscription_page.dart';
import 'package:kipik_v5/pages/pro/inscription_pro_page.dart';

// PARTICULIER
import 'package:kipik_v5/pages/particulier/accueil_particulier_page.dart';
import 'package:kipik_v5/pages/particulier/recherche_tatoueur_page.dart';
import 'package:kipik_v5/pages/particulier/mes_devis_page.dart';
import 'package:kipik_v5/pages/particulier/mes_projets_particulier_page.dart';
import 'package:kipik_v5/pages/particulier/messages_particulier_page.dart';
import 'package:kipik_v5/pages/particulier/profil_particulier_page.dart';
import 'package:kipik_v5/pages/particulier/favoris_page.dart';
import 'package:kipik_v5/pages/particulier/notifications_page.dart';
import 'package:kipik_v5/pages/particulier/parametres_page.dart';
import 'package:kipik_v5/pages/particulier/aide_support_page.dart';

// PRO
import 'package:kipik_v5/pages/pro/home_page_pro.dart';
import 'package:kipik_v5/pages/pro/dashboard_page.dart';
import 'package:kipik_v5/pages/pro/profil_tatoueur.dart';
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
import 'package:kipik_v5/pages/pro/booking/booking_calendar_page.dart';
import 'package:kipik_v5/pages/pro/booking/booking_day_view_page.dart';
import 'package:kipik_v5/pages/pro/booking/booking_add_event_page.dart';
import 'package:kipik_v5/pages/pro/booking/booking_import_page.dart';

// ORGANISATEUR
import 'package:kipik_v5/pages/organisateur/organisateur_dashboard_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_conventions_page.dart';
import 'package:kipik_v5/pages/organisateur/event_edit_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_inscriptions_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_billeterie_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_marketing_page.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_settings_page.dart';

// SHARED BOOKING, CONVENTIONS, FLASH, INSPIRATIONS
import 'package:kipik_v5/pages/shared/booking/booking_chat_page.dart';
import 'package:kipik_v5/pages/shared/booking/booking_flow_page.dart';
import 'package:kipik_v5/pages/shared/booking/booking_settings_page.dart';
import 'package:kipik_v5/pages/shared/conventions/convention_home_page.dart';
import 'package:kipik_v5/pages/shared/conventions/convention_system/convention_detail_page.dart';
import 'package:kipik_v5/pages/shared/conventions/convention_system/convention_layout_generator.dart';
import 'package:kipik_v5/pages/shared/conventions/convention_system/convention_pro_management_page.dart';
import 'package:kipik_v5/pages/shared/conventions/convention_system/convention_stand_optimizer.dart';
import 'package:kipik_v5/pages/shared/conventions/convention_system/interactive_convention_map.dart';
import 'package:kipik_v5/pages/shared/flashs/flash_detail_page.dart';
import 'package:kipik_v5/pages/shared/inspirations/detail_inspiration_page.dart';
import 'package:kipik_v5/pages/shared/inspirations/inspirations_page.dart';

// ADMIN
import 'package:kipik_v5/pages/admin/admin_dashboard_home.dart';
import 'package:kipik_v5/pages/admin/admin_setup_page.dart';
import 'package:kipik_v5/pages/admin/pros/admin_pros_management_page.dart';
import 'package:kipik_v5/pages/admin/clients/admin_clients_management_page.dart';
import 'package:kipik_v5/pages/admin/organizers/admin_organizers_management_page.dart';
import 'package:kipik_v5/pages/admin/users/admin_user_search_page.dart';
import 'package:kipik_v5/pages/admin/users/admin_user_detail_page.dart';
import 'package:kipik_v5/pages/admin/admin_free_codes_page.dart';
import 'package:kipik_v5/pages/admin/admin_referrals_page.dart';

// LEGAL
import 'package:kipik_v5/pages/legal/cgu_page.dart';
import 'package:kipik_v5/pages/legal/cgv_page.dart';

// ENUMS, MOCKS & ROLES
import 'package:kipik_v5/enums/convention_enums.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/mock/mock_flash.dart';
import 'package:kipik_v5/mock/mock_booking.dart';
import 'package:kipik_v5/mock/mock_inspiration_post.dart';

// ------------------- ROUTES STATIQUES -------------------

final Map<String, WidgetBuilder> appRoutes = {
  // AUTH
  '/welcome': (_) => const WelcomePage(),
  '/connexion': (_) => const ConnexionPage(),
  '/inscription': (_) => const InscriptionPage(),
  '/pro/inscriptionPro': (_) => InscriptionProPage(),

  // PARTICULIER
  '/home': (_) => const AccueilParticulierPage(),
  '/profil': (_) => const ProfilParticulierPage(),
  '/notifications': (_) => const NotificationsPage(),
  '/parametres': (_) => const ParametresPage(),
  '/aide': (_) => const AideSupportPage(),
  '/recherche_tatoueur': (_) => const RechercheTatoueurPage(),
  '/suivi_devis': (_) => const MesDevisPage(),
  '/mes_projets': (_) => const MesProjetsParticulierPage(),
  '/messages': (_) => const MessagesParticulierPage(),
  '/favoris': (_) => const FavorisPage(),

  // PRO
  '/pro': (_) => const HomePagePro(),
  '/pro/dashboard': (_) => const DashboardPage(),
  '/pro/profil': (_) => const ProfilTatoueur(),
  '/pro/notifications': (_) => const NotificationsProPage(),
  '/pro/parametres': (_) => const ParametresProPage(),
  '/pro/aide': (_) => const AideProPage(),
  '/pro/agenda': (_) => const ProAgendaHomePage(),
  '/pro/comptabilite': (_) => const ComptabilitePage(),
  '/pro/realisations': (_) => const MesRealisationsPage(),
  '/pro/shop': (_) => const MonShopPage(),
  '/pro/suppliers': (_) => const SuppliersListPage(),
  '/pro/booking': (_) => const BookingCalendarPage(),
  '/pro/booking/day': (_) => const BookingDayViewPage(),
  '/pro/booking/add': (_) => const BookingAddEventPage(),
  '/pro/booking/import': (_) => const BookingImportPage(),

  // ORGANISATEUR
  '/organisateur/dashboard': (_) => OrganisateurDashboardPage(),
  '/organisateur/conventions': (_) => OrganisateurConventionsPage(),
  '/organisateur/inscriptions': (_) => OrganisateurInscriptionsPage(),
  '/organisateur/billeterie': (_) => OrganisateurBilleteriePage(),
  '/organisateur/marketing': (_) => OrganisateurMarketingPage(),
  '/organisateur/settings': (_) => OrganisateurSettingsPage(),

  // SHARED BOOKING, FLASH, INSPIRATIONS
  '/shared/booking/chat': (_) => BookingChatPage(booking: mockBooking),
  '/shared/booking/flow': (_) => BookingFlowPage(flash: mockFlash),
  '/shared/booking/settings': (_) => BookingSettingsPage(),
  '/inspirations': (_) => InspirationsPage(),
  '/shared/inspirations': (_) => InspirationsPage(),

  // ADMIN
  '/admin': (_) => const AdminDashboardHome(),
  '/admin/dashboard': (_) => const AdminDashboardHome(),
  '/admin/setup': (_) => const AdminSetupPage(),
  '/admin/pros': (_) => const AdminProsManagementPage(),
  '/admin/clients': (_) => const AdminClientsManagementPage(),
  '/admin/organizers': (_) => const AdminOrganizersManagementPage(),
  '/admin/users/search': (_) => const AdminUserSearchPage(),
  '/admin/free-codes': (_) => const AdminFreeCodesPage(),
  '/admin/referrals': (_) => const AdminReferralsPage(),

  // LEGAL
  '/cgu': (_) => const CGUPage(),
  '/cgv': (_) => const CGVPage(),
};

// -------- ROUTES DYNAMIQUES ----------

Route<dynamic>? generateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '');
  final pathSegments = uri.pathSegments;

  // SHARED FLASH
  if (pathSegments.length >= 3 && pathSegments[0] == 'shared' && pathSegments[1] == 'flashs') {
    final action = pathSegments[2];
    if (action == 'detail' && pathSegments.length >= 4) {
      final flashId = pathSegments[3];
      return MaterialPageRoute(builder: (_) => FlashDetailPage(flashId: flashId));
    }
  }

  // SHARED CONVENTIONS
  if (pathSegments.length >= 3 && pathSegments[0] == 'shared' && pathSegments[1] == 'conventions') {
    final action = pathSegments[2];
    switch (action) {
      case 'detail':
        if (pathSegments.length >= 4) {
          final conventionId = pathSegments[3];
          return MaterialPageRoute(builder: (_) => ConventionDetailPage(conventionId: conventionId));
        }
        break;
      case 'map':
        if (pathSegments.length >= 4) {
          final conventionId = pathSegments[3];
          return MaterialPageRoute(
            builder: (_) => InteractiveConventionMap(
              conventionId: conventionId,
              initialMode: MapMode.organizer,
              userType: UserRole.admin,
            ),
          );
        }
        break;
      case 'layout':
        if (pathSegments.length >= 4) {
          final conventionId = pathSegments[3];
          // ATTENTION : ConventionLayoutGenerator attend un "convention" de type Map, PAS conventionId
          return MaterialPageRoute(
            builder: (_) => ConventionLayoutGenerator(
              convention: {"id": conventionId},
            ),
          );
        }
        break;
      case 'pro':
        if (settings.arguments is Map && (settings.arguments as Map).containsKey('conventionId')) {
          final conventionId = (settings.arguments as Map)['conventionId'];
          return MaterialPageRoute(builder: (_) => ConventionProManagementPage(conventionId: conventionId));
        }
        break;
    }
  }

  // SHARED INSPIRATIONS
  if (pathSegments.length >= 3 && pathSegments[0] == 'shared' && pathSegments[1] == 'inspirations') {
    final action = pathSegments[2];
    if (action == 'detail' && pathSegments.length >= 4) {
      // Utilise le mock pour le test, tu brancheras Firestore plus tard
      return MaterialPageRoute(
        builder: (_) => DetailInspirationPage(post: mockInspirationPost),
      );
    }
  }

  // FOURNISSEURS
  if (pathSegments.length >= 4 && pathSegments[0] == 'pro' && pathSegments[1] == 'suppliers') {
    final action = pathSegments[2];
    final id = pathSegments[3];
    switch (action) {
      case 'details':
        return MaterialPageRoute(builder: (_) => SupplierDetailPage(supplierId: id));
      case 'orders':
        return MaterialPageRoute(builder: (_) => OrderHistoryPage(supplierId: id));
    }
  }

  // ADMIN USERS DETAIL
  if (pathSegments.length >= 4 && pathSegments[0] == 'admin' && pathSegments[1] == 'users' && pathSegments[2] == 'detail') {
    final userId = pathSegments[3];
    final userType = uri.queryParameters['type'] ?? 'client';
    return MaterialPageRoute(builder: (_) => AdminUserDetailPage(userId: userId, userType: userType));
  }

  // ORGANISATEUR DYNAMIC
  if (pathSegments.length >= 2 && pathSegments[0] == 'organisateur') {
    switch (pathSegments[1]) {
      case 'dashboard':
        return MaterialPageRoute(builder: (_) => OrganisateurDashboardPage());
      case 'conventions':
        if (pathSegments.length == 2) {
          return MaterialPageRoute(builder: (_) => OrganisateurConventionsPage());
        } else if (pathSegments.length >= 4 && pathSegments[2] == 'edit') {
          final conventionId = pathSegments[3];
          return MaterialPageRoute(builder: (_) => EventEditPage(conventionId: conventionId));
        }
        break;
      case 'inscriptions':
        return MaterialPageRoute(builder: (_) => OrganisateurInscriptionsPage());
      case 'billeterie':
        if (pathSegments.length == 2) {
          return MaterialPageRoute(builder: (_) => OrganisateurBilleteriePage());
        } else if (pathSegments.length >= 3) {
          final conventionId = pathSegments[2];
          return MaterialPageRoute(builder: (_) => OrganisateurBilleteriePage(conventionId: conventionId));
        }
        break;
      case 'marketing':
        return MaterialPageRoute(builder: (_) => OrganisateurMarketingPage());
      case 'settings':
        return MaterialPageRoute(builder: (_) => OrganisateurSettingsPage());
    }
  }

  // DEFAULT: PAGE 404
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      body: Center(
        child: Text('Page non trouvée : ${settings.name}', style: TextStyle(fontSize: 20, color: Colors.red)),
      ),
    ),
  );
}