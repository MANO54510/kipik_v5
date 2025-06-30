// lib/services/quote/enhanced_quote_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/quote_request.dart';
import '../auth/auth_service.dart';
import 'quote_service.dart';

/// Service de devis complet avec gestion des séances, documents et paiements
class EnhancedQuoteService extends QuoteService {
  static EnhancedQuoteService? _instance;
  static EnhancedQuoteService get instance => _instance ??= EnhancedQuoteService._();
  EnhancedQuoteService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _quotesCollection = 'quotes';
  static const String _templatesCollection = 'quote_templates';

  @override
  Future<List<QuoteRequest>> fetchRequestsForPro() async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final snapshot = await _firestore
          .collection(_quotesCollection)
          .where('tattooistId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => _enhancedQuoteFromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur récupération devis pro: $e');
    }
  }

  @override
  Future<List<QuoteRequest>> fetchRequestsForParticulier() async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final snapshot = await _firestore
          .collection(_quotesCollection)
          .where('clientId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => _enhancedQuoteFromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur récupération devis client: $e');
    }
  }

  @override
  Future<QuoteRequest> fetchRequestDetail(String id) async {
    try {
      final doc = await _firestore.collection(_quotesCollection).doc(id).get();
      if (!doc.exists) throw Exception('Devis introuvable');
      return _enhancedQuoteFromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur récupération détail devis: $e');
    }
  }

  @override
  Future<void> acceptRequest(String id) async {
    try {
      await _updateQuoteStatus(id, QuoteStatus.Quoted);
      await _sendNotification(id, 'client', 'Votre demande a été acceptée');
    } catch (e) {
      throw Exception('Erreur acceptation devis: $e');
    }
  }

  @override
  Future<void> refuseRequest(String id) async {
    try {
      await _updateQuoteStatus(id, QuoteStatus.Refused);
      await _sendNotification(id, 'client', 'Votre demande a été refusée');
    } catch (e) {
      throw Exception('Erreur refus devis: $e');
    }
  }

  @override
  Future<void> sendQuote(String id, double price, String details) async {
    // Méthode basique - utilisez sendDetailedQuote pour plus de fonctionnalités
    await sendDetailedQuote(id, {
      'totalPrice': price,
      'description': details,
      'sessions': [
        {
          'sessionNumber': 1,
          'duration': 3.0,
          'price': price,
          'description': details,
        }
      ],
    });
  }

  /// Envoi d'un devis détaillé complet
  Future<void> sendDetailedQuote(String quoteId, Map<String, dynamic> quoteData) async {
    try {
      final updates = {
        'status': QuoteStatus.Quoted.name,
        'totalPrice': quoteData['totalPrice'],
        'description': quoteData['description'],
        
        // SÉANCES ET PLANNING
        'sessions': quoteData['sessions'], // Liste des séances prévues
        'totalHours': quoteData['totalHours'],
        'totalSessions': quoteData['totalSessions'],
        'estimatedDuration': quoteData['estimatedDuration'], // En semaines
        
        // DATES PROPOSÉES
        'proposedDates': quoteData['proposedDates'], // Liste de créneaux
        'flexibility': quoteData['flexibility'], // 'strict', 'flexible', 'very_flexible'
        
        // MODALITÉS DE PAIEMENT
        'paymentTerms': {
          'depositAmount': quoteData['depositAmount'], // Acompte
          'depositPercentage': quoteData['depositPercentage'], // % d'acompte
          'paymentSchedule': quoteData['paymentSchedule'], // 'per_session', 'end', 'split'
          'acceptedMethods': quoteData['acceptedMethods'], // ['card', 'transfer', '4x']
          'lateFees': quoteData['lateFees'], // Frais de retard
        },
        
        // DOCUMENTS OBLIGATOIRES
        'requiredDocuments': [
          {
            'type': 'consent_form',
            'name': 'Fiche de décharge',
            'mandatory': true,
            'template': 'consent_template_v1',
            'needsSignature': true,
          },
          {
            'type': 'care_instructions',
            'name': 'Fiche de soins',
            'mandatory': true,
            'template': 'care_template_v1',
            'needsSignature': true,
          },
          {
            'type': 'medical_history',
            'name': 'Questionnaire médical',
            'mandatory': true,
            'template': 'medical_template_v1',
            'needsSignature': false,
          }
        ],
        
        // CONDITIONS GÉNÉRALES
        'terms': {
          'cancellationPolicy': quoteData['cancellationPolicy'],
          'reschedulePolicy': quoteData['reschedulePolicy'],
          'refundPolicy': quoteData['refundPolicy'],
          'hygieneRequirements': quoteData['hygieneRequirements'],
        },
        
        // MÉTA-DONNÉES
        'quotedAt': FieldValue.serverTimestamp(),
        'clientRespondBy': Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
        'validUntil': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
        'updatedAt': FieldValue.serverTimestamp(),
        'version': 1,
        'currency': 'EUR',
        'taxRate': 0.20, // TVA 20%
        'includesTax': true,
      };

      await _firestore.collection(_quotesCollection).doc(quoteId).update(updates);
      
      // Générer le PDF du devis
      await _generateQuotePDF(quoteId);
      
      // Préparer les documents à signer
      await _prepareDocuments(quoteId);
      
      // Notification client
      await _sendNotification(quoteId, 'client', 'Votre devis détaillé est prêt !');
      
      // Historique
      await _addToHistory(quoteId, 'Devis envoyé', 'Devis complet avec ${quoteData['totalSessions']} séances');
      
    } catch (e) {
      throw Exception('Erreur envoi devis détaillé: $e');
    }
  }

  @override
  Future<void> clientAccept(String id) async {
    try {
      // Vérifier que tous les documents sont signés
      final documentsComplete = await _areAllDocumentsSigned(id);
      if (!documentsComplete) {
        throw Exception('Tous les documents obligatoires doivent être signés avant validation');
      }

      await _updateQuoteStatus(id, QuoteStatus.Accepted);
      
      // Créer le projet automatiquement
      final projectId = await _createProjectFromQuote(id);
      
      // Programmer les séances
      await _scheduleSessionsFromQuote(id, projectId);
      
      // Créer les échéances de paiement
      await _createPaymentSchedule(id, projectId);
      
      await _sendNotification(id, 'tattooist', 'Devis accepté ! Projet créé automatiquement.');
      
    } catch (e) {
      throw Exception('Erreur acceptation client: $e');
    }
  }

  @override
  Future<void> clientRefuse(String id) async {
    try {
      await _updateQuoteStatus(id, QuoteStatus.Refused);
      await _sendNotification(id, 'tattooist', 'Devis refusé par le client');
    } catch (e) {
      throw Exception('Erreur refus client: $e');
    }
  }

  /// Sauvegarder un template de devis pour réutilisation
  Future<String> saveQuoteTemplate({
    required String name,
    required Map<String, dynamic> templateData,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final docRef = await _firestore.collection(_templatesCollection).add({
        'tattooistId': currentUser.uid,
        'name': name,
        'templateData': templateData,
        'createdAt': FieldValue.serverTimestamp(),
        'usageCount': 0,
        'isActive': true,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur sauvegarde template: $e');
    }
  }

  /// Récupérer les templates de devis d'un tatoueur
  Future<List<Map<String, dynamic>>> getQuoteTemplates() async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) return [];

      final snapshot = await _firestore
          .collection(_templatesCollection)
          .where('tattooistId', isEqualTo: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('usageCount', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Génération PDF du devis
  Future<String> _generateQuotePDF(String quoteId) async {
    try {
      // TODO: Intégrer avec un service de génération PDF
      // Ex: pdf package + Firebase Storage
      
      final pdfUrl = 'https://storage.googleapis.com/quotes/$quoteId.pdf';
      
      // Sauvegarder l'URL du PDF dans le devis
      await _firestore.collection(_quotesCollection).doc(quoteId).update({
        'pdfUrl': pdfUrl,
        'pdfGeneratedAt': FieldValue.serverTimestamp(),
      });
      
      return pdfUrl;
    } catch (e) {
      throw Exception('Erreur génération PDF: $e');
    }
  }

  /// Préparer les documents pour signature électronique
  Future<void> _prepareDocuments(String quoteId) async {
    try {
      final quoteDoc = await _firestore.collection(_quotesCollection).doc(quoteId).get();
      final quoteData = quoteDoc.data()!;
      
      final requiredDocs = quoteData['requiredDocuments'] as List<dynamic>;
      
      for (final doc in requiredDocs) {
        if (doc['needsSignature'] == true) {
          // TODO: Intégrer avec DocuSign, HelloSign, ou autre service de signature
          // Créer le document à partir du template
          // Envoyer pour signature
          
          await _firestore
              .collection(_quotesCollection)
              .doc(quoteId)
              .collection('documents')
              .add({
            'type': doc['type'],
            'name': doc['name'],
            'template': doc['template'],
            'status': 'pending_signature',
            'createdAt': FieldValue.serverTimestamp(),
            'signingUrl': 'https://example.com/sign/$quoteId/${doc['type']}',
          });
        }
      }
    } catch (e) {
      print('Erreur préparation documents: $e');
    }
  }

  /// Vérifier que tous les documents sont signés
  Future<bool> _areAllDocumentsSigned(String quoteId) async {
    try {
      final snapshot = await _firestore
          .collection(_quotesCollection)
          .doc(quoteId)
          .collection('documents')
          .where('status', isNotEqualTo: 'signed')
          .get();
      
      return snapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Créer un projet à partir du devis accepté
  Future<String> _createProjectFromQuote(String quoteId) async {
    try {
      final quoteDoc = await _firestore.collection(_quotesCollection).doc(quoteId).get();
      final quoteData = quoteDoc.data()!;

      final projectData = {
        'titre': quoteData['projectTitle'] ?? 'Projet tatouage',
        'style': quoteData['style'] ?? '',
        'endroit': quoteData['location'] ?? '',
        'tatoueur': quoteData['tattooistId'],
        'montant': quoteData['totalPrice'] ?? 0.0,
        'acompte': quoteData['paymentTerms']['depositAmount'] ?? 0.0,
        'statut': 'confirme',
        'dateDevis': DateTime.now().toIso8601String(),
        'quoteId': quoteId,
        'clientId': quoteData['clientId'],
        'sessions': quoteData['sessions'] ?? [],
        'paymentSchedule': quoteData['paymentTerms'],
        'requiredDocuments': quoteData['requiredDocuments'],
        'createdAt': FieldValue.serverTimestamp(),
        'totalHours': quoteData['totalHours'],
        'estimatedCompletion': quoteData['estimatedDuration'],
      };

      final docRef = await _firestore.collection('projects').add(projectData);
      
      // Lier le projet au devis
      await _firestore.collection(_quotesCollection).doc(quoteId).update({
        'projectId': docRef.id,
        'projectCreatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur création projet: $e');
    }
  }

  /// Programmer les séances du projet
  Future<void> _scheduleSessionsFromQuote(String quoteId, String projectId) async {
    // TODO: Intégrer avec un système de calendrier/planning
    print('Programmation des séances pour le projet $projectId');
  }

  /// Créer l'échéancier de paiement
  Future<void> _createPaymentSchedule(String quoteId, String projectId) async {
    // TODO: Intégrer avec Stripe pour créer les paiements programmés
    print('Création échéancier paiement pour le projet $projectId');
  }

  // MÉTHODES PRIVÉES COMMUNES

  QuoteRequest _enhancedQuoteFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return QuoteRequest(
      id: doc.id,
      clientName: data['clientName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      proRespondBy: (data['proRespondBy'] as Timestamp?)?.toDate(),
      clientRespondBy: (data['clientRespondBy'] as Timestamp?)?.toDate(),
      status: QuoteStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => QuoteStatus.Pending,
      ),
    );
  }

  Future<void> _updateQuoteStatus(String id, QuoteStatus status) async {
    await _firestore.collection(_quotesCollection).doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addToHistory(id, 'Statut changé', 'Nouveau statut: ${status.name}');
  }

  Future<void> _addToHistory(String quoteId, String action, String details) async {
    await _firestore
        .collection(_quotesCollection)
        .doc(quoteId)
        .collection('history')
        .add({
      'action': action,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': AuthService.instance.currentUser?.uid,
    });
  }

  Future<void> _sendNotification(String quoteId, String recipient, String message) async {
    // TODO: Intégrer avec NotificationService
    print('Notification $recipient pour $quoteId: $message');
  }
}