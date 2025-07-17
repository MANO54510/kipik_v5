// lib/pages/particulier/demande_devis_page.dart

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:kipik_v5/services/demande_devis/firebase_demande_devis_service.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/utils/screenshot_helper.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_particulier.dart';
import 'package:kipik_v5/widgets/common/buttons/tattoo_assistant_button.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class DemandeDevisPage extends StatefulWidget {
  // ✅ PARAMÈTRES CORRIGÉS - noms cohérents avec le profil tatoueur
  final Map<String, dynamic>? prefilledFlash;
  final String? tatoueurId; // ✅ Changé de targetTattooerId à tatoueurId
  final String? tatoueurName; // ✅ Ajouté pour affichage
  
  const DemandeDevisPage({
    Key? key,
    this.prefilledFlash,
    this.tatoueurId,
    this.tatoueurName,
  }) : super(key: key);

  @override
  State<DemandeDevisPage> createState() => _DemandeDevisPageState();
}

class _DemandeDevisPageState extends State<DemandeDevisPage> {
  FirebaseDemandeDevisService get _devisService => FirebaseDemandeDevisService.instance;
  SecureAuthService get _authService => SecureAuthService.instance;

  late final String _backgroundImage;
  
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey _zonesKey = GlobalKey();
  List<String> _zonesSelectionnees = [];
  bool _isLoading = false;
  
  // ✅ Données utilisateur préremplies
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;
  
  String _tailleSelectionnee = "10x10 cm";
  
  final List<Map<String, dynamic>> _tailles = [
    {'value': "5x5 cm", 'category': 'Petit', 'price': '€', 'range': '80-150€'},
    {'value': "7x7 cm", 'category': 'Petit', 'price': '€', 'range': '100-200€'},
    {'value': "10x10 cm", 'category': 'Moyen', 'price': '€€', 'range': '150-300€'},
    {'value': "15x15 cm", 'category': 'Moyen', 'price': '€€', 'range': '250-450€'},
    {'value': "15x20 cm", 'category': 'Grand', 'price': '€€€', 'range': '350-600€'},
    {'value': "20x20 cm", 'category': 'Grand', 'price': '€€€', 'range': '450-750€'},
    {'value': "20x30 cm", 'category': 'Très grand', 'price': '€€€€', 'range': '600-1000€'},
    {'value': "30x30 cm", 'category': 'Très grand', 'price': '€€€€', 'range': '800-1500€'},
    {'value': "Grande pièce (plus de 30 cm)", 'category': 'Extra large', 'price': '€€€€€', 'range': '1000€+'},
  ];
  
  File? _photoEmplacement;
  List<File> _fichiersReference = [];
  List<String> _imagesGenerees = [];

  String? _estimatedBudget;
  String _urgency = 'normal';
  String? _preferredStyle;
  String? _colorPreference;
  
  // ✅ Contraintes pour forcer passage par l'app
  bool _acceptTerms = false;
  bool _agreeToAppOnlyContact = false;

  @override
  void initState() {
    super.initState();
    
    if (!_authService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    _backgroundImage = _getRandomBackground();
    _loadUserProfile();
    _initializeWithFlash(); // ✅ Préremplir si flash fourni
    IaGenerationService.instance.onImageGenerated.listen(_ajouterImageGeneree);
  }

  // ✅ Charger le profil utilisateur depuis SecureAuthService
  Future<void> _loadUserProfile() async {
    setState(() => _isLoadingProfile = true);
    
    try {
      // ✅ Utiliser les vraies données utilisateur quand disponibles
      final currentUser = _authService.currentUser;
      final userProfile = _authService.userProfile;
      
      if (currentUser != null && userProfile != null) {
        _userProfile = {
          'firstName': userProfile['firstName'] ?? userProfile['displayName']?.split(' ').first ?? 'Utilisateur',
          'lastName': userProfile['lastName'] ?? userProfile['displayName']?.split(' ').skip(1).join(' ') ?? '',
          'email': currentUser.email ?? 'Email non renseigné',
          'phone': userProfile['phone'] ?? userProfile['phoneNumber'] ?? 'Téléphone non renseigné',
          'address': userProfile['address'] ?? 'Adresse non renseignée',
          'dateOfBirth': userProfile['dateOfBirth'],
          'preferredStyles': userProfile['preferredStyles'] ?? ['Non défini'],
          'allergies': userProfile['allergies'] ?? 'Aucune allergie connue',
          'previousTattoos': userProfile['previousTattoos'] ?? 0,
          'preferredBudget': userProfile['preferredBudget'] ?? 'Non défini',
        };
      } else {
        // Fallback avec données par défaut
        _userProfile = {
          'firstName': 'Utilisateur',
          'lastName': 'Kipik',
          'email': _authService.currentUser?.email ?? 'email@exemple.com',
          'phone': 'Téléphone non renseigné',
          'address': 'Adresse non renseignée',
          'preferredStyles': ['Non défini'],
          'allergies': 'Aucune allergie connue',
          'previousTattoos': 0,
          'preferredBudget': 'Non défini',
        };
      }
      
    } catch (e) {
      print('❌ Erreur chargement profil: $e');
      // Profil d'urgence en cas d'erreur
      _userProfile = {
        'firstName': 'Utilisateur',
        'lastName': 'Kipik',
        'email': 'email@exemple.com',
        'phone': 'Téléphone à renseigner',
        'address': 'Adresse à renseigner',
        'preferredStyles': ['À définir'],
        'allergies': 'À préciser',
        'previousTattoos': 0,
        'preferredBudget': 'À définir',
      };
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }

  // ✅ Initialiser avec flash prérempli
  void _initializeWithFlash() {
    if (widget.prefilledFlash != null) {
      final flash = widget.prefilledFlash!;
      
      setState(() {
        // ✅ Message prérempli intelligent selon le type de flash
        final isFlashMinute = flash['status'] == 'flashminute';
        final discount = flash['discount'];
        
        String baseMessage = 'Je souhaite réserver ce flash : "${flash['title']}".\n\n';
        
        if (isFlashMinute && discount != null) {
          baseMessage += '🔥 FLASH MINUTE ACTIF (-${discount}%) !\n';
          baseMessage += 'Prix original : ${flash['originalPrice']}€\n';
          baseMessage += 'Prix Flash Minute : ${flash['price']}€\n\n';
        } else {
          baseMessage += 'Prix : ${flash['price']}€\n\n';
        }
        
        baseMessage += 'Style : ${flash['style']}\n';
        baseMessage += 'Taille : ${flash['size']}\n\n';
        
        if (flash['tags'] != null && flash['tags'].isNotEmpty) {
          baseMessage += 'Tags : ${(flash['tags'] as List).join(', ')}\n\n';
        }
        
        baseMessage += 'Merci de me confirmer :\n';
        baseMessage += '• Les créneaux disponibles\n';
        baseMessage += '• Les modalités de réservation\n';
        baseMessage += '• Le montant de l\'acompte requis\n\n';
        
        if (isFlashMinute) {
          baseMessage += '⚡ Je comprends que cette offre Flash Minute est limitée dans le temps.';
        }

        _descriptionController.text = baseMessage;
        
        // Préremplir les autres champs
        _tailleSelectionnee = flash['size'] ?? "10x10 cm";
        _preferredStyle = flash['style'];
        
        // Préremplir les zones si disponibles
        if (flash['placement'] != null) {
          _zonesSelectionnees = List<String>.from(flash['placement']);
        }
      });
    }
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
  
  void _ajouterImageGeneree(String imageUrl) {
    if (mounted) {
      setState(() {
        _imagesGenerees.add(imageUrl);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Image IA ajoutée à votre demande"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _choisirPhotoEmplacement() async {
    try {
      const XTypeGroup imagesGroup = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      
      final XFile? file = await openFile(
        acceptedTypeGroups: [imagesGroup],
      );
      
      if (file != null) {
        final fileSize = await File(file.path).length();
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Fichier trop volumineux (max 10MB)"),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        setState(() {
          _photoEmplacement = File(file.path);
        });
      }
    } catch (e) {
      debugPrint("Erreur sélection photo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible de sélectionner cette photo"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _choisirFichiersReference() async {
    try {
      const XTypeGroup imagesGroup = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      
      const XTypeGroup documentsGroup = XTypeGroup(
        label: 'Documents',
        extensions: ['pdf'],
      );
      
      final List<XFile> files = await openFiles(
        acceptedTypeGroups: [imagesGroup, documentsGroup],
      );
      
      if (files.isNotEmpty) {
        final nouveauxFichiers = <File>[];
        int totalSize = 0;

        for (final xFile in files) {
          final file = File(xFile.path);
          final fileSize = await file.length();
          totalSize += fileSize;

          if (fileSize > 10 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Fichier ${xFile.name} trop volumineux (max 10MB)"),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            continue;
          }

          nouveauxFichiers.add(file);
        }

        if (totalSize > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Taille totale des fichiers trop importante (max 50MB)"),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        setState(() {
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
      debugPrint("Erreur sélection fichiers: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la sélection: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _supprimerFichierReference(int index) {
    setState(() {
      _fichiersReference.removeAt(index);
    });
  }
  
  void _supprimerImageGeneree(int index) {
    setState(() {
      _imagesGenerees.removeAt(index);
    });
  }

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
    
    if (_descriptionController.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Description trop courte (minimum 20 caractères)"),
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

    // ✅ Validation des conditions renforcées
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez accepter les conditions d'utilisation"),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (!_agreeToAppOnlyContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez accepter de passer exclusivement par l'application"),
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
      String? zoneImageUrl;
      String? photoEmplacementUrl;
      List<String> fichiersReferenceUrls = [];

      final imagePath = await ScreenshotHelper.captureAvatar(
        context,
        _zonesKey,
      );

      if (imagePath != null) {
        zoneImageUrl = await _devisService.uploadImage(
          File(imagePath),
          'zones/${DateTime.now().millisecondsSinceEpoch}_zone.png',
        );
      }
      
      if (_photoEmplacement != null) {
        photoEmplacementUrl = await _devisService.uploadImage(
          _photoEmplacement!,
          'emplacements/${DateTime.now().millisecondsSinceEpoch}_emplacement.jpg',
        );
      }
      
      if (_fichiersReference.isNotEmpty) {
        fichiersReferenceUrls = await _devisService.uploadMultipleImages(
          _fichiersReference,
          'references',
        );
      }

      // ✅ Données enrichies avec profil utilisateur et flash
      final demandeData = {
        'description': _descriptionController.text.trim(),
        'taille': _tailleSelectionnee,
        'zones': _zonesSelectionnees,
        'zoneImageUrl': zoneImageUrl,
        'photoEmplacementUrl': photoEmplacementUrl,
        'fichiersReferenceUrls': fichiersReferenceUrls,
        'imagesGenerees': _imagesGenerees,
        
        // ✅ Données flash si prérempli
        'isFlashBooking': widget.prefilledFlash != null,
        'flashData': widget.prefilledFlash,
        'targetTattooerId': widget.tatoueurId,
        'targetTatoueurName': widget.tatoueurName,
        
        // ✅ Données utilisateur préremplies
        'clientProfile': _userProfile,
        'estimatedBudget': _estimatedBudget,
        'urgency': _urgency,
        'preferredStyle': _preferredStyle,
        'colorPreference': _colorPreference,
        
        // ✅ Contraintes application
        'acceptedTerms': _acceptTerms,
        'agreeToAppOnlyContact': _agreeToAppOnlyContact,
        'mustUseAppForBooking': true,
        'commissionRate': 0.01, // 1% de commission
        
        // ✅ Métadonnées enrichies
        'requestType': widget.prefilledFlash != null ? 'flash_booking' : 'custom_design',
        'isFlashMinute': widget.prefilledFlash?['status'] == 'flashminute',
        'flashMinuteDiscount': widget.prefilledFlash?['discount'],
        'urgentUntil': widget.prefilledFlash?['urgentUntil']?.toString(),
        'totalImages': fichiersReferenceUrls.length + _imagesGenerees.length,
        'hasPhotoEmplacement': _photoEmplacement != null,
        'zonesCount': _zonesSelectionnees.length,
        'descriptionLength': _descriptionController.text.trim().length,
        'submissionTimestamp': DateTime.now().toIso8601String(),
        'clientId': _authService.currentUserId,
        'complexity': _calculateComplexity(),
      };

      await _devisService.createDemandeDevis(demandeData);

      if (mounted) {
        final isFlashMinute = widget.prefilledFlash?['status'] == 'flashminute';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.prefilledFlash != null 
                  ? isFlashMinute 
                      ? "⚡ Demande Flash Minute envoyée !"
                      : "✅ Demande de réservation flash envoyée !"
                  : "✅ Demande de devis envoyée avec succès !"
            ),
            backgroundColor: isFlashMinute ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // ✅ Réinitialiser le formulaire
        _resetForm();
        
        // ✅ Retourner avec succès
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context, true); // ✅ true = succès
          }
        });
      }
      
    } catch (e) {
      debugPrint("Erreur envoi demande : $e");
      if (mounted) {
        String errorMessage = "❌ Échec de l'envoi, réessaye plus tard.";
        
        if (e.toString().contains('Validation de sécurité')) {
          errorMessage = "❌ Validation de sécurité échouée. Réessayez dans quelques minutes.";
        } else if (e.toString().contains('trop volumineux')) {
          errorMessage = "❌ Fichiers trop volumineux. Compressez vos images.";
        } else if (e.toString().contains('non connecté')) {
          errorMessage = "❌ Session expirée. Reconnectez-vous.";
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ Calculer la complexité du projet
  String _calculateComplexity() {
    int score = 0;
    
    // Taille
    if (_tailleSelectionnee.contains('30x30') || _tailleSelectionnee.contains('Grande pièce')) {
      score += 3;
    } else if (_tailleSelectionnee.contains('20x')) {
      score += 2;
    } else if (_tailleSelectionnee.contains('15x')) {
      score += 1;
    }
    
    // Nombre de zones
    score += (_zonesSelectionnees.length / 2).ceil();
    
    // Nombre d'images de référence
    score += (_fichiersReference.length / 2).ceil();
    
    // Description détaillée
    if (_descriptionController.text.length > 200) score += 1;
    if (_descriptionController.text.length > 500) score += 1;
    
    if (score <= 2) return 'simple';
    if (score <= 5) return 'medium';
    return 'complex';
  }

  // ✅ Réinitialiser le formulaire
  void _resetForm() {
    _descriptionController.clear();
    setState(() {
      _zonesSelectionnees = [];
      _tailleSelectionnee = "10x10 cm";
      _photoEmplacement = null;
      _fichiersReference = [];
      _imagesGenerees = [];
      _estimatedBudget = null;
      _urgency = 'normal';
      _preferredStyle = null;
      _colorPreference = null;
      _acceptTerms = false;
      _agreeToAppOnlyContact = false;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_authService.isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLoadingProfile) {
      return Scaffold(
        appBar: const CustomAppBarKipik(
          title: 'Demande de Devis',
          showBackButton: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de votre profil...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: const CustomDrawerParticulier(),
      appBar: CustomAppBarKipik(
        title: widget.prefilledFlash != null 
            ? widget.prefilledFlash!['status'] == 'flashminute'
                ? '⚡ Flash Minute'
                : 'Réserver ce Flash' 
            : 'Demande de Devis',
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
          Image.asset(_backgroundImage, fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.3)),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  
                  // ✅ Infos utilisateur préremplies
                  _buildUserProfileCard(),
                  const SizedBox(height: 16),
                  
                  // ✅ Flash prérempli si applicable
                  if (widget.prefilledFlash != null) ...[
                    _buildFlashInfoCard(),
                    const SizedBox(height: 16),
                  ],
                  
                  _buildSectionDescription(),
                  const SizedBox(height: 24),
                  _buildSectionTaille(),
                  const SizedBox(height: 24),
                  _buildSectionPreferences(),
                  const SizedBox(height: 24),
                  _buildSectionPhotoEmplacement(),
                  const SizedBox(height: 24),
                  _buildSectionImagesReference(),
                  _buildSectionImagesGenerees(),
                  const SizedBox(height: 24),
                  
                  // ✅ AVATAR AMÉLIORÉ
                  _buildSectionZonesCorps(),
                  const SizedBox(height: 24),
                  
                  // ✅ Conditions d'utilisation
                  _buildSectionConditions(),
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

  // ✅ Card profil utilisateur prérempli
  Widget _buildUserProfileCard() {
    return _buildSectionWithTitle(
      title: 'VOS INFORMATIONS',
      icon: Icons.person,
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Informations automatiquement remplies depuis votre profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${_userProfile?['firstName']} ${_userProfile?['lastName']}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _userProfile?['email'] ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            Text(
              _userProfile?['phone'] ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            if (_userProfile?['previousTattoos'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tatouages précédents : ${_userProfile!['previousTattoos']}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ Card flash prérempli avec info Flash Minute
  Widget _buildFlashInfoCard() {
    final flash = widget.prefilledFlash!;
    final isFlashMinute = flash['status'] == 'flashminute';
    final hasDiscount = flash['discount'] != null;
    
    return _buildSectionWithTitle(
      title: isFlashMinute ? '⚡ FLASH MINUTE SÉLECTIONNÉ' : 'FLASH SÉLECTIONNÉ',
      icon: isFlashMinute ? Icons.flash_on : Icons.star,
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFlashMinute 
              ? Colors.orange.withOpacity(0.1)
              : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFlashMinute 
                ? Colors.orange.withOpacity(0.3)
                : Colors.blue.withOpacity(0.3)
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flash['title'] ?? 'Flash sans titre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${flash['style']} • ${flash['size']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              '${flash['originalPrice']}€',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.6),
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '${flash['price']}€',
                            style: TextStyle(
                              color: isFlashMinute ? Colors.orange : Colors.blue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // ✅ Info Flash Minute avec countdown
            if (isFlashMinute && flash['urgentUntil'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offre limitée - Se termine le ${DateTime.parse(flash['urgentUntil']).toString().substring(0, 16)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ Section description adaptée pour flash
  Widget _buildSectionDescription() {
    final isFlash = widget.prefilledFlash != null;
    final isFlashMinute = widget.prefilledFlash?['status'] == 'flashminute';
    
    return _buildSectionWithTitle(
      title: isFlash 
          ? isFlashMinute 
              ? '⚡ MESSAGE FLASH MINUTE *'
              : 'MESSAGE POUR LE TATOUEUR *' 
          : 'DÉCRIS TON PROJET *',
      icon: isFlash ? Icons.message : Icons.description,
      content: Column(
        children: [
          _buildTextField(
            controller: _descriptionController,
            hint: isFlash 
                ? isFlashMinute
                    ? 'Confirmez votre réservation Flash Minute et précisez vos attentes...'
                    : 'Ajoutez un message pour le tatoueur concernant ce flash...'
                : 'Décris précisément ton idée de tatouage, le style souhaité, les couleurs, l\'ambiance...',
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isFlash ? Icons.schedule : Icons.info_outline, 
                color: Colors.white.withOpacity(0.7), 
                size: 16
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFlash
                      ? isFlashMinute
                          ? 'Réservation rapide - Le tatoueur vous répondra en priorité'
                          : 'Précisez vos attentes, questions ou demandes spécifiques'
                      : 'Minimum 20 caractères - Plus tu donnes de détails, meilleur sera le devis',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // [AUTRES MÉTHODES INCHANGÉES...]
  Widget _buildSectionTaille() {
    final isFlashWithSize = widget.prefilledFlash != null && widget.prefilledFlash!['size'] != null;
    
    return _buildSectionWithTitle(
      title: 'TAILLE DU TATOUAGE *',
      icon: Icons.straighten,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: _tailleSelectionnee,
          onChanged: isFlashWithSize ? null : (String? newValue) {
            if (newValue != null) {
              setState(() {
                _tailleSelectionnee = newValue;
              });
            }
          },
          items: _tailles.map<DropdownMenuItem<String>>((Map<String, dynamic> taille) {
            return DropdownMenuItem<String>(
              value: taille['value'],
              child: Row(
                children: [
                  Expanded(
                    child: Text(taille['value']),
                  ),
                  Text(
                    '${taille['category']} ${taille['price']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          isExpanded: true,
          dropdownColor: Colors.white,
          style: TextStyle(
            color: isFlashWithSize ? Colors.grey : Colors.black87, 
            fontSize: 16,
          ),
          underline: Container(),
        ),
      ),
    );
  }

  Widget _buildSectionPreferences() {
    return _buildSectionWithTitle(
      title: 'PRÉFÉRENCES (OPTIONNEL)',
      icon: Icons.tune,
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _estimatedBudget,
              hint: Text('Budget estimé (${_userProfile?['preferredBudget'] ?? 'Non défini'})'),
              onChanged: (String? newValue) {
                setState(() => _estimatedBudget = newValue);
              },
              items: [
                'Moins de 100€',
                '100€ - 300€',
                '300€ - 500€',
                '500€ - 1000€',
                'Plus de 1000€',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              underline: Container(),
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _urgency,
              onChanged: (String? newValue) {
                setState(() => _urgency = newValue!);
              },
              items: [
                'normal',
                'rapide',
                'urgent',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'normal' ? 'Pas pressé' : 
                              value == 'rapide' ? 'Assez rapide' : 'Urgent'),
                );
              }).toList(),
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              underline: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionConditions() {
    return _buildSectionWithTitle(
      title: 'CONDITIONS D\'UTILISATION *',
      icon: Icons.gavel,
      content: Column(
        children: [
          // Conditions générales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                CheckboxListTile(
                  value: _acceptTerms,
                  onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                  title: const Text(
                    'J\'accepte les conditions générales d\'utilisation',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.blue,
                  checkColor: Colors.white,
                ),
                CheckboxListTile(
                  value: _agreeToAppOnlyContact,
                  onChanged: (value) => setState(() => _agreeToAppOnlyContact = value ?? false),
                  title: const Text(
                    'Je m\'engage à passer exclusivement par l\'application Kipik pour toute communication et réservation avec le tatoueur',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.blue,
                  checkColor: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // ✅ Pourquoi passer par l'app
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KipikTheme.rouge.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: KipikTheme.rouge, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Pourquoi utiliser exclusivement Kipik ?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Protection de vos paiements et acomptes\n'
                  '• Chat sécurisé et historique conservé\n'
                  '• Gestion automatique des rendez-vous\n'
                  '• Support client en cas de litige\n'
                  '• Visioconférence intégrée pour les consultations\n'
                  '• Validation étape par étape de votre projet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // [SECTIONS INCHANGÉES]
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
                        'Ajouter une photo (optionnel)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aide le tatoueur à mieux comprendre l\'emplacement',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionImagesReference() {
    return _buildSectionWithTitle(
      title: 'IMAGES DE RÉFÉRENCE',
      icon: Icons.image,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ajoute jusqu\'à 5 images de référence (max 10MB chacune)',
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
                label: Text('Ajouter (${_fichiersReference.length}/5)'),
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
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
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
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
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

  Widget _buildSectionZonesCorps() {
    return _buildSectionWithTitle(
      title: 'ZONES À TATOUER *',
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
              height: 500,
              child: ImprovedBodyZoneSelector(
                selectedZones: _zonesSelectionnees,
                onZonesSelected: _onZonesSelected,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
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
    final isFlash = widget.prefilledFlash != null;
    final isFlashMinute = widget.prefilledFlash?['status'] == 'flashminute';
    
    return ElevatedButton(
      onPressed: _isLoading ? null : _envoyerDemande,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isLoading 
            ? Colors.grey 
            : isFlashMinute 
                ? Colors.orange 
                : KipikTheme.rouge,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.5),
      ),
      child: _isLoading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'ENVOI EN COURS...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFlashMinute 
                      ? Icons.flash_on 
                      : isFlash 
                          ? Icons.bookmark 
                          : Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isFlashMinute 
                      ? '⚡ RÉSERVER FLASH MINUTE'
                      : isFlash 
                          ? 'RÉSERVER CE FLASH'
                          : 'ENVOYER MA DEMANDE',
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'PermanentMarker',
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
    );
  }

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
          counterText: maxLines > 1 ? '${controller.text.length} caractères' : null,
          counterStyle: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        onChanged: maxLines > 1 ? (value) => setState(() {}) : null,
      ),
    );
  }
}

// ✅ Sélecteur de zones corporelles amélioré
class ImprovedBodyZoneSelector extends StatefulWidget {
  final List<String> selectedZones;
  final Function(List<String>) onZonesSelected;

  const ImprovedBodyZoneSelector({
    Key? key,
    required this.selectedZones,
    required this.onZonesSelected,
  }) : super(key: key);

  @override
  State<ImprovedBodyZoneSelector> createState() => _ImprovedBodyZoneSelectorState();
}

class _ImprovedBodyZoneSelectorState extends State<ImprovedBodyZoneSelector> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedZones = <String>{};

  // ✅ Zones anatomiques précises et réalistes
  final Map<String, Map<String, dynamic>> _bodyZones = {
    // Face avant
    'front': {
      'title': 'Face avant',
      'zones': [
        {'name': 'Visage', 'x': 0.5, 'y': 0.1, 'width': 0.12, 'height': 0.08},
        {'name': 'Cou', 'x': 0.5, 'y': 0.18, 'width': 0.08, 'height': 0.06},
        {'name': 'Épaule gauche', 'x': 0.25, 'y': 0.24, 'width': 0.12, 'height': 0.08},
        {'name': 'Épaule droite', 'x': 0.75, 'y': 0.24, 'width': 0.12, 'height': 0.08},
        {'name': 'Poitrine', 'x': 0.5, 'y': 0.32, 'width': 0.2, 'height': 0.12},
        {'name': 'Bras gauche', 'x': 0.18, 'y': 0.38, 'width': 0.08, 'height': 0.15},
        {'name': 'Bras droit', 'x': 0.82, 'y': 0.38, 'width': 0.08, 'height': 0.15},
        {'name': 'Abdomen', 'x': 0.5, 'y': 0.44, 'width': 0.16, 'height': 0.12},
        {'name': 'Avant-bras gauche', 'x': 0.15, 'y': 0.53, 'width': 0.06, 'height': 0.15},
        {'name': 'Avant-bras droit', 'x': 0.85, 'y': 0.53, 'width': 0.06, 'height': 0.15},
        {'name': 'Bassin', 'x': 0.5, 'y': 0.56, 'width': 0.14, 'height': 0.08},
        {'name': 'Main gauche', 'x': 0.12, 'y': 0.68, 'width': 0.05, 'height': 0.06},
        {'name': 'Main droite', 'x': 0.88, 'y': 0.68, 'width': 0.05, 'height': 0.06},
        {'name': 'Cuisse gauche', 'x': 0.42, 'y': 0.64, 'width': 0.08, 'height': 0.18},
        {'name': 'Cuisse droite', 'x': 0.58, 'y': 0.64, 'width': 0.08, 'height': 0.18},
        {'name': 'Genou gauche', 'x': 0.42, 'y': 0.82, 'width': 0.06, 'height': 0.04},
        {'name': 'Genou droit', 'x': 0.58, 'y': 0.82, 'width': 0.06, 'height': 0.04},
        {'name': 'Tibia gauche', 'x': 0.42, 'y': 0.86, 'width': 0.05, 'height': 0.12},
        {'name': 'Tibia droit', 'x': 0.58, 'y': 0.86, 'width': 0.05, 'height': 0.12},
        {'name': 'Pied gauche', 'x': 0.42, 'y': 0.98, 'width': 0.06, 'height': 0.04},
        {'name': 'Pied droit', 'x': 0.58, 'y': 0.98, 'width': 0.06, 'height': 0.04},
      ],
    },
    // Face arrière
    'back': {
      'title': 'Face arrière',
      'zones': [
        {'name': 'Crâne', 'x': 0.5, 'y': 0.1, 'width': 0.12, 'height': 0.08},
        {'name': 'Nuque', 'x': 0.5, 'y': 0.18, 'width': 0.08, 'height': 0.06},
        {'name': 'Épaule gauche', 'x': 0.25, 'y': 0.24, 'width': 0.12, 'height': 0.08},
        {'name': 'Épaule droite', 'x': 0.75, 'y': 0.24, 'width': 0.12, 'height': 0.08},
        {'name': 'Haut du dos', 'x': 0.5, 'y': 0.32, 'width': 0.2, 'height': 0.08},
        {'name': 'Omoplate gauche', 'x': 0.35, 'y': 0.36, 'width': 0.08, 'height': 0.08},
        {'name': 'Omoplate droite', 'x': 0.65, 'y': 0.36, 'width': 0.08, 'height': 0.08},
        {'name': 'Milieu du dos', 'x': 0.5, 'y': 0.44, 'width': 0.16, 'height': 0.08},
        {'name': 'Bas du dos', 'x': 0.5, 'y': 0.52, 'width': 0.14, 'height': 0.08},
        {'name': 'Fesse gauche', 'x': 0.42, 'y': 0.6, 'width': 0.08, 'height': 0.08},
        {'name': 'Fesse droite', 'x': 0.58, 'y': 0.6, 'width': 0.08, 'height': 0.08},
        {'name': 'Cuisse gauche (arrière)', 'x': 0.42, 'y': 0.68, 'width': 0.08, 'height': 0.16},
        {'name': 'Cuisse droite (arrière)', 'x': 0.58, 'y': 0.68, 'width': 0.08, 'height': 0.16},
        {'name': 'Mollet gauche', 'x': 0.42, 'y': 0.84, 'width': 0.06, 'height': 0.12},
        {'name': 'Mollet droit', 'x': 0.58, 'y': 0.84, 'width': 0.06, 'height': 0.12},
        {'name': 'Talon gauche', 'x': 0.42, 'y': 0.96, 'width': 0.05, 'height': 0.04},
        {'name': 'Talon droit', 'x': 0.58, 'y': 0.96, 'width': 0.05, 'height': 0.04},
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedZones.addAll(widget.selectedZones);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleZone(String zoneName) {
    setState(() {
      if (_selectedZones.contains(zoneName)) {
        _selectedZones.remove(zoneName);
      } else {
        _selectedZones.add(zoneName);
      }
      widget.onZonesSelected(_selectedZones.toList());
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
        
        // Contenu des tabs avec silhouettes améliorées
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
                _buildBodySilhouette('front'),
                _buildBodySilhouette('back'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodySilhouette(String view) {
    final viewData = _bodyZones[view]!;
    final zones = viewData['zones'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // ✅ Silhouette de base avec CustomPainter
          Center(
            child: Container(
              width: 200,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: CustomPaint(
                painter: BodySilhouettePainter(view: view),
                size: const Size(200, 400),
              ),
            ),
          ),
          
          // ✅ Zones cliquables superposées
          ...zones.map((zone) {
            final isSelected = _selectedZones.contains(zone['name']);
            return Positioned(
              left: (zone['x'] as double) * 200 - (zone['width'] as double) * 100,
              top: (zone['y'] as double) * 400 - (zone['height'] as double) * 200,
              child: GestureDetector(
                onTap: () => _toggleZone(zone['name']),
                child: Container(
                  width: (zone['width'] as double) * 200,
                  height: (zone['height'] as double) * 200,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? KipikTheme.rouge.withOpacity(0.7)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
          
          // ✅ Légende des zones sélectionnées
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedZones.isEmpty 
                    ? 'Touchez les zones pour les sélectionner'
                    : '${_selectedZones.length} zone${_selectedZones.length > 1 ? 's' : ''} sélectionnée${_selectedZones.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Painter pour dessiner les silhouettes
class BodySilhouettePainter extends CustomPainter {
  final String view;

  BodySilhouettePainter({required this.view});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (view == 'front') {
      _drawFrontSilhouette(canvas, size, paint, outlinePaint);
    } else {
      _drawBackSilhouette(canvas, size, paint, outlinePaint);
    }
  }

  void _drawFrontSilhouette(Canvas canvas, Size size, Paint fillPaint, Paint outlinePaint) {
    final path = Path();
    final centerX = size.width / 2;
    
    // Tête (cercle)
    canvas.drawCircle(
      Offset(centerX, size.height * 0.1),
      size.width * 0.06,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(centerX, size.height * 0.1),
      size.width * 0.06,
      outlinePaint,
    );
    
    // Corps principal
    path.moveTo(centerX, size.height * 0.16); // Cou
    
    // Épaules
    path.lineTo(centerX - size.width * 0.15, size.height * 0.24);
    path.lineTo(centerX - size.width * 0.2, size.height * 0.32);
    
    // Bras gauche
    path.lineTo(centerX - size.width * 0.22, size.height * 0.55);
    path.lineTo(centerX - size.width * 0.18, size.height * 0.68);
    path.lineTo(centerX - size.width * 0.15, size.height * 0.66);
    path.lineTo(centerX - size.width * 0.12, size.height * 0.52);
    
    // Torse gauche
    path.lineTo(centerX - size.width * 0.1, size.height * 0.44);
    path.lineTo(centerX - size.width * 0.08, size.height * 0.56);
    
    // Jambe gauche
    path.lineTo(centerX - size.width * 0.06, size.height * 0.64);
    path.lineTo(centerX - size.width * 0.05, size.height * 0.82);
    path.lineTo(centerX - size.width * 0.04, size.height * 0.98);
    path.lineTo(centerX - size.width * 0.01, size.height * 0.98);
    path.lineTo(centerX, size.height * 0.82);
    
    // Milieu
    path.lineTo(centerX, size.height * 0.64);
    path.lineTo(centerX, size.height * 0.82);
    
    // Jambe droite (symétrique)
    path.lineTo(centerX + size.width * 0.01, size.height * 0.98);
    path.lineTo(centerX + size.width * 0.04, size.height * 0.98);
    path.lineTo(centerX + size.width * 0.05, size.height * 0.82);
    path.lineTo(centerX + size.width * 0.06, size.height * 0.64);
    
    // Torse droit
    path.lineTo(centerX + size.width * 0.08, size.height * 0.56);
    path.lineTo(centerX + size.width * 0.1, size.height * 0.44);
    
    // Bras droit
    path.lineTo(centerX + size.width * 0.12, size.height * 0.52);
    path.lineTo(centerX + size.width * 0.15, size.height * 0.66);
    path.lineTo(centerX + size.width * 0.18, size.height * 0.68);
    path.lineTo(centerX + size.width * 0.22, size.height * 0.55);
    path.lineTo(centerX + size.width * 0.2, size.height * 0.32);
    
    // Épaule droite
    path.lineTo(centerX + size.width * 0.15, size.height * 0.24);
    path.lineTo(centerX, size.height * 0.16);
    
    path.close();
    
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, outlinePaint);
  }

  void _drawBackSilhouette(Canvas canvas, Size size, Paint fillPaint, Paint outlinePaint) {
    // Similaire à la face avant mais avec quelques différences pour le dos
    final path = Path();
    final centerX = size.width / 2;
    
    // Tête
    canvas.drawCircle(
      Offset(centerX, size.height * 0.1),
      size.width * 0.06,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(centerX, size.height * 0.1),
      size.width * 0.06,
      outlinePaint,
    );
    
    // Corps (similaire mais légèrement différent pour le dos)
    path.moveTo(centerX, size.height * 0.16);
    path.lineTo(centerX - size.width * 0.15, size.height * 0.24);
    path.lineTo(centerX - size.width * 0.2, size.height * 0.32);
    path.lineTo(centerX - size.width * 0.22, size.height * 0.55);
    path.lineTo(centerX - size.width * 0.18, size.height * 0.68);
    path.lineTo(centerX - size.width * 0.15, size.height * 0.66);
    path.lineTo(centerX - size.width * 0.12, size.height * 0.52);
    path.lineTo(centerX - size.width * 0.1, size.height * 0.44);
    path.lineTo(centerX - size.width * 0.08, size.height * 0.56);
    path.lineTo(centerX - size.width * 0.06, size.height * 0.64);
    path.lineTo(centerX - size.width * 0.05, size.height * 0.82);
    path.lineTo(centerX - size.width * 0.04, size.height * 0.98);
    path.lineTo(centerX + size.width * 0.04, size.height * 0.98);
    path.lineTo(centerX + size.width * 0.05, size.height * 0.82);
    path.lineTo(centerX + size.width * 0.06, size.height * 0.64);
    path.lineTo(centerX + size.width * 0.08, size.height * 0.56);
    path.lineTo(centerX + size.width * 0.1, size.height * 0.44);
    path.lineTo(centerX + size.width * 0.12, size.height * 0.52);
    path.lineTo(centerX + size.width * 0.15, size.height * 0.66);
    path.lineTo(centerX + size.width * 0.18, size.height * 0.68);
    path.lineTo(centerX + size.width * 0.22, size.height * 0.55);
    path.lineTo(centerX + size.width * 0.2, size.height * 0.32);
    path.lineTo(centerX + size.width * 0.15, size.height * 0.24);
    path.lineTo(centerX, size.height * 0.16);
    path.close();
    
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ✅ Service IA conservé
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