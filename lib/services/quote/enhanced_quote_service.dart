// lib/services/quote/enhanced_quote_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore_helper.dart'; // ✅ AJOUTÉ
import '../../core/database_manager.dart'; // ✅ AJOUTÉ pour détecter le mode
import '../../models/quote_request.dart';
import '../auth/secure_auth_service.dart'; // ✅ MIGRÉ

/// Service de devis complet unifié (Production + Démo)
/// En mode démo : simule les devis avec workflow complet et données factices
/// En mode production : utilise Firestore réel avec toutes les fonctionnalités
class EnhancedQuoteService {
  static EnhancedQuoteService? _instance;
  static EnhancedQuoteService get instance => _instance ??= EnhancedQuoteService._();
  EnhancedQuoteService._();

  final FirebaseFirestore _firestore = FirestoreHelper.instance; // ✅ CHANGÉ
  static const String _quotesCollection = 'quotes';
  static const String _templatesCollection = 'quote_templates';

  // ✅ DONNÉES MOCK POUR LES DÉMOS
  final List<QuoteRequest> _mockQuotes = [];
  final List<Map<String, dynamic>> _mockTemplates = [];
  final Map<String, List<Map<String, dynamic>>> _mockQuoteHistory = {};
  final Map<String, List<Map<String, dynamic>>> _mockDocuments = {};

  /// ✅ MÉTHODE PRINCIPALE - Détection automatique du mode
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  /// ✅ RÉCUPÉRER DEVIS PRO (mode auto)
  @override
  Future<List<QuoteRequest>> fetchRequestsForPro() async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Récupération devis pro');
      return await _fetchRequestsForProMock();
    } else {
      print('🏭 Mode production - Récupération devis pro');
      return await _fetchRequestsForProFirebase();
    }
  }

  /// ✅ FIREBASE - Devis pro réels
  Future<List<QuoteRequest>> _fetchRequestsForProFirebase() async {
    try {
      final currentUser = SecureAuthService.instance.currentUser; // ✅ MIGRÉ
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final userId = currentUser['uid'] ?? currentUser['id'];
      final snapshot = await _firestore
          .collection(_quotesCollection)
          .where('tattooistId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => _enhancedQuoteFromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur récupération devis pro Firebase: $e');
    }
  }

  /// ✅ MOCK - Devis pro factices
  Future<List<QuoteRequest>> _fetchRequestsForProMock() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser == null) throw Exception('[DÉMO] Utilisateur non connecté');

    _initializeMockQuotes();

    final userId = currentUser['uid'] ?? currentUser['id'];
    final proQuotes = _mockQuotes
        .where((q) => q.tattooistId == userId)
        .toList();

    print('✅ Devis pro démo récupérés: ${proQuotes.length}');
    return proQuotes;
  }

  /// ✅ RÉCUPÉRER DEVIS CLIENT (mode auto)
  @override
  Future<List<QuoteRequest>> fetchRequestsForParticulier() async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Récupération devis client');
      return await _fetchRequestsForParticulierMock();
    } else {
      print('🏭 Mode production - Récupération devis client');
      return await _fetchRequestsForParticulierFirebase();
    }
  }

  /// ✅ FIREBASE - Devis client réels
  Future<List<QuoteRequest>> _fetchRequestsForParticulierFirebase() async {
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final userId = currentUser['uid'] ?? currentUser['id'];
      final snapshot = await _firestore
          .collection(_quotesCollection)
          .where('clientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => _enhancedQuoteFromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur récupération devis client Firebase: $e');
    }
  }

  /// ✅ MOCK - Devis client factices
  Future<List<QuoteRequest>> _fetchRequestsForParticulierMock() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser == null) throw Exception('[DÉMO] Utilisateur non connecté');

    _initializeMockQuotes();

    final userId = currentUser['uid'] ?? currentUser['id'];
    final clientQuotes = _mockQuotes
        .where((q) => q.clientId == userId)
        .toList();

    print('✅ Devis client démo récupérés: ${clientQuotes.length}');
    return clientQuotes;
  }

  /// ✅ INITIALISER DEVIS DÉMO
  void _initializeMockQuotes() {
    if (_mockQuotes.isNotEmpty) return;

    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser == null) return;

    final userId = currentUser['uid'] ?? currentUser['id'];
    final userRole = SecureAuthService.instance.currentUserRole?.name ?? 'client';

    // Générer 5-8 devis pour l'utilisateur
    final quoteCount = Random().nextInt(4) + 5;
    
    for (int i = 0; i < quoteCount; i++) {
      final status = [
        QuoteStatus.Pending,
        QuoteStatus.Quoted,
        QuoteStatus.Accepted,
        QuoteStatus.Refused,
        QuoteStatus.Expired
      ][Random().nextInt(5)];

      final isProQuote = userRole == 'tatoueur';
      final quoteId = 'demo_quote_${userId}_$i';

      _mockQuotes.add(QuoteRequest(
        id: quoteId,
        clientId: isProQuote ? 'demo_client_$i' : userId,
        clientName: isProQuote ? 'Client Démo ${i + 1}' : 'Vous',
        clientEmail: isProQuote ? 'client.demo$i@kipik-demo.com' : currentUser['email'] ?? 'user@kipik-demo.com',
        tattooistId: isProQuote ? userId : 'demo_tattooist_$i',
        tattooistName: isProQuote ? 'Vous' : 'Tatoueur Démo ${i + 1}',
        projectTitle: _generateProjectTitle(),
        style: ['Traditionnel', 'Réaliste', 'Minimaliste', 'Géométrique', 'Old School'][Random().nextInt(5)],
        location: ['Bras', 'Jambe', 'Dos', 'Poitrine', 'Épaule'][Random().nextInt(5)],
        description: _generateProjectDescription(),
        budget: (Random().nextDouble() * 800 + 100).roundToDouble(),
        totalPrice: status == QuoteStatus.Quoted || status == QuoteStatus.Accepted 
            ? (Random().nextDouble() * 700 + 150).roundToDouble() 
            : null,
        status: status,
        createdAt: DateTime.now().subtract(Duration(days: Random().nextInt(30))),
        proRespondBy: DateTime.now().add(Duration(days: Random().nextInt(7) + 1)),
        clientRespondBy: status == QuoteStatus.Quoted 
            ? DateTime.now().add(Duration(days: Random().nextInt(7) + 1))
            : null,
        sessions: status == QuoteStatus.Quoted || status == QuoteStatus.Accepted 
            ? _generateMockSessions()
            : [],
        paymentTerms: status == QuoteStatus.Quoted || status == QuoteStatus.Accepted 
            ? _generateMockPaymentTerms()
            : {},
        referenceImages: ['https://picsum.photos/seed/quote$i/400/300'],
        requiredDocuments: _generateMockDocuments(),
      ));

      // Initialiser l'historique pour ce devis
      _mockQuoteHistory[quoteId] = _generateMockHistory(quoteId, status);
    }

    print('🎭 ${_mockQuotes.length} devis démo initialisés');
  }

  /// ✅ GÉNÉRER TITRE PROJET ALÉATOIRE
  String _generateProjectTitle() {
    final subjects = ['Dragon', 'Rose', 'Loup', 'Mandala', 'Tribal', 'Phoenix', 'Ancre', 'Crâne'];
    final styles = ['japonais', 'minimaliste', 'réaliste', 'géométrique', 'old school', 'tribal'];
    final locations = ['bras', 'jambe', 'dos', 'épaule', 'poignet'];
    
    return '${subjects[Random().nextInt(subjects.length)]} ${styles[Random().nextInt(styles.length)]} - ${locations[Random().nextInt(locations.length)]}';
  }

  /// ✅ GÉNÉRER DESCRIPTION PROJET
  String _generateProjectDescription() {
    final descriptions = [
      '[DÉMO] Tatouage détaillé avec ombrages complexes et finitions précises. Le client souhaite un style réaliste avec une attention particulière aux détails.',
      '[DÉMO] Design minimaliste et épuré, traits fins et élégants. Parfait pour un premier tatouage ou un style discret.',
      '[DÉMO] Pièce artistique ambitieuse nécessitant plusieurs séances. Style traditionnel avec couleurs vives et contours marqués.',
      '[DÉMO] Motifs géométriques symétriques demandant une grande précision. Style moderne et graphique.',
      '[DÉMO] Tatouage personnalisé inspiré de références spécifiques. Adaptation créative selon les goûts du client.',
    ];
    
    return descriptions[Random().nextInt(descriptions.length)];
  }

  /// ✅ GÉNÉRER SÉANCES DÉMO
  List<Map<String, dynamic>> _generateMockSessions() {
    final sessionCount = Random().nextInt(3) + 1; // 1-3 séances
    final sessions = <Map<String, dynamic>>[];
    
    for (int i = 0; i < sessionCount; i++) {
      sessions.add({
        'sessionNumber': i + 1,
        'duration': (Random().nextDouble() * 4 + 1).roundToDouble(), // 1-5h
        'price': (Random().nextDouble() * 300 + 100).roundToDouble(),
        'description': 'Séance ${i + 1}: ${i == 0 ? 'Contours et bases' : i == sessionCount - 1 ? 'Finitions et détails' : 'Remplissage et ombrages'}',
        'estimatedDate': DateTime.now().add(Duration(days: (i + 1) * 14)), // Espacées de 2 semaines
      });
    }
    
    return sessions;
  }

  /// ✅ GÉNÉRER CONDITIONS PAIEMENT DÉMO
  Map<String, dynamic> _generateMockPaymentTerms() {
    return {
      'depositAmount': (Random().nextDouble() * 150 + 50).roundToDouble(),
      'depositPercentage': [20, 30, 40][Random().nextInt(3)],
      'paymentSchedule': ['per_session', 'end', 'split'][Random().nextInt(3)],
      'acceptedMethods': ['card', 'transfer'],
      'lateFees': 'Frais de retard: 20€/jour après 48h',
      'cancellationPolicy': '48h minimum pour annulation sans frais',
      'refundPolicy': 'Acompte non remboursable sauf cas de force majeure',
    };
  }

  /// ✅ GÉNÉRER DOCUMENTS DÉMO
  List<Map<String, dynamic>> _generateMockDocuments() {
    return [
      {
        'type': 'consent_form',
        'name': 'Fiche de décharge',
        'mandatory': true,
        'template': 'consent_template_v1',
        'needsSignature': true,
        'status': 'pending_signature',
      },
      {
        'type': 'care_instructions',
        'name': 'Fiche de soins',
        'mandatory': true,
        'template': 'care_template_v1',
        'needsSignature': false,
        'status': 'ready',
      },
      {
        'type': 'medical_history',
        'name': 'Questionnaire médical',
        'mandatory': true,
        'template': 'medical_template_v1',
        'needsSignature': false,
        'status': 'pending',
      },
    ];
  }

  /// ✅ GÉNÉRER HISTORIQUE DÉMO
  List<Map<String, dynamic>> _generateMockHistory(String quoteId, QuoteStatus status) {
    final history = <Map<String, dynamic>>[
      {
        'action': 'Devis créé',
        'details': '[DÉMO] Demande de devis initiale',
        'timestamp': DateTime.now().subtract(Duration(days: Random().nextInt(15) + 1)),
        'userId': 'demo_user',
      },
    ];

    if (status.index >= QuoteStatus.Quoted.index) {
      history.add({
        'action': 'Devis envoyé',
        'details': '[DÉMO] Devis détaillé avec ${Random().nextInt(3) + 1} séances',
        'timestamp': DateTime.now().subtract(Duration(days: Random().nextInt(7))),
        'userId': 'demo_tattooist',
      });
    }

    if (status == QuoteStatus.Accepted) {
      history.add({
        'action': 'Devis accepté',
        'details': '[DÉMO] Client a validé le devis et signé les documents',
        'timestamp': DateTime.now().subtract(Duration(days: Random().nextInt(3))),
        'userId': 'demo_client',
      });
    } else if (status == QuoteStatus.Refused) {
      history.add({
        'action': 'Devis refusé',
        'details': '[DÉMO] Client a décliné le devis',
        'timestamp': DateTime.now().subtract(Duration(days: Random().nextInt(3))),
        'userId': 'demo_client',
      });
    }

    return history;
  }

  /// ✅ RÉCUPÉRER DÉTAIL DEVIS (mode auto)
  @override
  Future<QuoteRequest> fetchRequestDetail(String id) async {
    if (_isDemoMode) {
      return await _fetchRequestDetailMock(id);
    } else {
      return await _fetchRequestDetailFirebase(id);
    }
  }

  /// ✅ FIREBASE - Détail devis réel
  Future<QuoteRequest> _fetchRequestDetailFirebase(String id) async {
    try {
      final doc = await _firestore.collection(_quotesCollection).doc(id).get();
      if (!doc.exists) throw Exception('Devis introuvable');
      return _enhancedQuoteFromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur récupération détail devis Firebase: $e');
    }
  }

  /// ✅ MOCK - Détail devis factice
  Future<QuoteRequest> _fetchRequestDetailMock(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _initializeMockQuotes();
    
    try {
      final quote = _mockQuotes.firstWhere((q) => q.id == id);
      print('✅ Détail devis démo: ${quote.projectTitle}');
      return quote;
    } catch (e) {
      throw Exception('[DÉMO] Devis introuvable: $id');
    }
  }

  /// ✅ ACCEPTER DEMANDE (mode auto)
  @override
  Future<void> acceptRequest(String id) async {
    if (_isDemoMode) {
      await _acceptRequestMock(id);
    } else {
      await _acceptRequestFirebase(id);
    }
  }

  /// ✅ FIREBASE - Accepter demande réelle
  Future<void> _acceptRequestFirebase(String id) async {
    try {
      await _updateQuoteStatus(id, QuoteStatus.Quoted);
      await _sendNotification(id, 'client', 'Votre demande a été acceptée');
    } catch (e) {
      throw Exception('Erreur acceptation devis Firebase: $e');
    }
  }

  /// ✅ MOCK - Accepter demande factice
  Future<void> _acceptRequestMock(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    await _updateQuoteStatusMock(id, QuoteStatus.Quoted);
    await _sendNotificationMock(id, 'client', '[DÉMO] Votre demande a été acceptée');
    
    print('✅ Demande démo acceptée: $id');
  }

  /// ✅ REFUSER DEMANDE (mode auto)
  @override
  Future<void> refuseRequest(String id) async {
    if (_isDemoMode) {
      await _refuseRequestMock(id);
    } else {
      await _refuseRequestFirebase(id);
    }
  }

  /// ✅ FIREBASE - Refuser demande réelle
  Future<void> _refuseRequestFirebase(String id) async {
    try {
      await _updateQuoteStatus(id, QuoteStatus.Refused);
      await _sendNotification(id, 'client', 'Votre demande a été refusée');
    } catch (e) {
      throw Exception('Erreur refus devis Firebase: $e');
    }
  }

  /// ✅ MOCK - Refuser demande factice
  Future<void> _refuseRequestMock(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    await _updateQuoteStatusMock(id, QuoteStatus.Refused);
    await _sendNotificationMock(id, 'client', '[DÉMO] Votre demande a été refusée');
    
    print('✅ Demande démo refusée: $id');
  }

  /// ✅ ENVOYER DEVIS SIMPLE (mode auto)
  @override
  Future<void> sendQuote(String id, double price, String details) async {
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

  /// ✅ ENVOYER DEVIS DÉTAILLÉ (mode auto)
  Future<void> sendDetailedQuote(String quoteId, Map<String, dynamic> quoteData) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Envoi devis détaillé');
      await _sendDetailedQuoteMock(quoteId, quoteData);
    } else {
      print('🏭 Mode production - Envoi devis détaillé');
      await _sendDetailedQuoteFirebase(quoteId, quoteData);
    }
  }

  /// ✅ FIREBASE - Envoyer devis détaillé réel
  Future<void> _sendDetailedQuoteFirebase(String quoteId, Map<String, dynamic> quoteData) async {
    try {
      final updates = {
        'status': QuoteStatus.Quoted.name,
        'totalPrice': quoteData['totalPrice'],
        'description': quoteData['description'],
        'sessions': quoteData['sessions'],
        'totalHours': quoteData['totalHours'],
        'totalSessions': quoteData['totalSessions'],
        'estimatedDuration': quoteData['estimatedDuration'],
        'proposedDates': quoteData['proposedDates'],
        'flexibility': quoteData['flexibility'],
        'paymentTerms': {
          'depositAmount': quoteData['depositAmount'],
          'depositPercentage': quoteData['depositPercentage'],
          'paymentSchedule': quoteData['paymentSchedule'],
          'acceptedMethods': quoteData['acceptedMethods'],
          'lateFees': quoteData['lateFees'],
        },
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
        'terms': {
          'cancellationPolicy': quoteData['cancellationPolicy'],
          'reschedulePolicy': quoteData['reschedulePolicy'],
          'refundPolicy': quoteData['refundPolicy'],
          'hygieneRequirements': quoteData['hygieneRequirements'],
        },
        'quotedAt': FieldValue.serverTimestamp(),
        'clientRespondBy': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'validUntil': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'updatedAt': FieldValue.serverTimestamp(),
        'version': 1,
        'currency': 'EUR',
        'taxRate': 0.20,
        'includesTax': true,
      };

      await _firestore.collection(_quotesCollection).doc(quoteId).update(updates);
      
      await _generateQuotePDF(quoteId);
      await _prepareDocuments(quoteId);
      await _sendNotification(quoteId, 'client', 'Votre devis détaillé est prêt !');
      await _addToHistory(quoteId, 'Devis envoyé', 'Devis complet avec ${quoteData['totalSessions']} séances');
      
    } catch (e) {
      throw Exception('Erreur envoi devis détaillé Firebase: $e');
    }
  }

  /// ✅ MOCK - Envoyer devis détaillé factice
  Future<void> _sendDetailedQuoteMock(String quoteId, Map<String, dynamic> quoteData) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Mettre à jour le devis mock
    final quoteIndex = _mockQuotes.indexWhere((q) => q.id == quoteId);
    if (quoteIndex != -1) {
      final updatedQuote = _mockQuotes[quoteIndex].copyWith(
        status: QuoteStatus.Quoted,
        totalPrice: quoteData['totalPrice'],
        description: quoteData['description'],
        sessions: List<Map<String, dynamic>>.from(quoteData['sessions'] ?? []),
        paymentTerms: Map<String, dynamic>.from(quoteData['paymentTerms'] ?? {}),
        clientRespondBy: DateTime.now().add(const Duration(days: 7)),
      );
      
      _mockQuotes[quoteIndex] = updatedQuote;
    }

    // Simuler génération PDF
    await _generateQuotePDFMock(quoteId);
    
    // Simuler préparation documents
    await _prepareDocumentsMock(quoteId);
    
    // Notifications
    await _sendNotificationMock(quoteId, 'client', '[DÉMO] Votre devis détaillé est prêt !');
    
    // Historique
    await _addToHistoryMock(quoteId, 'Devis envoyé', '[DÉMO] Devis complet avec ${quoteData['sessions']?.length ?? 1} séances');
    
    print('✅ Devis détaillé démo envoyé: $quoteId (${quoteData['totalPrice']}€)');
  }

  /// ✅ CLIENT ACCEPTE DEVIS (mode auto)
  @override
  Future<void> clientAccept(String id) async {
    if (_isDemoMode) {
      await _clientAcceptMock(id);
    } else {
      await _clientAcceptFirebase(id);
    }
  }

  /// ✅ FIREBASE - Client accepte réel
  Future<void> _clientAcceptFirebase(String id) async {
    try {
      final documentsComplete = await _areAllDocumentsSigned(id);
      if (!documentsComplete) {
        throw Exception('Tous les documents obligatoires doivent être signés avant validation');
      }

      await _updateQuoteStatus(id, QuoteStatus.Accepted);
      
      final projectId = await _createProjectFromQuote(id);
      await _scheduleSessionsFromQuote(id, projectId);
      await _createPaymentSchedule(id, projectId);
      
      await _sendNotification(id, 'tattooist', 'Devis accepté ! Projet créé automatiquement.');
      
    } catch (e) {
      throw Exception('Erreur acceptation client Firebase: $e');
    }
  }

  /// ✅ MOCK - Client accepte factice
  Future<void> _clientAcceptMock(String id) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Simuler vérification documents (toujours OK en démo)
    const documentsComplete = true;
    if (!documentsComplete) {
      throw Exception('[DÉMO] Tous les documents obligatoires doivent être signés avant validation');
    }

    await _updateQuoteStatusMock(id, QuoteStatus.Accepted);
    
    final projectId = await _createProjectFromQuoteMock(id);
    await _scheduleSessionsFromQuoteMock(id, projectId);
    await _createPaymentScheduleMock(id, projectId);
    
    await _sendNotificationMock(id, 'tattooist', '[DÉMO] Devis accepté ! Projet créé automatiquement.');
    
    print('✅ Devis démo accepté par le client: $id → Projet: $projectId');
  }

  /// ✅ CLIENT REFUSE DEVIS (mode auto)
  @override
  Future<void> clientRefuse(String id) async {
    if (_isDemoMode) {
      await _clientRefuseMock(id);
    } else {
      await _clientRefuseFirebase(id);
    }
  }

  /// ✅ FIREBASE - Client refuse réel
  Future<void> _clientRefuseFirebase(String id) async {
    try {
      await _updateQuoteStatus(id, QuoteStatus.Refused);
      await _sendNotification(id, 'tattooist', 'Devis refusé par le client');
    } catch (e) {
      throw Exception('Erreur refus client Firebase: $e');
    }
  }

  /// ✅ MOCK - Client refuse factice
  Future<void> _clientRefuseMock(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    await _updateQuoteStatusMock(id, QuoteStatus.Refused);
    await _sendNotificationMock(id, 'tattooist', '[DÉMO] Devis refusé par le client');
    
    print('✅ Devis démo refusé par le client: $id');
  }

  /// ✅ SAUVEGARDER TEMPLATE (mode auto)
  Future<String> saveQuoteTemplate({
    required String name,
    required Map<String, dynamic> templateData,
  }) async {
    if (_isDemoMode) {
      return await _saveQuoteTemplateMock(name: name, templateData: templateData);
    } else {
      return await _saveQuoteTemplateFirebase(name: name, templateData: templateData);
    }
  }

  /// ✅ FIREBASE - Sauvegarder template réel
  Future<String> _saveQuoteTemplateFirebase({
    required String name,
    required Map<String, dynamic> templateData,
  }) async {
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final userId = currentUser['uid'] ?? currentUser['id'];
      final docRef = await _firestore.collection(_templatesCollection).add({
        'tattooistId': userId,
        'name': name,
        'templateData': templateData,
        'createdAt': FieldValue.serverTimestamp(),
        'usageCount': 0,
        'isActive': true,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur sauvegarde template Firebase: $e');
    }
  }

  /// ✅ MOCK - Sauvegarder template factice
  Future<String> _saveQuoteTemplateMock({
    required String name,
    required Map<String, dynamic> templateData,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser == null) throw Exception('[DÉMO] Utilisateur non connecté');

    final userId = currentUser['uid'] ?? currentUser['id'];
    final templateId = 'demo_template_${DateTime.now().millisecondsSinceEpoch}';
    
    final template = {
      'id': templateId,
      'tattooistId': userId,
      'name': name,
      'templateData': templateData,
      'createdAt': DateTime.now(),
      'usageCount': 0,
      'isActive': true,
      '_source': 'mock',
      '_demoData': true,
    };

    _mockTemplates.add(template);
    
    print('✅ Template démo sauvegardé: $name (ID: $templateId)');
    return templateId;
  }

  /// ✅ RÉCUPÉRER TEMPLATES (mode auto)
  Future<List<Map<String, dynamic>>> getQuoteTemplates() async {
    if (_isDemoMode) {
      return await _getQuoteTemplatesMock();
    } else {
      return await _getQuoteTemplatesFirebase();
    }
  }

  /// ✅ FIREBASE - Templates réels
  Future<List<Map<String, dynamic>>> _getQuoteTemplatesFirebase() async {
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) return [];

      final userId = currentUser['uid'] ?? currentUser['id'];
      final snapshot = await _firestore
          .collection(_templatesCollection)
          .where('tattooistId', isEqualTo: userId)
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

  /// ✅ MOCK - Templates factices
  Future<List<Map<String, dynamic>>> _getQuoteTemplatesMock() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser == null) return [];

    final userId = currentUser['uid'] ?? currentUser['id'];
    
    // Initialiser quelques templates de démo si vide
    if (_mockTemplates.isEmpty) {
      _initializeMockTemplates(userId);
    }

    final userTemplates = _mockTemplates
        .where((t) => t['tattooistId'] == userId)
        .toList();

    print('✅ Templates démo récupérés: ${userTemplates.length}');
    return userTemplates;
  }

  /// ✅ INITIALISER TEMPLATES DÉMO
  void _initializeMockTemplates(String userId) {
    _mockTemplates.addAll([
      {
        'id': 'demo_template_1',
        'tattooistId': userId,
        'name': 'Template Standard',
        'templateData': {
          'sessions': 2,
          'depositPercentage': 30,
          'paymentSchedule': 'per_session',
          'cancellationPolicy': '48h minimum pour annulation',
        },
        'createdAt': DateTime.now().subtract(const Duration(days: 15)),
        'usageCount': Random().nextInt(10) + 5,
        'isActive': true,
        '_source': 'mock',
        '_demoData': true,
      },
      {
        'id': 'demo_template_2',
        'tattooistId': userId,
        'name': 'Template Premium',
        'templateData': {
          'sessions': 3,
          'depositPercentage': 40,
          'paymentSchedule': 'split',
          'cancellationPolicy': '72h minimum pour annulation',
        },
        'createdAt': DateTime.now().subtract(const Duration(days: 30)),
        'usageCount': Random().nextInt(8) + 2,
        'isActive': true,
        '_source': 'mock',
        '_demoData': true,
      },
    ]);
  }

  /// ✅ MÉTHODE DE DIAGNOSTIC
  Future<void> debugQuoteService() async {
    print('🔍 Debug EnhancedQuoteService:');
    print('  - Mode démo: $_isDemoMode');
    print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');
    
    final currentUser = SecureAuthService.instance.currentUser;
    final userId = currentUser?['uid'] ?? currentUser?['id'];
    
    print('  - User ID: ${userId ?? 'Non connecté'}');
    
    if (userId != null) {
      try {
        final proQuotes = await fetchRequestsForPro();
        print('  - Devis pro: ${proQuotes.length}');
        
        final clientQuotes = await fetchRequestsForParticulier();
        print('  - Devis client: ${clientQuotes.length}');
        
        final templates = await getQuoteTemplates();
        print('  - Templates: ${templates.length}');
        
        if (_isDemoMode) {
          print('  - Devis mock: ${_mockQuotes.length}');
          print('  - Templates mock: ${_mockTemplates.length}');
          print('  - Historiques mock: ${_mockQuoteHistory.length}');
        }
      } catch (e) {
        print('  - Erreur: $e');
      }
    }
  }

  // ✅ MÉTHODES UTILITAIRES (adaptées pour le mode auto)

  /// Mettre à jour statut devis
  Future<void> _updateQuoteStatus(String id, QuoteStatus status) async {
    if (_isDemoMode) {
      await _updateQuoteStatusMock(id, status);
    } else {
      await _updateQuoteStatusFirebase(id, status);
    }
  }

  /// FIREBASE - Mise à jour statut réelle
  Future<void> _updateQuoteStatusFirebase(String id, QuoteStatus status) async {
    await _firestore.collection(_quotesCollection).doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addToHistory(id, 'Statut changé', 'Nouveau statut: ${status.name}');
  }

  /// MOCK - Mise à jour statut factice
  Future<void> _updateQuoteStatusMock(String id, QuoteStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final quoteIndex = _mockQuotes.indexWhere((q) => q.id == id);
    if (quoteIndex != -1) {
      _mockQuotes[quoteIndex] = _mockQuotes[quoteIndex].copyWith(status: status);
    }
    
    await _addToHistoryMock(id, 'Statut changé', '[DÉMO] Nouveau statut: ${status.name}');
  }

  /// Ajouter à l'historique
  Future<void> _addToHistory(String quoteId, String action, String details) async {
    if (_isDemoMode) {
      await _addToHistoryMock(quoteId, action, details);
    } else {
      await _addToHistoryFirebase(quoteId, action, details);
    }
  }

  /// FIREBASE - Historique réel
  Future<void> _addToHistoryFirebase(String quoteId, String action, String details) async {
    await _firestore
        .collection(_quotesCollection)
        .doc(quoteId)
        .collection('history')
        .add({
      'action': action,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': SecureAuthService.instance.currentUser?['uid'] ?? SecureAuthService.instance.currentUser?['id'],
    });
  }

  /// MOCK - Historique factice
  Future<void> _addToHistoryMock(String quoteId, String action, String details) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!_mockQuoteHistory.containsKey(quoteId)) {
      _mockQuoteHistory[quoteId] = [];
    }
    
    _mockQuoteHistory[quoteId]!.add({
      'action': action,
      'details': details,
      'timestamp': DateTime.now(),
      'userId': SecureAuthService.instance.currentUser?['uid'] ?? SecureAuthService.instance.currentUser?['id'],
      '_source': 'mock',
    });
  }

  /// Envoyer notification
  Future<void> _sendNotification(String quoteId, String recipient, String message) async {
    if (_isDemoMode) {
      await _sendNotificationMock(quoteId, recipient, message);
    } else {
      await _sendNotificationFirebase(quoteId, recipient, message);
    }
  }

  /// FIREBASE - Notification réelle
  Future<void> _sendNotificationFirebase(String quoteId, String recipient, String message) async {
    // TODO: Intégrer avec NotificationService
    print('Notification Firebase $recipient pour $quoteId: $message');
  }

  /// MOCK - Notification factice
  Future<void> _sendNotificationMock(String quoteId, String recipient, String message) async {
    await Future.delayed(const Duration(milliseconds: 100));
    print('🎭 Notification démo $recipient pour $quoteId: $message');
  }

  // ✅ MÉTHODES SPÉCIALISÉES (simplifiées pour la démo)

  /// Génération PDF du devis
  Future<String> _generateQuotePDF(String quoteId) async {
    if (_isDemoMode) {
      return await _generateQuotePDFMock(quoteId);
    } else {
      return await _generateQuotePDFFirebase(quoteId);
    }
  }

  /// FIREBASE - PDF réel
  Future<String> _generateQuotePDFFirebase(String quoteId) async {
    try {
      // TODO: Intégrer avec un service de génération PDF
      final pdfUrl = 'https://storage.googleapis.com/quotes/$quoteId.pdf';
      
      await _firestore.collection(_quotesCollection).doc(quoteId).update({
        'pdfUrl': pdfUrl,
        'pdfGeneratedAt': FieldValue.serverTimestamp(),
      });
      
      return pdfUrl;
    } catch (e) {
      throw Exception('Erreur génération PDF Firebase: $e');
    }
  }

  /// MOCK - PDF factice
  Future<String> _generateQuotePDFMock(String quoteId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final pdfUrl = 'https://demo.kipik.com/quotes/$quoteId.pdf';
    print('✅ PDF démo généré: $pdfUrl');
    
    return pdfUrl;
  }

  /// Préparer les documents pour signature
  Future<void> _prepareDocuments(String quoteId) async {
    if (_isDemoMode) {
      await _prepareDocumentsMock(quoteId);
    } else {
      await _prepareDocumentsFirebase(quoteId);
    }
  }

  /// FIREBASE - Documents réels
  Future<void> _prepareDocumentsFirebase(String quoteId) async {
    try {
      final quoteDoc = await _firestore.collection(_quotesCollection).doc(quoteId).get();
      final quoteData = quoteDoc.data()!;
      
      final requiredDocs = quoteData['requiredDocuments'] as List<dynamic>;
      
      for (final doc in requiredDocs) {
        if (doc['needsSignature'] == true) {
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
            'signingUrl': 'https://sign.kipik.com/$quoteId/${doc['type']}',
          });
        }
      }
    } catch (e) {
      print('Erreur préparation documents Firebase: $e');
    }
  }

  /// MOCK - Documents factices
  Future<void> _prepareDocumentsMock(String quoteId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!_mockDocuments.containsKey(quoteId)) {
      _mockDocuments[quoteId] = [];
    }
    
    final mockDocs = [
      {
        'type': 'consent_form',
        'name': 'Fiche de décharge',
        'template': 'consent_template_v1',
        'status': 'pending_signature',
        'createdAt': DateTime.now(),
        'signingUrl': 'https://demo.sign.kipik.com/$quoteId/consent_form',
        '_source': 'mock',
      },
      {
        'type': 'care_instructions',
        'name': 'Fiche de soins',
        'template': 'care_template_v1',
        'status': 'ready',
        'createdAt': DateTime.now(),
        '_source': 'mock',
      },
    ];
    
    _mockDocuments[quoteId]!.addAll(mockDocs);
    print('✅ Documents démo préparés: ${mockDocs.length} documents');
  }

  /// Vérifier que tous les documents sont signés
  Future<bool> _areAllDocumentsSigned(String quoteId) async {
    if (_isDemoMode) {
      // En mode démo, toujours retourner true pour fluidifier la demo
      return true;
    } else {
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
  }

  /// Créer un projet à partir du devis accepté
  Future<String> _createProjectFromQuote(String quoteId) async {
    if (_isDemoMode) {
      return await _createProjectFromQuoteMock(quoteId);
    } else {
      return await _createProjectFromQuoteFirebase(quoteId);
    }
  }

  /// FIREBASE - Créer projet réel
  Future<String> _createProjectFromQuoteFirebase(String quoteId) async {
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
      
      await _firestore.collection(_quotesCollection).doc(quoteId).update({
        'projectId': docRef.id,
        'projectCreatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur création projet Firebase: $e');
    }
  }

  /// MOCK - Créer projet factice
  Future<String> _createProjectFromQuoteMock(String quoteId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final projectId = 'demo_project_${DateTime.now().millisecondsSinceEpoch}';
    
    // Simuler création projet
    print('✅ Projet démo créé: $projectId (depuis devis: $quoteId)');
    
    return projectId;
  }

  /// Programmer les séances du projet
  Future<void> _scheduleSessionsFromQuote(String quoteId, String projectId) async {
    if (_isDemoMode) {
      await _scheduleSessionsFromQuoteMock(quoteId, projectId);
    } else {
      await _scheduleSessionsFromQuoteFirebase(quoteId, projectId);
    }
  }

  /// FIREBASE - Programmer séances réelles
  Future<void> _scheduleSessionsFromQuoteFirebase(String quoteId, String projectId) async {
    // TODO: Intégrer avec un système de calendrier/planning
    print('Programmation des séances Firebase pour le projet $projectId');
  }

  /// MOCK - Programmer séances factices
  Future<void> _scheduleSessionsFromQuoteMock(String quoteId, String projectId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('✅ Séances démo programmées pour le projet $projectId');
  }

  /// Créer l'échéancier de paiement
  Future<void> _createPaymentSchedule(String quoteId, String projectId) async {
    if (_isDemoMode) {
      await _createPaymentScheduleMock(quoteId, projectId);
    } else {
      await _createPaymentScheduleFirebase(quoteId, projectId);
    }
  }

  /// FIREBASE - Échéancier réel
  Future<void> _createPaymentScheduleFirebase(String quoteId, String projectId) async {
    // TODO: Intégrer avec Stripe pour créer les paiements programmés
    print('Création échéancier paiement Firebase pour le projet $projectId');
  }

  /// MOCK - Échéancier factice
  Future<void> _createPaymentScheduleMock(String quoteId, String projectId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('✅ Échéancier paiement démo créé pour le projet $projectId');
  }

  /// Convertir document Firestore en QuoteRequest
  QuoteRequest _enhancedQuoteFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return QuoteRequest(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      tattooistId: data['tattooistId'] ?? '',
      tattooistName: data['tattooistName'] ?? '',
      projectTitle: data['projectTitle'] ?? '',
      style: data['style'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      budget: (data['budget'] as num?)?.toDouble(),
      totalPrice: (data['totalPrice'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      proRespondBy: (data['proRespondBy'] as Timestamp?)?.toDate(),
      clientRespondBy: (data['clientRespondBy'] as Timestamp?)?.toDate(),
      status: QuoteStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => QuoteStatus.Pending,
      ),
      sessions: List<Map<String, dynamic>>.from(data['sessions'] ?? []),
      paymentTerms: Map<String, dynamic>.from(data['paymentTerms'] ?? {}),
      referenceImages: List<String>.from(data['referenceImages'] ?? []),
      requiredDocuments: List<Map<String, dynamic>>.from(data['requiredDocuments'] ?? []),
    );
  }
}