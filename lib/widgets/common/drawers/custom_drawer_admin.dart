// lib/widgets/common/drawers/custom_drawer_admin.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/models/user.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/widgets/common/drawers/secure_drawer_components.dart';

// Navigation imports - organisés par catégorie
// Dashboard principal et espaces spécialisés
import 'package:kipik_v5/pages/admin/admin_dashboard_home.dart';
import 'package:kipik_v5/pages/admin/pros/admin_pros_management_page.dart';
import 'package:kipik_v5/pages/admin/clients/admin_clients_management_page.dart';
import 'package:kipik_v5/pages/admin/organizers/admin_organizers_management_page.dart';

// Gestion Conventions
import 'package:kipik_v5/pages/admin/conventions/admin_convention_create_page.dart';
import 'package:kipik_v5/pages/admin/conventions/admin_convention_detail_page.dart';
import 'package:kipik_v5/pages/admin/conventions/admin_convention_tattooers_page.dart';
import 'package:kipik_v5/pages/admin/conventions/admin_conventions_list_page.dart';

// Flash & Réservations
import 'package:kipik_v5/pages/admin/flash/admin_flash_reservations_page.dart';

// Statistiques
import 'package:kipik_v5/pages/admin/stats/admin_convention_stats_page.dart';

// Codes gratuits et parrainages
import 'package:kipik_v5/pages/admin/admin_free_codes_page.dart';
import 'package:kipik_v5/pages/admin/admin_referrals_page.dart';

// Support & Chat
import 'package:kipik_v5/pages/support/support_chat_page.dart';
import 'package:kipik_v5/widgets/chat/ai_chat_bottom_sheet.dart';

class CustomDrawerAdmin extends StatelessWidget with SecureDrawerMixin {
  const CustomDrawerAdmin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Utiliser SecureAuthService avec conversion User
    final dynamic currentUserData = SecureAuthService.instance.currentUser;
    final User? currentUser = UserFromDynamic.fromDynamic(currentUserData);
    
    // Vérifications de sécurité avec SecureAuthService
    if (currentUser == null || !SecureAuthService.instance.isAuthenticated) {
      return SecureDrawerFactory.buildFallbackDrawer();
    }
    
    final currentRole = SecureAuthService.instance.currentUserRole;
    if (currentRole != UserRole.admin) {
      return SecureDrawerFactory.buildFallbackDrawer();
    }
    
    final headerImages = [
      'assets/images/header_tattoo_wallpaper.png',
      'assets/images/header_tattoo_wallpaper2.png',
      'assets/images/header_tattoo_wallpaper3.png',
    ];
    final bgImage = headerImages[Random().nextInt(headerImages.length)];

    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          // Header avec image aléatoire - style admin
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bgImage),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3), // Assombrir pour l'admin
                  BlendMode.darken,
                ),
              ),
            ),
            child: Stack(
              children: [
                // Badge admin flottant
                Positioned(
                  top: 50,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.admin_panel_settings, color: Colors.black, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          SecureAuthService.instance.isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.amber,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundImage: currentUser.profileImageUrl?.isNotEmpty == true
                              ? NetworkImage(currentUser.profileImageUrl!)
                              : const AssetImage('assets/avatars/avatar_admin.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.name,
                              style: const TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 22,
                                color: Colors.amber,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  SecureAuthService.instance.isSuperAdmin 
                                      ? 'SUPER ADMINISTRATEUR KIPIK'
                                      : 'ADMINISTRATEUR KIPIK',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu administrateur optimisé avec sécurité
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 16),
                
                // SECTION TABLEAU DE BORD
                const _SectionHeader('TABLEAU DE BORD'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard Principal',
                  subtitle: 'Vue d\'ensemble des 3 profils',
                  onTap: () => secureNavigate(context, const AdminDashboardHome()),
                ),

                const _SectionDivider(),
                
                // SECTION CHAT & ASSISTANCE
                const _SectionHeader('SUPPORT & ASSISTANCE'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.smart_toy_outlined,
                  title: 'Assistant IA Admin',
                  subtitle: 'Aide pour la gestion de la plateforme',
                  onTap: () => _openAIAssistant(context),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.support_agent_outlined,
                  title: 'Support Admin',
                  subtitle: 'Questions techniques avancées',
                  onTap: () => secureNavigate(context, SupportChatPage(userId: currentUser.id)),
                ),

                const _SectionDivider(),
                
                // SECTION GESTION DES PROFILS UTILISATEURS
                const _SectionHeader('GESTION DES PROFILS'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.brush_outlined,
                  title: 'Tatoueurs Professionnels',
                  subtitle: 'Abonnements, SAV, statistiques',
                  onTap: () => secureNavigate(context, const AdminProsManagementPage()),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.person_outlined,
                  title: 'Clients Particuliers',
                  subtitle: 'Projets, comportements, signalements',
                  onTap: () => secureNavigate(context, const AdminClientsManagementPage()),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.event_outlined,
                  title: 'Organisateurs Événements',
                  subtitle: 'Conventions, revenus, analytics',
                  onTap: () => secureNavigate(context, const AdminOrganizersManagementPage()),
                ),

                const _SectionDivider(),
                
                // SECTION CONVENTIONS & ÉVÉNEMENTS
                const _SectionHeader('CONVENTIONS & ÉVÉNEMENTS'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.list_outlined,
                  title: 'Liste des conventions',
                  onTap: () => secureNavigate(context, const AdminConventionsListPage()),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.add_circle_outline,
                  title: 'Créer une convention',
                  onTap: () => secureNavigate(context, const AdminConventionCreatePage()),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Stats conventions',
                  onTap: () => secureNavigate(context, const AdminConventionStatsPage()),
                ),

                const _SectionDivider(),
                
                // SECTION CODES PROMO & PARRAINAGE
                const _SectionHeader('CODES PROMO & PARRAINAGE'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.card_giftcard_outlined,
                  title: 'Codes gratuits',
                  subtitle: 'Générer des codes pour tatoueurs',
                  onTap: () => secureNavigate(context, const AdminFreeCodesPage()),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.people_outlined,
                  title: 'Gestion parrainages',
                  subtitle: 'Suivi des parrainages',
                  onTap: () => secureNavigate(context, const AdminReferralsPage()),
                ),

                const _SectionDivider(),
                
                // SECTION OUTILS ADMIN
                const _SectionHeader('OUTILS ADMIN'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.flash_on_outlined,
                  title: 'Réservations Flash',
                  onTap: () => secureNavigate(context, const AdminFlashReservationsPage()),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.business_outlined,
                  title: 'Gestion sponsors',
                  onTap: () => showDevelopmentMessage(context, 'Gestion sponsors'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.map_outlined,
                  title: 'Éditeur de carte',
                  onTap: () => showDevelopmentMessage(context, 'Éditeur de carte'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: 'Push notifications',
                  onTap: () => showDevelopmentMessage(context, 'Push notifications'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.emoji_events_outlined,
                  title: 'Contest Admin',
                  onTap: () => showDevelopmentMessage(context, 'Contest Admin'),
                ),

                // ✅ SECTION SUPER ADMIN EXCLUSIVE
                if (SecureAuthService.instance.isSuperAdmin) ...[
                  const _SectionDivider(),
                  const _SectionHeader('SUPER ADMIN'),
                  _buildSecureMenuItem(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Gestion des admins',
                    subtitle: 'Promouvoir/Révoquer des administrateurs',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () => showDevelopmentMessage(context, 'Gestion des admins'),
                  ),
                  _buildSecureMenuItem(
                    context,
                    icon: Icons.security_outlined,
                    title: 'Logs de sécurité',
                    subtitle: 'Audit des actions admin',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () => showDevelopmentMessage(context, 'Logs de sécurité'),
                  ),
                ],

                const _SectionDivider(),
                
                // SECTION STATISTIQUES & RAPPORTS
                const _SectionHeader('STATISTIQUES & RAPPORTS'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.bar_chart_outlined,
                  title: 'Statistiques générales',
                  onTap: () => secureNavigate(context, const AdminConventionStatsPage()),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.timeline_outlined,
                  title: 'Rapports d\'activité',
                  onTap: () => showDevelopmentMessage(context, 'Rapports d\'activité'),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Actions rapides admin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1F2937), width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      secureNavigate(context, const AdminDashboardHome());
                    },
                    icon: const Icon(Icons.dashboard, size: 16),
                    label: const Text('Dashboard', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openAIAssistant(context);
                    },
                    icon: const Icon(Icons.smart_toy, size: 16),
                    label: const Text('IA', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Déconnexion sécurisée
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1F2937), width: 1)),
            ),
            child: _buildSecureMenuItem(
              context,
              icon: Icons.logout_outlined,
              title: 'Se déconnecter',
              iconColor: KipikTheme.rouge,
              textColor: KipikTheme.rouge,
              onTap: () => secureSignOut(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecureMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null 
          ? Text(
              subtitle,
              style: TextStyle(
                color: (textColor ?? Colors.white).withOpacity(0.7),
                fontSize: 12,
              ),
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _openAIAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      builder: (_) => const AIChatBottomSheet(
        allowImageGeneration: false, // Admin n'a pas besoin de génération d'images
        contextPage: 'admin',
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.amber.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => const Divider(color: Color(0xFF1F2937), thickness: 1);
}