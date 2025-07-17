// lib/pages/pro/profil_tatoueur.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart'; // ✅ CORRECT IMPORT
import 'package:kipik_v5/pages/particulier/demande_devis_page.dart';
import 'package:kipik_v5/pages/pro/mes_realisations_page.dart';
import 'package:kipik_v5/pages/pro/mon_shop_page.dart';
import 'package:kipik_v5/pages/pro/home_page_pro.dart';
import '../../theme/kipik_theme.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/core/database_manager.dart';
import 'package:kipik_v5/models/user_role.dart';

class ProfilTatoueur extends StatefulWidget {
  final String? tatoueurId;
  final String name;
  final String style;
  final String avatar;
  final String availability;
  final String studio;
  final String address;
  final double note;
  final String instagram;
  final String distance;
  final String location;
  
  final UserRole? forceMode;
  final int? initialTab; // ✅ NOUVEAU : Onglet à sélectionner par défaut

  const ProfilTatoueur({
    Key? key,
    this.tatoueurId,
    this.name = 'InkMaster',
    this.style = 'Réaliste',
    this.avatar = 'assets/avatars/avatar_profil_pro.jpg',
    this.availability = '3 jours',
    this.studio = 'Studio Ink',
    this.address = '15 Rue Saint-Dizier, 54000 Nancy',
    this.note = 4.5,
    this.instagram = '@inkmaster_tattoo',
    this.distance = '1.2 km',
    this.location = 'Nancy (54)',
    this.forceMode,
    this.initialTab, // ✅ NOUVEAU
  }) : super(key: key);

  @override
  State<ProfilTatoueur> createState() => _ProfilTatoueurState();
}

class _ProfilTatoueurState extends State<ProfilTatoueur> with TickerProviderStateMixin {
  bool _isFav = false;
  bool _isEditMode = false;
  bool _isLoading = true;
  File? _profileImage;
  File? _bannerImage;
  
  // ✅ CONTRÔLEUR POUR LES ONGLETS
  late TabController _tabController;
  
  // Données dynamiques
  Map<String, dynamic>? _tattooistData;
  UserRole? _currentUserRole;
  
  // ✅ DONNÉES FLASHS
  List<Map<String, dynamic>> _flashsList = [];
  bool _isLoadingFlashs = false;
  
  // Contrôleurs pour les champs éditables
  late TextEditingController _nameController;
  late TextEditingController _studioController;
  late TextEditingController _styleController;
  late TextEditingController _addressController;
  late TextEditingController _instagramController;
  late TextEditingController _availabilityController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  
  final String bannerAsset = 'assets/banniere_kipik.jpg';
  late String bio;

  @override
  void initState() {
    super.initState();
    // ✅ INITIALISATION AVEC ONGLET SPÉCIFIQUE
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialTab ?? 0, // ✅ Onglet par défaut ou spécifié
    );
    _initializeUserRole();
    _loadTattooistData();
    _loadFlashs(); // ✅ Charger les flashs
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _studioController.dispose();
    _styleController.dispose();
    _addressController.dispose();
    _instagramController.dispose();
    _availabilityController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initializeUserRole() {
    if (widget.forceMode != null) {
      _currentUserRole = widget.forceMode;
      return;
    }

    final currentRole = SecureAuthService.instance.currentUserRole;
    final currentUserId = SecureAuthService.instance.currentUserId;
    
    if (currentRole == UserRole.tatoueur) {
      if (widget.tatoueurId == null || widget.tatoueurId == currentUserId) {
        _currentUserRole = UserRole.tatoueur;
      } else {
        _currentUserRole = UserRole.client;
      }
    } else {
      _currentUserRole = currentRole;
    }

    print('🎯 Rôle utilisateur: $_currentUserRole pour utilisateur: $currentRole');
    print('🎯 Onglet initial sélectionné: ${widget.initialTab ?? 0}');
  }

  Future<void> _loadTattooistData() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.tatoueurId != null) {
        _tattooistData = await _fetchTattooistFromDatabase(widget.tatoueurId!);
      }
      
      if (_tattooistData == null) {
        _tattooistData = _generateTattooistData();
      }
      
      _initializeControllers();
      _generateBio();
      
    } catch (e) {
      print('❌ Erreur chargement tatoueur: $e');
      _tattooistData = _generateTattooistData();
      _initializeControllers();
      _generateBio();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ NOUVELLE MÉTHODE : CHARGER LES FLASHS
  Future<void> _loadFlashs() async {
    if (!_canManageFlashs && _currentUserRole != UserRole.client) return;
    
    setState(() => _isLoadingFlashs = true);
    
    try {
      // TODO: Remplacer par la vraie requête Firebase
      await Future.delayed(const Duration(seconds: 1));
      
      // Données de démonstration
      _flashsList = _generateDemoFlashs();
      
    } catch (e) {
      print('❌ Erreur chargement flashs: $e');
      _flashsList = [];
    } finally {
      setState(() => _isLoadingFlashs = false);
    }
  }

  // ✅ GÉNÉRER DES FLASHS DE DÉMO
  List<Map<String, dynamic>> _generateDemoFlashs() {
    return [
      {
        'id': 'flash_001',
        'title': 'Rose Minimaliste',
        'imageUrl': 'assets/images/flash_rose.jpg',
        'price': 150.0,
        'size': '8x6cm',
        'style': 'Minimaliste',
        'status': 'available', // available, flashminute, reserved
        'tags': ['Rose', 'Fleur', 'Délicat'],
        'placement': ['Poignet', 'Cheville'],
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'views': 24,
        'likes': 7,
      },
      {
        'id': 'flash_002',
        'title': 'Lion Géométrique',
        'imageUrl': 'assets/images/flash_lion.jpg',
        'price': 280.0,
        'size': '12x10cm',
        'style': 'Géométrique',
        'status': 'flashminute',
        'originalPrice': 350.0,
        'discount': 20,
        'tags': ['Lion', 'Animal', 'Géométrie'],
        'placement': ['Bras', 'Cuisse'],
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'views': 45,
        'likes': 12,
        'urgentUntil': DateTime.now().add(const Duration(hours: 6)),
      },
      {
        'id': 'flash_003',
        'title': 'Mandala Lotus',
        'imageUrl': 'assets/images/flash_mandala.jpg',
        'price': 200.0,
        'size': '10x10cm',
        'style': 'Mandala',
        'status': 'available',
        'tags': ['Mandala', 'Lotus', 'Spirituel'],
        'placement': ['Dos', 'Avant-bras'],
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
        'views': 31,
        'likes': 9,
      },
    ];
  }

  Future<Map<String, dynamic>?> _fetchTattooistFromDatabase(String tatoueurId) async {
    try {
      final firestore = DatabaseManager.instance.firestore;
      final doc = await firestore.collection('users').doc(tatoueurId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        print('✅ Données tatoueur chargées depuis ${DatabaseManager.instance.activeDatabaseConfig.name}');
        return data;
      }
      
      return null;
    } catch (e) {
      print('❌ Erreur récupération tatoueur: $e');
      return null;
    }
  }

  Map<String, dynamic> _generateTattooistData() {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    final dbName = DatabaseManager.instance.activeDatabaseConfig.name;
    
    if (isDemoMode) {
      final demoProfiles = [
        {
          'name': 'Alex Dubois',
          'displayName': 'Alex Dubois',
          'email': 'alex.tattoo@demo.kipik.ink',
          'studio': 'Studio Ink Paris',
          'style': 'Réaliste, Japonais',
          'location': 'Paris (75)',
          'address': '42 Rue des Martyrs, 75009 Paris',
          'availability': '2-3 semaines',
          'instagram': '@alex_ink_paris',
          'note': 4.8,
          'reviewsCount': 156,
          'experience': 12,
          'specialties': ['Réalisme', 'Portraits', 'Japonais traditionnel'],
          'bio': 'Tatoueur passionné spécialisé dans le réalisme et l\'art japonais traditionnel. 12 ans d\'expérience dans le milieu du tatouage parisien.',
          'isActive': true,
          'role': 'tatoueur',
          '_source': 'demo',
        },
      ];
      
      final randomProfile = demoProfiles[Random().nextInt(demoProfiles.length)];
      randomProfile['_generatedFrom'] = dbName;
      
      return randomProfile;
      
    } else {
      return {
        'name': widget.name,
        'displayName': widget.name,
        'studio': widget.studio,
        'style': widget.style,
        'location': widget.location,
        'address': widget.address,
        'availability': widget.availability,
        'instagram': widget.instagram,
        'note': widget.note,
        'reviewsCount': 127,
        'experience': 10,
        'specialties': [widget.style],
        'bio': 'Tatoueur professionnel passionné par le ${widget.style}. 10 ans d\'expérience à ${widget.location}.',
        'isActive': true,
        'role': 'tatoueur',
        '_source': 'production',
        '_generatedFrom': DatabaseManager.instance.activeDatabaseConfig.name,
      };
    }
  }

  void _initializeControllers() {
    final data = _tattooistData!;
    
    _nameController = TextEditingController(text: data['name'] ?? data['displayName'] ?? widget.name);
    _studioController = TextEditingController(text: data['studio'] ?? widget.studio);
    _styleController = TextEditingController(text: data['style'] ?? widget.style);
    _addressController = TextEditingController(text: data['address'] ?? widget.address);
    _instagramController = TextEditingController(text: data['instagram'] ?? widget.instagram);
    _availabilityController = TextEditingController(text: data['availability'] ?? widget.availability);
    _locationController = TextEditingController(text: data['location'] ?? widget.location);
  }

  void _generateBio() {
    final data = _tattooistData!;
    
    if (data['bio'] != null) {
      bio = data['bio'];
    } else {
      final experience = data['experience'] ?? 10;
      final specialties = data['specialties'] as List<dynamic>? ?? [data['style'] ?? widget.style];
      
      bio = 'Tatoueur passionné spécialisé en ${specialties.join(', ')}.\n'
          '$experience ans d\'expérience à ${data['location'] ?? widget.location}.\n'
          'Travaillant au studio "${data['studio'] ?? widget.studio}".\n'
          'Mes créations sont reconnues pour leur finesse et leur précision.';
    }
    
    _bioController = TextEditingController(text: bio);
  }

  // ✅ PERMISSIONS
  bool get _canEdit {
    switch (_currentUserRole) {
      case UserRole.tatoueur:
        return true;
      case UserRole.admin:
        return true;
      case UserRole.client:
      case UserRole.organisateur:
      default:
        return false;
    }
  }

  bool get _canManageFlashs {
    return _currentUserRole == UserRole.tatoueur || _currentUserRole == UserRole.admin;
  }

  bool get _canViewFlashs {
    // Tous les utilisateurs peuvent voir les flashs, mais avec des interfaces différentes
    return true;
  }

  bool get _showDevisButton {
    switch (_currentUserRole) {
      case UserRole.client:
        return true;
      case UserRole.organisateur:
      case UserRole.tatoueur:
      case UserRole.admin:
      default:
        return false;
    }
  }

  bool get _showFavoriteButton {
    switch (_currentUserRole) {
      case UserRole.client:
      case UserRole.organisateur:
        return true;
      case UserRole.tatoueur:
      case UserRole.admin:
      default:
        return false;
    }
  }

  String get _getPageTitle {
    switch (_currentUserRole) {
      case UserRole.tatoueur:
        return 'Mon Profil';
      case UserRole.admin:
        return 'Profil Tatoueur (Admin)';
      case UserRole.organisateur:
        return 'Profil Tatoueur';
      case UserRole.client:
      default:
        return 'Profil Tatoueur';
    }
  }

  String get _getFlashTabTitle {
    switch (_currentUserRole) {
      case UserRole.tatoueur:
      case UserRole.admin:
        return 'Mes Flashs';
      case UserRole.client:
      case UserRole.organisateur:
      default:
        return 'Flashs Dispo';
    }
  }

  UserMode _getShopMode() {
    switch (_currentUserRole) {
      case UserRole.tatoueur:
        return UserMode.tatoueur;
      case UserRole.client:
      case UserRole.organisateur:
      case UserRole.admin:
      default:
        return UserMode.particulier;
    }
  }

  // ✅ SÉLECTION D'IMAGE AVEC FILE_SELECTOR
  Future<void> _pickProfileImage() async {
    if (!_canEdit) return;
    
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Images',
      extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
    );

    final XFile? image = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo de profil mise à jour !'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _pickBannerImage() async {
    if (!_canEdit) return;
    
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Images',
      extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
    );

    final XFile? image = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    
    if (image != null) {
      setState(() {
        _bannerImage = File(image.path);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bannière mise à jour !'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _pickFlashImage() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Images',
      extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
    );

    final XFile? image = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    
    if (image != null) {
      // TODO: Traiter l'image sélectionnée pour le flash
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image sélectionnée : ${image.name}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _toggleEditMode() {
    if (!_canEdit) return;
    
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _saveChanges() async {
    if (!_canEdit) return;
    
    setState(() => _isLoading = true);
    
    try {
      final firestore = DatabaseManager.instance.firestore;
      final userId = widget.tatoueurId ?? SecureAuthService.instance.currentUserId;
      
      if (userId != null) {
        await firestore.collection('users').doc(userId).update({
          'displayName': _nameController.text,
          'name': _nameController.text,
          'studio': _studioController.text,
          'style': _styleController.text,
          'address': _addressController.text,
          'instagram': _instagramController.text,
          'availability': _availabilityController.text,
          'location': _locationController.text,
          'bio': _bioController.text,
          'updatedAt': DateTime.now().toIso8601String(),
          'updatedBy': SecureAuthService.instance.currentUserId,
        });
        
        print('✅ Profil sauvegardé dans ${DatabaseManager.instance.activeDatabaseConfig.name}');
      }
      
      setState(() {
        _isEditMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Modifications sauvegardées !'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ MÉTHODES POUR GESTION DES FLASHS
  Future<void> _addNewFlash() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddFlashBottomSheet(),
    );
  }

  Future<void> _activateFlashMinute(String flashId) async {
    final flash = _flashsList.firstWhere((f) => f['id'] == flashId);
    
    showDialog(
      context: context,
      builder: (context) => _buildFlashMinuteDialog(flash),
    );
  }

  Future<void> _deleteFlash(String flashId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce flash ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _flashsList.removeWhere((f) => f['id'] == flashId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Flash supprimé')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ RÉSERVER UN FLASH (pour les clients)
  Future<void> _reserveFlash(Map<String, dynamic> flash) async {
    if (_currentUserRole != UserRole.client) return;
    
    // Naviguer vers la page de demande de devis avec le flash prérempli
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DemandeDevisPage(
          prefilledFlash: flash,
          tatoueurId: widget.tatoueurId,
          tatoueurName: widget.name,
        ),
      ),
    );

    // Si la réservation a été confirmée
    if (result == true) {
      setState(() {
        flash['status'] = 'reserved';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flash "${flash['title']}" réservé !'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tattooistData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: CustomAppBarKipik(
          title: 'Chargement...',
          showBackButton: true,
          useProStyle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final data = _tattooistData!;
    final note = (data['note'] as num?)?.toDouble() ?? widget.note;
    final reviewsCount = data['reviewsCount'] as int? ?? 127;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      endDrawer: DrawerFactory.of(context),
      appBar: CustomAppBarKipik(
        title: _getPageTitle,
        showBackButton: true,
        useProStyle: true,
        onBackPressed: () {
          if (_currentUserRole == UserRole.tatoueur) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePagePro()),
              (route) => false,
            );
          } else {
            Navigator.pop(context);
          }
        },
        actions: [
          if (_showFavoriteButton) ...[
            IconButton(
              icon: Icon(
                _isFav ? Icons.favorite : Icons.favorite_border,
                color: _isFav ? KipikTheme.rouge : Colors.white,
                size: 24,
              ),
              onPressed: () => setState(() => _isFav = !_isFav),
            ),
          ],
          if (_canEdit) ...[
            IconButton(
              icon: Icon(
                _isEditMode ? Icons.save : Icons.edit,
                color: Colors.white,
                size: 24,
              ),
              onPressed: _isEditMode ? _saveChanges : _toggleEditMode,
            ),
          ],
          if (_currentUserRole == UserRole.admin) ...[
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber, size: 24),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Actions admin à implémenter')),
                );
              },
            ),
          ],
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 24),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      floatingActionButton: const TattooAssistantButton(
        allowImageGeneration: false,
      ),

      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Bannière + avatar (partie fixe)
            _buildHeader(data),
            
            const SizedBox(height: 90),

            // Profil du tatoueur (partie fixe)
            _buildProfileInfo(data, note, reviewsCount),
            
            const SizedBox(height: 24),
            
            // ✅ ONGLETS AVEC MES FLASHS
            _buildTabSection(),
          ],
        ),
      ),

      bottomNavigationBar: _showDevisButton ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  KipikTheme.rouge,
                  KipikTheme.rouge.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: KipikTheme.rouge.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DemandeDevisPage()),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.request_quote_outlined, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Demander un devis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ) : null,
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: _canEdit ? _pickBannerImage : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _bannerImage != null 
                      ? Image.file(
                          _bannerImage!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          bannerAsset,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                ),
                if (_canEdit)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                if (DatabaseManager.instance.isDemoMode)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🎭 ${DatabaseManager.instance.activeDatabaseConfig.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          child: GestureDetector(
            onTap: _canEdit ? _pickProfileImage : null,
            child: Hero(
              tag: 'avatarHero',
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  image: _profileImage != null
                      ? DecorationImage(
                          image: FileImage(_profileImage!),
                          fit: BoxFit.cover,
                        )
                      : DecorationImage(
                          image: AssetImage(widget.avatar),
                          fit: BoxFit.cover,
                        ),
                ),
                child: _canEdit ? Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: KipikTheme.rouge,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: KipikTheme.rouge.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> data, double note, int reviewsCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Nom et studio
          _buildEditableField(
            controller: _nameController,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 26,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w400,
            ),
            hintText: 'Nom du tatoueur',
          ),
          const SizedBox(height: 8),
          
          _buildEditableField(
            controller: _studioController,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
            ),
            hintText: 'Nom du studio',
          ),
          
          const SizedBox(height: 16),
          
          // Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 5; i++)
                  Icon(
                    i < note.floor() ? Icons.star : 
                    (i == note.floor() && note % 1 > 0) ? Icons.star_half : Icons.star_outline,
                    color: Colors.amber,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Text(
                  '$note',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontFamily: 'PermanentMarker',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($reviewsCount avis)',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Instagram
          if (_isEditMode || _instagramController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF3B82F6),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildEditableField(
                      controller: _instagramController,
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                      ),
                      hintText: '@votre_instagram',
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),

          // Points forts
          _buildPointsForts(),
          
          const SizedBox(height: 20),

          // À propos
          _buildAPropos(),
        ],
      ),
    );
  }

  // ✅ NOUVELLE SECTION AVEC ONGLETS
  Widget _buildTabSection() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ✅ BARRE D'ONGLETS
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: KipikTheme.rouge,
                labelColor: KipikTheme.rouge,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.store_outlined, size: 18),
                        const SizedBox(width: 4),
                        Text(_currentUserRole == UserRole.tatoueur ? 'Mon Shop' : 'Shop'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 18),
                        const SizedBox(width: 4),
                        Text(_currentUserRole == UserRole.tatoueur ? 'Réalisations' : 'Réalisations'),
                      ],
                    ),
                  ),
                  // ✅ ONGLET FLASHS - VISIBLE POUR TOUS
                  if (_canViewFlashs)
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flash_on_outlined, size: 18),
                          const SizedBox(width: 4),
                          Text(_getFlashTabTitle),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // ✅ CONTENU DES ONGLETS
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Shop
                  _buildShopTab(),
                  // Réalisations
                  _buildRealisationsTab(),
                  // ✅ Flashs (visible pour tous)
                  if (_canViewFlashs) _buildFlashsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _currentUserRole == UserRole.tatoueur ? 'Mon Shop' : 'Shop du tatoueur',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Produits et accessoires',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MonShopPage(
                mode: _getShopMode(),
              )),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_currentUserRole == UserRole.tatoueur ? 'Gérer mon Shop' : 'Voir le Shop'),
          ),
        ],
      ),
    );
  }

  Widget _buildRealisationsTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _currentUserRole == UserRole.tatoueur ? 'Mes Réalisations' : 'Réalisations',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Portfolio de tatouages réalisés',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MesRealisationsPage()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_currentUserRole == UserRole.tatoueur ? 'Gérer mes Réalisations' : 'Voir les Réalisations'),
          ),
        ],
      ),
    );
  }

  // ✅ ONGLET FLASHS - ADAPTATIF SELON LE RÔLE
  Widget _buildFlashsTab() {
    if (_isLoadingFlashs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_flashsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flash_on_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _canManageFlashs ? 'Aucun flash disponible' : 'Aucun flash disponible',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _canManageFlashs 
                  ? 'Créez vos premiers flashs pour attirer les clients'
                  : 'Ce tatoueur n\'a pas encore publié de flashs',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_canManageFlashs)
              ElevatedButton.icon(
                onPressed: _addNewFlash,
                icon: const Icon(Icons.add),
                label: const Text('Créer mon premier Flash'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ✅ EN-TÊTE AVEC ACTIONS
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _canManageFlashs 
                    ? 'Mes Flashs (${_flashsList.where((f) => f['status'] != 'reserved').length})'
                    : 'Flashs Disponibles (${_flashsList.where((f) => f['status'] != 'reserved').length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_canManageFlashs)
                Row(
                  children: [
                    // Bouton Flash Minute
                    OutlinedButton.icon(
                      onPressed: () => _showFlashMinuteInfo(),
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: const Text('Flash Minute'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bouton Ajouter
                    ElevatedButton.icon(
                      onPressed: _addNewFlash,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Ajouter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KipikTheme.rouge,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        // ✅ LISTE DES FLASHS
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _canManageFlashs 
                ? _flashsList.length 
                : _flashsList.where((f) => f['status'] != 'reserved').length,
            itemBuilder: (context, index) {
              final flashList = _canManageFlashs 
                  ? _flashsList 
                  : _flashsList.where((f) => f['status'] != 'reserved').toList();
              final flash = flashList[index];
              return _buildFlashCard(flash);
            },
          ),
        ),
      ],
    );
  }

  // ✅ CARTE FLASH ADAPTATIVE
  Widget _buildFlashCard(Map<String, dynamic> flash) {
    final isFlashMinute = flash['status'] == 'flashminute';
    final hasDiscount = flash['discount'] != null;
    final isReserved = flash['status'] == 'reserved';
    final isClient = _currentUserRole == UserRole.client;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isFlashMinute ? Border.all(color: Colors.orange, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image du flash
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  flash['imageUrl'] ?? 'assets/images/placeholder_flash.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.image, color: Colors.grey[400], size: 32),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + Badge Flash Minute
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          flash['title'] ?? 'Flash sans titre',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isFlashMinute)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'FLASH MINUTE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isReserved)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'RÉSERVÉ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Style et taille
                  Text(
                    '${flash['style']} • ${flash['size']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Prix
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          '${flash['originalPrice']}€',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${flash['discount']}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${flash['price']}€',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isFlashMinute ? Colors.orange : KipikTheme.rouge,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Stats ou Action pour client
                  if (isClient && !isReserved) ...[
                    // Bouton Réserver pour les clients
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _reserveFlash(flash),
                        icon: const Icon(Icons.flash_on, size: 16),
                        label: Text(isFlashMinute ? 'Réserver Flash Minute!' : 'Réserver ce Flash'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFlashMinute ? Colors.orange : KipikTheme.rouge,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Stats pour les tatoueurs
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${flash['views']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.favorite, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${flash['likes']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Actions pour tatoueurs
            if (_canManageFlashs)
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'flashminute':
                      _activateFlashMinute(flash['id']);
                      break;
                    case 'edit':
                      // TODO: Éditer le flash
                      break;
                    case 'delete':
                      _deleteFlash(flash['id']);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!isFlashMinute && !isReserved)
                    const PopupMenuItem(
                      value: 'flashminute',
                      child: Row(
                        children: [
                          Icon(Icons.flash_on, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Flash Minute'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTHODES BOTTOM SHEETS ET DIALOGS
  Widget _buildAddFlashBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ajouter un Flash',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Contenu
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  const Text(
                    'Créer un nouveau Flash',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Uploadez un design et définissez le prix',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickFlashImage();
                      },
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Sélectionner une image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KipikTheme.rouge,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DIALOG FLASH MINUTE AMÉLIORÉ AVEC DURÉE CONFIGURABLE
  Widget _buildFlashMinuteDialog(Map<String, dynamic> flash) {
    int selectedHours = 8; // Durée par défaut
    int selectedDiscount = 20; // Réduction par défaut
    
    return StatefulBuilder(
      builder: (context, setDialogState) {
        final newPrice = flash['price'] * (1 - selectedDiscount / 100);
        
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.flash_on, color: Colors.orange),
              SizedBox(width: 8),
              Text('Activer Flash Minute'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flash : ${flash['title']}'),
                const SizedBox(height: 8),
                Text('Prix actuel : ${flash['price']}€'),
                const SizedBox(height: 16),
                
                // Sélection de la réduction
                const Text(
                  'Réduction :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  value: selectedDiscount,
                  isExpanded: true,
                  items: [10, 20, 30, 40].map((discount) {
                    final discountedPrice = flash['price'] * (1 - discount / 100);
                    return DropdownMenuItem(
                      value: discount,
                      child: Text('-$discount% → ${discountedPrice.toStringAsFixed(0)}€'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedDiscount = value;
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Sélection de la durée
                const Text(
                  'Durée :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  value: selectedHours,
                  isExpanded: true,
                  items: [8, 12, 24, 48, 72].map((hours) {
                    return DropdownMenuItem(
                      value: hours,
                      child: Text('$hours heures'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedHours = value;
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Récapitulatif
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Récapitulatif Flash Minute :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('• Prix final : ${newPrice.toStringAsFixed(0)}€'),
                      Text('• Économie : ${(flash['price'] - newPrice).toStringAsFixed(0)}€'),
                      Text('• Durée : $selectedHours heures'),
                      Text('• Fin : ${DateTime.now().add(Duration(hours: selectedHours)).toString().substring(0, 16)}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  flash['status'] = 'flashminute';
                  flash['originalPrice'] = flash['price'];
                  flash['price'] = newPrice;
                  flash['discount'] = selectedDiscount;
                  flash['urgentUntil'] = DateTime.now().add(Duration(hours: selectedHours));
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Flash Minute activé ! -$selectedDiscount% pendant ${selectedHours}h'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Activer'),
            ),
          ],
        );
      },
    );
  }

  void _showFlashMinuteInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flash_on, color: Colors.orange),
            SizedBox(width: 8),
            Text('Flash Minute'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Qu\'est-ce que Flash Minute ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Quand un client annule au dernier moment, activez Flash Minute sur vos flashs pour les proposer avec une réduction et remplir votre créneau libre.',
            ),
            SizedBox(height: 16),
            Text(
              '⚡ Promotion immédiate\n'
              '📱 Notification aux clients\n'
              '💰 Optimisation des revenus\n'
              '⏰ Durée configurable (8h à 72h)\n'
              '🎯 Pricing dynamique',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  // ✅ NOTIFICATION AUTOMATIQUE LORS D'ANNULATION (à appeler depuis le système de réservation)
  void _showCancellationFlashMinutePrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Créneau annulé'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Un client vient d\'annuler son rendez-vous.'),
            SizedBox(height: 12),
            Text(
              'Voulez-vous activer Flash Minute sur vos flashs disponibles pour optimiser votre planning ?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _activateFlashMinuteForAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Activer Flash Minute'),
          ),
        ],
      ),
    );
  }

  // ✅ ACTIVER FLASH MINUTE SUR TOUS LES FLASHS DISPONIBLES
  void _activateFlashMinuteForAll() {
    final availableFlashs = _flashsList.where((f) => f['status'] == 'available').toList();
    
    if (availableFlashs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun flash disponible pour Flash Minute')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activer Flash Minute en masse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${availableFlashs.length} flashs seront activés en Flash Minute'),
            const SizedBox(height: 16),
            const Text('Paramètres par défaut :'),
            const Text('• Réduction : -20%'),
            const Text('• Durée : 8 heures'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (var flash in availableFlashs) {
                  flash['status'] = 'flashminute';
                  flash['originalPrice'] = flash['price'];
                  flash['price'] = flash['price'] * 0.8; // -20%
                  flash['discount'] = 20;
                  flash['urgentUntil'] = DateTime.now().add(const Duration(hours: 8));
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${availableFlashs.length} flashs activés en Flash Minute !'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Activer tout'),
          ),
        ],
      ),
    );
  }

  // AUTRES MÉTHODES (déjà existantes, restent inchangées)
  Widget _buildEditableField({
    required TextEditingController controller,
    required TextStyle style,
    required String hintText,
    bool compact = false,
    int maxLines = 1,
  }) {
    if (!_canEdit || !_isEditMode) {
      return Text(
        controller.text.isEmpty ? hintText : controller.text,
        style: controller.text.isEmpty ? style.copyWith(color: Colors.grey) : style,
        maxLines: maxLines,
        overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
      );
    }

    return TextField(
      controller: controller,
      style: style,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: style.copyWith(color: Colors.grey),
        border: compact ? InputBorder.none : UnderlineInputBorder(
          borderSide: BorderSide(color: KipikTheme.rouge.withOpacity(0.3)),
        ),
        focusedBorder: compact ? InputBorder.none : UnderlineInputBorder(
          borderSide: BorderSide(color: KipikTheme.rouge),
        ),
        contentPadding: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _buildPointsForts() {
    final data = _tattooistData!;
    final experience = data['experience'] ?? 10;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KipikTheme.rouge.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star_outline, color: KipikTheme.rouge, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mes points forts',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FeatureRow(
            icon: Icons.brush,
            label: 'Spécialités : ${_styleController.text}',
            isDarkMode: false,
            isEditable: _canEdit && _isEditMode,
            controller: _styleController,
          ),
          FeatureRow(
            icon: Icons.schedule,
            label: '$experience ans d\'expérience',
            isDarkMode: false,
          ),
          FeatureRow(
            icon: Icons.location_on,
            label: _locationController.text,
            isDarkMode: false,
            isEditable: _canEdit && _isEditMode,
            controller: _locationController,
          ),
          FeatureRow(
            icon: Icons.access_time,
            label: 'Disponibilité : ${_availabilityController.text}',
            isDarkMode: false,
            isEditable: _canEdit && _isEditMode,
            controller: _availabilityController,
          ),
          FeatureRow(
            icon: Icons.pin_drop,
            label: _addressController.text,
            isDarkMode: false,
            isEditable: _canEdit && _isEditMode,
            controller: _addressController,
          ),
          if (_showDevisButton)
            FeatureRow(
              icon: Icons.social_distance,
              label: 'Distance : ${widget.distance}',
              isDarkMode: false,
            ),
        ],
      ),
    );
  }

  Widget _buildAPropos() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KipikTheme.rouge.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline, color: KipikTheme.rouge, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'À propos de moi',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEditableField(
            controller: _bioController,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            hintText: 'Parlez de vous, votre expérience, votre passion...',
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}

class FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDarkMode;
  final bool isEditable;
  final TextEditingController? controller;
  
  const FeatureRow({
    required this.icon, 
    required this.label, 
    this.isDarkMode = true,
    this.isEditable = false,
    this.controller,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: KipikTheme.rouge, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isEditable && controller != null
                ? TextField(
                    controller: controller,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : const Color(0xFF6B7280),
                      fontSize: 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: KipikTheme.rouge.withOpacity(0.3)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: KipikTheme.rouge),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : const Color(0xFF6B7280),
                      fontSize: 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}