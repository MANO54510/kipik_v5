// lib/services/inspiration/firebase_inspiration_service.dart
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'inspiration_service.dart';

class FirebaseInspirationService extends InspirationService {
  static FirebaseInspirationService? _instance;
  static FirebaseInspirationService get instance => _instance ??= FirebaseInspirationService._();
  FirebaseInspirationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getInspirations({
    String? style,
    String? category,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('inspirations');

      if (style != null) {
        query = query.where('style', isEqualTo: style);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      query = query
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération inspirations: $e');
    }
  }

  Future<void> addInspiration({
    required String title,
    required String imageUrl,
    required String style,
    required String category,
    String? description,
    List<String>? tags,
  }) async {
    try {
      await _firestore.collection('inspirations').add({
        'title': title,
        'imageUrl': imageUrl,
        'style': style,
        'category': category,
        'description': description ?? '',
        'tags': tags ?? [],
        'isPublic': true,
        'likes': 0,
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur ajout inspiration: $e');
    }
  }
}