import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kipik_v5/models/faq_item.dart';
import 'package:kipik_v5/models/tutorial.dart';
import 'package:kipik_v5/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Récupère les FAQs selon le type d'utilisateur (pro ou client)
  Future<List<FAQItem>> getFAQItems({required String userType}) async {
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
        print('Erreur lors du chargement des FAQs: $e');
      }
      
      // En cas d'erreur, essayer d'utiliser les données de démo
      return _getDemoFAQItems(userType: userType);
    }
  }
  
  // Récupère les tutoriels selon le type d'utilisateur (pro ou client)
  Future<List<Tutorial>> getTutorials({required String userType}) async {
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
        print('Erreur lors du chargement des tutoriels: $e');
      }
      
      // En cas d'erreur, essayer d'utiliser les données de démo
      return _getDemoTutorials(userType: userType);
    }
  }
  
  // Soumet une demande de support
  Future<void> submitSupportRequest({
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
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'envoi de la demande de support: $e');
      }
      
      // En mode démo ou debug, on simule un délai et on renvoie un succès
      if (kDebugMode) {
        await Future.delayed(Duration(seconds: 2));
        return;
      } else {
        throw e;
      }
    }
  }
  
  // Données de démo pour les FAQ (utilisées en cas d'erreur ou en mode développement)
  List<FAQItem> _getDemoFAQItems({required String userType}) {
    if (userType == 'pro') {
      return [
        FAQItem(
          id: '1',
          question: 'Comment modifier mes informations de facturation ?',
          answer: 'Pour modifier vos informations de facturation, accédez à votre profil en cliquant sur l\'icône en haut à droite, puis sélectionnez "Paramètres" > "Facturation". Vous pourrez y mettre à jour vos coordonnées, méthodes de paiement et préférences de facturation.',
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
          answer: 'Pour ajouter un nouvel utilisateur à votre compte professionnel, rendez-vous dans "Paramètres" > "Utilisateurs" > "Ajouter un utilisateur". Saisissez l\'adresse e-mail de la personne à inviter et sélectionnez son niveau d\'accès. Un e-mail d\'invitation sera automatiquement envoyé avec les instructions pour rejoindre votre espace.',
          category: 'Fonctionnalités',
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
          answer: 'Kipik propose trois formules d\'abonnement professionnel : Essentiel, Premium et Entreprise. La formule Essentiel comprend les fonctionnalités de base pour les petites entreprises. Premium ajoute des fonctionnalités avancées de personnalisation et d\'analyse. Entreprise offre un accompagnement dédié, une API complète et des fonctionnalités exclusives pour les grandes structures.',
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
          answer: 'Pour exporter vos données et statistiques, accédez à la section "Statistiques" depuis le menu principal. En haut à droite de chaque graphique ou tableau, vous trouverez une icône d\'exportation. Vous pouvez choisir le format d\'exportation (CSV, Excel, PDF) et la période concernée. Pour une exportation complète de toutes vos données, utilisez la fonction "Exportation globale" accessible depuis "Paramètres" > "Données et confidentialité".',
          category: 'Fonctionnalités',
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
          answer: 'Pour activer l\'authentification à deux facteurs (2FA), rendez-vous dans "Paramètres" > "Sécurité" > "Authentification". Cliquez sur "Activer l\'authentification à deux facteurs" et suivez les instructions. Vous pouvez choisir entre recevoir un code par SMS ou utiliser une application d\'authentification comme Google Authenticator ou Authy. Une fois configurée, vous devrez fournir un code à usage unique en plus de votre mot de passe lors de la connexion.',
          category: 'Sécurité',
          relatedLinks: [
            RelatedLink(
              label: 'Bonnes pratiques de sécurité',
              url: 'https://www.kipik.fr/aide/pro/securite-compte',
            ),
          ],
        ),
      ];
    } else {
      // FAQ pour les clients
      return [
        FAQItem(
          id: '1',
          question: 'Comment créer un compte Kipik ?',
          answer: 'Pour créer un compte Kipik, téléchargez l\'application depuis l\'App Store ou Google Play Store, puis cliquez sur "S\'inscrire". Vous pouvez vous inscrire avec votre adresse e-mail, ou via vos comptes Google ou Facebook. Suivez les instructions à l\'écran pour compléter votre profil.',
          category: 'Compte',
          relatedLinks: [
            RelatedLink(
              label: 'Télécharger l\'application',
              url: 'https://www.kipik.fr/telecharger',
            ),
          ],
        ),
        FAQItem(
          id: '2',
          question: 'Comment réinitialiser mon mot de passe ?',
          answer: 'Pour réinitialiser votre mot de passe, cliquez sur "Mot de passe oublié" sur l\'écran de connexion. Saisissez l\'adresse e-mail associée à votre compte et suivez les instructions envoyées par e-mail pour créer un nouveau mot de passe. Si vous ne recevez pas l\'e-mail, vérifiez votre dossier spam ou contactez notre support.',
          category: 'Compte',
          relatedLinks: [
            RelatedLink(
              label: 'Sécuriser mon compte',
              url: 'https://www.kipik.fr/aide/securite',
            ),
          ],
        ),
      ];
    }
  }
  
  // Données de démo pour les tutoriels (utilisées en cas d'erreur ou en mode développement)
  List<Tutorial> _getDemoTutorials({required String userType}) {
    if (userType == 'pro') {
      return [
        Tutorial(
          id: '1',
          title: 'Premiers pas avec Kipik Pro',
          description: 'Découvrez les fonctionnalités essentielles pour bien démarrer avec Kipik Pro.',
          content: 'Bienvenue sur Kipik Pro ! Ce tutoriel vous guidera à travers les premières étapes pour configurer votre compte professionnel et commencer à utiliser nos fonctionnalités avancées.\n\n1. Configuration du profil entreprise\n2. Personnalisation de votre espace\n3. Invitation de vos collaborateurs\n4. Configuration des paramètres de base\n5. Premiers ajouts de contenu\n\nPour commencer, accédez à votre tableau de bord en vous connectant à votre compte...',
          category: 'Abonnement',
          videoUrl: 'https://www.youtube.com/watch?v=example1',
          thumbnailUrl: 'https://example.com/thumbnails/getting-started.jpg',
        ),
        Tutorial(
          id: '2',
          title: 'Analyse des statistiques de performance',
          description: 'Apprenez à interpréter les données statistiques pour optimiser votre activité.',
          content: 'Les statistiques de Kipik Pro vous permettent de suivre l\'ensemble de vos performances et d\'identifier les opportunités d\'amélioration. Ce tutoriel détaille les différentes métriques disponibles et comment les exploiter efficacement.\n\nLe tableau de bord principal présente une vue d\'ensemble de vos performances. Vous pouvez y voir :\n\n- Le nombre total de clients\n- Le chiffre d\'affaires mensuel\n- Les tendances de croissance\n- Les sources de trafic\n\nPour accéder à des analyses plus détaillées, cliquez sur...',
          category: 'Fonctionnalités',
          videoUrl: null,
          thumbnailUrl: 'https://example.com/thumbnails/stats-analysis.jpg',
        ),
        Tutorial(
          id: '3',
          title: 'Configuration des notifications automatiques',
          description: 'Paramétrez les notifications pour vos clients et votre équipe.',
          content: 'Les notifications automatiques permettent d\'informer vos clients et collaborateurs des événements importants. Ce tutoriel vous guide pour les configurer selon vos besoins.\n\nTypes de notifications disponibles :\n\n1. Notifications client (confirmations, rappels, etc.)\n2. Notifications internes (nouvelles commandes, alertes, etc.)\n3. Rapports automatiques (quotidiens, hebdomadaires, mensuels)\n\nPour commencer la configuration, accédez à "Paramètres" > "Notifications"...',
          category: 'Fonctionnalités',
          videoUrl: 'https://www.youtube.com/watch?v=example3',
          thumbnailUrl: 'https://example.com/thumbnails/notifications.jpg',
        ),
        Tutorial(
          id: '4',
          title: 'Gestion des utilisateurs et des permissions',
          description: 'Contrôlez précisément qui a accès à quelles fonctionnalités dans votre espace.',
          content: 'La gestion des utilisateurs et des permissions vous permet de contrôler les accès à votre espace Kipik Pro. Ce tutoriel explique comment créer des rôles personnalisés et attribuer des permissions spécifiques.\n\nNiveaux d\'accès prédéfinis :\n\n1. Administrateur (accès complet)\n2. Gestionnaire (peut modifier mais pas supprimer)\n3. Éditeur (peut ajouter et modifier certains contenus)\n4. Lecteur (accès en lecture seule)\n\nPour créer un nouveau rôle personnalisé, accédez à "Paramètres" > "Utilisateurs" > "Rôles"...',
          category: 'Sécurité',
          videoUrl: null,
          thumbnailUrl: 'https://example.com/thumbnails/user-management.jpg',
        ),
        Tutorial(
          id: '5',
          title: 'Optimisation de votre facturation',
          description: 'Automatisez et personnalisez vos factures pour gagner du temps.',
          content: 'Une facturation efficace est essentielle pour toute entreprise. Ce tutoriel vous montre comment automatiser et personnaliser votre processus de facturation avec Kipik Pro.\n\nFonctionnalités abordées :\n\n1. Création de modèles de facture personnalisés\n2. Configuration de la numérotation automatique\n3. Mise en place de rappels de paiement\n4. Intégration avec votre logiciel comptable\n5. Gestion des taxes et remises\n\nPour commencer, accédez à "Facturation" dans votre menu principal...',
          category: 'Facturation',
          videoUrl: 'https://www.youtube.com/watch?v=example5',
          thumbnailUrl: 'https://example.com/thumbnails/invoicing.jpg',
        ),
      ];
    } else {
      // Tutoriels pour les clients
      return [
        Tutorial(
          id: '1',
          title: 'Comment créer votre premier projet',
          description: 'Apprenez à créer et configurer votre premier projet sur Kipik.',
          content: 'Ce tutoriel vous guide pas à pas pour créer votre premier projet sur l\'application Kipik...',
          category: 'Débutant',
          videoUrl: 'https://www.youtube.com/watch?v=example-client1',
          thumbnailUrl: 'https://example.com/thumbnails/first-project.jpg',
        ),
        Tutorial(
          id: '2',
          title: 'Partager vos créations avec vos amis',
          description: 'Découvrez les différentes façons de partager vos projets.',
          content: 'Kipik vous permet de partager facilement vos créations sur les réseaux sociaux ou directement avec vos contacts...',
          category: 'Fonctionnalités',
          videoUrl: null,
          thumbnailUrl: 'https://example.com/thumbnails/sharing.jpg',
        ),
      ];
    }
  }
}