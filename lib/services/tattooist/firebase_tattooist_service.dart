// lib/services/tattooist/firebase_tattooist_service.dart
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_service.dart';
import 'tattooist_service.dart';

class FirebaseTattooistService extends TattooistService {
  static FirebaseTattooistService? _instance;
  static FirebaseTattooistService get instance => _instance ??= FirebaseTattooistService._();
  FirebaseTattooistService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getTattooists({
    String? city,
    String? style,
    double? maxDistance,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'tattooist')
          .where('isActive', isEqualTo: true);

      if (city != null) {
        query = query.where('city', isEqualTo: city);
      }

      if (style != null) {
        query = query.where('specialties', arrayContains: style);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération tatoueurs: $e');
    }
  }

  Future<Map<String, dynamic>?> getTattooistProfile(String tattooistId) async {
    try {
      final doc = await _firestore.collection('users').doc(tattooistId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateTattooistProfile(Map<String, dynamic> profileData) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      profileData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(user.uid).update(profileData);
    } catch (e) {
      throw Exception('Erreur mise à jour profil: $e');
    }
  }
}