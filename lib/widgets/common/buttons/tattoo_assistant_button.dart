// lib/widgets/tattoo_assistant_button.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/pages/chat/ai_assistant_page.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

/// Bouton "L'assistant Kipik" animé et déplaçable par l'utilisateur
/// Intégré avec ChatManager pour l'IA contextuelle
class TattooAssistantButton extends StatefulWidget {
  final bool allowImageGeneration;
  final String? contextPage; // Pour personnaliser l'aide selon la page
  
  const TattooAssistantButton({
    this.allowImageGeneration = false, 
    this.contextPage,
    Key? key
  }) : super(key: key);

  @override
  _TattooAssistantButtonState createState() => _TattooAssistantButtonState();
}

class _TattooAssistantButtonState extends State<TattooAssistantButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  Offset _offset = const Offset(0, 0); // Position initiale centrée

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _openAssistant() {
    // Navigation vers la page AI Assistant avec contexte
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIAssistantPage(
          allowImageGeneration: widget.allowImageGeneration,
          contextPage: widget.contextPage,
          initialPrompt: _getContextualPrompt(),
        ),
      ),
    );
  }

  String? _getContextualPrompt() {
    // Prompt initial selon la page courante
    switch (widget.contextPage) {
      case 'devis':
        return 'Je souhaite créer un devis pour un tatouage';
      case 'agenda':
        return 'Comment utiliser mon agenda professionnel ?';
      case 'projets':
        return 'Comment gérer mes projets clients ?';
      case 'comptabilite':
        return 'Aide pour la comptabilité tatoueur';
      case 'conventions':
        return 'Comment m\'inscrire à une convention ?';
      default:
        return null; // Pas de prompt initial
    }
  }

  void _constrainPosition() {
    // Contraindre la position dans les limites de l'écran
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = 70.0;
    
    setState(() {
      _offset = Offset(
        _offset.dx.clamp(
          -screenSize.width / 2 + buttonSize,
          screenSize.width / 2 - buttonSize,
        ),
        _offset.dy.clamp(
          -screenSize.height / 2 + buttonSize + 100, // Marge pour AppBar
          screenSize.height / 2 - buttonSize - 100,  // Marge pour BottomNav
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100, // Position au-dessus de la navigation
      right: 16,
      child: GestureDetector(
        onTap: _openAssistant,
        onPanUpdate: (details) {
          setState(() {
            _offset += details.delta;
          });
        },
        onPanEnd: (_) => _constrainPosition(),
        child: Transform.translate(
          offset: _offset,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseCtrl.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Halo animé
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: KipikTheme.rouge.withOpacity(
                          0.3 * (1.1 - _pulseCtrl.value),
                        ),
                      ),
                    ),
                    // Bouton principal
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: KipikTheme.rouge,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Avatar assistant
                            Image.asset(
                              'assets/avatars/avatar_assistant_kipik.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.smart_toy,
                                  color: Colors.white,
                                  size: 35,
                                );
                              },
                            ),
                            // Badge si génération d'images activée
                            if (widget.allowImageGeneration)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Texte d'aide au premier lancement
                    if (_shouldShowHelpText())
                      Positioned(
                        top: -35,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Assistant Kipik',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _shouldShowHelpText() {
    // Logique pour afficher le texte d'aide (première utilisation, etc.)
    // TODO: Implémenter avec SharedPreferences
    return false;
  }
}