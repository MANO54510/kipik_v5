// lib/pages/organisateur/inscription_organisateur_page.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ MIGRATION
import 'package:kipik_v5/services/auth/captcha_manager.dart'; // ✅ SÉCURITÉ

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
  final _websiteController = TextEditingController();
  
  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _acceptPrivacyPolicy = false; // ✅ NOUVEAU: Politique de confidentialité
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  
  // ✅ MIGRATION: Service sécurisé centralisé
  SecureAuthService get _authService => SecureAuthService.instance;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  /// ✅ Validation complète du formulaire
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    
    if (!_acceptTerms) {
      _showError(tr('signup.acceptTermsError'));
      return false;
    }
    
    if (!_acceptPrivacyPolicy) {
      _showError('Vous devez accepter la politique de confidentialité');
      return false;
    }
    
    // ✅ Validation supplémentaire du site web
    if (_websiteController.text.isNotEmpty) {
      final website = _websiteController.text.trim();
      if (!RegExp(r'^https?://').hasMatch(website) && !RegExp(r'^www\.').hasMatch(website)) {
        _showError('Le site web doit commencer par http://, https:// ou www.');
        return false;
      }
    }
    
    return true;
  }

  /// ✅ Afficher une erreur
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// ✅ Afficher un succès
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _register() async {
    if (!_validateForm()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // ✅ SÉCURITÉ: Validation reCAPTCHA pour inscription organisateur
      final captchaResult = await CaptchaManager.instance.validateUserAction(
        action: 'signup',
        context: context,
      );

      if (!captchaResult.isValid) {
        throw Exception('Validation de sécurité échouée - Score: ${captchaResult.score.toStringAsFixed(2)}');
      }

      // ✅ MIGRATION: Nouvelle méthode SecureAuthService
      final user = await _authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
        userRole: 'organisateur', // ✅ Rôle explicite
        captchaResult: captchaResult,
      );

      if (user != null) {
        // ✅ MIGRATION: Mise à jour du profil avec données organisateur
        await _authService.updateUserProfile(
          additionalData: {
            'type': 'organisateur',
            'company': _companyController.text.trim(),
            'phone': _phoneController.text.trim(),
            'website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
            'inscriptionCompleted': true,
            'profileComplete': true,
            'organizerStatus': 'pending_verification', // ✅ Statut en attente de vérification
            'signupCaptchaScore': captchaResult.score,
            'termsAccepted': true,
            'privacyPolicyAccepted': true,
            'signupDate': DateTime.now().toIso8601String(),
            
            // ✅ Données métier spécifiques organisateur
            'organizerProfile': {
              'companyName': _companyController.text.trim(),
              'contactPhone': _phoneController.text.trim(),
              'website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
              'verificationStatus': 'pending',
              'canCreateEvents': false, // ✅ Activé après vérification
              'maxEventsPerMonth': 0,
            },
          },
        );

        if (mounted) {
          _showSuccess('✅ Inscription réussie ! Votre compte est en cours de vérification.');
          
          // ✅ Redirection vers dashboard organisateur avec délai
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/organisateur/dashboard', 
                (route) => false,
              );
            }
          });
        }
      } else {
        throw Exception('Échec de la création du compte');
      }
    } catch (e) {
      print('❌ Erreur inscription organisateur: $e');
      
      String errorMessage = '❌ Échec de l\'inscription, réessayez plus tard.';
      
      // ✅ Messages d'erreur spécifiques
      if (e.toString().contains('Validation de sécurité')) {
        errorMessage = '❌ Validation de sécurité échouée. Réessayez dans quelques minutes.';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = '❌ Cette adresse email est déjà utilisée.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = '❌ Le mot de passe est trop faible.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = '❌ L\'adresse email n\'est pas valide.';
      }
      
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// ✅ NOUVEAU: Validation en temps réel du mot de passe
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return tr('validation.required');
    }
    if (value.length < 8) {
      return tr('validation.passwordTooShort');
    }
    
    // ✅ Validation renforcée pour organisateurs
    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (!hasUppercase || !hasDigits || !hasSpecialCharacters) {
      return 'Le mot de passe doit contenir: majuscule, chiffre et caractère spécial';
    }
    
    return null;
  }

  /// ✅ NOUVEAU: Validation du site web
  String? _validateWebsite(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }
    
    final websiteRegex = RegExp(
      r'^(https?://)?(www\.)?[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+(/.*)?$'
    );
    
    if (!websiteRegex.hasMatch(value.trim())) {
      return 'Format de site web invalide';
    }
    
    return null;
  }

  /// ✅ NOUVEAU: Validation du téléphone
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return tr('validation.required');
    }
    
    // ✅ Validation téléphone français et international
    final phoneRegex = RegExp(r'^(\+33|0)[1-9]([0-9]{8})$|^\+[1-9]\d{1,14}$');
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)\.]+'), '');
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Numéro de téléphone invalide';
    }
    
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBarKipik(
        title: tr('signup.organisateurTitle'),
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background_charbon.png',
            fit: BoxFit.cover,
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ NOUVEAU: Indicateur de sécurité
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.security, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Inscription sécurisée avec validation reCAPTCHA',
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
                    
                    Text(
                      tr('signup.organisateurIntro'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Informations de base
                    Text(
                      tr('signup.basicInfo'),
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        color: KipikTheme.rouge,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: tr('signup.email'),
                        prefixIcon: const Icon(Icons.email, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation.required');
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return tr('validation.invalidEmail');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: tr('signup.password'),
                        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        helperText: '8+ caractères, majuscule, chiffre, caractère spécial',
                        helperStyle: const TextStyle(color: Colors.orange, fontSize: 11),
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: !_showPassword,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),
                    
                    // Confirmation mot de passe
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: tr('signup.confirmPassword'),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: !_showConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation.required');
                        }
                        if (value != _passwordController.text) {
                          return tr('validation.passwordsDoNotMatch');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Informations sur l'organisateur
                    Text(
                      tr('signup.organisateurInfo'),
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        color: KipikTheme.rouge,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nom complet
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: tr('signup.fullName'),
                        prefixIcon: const Icon(Icons.person, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation.required');
                        }
                        if (value.trim().split(' ').length < 2) {
                          return 'Veuillez entrer votre nom et prénom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Nom de l'entreprise
                    TextFormField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: tr('signup.companyName'),
                        prefixIcon: const Icon(Icons.business, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation.required');
                        }
                        if (value.trim().length < 2) {
                          return 'Le nom de l\'entreprise doit faire au moins 2 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Numéro de téléphone
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: tr('signup.phoneNumber'),
                        prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        helperText: 'Format: +33123456789 ou 0123456789',
                        helperStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 12),
                    
                    // Site web
                    TextFormField(
                      controller: _websiteController,
                      decoration: InputDecoration(
                        labelText: tr('signup.website') + ' ' + tr('common.optional'),
                        prefixIcon: const Icon(Icons.language, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        helperText: 'Ex: https://monsite.com ou www.monsite.com',
                        helperStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.url,
                      validator: _validateWebsite,
                    ),
                    const SizedBox(height: 24),
                    
                    // ✅ NOUVEAU: Note de vérification
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Votre compte sera vérifié avant d\'organiser des événements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Conditions d'utilisation
                    CheckboxListTile(
                      title: Text(
                        tr('signup.acceptTerms'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      checkColor: Colors.black,
                      activeColor: KipikTheme.rouge,
                    ),
                    
                    // ✅ NOUVEAU: Politique de confidentialité
                    CheckboxListTile(
                      title: const Text(
                        'J\'accepte la politique de confidentialité',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _acceptPrivacyPolicy,
                      onChanged: (value) {
                        setState(() {
                          _acceptPrivacyPolicy = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      checkColor: Colors.black,
                      activeColor: KipikTheme.rouge,
                    ),
                    const SizedBox(height: 24),
                    
                    // Bouton d'inscription
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading ? Colors.grey : KipikTheme.rouge,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Inscription en cours...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                tr('signup.submit'),
                                style: const TextStyle(
                                  fontFamily: 'PermanentMarker',
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    
                    // ✅ NOUVEAU: Informations supplémentaires
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'En tant qu\'organisateur, vous pourrez :',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('• Créer et gérer des conventions de tatouage', style: TextStyle(color: Colors.white70)),
                          Text('• Gérer les inscriptions et la billetterie', style: TextStyle(color: Colors.white70)),
                          Text('• Promouvoir vos événements', style: TextStyle(color: Colors.white70)),
                          Text('• Accéder aux outils de marketing', style: TextStyle(color: Colors.white70)),
                          Text('• Obtenir des analyses détaillées', style: TextStyle(color: Colors.white70)),
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