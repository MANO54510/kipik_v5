// lib/pages/auth/forgot_password_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../theme/kipik_theme.dart'; // import du thème pour KipikTheme.rouge

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  final List<String> backgrounds = [
    'assets/background1.png',
    'assets/background2.png',
    'assets/background3.png',
    'assets/background4.png',
  ];

  void _sendResetLink() {
    final email = _emailController.text.trim();
    final isValidEmail = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

    if (email.isEmpty || !isValidEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci d\'indiquer un email valide.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien de réinitialisation envoyé !')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final selectedBackground = backgrounds[Random().nextInt(backgrounds.length)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Mot de passe oublié',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(selectedBackground, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Indiquez votre adresse email pour recevoir un lien de réinitialisation.',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontFamily: 'Roboto', color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(fontFamily: 'Roboto', color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // — Bouton plein écran en rouge avec texte PermanentMarker —
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KipikTheme.rouge,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 18,
                      ),
                    ),
                    child: const Text('Envoyer le lien'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
