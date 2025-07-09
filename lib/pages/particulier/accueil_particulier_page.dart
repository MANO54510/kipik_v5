// lib/pages/particulier/accueil_particulier_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../widgets/common/drawers/custom_drawer_particulier.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../theme/kipik_theme.dart';
import '../../core/database_manager.dart';
import '../../services/auth/secure_auth_service.dart';
import 'recherche_tatoueur_page.dart';
import 'rdv_jour_page.dart';
import 'mes_devis_page.dart';
import 'mes_projets_particulier_page.dart';
import 'messages_particulier_page.dart';

class AccueilParticulierPage extends StatefulWidget {
  const AccueilParticulierPage({Key? key}) : super(key: key);

  @override
  State<AccueilParticulierPage> createState() => _AccueilParticulierPageState();
}

class _AccueilParticulierPageState extends State<AccueilParticulierPage> {
  late final String _bgAsset;
  
  // ✅ Données utilisateur dynamiques
  String _userName = 'Utilisateur';
  String? _avatarUrl;
  bool _isLoading = true;
  
  // ✅ Données dynamiques depuis Firestore
  int _requestsCount = 0;
  int _projectsCount = 0;
  String? _nextAppointment;
  int _messagesCount = 0;

  // ✅ Services
  SecureAuthService get _authService => SecureAuthService.instance;
  DatabaseManager get _databaseManager => DatabaseManager.instance;

  @override
  void initState() {
    super.initState();
    const backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    _bgAsset = backgrounds[Random().nextInt(backgrounds.length)];
    
    _initializeUserData();
  }

  // ✅ Initialisation des données utilisateur
  Future<void> _initializeUserData() async {
    try {
      await _loadUserProfile();
      await _loadUserStats();
    } catch (e) {
      print('❌ Erreur initialisation données utilisateur: $e');
      // ✅ En cas d'erreur, charger des données par défaut
      _setDefaultData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ NOUVEAU: Données par défaut en cas d'erreur
  void _setDefaultData() {
    if (mounted) {
      setState(() {
        _userName = 'Client Kipik';
        _requestsCount = 0;
        _projectsCount = 0;
        _nextAppointment = 'Aucun RDV';
        _messagesCount = 0;
      });
    }
  }

  // ✅ Charger le profil utilisateur
  Future<void> _loadUserProfile() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userId = currentUser['uid'] ?? currentUser['id'];
      if (userId == null) return;

      final userDoc = await _databaseManager.firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data()!;
        
        setState(() {
          _userName = userData['displayName'] ?? 
                     userData['name'] ?? 
                     userData['email']?.split('@')[0] ?? 
                     'Client Kipik';
          _avatarUrl = userData['profileImageUrl'];
        });
      }
    } catch (e) {
      print('❌ Erreur chargement profil: $e');
      // Utiliser des données par défaut
      if (mounted) {
        setState(() {
          _userName = 'Client Kipik';
        });
      }
    }
  }

  // ✅ Charger les statistiques utilisateur avec gestion d'erreur
  Future<void> _loadUserStats() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userId = currentUser['uid'] ?? currentUser['id'];
      if (userId == null) return;

      final firestore = _databaseManager.firestore;

      // ✅ Charger chaque statistique individuellement avec gestion d'erreur
      final requests = await _loadQuoteRequests(firestore, userId);
      final projects = await _loadProjects(firestore, userId);
      final nextAppt = await _loadNextAppointment(firestore, userId);
      final messages = await _loadMessages(firestore, userId);

      if (mounted) {
        setState(() {
          _requestsCount = requests;
          _projectsCount = projects;
          _nextAppointment = nextAppt;
          _messagesCount = messages;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement statistiques: $e');
      // Valeurs par défaut en cas d'erreur
      if (mounted) {
        setState(() {
          _requestsCount = 0;
          _projectsCount = 0;
          _nextAppointment = 'Aucun RDV';
          _messagesCount = 0;
        });
      }
    }
  }

  // ✅ Charger les demandes de devis avec gestion d'erreur
  Future<int> _loadQuoteRequests(FirebaseFirestore firestore, String userId) async {
    try {
      final snapshot = await firestore
          .collection('quote_requests')
          .where('clientId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Erreur chargement devis: $e');
      return 0;
    }
  }

  // ✅ Charger les projets avec gestion d'erreur
  Future<int> _loadProjects(FirebaseFirestore firestore, String userId) async {
    try {
      final snapshot = await firestore
          .collection('projects')
          .where('clientId', isEqualTo: userId)
          .where('status', whereIn: ['active', 'in_progress', 'scheduled'])
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Erreur chargement projets: $e');
      return 0;
    }
  }

  // ✅ Charger le prochain rendez-vous avec gestion d'erreur
  Future<String?> _loadNextAppointment(FirebaseFirestore firestore, String userId) async {
    try {
      final now = DateTime.now();
      final snapshot = await firestore
          .collection('appointments')
          .where('clientId', isEqualTo: userId)
          .where('dateTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('dateTime', descending: false)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final appointment = snapshot.docs.first.data();
        final dateTime = (appointment['dateTime'] as Timestamp).toDate();
        
        final day = dateTime.day.toString().padLeft(2, '0');
        final month = dateTime.month.toString().padLeft(2, '0');
        final year = dateTime.year;
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        
        return '$day/$month/$year • ${hour}h$minute';
      }
      
      return 'Aucun RDV';
    } catch (e) {
      print('❌ Erreur chargement RDV: $e');
      return 'Aucun RDV';
    }
  }

  // ✅ Charger les messages avec gestion d'erreur
  Future<int> _loadMessages(FirebaseFirestore firestore, String userId) async {
    try {
      final snapshot = await firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .where('hasUnreadMessages.$userId', isEqualTo: true)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Erreur chargement messages: $e');
      return 0;
    }
  }

  // ✅ Actualiser les données
  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    await _initializeUserData();
  }

  // ✅ Gérer le clic sur l'avatar
  void _handleAvatarTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Photo de profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'PermanentMarker',
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _updateProfilePicture('camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(context);
                _updateProfilePicture('gallery');
              },
            ),
            if (_avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer la photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
              ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.orange),
              title: const Text('Aller aux paramètres'),
              onTap: () {
                Navigator.pop(context);
                _goToSettings();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ Mettre à jour la photo de profil
  void _updateProfilePicture(String source) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload photo depuis $source - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ✅ Supprimer la photo de profil
  Future<void> _removeProfilePicture() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userId = currentUser['uid'] ?? currentUser['id'];
      if (userId == null) return;

      await _databaseManager.firestore
          .collection('users')
          .doc(userId)
          .update({
        'profileImageUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _avatarUrl = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Aller aux paramètres
  void _goToSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation vers paramètres - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardW = (w - 48 - 12) / 2;

    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        endDrawer: const CustomDrawerParticulier(),
        appBar: const CustomAppBarParticulier(
          title: 'Accueil',
          showBackButton: false,
          showBurger: true,
          showNotificationIcon: true,
          redirectToHome: false,
        ),
        floatingActionButton: const TattooAssistantButton(
          allowImageGeneration: false,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_bgAsset, fit: BoxFit.cover),
            SafeArea(
              bottom: true,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      color: KipikTheme.rouge,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Bienvenue, $_userName',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 26,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            
                            // ✅ Indicateur base de données si mode démo
                            if (_databaseManager.isDemoMode) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, 
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '🎭 MODE DÉMO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            
                            const Text(
                              'Encre tes idées, à toi de jouer',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // ✅ Avatar cliquable avec avatar client par défaut
                            GestureDetector(
                              onTap: _handleAvatarTap,
                              child: Container(
                                width: cardW,
                                height: cardW,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // ✅ Image de profil ou avatar client par défaut
                                      if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                        Image.network(
                                          _avatarUrl!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Erreur chargement avatar réseau: $error');
                                            return _buildDefaultAvatar();
                                          },
                                        )
                                      else
                                        _buildDefaultAvatar(),
                                      
                                      // Overlay pour indiquer que c'est cliquable
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: KipikTheme.rouge, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RechercheTatoueurPage(),
                                  ),
                                ),
                                child: const Text(
                                  'Rechercher mon tatoueur',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'PermanentMarker',
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  _DashboardCard(
                                    icon: Icons.event,
                                    title: 'Prochain RDV',
                                    value: _nextAppointment ?? 'Aucun RDV',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RdvJourPage(),
                                      ),
                                    ),
                                  ),
                                  _DashboardCard(
                                    icon: Icons.request_quote,
                                    title: 'Demande de devis\nen cours',
                                    value: '$_requestsCount',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const MesDevisPage(),
                                      ),
                                    ),
                                  ),
                                  _DashboardCard(
                                    icon: Icons.work_outline,
                                    title: 'Projets en cours',
                                    value: '$_projectsCount',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MesProjetsParticulierPage(),
                                      ),
                                    ),
                                  ),
                                  _DashboardCard(
                                    icon: Icons.chat_bubble,
                                    title: 'Messages',
                                    value: '$_messagesCount',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MessagesParticulierPage(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Widget pour l'avatar par défaut
  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white,
      child: Image.asset(
        'assets/avatars/avatar_client.png', // ✅ CORRIGÉ: Utilise avatar_client.png
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Erreur chargement avatar_client.png: $error');
          // Fallback vers une icône
          return Container(
            color: Colors.white,
            child: Icon(
              Icons.person,
              color: KipikTheme.rouge,
              size: 60,
            ),
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: KipikTheme.rouge.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'PermanentMarker',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}