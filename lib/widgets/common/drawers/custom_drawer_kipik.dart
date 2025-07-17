// lib/widgets/common/drawers/custom_drawer_kipik.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/utils/chat_helper.dart';

// ✅ IMPORTS PAGES EXISTANTES - ORGANISÉS PAR CATÉGORIE
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

// Outils Pro
import 'package:kipik_v5/pages/conventions/convention_map_page.dart';
import 'package:kipik_v5/pages/pro/suppliers/suppliers_list_page.dart';

// Gestion & Comptabilité
import 'package:kipik_v5/pages/pro/comptabilite/comptabilite_page.dart';

// Support & Chat
import 'package:kipik_v5/pages/support/support_chat_page.dart';
import 'package:kipik_v5/widgets/chat/ai_chat_bottom_sheet.dart';

// Paramètres
import 'package:kipik_v5/pages/pro/parametres_pro_page.dart';
import 'package:kipik_v5/pages/pro/notifications_pro_page.dart';

// ✅ IMPORTS SHARED CORRIGÉS
import 'package:kipik_v5/pages/shared/inspirations/inspirations_page.dart';

// ✅ NOUVEAUX IMPORTS FLASH SYSTÈME (Phase 5) - Gardés pour les liens directs spécialisés
import 'package:kipik_v5/pages/pro/flashs/publier_flash_page.dart';
import 'package:kipik_v5/pages/pro/flashs/flash_minute_create_page.dart';
import 'package:kipik_v5/pages/pro/flashs/analytics_flashs_page.dart';

// ✅ NOUVEAUX IMPORTS BOOKING SYSTÈME
import 'package:kipik_v5/pages/pro/booking/demandes_rdv_page.dart';
// import 'package:kipik_v5/pages/pro/booking/rdv_validation_page.dart'; // ❌ SUPPRIMÉ car nécessite requestId
// import 'package:kipik_v5/pages/shared/booking/booking_chat_page.dart'; // ❌ SUPPRIMÉ car nécessite booking

class CustomDrawerKipik extends StatelessWidget {
  const CustomDrawerKipik({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = SecureAuthService.instance.currentUser;
    
    // Vérifications de sécurité avec SecureAuthService
    if (currentUser == null || !SecureAuthService.instance.isAuthenticated) {
      return _buildFallbackDrawer();
    }
    
    final currentRole = SecureAuthService.instance.currentUserRole;
    if (currentRole != UserRole.tatoueur) {
      return _buildFallbackDrawer();
    }
    
    // ✅ Extraction sécurisée des données utilisateur
    final userData = _extractUserData(currentUser);
    
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
          // ✅ Header avec image aléatoire et thème tatoueur
          _buildDrawerHeader(userData, bgImage),

          // ✅ Menu optimisé avec navigation unifiée vers le profil
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 16),
                
                // SECTION PRINCIPALE - Accès rapide aux pages les plus utilisées
                _buildSectionHeader('TABLEAU DE BORD'),
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
                  onTap: () => _navigateToProfilTab(context, 0), // ✅ Tab général
                ),

                const _SectionDivider(),
                
                // ✅ SECTION UNIFIÉE : MON PROFIL & PORTFOLIO
                _buildSectionHeader('MON PROFIL & PORTFOLIO'),
                _buildMenuItem(
                  context,
                  icon: Icons.store_outlined,
                  title: 'Mon Shop',
                  subtitle: 'Produits et accessoires',
                  onTap: () => _navigateToProfilTab(context, 0), // ✅ Tab Shop dans profil
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.photo_library_outlined,
                  title: 'Mes Réalisations',
                  subtitle: 'Portfolio de tatouages terminés',
                  onTap: () => _navigateToProfilTab(context, 1), // ✅ Tab Réalisations dans profil
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.flash_on_outlined,
                  title: 'Mes Flashs',
                  subtitle: 'Flashs disponibles et Flash Minute',
                  badge: '🔥',
                  onTap: () => _navigateToProfilTab(context, 2), // ✅ Tab Flashs dans profil
                ),

                const _SectionDivider(),
                
                // ✅ SECTION FLASH OUTILS AVANCÉS
                _buildSectionHeader('OUTILS FLASH AVANCÉS'),
                _buildMenuItem(
                  context,
                  icon: Icons.add_circle_outline,
                  title: 'Publier un Flash',
                  subtitle: 'Créer nouveau flash rapidement',
                  onTap: () => _navigateTo(context, const PublierFlashPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.timer_outlined,
                  title: 'Flash Minute',
                  subtitle: 'Créer offres last-minute',
                  badge: '⚡',
                  onTap: () => _navigateTo(context, const FlashMinuteCreatePage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Analytics Flashs',
                  subtitle: 'Statistiques et performance',
                  onTap: () => _navigateTo(context, const AnalyticsFlashsPage()),
                ),

                const _SectionDivider(),
                
                // ✅ SECTION RÉSERVATIONS FLASHS
                _buildSectionHeader('RÉSERVATIONS FLASHS'),
                _buildMenuItem(
                  context,
                  icon: Icons.request_page_outlined,
                  title: 'Demandes de RDV',
                  subtitle: 'Nouvelles réservations flashs',
                  badge: '📬',
                  onTap: () => _navigateTo(context, const DemandesRdvPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  title: 'Mes conversations',
                  subtitle: 'Chats avec les clients',
                  badge: '💬',
                  onTap: () => _navigateToChats(context), // ✅ Navigation vers liste des chats
                ),

                const _SectionDivider(),
                
                // SECTION PROJETS & CLIENTS (Devis classiques)
                _buildSectionHeader('PROJETS PERSONNALISÉS'),
                _buildMenuItem(
                  context,
                  icon: Icons.request_quote_outlined,
                  title: 'Devis en attente',
                  subtitle: 'Projets personnalisés',
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
                
                // SECTION INSPIRATIONS
                _buildSectionHeader('INSPIRATION & CRÉATIVITÉ'),
                _buildMenuItem(
                  context,
                  icon: Icons.brush_outlined,
                  title: 'Galerie d\'inspiration',
                  subtitle: 'Explorer les tendances',
                  onTap: () => _navigateTo(context, const InspirationsPage()),
                ),

                const _SectionDivider(),
                
                // SECTION AGENDA & PLANNING
                _buildSectionHeader('AGENDA & PLANNING'),
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
                
                // SECTION OUTILS PRO
                _buildSectionHeader('OUTILS PRO'),
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
                _buildSectionHeader('COMPTABILITÉ'),
                _buildMenuItem(
                  context,
                  icon: Icons.euro_outlined,
                  title: 'Comptabilité',
                  onTap: () => _navigateTo(context, const ComptabilitePage()),
                ),

                const _SectionDivider(),
                
                // SECTION CHAT & ASSISTANCE
                _buildSectionHeader('CHAT & ASSISTANCE'),
                _buildMenuItem(
                  context,
                  icon: Icons.smart_toy_outlined,
                  title: 'Assistant IA Kipik',
                  subtitle: 'Questions, idées, aide navigation',
                  badge: '🤖',
                  onTap: () => _openAIAssistant(context),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.support_agent_outlined,
                  title: 'Support Client',
                  subtitle: 'Aide, bugs, questions techniques',
                  onTap: () => _navigateTo(context, SupportChatPage(userId: userData['uid'])),
                ),

                const _SectionDivider(),
                
                // SECTION PARAMÈTRES
                _buildSectionHeader('PARAMÈTRES'),
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

          // ✅ Actions rapides
          _buildQuickActions(context, userData['uid']),

          // ✅ Déconnexion
          _buildLogoutSection(context),
        ],
      ),
    );
  }

  // ✅ MÉTHODES HELPER - Extraction sécurisée des données utilisateur
  Map<String, dynamic> _extractUserData(dynamic currentUser) {
    try {
      if (currentUser == null) {
        return {
          'name': 'Tatoueur',
          'email': '',
          'uid': '',
          'profileImageUrl': null,
        };
      }

      Map<String, dynamic> userData;
      
      if (currentUser is Map<String, dynamic>) {
        userData = currentUser;
      } else {
        userData = {
          'displayName': currentUser.displayName,
          'name': currentUser.displayName,
          'email': currentUser.email,
          'photoURL': currentUser.photoURL,
          'uid': currentUser.uid,
        };
      }
      
      return {
        'name': userData['name']?.toString() ?? 
                userData['displayName']?.toString() ?? 
                userData['businessName']?.toString() ?? 
                userData['studioName']?.toString() ?? 
                'Tatoueur',
        'email': userData['email']?.toString() ?? '',
        'uid': userData['uid']?.toString() ?? userData['id']?.toString() ?? '',
        'profileImageUrl': userData['profileImageUrl']?.toString() ?? 
                          userData['photoURL']?.toString() ?? 
                          userData['avatar']?.toString(),
      };
    } catch (e) {
      print('❌ Erreur extraction données utilisateur: $e');
      return {
        'name': 'Tatoueur',
        'email': '',
        'uid': '',
        'profileImageUrl': null,
      };
    }
  }

  Widget _buildFallbackDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF0A0A0A),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Erreur d\'authentification',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(Map<String, dynamic> userData, String bgImage) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(bgImage),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            print('❌ Erreur image header: $exception');
          },
        ),
      ),
      child: Stack(
        children: [
          // Badge PRO
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: KipikTheme.rouge.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KipikTheme.rouge, width: 2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.brush, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'PRO',
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
          // Effet décoratif
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
          // Avatar et infos utilisateur
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: KipikTheme.rouge,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundImage: (userData['profileImageUrl']?.isNotEmpty == true)
                        ? NetworkImage(userData['profileImageUrl']!)
                        : const AssetImage('assets/avatars/avatar_neutre.png') as ImageProvider,
                    onBackgroundImageError: (exception, stackTrace) {
                      print('❌ Erreur image avatar: $exception');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['name'],
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
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(icon, color: iconColor ?? Colors.white),
          if (badge != null)
            Positioned(
              right: -2,
              top: -2,
              child: Text(
                badge,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
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

  Widget _buildQuickActions(BuildContext context, String userId) {
    return Container(
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
                _navigateTo(context, SupportChatPage(userId: userId));
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
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Container(
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
        onTap: () => _handleLogout(context),
      ),
    );
  }

  // ✅ MÉTHODES DE NAVIGATION UNIFIÉE
  void _navigateTo(BuildContext context, Widget page) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e) {
      print('❌ Erreur navigation: $e');
      _showError(context, 'Erreur de navigation');
    }
  }

  // ✅ NOUVELLE MÉTHODE : Navigation vers profil avec onglet spécifique
  void _navigateToProfilTab(BuildContext context, int tabIndex) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilTatoueur(
            forceMode: UserRole.tatoueur,
            tatoueurId: SecureAuthService.instance.currentUserId,
            initialTab: tabIndex, // ✅ Paramètre pour sélectionner l'onglet
          ),
        ),
      );
    } catch (e) {
      print('❌ Erreur navigation profil: $e');
      _showError(context, 'Erreur de navigation vers le profil');
    }
  }

  // ✅ NOUVELLE MÉTHODE : Navigation vers la liste des chats/conversations
  void _navigateToChats(BuildContext context) {
    // TODO: Créer une page qui liste toutes les conversations de réservations
    // Pour le moment, on affiche la page des demandes de RDV
    _navigateTo(context, const DemandesRdvPage());
    
    // Alternative : afficher un message temporaire
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: const Text('Liste des conversations - Bientôt disponible'),
    //     backgroundColor: KipikTheme.rouge,
    //   ),
    // );
  }

  void _openAIAssistant(BuildContext context) {
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        barrierColor: Colors.black54,
        backgroundColor: Colors.transparent,
        builder: (_) => const AIChatBottomSheet(
          allowImageGeneration: false,
          contextPage: 'drawer',
        ),
      );
    } catch (e) {
      print('❌ Erreur ouverture assistant IA: $e');
      _showError(context, 'Erreur ouverture assistant');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await SecureAuthService.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/welcome');
                  }
                } catch (e) {
                  print('❌ Erreur déconnexion: $e');
                  if (context.mounted) {
                    _showError(context, 'Erreur lors de la déconnexion');
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
              child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => const Divider(color: Color(0xFF1F2937), thickness: 1);
}