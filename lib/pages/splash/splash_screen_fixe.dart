// lib/pages/splash/splash_screen_fixe.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kipik_v5/pages/splash/splash_screen_animated.dart';
import 'package:kipik_v5/widgets/logo_with_text.dart';

class SplashScreenFixe extends StatefulWidget {
  const SplashScreenFixe({Key? key}) : super(key: key);

  @override
  State<SplashScreenFixe> createState() => _SplashScreenFixeState();
}

class _SplashScreenFixeState extends State<SplashScreenFixe> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Lance un timer de 3 secondes avant de passer à l'écran animé
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SplashScreenAnimated(),
          transitionsBuilder: (_, __, ___, child) => child,
          transitionDuration: Duration.zero,
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          // Utilisation du widget commun
          child: const LogoWithText(textColor: Colors.black),
        ),
      ),
    );
  }
}