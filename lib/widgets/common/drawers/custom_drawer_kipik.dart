// lib/widgets/common/drawers/custom_drawer_kipik.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/models/user.dart';

// Navigation imports - organisés par catégorie
import 'package:kipik_v5/pages/pro/home_page_pro.dart';
import 'package:kipik_v5/pages/pro/dashboard_page.dart';
import 'package:kipik_v5/pages/pro/profil_tatoueur.dart';

// Agenda & Planning
import 'package:kipik_v5/pages/pro/agenda/pro_agenda_home_page.dart';
import 'package:kipik_v5/pages/pro/agenda/pro_agenda_notifications_page.dart';

// Projets & Communication
import 'package:kipik_v5/pages/pro/attente_devis_page.dart';
import 'package:kipik_v5/pages/chat_projet_page.dart';
import 'package:kipik_v5/pages/pro/mes_projets_page.dart';

// Portfolio & Réalisations
import 'package:kipik_v5/pages/pro/mes_realisations_page.dart';
import 'package:kipik_v5/pages/pro/mon_shop_page.dart';

// Outils Pro
import 'package:kipik_v5/pages/conventions/convention_map_page.dart';
import 'package:kipik_v5/pages/pro/suppliers/suppliers_list_page.dart';

// Gestion & Comptabilité
import 'package:kipik_v5/pages/pro/comptabilite/comptabilite_page.dart';

// Support & Chat - CORRIGÉ : On retire l'import AIAssistantPage
import 'package:kipik_v5/pages/support/support_chat_page.dart';
import 'package:kipik_v5/widgets/chat/ai_chat_bottom_sheet.dart';

// Paramètres
import 'package:kipik_v5/pages/pro/parametres_pro_page.dart';
import 'package:kipik_v5/pages/pro/notifications_pro_page.dart';

class CustomDrawerKipik extends StatelessWidget {
  const CustomDrawerKipik({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = AuthService.instance.currentUser;
    
    // Si pas d'utilisateur connecté, ne pas afficher le drawer
    if (currentUser == null) {
      return const Drawer(
        child: Center(
          child: Text('Utilisateur non connecté'),
        ),
      );
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
          // Header avec image aléatoire
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bgImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: KipikTheme.rouge.withOpacity(0.2),
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
                        backgroundImage: currentUser.profileImageUrl?.isNotEmpty == true
                            ? NetworkImage(currentUser.profileImageUrl!)
                            : const AssetImage('assets/avatars/avatar_neutre.png') as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.name,
                              style: TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 22,
                                color: KipikTheme.rouge,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'TATOUEUR PROFESSIONNEL',
                                  style: TextStyle(
                                    color: Colors.white,
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

          // Menu optimisé avec les nouvelles fonctionnalités
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 16),
                
                // SECTION PRINCIPALE - Accès rapide aux pages les plus utilisées
                const _SectionHeader('TABLEAU DE BORD'),
                _buildMenuItem(
                  context,
                  icon: Icons.home_outlined,
                  title: 'Accueil Pro',
                  onTap: () => _navigateTo(context, const HomePagePro()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Tableau de bord',
                  onTap: () => _navigateTo(context, const DashboardPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Mon profil',
                  onTap: () => _navigateTo(context, const ProfilTatoueur()),
                ),

                const _SectionDivider(),
                
                // SECTION CHAT & ASSISTANCE
                const _SectionHeader('CHAT & ASSISTANCE'),
                _buildMenuItem(
                  context,
                  icon: Icons.smart_toy_outlined,
                  title: 'Assistant IA Kipik',
                  subtitle: 'Questions, idées, aide navigation',
                  onTap: () => _openAIAssistant(context),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.support_agent_outlined,
                  title: 'Support Client',
                  subtitle: 'Aide, bugs, questions techniques',
                  onTap: () => _navigateTo(context, SupportChatPage(userId: currentUser.id)),
                ),

                const _SectionDivider(),
                
                // SECTION AGENDA & PLANNING
                const _SectionHeader('AGENDA & PLANNING'),
                _buildMenuItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  title: 'Mon Agenda',
                  onTap: () => _navigateTo(context, const ProAgendaHomePage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.schedule_outlined,
                  title: 'Notifications Agenda',
                  onTap: () => _navigateTo(context, const ProAgendaNotificationsPage()),
                ),

                const _SectionDivider(),
                
                // SECTION PROJETS & CLIENTS
                const _SectionHeader('PROJETS & CLIENTS'),
                _buildMenuItem(
                  context,
                  icon: Icons.request_quote_outlined,
                  title: 'Devis en attente',
                  onTap: () => _navigateTo(context, const AttenteDevisPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.folder_outlined,
                  title: 'Mes Projets',
                  onTap: () => _navigateTo(context, MesProjetsPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat Projets',
                  subtitle: 'Communiquer avec vos clients',
                  onTap: () => _navigateTo(context, const ChatProjetPage()),
                ),

                const _SectionDivider(),
                
                // SECTION PORTFOLIO & SHOP
                const _SectionHeader('PORTFOLIO & SHOP'),
                _buildMenuItem(
                  context,
                  icon: Icons.photo_library_outlined,
                  title: 'Mes Réalisations',
                  onTap: () => _navigateTo(context, const MesRealisationsPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.store_outlined,
                  title: 'Mon Shop',
                  onTap: () => _navigateTo(context, const MonShopPage()),
                ),

                const _SectionDivider(),
                
                // SECTION OUTILS PRO
                const _SectionHeader('OUTILS PRO'),
                _buildMenuItem(
                  context,
                  icon: Icons.map_outlined,
                  title: 'Conventions',
                  onTap: () => _navigateTo(context, const ConventionMapPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_outlined,
                  title: 'Fournisseurs',
                  onTap: () => _navigateTo(context, const SuppliersListPage()),
                ),

                const _SectionDivider(),
                
                // SECTION COMPTABILITÉ & GESTION
                const _SectionHeader('COMPTABILITÉ'),
                _buildMenuItem(
                  context,
                  icon: Icons.euro_outlined,
                  title: 'Comptabilité',
                  onTap: () => _navigateTo(context, ComptabilitePage()),
                ),

                const _SectionDivider(),
                
                // SECTION PARAMÈTRES
                const _SectionHeader('PARAMÈTRES'),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications Pro',
                  onTap: () => _navigateTo(context, const NotificationsProPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  onTap: () => _navigateTo(context, const ParametresProPage()),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Actions rapides
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
                      _openAIAssistant(context);
                    },
                    icon: const Icon(Icons.smart_toy, size: 16),
                    label: const Text('IA', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KipikTheme.rouge,
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
                      _navigateTo(context, SupportChatPage(userId: currentUser.id));
                    },
                    icon: const Icon(Icons.support_agent, size: 16),
                    label: const Text('Support', style: TextStyle(fontSize: 12)),
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

          // Déconnexion
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1F2937), width: 1)),
            ),
            child: _buildMenuItem(
              context,
              icon: Icons.logout_outlined,
              title: 'Se déconnecter',
              iconColor: KipikTheme.rouge,
              textColor: KipikTheme.rouge,
              onTap: () => _showLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
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

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _openAIAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      builder: (_) => const AIChatBottomSheet(
        allowImageGeneration: false, // Pas de génération d'images depuis le drawer
        contextPage: 'drawer',
      ),
    );
  }

  void _showLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
            onPressed: () {
              Navigator.pop(context);
              AuthService.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
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
            color: KipikTheme.rouge.withOpacity(0.8),
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