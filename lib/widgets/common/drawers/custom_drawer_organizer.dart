// lib/widgets/common/drawers/custom_drawer_organizer.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/models/user.dart';

// Support & Chat - CORRIGÉ : On retire l'import AIAssistantPage
import 'package:kipik_v5/pages/support/support_chat_page.dart';
import 'package:kipik_v5/widgets/chat/ai_chat_bottom_sheet.dart';

class CustomDrawerOrganizer extends StatelessWidget {
  const CustomDrawerOrganizer({Key? key}) : super(key: key);

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

          // Menu organisateur
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 16),
                
                // SECTION TABLEAU DE BORD
                const _SectionHeader('TABLEAU DE BORD'),
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard Organisateur',
                  subtitle: 'Vue d\'ensemble de mes événements',
                  onTap: () => _navigateToPlaceholder(context, 'Dashboard Organisateur'),
                ),

                const _SectionDivider(),
                
                // SECTION CHAT & ASSISTANCE
                const _SectionHeader('CHAT & ASSISTANCE'),
                _buildMenuItem(
                  context,
                  icon: Icons.smart_toy_outlined,
                  title: 'Assistant IA Kipik',
                  subtitle: 'Aide pour organiser vos événements',
                  onTap: () => _openAIAssistant(context),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.support_agent_outlined,
                  title: 'Support Organisateur',
                  subtitle: 'Aide spécialisée événements',
                  onTap: () => _navigateTo(context, SupportChatPage(userId: currentUser.id)),
                ),

                const _SectionDivider(),
                
                // SECTION GESTION ÉVÉNEMENTS
                const _SectionHeader('MES ÉVÉNEMENTS'),
                _buildMenuItem(
                  context,
                  icon: Icons.event_outlined,
                  title: 'Mes événements',
                  subtitle: 'Gérer mes conventions/salons',
                  onTap: () => _navigateToPlaceholder(context, 'Liste des événements'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.add_circle_outline,
                  title: 'Créer un événement',
                  onTap: () => _navigateToPlaceholder(context, 'Création d\'événement'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people_outlined,
                  title: 'Participants',
                  subtitle: 'Tatoueurs et visiteurs inscrits',
                  onTap: () => _navigateToPlaceholder(context, 'Gestion des participants'),
                ),

                const _SectionDivider(),
                
                // SECTION COMMUNICATION
                const _SectionHeader('COMMUNICATION'),
                _buildMenuItem(
                  context,
                  icon: Icons.forum_outlined,
                  title: 'Forum Organisateurs',
                  subtitle: 'Échanger avec d\'autres organisateurs',
                  onTap: () => _navigateToPlaceholder(context, 'Forum organisateurs'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Alertes et messages importants',
                  onTap: () => _navigateToPlaceholder(context, 'Notifications'),
                ),

                const _SectionDivider(),
                
                // SECTION OUTILS
                const _SectionHeader('OUTILS'),
                _buildMenuItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Statistiques',
                  subtitle: 'Analyse de mes événements',
                  onTap: () => _navigateToPlaceholder(context, 'Statistiques'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.map_outlined,
                  title: 'Carte des conventions',
                  subtitle: 'Voir tous les événements',
                  onTap: () => _navigateToPlaceholder(context, 'Carte des conventions'),
                ),

                const _SectionDivider(),
                
                // SECTION PARAMÈTRES
                const _SectionHeader('PARAMÈTRES'),
                _buildMenuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Mon profil',
                  onTap: () => _navigateToPlaceholder(context, 'Profil organisateur'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  onTap: () => _navigateToPlaceholder(context, 'Paramètres'),
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
                      _navigateToPlaceholder(context, 'Créer événement');
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _navigateToPlaceholder(BuildContext context, String pageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Page "$pageName" en cours de développement'),
        backgroundColor: Colors.purple,
      ),
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

  void _showLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.event, color: Colors.purple),
            const SizedBox(width: 8),
            const Text('Déconnexion Organisateur'),
          ],
        ),
        content: const Text('Voulez-vous vraiment vous déconnecter de l\'espace organisateur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Annuler'),
          ),
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