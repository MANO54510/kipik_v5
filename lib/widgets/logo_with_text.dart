// lib/widgets/logo_with_text.dart
import 'package:flutter/material.dart';

class LogoWithText extends StatelessWidget {
  // Paramètre désormais optionnel avec valeur par défaut blanc
  final Color textColor;
  
  const LogoWithText({
    Key? key,
    // Couleur blanche par défaut
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo_kipik.png',
          width: MediaQuery.of(context).size.width * 0.7,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        // Le texte sera toujours blanc, indépendamment du paramètre textColor
        const Text(
          "L'APPLICATION TATOUAGE",
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 28,
            color: Colors.white, // Toujours blanc, peu importe le paramètre
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}