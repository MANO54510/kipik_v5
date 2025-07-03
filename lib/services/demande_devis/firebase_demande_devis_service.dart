// lib/services/demande_devis/firebase_demande_devis_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../photo/firebase_photo_service.dart';
import '../auth/secure_auth_service.dart'; // ✅ MIGRATION
import '../auth/captcha_manager.dart'; // ✅ SÉCURITÉ
import '../../models/user_role.dart'; // ✅ MIGRATION
import 'demande_devis_service.dart';

class FirebaseDemandeDevisService extends DemandeDevisService {
  static FirebaseDemandeDevisService? _instance;
  static FirebaseDemandeDevisService get instance => _instance ??= FirebaseDemandeDevisService._();
  FirebaseDemandeDevisService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebasePhotoService _photoService = FirebasePhotoService.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ✅ MIGRATION: Service sécurisé centralisé
  SecureAuthService get _authService => SecureAuthService.instance;

  // Getters sécurisés
  String? get _currentUserId => _authService.currentUserId;
  UserRole? get _currentUserRole => _authService.currentUserRole;
  dynamic get _currentUser => _authService.currentUser;

  /// ✅ Vérification d'authentification obligatoire
  void _ensureAuthenticated() {
    if (_currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }
  }

  @override
  Future<String?> uploadImage(File file, String storagePath) async {
    try {
      _ensureAuthenticated();

      // ✅ Validation du fichier
      if (!file.existsSync()) {
        throw Exception('Fichier inexistant');
      }

      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB max
        throw Exception('Fichier trop volumineux (max 10MB)');
      }

      // ✅ Validation du type de fichier
      final extension = path.extension(file.path).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.pdf'];
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Type de fichier non autorisé');
      }

      // ✅ Chemin sécurisé avec userId
      final securePath = 'demandes_devis/$_currentUserId/$storagePath';
      
      print('📤 Upload devis - Fichier: ${file.path}, Taille: ${(fileSize / 1024).round()}KB');

      // Upload vers Firebase Storage
      final ref = _storage.ref().child(securePath);
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'uploadedBy': _currentUserId!,
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': path.basename(file.path),
          'fileSize': fileSize.toString(),
        },
      );

      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Upload devis réussi - URL: ${downloadUrl.substring(0, 50)}...');
      return downloadUrl;

    } catch (e) {
      print('❌ Erreur upload image devis: $e');
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Upload multiple optimisé
  Future<List<String>> uploadMultipleImages(List<File> files, String basePath) async {
    try {
      _ensureAuthenticated();

      if (files.length > 5) {
        throw Exception('Maximum 5 fichiers autorisés');
      }

      final List<String> urls = [];
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final extension = path.extension(file.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i$extension';
        final url = await uploadImage(file, '$basePath/$fileName');
        if (url != null) {
          urls.add(url);
        }
      }

      return urls;
    } catch (e) {
      print('❌ Erreur upload multiple: $e');
      rethrow;
    }
  }

  @override
  Future<void> createDemandeDevis(Map<String, dynamic> data) async {
    try {
      _ensureAuthenticated();

      // ✅ SÉCURITÉ: Validation reCAPTCHA pour demandes de devis
      final captchaResult = await CaptchaManager.instance.validateUserAction(
        action: 'booking', // Utilise le score de réservation (0.6)
      );

      if (!captchaResult.isValid) {
        throw Exception('Validation de sécurité échouée - Score: ${captchaResult.score.toStringAsFixed(2)}');
      }

      // ✅ Validation des données obligatoires
      if (data['description'] == null || data['description'].toString().trim().isEmpty) {
        throw Exception('Description du projet requise');
      }

      if (data['zones'] == null || (data['zones'] as List).isEmpty) {
        throw Exception('Au moins une zone corporelle doit être sélectionnée');
      }

      // ✅ Données sécurisées de la demande
      final demandeData = {
        // Données utilisateur (sécurisées)
        'clientId': _currentUserId!,
        'clientEmail': _currentUser?['email'] ?? '',
        'clientName': _currentUser?['displayName'] ?? _currentUser?['name'] ?? 'Client',
        
        // Données du projet (validées)
        'description': data['description'].toString().trim(),
        'taille': data['taille'] ?? '10x10 cm',
        'zones': data['zones'] as List<String>,
        
        // URLs des fichiers (sécurisées)
        'zoneImageUrl': data['zoneImageUrl'],
        'photoEmplacementUrl': data['photoEmplacementUrl'],
        'fichiersReferenceUrls': data['fichiersReferenceUrls'] ?? [],
        'imagesGenerees': data['imagesGenerees'] ?? [],
        
        // Métadonnées système
        'status': 'pending',
        'priority': 'normal',
        'source': 'mobile_app',
        'version': '2.0',
        
        // Sécurité et traçabilité
        'captchaScore': captchaResult.score,
        'captchaAction': captchaResult.action,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': _currentUserId,
        
        // Données additionnelles pour matching
        'estimatedBudget': data['estimatedBudget'],
        'urgency': data['urgency'] ?? 'normal',
        'preferredStyle': data['preferredStyle'],
        'colorPreference': data['colorPreference'],
      };

      // ✅ Création de la demande avec ID généré
      final docRef = await _firestore.collection('demandes_devis').add(demandeData);
      
      // ✅ Log de traçabilité
      await _firestore.collection('devis_logs').add({
        'action': 'demande_created',
        'demandeId': docRef.id,
        'clientId': _currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'captchaScore': captchaResult.score,
        'zonesCount': (data['zones'] as List).length,
        'hasImages': (data['fichiersReferenceUrls'] as List? ?? []).isNotEmpty,
      });

      print('✅ Demande de devis créée - ID: ${docRef.id}, Score: ${captchaResult.score.toStringAsFixed(2)}');

    } catch (e) {
      print('❌ Erreur création demande devis: $e');
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Récupérer les demandes de l'utilisateur
  Future<List<Map<String, dynamic>>> getMesDemandesDevis() async {
    try {
      _ensureAuthenticated();

      final snapshot = await _firestore
          .collection('demandes_devis')
          .where('clientId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

    } catch (e) {
      print('❌ Erreur récupération demandes: $e');
      return [];
    }
  }

  /// ✅ NOUVEAU: Stream des demandes en temps réel
  Stream<List<Map<String, dynamic>>> streamMesDemandesDevis() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('demandes_devis')
        .where('clientId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// ✅ NOUVEAU: Mettre à jour le statut d'une demande
  Future<void> updateDemandeStatus(String demandeId, String newStatus) async {
    try {
      _ensureAuthenticated();

      // ✅ Vérifier que la demande appartient à l'utilisateur ou est admin
      final demandeDoc = await _firestore.collection('demandes_devis').doc(demandeId).get();
      
      if (!demandeDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final demandeData = demandeDoc.data()!;
      final isOwner = demandeData['clientId'] == _currentUserId;
      final isAdmin = _currentUserRole == UserRole.admin;

      if (!isOwner && !isAdmin) {
        throw Exception('Permission refusée');
      }

      await _firestore.collection('demandes_devis').doc(demandeId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _currentUserId,
      });

      // ✅ Log de traçabilité
      await _firestore.collection('devis_logs').add({
        'action': 'status_updated',
        'demandeId': demandeId,
        'oldStatus': demandeData['status'],
        'newStatus': newStatus,
        'updatedBy': _currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('❌ Erreur mise à jour statut: $e');
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Supprimer une demande (si en attente)
  Future<void> deleteDemandeDevis(String demandeId) async {
    try {
      _ensureAuthenticated();

      final demandeDoc = await _firestore.collection('demandes_devis').doc(demandeId).get();
      
      if (!demandeDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final demandeData = demandeDoc.data()!;
      
      // ✅ Vérifications de sécurité
      if (demandeData['clientId'] != _currentUserId && _currentUserRole != UserRole.admin) {
        throw Exception('Permission refusée');
      }

      if (demandeData['status'] != 'pending') {
        throw Exception('Impossible de supprimer une demande déjà traitée');
      }

      // ✅ Supprimer les fichiers associés
      final urls = [
        demandeData['zoneImageUrl'],
        demandeData['photoEmplacementUrl'],
        ...(demandeData['fichiersReferenceUrls'] as List? ?? []),
      ].where((url) => url != null).cast<String>();

      for (final url in urls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          print('⚠️ Impossible de supprimer le fichier: $url');
        }
      }

      // ✅ Supprimer la demande
      await _firestore.collection('demandes_devis').doc(demandeId).delete();

      // ✅ Log de traçabilité
      await _firestore.collection('devis_logs').add({
        'action': 'demande_deleted',
        'demandeId': demandeId,
        'deletedBy': _currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('❌ Erreur suppression demande: $e');
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Obtenir les statistiques des demandes
  Future<Map<String, dynamic>> getDemandesStats() async {
    try {
      _ensureAuthenticated();

      final snapshot = await _firestore
          .collection('demandes_devis')
          .where('clientId', isEqualTo: _currentUserId)
          .get();

      final total = snapshot.docs.length;
      int pending = 0, accepted = 0, rejected = 0, completed = 0;

      for (final doc in snapshot.docs) {
        switch (doc.data()['status']) {
          case 'pending':
            pending++;
            break;
          case 'accepted':
          case 'in_progress':
            accepted++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'completed':
            completed++;
            break;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'accepted': accepted,
        'rejected': rejected,
        'completed': completed,
      };

    } catch (e) {
      print('❌ Erreur stats demandes: $e');
      return {
        'total': 0,
        'pending': 0,
        'accepted': 0,
        'rejected': 0,
        'completed': 0,
      };
    }
  }

  /// ✅ Utilitaire pour déterminer le type MIME
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// ✅ NOUVEAU: Diagnostic du service
  Future<void> debugDemandeDevisService() async {
    try {
      print('🔍 Debug FirebaseDemandeDevisService:');
      print('  - Utilisateur connecté: ${_currentUserId != null}');
      print('  - User ID: $_currentUserId');
      print('  - User Role: $_currentUserRole');
      
      if (_currentUserId != null) {
        final stats = await getDemandesStats();
        print('  - Demandes totales: ${stats['total']}');
        print('  - En attente: ${stats['pending']}');
        print('  - Acceptées: ${stats['accepted']}');
        print('  - Rejetées: ${stats['rejected']}');
        print('  - Terminées: ${stats['completed']}');
      }
    } catch (e) {
      print('❌ Erreur debug service: $e');
    }
  }
}