// lib/widgets/common/buttons/tattoo_assistant_button.dart

import 'package:flutter/material.dart';
import '../../../theme/kipik_theme.dart';
import '../../../utils/chat_helper.dart';
import '../../../core/database_manager.dart';

class TattooAssistantButton extends StatefulWidget {
  final bool allowImageGeneration;
  final String? contextPage;
  
  // ✅ AJOUTÉ - Paramètres pour EventEditPage
  final int? currentStep;
  final Map<String, dynamic>? formData;
  final String? contextData;
  
  const TattooAssistantButton({
    Key? key,
    this.allowImageGeneration = true,
    this.contextPage,
    this.currentStep, // ✅ NOUVEAU
    this.formData,    // ✅ NOUVEAU  
    this.contextData, // ✅ NOUVEAU
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
      // ✅ AMÉLIORÉ - Utilise les nouvelles données contextuelles
      final contextualPage = _getContextualPage();
      final contextualPrompt = _getContextualPrompt();
      
      ChatHelper.openAIAssistant(
        context,
        allowImageGeneration: widget.allowImageGeneration,
        contextPage: contextualPage,
        initialPrompt: contextualPrompt,
      );
    } catch (e) {
      print('❌ Erreur ouverture assistant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Assistant temporairement indisponible'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ✅ NOUVEAU - Détermine la page contextuelle selon les paramètres
  String _getContextualPage() {
    if (widget.contextData == 'event_creation') {
      return 'Création de convention - Étape ${(widget.currentStep ?? 0) + 1}';
    }
    return widget.contextPage ?? 'general';
  }

  // ✅ NOUVEAU - Génère un prompt contextuel intelligent
  String _getContextualPrompt() {
    if (widget.contextData == 'event_creation') {
      switch (widget.currentStep) {
        case 0:
          return _getStep0Prompt();
        case 1:
          return _getStep1Prompt();
        case 2:
          return _getStep2Prompt();
        case 3:
          return _getStep3Prompt();
        default:
          return 'Je crée une convention de tatouage et j\'ai besoin de conseils.';
      }
    }
    return ChatHelper.getContextualPrompt(widget.contextPage);
  }

  String _getStep0Prompt() {
    final formData = widget.formData ?? {};
    final conventionName = formData['name'] ?? '';
    final conventionType = formData['type']?.toString().split('.').last ?? '';
    
    return 'Je crée une convention de tatouage. '
           '${conventionName.isNotEmpty ? 'Nom: "$conventionName". ' : ''}'
           '${conventionType.isNotEmpty ? 'Type: $conventionType. ' : ''}'
           'J\'ai besoin de conseils pour le nom, la description et le type de convention.';
  }

  String _getStep1Prompt() {
    final formData = widget.formData ?? {};
    final location = formData['location'] ?? '';
    
    return 'Je configure le lieu et les dates de ma convention de tatouage. '
           '${location.isNotEmpty ? 'Lieu envisagé: "$location". ' : ''}'
           'J\'ai besoin de conseils pour choisir le lieu optimal et les meilleures dates.';
  }

  String _getStep2Prompt() {
    final formData = widget.formData ?? {};
    final standPrice = formData['standPrice'] ?? 0;
    final ticketPrice = formData['ticketPrice'] ?? 0;
    final maxTattooers = formData['maxTattooers'] ?? 0;
    
    return 'Je configure les prix et options de ma convention. '
           'Prix stand: ${standPrice}€/m², Prix billet: ${ticketPrice}€, '
           'Capacité: $maxTattooers tatoueurs. '
           'J\'ai besoin de conseils sur la tarification et les options.';
  }

  String _getStep3Prompt() {
    final formData = widget.formData ?? {};
    final standRevenue = (formData['maxTattooers'] ?? 0) * (formData['standPrice'] ?? 0) * 6;
    final ticketRevenue = (formData['expectedVisitors'] ?? 0) * (formData['ticketPrice'] ?? 0);
    
    return 'Je finalise ma convention de tatouage. '
           'Revenus estimés: ${standRevenue + ticketRevenue}€. '
           'J\'ai besoin de conseils pour la publication et le marketing.';
  }

  // ✅ NOUVEAU - Icône contextuelle selon l'étape
  IconData _getContextualIcon() {
    if (widget.contextData == 'event_creation') {
      switch (widget.currentStep) {
        case 0: return Icons.lightbulb_outline; // Idées
        case 1: return Icons.location_on; // Lieu
        case 2: return Icons.calculate; // Prix
        case 3: return Icons.rocket_launch; // Publication
        default: return Icons.smart_toy;
      }
    }
    return Icons.smart_toy;
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = DatabaseManager.instance.isDemoMode;
    
    return Positioned( // ✅ REMIS - Position fixe pour EventEditPage
      bottom: 100,
      right: 20,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: _openAssistant,
              backgroundColor: isDemoMode ? Colors.orange : KipikTheme.rouge,
              foregroundColor: Colors.white,
              elevation: 8,
              heroTag: "tattoo_assistant_btn",
              icon: Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159 * 0.1, // Rotation plus lente
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _getContextualIcon(), // ✅ Icône contextuelle
                      size: 24,
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
                        top: -8,
                        right: -8,
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
                  ],
                ),
              ),
              label: Text(
                _getContextualLabel(), // ✅ Label contextuel
                style: const TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ NOUVEAU - Label contextuel selon l'étape
  String _getContextualLabel() {
    if (widget.contextData == 'event_creation') {
      switch (widget.currentStep) {
        case 0: return 'Idées';
        case 1: return 'Localiser';
        case 2: return 'Calculer';
        case 3: return 'Publier';
        default: return 'Assistant';
      }
    }
    return 'Assistant';
  }
}

// ================================
// lib/utils/chat_helper.dart - Mise à jour

class ChatHelper {
  /// ✅ Ouvre l'assistant IA avec gestion d'erreur robuste
  static void openAIAssistant(
    BuildContext context, {
    bool allowImageGeneration = false,
    String? contextPage,
    String? initialPrompt, // ✅ NOUVEAU paramètre
  }) {
    try {
      final isDemoMode = DatabaseManager.instance.isDemoMode;
      
      if (isDemoMode) {
        _showDemoAssistantDialog(context, contextPage, initialPrompt);
      } else {
        _showRealAssistantDialog(context, allowImageGeneration, contextPage, initialPrompt);
      }
    } catch (e) {
      print('❌ Erreur ChatHelper.openAIAssistant: $e');
      _showErrorDialog(context, e.toString());
    }
  }

  /// ✅ Dialog démo amélioré avec prompt contextuel
  static void _showDemoAssistantDialog(BuildContext context, String? contextPage, String? initialPrompt) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              
              // ✅ NOUVEAU - Affichage du contexte si présent
              if (initialPrompt != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎯 Contexte détecté:',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        initialPrompt,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
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
                _buildFeatureItem('📍 Aide contextuelle: $contextPage'),
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
          content: const Text(
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
            decoration: const BoxDecoration(
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