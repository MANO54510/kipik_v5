// lib/pages/pro/confirmation_inscription_pro_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/pages/pro/home_page_pro.dart';

class ConfirmationInscriptionProPage extends StatefulWidget {
  const ConfirmationInscriptionProPage({Key? key}) : super(key: key);

  @override
  State<ConfirmationInscriptionProPage> createState() =>
      _ConfirmationInscriptionProPageState();
}

class _ConfirmationInscriptionProPageState
    extends State<ConfirmationInscriptionProPage> {
  late final String _bgAsset;

  @override
  void initState() {
    super.initState();
    // Choix aléatoire du fond
    const backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    _bgAsset = backgrounds[Random().nextInt(backgrounds.length)];

    // Après 3s, redirection automatique
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePagePro()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: '', // AppBar épuré
        showBackButton: false,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond aléatoire
          Image.asset(_bgAsset, fit: BoxFit.cover),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset('assets/logo_kipik.png', width: 150),
                  const SizedBox(height: 24),
                  // Message
                  const Text(
                    'Bienvenue dans la team KIPIK !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Loader
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
