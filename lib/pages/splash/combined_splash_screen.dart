// lib/pages/splash/combined_splash_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kipik_v5/pages/auth/welcome_page.dart';
import 'package:vibration/vibration.dart';

class CombinedSplashScreen extends StatefulWidget {
  const CombinedSplashScreen({super.key});

  @override
  State<CombinedSplashScreen> createState() => _CombinedSplashScreenState();
}

class _CombinedSplashScreenState extends State<CombinedSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<InkPoint> _inkPoints;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _navigated = false;
  final Set<int> _vibratedPoints = {};
  late Timer _vibrationTimer;

  @override
  void initState() {
    super.initState();
    
    // Générer les points d'encre
    _generateInkPoints();
    
    // Démarrer l'audio
    _playSound();
    
    // Animation principale (4 secondes)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
    
    // Timer pour vérifier les vibrations
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _checkVibrationsForNewPoints();
    });
    
    // Navigation automatique à la fin
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_navigated) {
        _navigateToWelcome();
      }
    });
  }
  
  void _generateInkPoints() {
    final random = Random();
    
    // Créer 5 points comme dans votre code original
    _inkPoints = List.generate(5, (index) {
      return InkPoint(
        position: Offset(
          random.nextDouble() * 2 - 0.5, // -0.5 à 1.5
          random.nextDouble() * 2 - 0.5, // -0.5 à 1.5
        ),
        // Ajouter des délais variables pour les vibrations séquentielles
        delay: index * 0.15, // 0, 0.15, 0.3, 0.45, 0.6
      );
    });
  }
  
  // Vérifie si de nouveaux points d'encre doivent déclencher une vibration
  void _checkVibrationsForNewPoints() {
    if (!mounted) return;
    
    final progress = _controller.value;
    for (int i = 0; i < _inkPoints.length; i++) {
      // Si ce point n'a pas encore vibré et si son délai est dépassé
      if (!_vibratedPoints.contains(i) && progress >= _inkPoints[i].delay) {
        _vibratedPoints.add(i);
        _vibrateForPoint();
      }
    }
  }
  
  // Vibration pour un nouveau point d'encre
  Future<void> _vibrateForPoint() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50, amplitude: 80);
    }
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/tattoo_machine.mp3');
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Erreur lecture son: $e');
    }
  }

  void _navigateToWelcome() {
    _navigated = true;
    _audioPlayer.stop();
    _vibrationTimer.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    _vibrationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animation d'encre
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: EnhancedInkPainter(
                  progress: _controller.value,
                  inkPoints: _inkPoints,
                ),
              );
            },
          ),
          
          // Logo et texte
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo_kipik.png',
                  width: MediaQuery.of(context).size.width * 0.7,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  "L'APPLICATION TATOUAGE",
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 32,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Classe pour stocker un point d'encre avec son délai
class InkPoint {
  final Offset position;
  final double delay;
  
  InkPoint({
    required this.position,
    this.delay = 0.0,
  });
}

// Painter amélioré pour l'animation d'encre
class EnhancedInkPainter extends CustomPainter {
  final double progress;
  final List<InkPoint> inkPoints;
  
  EnhancedInkPainter({
    required this.progress,
    required this.inkPoints,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    // Rayon maximum un peu plus grand pour s'assurer que tout l'écran est couvert
    final maxRadius = sqrt(size.width * size.width + size.height * size.height) * 1.2;
    
    // Dessiner chaque point d'encre
    for (var point in inkPoints) {
      // Calculer la progression ajustée en fonction du délai
      final adjustedProgress = max(0.0, progress - point.delay) / (1.0 - point.delay);
      if (adjustedProgress <= 0) continue;
      
      // Position réelle sur l'écran
      final position = Offset(
        point.position.dx * size.width,
        point.position.dy * size.height,
      );
      
      // Rayon actuel avec une courbe d'easing pour un mouvement plus naturel
      final radius = maxRadius * _easeOutCubic(adjustedProgress);
      
      // Dessiner le cercle d'encre
      canvas.drawCircle(position, radius, paint);
    }
  }
  
  // Fonction d'easing pour un mouvement plus naturel
  double _easeOutCubic(double t) {
    return 1 - pow(1 - t, 3).toDouble();
  }
  
  @override
  bool shouldRepaint(EnhancedInkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}