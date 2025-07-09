// lib/utils/chat_helper.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/chat/ai_chat_bottom_sheet.dart';
import 'package:kipik_v5/services/chat/chat_manager.dart'; // ✅ AJOUTÉ
import 'package:flutter/material.dart';
import '../core/database_manager.dart';
import '../theme/kipik_theme.dart';

class ChatHelper {
  /// Ouvre l'assistant IA avec les bons paramètres partout dans l'app
  static void openAIAssistant(
    BuildContext context, {
    bool allowImageGeneration = false,
    String? contextPage,
    String? initialPrompt,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ CRUCIAL pour DraggableScrollableSheet
      useSafeArea: true, // ✅ AJOUTÉ pour la gestion des Safe Areas
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => AIChatBottomSheet(
        allowImageGeneration: allowImageGeneration,
        contextPage: contextPage,
        initialPrompt: initialPrompt ?? getContextualPrompt(contextPage),
      ),
    );
  }

  /// Obtient le prompt contextuel selon la page
  static String? getContextualPrompt(String? contextPage) {
    switch (contextPage) {
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
      case 'client':
        return 'J\'aimerais avoir des conseils pour mon projet de tatouage';
      default:
        return null; // Pas de prompt initial
    }
  }

  /// ✅ SIMPLIFIÉ: Vérifie si l'utilisateur peut utiliser l'IA
  static Future<bool> canOpenAIAssistant(BuildContext context) async {
    try {
      // Test simple en appelant les stats budget
      final stats = await ChatManager.getAIBudgetStats();
      final percentage = stats['percentage'] as int? ?? 0;
      
      // Si budget épuisé, afficher un message
      if (percentage >= 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💰 Budget IA épuisé ! Revenez le mois prochain.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return false;
      }
      
      return true;
    } catch (e) {
      // En cas d'erreur, laisser l'utilisateur essayer
      return true;
    }
  }

  /// ✅ SIMPLIFIÉ: Ouverture avec vérification préalable
  static Future<void> openAIAssistantSafe(
    BuildContext context, {
    bool allowImageGeneration = false,
    String? contextPage,
    String? initialPrompt,
  }) async {
    // Vérification budget général
    final canOpen = await canOpenAIAssistant(context);
    if (!canOpen) return;

    // Ouvrir normalement
    openAIAssistant(
      context,
      allowImageGeneration: allowImageGeneration,
      contextPage: contextPage,
      initialPrompt: initialPrompt,
    );
  }
}