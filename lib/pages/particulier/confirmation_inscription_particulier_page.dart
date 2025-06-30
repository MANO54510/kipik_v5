import 'dart:math';
import 'package:flutter/material.dart';

import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/pages/particulier/recherche_tatoueur_page.dart';

class ConfirmationInscriptionParticulierPage extends StatelessWidget {
  const ConfirmationInscriptionParticulierPage({Key? key}) : super(key: key);

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
        title: "Bienvenue",
        showBackButton: false,
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
                  const Text(
                    "Merci pour votre inscription.\n"
                    "Chaque tatouage raconte une histoire...\n"
                    "La vôtre démarre aujourd'hui.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 26,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RechercheTatoueurPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                      shadowColor: Colors.black54,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    child: const Text("Trouver mon tatoueur"),
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
