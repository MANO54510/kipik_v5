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

  bool get isFormValid =>
      _formKey.currentState?.validate() == true &&
      cguLu &&
      cgvLu &&
      pieceIdentite != null &&
      dateNaissance != null; // ✅ Vérification date de naissance

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

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'PermanentMarker',
          color: Colors.black87,
        ),
        filled: true,
        fillColor: Colors.white,
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
        suffixIcon: label.toLowerCase().contains('mot de passe')
            ? IconButton(
                icon: Icon(
                  label == 'Mot de passe'
                      ? (showPassword ? Icons.visibility_off : Icons.visibility)
                      : (showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  color: KipikTheme.rouge,
                ),
                onPressed: () {
                  setState(() {
                    if (label == 'Mot de passe') {
                      showPassword = !showPassword;
                    } else {
                      showConfirmPassword = !showConfirmPassword;
                    }
                  });
                },
              )
            : null,
      );

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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Nom / Prénom
                    TextFormField(
                      controller: nomController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Nom *'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: prenomController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Prénom *'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),

                    // Adresse
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: numeroController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: _inputDecoration('N° *'),
                            validator: _requiredValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: rueController,
                            style: const TextStyle(color: Colors.black87),
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
                            style: const TextStyle(color: Colors.black87),
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Code postal *'),
                            validator: _requiredValidator,
                            onChanged: (v) {
                              final liste = villesParCodePostal[v.trim()];
                              setState(() {
                                villeController.text =
                                    (liste != null && liste.isNotEmpty)
                                        ? liste.first
                                        : '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: villeController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: _inputDecoration('Ville *'),
                            validator: _requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Téléphone
                    TextFormField(
                      controller: telController,
                      style: const TextStyle(color: Colors.black87),
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Téléphone *'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),

                    // Email
                    TextFormField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.black87),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Email *'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),

                    // Mot de passe
                    TextFormField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Mot de passe *'),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),

                    // Confirmer mot de passe
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !showConfirmPassword,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Confirmer mot de passe *'),
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 12),

                    // Date de naissance
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final pick = await showDatePicker(
                          context: context,
                          initialDate: dateNaissance ?? DateTime(now.year - 18),
                          firstDate: DateTime(1900),
                          lastDate: now,
                          locale: const Locale('fr', 'FR'),
                        );
                        if (pick != null) setState(() => dateNaissance = pick);
                      },
                      child: InputDecorator(
                        decoration: _inputDecoration('Date de naissance *'),
                        child: Text(
                          dateNaissance == null
                              ? 'Sélectionner votre date'
                              : '${dateNaissance!.day}/${dateNaissance!.month}/${dateNaissance!.year}',
                          style: TextStyle(
                            color: dateNaissance == null ? Colors.grey : Colors.black87,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pièce d'identité full-width
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final XFile? result = await openFile(
                            acceptedTypeGroups: [
                              XTypeGroup(
                                label: 'Images et PDF',
                                extensions: ['jpg', 'jpeg', 'png', 'pdf'],
                              )
                            ],
                          );
                          if (result != null) setState(() => pieceIdentite = result);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pieceIdentite != null 
                              ? Colors.green 
                              : KipikTheme.rouge,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontFamily: 'PermanentMarker',
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
                                    ? "Joindre ma pièce d'identité *"
                                    : "✓ Fichier : ${pieceIdentite!.name}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

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
                        style: TextStyle(color: Colors.white),
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