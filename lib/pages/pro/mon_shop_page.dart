import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/pages/pro/home_page_pro.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/widgets/common/buttons/tattoo_assistant_button.dart';
import '../../theme/kipik_theme.dart';

enum UserMode { 
  particulier, // Mode lecture seule pour les particuliers
  tatoueur     // Mode édition pour les tatoueurs
}

class MonShopPage extends StatefulWidget {
  final UserMode mode;
  
  const MonShopPage({
    Key? key,
    this.mode = UserMode.tatoueur, // Par défaut tatoueur car c'est "MonShop"
  }) : super(key: key);

  @override
  State<MonShopPage> createState() => _MonShopPageState();
}

class _MonShopPageState extends State<MonShopPage> {
  bool _isEditMode = false;
  
  // Contrôleurs pour les champs éditables
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _peopleCountController;
  
  // Contrôleurs pour les horaires
  late Map<String, TextEditingController> _hoursControllers;
  
  // Images de la galerie (gestion locale)
  List<File?> _galleryFiles = List.filled(8, null);
  File? _logoFile;
  
  // Données du shop
  late Map<String, dynamic> shopData;

  @override
  void initState() {
    super.initState();
    _initializeShopData();
    _initializeControllers();
  }

  void _initializeShopData() {
    shopData = {
      'name': 'Ink Legends Studio',
      'address': '25 rue du Tatouage, 75000 Paris',
      'phone': '06 12 34 56 78',
      'email': 'contact@inklegends.com',
      'logo': 'assets/pro/shop_profil_gen.jpg',
      'isPublic': true,
      'peopleCount': 4,
      'openingHours': {
        'Lun-Ven': '10:00 - 19:00',
        'Sam': '11:00 - 17:00',
        'Dim': 'Fermé'
      },
      'galleryImages': [
        'assets/pro/shop_gen.jpg',
        'assets/pro/shop_profil_gen.jpg',
        null, null, null, null, null, null,
      ]
    };
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: shopData['name']);
    _addressController = TextEditingController(text: shopData['address']);
    _phoneController = TextEditingController(text: shopData['phone']);
    _emailController = TextEditingController(text: shopData['email']);
    _peopleCountController = TextEditingController(text: shopData['peopleCount'].toString());
    
    _hoursControllers = {};
    (shopData['openingHours'] as Map<String, String>).forEach((day, hours) {
      _hoursControllers[day] = TextEditingController(text: hours);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _peopleCountController.dispose();
    _hoursControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  bool get _canEdit => widget.mode == UserMode.tatoueur;
  
  int _currentPhotoIndex = 0;

  List<String> get _validGalleryImages {
    List<String> validImages = [];
    
    // Ajouter les fichiers locaux d'abord
    for (int i = 0; i < _galleryFiles.length; i++) {
      if (_galleryFiles[i] != null) {
        validImages.add(_galleryFiles[i]!.path);
      }
    }
    
    // Puis ajouter les assets qui ne sont pas remplacés
    List<String?> originalImages = List<String?>.from(shopData['galleryImages']);
    for (int i = 0; i < originalImages.length; i++) {
      if (originalImages[i] != null && _galleryFiles.length > i && _galleryFiles[i] == null) {
        validImages.add(originalImages[i]!);
      }
    }
    
    return validImages;
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
      shopData['name'] = _nameController.text;
      shopData['address'] = _addressController.text;
      shopData['phone'] = _phoneController.text;
      shopData['email'] = _emailController.text;
      shopData['peopleCount'] = int.tryParse(_peopleCountController.text) ?? 4;
      
      _hoursControllers.forEach((day, controller) {
        (shopData['openingHours'] as Map<String, String>)[day] = controller.text;
      });
      
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

  Future<void> _pickGalleryImage(int index) async {
    if (!_canEdit) return;
    
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    final XFile? image = await openFile(acceptedTypeGroups: [typeGroup]);
    
    if (image != null) {
      setState(() {
        if (_galleryFiles.length <= index) {
          _galleryFiles = List.filled(index + 1, null);
        }
        _galleryFiles[index] = File(image.path);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image ajoutée à la galerie !'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _pickLogoImage() async {
    if (!_canEdit) return;
    
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    final XFile? image = await openFile(acceptedTypeGroups: [typeGroup]);
    
    if (image != null) {
      setState(() {
        _logoFile = File(image.path);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logo mis à jour !'),
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
    final validImages = _validGalleryImages;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      endDrawer: DrawerFactory.of(context),
      appBar: CustomAppBarKipik(
        title: _canEdit ? 'Mon Shop' : shopData['name'] as String,
        showBackButton: true,
        useProStyle: true,
        onBackPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePagePro()),
            (route) => false,
          );
        },
        actions: [
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              // Photo principale avec galerie
              if (validImages.isNotEmpty) ...[
                _buildGallerySection(validImages),
              ] else if (_canEdit && _isEditMode) ...[
                _buildEmptyGallery(),
              ],

              // Informations du shop
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section logo et nom
                    _buildHeaderSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Section Horaires
                    _buildHoursSection(),

                    const SizedBox(height: 16),
                    
                    // Section Adresse
                    _buildAddressSection(),

                    const SizedBox(height: 16),
                    
                    // Section Contact
                    _buildContactSection(),

                    const SizedBox(height: 24),
                    
                    // Boutons d'action (seulement pour les particuliers)
                    if (widget.mode == UserMode.particulier)
                      _buildActionButtons(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGallerySection(List<String> validImages) {
    return Stack(
      children: [
        // Image actuelle
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: PageView.builder(
                itemCount: validImages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPhotoIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final imagePath = validImages[index];
                  return GestureDetector(
                    onTap: _canEdit && _isEditMode ? () => _pickGalleryImage(index) : null,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imagePath.startsWith('assets/')
                            ? Image.asset(imagePath, fit: BoxFit.cover)
                            : Image.file(File(imagePath), fit: BoxFit.cover),
                        if (_canEdit && _isEditMode)
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
                  );
                },
              ),
            ),
          ),
        ),
        
        // Indicateur de nombre de photos
        if (validImages.length > 1)
          Positioned(
            top: 16,
            right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentPhotoIndex + 1}/${validImages.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        // Statut du shop
        Positioned(
          top: 16,
          left: 32,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  (shopData['isPublic'] as bool) ? Icons.public : Icons.lock,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  (shopData['isPublic'] as bool) ? 'Shop Public' : 'Shop Privé',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyGallery() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _pickGalleryImage(0),
        borderRadius: BorderRadius.circular(20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, color: Colors.white, size: 50),
            SizedBox(height: 12),
            Text(
              'Ajouter des photos de votre shop',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          // Logo
          GestureDetector(
            onTap: _canEdit && _isEditMode ? _pickLogoImage : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: _logoFile != null
                      ? FileImage(_logoFile!)
                      : AssetImage(shopData['logo'] as String) as ImageProvider,
                ),
                if (_canEdit && _isEditMode)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: KipikTheme.rouge,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditableField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'PermanentMarker',
                    color: Color(0xFF111827),
                  ),
                  hintText: 'Nom du shop',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: Color(0xFF6B7280),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildEditableField(
                        controller: _peopleCountController,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        hintText: '4',
                        suffix: ' tatoueurs présents',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursSection() {
    return _buildInfoContainer(
      title: 'Horaires d\'ouverture',
      icon: Icons.access_time,
      child: Column(
        children: _hoursControllers.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: _buildEditableField(
                    controller: entry.value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.bold,
                    ),
                    hintText: 'Horaires',
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddressSection() {
    return _buildInfoContainer(
      title: 'Adresse',
      icon: Icons.location_on,
      child: Row(
        children: [
          Expanded(
            child: _buildEditableField(
              controller: _addressController,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF111827),
              ),
              hintText: 'Adresse du shop',
              maxLines: 2,
            ),
          ),
          if (widget.mode == UserMode.particulier)
            IconButton(
              icon: const Icon(
                Icons.map,
                color: Color(0xFF6B7280),
              ),
              onPressed: () {
                // Ouvrir dans Maps
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildInfoContainer(
      title: 'Contact',
      icon: Icons.contact_phone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Téléphone
          Row(
            children: [
              const Icon(Icons.phone, color: Color(0xFF6B7280), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEditableField(
                  controller: _phoneController,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                  hintText: 'Numéro de téléphone',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Email
          Row(
            children: [
              const Icon(Icons.email, color: Color(0xFF6B7280), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEditableField(
                  controller: _emailController,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                  hintText: 'Adresse email',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
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
                onTap: () {
                  // Appeler le shop
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Appeler',
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
        const SizedBox(width: 12),
        Expanded(
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
                onTap: () {
                  // Partager le shop
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share, color: KipikTheme.rouge, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Partager',
                      style: TextStyle(
                        color: KipikTheme.rouge,
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
      ],
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required TextStyle style,
    required String hintText,
    int maxLines = 1,
    TextAlign textAlign = TextAlign.start,
    String suffix = '',
  }) {
    if (!_canEdit || !_isEditMode) {
      return Text(
        controller.text.isEmpty ? hintText : '${controller.text}$suffix',
        style: controller.text.isEmpty ? style.copyWith(color: Colors.grey) : style,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
      );
    }

    return TextField(
      controller: controller,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: style.copyWith(color: Colors.grey),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: KipikTheme.rouge.withOpacity(0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: KipikTheme.rouge),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }

  Widget _buildInfoContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
                child: Icon(icon, color: KipikTheme.rouge, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}