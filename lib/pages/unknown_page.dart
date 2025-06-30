// lib/pages/unknown_page.dart

import 'package:flutter/material.dart';
import 'dart:math';

/// Page affichée lorsque la route demandée est introuvable ou mal configurée.
class UnknownPage extends StatelessWidget {
  /// Message à afficher pour expliquer l'erreur de routage.
  final String message;

  const UnknownPage({Key? key, this.message = 'Page introuvable'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Liste d'assets de fond aléatoires
    const backgrounds = [
      'assets/background_charbon.png',
      'assets/background1.png',
      'assets/background2.png',
    ];
    final bg = backgrounds[Random().nextInt(backgrounds.length)];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bg, fit: BoxFit.cover),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'PermanentMarker',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.popUntil(
                        context,
                        (route) => route.isFirst,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        "Retour à l'accueil",
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 20,
                          color: Colors.black,
                        ),
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
