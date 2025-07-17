// lib/services/organisateur/analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir un stream des analytics de ventes
  Stream<QuerySnapshot> getSalesAnalyticsStream(String organizerId) {
    return _firestore
        .collection('ticket_sales')
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('saleDate', descending: true)
        .limit(100)
        .snapshots();
  }

  // Obtenir les métriques générales pour un organisateur
  Future<Map<String, dynamic>> getAnalytics(String organizerId) async {
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, now.day);
      
      // Statistiques des conventions
      final conventionsStats = await _getConventionsStats(organizerId);
      
      // Statistiques de visiteurs
      final visitorsStats = await _getVisitorsStats(organizerId, lastMonth);
      
      // Statistiques de revenus
      final revenueStats = await _getRevenueStats(organizerId, lastMonth);
      
      // Statistiques des tatoueurs
      final tattooersStats = await _getTattooersStats(organizerId);
      
      return {
        'conventions': conventionsStats,
        'visitors': visitorsStats,
        'revenue': revenueStats,
        'tattooers': tattooersStats,
        'period': 'last_30_days',
        'generatedAt': FieldValue.serverTimestamp(),
      };
    } catch (e) {
      print('Erreur getAnalytics: $e');
      return _getDefaultAnalytics();
    }
  }

  Future<Map<String, dynamic>> _getConventionsStats(String organizerId) async {
    try {
      final snapshot = await _firestore
          .collection('conventions')
          .where('organizerId', isEqualTo: organizerId)
          .get();

      int totalConventions = snapshot.docs.length;
      int activeConventions = 0;
      int upcomingConventions = 0;
      int completedConventions = 0;
      
      final now = DateTime.now();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final startDate = (data['startDate'] as Timestamp?)?.toDate();
        final endDate = (data['endDate'] as Timestamp?)?.toDate();
        
        if (startDate != null && endDate != null) {
          if (now.isBefore(startDate)) {
            upcomingConventions++;
          } else if (now.isAfter(endDate)) {
            completedConventions++;
          } else {
            activeConventions++;
          }
        }
      }

      return {
        'total': totalConventions,
        'active': activeConventions,
        'upcoming': upcomingConventions,
        'completed': completedConventions,
      };
    } catch (e) {
      print('Erreur _getConventionsStats: $e');
      return {'total': 0, 'active': 0, 'upcoming': 0, 'completed': 0};
    }
  }

  Future<Map<String, dynamic>> _getVisitorsStats(String organizerId, DateTime since) async {
    try {
      // Simuler des données de visiteurs - à adapter selon votre logique
      final snapshot = await _firestore
          .collection('convention_visits')
          .where('organizerId', isEqualTo: organizerId)
          .where('visitDate', isGreaterThan: Timestamp.fromDate(since))
          .get();

      int totalVisitors = snapshot.docs.length;
      int uniqueVisitors = snapshot.docs.map((doc) => doc.data()['visitorId']).toSet().length;
      
      return {
        'total': totalVisitors,
        'unique': uniqueVisitors,
        'returning': totalVisitors - uniqueVisitors,
        'averagePerDay': totalVisitors / 30,
      };
    } catch (e) {
      print('Erreur _getVisitorsStats: $e');
      return {'total': 0, 'unique': 0, 'returning': 0, 'averagePerDay': 0.0};
    }
  }

  Future<Map<String, dynamic>> _getRevenueStats(String organizerId, DateTime since) async {
    try {
      // Récupérer les tickets vendus
      final ticketsSnapshot = await _firestore
          .collection('tickets')
          .where('organizerId', isEqualTo: organizerId)
          .get();
      
      double totalRevenue = 0.0;
      int totalSales = 0;
      
      for (final doc in ticketsSnapshot.docs) {
        final data = doc.data();
        final sold = data['sold'] as int? ?? 0;
        final price = data['price'] as double? ?? 0.0;
        
        totalRevenue += sold * price;
        totalSales += sold;
      }
      
      // Récupérer les données du mois précédent pour la comparaison
      final lastMonthRevenue = await _getLastMonthRevenue(organizerId, since);
      final growth = lastMonthRevenue > 0 ? ((totalRevenue - lastMonthRevenue) / lastMonthRevenue) * 100 : 0.0;
      
      return {
        'total': totalRevenue,
        'totalSales': totalSales,
        'averagePerSale': totalSales > 0 ? totalRevenue / totalSales : 0.0,
        'growth': growth,
        'lastMonth': lastMonthRevenue,
      };
    } catch (e) {
      print('Erreur _getRevenueStats: $e');
      return {'total': 0.0, 'totalSales': 0, 'averagePerSale': 0.0, 'growth': 0.0};
    }
  }

  Future<double> _getLastMonthRevenue(String organizerId, DateTime since) async {
    try {
      // Simuler les revenus du mois précédent
      // À adapter selon votre structure de données
      return 500.0; // Valeur simulée
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> _getTattooersStats(String organizerId) async {
    try {
      final snapshot = await _firestore
          .collection('convention_participants')
          .where('organizerId', isEqualTo: organizerId)
          .where('type', isEqualTo: 'tattooist')
          .get();

      int totalTattooers = snapshot.docs.length;
      int activeTattooers = snapshot.docs.where((doc) => 
        doc.data()['status'] == 'confirmed'
      ).length;
      
      return {
        'total': totalTattooers,
        'active': activeTattooers,
        'pending': totalTattooers - activeTattooers,
      };
    } catch (e) {
      print('Erreur _getTattooersStats: $e');
      return {'total': 0, 'active': 0, 'pending': 0};
    }
  }

  // Obtenir des métriques détaillées pour une période spécifique
  Future<Map<String, dynamic>> getDetailedAnalytics(
    String organizerId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final analytics = await getAnalytics(organizerId);
      
      // Ajouter des données spécifiques à la période
      final periodData = await _getPeriodSpecificData(organizerId, startDate, endDate);
      
      return {
        ...analytics,
        'period_specific': periodData,
        'date_range': {
          'start': Timestamp.fromDate(startDate),
          'end': Timestamp.fromDate(endDate),
        },
      };
    } catch (e) {
      print('Erreur getDetailedAnalytics: $e');
      return _getDefaultAnalytics();
    }
  }

  Future<Map<String, dynamic>> _getPeriodSpecificData(
    String organizerId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      // Données spécifiques à la période demandée
      final dailyRevenue = await _getDailyRevenue(organizerId, startDate, endDate);
      final popularEvents = await _getPopularEvents(organizerId, startDate, endDate);
      
      return {
        'daily_revenue': dailyRevenue,
        'popular_events': popularEvents,
      };
    } catch (e) {
      return {'daily_revenue': [], 'popular_events': []};
    }
  }

  Future<List<Map<String, dynamic>>> _getDailyRevenue(
    String organizerId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    // Simuler des données quotidiennes de revenus
    final days = endDate.difference(startDate).inDays;
    final dailyRevenue = <Map<String, dynamic>>[];
    
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      dailyRevenue.add({
        'date': Timestamp.fromDate(date),
        'revenue': (i % 3 + 1) * 150.0, // Données simulées
      });
    }
    
    return dailyRevenue;
  }

  Future<List<Map<String, dynamic>>> _getPopularEvents(
    String organizerId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final snapshot = await _firestore
          .collection('conventions')
          .where('organizerId', isEqualTo: organizerId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('startDate')
          .limit(5)
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

  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'conventions': {'total': 0, 'active': 0, 'upcoming': 0, 'completed': 0},
      'visitors': {'total': 0, 'unique': 0, 'returning': 0, 'averagePerDay': 0.0},
      'revenue': {'total': 0.0, 'totalSales': 0, 'averagePerSale': 0.0, 'growth': 0.0},
      'tattooers': {'total': 0, 'active': 0, 'pending': 0},
      'period': 'last_30_days',
    };
  }

  // Enregistrer un événement d'analytics
  Future<void> trackEvent({
    required String organizerId,
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      await _firestore.collection('analytics_events').add({
        'organizerId': organizerId,
        'eventType': eventType,
        'eventData': eventData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur trackEvent: $e');
    }
  }
}