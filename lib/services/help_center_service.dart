import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kipik_v5/models/faq_item.dart';
import 'package:kipik_v5/models/tutorial.dart';
import 'package:kipik_v5/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database_manager.dart'; // ✅ AJOUTÉ pour détecter le mode

/// Service de centre d'aide unifié (Production + Démo)
/// En mode démo : utilise des données factices réalistes avec cache simulé
/// En mode production : utilise l'API HTTP réelle avec cache SharedPreferences
class HelpCenterService with ChangeNotifier {
  final String _baseUrl = Constants.apiBaseUrl;
  
  // Cache des données
  List<FAQItem>? _cachedProFaqItems;
  List<FAQItem>? _cachedClientFaqItems;
  List<Tutorial>? _cachedProTutorials;
  List<Tutorial>? _cachedClientTutorials;
  DateTime? _lastFaqFetchTime;
  DateTime? _lastTutorialsFetchTime;
  
  // Durée de validité du cache (en heures)
  final int _cacheDuration = 24;

  // ✅ DONNÉES MOCK POUR LES DÉMOS
  final Map<String, List<Map<String, dynamic>>> _mockSupportRequests = {};
  int _mockRequestCounter = 1;

  /// ✅ MÉTHODE PRINCIPALE - Détection automatique du mode
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  /// ✅ RÉCUPÉRER FAQ (mode auto)
  Future<List<FAQItem>> getFAQItems({required String userType}) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Récupération FAQ factices');
      return await _getFAQItemsMock(userType: userType);
    } else {
      print('🏭 Mode production - Récupération FAQ réelles');
      return await _getFAQItemsHttp(userType: userType);
    }
  }

  /// ✅ HTTP - FAQ réelles
  Future<List<FAQItem>> _getFAQItemsHttp({required String userType}) async {
    // Vérifier si on a des données en cache et si elles sont encore valides
    if (userType == 'pro' && 
        _cachedProFaqItems != null && 
        _lastFaqFetchTime != null &&
        DateTime.now().difference(_lastFaqFetchTime!).inHours < _cacheDuration) {
      return _cachedProFaqItems!;
    } else if (userType == 'client' && 
        _cachedClientFaqItems != null && 
        _lastFaqFetchTime != null &&
        DateTime.now().difference(_lastFaqFetchTime!).inHours < _cacheDuration) {
      return _cachedClientFaqItems!;
    }
    
    try {
      // Tenter de récupérer les données depuis le stockage local
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('faq_${userType}_cache');
      
      if (cachedData != null) {
        final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(
          prefs.getInt('faq_${userType}_last_fetch') ?? 0
        );
        
        if (DateTime.now().difference(lastFetchTime).inHours < _cacheDuration) {
          final List<dynamic> decodedData = jsonDecode(cachedData);
          final List<FAQItem> faqItems = decodedData
              .map((item) => FAQItem.fromJson(item as Map<String, dynamic>))
              .toList();
          
          // Mettre à jour le cache en mémoire
          if (userType == 'pro') {
            _cachedProFaqItems = faqItems;
          } else {
            _cachedClientFaqItems = faqItems;
          }
          _lastFaqFetchTime = lastFetchTime;
          
          return faqItems;
        }
      }
      
      // Si pas de cache valide, faire une requête API
      final response = await http.get(
        Uri.parse('$_baseUrl/help-center/faq?userType=$userType'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<FAQItem> faqItems = data
            .map((item) => FAQItem.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Mettre à jour le cache
        prefs.setString('faq_${userType}_cache', response.body);
        prefs.setInt('faq_${userType}_last_fetch', DateTime.now().millisecondsSinceEpoch);
        
        // Mettre à jour le cache en mémoire
        if (userType == 'pro') {
          _cachedProFaqItems = faqItems;
        } else {
          _cachedClientFaqItems = faqItems;
        }
        _lastFaqFetchTime = DateTime.now();
        
        return faqItems;
      } else {
        throw Exception('Échec du chargement des FAQs: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des FAQs HTTP: $e');
      }
      
      // En cas d'erreur, utiliser les données de démo
      return _getEnhancedDemoFAQItems(userType: userType);
    }
  }

  /// ✅ MOCK - FAQ factices
  Future<List<FAQItem>> _getFAQItemsMock({required String userType}) async {
    await Future.delayed(const Duration(milliseconds: 400)); // Simuler latence réseau

    // Vérifier cache en mémoire
    if (userType == 'pro' && 
        _cachedProFaqItems != null && 
        _lastFaqFetchTime != null &&
        DateTime.now().difference(_lastFaqFetchTime!).inHours < _cacheDuration) {
      return _cachedProFaqItems!;
    } else if (userType == 'client' && 
        _cachedClientFaqItems != null && 
        _lastFaqFetchTime != null &&
        DateTime.now().difference(_lastFaqFetchTime!).inHours < _cacheDuration) {
      return _cachedClientFaqItems!;
    }

    // Générer données démo
    final faqItems = _getEnhancedDemoFAQItems(userType: userType);
    
    // Mettre à jour le cache en mémoire
    if (userType == 'pro') {
      _cachedProFaqItems = faqItems;
    } else {
      _cachedClientFaqItems = faqItems;
    }
    _lastFaqFetchTime = DateTime.now();
    
    return faqItems;
  }

  /// ✅ RÉCUPÉRER TUTORIELS (mode auto)
  Future<List<Tutorial>> getTutorials({required String userType}) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Récupération tutoriels factices');
      return await _getTutorialsMock(userType: userType);
    } else {
      print('🏭 Mode production - Récupération tutoriels réels');
      return await _getTutorialsHttp(userType: userType);
    }
  }

  /// ✅ HTTP - Tutoriels réels
  Future<List<Tutorial>> _getTutorialsHttp({required String userType}) async {
    // Vérifier si on a des données en cache et si elles sont encore valides
    if (userType == 'pro' && 
        _cachedProTutorials != null && 
        _lastTutorialsFetchTime != null &&
        DateTime.now().difference(_lastTutorialsFetchTime!).inHours < _cacheDuration) {
      return _cachedProTutorials!;
    } else if (userType == 'client' && 
        _cachedClientTutorials != null && 
        _lastTutorialsFetchTime != null &&
        DateTime.now().difference(_lastTutorialsFetchTime!).inHours < _cacheDuration) {
      return _cachedClientTutorials!;
    }
    
    try {
      // Tenter de récupérer les données depuis le stockage local
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('tutorials_${userType}_cache');
      
      if (cachedData != null) {
        final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(
          prefs.getInt('tutorials_${userType}_last_fetch') ?? 0
        );
        
        if (DateTime.now().difference(lastFetchTime).inHours < _cacheDuration) {
          final List<dynamic> decodedData = jsonDecode(cachedData);
          final List<Tutorial> tutorials = decodedData
              .map((item) => Tutorial.fromJson(item as Map<String, dynamic>))
              .toList();
          
          // Mettre à jour le cache en mémoire
          if (userType == 'pro') {
            _cachedProTutorials = tutorials;
          } else {
            _cachedClientTutorials = tutorials;
          }
          _lastTutorialsFetchTime = lastFetchTime;
          
          return tutorials;
        }
      }
      
      // Si pas de cache valide, faire une requête API
      final response = await http.get(
        Uri.parse('$_baseUrl/help-center/tutorials?userType=$userType'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Tutorial> tutorials = data
            .map((item) => Tutorial.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Mettre à jour le cache
        prefs.setString('tutorials_${userType}_cache', response.body);
        prefs.setInt('tutorials_${userType}_last_fetch', DateTime.now().millisecondsSinceEpoch);
        
        // Mettre à jour le cache en mémoire
        if (userType == 'pro') {
          _cachedProTutorials = tutorials;
        } else {
          _cachedClientTutorials = tutorials;
        }
        _lastTutorialsFetchTime = DateTime.now();
        
        return tutorials;
      } else {
        throw Exception('Échec du chargement des tutoriels: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des tutoriels HTTP: $e');
      }
      
      // En cas d'erreur, utiliser les données de démo
      return _getEnhancedDemoTutorials(userType: userType);
    }
  }

  /// ✅ MOCK - Tutoriels factices
  Future<List<Tutorial>> _getTutorialsMock({required String userType}) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simuler latence

    // Vérifier cache en mémoire
    if (userType == 'pro' && 
        _cachedProTutorials != null && 
        _lastTutorialsFetchTime != null &&
        DateTime.now().difference(_lastTutorialsFetchTime!).inHours < _cacheDuration) {
      return _cachedProTutorials!;
    } else if (userType == 'client' && 
        _cachedClientTutorials != null && 
        _lastTutorialsFetchTime != null &&
        DateTime.now().difference(_lastTutorialsFetchTime!).inHours < _cacheDuration) {
      return _cachedClientTutorials!;
    }

    // Générer données démo
    final tutorials = _getEnhancedDemoTutorials(userType: userType);
    
    // Mettre à jour le cache en mémoire
    if (userType == 'pro') {
      _cachedProTutorials = tutorials;
    } else {
      _cachedClientTutorials = tutorials;
    }
    _lastTutorialsFetchTime = DateTime.now();
    
    return tutorials;
  }

  /// ✅ SOUMETTRE DEMANDE SUPPORT (mode auto)
  Future<void> submitSupportRequest({
    required String userId,
    required String userEmail,
    required String subject,
    required String message,
    required String userType,
    List<String>? attachmentUrls,
  }) async {
    if (_isDemoMode) {
      await _submitSupportRequestMock(
        userId: userId,
        userEmail: userEmail,
        subject: subject,
        message: message,
        userType: userType,
        attachmentUrls: attachmentUrls,
      );
    } else {
      await _submitSupportRequestHttp(
        userId: userId,
        userEmail: userEmail,
        subject: subject,
        message: message,
        userType: userType,
        attachmentUrls: attachmentUrls,
      );
    }
  }

  /// ✅ HTTP - Demande support réelle
  Future<void> _submitSupportRequestHttp({
    required String userId,
    required String userEmail,
    required String subject,
    required String message,
    required String userType,
    List<String>? attachmentUrls,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/help-center/support-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userEmail': userEmail,
          'subject': subject,
          'message': message,
          'userType': userType,
          'attachmentUrls': attachmentUrls ?? [],
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Échec de l\'envoi de la demande: ${response.statusCode}');
      }
      
      print('✅ Demande de support envoyée avec succès');
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'envoi de la demande de support HTTP: $e');
      }
      
      // En mode debug, simuler un succès après délai
      if (kDebugMode) {
        await Future.delayed(const Duration(seconds: 2));
        return;
      } else {
        throw e;
      }
    }
  }

  /// ✅ MOCK - Demande support factice
  Future<void> _submitSupportRequestMock({
    required String userId,
    required String userEmail,
    required String subject,
    required String message,
    required String userType,
    List<String>? attachmentUrls,
  }) async {
    await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(500))); // Latence réaliste

    // Stocker la demande en mémoire pour simulation
    final requestId = 'DEMO-REQ-${_mockRequestCounter.toString().padLeft(6, '0')}';
    _mockRequestCounter++;

    final request = {
      'id': requestId,
      'userId': userId,
      'userEmail': userEmail,
      'subject': subject,
      'message': message,
      'userType': userType,
      'attachmentUrls': attachmentUrls ?? [],
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'received',
      'priority': ['low', 'medium', 'high'][Random().nextInt(3)],
      'estimatedResponseTime': '24-48h',
      '_source': 'mock',
      '_demoData': true,
    };

    if (!_mockSupportRequests.containsKey(userId)) {
      _mockSupportRequests[userId] = [];
    }
    _mockSupportRequests[userId]!.add(request);

    print('✅ Demande de support démo enregistrée: $requestId');
    print('   Sujet: $subject');
    print('   Status: ${request['status']}');
    print('   Réponse estimée: ${request['estimatedResponseTime']}');
  }

  /// ✅ OBTENIR HISTORIQUE SUPPORT (mode auto) - NOUVEAU
  Future<List<Map<String, dynamic>>> getSupportHistory({required String userId}) async {
    if (_isDemoMode) {
      return await _getSupportHistoryMock(userId: userId);
    } else {
      return await _getSupportHistoryHttp(userId: userId);
    }
  }

  /// ✅ HTTP - Historique support réel
  Future<List<Map<String, dynamic>>> _getSupportHistoryHttp({required String userId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/help-center/support-requests?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Échec récupération historique: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur récupération historique support: $e');
      }
      return [];
    }
  }

  /// ✅ MOCK - Historique support factice
  Future<List<Map<String, dynamic>>> _getSupportHistoryMock({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Retourner l'historique stocké + quelques demandes générées
    final userRequests = _mockSupportRequests[userId] ?? [];
    
    // Ajouter quelques demandes historiques si la liste est vide
    if (userRequests.isEmpty) {
      _generateMockSupportHistory(userId);
    }

    return List<Map<String, dynamic>>.from(_mockSupportRequests[userId] ?? []);
  }

  /// ✅ RECHERCHER FAQ (mode auto) - NOUVEAU
  Future<List<FAQItem>> searchFAQ({
    required String query,
    required String userType,
    String? category,
  }) async {
    final allFAQs = await getFAQItems(userType: userType);
    
    if (query.isEmpty) {
      return category != null 
          ? allFAQs.where((faq) => faq.category == category).toList()
          : allFAQs;
    }

    final queryLower = query.toLowerCase();
    var results = allFAQs.where((faq) {
      return faq.question.toLowerCase().contains(queryLower) ||
             faq.answer.toLowerCase().contains(queryLower) ||
             faq.category.toLowerCase().contains(queryLower);
    }).toList();

    if (category != null) {
      results = results.where((faq) => faq.category == category).toList();
    }

    return results;
  }

  /// ✅ OBTENIR CATÉGORIES FAQ (mode auto) - NOUVEAU
  Future<List<String>> getFAQCategories({required String userType}) async {
    final allFAQs = await getFAQItems(userType: userType);
    final categories = allFAQs.map((faq) => faq.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// ✅ MÉTHODE DE DIAGNOSTIC
  Future<void> debugHelpCenterService() async {
    print('🔍 Debug HelpCenterService:');
    print('  - Mode démo: $_isDemoMode');
    print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');

    if (_isDemoMode) {
      print('  - Demandes support mock: ${_mockSupportRequests.length} utilisateurs');
      final totalRequests = _mockSupportRequests.values.fold(0, (sum, list) => sum + list.length);
      print('  - Total demandes mock: $totalRequests');
    }

    print('  - Cache FAQ Pro: ${_cachedProFaqItems?.length ?? 0} items');
    print('  - Cache FAQ Client: ${_cachedClientFaqItems?.length ?? 0} items');
    print('  - Cache Tutoriels Pro: ${_cachedProTutorials?.length ?? 0} items');
    print('  - Cache Tutoriels Client: ${_cachedClientTutorials?.length ?? 0} items');
    print('  - Dernière MAJ FAQ: ${_lastFaqFetchTime?.toString() ?? 'Jamais'}');
    print('  - Dernière MAJ Tutoriels: ${_lastTutorialsFetchTime?.toString() ?? 'Jamais'}');

    // Test des fonctionnalités
    try {
      final proFAQs = await getFAQItems(userType: 'pro');
      final clientFAQs = await getFAQItems(userType: 'client');
      final proTutorials = await getTutorials(userType: 'pro');
      final clientTutorials = await getTutorials(userType: 'client');

      print('  - FAQ Pro récupérées: ${proFAQs.length}');
      print('  - FAQ Client récupérées: ${clientFAQs.length}');
      print('  - Tutoriels Pro récupérés: ${proTutorials.length}');
      print('  - Tutoriels Client récupérés: ${clientTutorials.length}');
    } catch (e) {
      print('  - Erreur test fonctionnalités: $e');
    }
  }

  // ========================
  // MÉTHODES PRIVÉES - GÉNÉRATION DONNÉES DÉMO
  // ========================

  void _generateMockSupportHistory(String userId) {
    final subjects = [
      'Problème de connexion à mon compte',
      'Question sur la facturation',
      'Demande de fonctionnalité',
      'Bug dans l\'application mobile',
      'Aide pour configurer mon profil',
      'Problème d\'affichage des statistiques',
    ];

    final statuses = ['resolved', 'in_progress', 'closed'];

    for (int i = 0; i < Random().nextInt(4) + 1; i++) {
      final requestId = 'DEMO-HIST-${(Random().nextInt(9000) + 1000)}';
      final daysAgo = Random().nextInt(60) + 1;
      
      final request = {
        'id': requestId,
        'userId': userId,
        'userEmail': 'demo@kipik.app',
        'subject': subjects[Random().nextInt(subjects.length)],
        'message': '[DÉMO] Description détaillée du problème rencontré...',
        'userType': 'pro',
        'attachmentUrls': [],
        'timestamp': DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String(),
        'status': statuses[Random().nextInt(statuses.length)],
        'priority': ['low', 'medium', 'high'][Random().nextInt(3)],
        'responseTime': '${Random().nextInt(48) + 2}h',
        '_source': 'mock',
        '_demoData': true,
      };

      if (!_mockSupportRequests.containsKey(userId)) {
        _mockSupportRequests[userId] = [];
      }
      _mockSupportRequests[userId]!.add(request);
    }
  }

  // ✅ DONNÉES DE DÉMO ENRICHIES
  List<FAQItem> _getEnhancedDemoFAQItems({required String userType}) {
    if (userType == 'pro') {
      return [
        FAQItem(
          id: '1',
          question: 'Comment modifier mes informations de facturation ?',
          answer: '[DÉMO] Pour modifier vos informations de facturation, accédez à votre profil en cliquant sur l\'icône en haut à droite, puis sélectionnez "Paramètres" > "Facturation". Vous pourrez y mettre à jour vos coordonnées, méthodes de paiement et préférences de facturation.\n\nLes modifications sont prises en compte immédiatement et s\'appliquent à votre prochaine facture.',
          category: 'Facturation',
          relatedLinks: [
            RelatedLink(
              label: 'Gérer vos méthodes de paiement',
              url: 'https://www.kipik.fr/aide/pro/paiement',
            ),
            RelatedLink(
              label: 'Consulter vos factures',
              url: 'https://www.kipik.fr/aide/pro/factures',
            ),
          ],
        ),
        FAQItem(
          id: '2',
          question: 'Comment ajouter un nouvel utilisateur à mon compte professionnel ?',
          answer: '[DÉMO] Pour ajouter un nouvel utilisateur à votre compte professionnel, rendez-vous dans "Paramètres" > "Utilisateurs" > "Ajouter un utilisateur". Saisissez l\'adresse e-mail de la personne à inviter et sélectionnez son niveau d\'accès.\n\nNiveaux d\'accès disponibles :\n• Administrateur : Accès complet\n• Gestionnaire : Modification sans suppression\n• Éditeur : Ajout et modification de contenu\n• Lecteur : Consultation uniquement\n\nUn e-mail d\'invitation sera automatiquement envoyé avec les instructions pour rejoindre votre espace.',
          category: 'Gestion équipe',
          relatedLinks: [
            RelatedLink(
              label: 'Gérer les accès utilisateurs',
              url: 'https://www.kipik.fr/aide/pro/utilisateurs',
            ),
          ],
        ),
        FAQItem(
          id: '3',
          question: 'Quelles sont les différences entre les formules d\'abonnement ?',
          answer: '[DÉMO] Kipik propose trois formules d\'abonnement professionnel adaptées à vos besoins :\n\n**Essentiel (29€/mois)**\n• Fonctionnalités de base\n• Jusqu\'à 5 utilisateurs\n• Support standard\n\n**Premium (79€/mois)**\n• Fonctionnalités avancées\n• Utilisateurs illimités\n• Analytics détaillées\n• Support prioritaire\n\n**Entreprise (149€/mois)**\n• Toutes les fonctionnalités\n• API complète\n• Accompagnement dédié\n• SLA garanti\n\nVous pouvez changer de formule à tout moment depuis votre espace de gestion.',
          category: 'Abonnement',
          relatedLinks: [
            RelatedLink(
              label: 'Comparer nos formules',
              url: 'https://www.kipik.fr/tarifs',
            ),
            RelatedLink(
              label: 'Changer de formule',
              url: 'https://www.kipik.fr/aide/pro/changer-formule',
            ),
          ],
        ),
        FAQItem(
          id: '4',
          question: 'Comment exporter mes données et statistiques ?',
          answer: '[DÉMO] Pour exporter vos données et statistiques, plusieurs options s\'offrent à vous :\n\n**Export par section :**\nAccédez à la section "Statistiques" depuis le menu principal. En haut à droite de chaque graphique ou tableau, cliquez sur l\'icône d\'exportation et choisissez le format souhaité (CSV, Excel, PDF).\n\n**Export global :**\nUtilisez la fonction "Exportation globale" accessible depuis "Paramètres" > "Données et confidentialité" pour télécharger toutes vos données d\'un coup.\n\n**Programmation d\'exports :**\nVous pouvez programmer des exports automatiques hebdomadaires ou mensuels pour recevoir vos statistiques par e-mail.',
          category: 'Données',
          relatedLinks: [
            RelatedLink(
              label: 'Guide d\'analyse des statistiques',
              url: 'https://www.kipik.fr/aide/pro/statistiques',
            ),
          ],
        ),
        FAQItem(
          id: '5',
          question: 'Comment sécuriser mon compte avec l\'authentification à deux facteurs ?',
          answer: '[DÉMO] L\'authentification à deux facteurs (2FA) ajoute une couche de sécurité supplémentaire à votre compte :\n\n**Activation :**\n1. Rendez-vous dans "Paramètres" > "Sécurité"\n2. Cliquez sur "Activer l\'authentification à deux facteurs"\n3. Choisissez votre méthode préférée\n\n**Méthodes disponibles :**\n• SMS : Recevez un code par texto\n• Application : Utilisez Google Authenticator, Authy ou similar\n• Clé de sécurité : Compatible FIDO2/WebAuthn\n\n**Important :** Conservez précieusement vos codes de récupération dans un endroit sûr.',
          category: 'Sécurité',
          relatedLinks: [
            RelatedLink(
              label: 'Bonnes pratiques de sécurité',
              url: 'https://www.kipik.fr/aide/pro/securite-compte',
            ),
          ],
        ),
        FAQItem(
          id: '6',
          question: 'Comment intégrer Kipik avec mon système existant ?',
          answer: '[DÉMO] Kipik offre plusieurs options d\'intégration pour s\'adapter à votre écosystème :\n\n**API REST complète :**\n• Documentation complète disponible\n• Authentification sécurisée OAuth 2.0\n• Webhooks pour notifications en temps réel\n\n**Connecteurs prêts à l\'emploi :**\n• CRM : Salesforce, HubSpot, Pipedrive\n• Comptabilité : QuickBooks, Sage, Cegid\n• E-commerce : Shopify, WooCommerce, Prestashop\n\n**Support technique dédié :**\nNotre équipe technique vous accompagne dans la mise en œuvre de l\'intégration.',
          category: 'Intégrations',
          relatedLinks: [
            RelatedLink(
              label: 'Documentation API',
              url: 'https://developers.kipik.fr',
            ),
          ],
        ),
      ];
    } else {
      // FAQ pour les clients avec plus de contenu
      return [
        FAQItem(
          id: '1',
          question: 'Comment créer un compte Kipik ?',
          answer: '[DÉMO] Créer un compte Kipik est simple et rapide :\n\n**Étape 1 : Téléchargement**\nTéléchargez l\'application depuis l\'App Store (iOS) ou Google Play Store (Android).\n\n**Étape 2 : Inscription**\n• Ouvrez l\'application\n• Cliquez sur "S\'inscrire"\n• Choisissez votre méthode : e-mail, Google, Facebook ou Apple\n\n**Étape 3 : Vérification**\n• Confirmez votre adresse e-mail\n• Complétez votre profil\n• Ajoutez une photo (optionnel)\n\n**Étape 4 : Découverte**\nSuivez le tour guidé pour découvrir les fonctionnalités principales.',
          category: 'Compte',
          relatedLinks: [
            RelatedLink(
              label: 'Télécharger l\'application',
              url: 'https://www.kipik.fr/telecharger',
            ),
            RelatedLink(
              label: 'Guide de première utilisation',
              url: 'https://www.kipik.fr/aide/premiers-pas',
            ),
          ],
        ),
        FAQItem(
          id: '2',
          question: 'Comment réinitialiser mon mot de passe ?',
          answer: '[DÉMO] Pour réinitialiser votre mot de passe en toute sécurité :\n\n**Sur l\'application mobile :**\n1. Ouvrez l\'application Kipik\n2. Sur l\'écran de connexion, tapez "Mot de passe oublié"\n3. Saisissez votre adresse e-mail\n4. Vérifiez votre boîte mail (et vos spams)\n5. Cliquez sur le lien reçu\n6. Créez votre nouveau mot de passe\n\n**Sur le site web :**\nLa procédure est identique depuis www.kipik.fr\n\n**Conseils sécurité :**\n• Utilisez un mot de passe unique et complexe\n• Activez l\'authentification à deux facteurs\n• Ne partagez jamais vos identifiants',
          category: 'Compte',
          relatedLinks: [
            RelatedLink(
              label: 'Sécuriser mon compte',
              url: 'https://www.kipik.fr/aide/securite',
            ),
          ],
        ),
        FAQItem(
          id: '3',
          question: 'Comment trouver un tatoueur près de moi ?',
          answer: '[DÉMO] Kipik vous aide à trouver le tatoueur parfait près de chez vous :\n\n**Recherche géolocalisée :**\n• Autorisez la géolocalisation dans l\'app\n• Utilisez l\'onglet "Explorer" > "Près de moi"\n• Ajustez le rayon de recherche (5 à 100 km)\n\n**Filtres de recherche :**\n• Style de tatouage (traditionnel, réalisme, etc.)\n• Note minimum des clients\n• Tarifs\n• Disponibilité\n\n**Informations détaillées :**\n• Portfolio complet\n• Avis clients vérifiés\n• Tarifs et disponibilités\n• Contact direct via l\'app',
          category: 'Recherche',
          relatedLinks: [
            RelatedLink(
              label: 'Guide de recherche avancée',
              url: 'https://www.kipik.fr/aide/recherche-tatoueur',
            ),
          ],
        ),
        FAQItem(
          id: '4',
          question: 'Comment prendre rendez-vous avec un tatoueur ?',
          answer: '[DÉMO] Prendre rendez-vous via Kipik est simple et sécurisé :\n\n**Étapes de réservation :**\n1. Consultez le profil du tatoueur\n2. Vérifiez ses disponibilités en temps réel\n3. Choisissez un créneau libre\n4. Décrivez votre projet en détail\n5. Joignez des images de référence\n6. Confirmez votre demande\n\n**Validation du rendez-vous :**\n• Le tatoueur examine votre demande\n• Il peut vous poser des questions\n• Il confirme ou propose un autre créneau\n• Vous recevez une notification de confirmation\n\n**Avant le rendez-vous :**\n• Rappel automatique 24h avant\n• Possibilité de reporter si nécessaire\n• Préparation avec les conseils du tatoueur',
          category: 'Rendez-vous',
          relatedLinks: [
            RelatedLink(
              label: 'Préparer son premier tatouage',
              url: 'https://www.kipik.fr/aide/premier-tatouage',
            ),
          ],
        ),
      ];
    }
  }

  List<Tutorial> _getEnhancedDemoTutorials({required String userType}) {
    if (userType == 'pro') {
      return [
        Tutorial(
          id: '1',
          title: 'Premiers pas avec Kipik Pro',
          description: '[DÉMO] Découvrez les fonctionnalités essentielles pour bien démarrer avec Kipik Pro et maximiser votre succès.',
          content: '[DÉMO] Bienvenue sur Kipik Pro ! Ce tutoriel vous guidera à travers les premières étapes pour configurer votre compte professionnel et commencer à utiliser nos fonctionnalités avancées.\n\n**1. Configuration du profil entreprise**\n• Ajoutez votre logo et informations de contact\n• Définissez vos spécialités et styles\n• Configurez vos tarifs et disponibilités\n\n**2. Personnalisation de votre espace**\n• Choisissez votre thème et couleurs\n• Organisez votre portfolio\n• Configurez vos notifications\n\n**3. Invitation de vos collaborateurs**\n• Définissez les rôles et permissions\n• Envoyez les invitations par email\n• Formez votre équipe aux bonnes pratiques\n\n**4. Configuration des paramètres de base**\n• Modes de paiement acceptés\n• Politiques d\'annulation\n• Conditions générales\n\n**5. Premiers ajouts de contenu**\n• Upload de votre portfolio\n• Création de vos premiers services\n• Publication de votre profil\n\nPour commencer, accédez à votre tableau de bord en vous connectant à votre compte...',
          category: 'Démarrage',
          videoUrl: 'https://www.youtube.com/watch?v=demoKipikPro1',
          thumbnailUrl: 'https://picsum.photos/seed/tutorial1/640/360',
        ),
        Tutorial(
          id: '2',
          title: 'Analyse des statistiques de performance',
          description: '[DÉMO] Apprenez à interpréter les données statistiques pour optimiser votre activité et augmenter vos revenus.',
          content: '[DÉMO] Les statistiques de Kipik Pro vous permettent de suivre l\'ensemble de vos performances et d\'identifier les opportunités d\'amélioration. Ce tutoriel détaille les différentes métriques disponibles et comment les exploiter efficacement.\n\n**Le tableau de bord principal présente :**\n• Nombre total de clients et prospects\n• Chiffre d\'affaires mensuel et évolution\n• Tendances de croissance et saisonnalité\n• Sources de trafic et conversion\n• Taux de satisfaction client\n\n**Analyses détaillées disponibles :**\n• Performance par style de tatouage\n• Répartition géographique de votre clientèle\n• Temps de réponse moyen\n• Taux de conversion des devis\n• Revenus par client (LTV)\n\n**Comment optimiser grâce aux données :**\n• Identifiez vos services les plus rentables\n• Ajustez vos tarifs selon la demande\n• Optimisez vos créneaux de disponibilité\n• Améliorez votre taux de conversion\n\nPour accéder à des analyses plus détaillées, cliquez sur...',
          category: 'Analytics',
          videoUrl: null,
          thumbnailUrl: 'https://picsum.photos/seed/tutorial2/640/360',
        ),
        Tutorial(
          id: '3',
          title: 'Configuration des notifications automatiques',
          description: '[DÉMO] Paramétrez les notifications pour vos clients et votre équipe afin d\'améliorer la communication et la satisfaction.',
          content: '[DÉMO] Les notifications automatiques permettent d\'informer vos clients et collaborateurs des événements importants. Ce tutoriel vous guide pour les configurer selon vos besoins et votre style de communication.\n\n**Types de notifications client :**\n• Confirmations de rendez-vous\n• Rappels 24h et 2h avant\n• Demandes de feedback post-service\n• Promotions et offres spéciales\n• Conseils de soins après tatouage\n\n**Notifications internes équipe :**\n• Nouvelles demandes de rendez-vous\n• Annulations et modifications\n• Alertes de planning\n• Objectifs et performances\n• Messages clients urgents\n\n**Rapports automatiques :**\n• Statistiques quotidiennes\n• Résumés hebdomadaires\n• Bilans mensuels\n• Analyses trimestrielles\n\n**Personnalisation avancée :**\n• Ton et style de communication\n• Horaires d\'envoi optimaux\n• Fréquence et timing\n• Templates personnalisés\n\nPour commencer la configuration, accédez à "Paramètres" > "Notifications"...',
          category: 'Communication',
          videoUrl: 'https://www.youtube.com/watch?v=demoKipikPro3',
          thumbnailUrl: 'https://picsum.photos/seed/tutorial3/640/360',
        ),
        Tutorial(
          id: '4',
          title: 'Gestion des utilisateurs et des permissions',
          description: '[DÉMO] Contrôlez précisément qui a accès à quelles fonctionnalités dans votre espace pour une sécurité optimale.',
          content: '[DÉMO] La gestion des utilisateurs et des permissions vous permet de contrôler les accès à votre espace Kipik Pro. Ce tutoriel explique comment créer des rôles personnalisés et attribuer des permissions spécifiques selon les besoins de votre équipe.\n\n**Niveaux d\'accès prédéfinis :**\n• **Propriétaire** : Contrôle total, facturation, suppression\n• **Administrateur** : Accès complet sauf facturation\n• **Gestionnaire** : Peut modifier mais pas supprimer\n• **Tatoueur** : Gère ses rendez-vous et portfolio\n• **Accueil** : Consultation et prise de rendez-vous\n• **Lecteur** : Accès en lecture seule aux statistiques\n\n**Permissions détaillées :**\n• Gestion des rendez-vous\n• Modification des tarifs\n• Accès aux statistiques financières\n• Gestion du portfolio\n• Communication avec les clients\n• Paramétrage de l\'espace\n\n**Bonnes pratiques de sécurité :**\n• Principe du moindre privilège\n• Révision régulière des accès\n• Audit des connexions\n• Mots de passe forts obligatoires\n\nPour créer un nouveau rôle personnalisé, accédez à "Paramètres" > "Utilisateurs" > "Rôles"...',
          category: 'Sécurité',
          videoUrl: null,
          thumbnailUrl: 'https://picsum.photos/seed/tutorial4/640/360',
        ),
        Tutorial(
          id: '5',
          title: 'Optimisation de votre facturation',
          description: '[DÉMO] Automatisez et personnalisez vos factures pour gagner du temps et améliorer votre trésorerie.',
          content: '[DÉMO] Une facturation efficace est essentielle pour toute entreprise. Ce tutoriel vous montre comment automatiser et personnaliser votre processus de facturation avec Kipik Pro pour optimiser votre trésorerie et votre relation client.\n\n**Fonctionnalités de facturation :**\n• Devis automatiques avec templates\n• Facturation pro avec votre identité\n• Gestion des acomptes et échelonnements\n• Relances automatiques de paiement\n• Intégration comptable\n\n**Personnalisation avancée :**\n• Templates de facture à votre image\n• Numérotation automatique\n• Mentions légales personnalisées\n• Conditions de paiement flexibles\n• Multidevises pour l\'international\n\n**Automatisation intelligente :**\n• Génération automatique après service\n• Envoi par email avec accusé de réception\n• Relances programmées J+30, J+45, J+60\n• Notifications de paiement reçu\n• Archivage automatique\n\n**Intégrations comptables :**\n• Export vers votre logiciel comptable\n• Synchronisation avec votre banque\n• Rapports TVA automatiques\n• Déclarations simplifiées\n\nPour commencer, accédez à "Facturation" dans votre menu principal...',
          category: 'Facturation',
          videoUrl: 'https://www.youtube.com/watch?v=demoKipikPro5',
          thumbnailUrl: 'https://picsum.photos/seed/tutorial5/640/360',
        ),
        Tutorial(
          id: '6',
          title: 'Marketing et fidélisation client',
          description: '[DÉMO] Développez votre clientèle et fidélisez vos clients avec nos outils marketing intégrés.',
          content: '[DÉMO] Kipik Pro vous offre des outils marketing puissants pour développer votre activité et fidéliser votre clientèle. Ce tutoriel vous montre comment créer des campagnes efficaces et mesurer leur impact.\n\n**Outils de prospection :**\n• Pages de capture optimisées\n• Formulaires de contact intelligents\n• SEO local automatique\n• Référencement Google My Business\n• Intégration réseaux sociaux\n\n**Campagnes de fidélisation :**\n• Programmes de fidélité personnalisés\n• Emails de suivi automatiques\n• Offres anniversaire et saisonnières\n• Parrainage avec récompenses\n• Enquêtes de satisfaction\n\n**Marketing automation :**\n• Scénarios email personnalisés\n• Segmentation client avancée\n• Scoring comportemental\n• Retargeting automatique\n• A/B testing intégré\n\n**Mesure de performance :**\n• ROI des campagnes\n• Taux d\'ouverture et clics\n• Conversion et attribution\n• LTV client\n• Coût d\'acquisition\n\nPour lancer votre première campagne...',
          category: 'Marketing',
          videoUrl: 'https://www.youtube.com/watch?v=demoKipikPro6',
          thumbnailUrl: 'https://picsum.photos/seed/tutorial6/640/360',
        ),
      ];
    } else {
      // Tutoriels pour les clients avec plus de contenu
      return [
        Tutorial(
          id: '1',
          title: 'Comment créer votre premier projet de tatouage',
          description: '[DÉMO] Guide complet pour créer et configurer votre premier projet de tatouage sur Kipik, de l\'idée à la réalisation.',
          content: '[DÉMO] Ce tutoriel vous guide pas à pas pour créer votre premier projet de tatouage sur l\'application Kipik. Vous apprendrez à exprimer votre vision, choisir le bon tatoueur et préparer votre séance.\n\n**Étape 1 : Définir votre projet**\n• Décrivez votre idée en détail\n• Choisissez l\'emplacement sur votre corps\n• Estimez la taille souhaitée\n• Définissez votre budget\n• Sélectionnez le style artistique\n\n**Étape 2 : Rassembler vos références**\n• Créez un mood board\n• Collectez des images d\'inspiration\n• Notez les éléments importants\n• Précisez les couleurs souhaitées\n• Ajoutez des détails personnels\n\n**Étape 3 : Rechercher le bon tatoueur**\n• Filtrez par style et localisation\n• Consultez les portfolios\n• Lisez les avis clients\n• Vérifiez les certifications\n• Comparez les tarifs\n\n**Étape 4 : Prendre contact**\n• Envoyez votre projet détaillé\n• Planifiez une consultation\n• Discutez des adaptations\n• Validez le devis\n• Programmez la séance\n\n**Conseils pour un premier tatouage réussi**\n• Prenez votre temps pour réfléchir\n• N\'hésitez pas à poser des questions\n• Préparez-vous physiquement et mentalement\n• Suivez les conseils d\'hygiène\n• Planifiez la cicatrisation',
          category: 'Projets',
          videoUrl: 'https://www.youtube.com/watch?v=demoKipikClient1',
          thumbnailUrl: 'https://picsum.photos/seed/client-tutorial1/640/360',
        ),
        Tutorial(
          id: '2',
          title: 'Partager vos créations avec la communauté',
          description: '[DÉMO] Découvrez comment partager vos tatouages, obtenir des retours et inspirer d\'autres passionnés sur Kipik.',
          content: '[DÉMO] Kipik vous permet de partager facilement vos créations avec une communauté de passionnés. Ce tutoriel vous montre comment mettre en valeur vos tatouages et interagir avec d\'autres utilisateurs.\n\n**Photographier votre tatouage :**\n• Utilisez un bon éclairage naturel\n• Nettoyez délicatement la zone\n• Trouvez le bon angle\n• Évitez les reflets et ombres\n• Prenez plusieurs photos\n\n**Publier sur Kipik :**\n• Accédez à "Mon Portfolio"\n• Cliquez sur "Ajouter une création"\n• Téléchargez vos meilleures photos\n• Rédigez une description engageante\n• Ajoutez les tags appropriés\n• Mentionnez votre tatoueur\n• Partagez votre histoire\n\n**Optimiser votre visibilité :**\n• Utilisez des hashtags pertinents\n• Décrivez le processus créatif\n• Mentionnez l\'inspiration\n• Ajoutez la localisation\n• Interagissez avec les commentaires\n\n**Partage externe :**\n• Instagram et Facebook intégrés\n• Liens directs à envoyer\n• QR codes pour portfolio\n• Export haute qualité\n• Stories temporaires\n\n**Rejoindre la communauté :**\n• Likez et commentez\n• Suivez vos tatoueurs favoris\n• Participez aux défis\n• Partagez vos conseils\n• Organisez des meetups locaux',
          category: 'Communauté',
          videoUrl: null,
          thumbnailUrl: 'https://picsum.photos/seed/client-tutorial2/640/360',
        ),
        Tutorial(
          id: '3',
          title: 'Préparer et entretenir votre tatouage',
          description: '[DÉMO] Guide complet pour bien préparer votre séance de tatouage et assurer une cicatrisation optimale.',
          content: '[DÉMO] Un tatouage réussi commence avant la séance et se termine bien après. Ce guide vous accompagne dans toutes les étapes pour un résultat optimal et une cicatrisation parfaite.\n\n**Préparation avant la séance :**\n• Dormez suffisamment la veille\n• Mangez un bon repas 2h avant\n• Hydratez-vous bien\n• Évitez alcool et drogues\n• Rasez la zone si nécessaire\n• Portez des vêtements adaptés\n• Préparez votre trousse de soins\n\n**Pendant la séance :**\n• Respirez calmement et profondément\n• Communiquez avec votre tatoueur\n• Faites des pauses si nécessaire\n• Hydratez-vous régulièrement\n• Évitez de regarder si ça vous stresse\n• Écoutez de la musique relaxante\n\n**Soins post-tatouage (J0 à J3) :**\n• Retirez le pansement après 2-4h\n• Nettoyez délicatement à l\'eau tiède\n• Appliquez une crème cicatrisante\n• Évitez les frottements\n• Pas de bain ni piscine\n• Protégez du soleil\n\n**Cicatrisation (J4 à J21) :**\n• Continuez les soins quotidiens\n• Hydratez avec une crème neutre\n• Ne grattez pas les croûtes\n• Évitez les vêtements serrés\n• Surveillez les signes d\'infection\n• Consultez si problème\n\n**Entretien à long terme :**\n• Protection solaire systématique\n• Hydratation régulière\n• Retouches si nécessaire\n• Photos d\'évolution\n• Suivi avec votre tatoueur',
          category: 'Soins',
          videoUrl: 'https://www.youtube.com/watch?v=demoKipikClient3',
          thumbnailUrl: 'https://picsum.photos/seed/client-tutorial3/640/360',
        ),
      ];
    }
  }
}