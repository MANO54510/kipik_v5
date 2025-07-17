// lib/services/organisateur/firebase_organisateur_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../payment/firebase_payment_service.dart'; // ✅ Votre service existant

class FirebaseOrganisateurService {
  static final FirebaseOrganisateurService _instance = FirebaseOrganisateurService._internal();
  factory FirebaseOrganisateurService() => _instance;
  static FirebaseOrganisateurService get instance => _instance;
  FirebaseOrganisateurService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ✅ Utilise votre service de paiement existant
  final FirebasePaymentService _paymentService = FirebasePaymentService.instance;

  // Collection references
  CollectionReference get _organizersCollection => _firestore.collection('organizers');
  CollectionReference get _conventionsCollection => _firestore.collection('conventions');
  CollectionReference get _standRequestsCollection => _firestore.collection('standRequests');
  CollectionReference get _ticketsCollection => _firestore.collection('tickets');
  CollectionReference get _campaignsCollection => _firestore.collection('campaigns');

  /// ===== MÉTHODES DE BASE (votre code existant) =====

  /// Obtient l'ID de l'organisateur connecté
  String? getCurrentOrganizerId() {
    return _auth.currentUser?.uid;
  }

  /// Vérifie si l'utilisateur connecté est un organisateur
  Future<bool> isCurrentUserOrganizer() async {
    try {
      final userId = getCurrentOrganizerId();
      if (userId == null) return false;

      final doc = await _organizersCollection.doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      return data['isVerified'] == true && data['status'] != 'suspended';
    } catch (e) {
      return false;
    }
  }

  /// Stream du profil organisateur
  Stream<DocumentSnapshot> getOrganizerProfileStream(String organizerId) {
    return _organizersCollection.doc(organizerId).snapshots();
  }

  /// Récupère le profil organisateur
  Future<DocumentSnapshot> getOrganizerProfile(String organizerId) {
    return _organizersCollection.doc(organizerId).get();
  }

  /// Met à jour le profil organisateur
  Future<void> updateProfile(String organizerId, Map<String, dynamic> data) async {
    await _organizersCollection.doc(organizerId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Crée le profil organisateur
  Future<void> createOrganizerProfile(String organizerId, Map<String, dynamic> profileData) async {
    await _organizersCollection.doc(organizerId).set({
      ...profileData,
      'isVerified': false,
      'status': 'pending',
      'stats': {
        'totalConventions': 0,
        'totalTattooers': 0,
        'totalVisitors': 0,
        'totalRevenue': 0,
        'avgRating': 0.0,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Incrémente une statistique
  Future<void> incrementStat(String organizerId, String statName, int value) async {
    await _organizersCollection.doc(organizerId).update({
      'stats.$statName': FieldValue.increment(value),
    });
  }

  /// Met à jour les statistiques
  Future<void> updateStats(String organizerId, Map<String, dynamic> stats) async {
    final updates = <String, dynamic>{};
    for (final entry in stats.entries) {
      updates['stats.${entry.key}'] = entry.value;
    }
    await _organizersCollection.doc(organizerId).update(updates);
  }

  /// ===== MÉTHODES ÉTENDUES POUR LES PAGES ORGANISATEUR =====

  /// Stream des conventions d'un organisateur
  Stream<QuerySnapshot> getConventionsStream(String organizerId) {
    return _conventionsCollection
        .where('basic.organizerId', isEqualTo: organizerId)
        .orderBy('dates.start', descending: false)
        .snapshots();
  }

  /// Crée une nouvelle convention
  Future<String> createConvention(Map<String, dynamic> conventionData) async {
    try {
      final organizerId = getCurrentOrganizerId();
      if (organizerId == null) throw Exception('Organisateur non connecté');

      final docRef = await _conventionsCollection.add({
        ...conventionData,
        'basic': {
          ...conventionData['basic'] ?? {},
          'organizerId': organizerId,
          'createdAt': FieldValue.serverTimestamp(),
        },
        'metrics': {
          'stands_reserved': 0,
          'tickets_sold': 0,
          'total_revenue': 0.0,
          'visitors_expected': conventionData['capacity']?['expected_visitors'] ?? 0,
        },
        'status': 'draft',
      });

      // Met à jour les stats
      await incrementStat(organizerId, 'totalConventions', 1);

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur création convention: $e');
    }
  }

  /// Met à jour une convention
  Future<void> updateConvention(String conventionId, Map<String, dynamic> updates) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur mise à jour convention: $e');
    }
  }

  /// Récupère une convention par son ID
  Future<DocumentSnapshot> getConvention(String conventionId) async {
    try {
      return await _conventionsCollection.doc(conventionId).get();
    } catch (e) {
      throw Exception('Erreur récupération convention: $e');
    }
  }

  /// Publie une convention (change le statut vers 'published')
  Future<void> publishConvention(String conventionId) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'basic.status': 'published',
        'publishedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur publication convention: $e');
    }
  }

  /// Dépublie une convention (change le statut vers 'draft')
  Future<void> unpublishConvention(String conventionId) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'basic.status': 'draft',
        'unpublishedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur dépublication convention: $e');
    }
  }

  /// Vérifie si une convention peut être modifiée
  Future<bool> canEditConvention(String conventionId) async {
    try {
      final doc = await getConvention(conventionId);
      
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>;
      final status = data['basic']?['status'] as String?;
      
      // Seules les conventions en draft ou published peuvent être modifiées
      return status == 'draft' || status == 'published';
      
    } catch (e) {
      return false;
    }
  }

  /// Duplique une convention existante
  Future<String> duplicateConvention(String conventionId) async {
    try {
      final originalDoc = await getConvention(conventionId);
      
      if (!originalDoc.exists) {
        throw Exception('Convention non trouvée');
      }
      
      final originalData = originalDoc.data() as Map<String, dynamic>;
      
      // Modifier les données pour la duplication
      final duplicatedData = Map<String, dynamic>.from(originalData);
      
      // Mettre à jour les infos de base
      if (duplicatedData['basic'] != null) {
        duplicatedData['basic']['name'] = '${duplicatedData['basic']['name']} (Copie)';
        duplicatedData['basic']['status'] = 'draft';
        duplicatedData['basic']['createdAt'] = FieldValue.serverTimestamp();
        duplicatedData['basic']['updatedAt'] = FieldValue.serverTimestamp();
      }
      
      // Réinitialiser les stats
      duplicatedData['stats'] = {
        'tattooersCount': 0,
        'maxTattooers': duplicatedData['location']?['capacity'] ?? 50,
        'ticketsSold': 0,
        'expectedVisitors': duplicatedData['dates']?['expectedVisitors'] ?? 500,
        'revenue': {
          'total': 0.0,
          'stands': 0.0,
          'tickets': 0.0,
          'kipikCommission': 0.0,
        },
      };
      
      // Créer la nouvelle convention
      final newDocRef = await createConvention(duplicatedData);
      
      return newDocRef;
      
    } catch (e) {
      throw Exception('Erreur duplication convention: $e');
    }
  }

  /// Obtient les conventions de l'organisateur avec filtres
  Future<List<DocumentSnapshot>> getConventionsByStatus(String status) async {
    try {
      final organizerId = getCurrentOrganizerId();
      if (organizerId == null) {
        throw Exception('Organisateur non connecté');
      }
      
      final snapshot = await _conventionsCollection
          .where('basic.organizerId', isEqualTo: organizerId)
          .where('basic.status', isEqualTo: status)
          .orderBy('basic.createdAt', descending: true)
          .get();
      
      return snapshot.docs;
      
    } catch (e) {
      throw Exception('Erreur récupération conventions: $e');
    }
  }

  /// Recherche dans les conventions de l'organisateur
  Future<List<DocumentSnapshot>> searchConventions(String query) async {
    try {
      final organizerId = getCurrentOrganizerId();
      if (organizerId == null) {
        throw Exception('Organisateur non connecté');
      }
      
      // Recherche simple par nom (Firebase ne supporte pas la recherche full-text native)
      final snapshot = await _conventionsCollection
          .where('basic.organizerId', isEqualTo: organizerId)
          .where('basic.name', isGreaterThanOrEqualTo: query)
          .where('basic.name', isLessThan: query + '\uf8ff')
          .orderBy('basic.name')
          .limit(20)
          .get();
      
      return snapshot.docs;
      
    } catch (e) {
      throw Exception('Erreur recherche conventions: $e');
    }
  }

  /// Archive une convention
  Future<void> archiveConvention(String conventionId) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'basic.status': 'archived',
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur archivage convention: $e');
    }
  }

  /// Supprime définitivement une convention (avec confirmation)
  Future<void> deleteConvention(String conventionId) async {
    try {
      // Vérifier que la convention appartient à l'organisateur connecté
      final canManage = await canManageConvention(conventionId);
      if (!canManage) {
        throw Exception('Vous n\'avez pas les droits pour supprimer cette convention');
      }
      
      // Supprimer les données liées
      await _deleteConventionRelatedData(conventionId);
      
      // Supprimer la convention
      await _conventionsCollection.doc(conventionId).delete();
      
    } catch (e) {
      throw Exception('Erreur suppression convention: $e');
    }
  }

  /// Supprime les données liées à une convention
  Future<void> _deleteConventionRelatedData(String conventionId) async {
    try {
      // Supprimer les demandes de stands
      final standRequests = await _standRequestsCollection
          .where('convention.id', isEqualTo: conventionId)
          .get();
      
      for (final doc in standRequests.docs) {
        await doc.reference.delete();
      }
      
      // Supprimer les tickets
      final tickets = await _ticketsCollection
          .where('conventionId', isEqualTo: conventionId)
          .get();
      
      for (final doc in tickets.docs) {
        await doc.reference.delete();
      }
      
      // Supprimer les campagnes marketing
      final campaigns = await _campaignsCollection
          .where('campaign.conventionId', isEqualTo: conventionId)
          .get();
      
      for (final doc in campaigns.docs) {
        await doc.reference.delete();
      }
      
    } catch (e) {
      print('Erreur suppression données liées: $e');
    }
  }

  /// Obtient le nombre total de conventions par statut
  Future<Map<String, int>> getConventionsCountByStatus() async {
    try {
      final organizerId = getCurrentOrganizerId();
      if (organizerId == null) {
        throw Exception('Organisateur non connecté');
      }
      
      final allConventions = await _conventionsCollection
          .where('basic.organizerId', isEqualTo: organizerId)
          .get();
      
      final counts = <String, int>{
        'draft': 0,
        'published': 0,
        'active': 0,
        'completed': 0,
        'archived': 0,
      };
      
      for (final doc in allConventions.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['basic']?['status'] as String?;
        
        if (status != null && counts.containsKey(status)) {
          counts[status] = counts[status]! + 1;
        }
      }
      
      return counts;
      
    } catch (e) {
      print('Erreur comptage conventions: $e');
      return {
        'draft': 0,
        'published': 0,
        'active': 0,
        'completed': 0,
        'archived': 0,
      };
    }
  }

  /// Obtient les conventions à venir (dans les 30 prochains jours)
  Future<List<DocumentSnapshot>> getUpcomingConventions() async {
    try {
      final organizerId = getCurrentOrganizerId();
      if (organizerId == null) {
        throw Exception('Organisateur non connecté');
      }
      
      final now = DateTime.now();
      final inThirtyDays = now.add(const Duration(days: 30));
      
      final snapshot = await _conventionsCollection
          .where('basic.organizerId', isEqualTo: organizerId)
          .where('dates.start', isGreaterThan: Timestamp.fromDate(now))
          .where('dates.start', isLessThan: Timestamp.fromDate(inThirtyDays))
          .orderBy('dates.start')
          .get();
      
      return snapshot.docs;
      
    } catch (e) {
      throw Exception('Erreur conventions à venir: $e');
    }
  }

  /// Met à jour les métriques d'une convention
  Future<void> updateConventionMetrics(String conventionId, Map<String, dynamic> metrics) async {
    try {
      await _conventionsCollection.doc(conventionId).update({
        'stats': metrics,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur mise à jour métriques: $e');
    }
  }

  /// ===== DEMANDES DE STANDS =====

  /// Stream des demandes de stands en attente
  Stream<QuerySnapshot> getPendingStandRequestsStream(String organizerId) {
    return _standRequestsCollection
        .where('convention.organizerId', isEqualTo: organizerId)
        .where('status.current', isEqualTo: 'pending')
        .orderBy('status.createdAt', descending: true)
        .snapshots();
  }

  /// Stream de toutes les demandes de stands
  Stream<QuerySnapshot> getAllStandRequestsStream(String organizerId) {
    return _standRequestsCollection
        .where('convention.organizerId', isEqualTo: organizerId)
        .orderBy('status.createdAt', descending: true)
        .snapshots();
  }

  /// Accepte une demande de stand et crée le paiement
  Future<Map<String, dynamic>> acceptStandRequest(
    String requestId,
    Map<String, dynamic> requestData,
  ) async {
    try {
      final organizerId = getCurrentOrganizerId();
      if (organizerId == null) throw Exception('Organisateur non connecté');

      // Met à jour le statut de la demande
      await _standRequestsCollection.doc(requestId).update({
        'status.current': 'accepted',
        'status.acceptedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Crée le paiement via votre service existant
      final paymentResult = await _paymentService.payProject(
        projectId: requestData['convention']?['id'] ?? '',
        amount: (requestData['stand']?['price'] ?? 0.0).toDouble(),
        tattooistId: requestData['tattooist']?['id'] ?? '',
        description: 'Stand ${requestData['stand']?['size']} - ${requestData['convention']?['name'] ?? ''}',
      );

      // Met à jour la demande avec les infos de paiement
      await _standRequestsCollection.doc(requestId).update({
        'payment.paymentId': paymentResult['id'],
        'payment.status': paymentResult['status'],
        'payment.createdAt': FieldValue.serverTimestamp(),
      });

      // Met à jour les stats
      await incrementStat(organizerId, 'totalTattooers', 1);

      return paymentResult;
    } catch (e) {
      throw Exception('Erreur acceptation demande: $e');
    }
  }

  /// Refuse une demande de stand
  Future<void> rejectStandRequest(String requestId, String reason) async {
    await _standRequestsCollection.doc(requestId).update({
      'status.current': 'rejected',
      'status.rejectedAt': FieldValue.serverTimestamp(),
      'status.reason': reason,
    });
  }

  /// ===== BILLETERIE =====

  /// Obtient les statistiques de billeterie
  Future<Map<String, dynamic>> getTicketingStats(String conventionId) async {
    try {
      // ✅ Utilise votre service de paiement pour les commissions
      final paymentStats = await _paymentService.getCommissionStats(conventionId);
      
      final ticketsQuery = await _ticketsCollection
          .where('conventionId', isEqualTo: conventionId)
          .get();

      int totalSold = 0;
      double totalRevenue = 0.0;
      Map<String, int> typeBreakdown = {};

      for (var doc in ticketsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final quantity = data['quantity'] is int 
            ? data['quantity'] as int
            : int.tryParse(data['quantity'].toString()) ?? 1;
        final amount = data['amount'] is double 
            ? data['amount'] as double
            : double.tryParse(data['amount'].toString()) ?? 0.0;
        
        totalSold += quantity;
        totalRevenue += amount;
        
        final type = data['type']?.toString() ?? 'standard';
        typeBreakdown[type] = (typeBreakdown[type] ?? 0) + quantity;
      }

      return {
        'total_sold': totalSold,
        'total_revenue': totalRevenue,
        'type_breakdown': typeBreakdown,
        'commission_paid': paymentStats['total_commissions'] ?? 0.0,
        'net_revenue': totalRevenue - (paymentStats['total_commissions']?.toDouble() ?? 0.0),
      };
    } catch (e) {
      throw Exception('Erreur stats billeterie: $e');
    }
  }

  /// Crée un billet pour un acheteur
  Future<String> createTicket({
    required String conventionId,
    required String buyerId,
    required String ticketType,
    required int quantity,
    required double unitPrice,
  }) async {
    try {
      final totalAmount = quantity * unitPrice;
      
      // ✅ Crée le paiement via votre service existant
      final paymentResult = await _paymentService.payProject(
        projectId: conventionId,
        amount: totalAmount,
        tattooistId: '', // L'organisateur reçoit le paiement
        description: 'Billet $ticketType x$quantity',
      );

      // Crée le ticket
      final docRef = await _ticketsCollection.add({
        'conventionId': conventionId,
        'buyerId': buyerId,
        'type': ticketType,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalAmount': totalAmount,
        'paymentId': paymentResult['id'],
        'paymentStatus': paymentResult['status'],
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Met à jour les stats
      final organizerId = getCurrentOrganizerId();
      if (organizerId != null) {
        await incrementStat(organizerId, 'totalVisitors', quantity);
        await incrementStat(organizerId, 'totalRevenue', totalAmount.toInt());
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur création billet: $e');
    }
  }

  /// ===== MARKETING =====

  /// Stream des campagnes marketing
  Stream<QuerySnapshot> getCampaignsStream(String organizerId) {
    return _campaignsCollection
        .where('campaign.organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Crée une campagne marketing
  Future<String> createCampaign(Map<String, dynamic> campaignData) async {
    try {
      final organizerId = getCurrentOrganizerId();
      if (organizerId == null) throw Exception('Organisateur non connecté');

      final docRef = await _campaignsCollection.add({
        ...campaignData,
        'campaign': {
          ...campaignData['campaign'] ?? {},
          'organizerId': organizerId,
        },
        'status': 'draft',
        'metrics': {
          'sent': 0,
          'delivered': 0,
          'opened': 0,
          'clicked': 0,
          'conversions': 0,
          'reach': 0,
          'engagement': 0,
          'engagementRate': 0.0,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur création campagne: $e');
    }
  }

  /// Lance une campagne immédiatement
  Future<void> launchCampaign(String campaignId) async {
    await _campaignsCollection.doc(campaignId).update({
      'status': 'active',
      'launchedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ===== REVENUS ET ANALYTICS =====

  /// Calcule les revenus totaux d'un organisateur
  Future<Map<String, dynamic>> calculateTotalRevenue(String organizerId) async {
    try {
      // ✅ Utilise votre service de paiement pour les stats
      final stats = await _paymentService.getCommissionStats(organizerId, months: 12);
      
      final totalRevenue = (stats['total_revenue'] ?? 0.0).toDouble();
      final totalCommissions = (stats['total_commissions'] ?? 0.0).toDouble();
      final netRevenue = totalRevenue - totalCommissions;

      // Obtient les données mensuelles
      final monthlyData = await _paymentService.getMonthlyEarnings(DateTime.now().year);

      // Met à jour les stats dans le profil
      await updateStats(organizerId, {
        'totalRevenue': totalRevenue.toInt(),
        'avgRating': 4.5, // À calculer selon vos besoins
      });

      return {
        'total_revenue': totalRevenue,
        'total_commissions': totalCommissions,
        'net_revenue': netRevenue,
        'monthly_data': monthlyData,
        'commission_rate': totalRevenue > 0 ? (totalCommissions / totalRevenue) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Erreur calcul revenus: $e');
    }
  }

  /// Génère un rapport complet pour l'organisateur
  Future<Map<String, dynamic>> generateOrganizatorReport(String organizerId) async {
    try {
      final revenueData = await calculateTotalRevenue(organizerId);
      
      // Obtient le profil avec les stats
      final profileDoc = await getOrganizerProfile(organizerId);
      final profileData = profileDoc.data() as Map<String, dynamic>?;
      final profileStats = profileData?['stats'] ?? {};
      
      // Conventions actives
      final conventionsSnapshot = await _conventionsCollection
          .where('basic.organizerId', isEqualTo: organizerId)
          .where('status', whereIn: ['published', 'active'])
          .get();

      final activeConventions = conventionsSnapshot.docs.length;
      
      // Demandes en attente
      final pendingRequestsSnapshot = await _standRequestsCollection
          .where('convention.organizerId', isEqualTo: organizerId)
          .where('status.current', isEqualTo: 'pending')
          .get();

      final pendingRequests = pendingRequestsSnapshot.docs.length;

      return {
        'summary': {
          'active_conventions': activeConventions,
          'pending_requests': pendingRequests,
          'total_revenue': revenueData['total_revenue'],
          'net_revenue': revenueData['net_revenue'],
          'total_conventions': profileStats['totalConventions'] ?? 0,
          'total_tattooers': profileStats['totalTattooers'] ?? 0,
          'total_visitors': profileStats['totalVisitors'] ?? 0,
        },
        'revenue': revenueData,
        'growth_rate': _calculateGrowthRate(revenueData['monthly_data'] as List),
        'profile_stats': profileStats,
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Erreur génération rapport: $e');
    }
  }

  /// ===== MÉTHODES ADMINISTRATIVES =====

  /// Stream des organisateurs vérifiés (pour admin)
  Stream<QuerySnapshot> getVerifiedOrganizersStream() {
    return _organizersCollection
        .where('isVerified', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Marque un organisateur comme vérifié (admin)
  Future<void> verifyOrganizer(String organizerId) async {
    await _organizersCollection.doc(organizerId).update({
      'isVerified': true,
      'status': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Suspend un organisateur (admin)
  Future<void> suspendOrganizer(String organizerId, String reason) async {
    await _organizersCollection.doc(organizerId).update({
      'status': 'suspended',
      'suspendedAt': FieldValue.serverTimestamp(),
      'suspensionReason': reason,
    });
  }

  /// Recherche d'organisateurs
  Future<QuerySnapshot> searchOrganizers(String query) {
    return _organizersCollection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + '\uf8ff')
        .limit(20)
        .get();
  }

  /// Supprime un organisateur (GDPR)
  Future<void> deleteOrganizer(String organizerId) async {
    await _organizersCollection.doc(organizerId).delete();
  }

  /// Métriques d'activité (pour admin)
  Future<Map<String, dynamic>> getActivityMetrics() async {
    final organizersSnapshot = await _organizersCollection.get();
    final conventionsSnapshot = await _conventionsCollection.get();
    final standRequestsSnapshot = await _standRequestsCollection.get();

    return {
      'total_organizers': organizersSnapshot.docs.length,
      'verified_organizers': organizersSnapshot.docs
          .where((doc) => (doc.data() as Map)['isVerified'] == true)
          .length,
      'total_conventions': conventionsSnapshot.docs.length,
      'total_stand_requests': standRequestsSnapshot.docs.length,
    };
  }

  /// ===== MÉTHODES UTILITAIRES =====

  /// Calcule le taux de croissance
  double _calculateGrowthRate(List<dynamic> monthlyData) {
    if (monthlyData.length < 2) return 0.0;
    
    final lastMonth = monthlyData.last['earnings'] ?? 0.0;
    final previousMonth = monthlyData[monthlyData.length - 2]['earnings'] ?? 0.0;
    
    if (previousMonth == 0) return 0.0;
    
    return ((lastMonth - previousMonth) / previousMonth) * 100;
  }

  /// Vérifie si l'utilisateur peut gérer une convention
  Future<bool> canManageConvention(String conventionId) async {
    try {
      final organizerId = getCurrentOrganizerId();
      if (organizerId == null) return false;

      final doc = await _conventionsCollection.doc(conventionId).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>;
      return data['basic']?['organizerId'] == organizerId;
    } catch (e) {
      return false;
    }
  }

  /// Obtient les informations de paiement d'une convention
  Future<Map<String, dynamic>?> getConventionPaymentInfo(String conventionId) async {
    try {
      // ✅ Utilise votre service pour les paiements
      final payments = await _paymentService.getProjectPayments(conventionId);
      
      double totalReceived = 0.0;
      double totalCommissions = 0.0;
      int transactionCount = 0;

      for (var payment in payments) {
        if (payment['status'] == 'succeeded') {
          totalReceived += (payment['amount']?.toDouble() ?? 0.0);
          totalCommissions += (payment['platformFee']?.toDouble() ?? 0.0);
          transactionCount++;
        }
      }

      return {
        'total_received': totalReceived,
        'total_commissions': totalCommissions,
        'net_amount': totalReceived - totalCommissions,
        'transaction_count': transactionCount,
        'payments': payments,
      };
    } catch (e) {
      return null;
    }
  }

  /// Accès direct à votre service de paiement
  FirebasePaymentService get paymentService => _paymentService;
}