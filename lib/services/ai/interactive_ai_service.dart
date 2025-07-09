// lib/services/ai/interactive_ai_service.dart - Version mise à jour

import '../../models/chat_message.dart';
import '../../models/ai_action.dart';

class InteractiveAIService {
  /// 🎯 Analyse la réponse IA et détecte les actions possibles
  static ChatMessage enhanceResponseWithActions(String aiText, String? contextPage) {
    final actions = <AIAction>[];
    
    // 🔍 Détection des intentions dans la réponse IA
    final lowerText = aiText.toLowerCase();
    
    // Navigation vers Recherche Tatoueur
    if (_shouldNavigateToTattooSearch(lowerText)) {
      actions.add(const AIAction(
        type: AIActionType.navigate,
        title: '🔍 Rechercher un tatoueur',
        subtitle: 'Trouve le tatoueur parfait près de chez toi',
        route: '/recherche-tatoueur',
        icon: 'search',
        color: 'primary',
      ));
    }
    
    // Navigation vers Créer un Projet
    if (_shouldCreateProject(lowerText)) {
      actions.add(const AIAction(
        type: AIActionType.navigate,
        title: '📝 Créer mon projet',
        subtitle: 'Lance ton projet de tatouage',
        route: '/nouveau-projet',
        icon: 'add_circle',
        color: 'success',
      ));
    }
    
    // Navigation vers Galerie d'inspiration
    if (_shouldShowGallery(lowerText)) {
      actions.add(const AIAction(
        type: AIActionType.navigate,
        title: '🎨 Voir la galerie',
        subtitle: 'Explore les réalisations pour t\'inspirer',
        route: '/galerie',
        icon: 'photo_library',
        color: 'purple',
      ));
    }
    
    // ❌ SUPPRIMÉ: Estimateur de prix (pour éviter les tensions avec les tatoueurs)
    
    // Navigation vers Guide du tatouage
    if (_shouldShowGuide(lowerText)) {
      actions.add(const AIAction(
        type: AIActionType.navigate,
        title: '📚 Guide du tatouage',
        subtitle: 'Tout savoir sur les tatouages',
        route: '/guide',
        icon: 'menu_book',
        color: 'info',
      ));
    }
    
    // Support client pour les questions sur les prix
    if (_shouldShowPriceHelp(lowerText)) {
      actions.add(const AIAction(
        type: AIActionType.navigate,
        title: '💬 Questions sur les prix ?',
        subtitle: 'Contacte directement les tatoueurs',
        route: '/recherche-tatoueur',
        icon: 'search',
        color: 'info',
      ));
    }
    
    // Génération d'image (ne peut pas être const à cause du data dynamique)
    if (_shouldGenerateImage(lowerText)) {
      actions.add(AIAction(
        type: AIActionType.generateImage,
        title: '🎨 Générer une image',
        subtitle: 'Crée une inspiration visuelle',
        data: {'prompt': _extractImagePrompt(aiText)},
        icon: 'image',
        color: 'gradient',
      ));
    }
    
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: aiText,
      senderId: 'assistant',
      timestamp: DateTime.now(),
      actions: actions.isNotEmpty ? actions : null,
    );
  }
  
  /// 🔍 Détection - Recherche tatoueur
  static bool _shouldNavigateToTattooSearch(String text) {
    final keywords = [
      'rechercher un tatoueur', 'trouver un tatoueur', 'chercher tatoueur',
      'tatoueur près de', 'tatoueur dans', 'recommander tatoueur',
      'bon tatoueur', 'tatoueur qualifié', 'choisir tatoueur',
      'studio de tatouage', 'salon de tatouage', 'tatoueur'
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// 📝 Détection - Créer projet
  static bool _shouldCreateProject(String text) {
    final keywords = [
      'créer un projet', 'nouveau projet', 'lancer projet',
      'commencer tatouage', 'débuter projet', 'premier tatouage',
      'organiser tatouage', 'planifier tatouage', 'projet'
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// 🎨 Détection - Galerie
  static bool _shouldShowGallery(String text) {
    final keywords = [
      'voir des exemples', 'galerie', 'inspiration', 'réalisations',
      'exemples de tatouages', 'idées de tatouages', 'styles de tatouages',
      'portfolios', 'œuvres', 'exemples'
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// 💬 Détection - Aide prix (redirige vers recherche tatoueur)
  static bool _shouldShowPriceHelp(String text) {
    final keywords = [
      'prix', 'coût', 'tarif', 'budget', 'combien',
      'ça coûte', 'dépenser', 'coûte'
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// 📚 Détection - Guide
  static bool _shouldShowGuide(String text) {
    final keywords = [
      'guide', 'conseils', 'informations', 'apprendre',
      'comment ça marche', 'procédure', 'étapes',
      'soins', 'cicatrisation', 'préparation', 'comment'
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// 🖼️ Détection - Image
  static bool _shouldGenerateImage(String text) {
    final keywords = [
      'montre-moi', 'dessine', 'image', 'visualiser',
      'à quoi ça ressemble', 'voir le résultat', 'générer', 'créer'
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// 🎨 Extraction du prompt pour l'image - VERSION SIMPLIFIÉE
  static String _extractImagePrompt(String text) {
    final lowerText = text.toLowerCase();
    
    // Recherche simple par mots-clés - plus fiable que les RegExp complexes
    final keywords = {
      'dragon': 'tatouage dragon',
      'loup': 'tatouage loup', 
      'rose': 'tatouage rose',
      'tribal': 'tatouage tribal',
      'géométrique': 'tatouage géométrique',
      'réalisme': 'tatouage réaliste',
      'fleur': 'tatouage fleur',
      'animal': 'tatouage animal',
      'papillon': 'tatouage papillon',
      'étoile': 'tatouage étoile',
      'cœur': 'tatouage cœur',
      'crâne': 'tatouage crâne',
      'mandala': 'tatouage mandala',
    };
    
    // Chercher le premier mot-clé trouvé
    for (final entry in keywords.entries) {
      if (lowerText.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Si "tatouage" est mentionné, essayer d'extraire ce qui suit
    if (lowerText.contains('tatouage')) {
      final words = text.split(' ');
      final tattooIndex = words.indexWhere((word) => 
        word.toLowerCase().contains('tatouage'));
      
      if (tattooIndex != -1 && tattooIndex < words.length - 1) {
        final nextWord = words[tattooIndex + 1].replaceAll(RegExp(r'[.,!?]'), '');
        if (nextWord.isNotEmpty && nextWord.length > 2) {
          return 'tatouage $nextWord';
        }
      }
    }
    
    return 'design de tatouage personnalisé';
  }
  
  /// 📱 Actions contextuelles selon la page
  static List<AIAction> getContextualActions(String? contextPage) {
    switch (contextPage) {
      case 'client':
        return [
          AIAction.searchTattooer,
          AIAction.viewGallery,
          AIAction.tattooGuide, // Guide au lieu de prix
        ];
      case 'recherche-tatoueur':
        return [
          AIAction.createProject,
          AIAction.generateImage,
          AIAction.viewGallery,
        ];
      case 'galerie':
        return [
          AIAction.searchTattooer,
          AIAction.createProject,
          AIAction.tattooGuide,
        ];
      default:
        return [
          AIAction.searchTattooer,
          AIAction.viewGallery,
          AIAction.tattooGuide,
        ];
    }
  }
}