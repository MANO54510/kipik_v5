// lib/pages/organisateur/inscription_organisateur_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/utils/cgu_cgv_validation_widget.dart';
import 'package:kipik_v5/pages/organisateur/confirmation_inscription_organisateur_page.dart'; // ✅ AJOUT
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/services/auth/captcha_manager.dart';

class InscriptionOrganisateurPage extends StatefulWidget {
  const InscriptionOrganisateurPage({Key? key}) : super(key: key);

  @override
  _InscriptionOrganisateurPageState createState() => _InscriptionOrganisateurPageState();
}

class _InscriptionOrganisateurPageState extends State<InscriptionOrganisateurPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailProController = TextEditingController();
  final _websiteController = TextEditingController();
  
  bool _isLoading = false;
  bool cguLu = false;
  bool cgvLu = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  
  // ✅ Variables pour la vérification d'âge
  DateTime? dateNaissance;
  bool majoriteConfirmee = false;
  String? ageError;
  
  // ✅ Service sécurisé
  SecureAuthService get _authService => SecureAuthService.instance;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailProController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  // ✅ Méthode de vérification d'âge
  bool _isOver18(DateTime birthDate) {
    final today = DateTime.now();
    final age = today.year - birthDate.year;
    
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      return age - 1 >= 18;
    }
    return age >= 18;
  }

  // ✅ Validation avec vérification d'âge
  bool get isFormValid =>
      _formKey.currentState?.validate() == true &&
      dateNaissance != null &&
      majoriteConfirmee &&
      (dateNaissance != null ? _isOver18(dateNaissance!) : false) &&
      cguLu &&
      cgvLu;

  Future<void> _submitForm() async {
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de remplir tous les champs obligatoires')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // ✅ Validation reCAPTCHA
      final captchaResult = await CaptchaManager.instance.validateInvisibleCaptcha('signup');

      if (!captchaResult.isValid) {
        throw Exception('Validation de sécurité échouée');
      }

      // ✅ Création du compte
      final user = await _authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
        userRole: 'organisateur',
        captchaResult: captchaResult,
      );

      if (user != null) {
        // ✅ Mise à jour du profil
        await _authService.updateUserProfile(
          additionalData: {
            'type': 'organisateur',
            'nom': _nameController.text.trim(),
            'company': _companyController.text.trim(),
            'phone': _phoneController.text.trim(),
            'emailPro': _emailProController.text.trim(),
            'website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
            'dateNaissance': dateNaissance?.toIso8601String(),
            'majoriteConfirmee': majoriteConfirmee,
            'inscriptionCompleted': true,
            'profileComplete': true,
            'organizerStatus': 'pending_verification',
            'signupCaptchaScore': captchaResult.score,
            'cguAccepted': true,
            'cgvAccepted': true,
            'signupDate': DateTime.now().toIso8601String(),
            
            // ✅ Données métier spécifiques organisateur
            'organizerProfile': {
              'companyName': _companyController.text.trim(),
              'contactPhone': _phoneController.text.trim(),
              'emailPro': _emailProController.text.trim(),
              'website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
              'verificationStatus': 'pending',
              'canCreateEvents': false,
              'maxEventsPerMonth': 0,
            },
          },
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ConfirmationInscriptionOrganisateurPage(), // ✅ CHANGEMENT: Vers page de confirmation
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
    if (v.length < 8) return '8 caractères minimum';
    
    bool hasUppercase = v.contains(RegExp(r'[A-Z]'));
    bool hasDigits = v.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (!hasUppercase || !hasDigits || !hasSpecialCharacters) {
      return 'Majuscule, chiffre et caractère spécial requis';
    }
    
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  String? _validateWebsite(String? v) {
    if (v == null || v.isEmpty) return null; // Optionnel
    
    final websiteRegex = RegExp(
      r'^(https?://)?(www\.)?[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+(/.*)?$'
    );
    
    if (!websiteRegex.hasMatch(v.trim())) {
      return 'Format de site web invalide';
    }
    
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Champ obligatoire';
    
    final phoneRegex = RegExp(r'^(\+33|0)[1-9]([0-9]{8})$|^\+[1-9]\d{1,14}$');
    final cleanPhone = v.replaceAll(RegExp(r'[\s\-\(\)\.]+'), '');
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Numéro de téléphone invalide';
    }
    
    return null;
  }

  // ✅ InputDecoration optimisé
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, 
          vertical: 18,
        ),
        isDense: true,
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

  // ✅ Widget certification de majorité
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
                    : null,
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
          if (ageError != null)
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // ✅ Background aléatoire
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
                    // ✅ Indicateur de sécurité reCAPTCHA
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

                    // ✅ Section Informations personnelles avec header tattoo
                    _buildSectionTitleWithHeader('Informations personnelles', Icons.person, headerIndex: 1),

                    // Nom et prénom
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      decoration: _inputDecoration('Nom et prénom *'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Champ obligatoire';
                        }
                        if (value.trim().split(' ').length < 2) {
                          return 'Veuillez entrer votre nom et prénom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Date de naissance avec validation d'âge
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final pick = await showDatePicker(
                          context: context,
                          initialDate: dateNaissance ?? DateTime(now.year - 25),
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
                                  style: TextButton.styleFrom(
                                    foregroundColor: KipikTheme.rouge,
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
                            
                            if (!_isOver18(pick)) {
                              ageError = "Vous devez avoir au moins 18 ans pour vous inscrire";
                              majoriteConfirmee = false;
                            } else {
                              ageError = null;
                            }
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: _inputDecoration('Date de naissance *').copyWith(
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
                                  fontFamily: 'Roboto',
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

                    // Widget de certification de majorité
                    _buildMajoriteConfirmation(),
                    const SizedBox(height: 20),

                    // ✅ Section Informations professionnelles avec header tattoo
                    _buildSectionTitleWithHeader('Informations professionnelles', Icons.business, headerIndex: 2),

                    // Nom de la compagnie
                    TextFormField(
                      controller: _companyController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      decoration: _inputDecoration('Nom de la compagnie *'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),

                    // Numéro professionnel
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Numéro professionnel *'),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 12),

                    // Email professionnel
                    TextFormField(
                      controller: _emailProController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Email professionnel *'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),

                    // Site web professionnel
                    TextFormField(
                      controller: _websiteController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      keyboardType: TextInputType.url,
                      decoration: _inputDecoration('Site web professionnel (optionnel)'),
                      validator: _validateWebsite,
                    ),
                    const SizedBox(height: 20),

                    // ✅ Section Sécurité avec header tattoo
                    _buildSectionTitleWithHeader('Sécurité', Icons.lock, headerIndex: 3),

                    // Email de connexion
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Email de connexion *'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),

                    // Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      decoration: _inputDecoration('Mot de passe *'),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),

                    // Confirmer mot de passe
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      decoration: _inputDecoration('Confirmer mot de passe *'),
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 20),

                    // ✅ Section Conditions avec header tattoo
                    _buildSectionTitleWithHeader('Conditions d\'utilisation', Icons.gavel, headerIndex: 1),

                    // ✅ CGU / CGV avec widget de validation
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
                    const SizedBox(height: 24),

                    // Valider inscription
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
                            fontFamily: 'PermanentMarker',
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

                    // ✅ Aide visuelle
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
                                fontFamily: 'Roboto',
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