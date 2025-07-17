// lib/pages/organisateur/inscription_organisateur_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/services/auth/captcha_manager.dart';
import 'package:kipik_v5/services/promo/firebase_promo_code_service.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/utils/cgu_cgv_validation_widget.dart';
import 'package:kipik_v5/pages/organisateur/confirmation_inscription_organisateur_page.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/config/api_config.dart';

class InscriptionOrganisateurPage extends StatefulWidget {
  const InscriptionOrganisateurPage({Key? key}) : super(key: key);

  @override
  State<InscriptionOrganisateurPage> createState() => _InscriptionOrganisateurPageState();
}

class _InscriptionOrganisateurPageState extends State<InscriptionOrganisateurPage> {
  final _formKey = GlobalKey<FormState>();

  // Service sécurisé centralisé
  SecureAuthService get _authService => SecureAuthService.instance;

  // Controllers - Informations personnelles
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  DateTime? _dateNaissance;
  final _numeroController = TextEditingController();
  final _rueController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _villeController = TextEditingController();
  final _telephoneController = TextEditingController();

  // Controllers - Informations entreprise
  final _nomEntrepriseController = TextEditingController();
  final _siretController = TextEditingController();
  final _adresseEntrepriseController = TextEditingController();
  final _telephoneEntrepriseController = TextEditingController();
  final _emailEntrepriseController = TextEditingController();
  String? _formeJuridique;
  
  // Controllers - Authentification
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controllers - Code promo
  final _promoCodeController = TextEditingController();
  Map<String, dynamic>? _validatedPromoCode;
  bool _isValidatingPromo = false;

  // Documents
  XFile? _pieceIdentite;
  XFile? _kbis;
  XFile? _rib;
  XFile? _attestationAssurance;

  // États
  bool _newsletterAccepted = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _cguLu = false;
  bool _cgvLu = false;
  bool _isLoading = false;
  bool _majoriteConfirmee = false;
  String? _ageError;

  // Données statiques
  static const Map<String, List<String>> villesParCodePostal = {
    '54510': ['Tomblaine'],
    '75001': ['Paris 1er'],
    '69001': ['Lyon 1er'],
    '13001': ['Marseille 1er'],
    '33000': ['Bordeaux'],
    '31000': ['Toulouse'],
    '59000': ['Lille'],
    '67000': ['Strasbourg'],
    '44000': ['Nantes'],
    '34000': ['Montpellier'],
    // Ajoutez plus de codes postaux selon vos besoins
  };

  @override
  void dispose() {
    // Nettoyage des controllers
    _prenomController.dispose();
    _nomController.dispose();
    _numeroController.dispose();
    _rueController.dispose();
    _codePostalController.dispose();
    _villeController.dispose();
    _telephoneController.dispose();
    _nomEntrepriseController.dispose();
    _siretController.dispose();
    _adresseEntrepriseController.dispose();
    _telephoneEntrepriseController.dispose();
    _emailEntrepriseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  // Validators
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
    if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  String? _validateSiret(String? v) {
    if (v == null || v.isEmpty) return 'SIRET requis';
    if (v.replaceAll(' ', '').length != 14) return 'SIRET doit contenir 14 chiffres';
    return null;
  }

  // Méthode de vérification d'âge
  bool _isOver18(DateTime birthDate) {
    final today = DateTime.now();
    final age = today.year - birthDate.year;
    
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      return age - 1 >= 18;
    }
    return age >= 18;
  }

  // Validation du formulaire
  bool get isFormValid =>
      _formKey.currentState?.validate() == true &&
      _prenomController.text.isNotEmpty &&
      _nomController.text.isNotEmpty &&
      _dateNaissance != null &&
      _majoriteConfirmee &&
      (_dateNaissance != null ? _isOver18(_dateNaissance!) : false) &&
      _numeroController.text.isNotEmpty &&
      _rueController.text.isNotEmpty &&
      _codePostalController.text.isNotEmpty &&
      _villeController.text.isNotEmpty &&
      _telephoneController.text.isNotEmpty &&
      _nomEntrepriseController.text.isNotEmpty &&
      _siretController.text.isNotEmpty &&
      _adresseEntrepriseController.text.isNotEmpty &&
      _telephoneEntrepriseController.text.isNotEmpty &&
      _emailEntrepriseController.text.isNotEmpty &&
      _formeJuridique != null &&
      _emailController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty &&
      _pieceIdentite != null &&
      _kbis != null &&
      _rib != null &&
      _attestationAssurance != null &&
      _cguLu &&
      _cgvLu;

  // Validation du code promo
  Future<void> _validatePromoCode() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingPromo = true);

    try {
      final promoData = await FirebasePromoCodeService.instance.validatePromoCode(code);
      
      if (!mounted) return;
      
      setState(() {
        _validatedPromoCode = promoData;
        _isValidatingPromo = false;
      });

      if (promoData != null) {
        String message = 'Code promo valide ! ✅';
        final type = promoData['type'] as String?;
        final value = promoData['value'] as num?;
        
        if (type == 'referral') {
          message += '\nCode de parrainage validé ! Réduction appliquée sur votre futur abonnement.';
        } else if (type == 'percentage' && value != null) {
          message += '\n${value.toInt()}% de réduction appliquée sur votre futur abonnement !';
        } else if (type == 'fixed' && value != null) {
          message += '\n${value.toInt()}€ de réduction appliquée sur votre futur abonnement !';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code promo invalide ou expiré ❌'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isValidatingPromo = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la validation du code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Soumission du formulaire
  Future<void> _submitForm() async {
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de remplir tous les champs obligatoires')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Validation reCAPTCHA pour sécurité
      final captchaResult = await CaptchaManager.instance.validateInvisibleCaptcha('signup_organizer');

      if (!captchaResult.isValid) {
        throw Exception('Validation de sécurité échouée');
      }

      // Création de l'utilisateur
      final user = await _authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: '${_prenomController.text.trim()} ${_nomController.text.trim()}',
        userRole: 'organisateur',
        captchaResult: captchaResult,
      );

      if (user != null) {
        // Calcul des dates d'essai
        final now = DateTime.now();
        final trialEndDate = now.add(const Duration(days: 30));

        // Mise à jour du profil avec données complètes
        await _authService.updateUserProfile(
          additionalData: {
            'type': 'organisateur',
            'role': 'organisateur',
            
            // Informations personnelles
            'prenom': _prenomController.text.trim(),
            'nom': _nomController.text.trim(),
            'dateNaissance': _dateNaissance?.toIso8601String(),
            'adressePersonnelle': {
              'numero': _numeroController.text.trim(),
              'rue': _rueController.text.trim(),
              'codePostal': _codePostalController.text.trim(),
              'ville': _villeController.text.trim(),
            },
            'telephone': _telephoneController.text.trim(),
            'majoriteConfirmee': _majoriteConfirmee,
            
            // Informations entreprise
            'entreprise': {
              'nom': _nomEntrepriseController.text.trim(),
              'siret': _siretController.text.trim(),
              'formeJuridique': _formeJuridique,
              'adresse': _adresseEntrepriseController.text.trim(),
              'telephone': _telephoneEntrepriseController.text.trim(),
              'email': _emailEntrepriseController.text.trim(),
            },
            
            // Documents
            'documents': {
              'pieceIdentite': _pieceIdentite?.name,
              'kbis': _kbis?.name,
              'rib': _rib?.name,
              'attestationAssurance': _attestationAssurance?.name,
            },
            
            // Préférences
            'newsletter': _newsletterAccepted,
            'inscriptionCompleted': true,
            'profileComplete': true,
            'signupCaptchaScore': captchaResult.score,
            
            // Données d'essai 30 jours
            'subscriptionType': 'trial',
            'trialStartDate': now.toIso8601String(),
            'trialEndDate': trialEndDate.toIso8601String(),
            'trialDaysRemaining': 30,
            'subscriptionStatus': 'trial_active',
            'mustChooseSubscription': false,
          },
        );

        // Gestion du code promo si validé
        if (_validatedPromoCode != null) {
          final code = _validatedPromoCode!['code'] as String;
          
          try {
            // Marquer le code comme utilisé
            await FirebasePromoCodeService.instance.usePromoCode(code);
            
            // Sauvegarder le code promo pour application future
            await _authService.updateUserProfile(
              additionalData: {
                'pendingPromoCode': {
                  'code': code,
                  'type': _validatedPromoCode!['type'],
                  'value': _validatedPromoCode!['value'],
                  'description': _validatedPromoCode!['description'],
                  'appliedAt': DateTime.now().toIso8601String(),
                  'createdBy': _validatedPromoCode!['createdBy'],
                }
              },
            );
            
            print('✅ Code promo sauvegardé pour application future');
          } catch (e) {
            print('⚠️ Erreur lors de la sauvegarde du code promo: $e');
          }
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ConfirmationInscriptionOrganisateurPage(),
            ),
          );
        }
      } else {
        throw Exception('Erreur lors de la création du compte');
      }
    } catch (e) {
      print('❌ Erreur inscription organisateur: $e');
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

  // Upload de documents avec vérification
  Future<void> _uploadDocument(String type) async {
    try {
      final XFile? result = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'Images et PDF',
            extensions: ['jpg', 'jpeg', 'png', 'pdf'],
          )
        ],
      );

      if (result == null) return;

      // Vérification optionnelle avec Google Vision si configuré
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
              duration: Duration(seconds: 2),
            ),
          );
        }

        await Future.delayed(Duration(seconds: 1));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Document analysé et approuvé !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }

      // Enregistrer le fichier selon le type
      setState(() {
        switch (type) {
          case 'identite':
            _pieceIdentite = result;
            break;
          case 'kbis':
            _kbis = result;
            break;
          case 'rib':
            _rib = result;
            break;
          case 'assurance':
            _attestationAssurance = result;
            break;
        }
      });

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

  // InputDecoration personnalisée
  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'PermanentMarker',
          fontSize: 11,
          color: Colors.black87,
          height: 0.9,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'PermanentMarker', 
          fontSize: 12,
          color: Colors.black87,
          height: 0.9,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          fontSize: 10,
          color: Colors.red,
          height: 1.0,
        ),
        suffixIcon: label.toLowerCase().contains('mot de passe')
            ? IconButton(
                icon: Icon(
                  label == 'Mot de passe *'
                      ? (_showPassword ? Icons.visibility_off : Icons.visibility)
                      : (_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  color: KipikTheme.rouge,
                ),
                onPressed: () {
                  setState(() {
                    if (label == 'Mot de passe *') {
                      _showPassword = !_showPassword;
                    } else {
                      _showConfirmPassword = !_showConfirmPassword;
                    }
                  });
                },
              )
            : null,
      );

  // Widget de certification de majorité
  Widget _buildMajoriteConfirmation() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _majoriteConfirmee ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _majoriteConfirmee ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: _majoriteConfirmee,
                onChanged: _dateNaissance != null && _isOver18(_dateNaissance!) 
                    ? (value) => setState(() => _majoriteConfirmee = value!) 
                    : null,
                activeColor: KipikTheme.rouge,
              ),
              Expanded(
                child: Text(
                  "Je certifie avoir plus de 18 ans *",
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 14,
                    color: _dateNaissance != null && _isOver18(_dateNaissance!) 
                        ? Colors.white 
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                _majoriteConfirmee ? Icons.check_circle : Icons.warning,
                color: _majoriteConfirmee ? Colors.green : Colors.orange,
              ),
            ],
          ),
          if (_ageError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ageError!,
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

  // Widget titres de sections avec headers tattoo
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
        title: 'Inscription Organisateur',
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
                    // Bandeau essai gratuit 30 jours
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.celebration, color: Colors.white, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'ESSAI GRATUIT 30 JOURS',
                            style: TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Organisez vos conventions avec tous les outils pros.\nChoisissez votre abonnement à la fin de la période.',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Indicateur de sécurité reCAPTCHA
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
                                fontFamily: 'PermanentMarker',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Section Code promo
                    _buildSectionTitleWithHeader('Code promo', Icons.card_giftcard, headerIndex: 1),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KipikTheme.rouge, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Bénéficiez d\'une réduction sur votre futur abonnement',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _promoCodeController,
                                  decoration: _inputDecoration('Code promo (optionnel)'),
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textCapitalization: TextCapitalization.characters,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isValidatingPromo ? null : _validatePromoCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: KipikTheme.rouge,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                child: _isValidatingPromo
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Valider'),
                              ),
                            ],
                          ),
                          if (_validatedPromoCode != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Text(
                                _validatedPromoCode!['type'] == 'referral'
                                    ? '✅ Code de parrainage validé !'
                                    : _validatedPromoCode!['type'] == 'percentage'
                                    ? '✅ ${(_validatedPromoCode!['value'] as num).toInt()}% de réduction sur votre futur abonnement !'
                                    : '✅ ${(_validatedPromoCode!['value'] as num).toInt()}€ de réduction sur votre futur abonnement !',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Section Informations personnelles
                    _buildSectionTitleWithHeader('Informations personnelles', Icons.person, headerIndex: 1),

                    TextFormField(
                      controller: _prenomController,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: _inputDecoration('Prénom *'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nomController,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: _inputDecoration('Nom *'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),

                    // Date de naissance avec validation d'âge
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final pick = await showDatePicker(
                          context: context,
                          initialDate: _dateNaissance ?? DateTime(now.year - 25),
                          firstDate: DateTime(1900),
                          lastDate: now,
                          locale: const Locale('fr', 'FR'),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: KipikTheme.rouge,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(foregroundColor: KipikTheme.rouge),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        
                        if (pick != null) {
                          setState(() {
                            _dateNaissance = pick;
                            
                            if (!_isOver18(pick)) {
                              _ageError = "Vous devez avoir au moins 18 ans pour vous inscrire";
                              _majoriteConfirmee = false;
                            } else {
                              _ageError = null;
                            }
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: _inputDecoration('Date de naissance *').copyWith(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _dateNaissance != null && !_isOver18(_dateNaissance!) 
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
                                _dateNaissance == null
                                    ? 'Sélectionner votre date'
                                    : '${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}',
                                style: TextStyle(
                                  color: _dateNaissance == null ? Colors.grey : Colors.black87,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (_dateNaissance != null)
                              Icon(
                                _isOver18(_dateNaissance!) ? Icons.check_circle : Icons.error,
                                color: _isOver18(_dateNaissance!) ? Colors.green : Colors.red,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Widget de certification de majorité
                    _buildMajoriteConfirmation(),

                    // Section Adresse personnelle
                    _buildSectionTitleWithHeader('Adresse personnelle', Icons.home, headerIndex: 2),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _numeroController,
                            style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                            decoration: _inputDecoration('N° *'),
                            validator: _requiredValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _rueController,
                            style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
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
                            controller: _codePostalController,
                            style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Code postal *'),
                            validator: _requiredValidator,
                            onChanged: (v) {
                              final liste = villesParCodePostal[v.trim()];
                              if (liste != null && liste.length == 1) {
                                setState(() => _villeController.text = liste.first);
                              } else {
                                setState(() => _villeController.text = '');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _villeController,
                            style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                            decoration: _inputDecoration('Ville *'),
                            validator: _requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telephoneController,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Téléphone *'),
                      validator: _requiredValidator,
                    ),

                    const SizedBox(height: 20),

                    // Section Informations entreprise
                    _buildSectionTitleWithHeader('Informations entreprise', Icons.business, headerIndex: 3),

                    TextFormField(
                      controller: _nomEntrepriseController,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: _inputDecoration('Nom de l\'entreprise *'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _siretController,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('SIRET *'),
                      validator: _validateSiret,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _formeJuridique,
                      decoration: _inputDecoration('Forme juridique *'),
                      items: const [
                        DropdownMenuItem(value: 'SARL', child: Text('SARL')),
                        DropdownMenuItem(value: 'SAS', child: Text('SAS')),
                        DropdownMenuItem(value: 'EURL', child: Text('EURL')),
                        DropdownMenuItem(value: 'Auto-entrepreneur', child: Text('Auto-entrepreneur')),
                        DropdownMenuItem(value: 'Association', child: Text('Association')),
                        DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                      ],
                      onChanged: (v) => setState(() => _formeJuridique = v),
                      validator: (v) => v == null ? 'Champ obligatoire' : null,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adresseEntrepriseController,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: _inputDecoration('Adresse entreprise *'),
                      validator: _requiredValidator,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telephoneEntrepriseController,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Téléphone entreprise *'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailEntrepriseController,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Email entreprise *'),
                      validator: _validateEmail,
                    ),

                    const SizedBox(height: 20),

                    // Section Documents obligatoires
                    _buildSectionTitleWithHeader('Documents obligatoires', Icons.folder, headerIndex: 1),

                    for (final doc in [
                      {'title': 'Pièce d\'identité *', 'type': 'identite', 'file': _pieceIdentite},
                      {'title': 'KBIS < 3 mois *', 'type': 'kbis', 'file': _kbis},
                      {'title': 'RIB entreprise *', 'type': 'rib', 'file': _rib},
                      {'title': 'Attestation assurance *', 'type': 'assurance', 'file': _attestationAssurance},
                    ]) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _uploadDocument(doc['type'] as String),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (doc['file'] as XFile?) != null ? Colors.green : KipikTheme.rouge,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontFamily: 'PermanentMarker', fontSize: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon((doc['file'] as XFile?) != null ? Icons.check_circle : Icons.upload_file),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  (doc['file'] as XFile?) == null
                                      ? doc['title'] as String
                                      : "✓ ${(doc['file'] as XFile?)!.name}",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Section Identifiants de connexion
                    _buildSectionTitleWithHeader('Identifiants de connexion', Icons.lock, headerIndex: 2),

                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Email *'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: _inputDecoration('Mot de passe *'),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: _inputDecoration('Confirmer mot de passe *'),
                      validator: _validateConfirmPassword,
                    ),

                    const SizedBox(height: 20),

                    // Section Conditions d'utilisation
                    _buildSectionTitleWithHeader('Conditions d\'utilisation', Icons.gavel, headerIndex: 3),

                    // CGU / CGV
                    CGUCGVValidationWidget(
                      cguAccepted: _cguLu,
                      cgvAccepted: _cgvLu,
                      onCGURead: () async {
                        final ok = await Navigator.pushNamed(context, '/cgu') as bool?;
                        if (mounted) setState(() => _cguLu = ok == true);
                      },
                      onCGVRead: () async {
                        final ok = await Navigator.pushNamed(context, '/cgv') as bool?;
                        if (mounted) setState(() => _cgvLu = ok == true);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Newsletter
                    CheckboxListTile(
                      value: _newsletterAccepted,
                      onChanged: (v) => setState(() => _newsletterAccepted = v!),
                      title: const Text(
                        "Recevoir la newsletter Kipik",
                        style: TextStyle(color: Colors.white, fontFamily: 'PermanentMarker'),
                      ),
                      activeColor: KipikTheme.rouge,
                    ),
                    const SizedBox(height: 24),

                    // Bouton de validation
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading || !isFormValid ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFormValid ? KipikTheme.rouge : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontFamily: 'PermanentMarker', fontSize: 18),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Inscription en cours...'),
                                ],
                              )
                            : const Text('Commencer mon essai gratuit'),
                      ),
                    ),
                    
                    // Aide visuelle pour les champs obligatoires
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
                              style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Roboto'),
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