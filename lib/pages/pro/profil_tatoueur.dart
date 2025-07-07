// lib/pages/pro/profil_tatoueur.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
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

// ✅ Harmonisation : Suppression de ViewMode, utilisation directe de UserRole
// Plus besoin d'un enum séparé, on utilise directement UserRole du modèle

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
  
  // ✅ Mode forcé basé sur UserRole (optionnel)
  final UserRole? forceMode;

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
  }) : super(key: key);

  @override
  State<ProfilTatoueur> createState() => _ProfilTatoueurState();
}

class _ProfilTatoueurState extends State<ProfilTatoueur> {
  bool _isFav = false;
  bool _isEditMode = false;
  bool _isLoading = true;
  File? _profileImage;
  File? _bannerImage;
  
  // Données dynamiques (overrides les props si trouvées)
  Map<String, dynamic>? _tattooistData;
  UserRole? _currentUserRole; // ✅ Utilise UserRole au lieu de ViewMode
  
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
    _initializeUserRole();
    _loadTattooistData();
  }

  /// ✅ CALCULER LE RÔLE DE L'UTILISATEUR CONNECTÉ
  void _initializeUserRole() {
    if (widget.forceMode != null) {
      _currentUserRole = widget.forceMode;
      return;
    }

    final currentRole = SecureAuthService.instance.currentUserRole;
    final currentUserId = SecureAuthService.instance.currentUserId;
    
    // Si c'est un tatoueur qui regarde son propre profil ou pas d'ID spécifié
    if (currentRole == UserRole.tatoueur) {
      if (widget.tatoueurId == null || widget.tatoueurId == currentUserId) {
        _currentUserRole = UserRole.tatoueur; // Son propre profil
      } else {
        _currentUserRole = UserRole.client; // Profil d'un autre tatoueur (vue client)
      }
    } else {
      _currentUserRole = currentRole; // Garde le rôle original
    }

    print('🎯 Rôle utilisateur: $_currentUserRole pour utilisateur: $currentRole');
  }

  /// ✅ CHARGER LES DONNÉES DU TATOUEUR
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

  /// ✅ RÉCUPÉRER LES DONNÉES DEPUIS LA BASE DE DONNÉES
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

  /// ✅ GÉNÉRER DES DONNÉES SELON LE MODE
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
        {
          'name': 'Sophie Martinez',
          'displayName': 'Sophie Martinez',
          'email': 'sophie.ink@demo.kipik.ink',
          'studio': 'Atelier Luna',
          'style': 'Minimaliste, Géométrique',
          'location': 'Lyon (69)',
          'address': '15 Rue de la République, 69002 Lyon',
          'availability': '1-2 semaines',
          'instagram': '@luna_tattoo_lyon',
          'note': 4.9,
          'reviewsCount': 203,
          'experience': 8,
          'specialties': ['Minimalisme', 'Géométrie', 'Fine line'],
          'bio': 'Artiste tatoueur spécialisée dans les créations minimalistes et géométriques. Mon style se caractérise par des lignes fines et des compositions épurées.',
          'isActive': true,
          'role': 'tatoueur',
          '_source': 'demo',
        },
        {
          'name': 'Marc Dubois',
          'displayName': 'Marc Dubois',
          'email': 'marc.blackwork@demo.kipik.ink',
          'studio': 'Black & Grey Studio',
          'style': 'Black & Grey, Tribal',
          'location': 'Marseille (13)',
          'address': '8 Cours Julien, 13006 Marseille',
          'availability': '3-4 semaines',
          'instagram': '@marc_blackwork',
          'note': 4.7,
          'reviewsCount': 89,
          'experience': 15,
          'specialties': ['Black & Grey', 'Tribal moderne', 'Biomécanique'],
          'bio': 'Vétéran du tatouage marseillais, je me spécialise dans les créations en noir et gris. Passionné par les motifs tribaux modernes.',
          'isActive': true,
          'role': 'tatoueur',
          '_source': 'demo',
        }
      ];
      
      final randomProfile = demoProfiles[Random().nextInt(demoProfiles.length)];
      randomProfile['_generatedFrom'] = dbName;
      
      print('🎭 Données démo générées: ${randomProfile['name']} depuis $dbName');
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
        '_generatedFrom': dbName,
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

  @override
  void dispose() {
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

  // ✅ PERMISSIONS SELON LE RÔLE
  bool get _canEdit {
    switch (_currentUserRole) {
      case UserRole.tatoueur:
        return true; // Le tatoueur peut éditer son profil
      case UserRole.admin:
        return true; // L'admin peut tout éditer
      case UserRole.client:
      case UserRole.organisateur:
      default:
        return false; // Lecture seule
    }
  }

  bool get _showDevisButton {
    switch (_currentUserRole) {
      case UserRole.client:
        return true; // Seulement les clients voient le bouton devis
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
        return true; // Peuvent ajouter en favoris
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

  String get _getShopButtonLabel {
    switch (_currentUserRole) {
      case UserRole.tatoueur:
        return 'Mon Shop';
      case UserRole.admin:
        return 'Shop (Admin)';
      case UserRole.client:
      case UserRole.organisateur:
      default:
        return 'Voir le Shop';
    }
  }

  String get _getRealisationsButtonLabel {
    switch (_currentUserRole) {
      case UserRole.tatoueur:
        return 'Mes Réalisations';
      case UserRole.admin:
        return 'Réalisations (Admin)';
      case UserRole.client:
      case UserRole.organisateur:
      default:
        return 'Voir Réalisations';
    }
  }

  /// ✅ CONVERTIR UserRole EN UserMode POUR MonShopPage
  UserMode _getShopMode() {
    switch (_currentUserRole) {
      case UserRole.tatoueur:
        return UserMode.tatoueur; // Mode édition
      case UserRole.client:
      case UserRole.organisateur:
      case UserRole.admin:
      default:
        return UserMode.particulier; // Mode lecture seule
    }
  }

  Future<void> _pickProfileImage() async {
    if (!_canEdit) return;
    
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    final XFile? image = await openFile(acceptedTypeGroups: [typeGroup]);
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Photo de profil mise à jour !',
              style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500),
            ),
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
    
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    final XFile? image = await openFile(acceptedTypeGroups: [typeGroup]);
    
    if (image != null) {
      setState(() {
        _bannerImage = File(image.path);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Bannière mise à jour !',
              style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500),
            ),
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
            content: const Text(
              'Modifications sauvegardées !',
              style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500),
            ),
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
          // Navigation selon le rôle
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Bannière + avatar
              Stack(
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
                          // ✅ Indicateur de mode (démo/test/prod)
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
              ),
              const SizedBox(height: 90),

              // Profil du tatoueur
              Container(
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
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
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
                    
                    // Note (non éditable)
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

                    // Mes points forts
                    _buildPointsForts(),
                    
                    const SizedBox(height: 20),

                    // À propos
                    _buildAPropos(),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Boutons action - ✅ TOUJOURS VISIBLES POUR TOUS
              _buildActionButtons(),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // Bouton devis SEULEMENT pour les clients
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
                  MaterialPageRoute(builder: (_) => DemandeDevisPage()),
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

  // ✅ BOUTONS TOUJOURS VISIBLES AVEC PERMISSIONS CORRECTES
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _actionCard(
            label: _getShopButtonLabel,
            icon: Icons.store_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MonShopPage(
                mode: _getShopMode(), // ✅ Conversion UserRole → UserMode
              )),
            ),
          ),
          const SizedBox(width: 12),
          _actionCard(
            label: _getRealisationsButtonLabel,
            icon: Icons.photo_library_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MesRealisationsPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required String label, 
    required IconData icon,
    required VoidCallback onTap
  }) {
    return Expanded(
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: KipikTheme.rouge, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: KipikTheme.rouge,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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