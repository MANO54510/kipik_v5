// lib/pages/pro/flashs/publier_flash_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/kipik_theme.dart';
import '../../../services/flash/flash_service.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../../models/flash/flash.dart';
import '../../../widgets/common/app_bars/custom_app_bar_particulier.dart';

class PublierFlashPage extends StatefulWidget {
  const PublierFlashPage({Key? key}) : super(key: key);

  @override
  State<PublierFlashPage> createState() => _PublierFlashPageState();
}

class _PublierFlashPageState extends State<PublierFlashPage> {
  final _formKey = GlobalKey<FormState>();
  final FlashService _flashService = FlashService.instance;
  
  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _sizeController = TextEditingController();
  final _sizeDescriptionController = TextEditingController();
  final _priceNoteController = TextEditingController();
  
  // Form data
  String _selectedStyle = 'Réalisme';
  List<String> _selectedBodyPlacements = [];
  List<String> _selectedColors = [];
  List<String> _tags = [];
  String _imageUrl = '';
  List<String> _additionalImages = [];
  List<DateTime> _availableTimeSlots = [];
  FlashType _flashType = FlashType.standard;
  
  // UI State
  bool _isPublishing = false;
  bool _isImageUploading = false;
  
  // Options
  final List<String> _styles = [
    'Réalisme', 'Japonais', 'Géométrique', 'Minimaliste', 'Traditionnel', 
    'Old School', 'Biomécanique', 'Aquarelle', 'Lettering', 'Tribal'
  ];
  
  final List<String> _bodyPlacements = [
    'Poignet', 'Avant-bras', 'Bras', 'Épaule', 'Dos', 'Poitrine', 
    'Cuisse', 'Jambe', 'Cheville', 'Nuque', 'Ventre', 'Côtes'
  ];
  
  final List<String> _colors = [
    'Noir', 'Couleur', 'Noir et Gris', 'Rouge', 'Bleu', 'Vert', 
    'Violet', 'Orange', 'Jaune', 'Rose'
  ];

  @override
  void initState() {
    super.initState();
    _generateDemoTimeSlots();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _sizeDescriptionController.dispose();
    _priceNoteController.dispose();
    super.dispose();
  }

  void _generateDemoTimeSlots() {
    final now = DateTime.now();
    _availableTimeSlots = [
      now.add(const Duration(days: 3)),
      now.add(const Duration(days: 7)),
      now.add(const Duration(days: 10)),
      now.add(const Duration(days: 14)),
    ];
  }

  Future<void> _selectImage() async {
    setState(() {
      _isImageUploading = true;
    });
    
    // Simuler upload d'image
    await Future.delayed(const Duration(seconds: 2));
    
    // Image de démonstration aléatoire
    final imageId = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _imageUrl = 'https://picsum.photos/seed/flash_$imageId/400/600';
      _isImageUploading = false;
    });
    
    _showSuccessSnackBar('Image ajoutée avec succès !');
  }

  Future<void> _addAdditionalImage() async {
    setState(() {
      _isImageUploading = true;
    });
    
    await Future.delayed(const Duration(seconds: 1));
    
    final imageId = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _additionalImages.add('https://picsum.photos/seed/extra_$imageId/400/600');
      _isImageUploading = false;
    });
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _publishFlash() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageUrl.isEmpty) {
      _showErrorSnackBar('Veuillez ajouter une image principale');
      return;
    }
    
    if (_selectedBodyPlacements.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner au moins un emplacement');
      return;
    }
    
    if (_selectedColors.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner au moins une couleur');
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final flash = Flash(
        id: '', // Sera généré par le service
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrl,
        additionalImages: _additionalImages,
        tattooArtistId: currentUser.uid,
        tattooArtistName: currentUser.name ?? 'Tatoueur',
        studioName: 'Mon Studio', // TODO: Récupérer depuis profil
        style: _selectedStyle,
        size: _sizeController.text.trim(),
        sizeDescription: _sizeDescriptionController.text.trim(),
        price: double.parse(_priceController.text),
        priceNote: _priceNoteController.text.trim(),
        bodyPlacements: _selectedBodyPlacements,
        colors: _selectedColors,
        tags: _tags,
        availableTimeSlots: _availableTimeSlots,
        flashType: _flashType,
        status: FlashStatus.published,
        latitude: 48.8566, // TODO: Géolocalisation réelle
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _flashService.createFlash(flash);
      
      _showSuccessSnackBar('Flash publié avec succès !');
      
      // Retourner à la page précédente après un délai
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la publication : $e');
    } finally {
      setState(() {
        _isPublishing = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: 'Publier un Flash',
        showBackButton: true,
      ),
      body: Stack(
        children: [
          // Background
          Image.asset(
            'assets/background_charbon.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          
          // Content
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec info
                    _buildHeader(),
                    
                    const SizedBox(height: 24),
                    
                    // Image principale
                    _buildImageSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Informations de base
                    _buildBasicInfoSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Style et emplacements
                    _buildStyleAndPlacementSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Prix et taille
                    _buildPriceAndSizeSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Tags
                    _buildTagsSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Type de flash
                    _buildFlashTypeSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Bouton publier
                    _buildPublishButton(),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.flash_on,
            color: KipikTheme.rouge,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau Flash',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: KipikTheme.rouge,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Partagez votre création avec la communauté',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, color: KipikTheme.rouge),
              const SizedBox(width: 8),
              const Text(
                'Image principale *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Image principale
          GestureDetector(
            onTap: _isImageUploading ? null : _selectImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _isImageUploading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _imageUrl.isNotEmpty
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageUrl = ''),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ajouter une image',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Images supplémentaires
          Row(
            children: [
              Text(
                'Images supplémentaires (${_additionalImages.length}/3)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (_additionalImages.length < 3)
                TextButton.icon(
                  onPressed: _isImageUploading ? null : _addAdditionalImage,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
            ],
          ),
          
          if (_additionalImages.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _additionalImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _additionalImages[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => _additionalImages.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: KipikTheme.rouge),
              const SizedBox(width: 8),
              const Text(
                'Informations de base',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Titre
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre du flash *',
              hintText: 'Ex: Rose minimaliste',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le titre est obligatoire';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Décrivez votre flash...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La description est obligatoire';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStyleAndPlacementSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style, color: KipikTheme.rouge),
              const SizedBox(width: 8),
              const Text(
                'Style et emplacements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Style
          DropdownButtonFormField<String>(
            value: _selectedStyle,
            decoration: const InputDecoration(
              labelText: 'Style *',
              border: OutlineInputBorder(),
            ),
            items: _styles.map((style) {
              return DropdownMenuItem(
                value: style,
                child: Text(style),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStyle = value!;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Emplacements
          const Text(
            'Emplacements recommandés *',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bodyPlacements.map((placement) {
              final isSelected = _selectedBodyPlacements.contains(placement);
              return FilterChip(
                label: Text(placement),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedBodyPlacements.add(placement);
                    } else {
                      _selectedBodyPlacements.remove(placement);
                    }
                  });
                },
                selectedColor: KipikTheme.rouge.withOpacity(0.3),
                checkmarkColor: KipikTheme.rouge,
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Couleurs
          const Text(
            'Couleurs *',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((color) {
              final isSelected = _selectedColors.contains(color);
              return FilterChip(
                label: Text(color),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedColors.add(color);
                    } else {
                      _selectedColors.remove(color);
                    }
                  });
                },
                selectedColor: KipikTheme.rouge.withOpacity(0.3),
                checkmarkColor: KipikTheme.rouge,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndSizeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.euro, color: KipikTheme.rouge),
              const SizedBox(width: 8),
              const Text(
                'Prix et dimensions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Prix
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Prix (€) *',
                    hintText: '150',
                    border: OutlineInputBorder(),
                    suffixText: '€',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Prix obligatoire';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Prix invalide';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Taille
              Expanded(
                child: TextFormField(
                  controller: _sizeController,
                  decoration: const InputDecoration(
                    labelText: 'Taille *',
                    hintText: '8x6cm',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Taille obligatoire';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description taille
          TextFormField(
            controller: _sizeDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Description de la taille',
              hintText: 'Parfait pour poignet ou cheville',
              border: OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Note prix
          TextFormField(
            controller: _priceNoteController,
            decoration: const InputDecoration(
              labelText: 'Note sur le prix',
              hintText: 'Prix final selon adaptation',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tag, color: KipikTheme.rouge),
              const SizedBox(width: 8),
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Input tag
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Ajouter un tag...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    _addTag(value.trim());
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tags sélectionnés
          if (_tags.isNotEmpty) ...[
            const Text(
              'Tags ajoutés:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text('#$tag'),
                  onDeleted: () => _removeTag(tag),
                  deleteIconColor: KipikTheme.rouge,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlashTypeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: KipikTheme.rouge),
              const SizedBox(width: 8),
              const Text(
                'Type de flash',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ...FlashType.values.map((type) {
            return RadioListTile<FlashType>(
              title: Text(type.displayName),
              subtitle: Text(type.description),
              value: type,
              groupValue: _flashType,
              onChanged: (value) {
                setState(() {
                  _flashType = value!;
                });
              },
              activeColor: KipikTheme.rouge,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPublishing ? null : _publishFlash,
        style: ElevatedButton.styleFrom(
          backgroundColor: KipikTheme.rouge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isPublishing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Publication en cours...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : const Text(
                'Publier le Flash',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}