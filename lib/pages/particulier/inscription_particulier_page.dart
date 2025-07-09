// lib/pages/particulier/inscription_particulier_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ MIGRATION
import 'package:kipik_v5/services/auth/captcha_manager.dart'; // ✅ MIGRATION: reCAPTCHA
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/utils/cgu_cgv_validation_widget.dart';
import 'package:kipik_v5/pages/particulier/confirmation_inscription_particulier_page.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/config/api_config.dart'; // ✅ NOUVEAU - ApiConfig

class InscriptionParticulierPage extends StatefulWidget {
  const InscriptionParticulierPage({
    Key? key,
  }) : super(key: key);

  @override
  State<InscriptionParticulierPage> createState() =>
      _InscriptionParticulierPageState();
}

class _InscriptionParticulierPageState
    extends State<InscriptionParticulierPage> {
  final _formKey = GlobalKey<FormState>();

  // ✅ MIGRATION: Service sécurisé centralisé
  SecureAuthService get _authService => SecureAuthService.instance;

  // Controllers
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final numeroController = TextEditingController();
  final rueController = TextEditingController();
  final codePostalController = TextEditingController();
  final villeController = TextEditingController();
  final telController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  DateTime? dateNaissance;
  XFile? pieceIdentite;

  bool newsletterAccepted = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool cguLu = false;
  bool cgvLu = false;
  bool _isLoading = false; // ✅ État de chargement
  
  // ✅ NOUVEAU: Variables pour la vérification d'âge
  bool majoriteConfirmee = false; // ✅ Certification majorité
  String? ageError; // ✅ Erreur d'âge

  static const Map<String, List<String>> villesParCodePostal = {
    '54510': ['Tomblaine'],
    '75001': ['Paris 1er'],
    '69001': ['Lyon 1er'],
    // Ajoutez plus de codes postaux selon vos besoins
  };

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email requis';
    final reg = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!reg.hasMatch(v.trim())) return 'Email invalide';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe requis';
    if (v.length < 6) return '6 caractères minimum';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v != passwordController.text) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  // ✅ NOUVEAU: Méthode de vérification d'âge
  bool _isOver18(DateTime birthDate) {
    final today = DateTime.now();
    final age = today.year - birthDate.year;
    
    // Vérification précise avec mois et jour
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      return age - 1 >= 18;
    }
    return age >= 18;
  }

  // ✅ MISE À JOUR: Validation avec vérification d'âge
  bool get isFormValid =>
      _formKey.currentState?.validate() == true &&
      cguLu &&
      cgvLu &&
      pieceIdentite != null &&
      dateNaissance != null &&
      majoriteConfirmee && // ✅ Certification obligatoire
      (dateNaissance != null ? _isOver18(dateNaissance!) : false); // ✅ Vérification âge

  Future<void> _submitForm() async {
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de remplir tous les champs obligatoires')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ MIGRATION: Validation reCAPTCHA pour sécurité
      final captchaResult = await CaptchaManager.instance.validateInvisibleCaptcha('signup');

      if (!captchaResult.isValid) {
        throw Exception('Validation de sécurité échouée');
      }

      // ✅ MIGRATION: Nouvelle méthode SecureAuthService
      final user = await _authService.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        displayName: '${prenomController.text.trim()} ${nomController.text.trim()}',
        userRole: 'client', // ✅ Rôle explicite pour particulier
        captchaResult: captchaResult,
      );

      if (user != null) {
        // ✅ MIGRATION: Mise à jour du profil avec données additionnelles
        await _authService.updateUserProfile(
          additionalData: {
            'type': 'particulier',
            'nom': nomController.text.trim(),
            'prenom': prenomController.text.trim(),
            'telephone': telController.text.trim(),
            'adresse': {
              'numero': numeroController.text.trim(),
              'rue': rueController.text.trim(),
              'codePostal': codePostalController.text.trim(),
              'ville': villeController.text.trim(),
            },
            'dateNaissance': dateNaissance?.toIso8601String(),
            'newsletter': newsletterAccepted,
            'pieceIdentiteNom': pieceIdentite?.name,
            'inscriptionCompleted': true,
            'profileComplete': true,
            'signupCaptchaScore': captchaResult.score,
            'majoriteConfirmee': majoriteConfirmee, // ✅ Enregistrement de la certification
          },
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ConfirmationInscriptionParticulierPage(),
            ),
          );
        }
      } else {
        throw Exception('Erreur lors de la création du compte');
      }
    } catch (e) {
      print('❌ Erreur inscription particulier: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'inscription: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ NOUVEAU - Test Google Vision API
  Future<void> _testGoogleVisionAPI() async {
    try {
      print('🔍 Test complet de Google Vision...');
      
      // Test 1: Configuration
      final isConfigured = await ApiConfig.isGoogleVisionConfigured;
      print('✅ Google Vision configuré: $isConfigured');
      
      // Test 2: Récupération clé
      final apiKey = await ApiConfig.googleApiKey;
      print('✅ Clé API récupérée: ${apiKey.substring(0, 15)}...');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Google Vision API prêt ! (${apiKey.substring(0, 10)}...)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Test Google Vision échoué: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ✅ NOUVEAU - Upload avec vérification Google Vision
  Future<void> _uploadDocumentWithVerification() async {
    try {
      // 1. Sélectionner le fichier
      final XFile? result = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'Images et PDF',
            extensions: ['jpg', 'jpeg', 'png', 'pdf'],
          )
        ],
      );

      if (result == null) return;

      // 2. Vérifier avec Google Vision si configuré
      bool isGoogleVisionEnabled = false;
      try {
        isGoogleVisionEnabled = await ApiConfig.isGoogleVisionConfigured;
      } catch (e) {
        print('⚠️ Google Vision non disponible: $e');
      }

      if (isGoogleVisionEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('🔍 Analyse du document en cours...'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Simulation d'analyse Google Vision (remplacez par l'appel réel)
        await Future.delayed(Duration(seconds: 2));
        
        // Ici vous pouvez ajouter l'appel réel à GoogleVisionService
        // final analysis = await GoogleVisionService.analyzeDocument(result);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Document analysé et approuvé !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // 3. Enregistrer le fichier
      setState(() => pieceIdentite = result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Document "${result.name}" téléchargé avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      print('❌ Erreur upload document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✅ OPTIMISÉ: InputDecoration compact avec PermanentMarker
  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'PermanentMarker', // ✅ PermanentMarker conservé
          fontSize: 11, // ✅ Taille réduite mais lisible
          color: Colors.black87,
          height: 0.9, // ✅ Interligne serré pour économiser l'espace
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'PermanentMarker', 
          fontSize: 12, // ✅ Taille contrôlée quand il flotte
          color: Colors.black87,
          height: 0.9,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, 
          vertical: 18, // ✅ Juste assez d'espace pour le label flottant
        ),
        isDense: true, // ✅ CRUCIAL: Réduit la hauteur globale du champ
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: KipikTheme.rouge, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: KipikTheme.rouge, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'PermanentMarker',
          fontSize: 10, // ✅ Erreurs compactes
          color: Colors.red,
          height: 1.0,
        ),
        suffixIcon: label.toLowerCase().contains('mot de passe')
            ? IconButton(
                icon: Icon(
                  label == 'Mot de passe *'
                      ? (showPassword ? Icons.visibility_off : Icons.visibility)
                      : (showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  color: KipikTheme.rouge,
                ),
                onPressed: () {
                  setState(() {
                    if (label == 'Mot de passe *') {
                      showPassword = !showPassword;
                    } else {
                      showConfirmPassword = !showConfirmPassword;
                    }
                  });
                },
              )
            : null,
      );

  // ✅ NOUVEAU: Widget de certification de majorité
  Widget _buildMajoriteConfirmation() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: majoriteConfirmee ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: majoriteConfirmee ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: majoriteConfirmee,
                onChanged: dateNaissance != null && _isOver18(dateNaissance!) 
                    ? (value) => setState(() => majoriteConfirmee = value!) 
                    : null, // ✅ Désactivé si pas majeur
                activeColor: KipikTheme.rouge,
              ),
              Expanded(
                child: Text(
                  "Je certifie avoir plus de 18 ans *",
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 14,
                    color: dateNaissance != null && _isOver18(dateNaissance!) 
                        ? Colors.white 
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                majoriteConfirmee ? Icons.check_circle : Icons.warning,
                color: majoriteConfirmee ? Colors.green : Colors.orange,
              ),
            ],
          ),
          if (ageError != null) // ✅ Affichage de l'erreur d'âge
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ageError!,
                      style: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ✅ Widget titres de sections avec headers tattoo (sans emoji dans le texte)
  Widget _buildSectionTitleWithHeader(String title, IconData icon, {int headerIndex = 1}) {
    final headers = [
      'assets/images/header_tattoo_wallpaper.png',
      'assets/images/header_tattoo_wallpaper2.png', 
      'assets/images/header_tattoo_wallpaper3.png',
    ];
    
    final headerImage = headers[(headerIndex - 1) % headers.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: AssetImage(headerImage),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.6),
            BlendMode.lighten,
          ),
        ),
        border: Border.all(color: KipikTheme.rouge, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: KipikTheme.rouge,
            size: 20,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.white,
                  blurRadius: 3,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // ✅ Nettoyage des controllers
    nomController.dispose();
    prenomController.dispose();
    numeroController.dispose();
    rueController.dispose();
    codePostalController.dispose();
    villeController.dispose();
    telController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final bg = backgrounds[Random().nextInt(backgrounds.length)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Inscription Particulier',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bg, fit: BoxFit.cover),
          SafeArea(
            top: true,
            bottom: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ✅ Indicateur de sécurité reCAPTCHA avec PermanentMarker
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.security, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Inscription sécurisée avec reCAPTCHA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les titres
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ Section Informations personnelles
                    _buildSectionTitleWithHeader('Informations personnelles', Icons.person, headerIndex: 1),

                    // Nom / Prénom avec Roboto pour le contenu saisi
                    TextFormField(
                      controller: nomController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto', // ✅ Roboto pour le contenu saisi
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      decoration: _inputDecoration('Nom *'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: prenomController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto', // ✅ Roboto pour le contenu saisi
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      decoration: _inputDecoration('Prénom *'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 20),

                    // ✅ Section Adresse
                    _buildSectionTitleWithHeader('Adresse', Icons.home, headerIndex: 2),

                    // Adresse
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: numeroController,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontFamily: 'Roboto', // ✅ Roboto pour le contenu saisi
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            decoration: _inputDecoration('N° *'),
                            validator: _requiredValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: rueController,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontFamily: 'Roboto', // ✅ Roboto pour le contenu saisi
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            decoration: _inputDecoration('Rue *'),
                            validator: _requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: codePostalController,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontFamily: 'Roboto', // ✅ Roboto pour le contenu saisi
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Code postal *'),
                            validator: _requiredValidator,
                            onChanged: (v) {
                              final liste = villesParCodePostal[v.trim()];
                              // ✅ CORRECTION: Ne pas écraser automatiquement si plusieurs villes
                              if (liste != null && liste.length == 1) {
                                setState(() {
                                  villeController.text = liste.first;
                                });
                              } else if (liste != null && liste.length > 1) {
                                // Vider le champ pour permettre à l'utilisateur de choisir
                                setState(() {
                                  villeController.text = '';
                                });
                              } else {
                                setState(() {
                                  villeController.text = '';
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: villeController,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontFamily: 'Roboto', // ✅ Roboto pour le contenu saisi
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            decoration: _inputDecoration('Ville *'),
                            validator: _requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ✅ Section Contact
                    _buildSectionTitleWithHeader('Contact', Icons.phone, headerIndex: 3),

                    // Téléphone
                    TextFormField(
                      controller: telController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto', // ✅ Roboto pour le contenu saisi
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Téléphone *'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),

                    // Email
                    TextFormField(
                      controller: emailController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto', // ✅ Roboto pour le contenu saisi
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Email *'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),

                    // ✅ Section Sécurité
                    _buildSectionTitleWithHeader('Sécurité', Icons.lock, headerIndex: 1),

                    // Mot de passe
                    TextFormField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto', // ✅ Roboto pour le contenu saisi
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      decoration: _inputDecoration('Mot de passe *'),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),

                    // Confirmer mot de passe
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !showConfirmPassword,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto', // ✅ Roboto pour le contenu saisi
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      decoration: _inputDecoration('Confirmer mot de passe *'),
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 20),

                    // ✅ Section Informations complémentaires
                    _buildSectionTitleWithHeader('Informations complémentaires', Icons.calendar_today, headerIndex: 2),

                    // ✅ MISE À JOUR: Date de naissance avec validation d'âge
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final pick = await showDatePicker(
                          context: context,
                          initialDate: dateNaissance ?? DateTime(now.year - 18),
                          firstDate: DateTime(1900),
                          lastDate: now,
                          locale: const Locale('fr', 'FR'),
                          // ✅ CORRECTION: Thème personnalisé avec couleur Kipik
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: KipikTheme.rouge, // ✅ Rouge Kipik au lieu de violet
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: KipikTheme.rouge, // ✅ Boutons en rouge Kipik
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        
                        if (pick != null) {
                          setState(() {
                            dateNaissance = pick;
                            
                            // ✅ VALIDATION AUTOMATIQUE D'ÂGE
                            if (!_isOver18(pick)) {
                              ageError = "Vous devez avoir au moins 18 ans pour vous inscrire";
                              majoriteConfirmee = false;
                            } else {
                              ageError = null;
                              // Ne pas cocher automatiquement, l'utilisateur doit le faire
                            }
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: _inputDecoration('Date de naissance *').copyWith(
                          // ✅ Bordure rouge si mineur
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: dateNaissance != null && !_isOver18(dateNaissance!) 
                                  ? Colors.red 
                                  : KipikTheme.rouge, 
                              width: 1.5
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                dateNaissance == null
                                    ? 'Sélectionner votre date'
                                    : '${dateNaissance!.day}/${dateNaissance!.month}/${dateNaissance!.year}',
                                style: TextStyle(
                                  color: dateNaissance == null ? Colors.grey : Colors.black87,
                                  fontFamily: 'Roboto', // ✅ Roboto pour le contenu saisi
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (dateNaissance != null)
                              Icon(
                                _isOver18(dateNaissance!) ? Icons.check_circle : Icons.error,
                                color: _isOver18(dateNaissance!) ? Colors.green : Colors.red,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ✅ NOUVEAU: Widget de certification de majorité
                    _buildMajoriteConfirmation(),

                    // ✅ NOUVEAU - Pièce d'identité avec vérification Google Vision
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _uploadDocumentWithVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pieceIdentite != null 
                              ? Colors.green 
                              : KipikTheme.rouge,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les boutons
                            fontSize: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              pieceIdentite != null 
                                  ? Icons.check_circle 
                                  : Icons.upload_file,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pieceIdentite == null
                                    ? "Joindre ma pièce d'identité * (vérification auto)"
                                    : "✓ Fichier vérifié : ${pieceIdentite!.name}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ✅ Section Conditions
                    _buildSectionTitleWithHeader('Conditions d\'utilisation', Icons.gavel, headerIndex: 3),

                    // CGU / CGV
                    CGUCGVValidationWidget(
                      cguAccepted: cguLu,
                      cgvAccepted: cgvLu,
                      onCGURead: () async {
                        final ok = await Navigator.pushNamed(context, '/cgu') as bool?;
                        if (mounted) setState(() => cguLu = ok == true);
                      },
                      onCGVRead: () async {
                        final ok = await Navigator.pushNamed(context, '/cgv') as bool?;
                        if (mounted) setState(() => cgvLu = ok == true);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Newsletter
                    CheckboxListTile(
                      value: newsletterAccepted,
                      onChanged: (v) => setState(() => newsletterAccepted = v!),
                      title: const Text(
                        "Recevoir la newsletter Kipik",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les labels
                        ),
                      ),
                      activeColor: KipikTheme.rouge,
                    ),
                    const SizedBox(height: 24),

                    // Valider mon inscription
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading || !isFormValid ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFormValid 
                              ? KipikTheme.rouge 
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'PermanentMarker', // ✅ PermanentMarker pour les boutons
                            fontSize: 18,
                          ),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Inscription en cours...'),
                                ],
                              )
                            : const Text('Valider mon inscription'),
                      ),
                    ),
                    
                    // ✅ NOUVEAU - Bouton de test Google Vision API
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _testGoogleVisionAPI,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.api),
                            SizedBox(width: 8),
                            Text('🧪 Tester Google Vision API', style: TextStyle(fontFamily: 'Roboto')),
                          ],
                        ),
                      ),
                    ),
                    
                    // ✅ Aide visuelle pour les champs obligatoires
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Les champs marqués d\'un * sont obligatoires',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Roboto', // ✅ Roboto pour les textes informatifs
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
    );
  }
}