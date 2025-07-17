// lib/services/organisateur/billeterie_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BilleterieService {
  static final BilleterieService _instance = BilleterieService._internal();
  static BilleterieService get instance => _instance;
  BilleterieService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== STREAMS TEMPS RÉEL =====
  
  /// Stream des conventions avec leurs tickets
  Stream<QuerySnapshot> getConventionsWithTicketsStream(String organizerId) {
    return _firestore
        .collection('tickets')
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream des ventes récentes
  Stream<QuerySnapshot> getRecentSalesStream(String organizerId) {
    return _firestore
        .collection('ticket_sales')
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('saleDate', descending: true)
        .limit(10)
        .snapshots();
  }

  /// Stream des ventes de tickets avec filtres
  Stream<QuerySnapshot> getTicketSalesStream({
    required String organizerId,
    String? conventionId,
    String? period,
  }) {
    Query query = _firestore
        .collection('ticket_sales')
        .where('organizerId', isEqualTo: organizerId);
    
    if (conventionId != null && conventionId.isNotEmpty) {
      query = query.where('conventionId', isEqualTo: conventionId);
    }
    
    // Filtres par période
    if (period != null && period != 'all') {
      final now = DateTime.now();
      DateTime startDate;
      
      switch (period) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }
      
      query = query.where('saleDate', isGreaterThan: Timestamp.fromDate(startDate));
    }
    
    return query
        .orderBy('saleDate', descending: true)
        .limit(50)
        .snapshots();
  }

  // ===== STATISTIQUES =====

  /// Obtient les statistiques de billetterie pour un organisateur
  Future<Map<String, dynamic>> getBilleterieStats(String organizerId) async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('organizerId', isEqualTo: organizerId)
          .get();

      int totalTickets = 0;
      int soldTickets = 0;
      double totalRevenue = 0.0;
      Map<String, int> typeBreakdown = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final quantity = data['quantity'] as int? ?? 0;
        final sold = data['sold'] as int? ?? 0;
        final price = data['price'] as double? ?? 0.0;
        final type = data['name'] as String? ?? 'standard';
        
        totalTickets += quantity;
        soldTickets += sold;
        totalRevenue += price * sold;
        
        typeBreakdown[type] = (typeBreakdown[type] ?? 0) + sold;
      }

      return {
        'totalTickets': totalTickets,
        'soldTickets': soldTickets,
        'availableTickets': totalTickets - soldTickets,
        'totalRevenue': totalRevenue,
        'salesRate': totalTickets > 0 ? (soldTickets / totalTickets) * 100 : 0.0,
        'typeBreakdown': typeBreakdown,
        'averageTicketPrice': soldTickets > 0 ? totalRevenue / soldTickets : 0.0,
      };
    } catch (e) {
      print('Erreur getBilleterieStats: $e');
      return {
        'totalTickets': 0,
        'soldTickets': 0,
        'availableTickets': 0,
        'totalRevenue': 0.0,
        'salesRate': 0.0,
        'typeBreakdown': <String, int>{},
        'averageTicketPrice': 0.0,
      };
    }
  }

  // ===== GESTION DES TYPES DE BILLETS =====

  /// Crée un nouveau type de ticket
  Future<String?> createTicketType({
    required String organizerId,
    required String conventionId,
    required String name,
    required double price,
    required int quantity,
    String? description,
    DateTime? saleStartDate,
    DateTime? saleEndDate,
  }) async {
    try {
      final docRef = await _firestore.collection('tickets').add({
        'organizerId': organizerId,
        'conventionId': conventionId,
        'name': name,
        'description': description ?? '',
        'price': price,
        'quantity': quantity,
        'sold': 0,
        'saleStartDate': saleStartDate != null ? Timestamp.fromDate(saleStartDate) : null,
        'saleEndDate': saleEndDate != null ? Timestamp.fromDate(saleEndDate) : null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      
      return docRef.id;
    } catch (e) {
      print('Erreur createTicketType: $e');
      return null;
    }
  }

  /// Met à jour un type de ticket
  Future<bool> updateTicketType(String ticketTypeId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('tickets').doc(ticketTypeId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur updateTicketType: $e');
      return false;
    }
  }

  /// Désactive un type de ticket
  Future<bool> disableTicketType(String ticketTypeId) async {
    try {
      await _firestore.collection('tickets').doc(ticketTypeId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur disableTicketType: $e');
      return false;
    }
  }

  /// Active un type de ticket
  Future<bool> enableTicketType(String ticketTypeId) async {
    try {
      await _firestore.collection('tickets').doc(ticketTypeId).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur enableTicketType: $e');
      return false;
    }
  }

  /// Obtient la liste des types de tickets pour une convention
  Future<List<Map<String, dynamic>>> getTicketTypes(String conventionId) async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('conventionId', isEqualTo: conventionId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Erreur getTicketTypes: $e');
      return [];
    }
  }

  // ===== VENTES =====

  /// Vend des tickets
  Future<bool> sellTickets({
    required String ticketTypeId,
    required int quantity,
    required String buyerEmail,
    required String buyerName,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final ticketRef = _firestore.collection('tickets').doc(ticketTypeId);
        final ticketSnapshot = await transaction.get(ticketRef);
        
        if (!ticketSnapshot.exists) {
          throw Exception('Type de ticket non trouvé');
        }
        
        final ticketData = ticketSnapshot.data()!;
        final currentSold = ticketData['sold'] as int;
        final totalQuantity = ticketData['quantity'] as int;
        
        if (currentSold + quantity > totalQuantity) {
          throw Exception('Pas assez de tickets disponibles');
        }
        
        // Met à jour le nombre de tickets vendus
        transaction.update(ticketRef, {
          'sold': currentSold + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Crée l'entrée de vente
        transaction.set(_firestore.collection('ticket_sales').doc(), {
          'ticketTypeId': ticketTypeId,
          'organizerId': ticketData['organizerId'],
          'conventionId': ticketData['conventionId'],
          'quantity': quantity,
          'buyerEmail': buyerEmail,
          'buyerName': buyerName,
          'price': ticketData['price'],
          'totalAmount': (ticketData['price'] as double) * quantity,
          'saleDate': FieldValue.serverTimestamp(),
          'status': 'confirmed',
          'ticketTypeName': ticketData['name'],
        });
        
        return true;
      });
    } catch (e) {
      print('Erreur sellTickets: $e');
      return false;
    }
  }

  /// Annule une vente
  Future<bool> cancelSale(String saleId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final saleRef = _firestore.collection('ticket_sales').doc(saleId);
        final saleSnapshot = await transaction.get(saleRef);
        
        if (!saleSnapshot.exists) {
          throw Exception('Vente non trouvée');
        }
        
        final saleData = saleSnapshot.data()!;
        final ticketTypeId = saleData['ticketTypeId'] as String;
        final quantity = saleData['quantity'] as int;
        
        // Remet les tickets en disponibilité
        final ticketRef = _firestore.collection('tickets').doc(ticketTypeId);
        transaction.update(ticketRef, {
          'sold': FieldValue.increment(-quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Met à jour le statut de la vente
        transaction.update(saleRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      });
    } catch (e) {
      print('Erreur cancelSale: $e');
      return false;
    }
  }

  // ===== HISTORIQUE =====

  /// Obtient l'historique des ventes
  Future<List<Map<String, dynamic>>> getSalesHistory(String organizerId, {int limit = 50}) async {
    try {
      final salesSnapshot = await _firestore
          .collection('ticket_sales')
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('saleDate', descending: true)
          .limit(limit)
          .get();
      
      return salesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Erreur getSalesHistory: $e');
      return [];
    }
  }

  /// Obtient les ventes pour une convention spécifique
  Future<List<Map<String, dynamic>>> getConventionSales(String conventionId) async {
    try {
      final salesSnapshot = await _firestore
          .collection('ticket_sales')
          .where('conventionId', isEqualTo: conventionId)
          .orderBy('saleDate', descending: true)
          .get();
      
      return salesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Erreur getConventionSales: $e');
      return [];
    }
  }

  // ===== RAPPORTS =====

  /// Génère un rapport de ventes pour une période
  Future<Map<String, dynamic>> generateSalesReport({
    required String organizerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('ticket_sales')
          .where('organizerId', isEqualTo: organizerId);
      
      if (startDate != null) {
        query = query.where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      final snapshot = await query.get();
      
      double totalRevenue = 0.0;
      int totalTickets = 0;
      Map<String, int> salesByType = {};
      Map<String, double> revenueByType = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['totalAmount'] as double?) ?? 0.0;
        final quantity = (data['quantity'] as int?) ?? 0;
        final typeName = (data['ticketTypeName'] as String?) ?? 'Inconnu';
        
        totalRevenue += amount;
        totalTickets += quantity;
        
        salesByType[typeName] = (salesByType[typeName] ?? 0) + quantity;
        revenueByType[typeName] = (revenueByType[typeName] ?? 0.0) + amount;
      }
      
      return {
        'totalRevenue': totalRevenue,
        'totalTickets': totalTickets,
        'salesByType': salesByType,
        'revenueByType': revenueByType,
        'averageTicketPrice': totalTickets > 0 ? totalRevenue / totalTickets : 0.0,
        'totalSales': snapshot.docs.length,
        'period': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Erreur generateSalesReport: $e');
      return {
        'totalRevenue': 0.0,
        'totalTickets': 0,
        'salesByType': <String, int>{},
        'revenueByType': <String, double>{},
        'averageTicketPrice': 0.0,
        'totalSales': 0,
        'error': e.toString(),
      };
    }
  }

  // ===== VALIDATION =====

  /// Valide qu'un ticket peut être vendu
  Future<bool> canSellTicket(String ticketTypeId, int quantity) async {
    try {
      final doc = await _firestore.collection('tickets').doc(ticketTypeId).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final isActive = data['isActive'] as bool? ?? false;
      final currentSold = data['sold'] as int? ?? 0;
      final totalQuantity = data['quantity'] as int? ?? 0;
      final saleEndDate = data['saleEndDate'] as Timestamp?;
      
      // Vérifications
      if (!isActive) return false;
      if (currentSold + quantity > totalQuantity) return false;
      if (saleEndDate != null && DateTime.now().isAfter(saleEndDate.toDate())) return false;
      
      return true;
    } catch (e) {
      print('Erreur canSellTicket: $e');
      return false;
    }
  }
}