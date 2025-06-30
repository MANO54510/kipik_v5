import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/pages/auth/connexion_page.dart';

class NouveauMotDePassePage extends StatefulWidget {
  const NouveauMotDePassePage({super.key});

  @override
  State<NouveauMotDePassePage> createState() => _NouveauMotDePassePageState();
}

class _NouveauMotDePassePageState extends State<NouveauMotDePassePage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  String? _validatePassword(String value) {
    if (value.length < 6) return '6 caractères minimum';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Ajoute une majuscule';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Ajoute une minuscule';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Ajoute un chiffre';
    if (!RegExp(r'[!@#\$&*~%?^]').hasMatch(value)) return 'Ajoute un caractère spécial';
    return null;
  }

  void _validateNewPassword() {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();
    final error = _validatePassword(newPass);

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar('Merci de remplir tous les champs.');
      return;
    }

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    if (newPass != confirmPass) {
      _showSnackBar('Les mots de passe ne correspondent pas.');
      return;
    }

    _showSnackBar('Mot de passe modifié avec succès !');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) =>  ConnexionPage()),
      (route) => false,
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final List<String> backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final String selectedBackground = backgrounds[Random().nextInt(backgrounds.length)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nouveau mot de passe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(selectedBackground, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      'Définis ton nouveau mot de passe.',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontFamily: 'PermanentMarker',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: 'Nouveau mot de passe',
                      show: _showPassword,
                      toggle: (val) => setState(() => _showPassword = val),
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirmer mot de passe',
                      show: _showConfirmPassword,
                      toggle: (val) => setState(() => _showConfirmPassword = val),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _validateNewPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Valider mon nouveau mot de passe',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required Function(bool) toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.black45,
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility : Icons.visibility_off, color: Colors.white),
          onPressed: () => toggle(!show),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
