// lib/widgets/auth/secure_login_form.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/auth/recaptcha_widget.dart';
import '../../services/auth/captcha_manager.dart';
import '../../services/auth/secure_auth_service.dart';
import '../../theme/kipik_theme.dart';

class SecureLoginForm extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final Function(String)? onError;

  const SecureLoginForm({
    Key? key,
    this.onLoginSuccess,
    this.onError,
  }) : super(key: key);

  @override
  State<SecureLoginForm> createState() => _SecureLoginFormState();
}

class _SecureLoginFormState extends State<SecureLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _captchaValidated = false;
  bool _showPassword = false;
  CaptchaResult? _captchaResult;
  Duration? _lockoutTime;

  // ✅ CORRECTION: Utiliser l'instance singleton
  SecureAuthService get _authService => SecureAuthService.instance;

  @override
  void initState() {
    super.initState();
    _checkLockoutStatus();
  }

  void _checkLockoutStatus() {
    // ✅ CORRECTION: Utiliser CaptchaManager pour le lockout
    final lockout = CaptchaManager.instance.getRemainingLockout(
      identifier: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo KIPIK
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Text(
              'KIPIK',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: KipikTheme.rouge,
                fontFamily: 'PermanentMarker',
              ),
            ),
          ),

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

          // Message de blocage si applicable
          if (_lockoutTime != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Compte temporairement bloqué',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Temps restant: ${_formatDuration(_lockoutTime!)}',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trop de tentatives de connexion échouées',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Champ Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: _lockoutTime == null && !_isLoading,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[900],
              labelStyle: TextStyle(color: Colors.grey[400]),
            ),
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Email requis';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                return 'Format email invalide';
              }
              return null;
            },
            onChanged: (value) {
              // ✅ Vérifier le lockout quand l'email change
              if (value.isNotEmpty && value.contains('@')) {
                _checkLockoutStatus();
              }
            },
          ),
          const SizedBox(height: 16),

          // Champ Mot de passe
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            enabled: _lockoutTime == null && !_isLoading,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[400],
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
            ),
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Mot de passe requis';
              if (value!.length < 6) return 'Minimum 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ✅ AMÉLIORÉ: Widget reCAPTCHA conditionnel avec meilleur feedback
          if (_shouldShowCaptcha()) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vérification de sécurité requise',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
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
            const SizedBox(height: 16),
          ],

          // Bouton de connexion
          ElevatedButton(
            onPressed: _canAttemptLogin() ? _handleLogin : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canAttemptLogin() ? KipikTheme.rouge : Colors.grey,
              foregroundColor: Colors.white,
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
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Connexion...'),
                    ],
                  )
                : const Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Lien mot de passe oublié
          TextButton(
            onPressed: _lockoutTime == null && !_isLoading ? _showForgotPasswordDialog : null,
            child: Text(
              'Mot de passe oublié ?',
              style: TextStyle(
                color: _lockoutTime == null ? KipikTheme.rouge : Colors.grey,
              ),
            ),
          ),

          // ✅ NOUVEAU: Informations de sécurité
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
    );
  }

  /// ✅ AMÉLIORÉ: Logique de vérification CAPTCHA
  bool _shouldShowCaptcha() {
    return CaptchaManager.instance.shouldShowCaptcha(
      'login',
      identifier: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    );
  }

  bool _canAttemptLogin() {
    if (_lockoutTime != null || _isLoading) return false;
    
    bool hasCredentials = _emailController.text.isNotEmpty && 
                         _passwordController.text.isNotEmpty;
    
    // Si CAPTCHA requis, vérifier qu'il est validé
    if (_shouldShowCaptcha()) {
      return hasCredentials && _captchaValidated;
    }
    
    return hasCredentials;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ✅ CORRECTION: Utiliser la bonne signature de méthode
      final user = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        captchaResult: _captchaResult,
      );

      if (user != null) {
        // ✅ Enregistrer le succès dans CaptchaManager
        CaptchaManager.instance.recordSuccessfulAttempt(
          'login',
          identifier: _emailController.text.trim(),
        );

        // Connexion réussie
        if (mounted) {
          widget.onLoginSuccess?.call();
        }
      } else {
        throw Exception('Identifiants incorrects');
      }

    } catch (e) {
      print('❌ Erreur connexion: $e');
      
      // ✅ Enregistrer l'échec dans CaptchaManager
      CaptchaManager.instance.recordFailedAttempt(
        'login',
        identifier: _emailController.text.trim(),
      );
      
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
      } else if (e.toString().contains('Identifiants incorrects')) {
        errorMessage = 'Email ou mot de passe incorrect';
      }
      
      if (mounted) {
        widget.onError?.call(errorMessage);
      }
      
      // Vérifier si bloqué après échec
      _checkLockoutStatus();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _captchaValidated = false; // ✅ Reset CAPTCHA après tentative
          _captchaResult = null;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Mot de passe oublié',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez votre adresse email pour recevoir un lien de réinitialisation.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _emailController.text,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[800],
                labelStyle: TextStyle(color: Colors.grey[400]),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter la réinitialisation avec reCAPTCHA
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonction de réinitialisation en cours de développement'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
            ),
            child: const Text(
              'Envoyer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}