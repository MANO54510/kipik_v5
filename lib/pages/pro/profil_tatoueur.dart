// lib/pages/pro/profil_tatoueur.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:kipik_v5/pages/particulier/demande_devis_page.dart';
import 'package:kipik_v5/pages/pro/mes_realisations_page.dart';
import 'package:kipik_v5/pages/pro/mon_shop_page.dart';
import 'package:kipik_v5/pages/pro/home_page_pro.dart'; // 🚨 IMPORT MANQUANT
import '../../theme/kipik_theme.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/models/user.dart';

enum UserMode { 
  particulier, // Mode lecture seule pour les particuliers
  tatoueur     // Mode édition pour les tatoueurs
}

class ProfilTatoueur extends StatefulWidget {
  // Paramètres du tatoueur
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
  
  // Nouveau paramètre pour définir le mode
  final UserMode mode;
  
  // ID du tatoueur pour savoir si c'est son propre profil
  final String? tatoueurId;

  const ProfilTatoueur({
    Key? key,
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
    this.mode = UserMode.particulier, // Par défaut en mode lecture
    this.tatoueurId,
  }) : super(key: key);

  @override
  State<ProfilTatoueur> createState() => _ProfilTatoueurState();
}

class _ProfilTatoueurState extends State<ProfilTatoueur> {
  bool _isFav = false;
  bool _isEditMode = false;
  File? _profileImage;
  File? _bannerImage;
  
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
    _initializeControllers();
    _generateBio();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.name);
    _studioController = TextEditingController(text: widget.studio);
    _styleController = TextEditingController(text: widget.style);
    _addressController = TextEditingController(text: widget.address);
    _instagramController = TextEditingController(text: widget.instagram);
    _availabilityController = TextEditingController(text: widget.availability);
    _locationController = TextEditingController(text: widget.location);
  }

  void _generateBio() {
    bio = 'Tatoueur passionné par le ${widget.style}.\n'
        '10 ans d\'expérience à ${widget.location}.\n'
        'Travaillant au studio "${widget.studio}".\n'
        'Mes créations sont reconnues pour leur finesse et leur précision.';
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

  bool get _canEdit => widget.mode == UserMode.tatoueur;
  bool get _showDevisButton => widget.mode == UserMode.particulier; // PARTICULIER = bouton devis

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

  void _saveChanges() {
    if (!_canEdit) return;
    
    // TODO: Sauvegarder les modifications sur le serveur
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      endDrawer: DrawerFactory.of(context),
      appBar: CustomAppBarKipik(
        title: _canEdit ? 'Mon Profil' : 'Profil Tatoueur',
        showBackButton: true,
        useProStyle: true,
        onBackPressed: () {
          // Toujours retourner vers HomePage Pro
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePagePro()),
            (route) => false,
          );
        },
        actions: [
          if (_showDevisButton) ...[
            // Bouton favori SEULEMENT pour les particuliers
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
            // Boutons d'édition SEULEMENT pour les tatoueurs
            IconButton(
              icon: Icon(
                _isEditMode ? Icons.save : Icons.edit,
                color: Colors.white,
                size: 24,
              ),
              onPressed: _isEditMode ? _saveChanges : _toggleEditMode,
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
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
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
                              i < widget.note.floor() ? Icons.star : 
                              (i == widget.note.floor() && widget.note % 1 > 0) ? Icons.star_half : Icons.star_outline,
                              color: Colors.amber,
                              size: 20,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.note}',
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontFamily: 'PermanentMarker',
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
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
              
              // Boutons action
              _buildActionButtons(),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // Bouton devis SEULEMENT pour les particuliers (pas pour les tatoueurs)
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
          const FeatureRow(
            icon: Icons.schedule,
            label: '10 ans d\'expérience',
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _actionCard(
            label: _canEdit ? 'Mon Shop' : 'Son Shop',
            icon: Icons.store_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MonShopPage()),
            ),
          ),
          const SizedBox(width: 12),
          _actionCard(
            label: _canEdit ? 'Mes Réalisations' : 'Ses Réalisations',
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