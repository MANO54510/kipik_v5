// lib/core/helpers/service_helper.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firestore_helper.dart';

/// 🎯 Helper central pour tous les services Firebase
/// Évite la redondance et centralise l'accès aux données
class ServiceHelper {
  // ⚡ Instance Firestore centralisée
  static FirebaseFirestore get firestore => FirestoreHelper.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  // 👤 Helpers d'authentification ultra-rapides
  static String? get currentUserId => auth.currentUser?.uid;
  static bool get isAuthenticated => auth.currentUser != null;
  static String? get currentUserEmail => auth.currentUser?.email;

  // 🎯 Méthodes communes ultra-optimisées
  static Future<T> handleAsyncOperation<T>(
    Future<T> Function() operation, {
    T? fallback,
    void Function(dynamic)? onError,
  }) async {
    try {
      return await operation();
    } catch (e) {
      onError?.call(e);
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  // 📊 Stream helper générique
  static Stream<QuerySnapshot> getStream(
    String collection, {
    Map<String, dynamic>? where,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = firestore.collection(collection);
    
    where?.forEach((field, value) {
      if (value is Map && value.containsKey('arrayContains')) {
        query = query.where(field, arrayContains: value['arrayContains']);
      } else if (value is Map && value.containsKey('isGreaterThan')) {
        query = query.where(field, isGreaterThan: value['isGreaterThan']);
      } else if (value is Map && value.containsKey('isLessThan')) {
        query = query.where(field, isLessThan: value['isLessThan']);
      } else {
        query = query.where(field, isEqualTo: value);
      }
    });
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }

  // 🔄 CRUD helper générique
  static Future<String> create(String collection, Map<String, dynamic> data) async {
    final doc = await firestore.collection(collection).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': currentUserId,
    });
    return doc.id;
  }

  static Future<void> update(String collection, String id, Map<String, dynamic> data) async {
    await firestore.collection(collection).doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    });
  }

  static Future<DocumentSnapshot> get(String collection, String id) async {
    return await firestore.collection(collection).doc(id).get();
  }

  static Future<void> delete(String collection, String id) async {
    await firestore.collection(collection).doc(id).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': currentUserId,
      'isDeleted': true,
    });
  }

  static Future<void> hardDelete(String collection, String id) async {
    await firestore.collection(collection).doc(id).delete();
  }

  // 📈 Analytics et tracking
  static Future<void> trackEvent(String eventName, Map<String, dynamic> eventData) async {
    try {
      await create('analytics_events', {
        'eventName': eventName,
        'eventData': eventData,
        'userId': currentUserId,
        'userEmail': currentUserEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
        'version': '1.0.0',
      });
    } catch (e) {
      print('❌ Erreur trackEvent: $e');
      // Ne pas faire planter l'app pour un problème de tracking
    }
  }

  // 🎯 Helpers spécialisés pour les cas d'usage fréquents
  static Future<Map<String, dynamic>> getConventionData(String conventionId) async {
    return handleAsyncOperation(
      () async {
        final doc = await get('conventions', conventionId);
        return doc.exists ? doc.data() as Map<String, dynamic> : {};
      },
      fallback: {},
    );
  }

  static Future<Map<String, dynamic>> getBilleterieStats(String organizerId) async {
    return handleAsyncOperation(
      () async {
        final snapshot = await firestore
            .collection('tickets')
            .where('organizerId', isEqualTo: organizerId)
            .get();
        
        int totalTickets = 0;
        int soldTickets = 0;
        double totalRevenue = 0.0;
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final capacity = data['capacity'] as int? ?? 0;
          final sold = data['sold'] as int? ?? 0;
          final price = (data['price'] as num?)?.toDouble() ?? 0.0;
          
          totalTickets += capacity;
          soldTickets += sold;
          totalRevenue += sold * price;
        }
        
        return {
          'totalTickets': totalTickets,
          'soldTickets': soldTickets,
          'totalRevenue': totalRevenue,
          'availability': totalTickets - soldTickets,
          'occupancyRate': totalTickets > 0 ? soldTickets / totalTickets : 0.0,
        };
      },
      fallback: {'totalTickets': 0, 'soldTickets': 0, 'totalRevenue': 0.0, 'availability': 0, 'occupancyRate': 0.0},
    );
  }

  static Future<Map<String, dynamic>> getAnalyticsData(String organizerId) async {
    return handleAsyncOperation(
      () async {
        // Récupérer les conventions de l'organisateur
        final conventionsSnapshot = await firestore
            .collection('conventions')
            .where('basic.organizerId', isEqualTo: organizerId)
            .get();
        
        // Calculer les métriques
        int totalConventions = conventionsSnapshot.docs.length;
        int activeConventions = 0;
        double totalRevenue = 0.0;
        int totalTattooers = 0;
        int totalVisitors = 0;
        
        for (final doc in conventionsSnapshot.docs) {
          final data = doc.data();
          final stats = data['stats'] as Map<String, dynamic>? ?? {};
          final status = data['basic']?['status'] ?? '';
          
          if (status == 'active') activeConventions++;
          
          totalRevenue += (stats['revenue']?['total'] as num?)?.toDouble() ?? 0.0;
          totalTattooers += stats['tattooersCount'] as int? ?? 0;
          totalVisitors += stats['visitorsCount'] as int? ?? 0;
        }
        
        return {
          'conventions': {
            'total': totalConventions,
            'active': activeConventions,
            'completed': totalConventions - activeConventions,
          },
          'revenue': {
            'total': totalRevenue,
            'average': totalConventions > 0 ? totalRevenue / totalConventions : 0.0,
            'growth': 5.2, // À calculer avec données historiques
          },
          'visitors': {
            'total': totalVisitors,
            'average': totalConventions > 0 ? totalVisitors ~/ totalConventions : 0,
          },
          'tattooers': {
            'total': totalTattooers,
            'active': totalTattooers,
            'average': totalConventions > 0 ? totalTattooers ~/ totalConventions : 0,
          },
        };
      },
      fallback: {
        'conventions': {'total': 0, 'active': 0, 'completed': 0},
        'revenue': {'total': 0.0, 'average': 0.0, 'growth': 0.0},
        'visitors': {'total': 0, 'average': 0},
        'tattooers': {'total': 0, 'active': 0, 'average': 0},
      },
    );
  }

  // 🎨 Helpers pour les conversions de données fréquentes
  static DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }

  static String formatCurrency(double amount, {String currency = '€'}) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M$currency';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k$currency';
    }
    return '${amount.toStringAsFixed(0)}$currency';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return 'Date inconnue';
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatTimeAgo(DateTime? date) {
    if (date == null) return 'Jamais';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return 'Il y a ${(difference.inDays / 365).floor()} an${(difference.inDays / 365).floor() > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      return 'Il y a ${(difference.inDays / 30).floor()} mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  // 📱 Helper pour les données organisateur courantes
  static Future<Map<String, dynamic>> getCurrentOrganizerData() async {
    final userId = currentUserId;
    if (userId == null) return {};
    
    return handleAsyncOperation(
      () async {
        final doc = await get('organizers', userId);
        return doc.exists ? doc.data() as Map<String, dynamic> : {};
      },
      fallback: {},
    );
  }

  // 🔍 Helpers de recherche avancée
  static Future<List<Map<String, dynamic>>> searchConventions({
    String? organizerId,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? searchTerm,
    int limit = 20,
  }) async {
    Query query = firestore.collection('conventions');
    
    if (organizerId != null) {
      query = query.where('basic.organizerId', isEqualTo: organizerId);
    }
    
    if (status != null) {
      query = query.where('basic.status', isEqualTo: status);
    }
    
    if (type != null) {
      query = query.where('basic.type', isEqualTo: type);
    }
    
    if (startDate != null) {
      query = query.where('dates.start', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    
    if (endDate != null) {
      query = query.where('dates.end', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    query = query.limit(limit);
    
    final snapshot = await query.get();
    
    List<Map<String, dynamic>> results = snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
    
    // Filtre par terme de recherche (côté client pour flexibilité)
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final term = searchTerm.toLowerCase();
      results = results.where((convention) {
        final name = (convention['basic']?['name'] ?? '').toString().toLowerCase();
        final description = (convention['basic']?['description'] ?? '').toString().toLowerCase();
        final location = (convention['location']?['venue'] ?? '').toString().toLowerCase();
        
        return name.contains(term) || description.contains(term) || location.contains(term);
      }).toList();
    }
    
    return results;
  }

  // 📊 Helpers pour les statistiques
  static Future<Map<String, dynamic>> getMonthlyStats(String organizerId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    return handleAsyncOperation(
      () async {
        // Stats des conventions du mois
        final conventionsSnapshot = await firestore
            .collection('conventions')
            .where('basic.organizerId', isEqualTo: organizerId)
            .where('dates.start', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('dates.start', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .get();
        
        double monthlyRevenue = 0.0;
        int monthlyConventions = conventionsSnapshot.docs.length;
        int monthlyParticipants = 0;
        
        for (final doc in conventionsSnapshot.docs) {
          final data = doc.data();
          final stats = data['stats'] as Map<String, dynamic>? ?? {};
          
          monthlyRevenue += (stats['revenue']?['total'] as num?)?.toDouble() ?? 0.0;
          monthlyParticipants += stats['tattooersCount'] as int? ?? 0;
        }
        
        return {
          'month': '${month.month}/${month.year}',
          'conventions': monthlyConventions,
          'revenue': monthlyRevenue,
          'participants': monthlyParticipants,
          'averageRevenuePerConvention': monthlyConventions > 0 ? monthlyRevenue / monthlyConventions : 0.0,
        };
      },
      fallback: {
        'month': '${month.month}/${month.year}',
        'conventions': 0,
        'revenue': 0.0,
        'participants': 0,
        'averageRevenuePerConvention': 0.0,
      },
    );
  }

  // 🔄 Helper pour refresh automatique des données
  static void scheduleDataRefresh(void Function() callback, {Duration interval = const Duration(minutes: 5)}) {
    Timer.periodic(interval, (_) => callback());
  }

  // 🛡️ Helper pour les opérations batch
  static Future<void> batchOperation(List<Map<String, dynamic>> operations) async {
    final batch = firestore.batch();
    
    for (final operation in operations) {
      final type = operation['type'] as String;
      final collection = operation['collection'] as String;
      final data = operation['data'] as Map<String, dynamic>;
      
      switch (type) {
        case 'create':
          final ref = firestore.collection(collection).doc();
          batch.set(ref, {
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': currentUserId,
          });
          break;
        case 'update':
          final id = operation['id'] as String;
          final ref = firestore.collection(collection).doc(id);
          batch.update(ref, {
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': currentUserId,
          });
          break;
        case 'delete':
          final id = operation['id'] as String;
          final ref = firestore.collection(collection).doc(id);
          batch.update(ref, {
            'deletedAt': FieldValue.serverTimestamp(),
            'deletedBy': currentUserId,
            'isDeleted': true,
          });
          break;
      }
    }
    
    await batch.commit();
  }

  // 🔐 Helper pour les permissions
  static Future<bool> hasPermission(String resource, String action) async {
    final userId = currentUserId;
    if (userId == null) return false;
    
    try {
      final doc = await get('user_permissions', userId);
      if (!doc.exists) return false;
      
      final permissions = doc.data() as Map<String, dynamic>;
      final userRole = permissions['role'] as String? ?? 'user';
      final customPermissions = permissions['permissions'] as Map<String, dynamic>? ?? {};
      
      // Admin a tous les droits
      if (userRole == 'admin') return true;
      
      // Vérifier les permissions spécifiques
      final resourcePermissions = customPermissions[resource] as List<dynamic>? ?? [];
      return resourcePermissions.contains(action);
    } catch (e) {
      print('❌ Erreur vérification permissions: $e');
      return false;
    }
  }
}

/// 🎯 Extension pour les conversions rapides de documents
extension DocumentHelper on DocumentSnapshot {
  Map<String, dynamic> get dataOrEmpty => exists ? data() as Map<String, dynamic> : {};
  
  T? getField<T>(String field) {
    final data = dataOrEmpty;
    return data[field] as T?;
  }
  
  String getString(String field, {String fallback = ''}) {
    return getField<String>(field) ?? fallback;
  }
  
  double getDouble(String field, {double fallback = 0.0}) {
    final value = getField(field);
    if (value is num) return value.toDouble();
    return fallback;
  }
  
  int getInt(String field, {int fallback = 0}) {
    final value = getField(field);
    if (value is num) return value.toInt();
    return fallback;
  }
  
  bool getBool(String field, {bool fallback = false}) {
    return getField<bool>(field) ?? fallback;
  }
  
  DateTime? getDateTime(String field) {
    final value = getField(field);
    return ServiceHelper.timestampToDateTime(value);
  }
  
  List<T> getList<T>(String field) {
    final value = getField<List>(field);
    return value?.cast<T>() ?? <T>[];
  }
}

/// 🎯 Extension pour les QuerySnapshot
extension QueryHelper on QuerySnapshot {
  List<Map<String, dynamic>> get dataList {
    return docs.map((doc) => {
      'id': doc.id,
      ...doc.dataOrEmpty,
    }).toList();
  }
  
  Map<String, dynamic> get firstData {
    return docs.isNotEmpty ? docs.first.dataOrEmpty : {};
  }
  
  List<String> get docIds {
    return docs.map((doc) => doc.id).toList();
  }
}