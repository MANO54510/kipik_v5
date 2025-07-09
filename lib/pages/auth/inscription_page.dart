// lib/pages/auth/inscription_page.dart - Version sécurisée avec reCAPTCHA

import 'dart:math';
import 'package:flutter/material.dart';
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
  // Variables reCAPTCHA
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
      appBar: const CustomAppBarKipik(
        title: 'Inscription',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background avec overlay
          Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(bg, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // Logo avec la largeur des cartes
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Image.asset(
                        'assets/logo_kipik.png', 
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Titre de section compact
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Choisissez votre type de compte',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: KipikTheme.rouge,
                        fontFamily: 'PermanentMarker',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // reCAPTCHA minimal
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: KipikTheme.rouge.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user, 
                                 color: KipikTheme.rouge, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Sécurité',
                              style: TextStyle(
                                color: KipikTheme.rouge,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PermanentMarker',
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 80,
                          child: ReCaptchaWidget(
                            action: 'signup',
                            useInvisible: true,
                            onValidated: (result) {
                              setState(() {
                                _captchaValidated = result.isValid;
                                _captchaResult = result;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Boutons de choix avec headers tattoo
                  _buildChoiceButton(
                    context,
                    'Particulier',
                    'Trouvez votre tatoueur idéal • Gérez vos projets • Suivez vos rendez-vous',
                    'assets/avatars/avatar_client.png',
                    InscriptionParticulierPage(),
                    enabled: _captchaValidated,
                  ),
                  const SizedBox(height: 8),
                  
                  _buildChoiceButton(
                    context,
                    'Tatoueur Pro',
                    'Développez votre clientèle • Gérez votre agenda • Boostez votre visibilité',
                    'assets/avatars/avatar_tatoueur.png',
                    InscriptionProPage(),
                    enabled: _captchaValidated,
                  ),
                  const SizedBox(height: 8),
                  
                  _buildChoiceButton(
                    context,
                    'Organisateur',
                    'Créez vos événements • Gérez vos exposants • Maximisez votre impact',
                    'assets/avatars/avatar_orga.png',
                    InscriptionOrganisateurPage(),
                    enabled: _captchaValidated,
                  ),

                  // Message d'aide si reCAPTCHA pas validé
                  if (!_captchaValidated) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info, color: Colors.orange[700], size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Validez la sécurité ci-dessus',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
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
    String avatarPath,
    Widget page, {
    bool enabled = true,
  }) {
    // ✅ Sélection du header selon le type
    String headerImage;
    if (title == 'Particulier') {
      headerImage = 'assets/images/header_tattoo_wallpaper.png';
    } else if (title == 'Tatoueur Pro') {
      headerImage = 'assets/images/header_tattoo_wallpaper2.png';
    } else { // Organisateur
      headerImage = 'assets/images/header_tattoo_wallpaper3.png';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled 
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: enabled ? DecorationImage(
            image: AssetImage(headerImage),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.6), // ✅ Même opacité que les autres pages
              BlendMode.lighten,
            ),
          ) : null,
          color: enabled ? null : Colors.grey[300],
          border: Border.all(
            color: enabled ? KipikTheme.rouge : Colors.grey,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled 
                ? () => _navigateToSignup(context, page, title)
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar avec fond blanc
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: enabled ? KipikTheme.rouge : Colors.grey,
                            width: 2,
                          ),
                          color: Colors.white,
                          boxShadow: [
                            if (enabled)
                              BoxShadow(
                                color: KipikTheme.rouge.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            color: Colors.white,
                            child: Image.asset(
                              avatarPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.white,
                                  child: Icon(
                                    title == 'Particulier' ? Icons.person :
                                    title == 'Tatoueur Pro' ? Icons.brush : Icons.event,
                                    color: enabled ? KipikTheme.rouge : Colors.grey,
                                    size: 35,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ Titre directement sur le fond (sans bulle)
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: enabled ? Colors.black87 : Colors.grey,
                                // ✅ Ombre pour détacher du fond tattoo
                                shadows: [
                                  Shadow(
                                    color: Colors.white,
                                    blurRadius: 3,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // ✅ Description directement sur le fond (sans bulle)
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 12,
                                color: enabled ? Colors.grey[800] : Colors.grey,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Roboto',
                                height: 1.3,
                                // ✅ Ombre pour détacher du fond tattoo
                                shadows: [
                                  Shadow(
                                    color: Colors.white,
                                    blurRadius: 2,
                                    offset: const Offset(0.5, 0.5),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // ✅ Icône flèche avec fond blanc
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: enabled ? KipikTheme.rouge.withOpacity(0.3) : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: enabled ? KipikTheme.rouge : Colors.grey,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  
                  // Indicateur de sécurité validée
                  if (enabled && _captchaValidated) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, 
                               color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          const Text(
                            'Sécurité validée ✓',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'PermanentMarker',
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
        ),
      ),
    );
  }

  // Navigation sécurisée avec transmission du résultat reCAPTCHA
  void _navigateToSignup(BuildContext context, Widget page, String type) {
    if (!_captchaValidated || _captchaResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.security, color: Colors.white),
              SizedBox(width: 8),
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