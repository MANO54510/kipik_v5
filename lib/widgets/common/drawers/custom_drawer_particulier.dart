// lib/widgets/common/drawers/custom_drawer_particulier.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ SEUL SERVICE UTILISÉ
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/widgets/common/drawers/secure_drawer_components.dart';

// Support & Chat
import 'package:kipik_v5/pages/support/support_chat_page.dart';
import 'package:kipik_v5/widgets/chat/ai_chat_bottom_sheet.dart';

class CustomDrawerParticulier extends StatelessWidget with SecureDrawerMixin {
  const CustomDrawerParticulier({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ CHANGÉ : Utiliser SecureAuthService uniquement
    final currentUser = SecureAuthService.instance.currentUser;
    
    // Vérifications de sécurité avec SecureAuthService
    if (currentUser == null || !SecureAuthService.instance.isAuthenticated) {
      return SecureDrawerFactory.buildFallbackDrawer();
    }
    
    final currentRole = SecureAuthService.instance.currentUserRole;
    if (currentRole != UserRole.client) {
      return SecureDrawerFactory.buildInsufficientRoleDrawer(
        currentRole: currentRole ?? UserRole.client,
        requiredRole: UserRole.client,
      );
    }
    
    // ✅ AJOUTÉ : Extraction des données utilisateur depuis SecureAuthService
    final userName = currentUser['name'] ?? currentUser['displayName'] ?? 'Client';
    final userEmail = currentUser['email'] ?? '';
    final userId = currentUser['uid'] ?? currentUser['id'] ?? '';
    final profileImageUrl = currentUser['photoURL'] ?? currentUser['profileImageUrl'];
    
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
          // Header avec thème client
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bgImage),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.blue.withOpacity(0.2),
                  BlendMode.multiply,
                ),
              ),
            ),
            child: Stack(
              children: [
                // Badge client
                Positioned(
                  top: 50,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'CLIENT',
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
                      color: Colors.blue.withOpacity(0.2),
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
                        backgroundColor: Colors.blue,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundImage: profileImageUrl?.isNotEmpty == true
                              ? NetworkImage(profileImageUrl!)
                              : const AssetImage('assets/avatars/avatar_client.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName, // ✅ CHANGÉ : Variable extraite
                              style: const TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 22,
                                color: Colors.blue,
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
                                  'CLIENT PARTICULIER',
                                  style: TextStyle(
                                    color: Colors.blue,
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

          // Menu client sécurisé
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
                  title: 'Mon espace client',
                  subtitle: 'Vue d\'ensemble de mes projets',
                  onTap: () => showDevelopmentMessage(context, 'Dashboard client'),
                ),

                const _SectionDivider(),
                
                // SECTION CHAT & ASSISTANCE
                const _SectionHeader('CHAT & ASSISTANCE'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.smart_toy_outlined,
                  title: 'Assistant IA Kipik',
                  subtitle: 'Idées de tatouages, conseils',
                  onTap: () => _openAIAssistant(context),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.support_agent_outlined,
                  title: 'Support Client',
                  subtitle: 'Aide et questions',
                  onTap: () => secureNavigate(context, SupportChatPage(userId: userId)), // ✅ CHANGÉ
                ),

                const _SectionDivider(),
                
                // SECTION MES PROJETS
                const _SectionHeader('MES PROJETS'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.folder_outlined,
                  title: 'Mes projets tatouage',
                  subtitle: 'Projets en cours et terminés',
                  onTap: () => showDevelopmentMessage(context, 'Mes projets'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.add_circle_outline,
                  title: 'Nouveau projet',
                  subtitle: 'Lancer un nouveau tatouage',
                  onTap: () => showDevelopmentMessage(context, 'Nouveau projet'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  title: 'Mes conversations',
                  subtitle: 'Chat avec mes tatoueurs',
                  onTap: () => showDevelopmentMessage(context, 'Conversations'),
                ),

                const _SectionDivider(),
                
                // SECTION DÉCOUVERTE
                const _SectionHeader('DÉCOUVERTE'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.search_outlined,
                  title: 'Trouver un tatoueur',
                  subtitle: 'Rechercher par style, ville...',
                  onTap: () => showDevelopmentMessage(context, 'Recherche tatoueurs'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.map_outlined,
                  title: 'Conventions',
                  subtitle: 'Événements tatouage près de moi',
                  onTap: () => showDevelopmentMessage(context, 'Carte des conventions'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.photo_library_outlined,
                  title: 'Galerie d\'inspiration',
                  subtitle: 'Explorer les réalisations',
                  onTap: () => showDevelopmentMessage(context, 'Galerie'),
                ),

                const _SectionDivider(),
                
                // SECTION OUTILS
                const _SectionHeader('OUTILS'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.calculate_outlined,
                  title: 'Estimateur de prix',
                  subtitle: 'Estimer le coût de mon projet',
                  onTap: () => showDevelopmentMessage(context, 'Estimateur'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'Guide du tatouage',
                  subtitle: 'Conseils et informations',
                  onTap: () => showDevelopmentMessage(context, 'Guide'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.palette_outlined,
                  title: 'Générateur d\'idées IA',
                  subtitle: 'Inspiration assistée par IA',
                  onTap: () => _openAIAssistant(context),
                ),

                const _SectionDivider(),
                
                // SECTION SOCIAL & COMMUNAUTÉ
                const _SectionHeader('COMMUNAUTÉ'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.favorite_outline,
                  title: 'Mes tatoueurs favoris',
                  subtitle: 'Artistes que je suis',
                  onTap: () => showDevelopmentMessage(context, 'Favoris'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.star_outline,
                  title: 'Mes avis',
                  subtitle: 'Évaluations que j\'ai données',
                  onTap: () => showDevelopmentMessage(context, 'Mes avis'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.share_outlined,
                  title: 'Partager mes tatouages',
                  subtitle: 'Montrer mes réalisations',
                  onTap: () => showDevelopmentMessage(context, 'Partage'),
                ),

                const _SectionDivider(),
                
                // SECTION PARAMÈTRES
                const _SectionHeader('PARAMÈTRES'),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Mon profil',
                  onTap: () => showDevelopmentMessage(context, 'Profil client'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => showDevelopmentMessage(context, 'Notifications'),
                ),
                _buildSecureMenuItem(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Confidentialité',
                  subtitle: 'Gérer mes données personnelles',
                  onTap: () => showDevelopmentMessage(context, 'Confidentialité'),
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

          // Actions rapides client
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
                      showDevelopmentMessage(context, 'Nouveau projet');
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Projet', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
                      backgroundColor: Colors.green,
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
                      showDevelopmentMessage(context, 'Recherche tatoueurs');
                    },
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Chercher', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
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
        allowImageGeneration: true, // Clients peuvent générer des images pour inspiration
        contextPage: 'client',
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
            color: Colors.blue.withOpacity(0.8),
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