// lib/widgets/common/drawers/custom_drawer_particulier.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/utils/chat_helper.dart';

// ✅ IMPORTS PAGES EXISTANTES
import 'package:kipik_v5/pages/particulier/recherche_tatoueur_page.dart';
import 'package:kipik_v5/pages/particulier/mes_projets_particulier_page.dart';
import 'package:kipik_v5/pages/particulier/guide_tatouage_page.dart';
import 'package:kipik_v5/pages/particulier/aide_support_page.dart';
import 'package:kipik_v5/pages/particulier/profil_particulier_page.dart';
import 'package:kipik_v5/pages/particulier/parametres_page.dart';

// ✅ IMPORTS SHARED - PAGES CROSS-RÔLES
import 'package:kipik_v5/pages/shared/inspirations/inspirations_page.dart'; 
import 'package:kipik_v5/pages/shared/flashs/flash_swipe_page.dart';
import 'package:kipik_v5/pages/shared/flashs/flash_minute_feed_page.dart';
import 'package:kipik_v5/pages/shared/booking/booking_flow_page.dart';

// ✅ NOUVEAUX IMPORTS PARTICULIERS - SYSTÈME FLASH
import 'package:kipik_v5/pages/particulier/mes_favoris_flashs_page.dart';
import 'package:kipik_v5/pages/particulier/mes_rdv_flashs_page.dart';
import 'package:kipik_v5/pages/particulier/historique_flashs_page.dart';

class CustomDrawerParticulier extends StatelessWidget {
  const CustomDrawerParticulier({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = SecureAuthService.instance.currentUser;
    
    // Vérifications de sécurité
    if (currentUser == null || !SecureAuthService.instance.isAuthenticated) {
      return _buildFallbackDrawer();
    }

    // ✅ Extraction sécurisée des données utilisateur
    final userData = _extractUserData(currentUser);

    return Drawer(
      child: Column(
        children: [
          // Header SANS SafeArea pour qu'il occupe tout l'écran
          _buildHeader(userData),
          
          // Menu principal avec SafeArea seulement pour le contenu
          Expanded(
            child: SafeArea(
              top: false, // Pas de SafeArea en haut
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: 15 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    
                    // ✅ SECTION 1 : PROJETS & RECHERCHE (modifiée)
                    _buildMenuSection(
                      'PROJETS & RECHERCHE', // ✅ NOUVEAU NOM
                      [
                        _MenuItemData(
                          icon: Icons.search,
                          title: 'Rechercher un tatoueur',
                          subtitle: 'Trouve ton artiste idéal',
                          onTap: () => _navigateToPage(context, const RechercheTatoueurPage()),
                        ),
                        _MenuItemData(
                          icon: Icons.photo_library,
                          title: 'Galerie d\'inspiration', // ✅ FONCTIONNE TOUJOURS
                          subtitle: 'Découvre les styles',
                          onTap: () => _navigateToPage(context, const InspirationsPage()),
                        ),
                        _MenuItemData(
                          icon: Icons.folder_open,
                          title: 'Mes projets',
                          subtitle: 'Gère tes tatouages',
                          onTap: () => _navigateToPage(context, const MesProjetsParticulierPage()),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // ✅ SECTION 2 : FLASHS & DÉCOUVERTE (NOUVELLE)
                    _buildMenuSection(
                      'FLASHS & DÉCOUVERTE',
                      [
                        _MenuItemData(
                          icon: Icons.swipe,
                          title: 'Découvrir des Flashs',
                          subtitle: 'Swipe pour trouver ton style',
                          onTap: () => _navigateToPage(context, const FlashSwipePage()),
                        ),
                        _MenuItemData(
                          icon: Icons.flash_on,
                          title: 'Flash Minute',
                          subtitle: 'Offres last-minute à prix réduit',
                          onTap: () => _navigateToPage(context, const FlashMinuteFeedPage()),
                        ),
                        _MenuItemData(
                          icon: Icons.favorite,
                          title: 'Mes Flashs Favoris',
                          subtitle: 'Flashs que j\'aime',
                          onTap: () => _navigateToPage(context, const MesFavorisFlashsPage()),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // ✅ SECTION 3 : MES RÉSERVATIONS (NOUVELLE)
                    _buildMenuSection(
                      'MES RÉSERVATIONS',
                      [
                        _MenuItemData(
                          icon: Icons.calendar_today,
                          title: 'Mes RDV Flash',
                          subtitle: 'Réservations en cours et passées',
                          onTap: () => _navigateToPage(context, const MesRdvFlashsPage()),
                        ),
                        _MenuItemData(
                          icon: Icons.history,
                          title: 'Historique Flashs',
                          subtitle: 'Mes tatouages terminés',
                          onTap: () => _navigateToPage(context, const HistoriqueFlashsPage()),
                        ),
                        _MenuItemData(
                          icon: Icons.chat_bubble_outline,
                          title: 'Messages Booking',
                          subtitle: 'Chat avec tatoueurs',
                          onTap: () => _showComingSoon(context, 'Messages Booking - Semaine 3'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // ✅ SECTION 4 : Aide & Support (conservée)
                    _buildMenuSection(
                      'Aide & Support',
                      [
                        _MenuItemData(
                          icon: Icons.smart_toy,
                          title: 'Assistant Kipik',
                          subtitle: 'Conseils personnalisés',
                          onTap: () => _openAIAssistant(context),
                        ),
                        _MenuItemData(
                          icon: Icons.menu_book,
                          title: 'Guide du tatouage',
                          subtitle: 'Tout savoir sur les tatouages',
                          onTap: () => _navigateToPage(context, const GuideTatouagePage()),
                        ),
                        _MenuItemData(
                          icon: Icons.support_agent,
                          title: 'Support client',
                          subtitle: 'Besoin d\'aide ?',
                          onTap: () => _navigateToPage(context, const AideSupportPage()),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // ✅ SECTION 5 : Mon compte (conservée)
                    _buildMenuSection(
                      'Mon compte',
                      [
                        _MenuItemData(
                          icon: Icons.person,
                          title: 'Profil',
                          subtitle: 'Mes informations',
                          onTap: () => _navigateToPage(context, const ProfilParticulierPage()),
                        ),
                        _MenuItemData(
                          icon: Icons.settings,
                          title: 'Paramètres',
                          subtitle: 'Préférences',
                          onTap: () => _navigateToPage(context, const ParametresPage()),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Bouton de déconnexion simplifié
                    _buildLogoutButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTHODES HELPER - Extraction sécurisée des données utilisateur
  Map<String, dynamic> _extractUserData(dynamic currentUser) {
    try {
      if (currentUser == null) {
        return {
          'name': 'Utilisateur',
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
                userData['prenom']?.toString() ?? 
                userData['userName']?.toString() ?? 
                userData['firstName']?.toString() ?? 
                'Utilisateur',
        'email': userData['email']?.toString() ?? '',
        'uid': userData['uid']?.toString() ?? userData['id']?.toString() ?? '',
        'profileImageUrl': userData['profileImageUrl']?.toString() ?? 
                          userData['photoURL']?.toString() ?? 
                          userData['avatar']?.toString(),
      };
    } catch (e) {
      print('❌ Erreur extraction données utilisateur: $e');
      return {
        'name': 'Utilisateur',
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

  Widget _buildHeader(Map<String, dynamic> userData) {
    // ✅ Images avec fallback sécurisé
    final headerImages = [
      'assets/images/header_tattoo_wallpaper.png',
      'assets/images/header_tattoo_wallpaper2.png',
      'assets/images/header_tattoo_wallpaper3.png',
    ];
    
    final randomImage = headerImages[Random().nextInt(headerImages.length)];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final headerHeight = screenHeight * 0.25;
        final topPadding = MediaQuery.of(context).padding.top;
        
        return Container(
          height: headerHeight,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(randomImage),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6),
                BlendMode.multiply,
              ),
              onError: (exception, stackTrace) {
                print('❌ Erreur chargement image header: $exception');
              },
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KipikTheme.rouge.withOpacity(0.8),
                KipikTheme.rouge.withOpacity(0.6),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, topPadding + 15, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  
                  // Avatar et infos utilisateur
                  Row(
                    children: [
                      // Avatar avec contour
                      Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: KipikTheme.rouge,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (userData['profileImageUrl']?.isNotEmpty == true)
                              ? Image.network(
                                  userData['profileImageUrl']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildFallbackAvatar();
                                  },
                                )
                              : _buildFallbackAvatar(),
                        ),
                      ),
                      
                      const SizedBox(width: 20),
                      
                      // Infos utilisateur
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData['name'],
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Roboto',
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            
                            if (userData['email'].isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                userData['email'],
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.7),
                                      blurRadius: 3,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackAvatar() {
    return Image.asset(
      'assets/avatars/avatar_client.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.person,
            color: Colors.grey[600],
            size: 40,
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItemData> items) {
    final headerImages = [
      'assets/images/header_tattoo_wallpaper.png',
      'assets/images/header_tattoo_wallpaper2.png',
      'assets/images/header_tattoo_wallpaper3.png',
    ];
    
    final randomImage = headerImages[Random().nextInt(headerImages.length)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de section avec fond sécurisé
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: AssetImage(randomImage),
              fit: BoxFit.cover,
              colorFilter: const ColorFilter.mode(
                Colors.white70,
                BlendMode.lighten,
              ),
              onError: (exception, stackTrace) {
                print('❌ Erreur image section: $exception');
              },
            ),
            gradient: LinearGradient(
              colors: [
                KipikTheme.rouge.withOpacity(0.1),
                KipikTheme.rouge.withOpacity(0.3),
              ],
            ),
            border: Border.all(
              color: KipikTheme.rouge.withOpacity(0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: KipikTheme.rouge,
              fontFamily: 'PermanentMarker',
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Items du menu
        ...items.map((item) => _buildMenuItem(item)),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItemData item) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              color: KipikTheme.rouge,
              size: 22,
            ),
          ),
          title: Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
              fontFamily: 'Roboto',
            ),
          ),
          subtitle: item.subtitle != null
              ? Text(
                  item.subtitle!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Roboto',
                  ),
                )
              : null,
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
          onTap: item.onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Se déconnecter',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: KipikTheme.rouge,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // ✅ MÉTHODES DE NAVIGATION ET INTERACTION
  void _navigateToPage(BuildContext context, Widget page) {
    try {
      Navigator.pop(context); // Fermer le drawer d'abord
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    } catch (e) {
      print('❌ Erreur navigation: $e');
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _openAIAssistant(BuildContext context) {
    Navigator.pop(context);
    ChatHelper.openAIAssistant(
      context,
      allowImageGeneration: false,
      contextPage: 'client',
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚀 $feature - Bientôt disponible !'),
        backgroundColor: KipikTheme.rouge,
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
                await SecureAuthService.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
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

class _MenuItemData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? route;
  final VoidCallback? onTap;

  _MenuItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.route,
    this.onTap,
  });
}