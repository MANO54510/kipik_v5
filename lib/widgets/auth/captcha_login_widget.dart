// lib/widgets/auth/captcha_login_widget.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/services/auth/captcha_manager.dart';
import 'package:kipik_v5/utils/auth_helper.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class CaptchaLoginWidget extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final Function(String)? onError;
  final String? initialEmail;
  final String? initialPassword;

  const CaptchaLoginWidget({
    Key? key,
    this.onLoginSuccess,
    this.onError,
    this.initialEmail,
    this.initialPassword,
  }) : super(key: key);

  @override
  State<CaptchaLoginWidget> createState() => _CaptchaLoginWidgetState();
}

class _CaptchaLoginWidgetState extends State<CaptchaLoginWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  
  bool _isLoading = false;
  Duration? _lockoutTime;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _passwordController = TextEditingController(text: widget.initialPassword);
    _checkLockoutStatus();
  }

  void _checkLockoutStatus() {
    final lockout = CaptchaManager.instance.getRemainingLockout();
    if (lockout != null) {
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
          // Message de blocage si applicable
          if (_lockoutTime != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_clock, color: Colors.red),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
            enabled: _lockoutTime == null,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Email requis';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                return 'Format email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Champ Mot de passe
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            enabled: _lockoutTime == null,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Mot de passe requis';
              if (value!.length < 6) return 'Minimum 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ✅ Indicateur CAPTCHA (sans widget complexe pour éviter les erreurs)
          if (CaptchaManager.instance.shouldShowCaptcha('login')) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, color: Colors.blue),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Vérification de sécurité renforcée activée',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Bouton de connexion
          ElevatedButton(
            onPressed: _canAttemptLogin() ? _handleLogin : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Connexion...'),
                    ],
                  )
                : Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  bool _canAttemptLogin() {
    if (_lockoutTime != null || _isLoading) return false;
    
    return _emailController.text.isNotEmpty && 
           _passwordController.text.isNotEmpty;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ✅ 1. Validation CAPTCHA si nécessaire (invisible)
      CaptchaResult? captchaResult;
      if (CaptchaManager.instance.shouldShowCaptcha('login')) {
        captchaResult = await CaptchaManager.instance.validateLogin(
          identifier: _emailController.text.trim(),
          context: context,
        );

        if (!captchaResult.isValid) {
          widget.onError?.call('Vérification de sécurité échouée. Réessayez.');
          CaptchaManager.instance.recordFailedAttempt('login', 
            identifier: _emailController.text.trim());
          return;
        }

        print('✅ CAPTCHA Login validé: ${captchaResult.score}/${captchaResult.requiredScore}');
      }

      // ✅ 2. Tentative de connexion
      final role = await checkUserCredentialsSecure(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        captchaResult: captchaResult,
      );

      if (role != null) {
        // ✅ 3. Connexion réussie
        CaptchaManager.instance.recordSuccessfulAttempt('login',
          identifier: _emailController.text.trim());
        widget.onLoginSuccess?.call();
      } else {
        // ❌ 4. Échec de connexion
        CaptchaManager.instance.recordFailedAttempt('login',
          identifier: _emailController.text.trim());
        widget.onError?.call('Email ou mot de passe incorrect');
      }

    } catch (e) {
      print('❌ Erreur connexion: $e');
      CaptchaManager.instance.recordFailedAttempt('login',
        identifier: _emailController.text.trim());
      widget.onError?.call('Erreur de connexion: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _checkLockoutStatus();
      }
    }
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