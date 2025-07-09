// lib/widgets/common/buttons/tattoo_assistant_button.dart - Version corrigée définitive

import 'package:flutter/material.dart';
import '../../../theme/kipik_theme.dart';
import '../../../utils/chat_helper.dart';
import '../../../core/database_manager.dart';

class TattooAssistantButton extends StatefulWidget {
  final bool allowImageGeneration;
  final String? contextPage;
  
  const TattooAssistantButton({
    Key? key,
    this.allowImageGeneration = true,
    this.contextPage,
  }) : super(key: key);

  @override
  State<TattooAssistantButton> createState() => _TattooAssistantButtonState();
}

class _TattooAssistantButtonState extends State<TattooAssistantButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation de pulsation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Animation de rotation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Démarrer les animations
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _openAssistant() {
    try {
      ChatHelper.openAIAssistant(
        context,
        allowImageGeneration: widget.allowImageGeneration,
        contextPage: widget.contextPage ?? 'general',
      );
    } catch (e) {
      print('❌ Erreur ouverture assistant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assistant temporairement indisponible'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    
    // ✅ SOLUTION DÉFINITIVE: Utiliser directement FloatingActionButton sans Positioned
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: FloatingActionButton(
            onPressed: _openAssistant,
            backgroundColor: isDemoMode ? Colors.orange : KipikTheme.rouge,
            foregroundColor: Colors.white,
            elevation: 8,
            heroTag: "tattoo_assistant_btn", // ✅ IMPORTANT: Éviter les conflits si plusieurs FAB
            child: Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle de fond avec dégradé
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  
                  // Icône principale avec badge démo
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 28,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      
                      // Badge mode démo
                      if (isDemoMode)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: const Center(
                              child: Text(
                                'D',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Badge génération d'images
                      if (widget.allowImageGeneration && !isDemoMode)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: const Icon(
                              Icons.image,
                              size: 6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================================
// lib/utils/chat_helper.dart - Version corrigée

class ChatHelper {
  /// ✅ Ouvre l'assistant IA avec gestion d'erreur robuste
  static void openAIAssistant(
    BuildContext context, {
    bool allowImageGeneration = false,
    String? contextPage,
    String? initialPrompt,
  }) {
    try {
      final isDemoMode = DatabaseManager.instance.isDemoMode;
      
      if (isDemoMode) {
        _showDemoAssistantDialog(context, contextPage);
      } else {
        _showRealAssistantDialog(context, allowImageGeneration, contextPage, initialPrompt);
      }
    } catch (e) {
      print('❌ Erreur ChatHelper.openAIAssistant: $e');
      _showErrorDialog(context, e.toString());
    }
  }

  /// ✅ Dialog démo sécurisé
  static void _showDemoAssistantDialog(BuildContext context, String? contextPage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              Icon(Icons.science, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Assistant Kipik (Démo)',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'PermanentMarker',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.smart_toy, size: 48, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text(
                      '🎭 Mode démonstration',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'L\'assistant IA sera disponible dans la version complète de Kipik.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Fonctionnalités prévues :',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildFeatureItem('💬 Conseils personnalisés de tatouage'),
              _buildFeatureItem('🎨 Suggestions de styles et emplacements'),
              _buildFeatureItem('🔍 Recherche de tatoueurs par critères'),
              _buildFeatureItem('📊 Estimation de prix et durée'),
              if (contextPage != null)
                _buildFeatureItem('📍 Aide contextuelle sur $contextPage'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fermer',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Naviguer vers la page d'inscription ou d'informations
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Version complète bientôt disponible !'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'En savoir plus',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Dialog assistant réel (à implémenter)
  static void _showRealAssistantDialog(
    BuildContext context,
    bool allowImageGeneration,
    String? contextPage,
    String? initialPrompt,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              Icon(Icons.smart_toy, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Assistant Kipik',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'PermanentMarker',
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: KipikTheme.rouge),
              SizedBox(height: 16),
              Text(
                'Connexion à l\'assistant IA...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    // TODO: Implémenter la vraie connexion à l'IA
    Future.delayed(const Duration(seconds: 2), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assistant IA en cours de développement'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });
  }

  /// ✅ Dialog d'erreur
  static void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Erreur',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            'Impossible d\'ouvrir l\'assistant pour le moment.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Helper pour construire les éléments de fonctionnalité
  static Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Obtenir un prompt contextuel
  static String getContextualPrompt(String? contextPage) {
    switch (contextPage) {
      case 'recherche':
        return 'Je cherche des conseils pour trouver un tatoueur qui correspond à mes attentes.';
      case 'inspirations':
        return 'J\'ai besoin d\'aide pour choisir un style de tatouage qui me convient.';
      case 'projets':
        return 'J\'ai des questions sur la gestion de mon projet de tatouage.';
      case 'profil':
        return 'J\'aimerais optimiser mon profil utilisateur.';
      default:
        return 'Bonjour, j\'aimerais avoir des conseils sur le tatouage.';
    }
  }
}

