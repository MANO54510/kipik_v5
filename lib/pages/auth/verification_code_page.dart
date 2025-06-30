import 'dart:math';
import 'package:flutter/material.dart';

class VerificationCodePage extends StatefulWidget {
  final String expectedCode;
  final String role; // 'client', 'tattooer' ou 'admin'

  const VerificationCodePage({
    super.key,
    required this.expectedCode,
    required this.role,
  });

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final TextEditingController _codeController = TextEditingController();
  String? _error;

  void _verifyCode() {
    if (_codeController.text.trim() == widget.expectedCode) {
      if (widget.role == 'client') {
        Navigator.pushReplacementNamed(context, '/home_particulier');
      } else if (widget.role == 'tattooer') {
        Navigator.pushReplacementNamed(context, '/home_pro');
      } else if (widget.role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      }
    } else {
      setState(() {
        _error = 'Code incorrect. Réessaie.';
      });
    }
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
      appBar: AppBar(
        title: const Text('Vérification Email'),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Entre le code reçu par email',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'PermanentMarker',
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _codeController,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Code de vérification',
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.black45,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Valider le code',
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
}
