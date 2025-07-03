// lib/widgets/common/drawers/custom_drawer_organizer.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/models/user.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/widgets/common/drawers/secure_drawer_components.dart';

// Support & Chat
import 'package:kipik_v5/pages/support/support_chat_page.dart';
import 'package:kipik_v5/widgets/chat/ai_chat_bottom_sheet.dart';

class CustomDrawerOrganizer extends StatelessWidget with SecureDrawerMixin {
  const CustomDrawerOrganizer({Key? key}) : super(key: key);

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
    if (currentRole != UserRole.organisateur) {
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
          // Header avec thème organisateur
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bgImage),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.purple.withOpacity(0.2),
                  BlendMode.multiply,
                ),
              ),
            ),
            child: Stack(
              children: [
                // Badge organisateur
                Positioned(
                  top: 50,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple, width: 2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'ORGANISATEUR',
                          style: TextStyle(
                            color: Colors.white,
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
                      color: Colors.purple.withOpacity(0.2),
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
                        backgroundColor: Colors.purple,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundImage: currentUser.profileImageUrl?.isNotEmpty == true
                              ? NetworkImage(currentUser.profileImageUrl!)
                              : const AssetImage('assets/avatars/avatar_organizer.png') as ImageProvider,
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
                                color: Colors.purple,
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
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'ORGANISATEUR ÉVÉNEMENTS',
                                  style: TextStyle(
                                    color: Colors.purple,
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

          // Menu organisateur sécurisé
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
                  title: 'Dashboard Organisateur',
                  subtitle: 'Vue d\'ensemble de mes événements',
                  onTap: () => showDevelopmentMessage(context, 'Dashboard Organisateur'),
                ),

                const _SectionDivider(),
                
                // SECTION CHAT & ASSISTANCE
                const _SectionHeader('CHAT & ASSISTANCE'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.smart_toy_outlined,
                  title: 'Assistant IA Kipik',
                  subtitle: 'Aide pour organiser vos événements',
                  onTap: () => _openAIAssistant(context),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.support_agent_outlined,
                  title: 'Support Organisateur',
                  subtitle: 'Aide spécialisée événements',
                  onTap: () => secureNavigate(context, SupportChatPage(userId: currentUser.id)),
                ),

                const _SectionDivider(),
                
                // SECTION GESTION ÉVÉNEMENTS
                const _SectionHeader('MES ÉVÉNEMENTS'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.event_outlined,
                  title: 'Mes événements',
                  subtitle: 'Gérer mes conventions/salons',
                  onTap: () => showDevelopmentMessage(context, 'Liste des événements'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.add_circle_outline,
                  title: 'Créer un événement',
                  onTap: () => showDevelopmentMessage(context, 'Création d\'événement'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.people_outlined,
                  title: 'Participants',
                  subtitle: 'Tatoueurs et visiteurs inscrits',
                  onTap: () => showDevelopmentMessage(context, 'Gestion des participants'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.edit_calendar_outlined,
                  title: 'Planning événements',
                  subtitle: 'Calendrier et horaires',
                  onTap: () => showDevelopmentMessage(context, 'Planning'),
                ),

                const _SectionDivider(),
                
                // SECTION GESTION & VALIDATION
                const _SectionHeader('GESTION & VALIDATION'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.pending_actions_outlined,
                  title: 'Événements en attente',
                  subtitle: 'Validation des créations',
                  onTap: () => showDevelopmentMessage(context, 'Événements en attente'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.check_circle_outline,
                  title: 'Événements validés',
                  subtitle: 'Mes événements publiés',
                  onTap: () => showDevelopmentMessage(context, 'Événements validés'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'Factures & Revenus',
                  subtitle: 'Gestion financière',
                  onTap: () => showDevelopmentMessage(context, 'Finances'),
                ),

                const _SectionDivider(),
                
                // SECTION COMMUNICATION
                const _SectionHeader('COMMUNICATION'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.forum_outlined,
                  title: 'Forum Organisateurs',
                  subtitle: 'Échanger avec d\'autres organisateurs',
                  onTap: () => showDevelopmentMessage(context, 'Forum organisateurs'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.campaign_outlined,
                  title: 'Promotion événements',
                  subtitle: 'Outils marketing et communication',
                  onTap: () => showDevelopmentMessage(context, 'Promotion'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Alertes et messages importants',
                  onTap: () => showDevelopmentMessage(context, 'Notifications'),
                ),

                const _SectionDivider(),
                
                // SECTION OUTILS & ANALYTICS
                const _SectionHeader('OUTILS & ANALYTICS'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Statistiques',
                  subtitle: 'Analyse de mes événements',
                  onTap: () => showDevelopmentMessage(context, 'Statistiques'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.map_outlined,
                  title: 'Carte des conventions',
                  subtitle: 'Voir tous les événements',
                  onTap: () => showDevelopmentMessage(context, 'Carte des conventions'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.qr_code_outlined,
                  title: 'QR Codes événements',
                  subtitle: 'Codes d\'accès et check-in',
                  onTap: () => showDevelopmentMessage(context, 'QR Codes'),
                ),

                const _SectionDivider(),
                
                // SECTION PARAMÈTRES
                const _SectionHeader('PARAMÈTRES'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Mon profil',
                  onTap: () => showDevelopmentMessage(context, 'Profil organisateur'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.business_outlined,
                  title: 'Informations entreprise',
                  subtitle: 'Données légales et contact',
                  onTap: () => showDevelopmentMessage(context, 'Infos entreprise'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  onTap: () => showDevelopmentMessage(context, 'Paramètres'),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Actions rapides organisateur
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
                      showDevelopmentMessage(context, 'Créer événement');
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Créer', style: TextStyle(fontSize: 12)),
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
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
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
        allowImageGeneration: false, // Organisateurs n'ont pas besoin de génération d'images
        contextPage: 'organizer',
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
            color: Colors.purple.withOpacity(0.8),
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