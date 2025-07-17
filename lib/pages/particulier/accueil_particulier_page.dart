// lib/pages/particulier/accueil_particulier_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ NOUVEAU: Import de l'AppBar universelle
import '../../widgets/common/app_bars/universal_app_bar_kipik.dart';
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

class _AccueilParticulierPageState extends State<AccueilParticulierPage> 
    with SingleTickerProviderStateMixin {
  
  // ✅ AMÉLIORATION: Animation controller pour l'intro
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  late final String _bgAsset;
  
  // ✅ Données utilisateur avec gestion d'état améliorée
  String _userName = 'Client Kipik';
  String? _avatarUrl;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  
  // ✅ Données dynamiques depuis Firestore
  int _requestsCount = 0;
  int _projectsCount = 0;
  String? _nextAppointment = 'Aucun RDV';
  int _messagesCount = 0;

  // ✅ Services
  SecureAuthService get _authService => SecureAuthService.instance;
  DatabaseManager get _databaseManager => DatabaseManager.instance;

  @override
  void initState() {
    super.initState();
    
    // ✅ NOUVEAU: Initialisation des animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
    
    // ✅ Fond aléatoire sécurisé
    _initializeBackground();
    
    // ✅ Vérification sécurité utilisateur
    _verifyUserSecurity();
  }

  // ✅ NOUVEAU: Initialisation du fond avec vérification
  void _initializeBackground() {
    try {
      const backgrounds = [
        'assets/background1.png',
        'assets/background2.png',
        'assets/background3.png',
        'assets/background4.png',
      ];
      _bgAsset = backgrounds[Random().nextInt(backgrounds.length)];
    } catch (e) {
      print('❌ Erreur sélection background: $e');
      _bgAsset = 'assets/background1.png'; // Fallback
    }
  }

  // ✅ NOUVEAU: Vérification sécurité utilisateur
  Future<void> _verifyUserSecurity() async {
    try {
      // ✅ Vérifier que l'utilisateur est bien connecté et autorisé
      if (!_authService.isAuthenticated) {
        _redirectToLogin();
        return;
      }

      final role = _authService.currentUserRole;
      if (role == null || (!role.isClient && !role.isParticulier)) {
        _redirectToLogin();
        return;
      }

      // ✅ Utilisateur valide, charger les données
      await _initializeUserData();
      
    } catch (e) {
      print('❌ Erreur vérification sécurité: $e');
      _showSecurityError();
    }
  }

  // ✅ Initialisation des données utilisateur améliorée
  Future<void> _initializeUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // ✅ Chargement en parallèle pour optimiser
      await Future.wait([
        _loadUserProfile(),
        _loadUserStats(),
      ]);

      // ✅ Démarrer l'animation une fois les données chargées
      if (mounted) {
        _animationController.forward();
      }

    } catch (e) {
      print('❌ Erreur initialisation données utilisateur: $e');
      _handleDataError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ NOUVEAU: Gestion centralisée des erreurs
  void _handleDataError(String error) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
      });
      _setDefaultData();
    }
  }

  // ✅ Données par défaut en cas d'erreur
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

  // ✅ Charger le profil utilisateur avec sécurité renforcée
  Future<void> _loadUserProfile() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final userId = currentUser['uid'] ?? currentUser['id'];
      if (userId == null) {
        throw Exception('ID utilisateur manquant');
      }

      final userDoc = await _databaseManager.firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data()!;
        
        // ✅ Validation des données
        final displayName = userData['displayName'] ?? 
                           userData['name'] ?? 
                           userData['email']?.split('@')[0];
        
        if (displayName == null || displayName.isEmpty) {
          throw Exception('Nom utilisateur manquant');
        }
        
        setState(() {
          _userName = displayName;
          _avatarUrl = userData['profileImageUrl'];
        });
      } else {
        throw Exception('Profil utilisateur introuvable');
      }
    } catch (e) {
      print('❌ Erreur chargement profil: $e');
      if (mounted) {
        setState(() {
          _userName = 'Client Kipik';
          _avatarUrl = null;
        });
      }
      rethrow;
    }
  }

  // ✅ Charger les statistiques avec optimisation
  Future<void> _loadUserStats() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userId = currentUser['uid'] ?? currentUser['id'];
      if (userId == null) return;

      final firestore = _databaseManager.firestore;

      // ✅ Chargement en parallèle avec timeout
      final futures = await Future.wait([
        _loadQuoteRequests(firestore, userId),
        _loadProjects(firestore, userId),
        _loadNextAppointment(firestore, userId),
        _loadMessages(firestore, userId),
      ].map((future) => future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => _getDefaultValue(future),
      )));

      if (mounted) {
        setState(() {
          _requestsCount = futures[0] as int;
          _projectsCount = futures[1] as int;
          _nextAppointment = futures[2] as String;
          _messagesCount = futures[3] as int;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement statistiques: $e');
      _setDefaultData();
      rethrow;
    }
  }

  // ✅ NOUVEAU: Valeurs par défaut selon le type
  dynamic _getDefaultValue(Future future) {
    if (future.toString().contains('String')) return 'Aucun RDV';
    return 0;
  }

  // ✅ Charger les demandes de devis optimisé
  Future<int> _loadQuoteRequests(FirebaseFirestore firestore, String userId) async {
    try {
      final snapshot = await firestore
          .collection('quote_requests')
          .where('clientId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'in_progress'])
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Erreur chargement devis: $e');
      return 0;
    }
  }

  // ✅ Charger les projets optimisé
  Future<int> _loadProjects(FirebaseFirestore firestore, String userId) async {
    try {
      final snapshot = await firestore
          .collection('projects')
          .where('clientId', isEqualTo: userId)
          .where('status', whereIn: ['active', 'in_progress', 'scheduled'])
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Erreur chargement projets: $e');
      return 0;
    }
  }

  // ✅ Charger le prochain rendez-vous optimisé
  Future<String> _loadNextAppointment(FirebaseFirestore firestore, String userId) async {
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
        
        return _formatDateTime(dateTime);
      }
      
      return 'Aucun RDV';
    } catch (e) {
      print('❌ Erreur chargement RDV: $e');
      return 'Aucun RDV';
    }
  }

  // ✅ NOUVEAU: Formatage date amélioré
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    if (difference == 0) {
      return 'Aujourd\'hui • ${hour}h$minute';
    } else if (difference == 1) {
      return 'Demain • ${hour}h$minute';
    } else if (difference < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      final dayName = days[dateTime.weekday - 1];
      return '$dayName • ${hour}h$minute';
    } else {
      return '$day/$month • ${hour}h$minute';
    }
  }

  // ✅ Charger les messages optimisé
  Future<int> _loadMessages(FirebaseFirestore firestore, String userId) async {
    try {
      final snapshot = await firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .where('hasUnreadMessages.$userId', isEqualTo: true)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Erreur chargement messages: $e');
      return 0;
    }
  }

  // ✅ Actualiser les données avec feedback
  Future<void> _refreshData() async {
    try {
      await _initializeUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données actualisées'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur actualisation: $e'),
            backgroundColor: KipikTheme.rouge,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✅ NOUVEAU: Action recherche pour l'AppBar
  Widget _buildSearchAction() {
    return IconButton(
      icon: const Icon(Icons.search, color: Colors.white),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RechercheTatoueurPage(),
        ),
      ),
      tooltip: 'Rechercher un tatoueur',
    );
  }

  // ✅ NOUVEAU: Action rapide pour l'AppBar
  Widget _buildQuickAction() {
    return IconButton(
      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
      onPressed: _showQuickActions,
      tooltip: 'Actions rapides',
    );
  }

  // ✅ NOUVEAU: Menu actions rapides
  void _showQuickActions() {
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
              'Actions rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'PermanentMarker',
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.search, color: KipikTheme.rouge),
              title: const Text('Rechercher un tatoueur'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RechercheTatoueurPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add, color: KipikTheme.rouge),
              title: const Text('Nouveau projet'),
              onTap: () {
                Navigator.pop(context);
                _createNewProject();
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: KipikTheme.rouge),
              title: const Text('Prendre RDV'),
              onTap: () {
                Navigator.pop(context);
                _bookAppointment();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ Nouvelles méthodes pour actions rapides
  void _createNewProject() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Création projet - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _bookAppointment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prise de RDV - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ✅ Gestion avatar optimisée
  void _handleAvatarTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
            if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
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
              title: const Text('Paramètres du profil'),
              onTap: () {
                Navigator.pop(context);
                _goToProfileSettings();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ Méthodes de gestion profil améliorées
  void _updateProfilePicture(String source) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload photo depuis $source - À implémenter'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _removeProfilePicture() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userId = currentUser['uid'] ?? currentUser['id'];
      if (userId == null) return;

      // ✅ Confirmation avant suppression
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer la photo'),
          content: const Text('Êtes-vous sûr de vouloir supprimer votre photo de profil ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (shouldDelete == true && mounted) {
        await _authService.updateProfileField('profileImageUrl', null);

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
            backgroundColor: KipikTheme.rouge,
          ),
        );
      }
    }
  }

  void _goToProfileSettings() {
    Navigator.pushNamed(context, '/particulier/profil');
  }

  // ✅ NOUVEAUX: Méthodes de sécurité
  void _redirectToLogin() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  void _showSecurityError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur de sécurité - Veuillez vous reconnecter'),
          backgroundColor: KipikTheme.rouge,
          duration: Duration(seconds: 5),
        ),
      );
      _redirectToLogin();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        
        // ✅ NOUVEAU: AppBar universelle avec actions
        appBar: UniversalAppBarKipik.particulier(
          title: 'Accueil',
          showDrawer: true,
          showNotificationIcon: true,
          showUserAvatar: true,
          userImageUrl: _avatarUrl,
          searchAction: _buildSearchAction(),
          quickAction: _buildQuickAction(),
        ),
        
        floatingActionButton: const TattooAssistantButton(
          allowImageGeneration: false,
        ),
        
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ✅ Background avec gestion d'erreur
            Image.asset(
              _bgAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Erreur chargement background: $error');
                return Container(
                  decoration: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black87,
                      KipikTheme.rouge.withOpacity(0.8),
                    ],
                  ),
                );
              },
            ),
            
            SafeArea(
              bottom: true,
              child: _buildBody(cardW),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NOUVEAU: Corps de la page avec gestion d'état
  Widget _buildBody(double cardW) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement de vos données...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: KipikTheme.rouge,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildHeader(),
                const SizedBox(height: 12),
                _buildAvatarSection(cardW),
                const SizedBox(height: 12),
                _buildSearchButton(),
                const SizedBox(height: 12),
                Expanded(child: _buildDashboardGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ NOUVEAU: Header avec animation
  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Bienvenue, $_userName',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 26,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        
        // ✅ Indicateur base de données si mode démo
        if (_databaseManager.isDemoMode) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      ],
    );
  }

  // ✅ Section avatar améliorée
  Widget _buildAvatarSection(double cardW) {
    return GestureDetector(
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                Image.network(
                  _avatarUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar();
                  },
                )
              else
                _buildDefaultAvatar(),
              
              // Overlay éditable
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: KipikTheme.rouge,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
    );
  }

  // ✅ Bouton recherche amélioré
  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
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
        icon: const Icon(
          Icons.search,
          color: KipikTheme.rouge,
          size: 20,
        ),
        label: const Text(
          'Rechercher mon tatoueur',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ✅ Grille dashboard améliorée
  Widget _buildDashboardGrid() {
    return GridView.count(
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
            MaterialPageRoute(builder: (_) => const RdvJourPage()),
          ),
          isValueLong: (_nextAppointment?.length ?? 0) > 10,
        ),
        _DashboardCard(
          icon: Icons.request_quote,
          title: 'Demandes de devis\nen cours',
          value: '$_requestsCount',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MesDevisPage()),
          ),
          badgeCount: _requestsCount > 0 ? _requestsCount : null,
        ),
        _DashboardCard(
          icon: Icons.work_outline,
          title: 'Projets en cours',
          value: '$_projectsCount',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MesProjetsParticulierPage()),
          ),
          badgeCount: _projectsCount > 0 ? _projectsCount : null,
        ),
        _DashboardCard(
          icon: Icons.chat_bubble,
          title: 'Messages',
          value: '$_messagesCount',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MessagesParticulierPage()),
          ),
          badgeCount: _messagesCount > 0 ? _messagesCount : null,
        ),
      ],
    );
  }

  // ✅ Avatar par défaut amélioré
  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white,
      child: Image.asset(
        'assets/avatars/avatar_client.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
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

// ✅ AMÉLIORATION: Carte dashboard avec badges et animations
class _DashboardCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool isValueLong;
  final int? badgeCount;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.isValueLong = false,
    this.badgeCount,
    Key? key,
  }) : super(key: key);

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KipikTheme.rouge.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        widget.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: widget.isValueLong ? 12 : 16,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'PermanentMarker',
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  
                  // Badge de notification
                  if (widget.badgeCount != null && widget.badgeCount! > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          widget.badgeCount! > 9 ? '9+' : '${widget.badgeCount}',
                          style: const TextStyle(
                            color: KipikTheme.rouge,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}