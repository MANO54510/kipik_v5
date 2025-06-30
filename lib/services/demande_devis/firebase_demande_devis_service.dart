// lib/services/demande_devis/firebase_demande_devis_service.dart
// ========================================

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../photo/firebase_photo_service.dart';
import '../auth/auth_service.dart';
import 'demande_devis_service.dart';

class FirebaseDemandeDevisService extends DemandeDevisService {
  static FirebaseDemandeDevisService? _instance;
  static FirebaseDemandeDevisService get instance => _instance ??= FirebaseDemandeDevisService._();
  FirebaseDemandeDevisService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebasePhotoService _photoService = FirebasePhotoService.instance;

  @override
  Future<String?> uploadImage(File file, String path) async {
    try {
      return await _photoService.uploadImage(file, 'demandes_devis/$path');
    } catch (e) {
      throw Exception('Erreur upload image devis: $e');
    }
  }

  @override
  Future<void> createDemandeDevis(Map<String, dynamic> data) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final demandeData = {
        ...data,
        'clientId': currentUser.uid,
        'clientEmail': currentUser.email,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('demandes_devis').add(demandeData);
    } catch (e) {
      throw Exception('Erreur création demande devis: $e');
    }
  }
}