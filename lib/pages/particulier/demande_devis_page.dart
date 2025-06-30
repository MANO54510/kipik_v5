// lib/pages/particulier/demande_devis_page.dart

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:kipik_v5/services/demande_devis/demande_devis_service.dart';
import 'package:kipik_v5/services/demande_devis/demande_devis_service.dart';
import 'package:kipik_v5/utils/screenshot_helper.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_particulier.dart';
import 'package:kipik_v5/widgets/common/buttons/tattoo_assistant_button.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class DemandeDevisPage extends StatefulWidget {
  /// Injection d'un service de demande de devis (stub par défaut).
  final DemandeDevisService devisService;

  DemandeDevisPage({
    Key? key,
    DemandeDevisService? devisService,
  })  : devisService = devisService ?? DemandeDevisService(),
        super(key: key);

  @override
  State<DemandeDevisPage> createState() => _DemandeDevisPageState();
}

class _DemandeDevisPageState extends State<DemandeDevisPage> {
  // Fond aléatoire
  late final String _backgroundImage;
  
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey _zonesKey = GlobalKey();
  List<String> _zonesSelectionnees = [];
  bool _isLoading = false;
  
  // Taille du tatouage sélectionnée
  String _tailleSelectionnee = "10x10 cm";
  // Liste des tailles standard disponibles
  final List<String> _tailles = [
    "5x5 cm", 
    "7x7 cm", 
    "10x10 cm", 
    "15x15 cm", 
    "15x20 cm", 
    "20x20 cm", 
    "20x30 cm",
    "30x30 cm",
    "Grande pièce (plus de 30 cm)"
  ];
  
  // Photos d'emplacement
  File? _photoEmplacement;
  
  // Fichiers de référence
  List<File> _fichiersReference = [];
  
  // Images générées par l'IA
  List<String> _imagesGenerees = [];
  
  @override
  void initState() {
    super.initState();
    // Sélectionner un fond aléatoire
    _backgroundImage = _getRandomBackground();
    // S'abonner aux événements d'images générées par l'IA
    IaGenerationService.instance.onImageGenerated.listen(_ajouterImageGeneree);
  }
  
  String _getRandomBackground() {
    const backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    return backgrounds[Random().nextInt(backgrounds.length)];
  }
  
  void _onZonesSelected(List<String> zones) {
    setState(() => _zonesSelectionnees = zones);
  }
  
  // Ajouter une image générée par l'IA
  void _ajouterImageGeneree(String imageUrl) {
    if (mounted) {
      setState(() {
        _imagesGenerees.add(imageUrl);
      });
      
      // Afficher une notification à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Image IA ajoutée à votre demande"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Choisir une photo d'emplacement avec file_selector
  Future<void> _choisirPhotoEmplacement() async {
    try {
      // Définir les types de fichiers image acceptés
      const XTypeGroup imagesGroup = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      
      // Ouvrir le sélecteur pour un seul fichier
      final XFile? file = await openFile(
        acceptedTypeGroups: [imagesGroup],
      );
      
      if (file != null) {
        setState(() {
          _photoEmplacement = File(file.path);
        });
      }
    } catch (e) {
      debugPrint("Erreur lors de la sélection de la photo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible de sélectionner cette photo"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Choisir des fichiers de référence avec file_selector
  Future<void> _choisirFichiersReference() async {
    try {
      // Définir les types de fichiers acceptés
      const XTypeGroup imagesGroup = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      
      // Vous pouvez ajouter d'autres types à l'avenir
      const XTypeGroup documentsGroup = XTypeGroup(
        label: 'Documents',
        extensions: ['pdf'],
      );
      
      // Ouvrir le sélecteur de fichiers multiples
      final List<XFile> files = await openFiles(
        acceptedTypeGroups: [imagesGroup, documentsGroup],
      );
      
      if (files.isNotEmpty) {
        final nouveauxFichiers = files.map((file) => File(file.path)).toList();
        
        setState(() {
          // Ne pas dépasser 5 fichiers au total
          if (_fichiersReference.length + nouveauxFichiers.length > 5) {
            final nbAjouter = 5 - _fichiersReference.length;
            if (nbAjouter > 0) {
              _fichiersReference.addAll(nouveauxFichiers.take(nbAjouter));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Maximum 5 fichiers de référence autorisés"),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            _fichiersReference.addAll(nouveauxFichiers);
          }
        });
      }
    } catch (e) {
      debugPrint("Erreur lors de la sélection des fichiers: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la sélection: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Supprimer un fichier de référence
  void _supprimerFichierReference(int index) {
    setState(() {
      _fichiersReference.removeAt(index);
    });
  }
  
  // Supprimer une image générée
  void _supprimerImageGeneree(int index) {
    setState(() {
      _imagesGenerees.removeAt(index);
    });
  }

  // Valider le formulaire avant envoi
  bool _validerFormulaire() {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Merci de décrire ton projet de tatouage"),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    
    if (_zonesSelectionnees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sélectionne au moins une zone corporelle"),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    
    return true;
  }

  Future<void> _envoyerDemande() async {
    if (!_validerFormulaire()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Capture de la zone sélectionnée
      final imagePath = await ScreenshotHelper.captureAvatar(
        context,
        _zonesKey,
      );
      String? imageUrl;

      if (imagePath != null) {
        imageUrl = await widget.devisService.uploadImage(
          File(imagePath),
          'devis_zones/${DateTime.now().millisecondsSinceEpoch}_zone.png',
        );
      }
      
      // Upload photo d'emplacement si elle existe
      String? photoEmplacementUrl;
      if (_photoEmplacement != null) {
        photoEmplacementUrl = await widget.devisService.uploadImage(
          _photoEmplacement!,
          'devis_emplacements/${DateTime.now().millisecondsSinceEpoch}_emplacement.jpg',
        );
      }
      
      // Upload des fichiers de référence
      List<String> fichiersReferenceUrls = [];
      for (var file in _fichiersReference) {
        // Déterminer l'extension du fichier
        String extension = 'jpg';
        if (file.path.toLowerCase().endsWith('.png')) {
          extension = 'png';
        } else if (file.path.toLowerCase().endsWith('.pdf')) {
          extension = 'pdf';
        } else if (file.path.toLowerCase().endsWith('.webp')) {
          extension = 'webp';
        }
        
        String? url = await widget.devisService.uploadImage(
           file,
           'devis_references/${DateTime.now().millisecondsSinceEpoch}_${fichiersReferenceUrls.length}.$extension',
        );
        if (url != null) {
          fichiersReferenceUrls.add(url);
        }
      }

      final demandeData = {
        'description': _descriptionController.text.trim(),
        'taille': _tailleSelectionnee,
        'zones': _zonesSelectionnees,
        'zoneImageUrl': imageUrl,
        'photoEmplacementUrl': photoEmplacementUrl,
        'fichiersReferenceUrls': fichiersReferenceUrls,
        'imagesGenerees': _imagesGenerees,
        'createdAt': DateTime.now(),
        'status': 'en_attente', // Statut initial
      };

      await widget.devisService.createDemandeDevis(demandeData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Demande envoyée au tatoueur !"),
          backgroundColor: Colors.green,
        ),
      );

      // Réinitialiser le formulaire
      _descriptionController.clear();
      setState(() {
        _zonesSelectionnees = [];
        _tailleSelectionnee = "10x10 cm";
        _photoEmplacement = null;
        _fichiersReference = [];
        _imagesGenerees = [];
      });
      
      // Retourner à l'écran précédent après succès
      Future.delayed(const Duration(seconds: 1), () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      
    } catch (e) {
      debugPrint("Erreur en envoyant la demande : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Échec de l'envoi, réessaye plus tard."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: const CustomDrawerParticulier(),
      appBar: const CustomAppBarKipik(
        title: 'Demande de Devis',
        showBackButton: true,
        showBurger: true,
        showNotificationIcon: true,
      ),
      floatingActionButton: const TattooAssistantButton(
        allowImageGeneration: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond aléatoire
          Image.asset(_backgroundImage, fit: BoxFit.cover),
          
          // Overlay pour assombrir légèrement le fond
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  _buildSectionDescription(),
                  const SizedBox(height: 24),
                  _buildSectionTaille(),
                  const SizedBox(height: 24),
                  _buildSectionPhotoEmplacement(),
                  const SizedBox(height: 24),
                  _buildSectionImagesReference(),
                  _buildSectionImagesGenerees(),
                  const SizedBox(height: 24),
                  _buildSectionZonesCorps(),
                  const SizedBox(height: 24),
                  _buildBoutonEnvoyer(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Section avec titre et fond amélioré
  Widget _buildSectionWithTitle({
    required String title,
    required Widget content,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête de section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu de la section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: content,
          ),
        ],
      ),
    );
  }
  
  // Sections de la page
  Widget _buildSectionDescription() {
    return _buildSectionWithTitle(
      title: 'DÉCRIS TON PROJET',
      icon: Icons.description,
      content: _buildTextField(
        controller: _descriptionController,
        hint: 'Ton idée de tatouage... Sois précis sur ton style souhaité',
        maxLines: 5,
      ),
    );
  }
  
  Widget _buildSectionTaille() {
    return _buildSectionWithTitle(
      title: 'TAILLE DU TATOUAGE',
      icon: Icons.straighten,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: _tailleSelectionnee,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _tailleSelectionnee = newValue;
              });
            }
          },
          items: _tailles.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          underline: Container(), // Supprime la ligne par défaut
        ),
      ),
    );
  }
  
  Widget _buildSectionPhotoEmplacement() {
    return _buildSectionWithTitle(
      title: 'PHOTO DE L\'EMPLACEMENT',
      icon: Icons.add_a_photo,
      content: GestureDetector(
        onTap: _choisirPhotoEmplacement,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: _photoEmplacement != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _photoEmplacement!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo, color: Colors.white, size: 50),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: KipikTheme.rouge.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ajouter une photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
  
  // Section des images de référence avec bouton centré
  Widget _buildSectionImagesReference() {
    return _buildSectionWithTitle(
      title: 'IMAGES DE RÉFÉRENCE',
      icon: Icons.image,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Centrer horizontalement
        children: [
          // Texte informatif et bouton centré
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ajoute jusqu\'à 5 images de référence',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _choisirFichiersReference,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Affichage des fichiers de référence
          if (_fichiersReference.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Aucune image de référence',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _fichiersReference.length,
                itemBuilder: (context, index) {
                  final file = _fichiersReference[index];
                  final String path = file.path.toLowerCase();
                  final bool isPdf = path.endsWith('.pdf');
                  final bool isImage = path.endsWith('.jpg') || 
                                      path.endsWith('.jpeg') || 
                                      path.endsWith('.png') || 
                                      path.endsWith('.webp');
                  
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: !isImage ? Colors.grey[800] : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: isPdf 
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.picture_as_pdf, color: Colors.white, size: 40),
                                    SizedBox(height: 4),
                                    Text('PDF', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              )
                            : isImage
                                ? Image.file(
                                    file,
                                    fit: BoxFit.cover,
                                    height: 120,
                                    width: 100,
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.insert_drive_file, color: Colors.white, size: 40),
                                        SizedBox(height: 4),
                                        Text('Fichier', style: TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _supprimerFichierReference(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
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
      ),
    );
  }
  
  Widget _buildSectionImagesGenerees() {
    if (_imagesGenerees.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: _buildSectionWithTitle(
        title: 'IMAGES GÉNÉRÉES PAR L\'IA',
        icon: Icons.auto_awesome,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imagesGenerees.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imagesGenerees[index],
                            fit: BoxFit.cover,
                            height: 120,
                            width: 100,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 120,
                                width: 100,
                                color: Colors.black45,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 120,
                                width: 100,
                                color: Colors.black45,
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: Colors.white54),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _supprimerImageGeneree(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
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
        ),
      ),
    );
  }
  
  // Version modifiée pour la nouvelle approche de sélection des zones
  Widget _buildSectionZonesCorps() {
    return _buildSectionWithTitle(
      title: 'ZONES À TATOUER',
      icon: Icons.person_outline,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionne les zones où tu veux être tatoué(e)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // Nouveau widget de sélection des zones 
          RepaintBoundary(
            key: _zonesKey,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              height: 500, // Hauteur augmentée pour notre silhouette
              child: ZoneSelectionWidget(
                onZonesSelected: _onZonesSelected,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          // Récapitulatif des zones sélectionnées
          if (_zonesSelectionnees.isNotEmpty) ...[
            const Text(
              "Zones sélectionnées :",
              style: TextStyle(
                color: Colors.white, 
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Utiliser une méthode simplifiée pour afficher les zones
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _buildZoneChips(),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Méthode séparée pour construire les chips des zones
  List<Widget> _buildZoneChips() {
    List<Widget> chips = [];
    
    for (String zone in _zonesSelectionnees) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              zone,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }
    
    return chips;
  }
  
  Widget _buildBoutonEnvoyer() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _envoyerDemande,
      style: ElevatedButton.styleFrom(
        backgroundColor: KipikTheme.rouge,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.5),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'ENVOYER MA DEMANDE',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'PermanentMarker',
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
    );
  }

  // Version simplifiée du TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54, fontSize: 15),
          contentPadding: const EdgeInsets.all(12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// Service pour la communication entre l'assistant et la page
class IaGenerationService {
  static final IaGenerationService _instance = IaGenerationService._internal();
  static IaGenerationService get instance => _instance;
  
  final StreamController<String> _imageController = StreamController<String>.broadcast();
  Stream<String> get onImageGenerated => _imageController.stream;
  
  IaGenerationService._internal();
  
  void ajouterImage(String imageUrl) {
    _imageController.add(imageUrl);
  }
  
  void dispose() {
    _imageController.close();
  }
}

// Nouveau widget de sélection de zones corporelles simplifié
class ZoneSelectionWidget extends StatefulWidget {
  final Function(List<String>) onZonesSelected;

  const ZoneSelectionWidget({
    Key? key,
    required this.onZonesSelected,
  }) : super(key: key);

  @override
  State<ZoneSelectionWidget> createState() => _ZoneSelectionWidgetState();
}

class _ZoneSelectionWidgetState extends State<ZoneSelectionWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _selectedZones = [];
  
  // Définition simplifiée des zones
  final List<Map<String, dynamic>> _frontZones = [
    {'name': 'Tête', 'row': 0, 'col': 1},
    {'name': 'Cou', 'row': 1, 'col': 1},
    {'name': 'Épaule gauche', 'row': 2, 'col': 0},
    {'name': 'Poitrine', 'row': 2, 'col': 1},
    {'name': 'Épaule droite', 'row': 2, 'col': 2},
    {'name': 'Bras gauche', 'row': 3, 'col': 0},
    {'name': 'Abdomen', 'row': 3, 'col': 1},
    {'name': 'Bras droit', 'row': 3, 'col': 2},
    {'name': 'Avant-bras gauche', 'row': 4, 'col': 0},
    {'name': 'Bassin', 'row': 4, 'col': 1},
    {'name': 'Avant-bras droit', 'row': 4, 'col': 2},
    {'name': 'Main gauche', 'row': 5, 'col': 0},
    {'name': 'Main droite', 'row': 5, 'col': 2},
    {'name': 'Cuisse gauche', 'row': 6, 'col': 0},
    {'name': 'Cuisse droite', 'row': 6, 'col': 2},
    {'name': 'Genou gauche', 'row': 7, 'col': 0},
    {'name': 'Genou droit', 'row': 7, 'col': 2},
    {'name': 'Tibia gauche', 'row': 8, 'col': 0},
    {'name': 'Tibia droit', 'row': 8, 'col': 2},
    {'name': 'Pied gauche', 'row': 9, 'col': 0},
    {'name': 'Pied droit', 'row': 9, 'col': 2},
  ];

  final List<Map<String, dynamic>> _backZones = [
    {'name': 'Crâne', 'row': 0, 'col': 1},
    {'name': 'Nuque', 'row': 1, 'col': 1},
    {'name': 'Épaule gauche', 'row': 2, 'col': 0},
    {'name': 'Haut du dos', 'row': 2, 'col': 1},
    {'name': 'Épaule droite', 'row': 2, 'col': 2},
    {'name': 'Omoplate gauche', 'row': 3, 'col': 0},
    {'name': 'Milieu du dos', 'row': 3, 'col': 1},
    {'name': 'Omoplate droite', 'row': 3, 'col': 2},
    {'name': 'Bas du dos', 'row': 4, 'col': 1},
    {'name': 'Fesse gauche', 'row': 5, 'col': 0},
    {'name': 'Fesse droite', 'row': 5, 'col': 2},
    {'name': 'Cuisse gauche', 'row': 6, 'col': 0},
    {'name': 'Cuisse droite', 'row': 6, 'col': 2},
    {'name': 'Mollet gauche', 'row': 8, 'col': 0},
    {'name': 'Mollet droit', 'row': 8, 'col': 2},
    {'name': 'Talon gauche', 'row': 9, 'col': 0},
    {'name': 'Talon droit', 'row': 9, 'col': 2},
  ];

  // Map pour suivre les zones sélectionnées
  final Map<String, bool> _selectedZonesMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialiser toutes les zones comme non sélectionnées
    for (var zone in _frontZones) {
      _selectedZonesMap[zone['name']] = false;
    }
    for (var zone in _backZones) {
      _selectedZonesMap[zone['name']] = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleZone(String zoneName) {
    setState(() {
      _selectedZonesMap[zoneName] = !(_selectedZonesMap[zoneName] ?? false);
      
      // Mettre à jour la liste des zones sélectionnées
      _selectedZones.clear();
      _selectedZonesMap.forEach((key, value) {
        if (value) {
          _selectedZones.add(key);
        }
      });
      
      // Notifier le parent
      widget.onZonesSelected(_selectedZones);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs pour face avant/arrière
        Container(
          decoration: BoxDecoration(
            color: KipikTheme.rouge.withOpacity(0.7),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'FACE AVANT'),
              Tab(text: 'FACE ARRIÈRE'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        
        // Contenu des tabs
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                // Vue avant
                _buildBodyGrid(true),
                // Vue arrière
                _buildBodyGrid(false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyGrid(bool isFrontView) {
    final zones = isFrontView ? _frontZones : _backZones;
    
    // Déterminer le nombre de lignes et colonnes nécessaires
    int maxRow = 0;
    int maxCol = 0;
    for (var zone in zones) {
      if (zone['row'] > maxRow) maxRow = zone['row'];
      if (zone['col'] > maxCol) maxCol = zone['col'];
    }
    
    return SingleChildScrollView(
      child: Column(
        children: List.generate(maxRow + 1, (rowIndex) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxCol + 1, (colIndex) {
              // Trouver la zone à cette position (s'il y en a une)
              final zoneAtPosition = zones.where((zone) => 
                zone['row'] == rowIndex && zone['col'] == colIndex
              ).toList();
              
              if (zoneAtPosition.isEmpty) {
                // Pas de zone à cette position
                return Expanded(
                  flex: 1,
                  child: Container(
                    height: 50, // hauteur fixe pour chaque cellule
                    margin: const EdgeInsets.all(2),
                  ),
                );
              } else {
                // Il y a une zone à cette position
                final zone = zoneAtPosition.first;
                final isSelected = _selectedZonesMap[zone['name']] ?? false;
                
                return Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => _toggleZone(zone['name']),
                    child: Container(
                      height: 50, // hauteur fixe pour chaque cellule
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? KipikTheme.rouge.withOpacity(0.8) 
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white38,
                          width: 1,
                        ),
                      ),
                      // Indicateur visuel uniquement sur sélection
                      child: isSelected 
                        ? const Center(
                            child: Icon(Icons.check, color: Colors.white, size: 20),
                          ) 
                        : null,
                    ),
                  ),
                );
              }
            }),
          );
        }),
      ),
    );
  }
}
