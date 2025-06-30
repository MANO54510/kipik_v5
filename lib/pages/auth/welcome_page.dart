import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/logo_with_text.dart';
import '../../theme/kipik_theme.dart';
import 'connexion_page.dart';
import 'inscription_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late final String _selectedBackground;
  late final AnimationController _animController;
  late final Animation<double> _animFade;

  static const _flagAssets = {
    'fr': 'assets/flags/fr.png',
    'en': 'assets/flags/en.png',
    'de': 'assets/flags/de.png',
    'es': 'assets/flags/es.png',
  };

  @override
  void initState() {
    super.initState();
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    _selectedBackground = backgrounds[Random().nextInt(backgrounds.length)];

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _animFade = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topOffset = kToolbarHeight + MediaQuery.of(context).padding.top + 8;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBarKipik(
        title: 'welcome'.tr(),
        showBackButton: false,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_selectedBackground, fit: BoxFit.cover),

          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: topOffset),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: context.supportedLocales.map((loc) {
                  final isActive = loc == context.locale;
                  return GestureDetector(
                    onTap: () => context.setLocale(loc),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? KipikTheme.rouge : Colors.white,
                          width: isActive ? 3 : 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage(_flagAssets[loc.languageCode]!),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          SafeArea(
            child: isLandscape
                ? _buildLandscapeLayout(size)
                : _buildPortraitLayout(size),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(Size size) {
    return Column(
      children: [
        const Spacer(flex: 4),
        const LogoWithText(textColor: Colors.white),
        const Spacer(flex: 5),
        _buildButtons(size),
        const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildLandscapeLayout(Size size) {
    return Row(
      children: [
        Expanded(
          child: Center(child: const LogoWithText(textColor: Colors.white)),
        ),
        Expanded(
          child: Center(child: _buildButtons(size)),
        ),
      ],
    );
  }

  Widget _buildButtons(Size size) {
    final buttonWidth = MediaQuery.of(context).orientation == Orientation.landscape
        ? size.width * 0.4
        : size.width * 0.8;

    return FadeTransition(
      opacity: _animFade,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // — Bouton “Se connecter”
            SizedBox(
              width: buttonWidth,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ConnexionPage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'loginButton'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // — Bouton “Créer un compte”
            SizedBox(
              width: buttonWidth,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InscriptionPage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: KipikTheme.rouge,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'signupButton'.tr(),  // “Créer un compte”
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
