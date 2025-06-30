// lib/pages/splash/splash_screen_animated.dart
import 'dart:math'; // Ajouté pour avoir accès à pi
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kipik_v5/pages/auth/welcome_page.dart';
import 'package:kipik_v5/widgets/logo_with_text.dart';
import 'package:vibration/vibration.dart';
import 'package:video_player/video_player.dart';

class SplashScreenAnimated extends StatefulWidget {
  const SplashScreenAnimated({super.key});

  @override
  State<SplashScreenAnimated> createState() => _SplashScreenAnimatedState();
}

class _SplashScreenAnimatedState extends State<SplashScreenAnimated> {
  late VideoPlayerController _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _navigated = false;
  bool _videoInitialized = false;
  bool _initializationFailed = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _triggerEffects(); // vibration + son
    
    // Augmenter le timer de secours à 10 secondes
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_navigated && !_videoInitialized) {
        debugPrint('Navigation forcée après délai dépassé');
        _navigateToHome();
      }
    });
  }

  Future<void> _initializeVideo() async {
    try {
      debugPrint('Début initialisation vidéo');
      
      // Initialiser le contrôleur vidéo avec votre fichier MP4 existant
      _videoController = VideoPlayerController.asset('assets/videos/animation_background.mp4');
      
      // Ajouter un listener pour détecter les erreurs
      _videoController.addListener(() {
        if (_videoController.value.hasError) {
          debugPrint('Erreur VideoPlayer: ${_videoController.value.errorDescription}');
          _handleVideoError();
        }
      });
      
      // Configurer la vidéo
      await _videoController.initialize().catchError((error) {
        debugPrint('Erreur initialisation: $error');
        _handleVideoError();
        return null;
      });
      
      if (_videoController.value.isInitialized && mounted) {
        debugPrint('Vidéo initialisée avec succès');
        _videoController.setLooping(true);
        _videoController.setVolume(0.0);
        _videoController.play();
        
        setState(() {
          _videoInitialized = true;
        });
        
        // Augmenter la durée à 7 secondes
        Future.delayed(const Duration(seconds: 7), () {
          if (mounted && !_navigated) {
            _navigateToHome();
          }
        });
      }
    } catch (e) {
      debugPrint('Exception lors de l\'initialisation de la vidéo: $e');
      _handleVideoError();
    }
  }
  
  void _handleVideoError() {
    if (mounted && !_initializationFailed) {
      setState(() {
        _initializationFailed = true;
      });
      
      // Naviguer après un court délai en cas d'erreur
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && !_navigated) {
          _navigateToHome();
        }
      });
    }
  }

  Future<void> _triggerEffects() async {
    // Vibration courte si supportée
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 100);
    }

    // Lecture du son
    try {
      await _audioPlayer.setAsset('assets/sounds/tattoo_machine.mp3');
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Erreur lecture son: $e');
    }
  }

  void _navigateToHome() {
    if (!_navigated) {
      _navigated = true;
      _audioPlayer.stop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomePage()),
      );
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Vidéo en arrière-plan ou animation de secours
          if (_videoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: Transform(
                    // Combinaison de transformations pour effet miroir horizontal + haut/bas inversé
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateY(pi) // Miroir horizontal (pi = 180 degrés)
                      ..rotateX(pi), // Inverser haut/bas (pi = 180 degrés)
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
            )
          else if (_initializationFailed)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Color(0xFF333333)],
                ),
              ),
            ),
          
          // Logo et texte (toujours blanc)
          const Center(
            child: LogoWithText(),
          ),
          
          // Indicateur de chargement
          if (!_videoInitialized && !_initializationFailed)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}