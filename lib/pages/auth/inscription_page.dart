// lib/pages/auth/inscription_page.dart - Version sécurisée avec reCAPTCHA

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/auth/recaptcha_widget.dart';
import 'package:kipik_v5/services/auth/captcha_manager.dart';
import 'package:kipik_v5/pages/particulier/inscription_particulier_page.dart';
import 'package:kipik_v5/pages/pro/inscription_pro_page.dart';
import 'package:kipik_v5/pages/organisateur/inscription_organisateur_page.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({Key? key}) : super(key: key);

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  // ✅ NOUVEAU: Variables reCAPTCHA
  bool _captchaValidated = false;
  CaptchaResult? _captchaResult;

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
      appBar: CustomAppBarKipik(
        title: tr('signup.choiceTitle'),
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo KIPIK
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'KIPIK',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: KipikTheme.rouge,
                        fontFamily: 'PermanentMarker',
                        shadows: [
                          Shadow(
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Titre de section
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KipikTheme.rouge, width: 2),
                    ),
                    child: Text(
                      'Choisissez votre type de compte',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: KipikTheme.rouge,
                        fontFamily: 'PermanentMarker',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // ✅ NOUVEAU: reCAPTCHA obligatoire pour TOUTES les inscriptions
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: KipikTheme.rouge.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user, 
                                 color: KipikTheme.rouge, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Vérification de sécurité requise',
                              style: TextStyle(
                                color: KipikTheme.rouge,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PermanentMarker',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ReCaptchaWidget(
                          action: 'signup',
                          useInvisible: true,
                          onValidated: (result) {
                            setState(() {
                              _captchaValidated = result.isValid;
                              _captchaResult = result;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Boutons de choix de type de compte
                  _buildChoiceButton(
                    context,
                    tr('signup.particulier'),
                    'Pour les clients qui souhaitent se faire tatouer',
                    Icons.person,
                    InscriptionParticulierPage(),
                    enabled: _captchaValidated,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildChoiceButton(
                    context,
                    tr('signup.pro'),
                    'Pour les tatoueurs professionnels',
                    Icons.brush,
                    InscriptionProPage(),
                    enabled: _captchaValidated,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildChoiceButton(
                    context,
                    tr('signup.organisateur'),
                    'Pour les organisateurs de conventions',
                    Icons.event,
                    InscriptionOrganisateurPage(),
                    enabled: _captchaValidated,
                  ),

                  // ✅ NOUVEAU: Message d'aide si reCAPTCHA pas validé
                  if (!_captchaValidated) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Veuillez valider la vérification de sécurité ci-dessus pour continuer',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Widget page, {
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled 
            ? () => _navigateToSignup(context, page, title)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.white : Colors.grey[300],
          foregroundColor: enabled ? Colors.black : Colors.grey,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: enabled ? 6 : 2,
          shadowColor: enabled ? Colors.black45 : Colors.transparent,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: enabled 
                        ? KipikTheme.rouge.withOpacity(0.1)
                        : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? KipikTheme.rouge : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: enabled ? Colors.black : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: enabled ? Colors.grey[600] : Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: enabled ? KipikTheme.rouge : Colors.grey,
                  size: 16,
                ),
              ],
            ),
            
            // ✅ NOUVEAU: Indicateur de sécurité validée
            if (enabled && _captchaValidated) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, 
                         color: Colors.green[700], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Sécurité validée',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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

  // ✅ NOUVEAU: Navigation sécurisée avec transmission du résultat reCAPTCHA
  void _navigateToSignup(BuildContext context, Widget page, String type) {
    if (!_captchaValidated || _captchaResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.security, color: Colors.white),
              const SizedBox(width: 8),
              Text('Veuillez valider la vérification de sécurité'),
            ],
          ),
          backgroundColor: KipikTheme.rouge,
        ),
      );
      return;
    }

    // Log de sécurité pour l'inscription
    print('🔐 Navigation sécurisée vers inscription $type - Score reCAPTCHA: ${(_captchaResult!.score * 100).round()}%');

    // Navigation avec transmission du résultat reCAPTCHA dans les arguments
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(
          arguments: {
            'captchaResult': _captchaResult,
            'signupType': type.toLowerCase(),
          },
        ),
      ),
    );
  }
}