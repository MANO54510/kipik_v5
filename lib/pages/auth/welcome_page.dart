import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/logo_with_text.dart';
import '../../theme/kipik_theme.dart';
import '../../services/auth/secure_auth_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    final selectedBackground = backgrounds[Random().nextInt(backgrounds.length)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: '',
        showBackButton: false,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background avec overlay pour meilleure visibilité
          Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                selectedBackground,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Erreur chargement background: $error');
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black87, Colors.black],
                      ),
                    ),
                  );
                },
              ),
              // Overlay pour éclaircir et améliorer la lisibilité
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3), // Plus léger en haut
                      Colors.black.withOpacity(0.6), // Plus sombre en bas
                    ],
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: OrientationBuilder(
                    builder: (context, orientation) {
                      final isLandscape = orientation == Orientation.landscape;
                      // Variables pour responsive design
                      final buttonWidth = isLandscape ? 300.0 : 280.0;
                      
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo et titre
                          const LogoWithText(),
                          SizedBox(height: isLandscape ? 30 : 60),

                          // Boutons principaux
                          SizedBox(
                            width: buttonWidth,
                            child: Column(
                              children: [
                                // Bouton Se connecter
                                _buildWelcomeButton(
                                  icon: Icons.login,
                                  text: 'loginButton'.tr(), // "Se connecter"
                                  onPressed: () => Navigator.pushNamed(context, '/connexion'),
                                  color: KipikTheme.rouge,
                                ),
                                const SizedBox(height: 16),

                                // Bouton S'inscrire
                                _buildWelcomeButton(
                                  icon: Icons.person_add,
                                  text: 'signupButton'.tr(), // "Créer un compte"
                                  onPressed: () => Navigator.pushNamed(context, '/inscription'),
                                  color: Colors.white,
                                  textColor: Colors.black87,
                                ),

                                // BOUTON ADMIN - TOUJOURS VISIBLE EN DEBUG
                                if (kDebugMode) ...[
                                  const SizedBox(height: 16),
                                  _buildAdminButton(buttonWidth),
                                ]
                                // Mode production - bouton conditionnel
                                else ...[
                                  const SizedBox(height: 16),
                                  FutureBuilder<bool>(
                                    future: SecureAuthService.instance.checkFirstAdminExists(),
                                    builder: (context, snapshot) {
                                      // En cas d'erreur ou pas de données, montrer le bouton
                                      if (snapshot.hasError || snapshot.data == false) {
                                        return _buildAdminButton(buttonWidth);
                                      }
                                      // Si admin existe, montrer badge
                                      if (snapshot.data == true) {
                                        return _buildConfiguredBadge();
                                      }
                                      // Chargement
                                      return _buildLoadingButton(buttonWidth);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    required Color color,
    Color? textColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'PermanentMarker',
            color: textColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor ?? Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAdminButton(double width) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/first-setup'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(Icons.admin_panel_settings, size: 24),
        label: const Text(
          '🔧 Configuration Admin',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'PermanentMarker',
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingButton(double width) {
    return Container(
      width: width,
      height: 56,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text(
            '✅ Application configurée',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'PermanentMarker',
            ),
          ),
        ],
      ),
    );
  }
}