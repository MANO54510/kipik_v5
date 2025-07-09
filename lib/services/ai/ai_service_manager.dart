// lib/services/ai/ai_service_manager.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat_message.dart';
import '../ai/interactive_ai_service.dart'; // ✅ AJOUTÉ

class AIServiceManager {
  // ✅ MODIFIÉ: Lecture depuis .env au lieu de constante
  static String get _openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _chatEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const String _imageEndpoint = 'https://api.openai.com/v1/images/generations';
  
  // ✅ Vérification que la clé API est configurée
  static bool get isConfigured => _openaiApiKey.isNotEmpty;
  
  // 🛡️ PROTECTION BUDGET
  static const double MONTHLY_BUDGET_EUROS = 35.0;
  static const int MAX_REQUESTS_PER_USER_DAILY = 8;
  static const int MAX_IMAGES_PER_USER_MONTHLY = 3;
  static const double ESTIMATED_COST_PER_REQUEST = 0.05; // €
  static const double ESTIMATED_COST_PER_IMAGE = 0.04; // €

  // 🎨 PROMPTS SPÉCIALISÉS TATOUAGE
  static const Map<String, String> _tattooPrompts = {
    'client': '''Tu es l'assistant expert Kipik, spécialiste du tatouage pour les clients particuliers.

EXPERTISE : Styles de tatouage, conseils personnalisés, préparation, soins, budget, choix d'artiste.

PERSONNALITÉ : Bienveillant, passionné, informatif, sans jugement.

NAVIGATION : Oriente activement les utilisateurs vers les services Kipik :
- "rechercher un tatoueur" pour trouver des artistes qualifiés
- "créer un projet" pour organiser leur tatouage
- "voir la galerie" pour s'inspirer des réalisations
- "estimer le prix" pour calculer leur budget
- "guide du tatouage" pour apprendre les bonnes pratiques

CONSIGNES :
- Donne des conseils personnalisés et détaillés
- Explique les styles de tatouage (réalisme, traditionnel, néo-traditionnel, géométrique, etc.)
- Suggère TOUJOURS des actions concrètes avec les services Kipik
- Aide à préparer les rendez-vous et choisir l'artiste
- Conseille sur les soins et la cicatrisation
- Utilise un ton amical et professionnel
- Maximum 200 mots par réponse pour rester concis
- Termine souvent par une suggestion d'action''',

    'tatoueur': '''Tu es l'assistant Kipik pour les tatoueurs professionnels.

EXPERTISE : Techniques, matériel, gestion client, business, hygiène, réglementation.

CONSIGNES :
- Aide sur les techniques avancées et nouveautés
- Conseils business et gestion d'atelier
- Réglementation et normes d'hygiène
- Gestion clientèle et devis
- Formation et perfectionnement
- Ton professionnel entre collègues
- Maximum 250 mots par réponse''',

    'default': '''Tu es l'assistant Kipik, expert en tatouage.

Aide les utilisateurs avec leurs questions sur l'univers du tatouage : styles, conseils, techniques, soins.
Reste bienveillant et professionnel. Maximum 200 mots par réponse.'''
  };

  /// 🚀 Méthode principale pour obtenir une réponse IA
  static Future<ChatMessage> getAIResponse(
    String prompt,
    String userId, {
    bool allowImageGeneration = false,
    String? contextPage,
  }) async {
    try {
      // ✅ Vérifier que la clé API est configurée
      if (!isConfigured) {
        throw Exception('Service IA non configuré. Contactez l\'administrateur.');
      }

      // 🛡️ Vérifications budget et quotas
      await _checkBudgetLimits(userId);
      await _checkUserQuotas(userId, allowImageGeneration);

      // 🎨 Détection si demande d'image
      if (allowImageGeneration && _isImageRequest(prompt)) {
        await _incrementImageUsage(userId);
        return await _generateImage(prompt, userId);
      } else {
        await _incrementChatUsage(userId);
        return await _generateText(prompt, userId, contextPage);
      }
    } catch (e) {
      return _createErrorMessage(e.toString());
    }
  }

  /// 💬 Génération de texte avec ChatGPT
  static Future<ChatMessage> _generateText(
    String prompt,
    String userId,
    String? contextPage,
  ) async {
    final systemPrompt = _getSystemPrompt(contextPage);

    final response = await http.post(
      Uri.parse(_chatEndpoint),
      headers: {
        'Content-Type': 'application/json; charset=utf-8', // ✅ MODIFIÉ: Encodage UTF-8 explicite
        'Authorization': 'Bearer $_openaiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini', // Plus économique que gpt-4o
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 300, // Limite pour contrôler les coûts
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      // ✅ MODIFIÉ: Décodage UTF-8 explicite
      final responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);
      var content = data['choices'][0]['message']['content'] as String;
      
      // ✅ AJOUTÉ: Nettoyage des caractères d'échappement
      content = _cleanTextContent(content);
      
      // 📊 Log des coûts
      await _logUsage('chat', userId, ESTIMATED_COST_PER_REQUEST);
      
      // ✅ NOUVEAU: Enrichir la réponse avec des actions interactives
      return InteractiveAIService.enhanceResponseWithActions(content, contextPage);
    } else {
      // ✅ AMÉLIORÉ: Gestion d'erreurs plus détaillée
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['error']['message'] ?? 'Erreur API';
      throw Exception('Erreur OpenAI (${response.statusCode}): $errorMessage');
    }
  }

  /// 🎨 Génération d'image avec DALL-E
  static Future<ChatMessage> _generateImage(String prompt, String userId) async {
    // Améliorer le prompt pour les tatouages
    final enhancedPrompt = _enhanceImagePrompt(prompt);

    final response = await http.post(
      Uri.parse(_imageEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openaiApiKey',
      },
      body: jsonEncode({
        'model': 'dall-e-3',
        'prompt': enhancedPrompt,
        'n': 1,
        'size': '1024x1024',
        'quality': 'standard', // Plus économique que 'hd'
        'style': 'natural',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final imageUrl = data['data'][0]['url'] as String;
      
      // 📊 Log des coûts
      await _logUsage('image', userId, ESTIMATED_COST_PER_IMAGE);
      
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "Voici une inspiration pour votre tatouage :",
        imageUrl: imageUrl,
        senderId: 'assistant',
        timestamp: DateTime.now(),
      );
    } else {
      // ✅ AMÉLIORÉ: Gestion d'erreurs plus détaillée
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['error']['message'] ?? 'Erreur DALL-E';
      throw Exception('Erreur DALL-E (${response.statusCode}): $errorMessage');
    }
  }

  /// 🔍 Détection de demande d'image
  static bool _isImageRequest(String prompt) {
    final imageKeywords = [
      'dessine', 'design', 'image', 'photo', 'illustration',
      'montre', 'crée', 'génère', 'imagine', 'visualise',
      'tatouage', 'motif', 'tribal', 'fleur', 'animal'
    ];
    
    final lowerPrompt = prompt.toLowerCase();
    return imageKeywords.any((keyword) => lowerPrompt.contains(keyword));
  }

  /// 📝 Prompt système selon le contexte
  static String _getSystemPrompt(String? contextPage) {
    switch (contextPage) {
      case 'client':
        return _tattooPrompts['client']!;
      case 'tatoueur':
      case 'devis':
      case 'agenda':
        return _tattooPrompts['tatoueur']!;
      default:
        return _tattooPrompts['default']!;
    }
  }

  /// ✨ Amélioration du prompt d'image pour tatouages
  static String _enhanceImagePrompt(String prompt) {
    return '''Create a tattoo design concept: $prompt. 
Style: Clean black and grey linework, suitable for tattooing, 
professional tattoo art style, detailed but not overcomplicated, 
suitable for skin application. High contrast, clear lines.''';
  }

  /// 🧹 NOUVEAU: Nettoyage du contenu texte pour corriger l'encodage
  static String _cleanTextContent(String content) {
    // Remplacement des caractères mal encodés courants
    content = content
        .replaceAll(r'\u0027', "'")  // Apostrophe
        .replaceAll(r'\u00e9', 'é')  // é
        .replaceAll(r'\u00e8', 'è')  // è
        .replaceAll(r'\u00ea', 'ê')  // ê
        .replaceAll(r'\u00e0', 'à')  // à
        .replaceAll(r'\u00e7', 'ç')  // ç
        .replaceAll(r'\u00f9', 'ù')  // ù
        .replaceAll(r'\u00ee', 'î')  // î
        .replaceAll(r'\u00f4', 'ô')  // ô
        .replaceAll(r'\u00fb', 'û')  // û
        .replaceAll(r'\u00ef', 'ï')  // ï
        .replaceAll(r'\u00fc', 'ü')  // ü
        .replaceAll(r'\u00c9', 'É')  // É
        .replaceAll(r'\u00c0', 'À')  // À
        .replaceAll(r'\u00c7', 'Ç')  // Ç
        .replaceAll(r'\u2019', "'")  // Apostrophe courbe
        .replaceAll(r'\u2018', "'")  // Apostrophe ouvrante
        .replaceAll(r'\u201c', '"')  // Guillemet ouvrant
        .replaceAll(r'\u201d', '"')  // Guillemet fermant
        .replaceAll(r'\u2026', '...') // Points de suspension
        .replaceAll(r'\u2013', '–')  // Tiret demi-cadratin
        .replaceAll(r'\u2014', '—'); // Tiret cadratin
    
    // Nettoyage des séquences d'échappement restantes
    content = content.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4})'),
      (match) {
        try {
          final codePoint = int.parse(match.group(1)!, radix: 16);
          return String.fromCharCode(codePoint);
        } catch (e) {
          return match.group(0)!; // Retourner le texte original si erreur
        }
      },
    );
    
    return content;
  }

  /// 🛡️ Vérification des limites budgétaires
  static Future<void> _checkBudgetLimits(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentMonth = DateTime.now().month;
    final storedMonth = prefs.getInt('budget_month') ?? 0;
    
    // Reset mensuel automatique
    if (currentMonth != storedMonth) {
      await prefs.setDouble('monthly_spent', 0.0);
      await prefs.setInt('budget_month', currentMonth);
    }
    
    final monthlySpent = prefs.getDouble('monthly_spent') ?? 0.0;
    
    if (monthlySpent >= MONTHLY_BUDGET_EUROS) {
      throw Exception('Budget mensuel atteint (${MONTHLY_BUDGET_EUROS}€). Réessayez le mois prochain.');
    }
  }

  /// 👤 Vérification des quotas utilisateur
  static Future<void> _checkUserQuotas(String userId, bool isImageRequest) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Quota quotidien de chat
    final dailyKey = 'daily_requests_${userId}_$today';
    final dailyRequests = prefs.getInt(dailyKey) ?? 0;
    
    if (dailyRequests >= MAX_REQUESTS_PER_USER_DAILY) {
      throw Exception('Limite quotidienne atteinte (${MAX_REQUESTS_PER_USER_DAILY} requêtes). Revenez demain !');
    }
    
    // Quota mensuel d'images
    if (isImageRequest) {
      final month = DateTime.now().toIso8601String().substring(0, 7);
      final monthlyImageKey = 'monthly_images_${userId}_$month';
      final monthlyImages = prefs.getInt(monthlyImageKey) ?? 0;
      
      if (monthlyImages >= MAX_IMAGES_PER_USER_MONTHLY) {
        throw Exception('Limite mensuelle d\'images atteinte (${MAX_IMAGES_PER_USER_MONTHLY}). Utilisez le chat pour des conseils !');
      }
    }
  }

  /// 📊 Incrémentation usage chat
  static Future<void> _incrementChatUsage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final dailyKey = 'daily_requests_${userId}_$today';
    final current = prefs.getInt(dailyKey) ?? 0;
    await prefs.setInt(dailyKey, current + 1);
  }

  /// 🎨 Incrémentation usage images
  static Future<void> _incrementImageUsage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final month = DateTime.now().toIso8601String().substring(0, 7);
    final monthlyImageKey = 'monthly_images_${userId}_$month';
    final current = prefs.getInt(monthlyImageKey) ?? 0;
    await prefs.setInt(monthlyImageKey, current + 1);
  }

  /// 📈 Log des coûts
  static Future<void> _logUsage(String type, String userId, double cost) async {
    final prefs = await SharedPreferences.getInstance();
    final currentSpent = prefs.getDouble('monthly_spent') ?? 0.0;
    await prefs.setDouble('monthly_spent', currentSpent + cost);
    
    // Log pour monitoring (en prod, envoyer à votre analytics)
    if (kDebugMode) {
      print('💰 Usage IA: $type | User: $userId | Coût: ${cost}€ | Total mois: ${(currentSpent + cost).toStringAsFixed(2)}€');
    }
  }

  /// ❌ Message d'erreur utilisateur-friendly
  static ChatMessage _createErrorMessage(String error) {
    String userMessage;
    
    if (error.contains('Service IA non configuré')) {
      userMessage = "🔧 Service en cours de configuration. Revenez bientôt !";
    } else if (error.contains('Budget mensuel')) {
      userMessage = "💰 Budget mensuel atteint ! L'IA reviendra le mois prochain. En attendant, contactez notre support pour une aide personnalisée.";
    } else if (error.contains('Limite quotidienne')) {
      userMessage = "⏰ Vous avez utilisé toutes vos questions d'aujourd'hui ! Revenez demain pour continuer à explorer l'univers du tatouage.";
    } else if (error.contains('Limite mensuelle d\'images')) {
      userMessage = "🎨 Limite d'images atteinte ! Continuez à me poser des questions pour des conseils tatouage.";
    } else if (error.contains('insufficient_quota')) {
      userMessage = "💳 Quota OpenAI dépassé. L'administrateur doit recharger le compte.";
    } else {
      userMessage = "😕 Service temporairement indisponible. Réessayez dans quelques instants !";
    }
    
    return ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      text: userMessage,
      senderId: 'assistant',
      timestamp: DateTime.now(),
    );
  }

  /// 📊 Statistiques budget (pour ton dashboard admin)
  static Future<Map<String, dynamic>> getBudgetStats() async {
    final prefs = await SharedPreferences.getInstance();
    final monthlySpent = prefs.getDouble('monthly_spent') ?? 0.0;
    final remainingBudget = MONTHLY_BUDGET_EUROS - monthlySpent;
    
    return {
      'monthlyBudget': MONTHLY_BUDGET_EUROS,
      'spent': monthlySpent,
      'remaining': remainingBudget,
      'percentage': (monthlySpent / MONTHLY_BUDGET_EUROS * 100).round(),
      'configured': isConfigured,
    };
  }
}