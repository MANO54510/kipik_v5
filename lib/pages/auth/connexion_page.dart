// lib/pages/auth/connexion_page.dart - Version sécurisée avec reCAPTCHA

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kipik_v5/pages/admin/admin_dashboard_home.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/auth/recaptcha_widget.dart';
import '../../theme/kipik_theme.dart';
import '../../services/auth/secure_auth_service.dart'; // ✅ CORRECTION
import '../../services/auth/captcha_manager.dart'; // ✅ CORRECTION
import '../particulier/accueil_particulier_page.dart';
import '../pro/home_page_pro.dart'; 
import '../organisateur/organisateur_dashboard_page.dart';
import 'inscription_page.dart';
import 'forgot_password_page.dart';
import 'package:kipik_v5/models/user_role.dart' as models;

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({Key? key}) : super(key: key);

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  
  // ✅ CORRECTION: Variables reCAPTCHA avec import correct
  bool _captchaValidated = false;
  CaptchaResult? _captchaResult;
  Duration? _lockoutTime;

  // ✅ CORRECTION: Services sécurisés
  SecureAuthService get _authService => SecureAuthService.instance;
  CaptchaManager get _captchaManager => CaptchaManager.instance;

  @override
  void initState() {
    super.initState();
    _checkLockoutStatus();
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  // ✅ CORRECTION: Utiliser CaptchaManager
  void _checkLockoutStatus() {
    final lockout = _captchaManager.getRemainingLockout(
      identifier: _emailC.text.trim().isEmpty ? null : _emailC.text.trim(),
    );
    
    if (lockout != null && lockout.inSeconds > 0) {
      setState(() => _lockoutTime = lockout);
      
      // Timer pour mettre à jour le temps restant
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _checkLockoutStatus();
      });
    } else {
      setState(() => _lockoutTime = null);
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return tr('login.validation.emailRequired');
    final reg = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!reg.hasMatch(v.trim())) return tr('login.validation.emailInvalid');
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return tr('login.validation.passwordRequired');
    if (v.length < 4) return tr('login.validation.passwordTooShort');
    return null;
  }

  // ✅ CORRECTION: Vérifier si le CAPTCHA est nécessaire
  bool _shouldShowCaptcha() {
    return _captchaManager.shouldShowCaptcha(
      'login',
      identifier: _emailC.text.trim().isEmpty ? null : _emailC.text.trim(),
    );
  }

  // ✅ NOUVEAU: Vérifier si la connexion est possible
  bool _canAttemptLogin() {
    if (_lockoutTime != null || _isLoading) return false;
    
    bool hasCredentials = _emailC.text.trim().isNotEmpty && 
                         _passC.text.isNotEmpty;
    
    // Si reCAPTCHA requis, vérifier qu'il est validé
    if (_shouldShowCaptcha()) {
      return hasCredentials && _captchaValidated;
    }
    
    return hasCredentials;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canAttemptLogin()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailC.text.trim();
      final pass = _passC.text.trim();
      
      // ✅ CORRECTION: Utiliser SecureAuthService directement
      final user = await _authService.signInWithEmailAndPassword(
        email,
        pass,
        captchaResult: _captchaResult,
      );

      if (user == null) {
        // ✅ Enregistrer l'échec
        _captchaManager.recordFailedAttempt('login', identifier: email);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('login.error.signInFailed')),
              backgroundColor: KipikTheme.rouge,
            ),
          );
          
          // Vérifier si maintenant bloqué après échec
          _checkLockoutStatus();
        }
        return;
      }

      // ✅ Enregistrer le succès
      _captchaManager.recordSuccessfulAttempt('login', identifier: email);

      if (!mounted) return;

      // ✅ CORRECTION: Récupérer le rôle depuis SecureAuthService
      final role = _authService.currentUserRole;
      
      if (role == null) {
        throw Exception('Impossible de déterminer le rôle utilisateur');
      }

      // Navigation selon le rôle
      Widget destination;
      switch (role) {
        case models.UserRole.client:
          destination = AccueilParticulierPage();
          break;
        case models.UserRole.tatoueur:
          destination = HomePagePro(); 
          break;
        case models.UserRole.admin:
          destination = const AdminDashboardHome();
          break;
        case models.UserRole.organisateur:
          destination = OrganisateurDashboardPage();
          break;
        default:
          destination = AccueilParticulierPage();
          print('⚠️ Rôle non reconnu: $role, redirection vers page client');
          break;
      }

      // Navigation avec remplacement
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );

    } catch (e) {
      print('❌ Erreur de connexion: $e');
      
      // ✅ Enregistrer l'échec
      _captchaManager.recordFailedAttempt('login', identifier: _emailC.text.trim());
      
      if (mounted) {
        String errorMessage = 'Erreur de connexion';
        
        // ✅ Messages d'erreur spécifiques
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'Aucun compte trouvé avec cet email';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Mot de passe incorrect';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Trop de tentatives. Réessayez plus tard.';
        } else if (e.toString().contains('Validation de sécurité')) {
          errorMessage = 'Validation de sécurité échouée';
        } else {
          errorMessage = 'Email ou mot de passe incorrect';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        _checkLockoutStatus();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // ✅ Reset CAPTCHA après tentative
          _captchaValidated = false;
          _captchaResult = null;
        });
      }
    }
  }

  // ✅ NOUVEAU: Formater la durée du blocage
  String _formatLockoutTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final bg = backgrounds[DateTime.now().millisecond % backgrounds.length];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBarKipik(
        title: tr('login.title'),
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bg, fit: BoxFit.cover),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: KipikTheme.rouge,
                      selectionColor: KipikTheme.rouge.withOpacity(0.4),
                      selectionHandleColor: KipikTheme.rouge,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/logo_kipik.png', width: 200),
                        const SizedBox(height: 30),

                        // ✅ NOUVEAU: Indicateur de sécurité
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.security, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Connexion sécurisée avec protection anti-bot',
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

                        // ✅ AMÉLIORÉ: Alerte de blocage si applicable
                        if (_lockoutTime != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.red, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_clock, 
                                     color: Colors.red, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Compte temporairement bloqué',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'PermanentMarker',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Temps restant: ${_formatLockoutTime(_lockoutTime!)}',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Trop de tentatives de connexion échouées',
                                        style: TextStyle(
                                          color: Colors.red[600],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // —– Email —–
                        TextFormField(
                          controller: _emailC,
                          enabled: !_isLoading && _lockoutTime == null,
                          cursorColor: KipikTheme.rouge,
                          validator: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            labelText: tr('login.emailLabel'),
                            labelStyle: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              color: Colors.black54,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: KipikTheme.rouge,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: KipikTheme.rouge,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: KipikTheme.rouge,
                            ),
                          ),
                          onChanged: (value) {
                            // ✅ Vérifier le lockout quand l'email change
                            if (value.isNotEmpty && value.contains('@')) {
                              _checkLockoutStatus();
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // —– Mot de passe —–
                        TextFormField(
                          controller: _passC,
                          enabled: !_isLoading && _lockoutTime == null,
                          obscureText: !_showPassword,
                          cursorColor: KipikTheme.rouge,
                          validator: _validatePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            labelText: tr('login.passwordLabel'),
                            labelStyle: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              color: Colors.black54,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: KipikTheme.rouge,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: KipikTheme.rouge,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: KipikTheme.rouge,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: KipikTheme.rouge,
                              ),
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ✅ CORRECTION: Widget reCAPTCHA conditionnel
                        if (_shouldShowCaptcha() && _lockoutTime == null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user, 
                                         color: Colors.orange, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Vérification de sécurité requise',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'PermanentMarker',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ReCaptchaWidget(
                                  action: 'login',
                                  useInvisible: true,
                                  onValidated: (result) {
                                    setState(() {
                                      _captchaValidated = result.isValid;
                                      _captchaResult = result;
                                    });
                                    
                                    if (result.isValid) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✅ Vérification de sécurité réussie'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // — Bouton "Se connecter" —
                        ElevatedButton(
                          onPressed: _canAttemptLogin() ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canAttemptLogin() 
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
                          child: SizedBox(
                            width: double.infinity,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : _lockoutTime != null
                                      ? Text('Bloqué (${_formatLockoutTime(_lockoutTime!)})')
                                      : Text(tr('login.submit')),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // — Liens —
                        TextButton(
                          onPressed: (_isLoading || _lockoutTime != null)
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const InscriptionPage(),
                                    ),
                                  ),
                          style: TextButton.styleFrom(
                            foregroundColor: (_isLoading || _lockoutTime != null) 
                                ? Colors.grey 
                                : KipikTheme.rouge,
                            textStyle: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 16,
                            ),
                          ),
                          child: Text(tr('login.signupPrompt')),
                        ),
                        TextButton(
                          onPressed: (_isLoading || _lockoutTime != null)
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ForgotPasswordPage(),
                                    ),
                                  ),
                          style: TextButton.styleFrom(
                            foregroundColor: (_isLoading || _lockoutTime != null) 
                                ? Colors.grey 
                                : KipikTheme.rouge,
                            textStyle: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 16,
                            ),
                          ),
                          child: Text(tr('login.forgotPassword')),
                        ),
                        
                        // ✅ NOUVEAU: Conseils de sécurité
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: Colors.blue, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Conseils de sécurité :',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• Utilisez un mot de passe unique pour Kipik\n'
                                '• Connectez-vous depuis un appareil de confiance\n'
                                '• Déconnectez-vous après usage sur appareil partagé',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
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
            ),
          ),
        ],
      ),
    );
  }
}