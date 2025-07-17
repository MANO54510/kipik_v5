// lib/services/demande_devis/firebase_demande_devis_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/core/firestore_helper.dart';

class FirebaseDemandeDevisService {
  static FirebaseDemandeDevisService? _instance;
  static FirebaseDemandeDevisService get instance =>
      _instance ??= FirebaseDemandeDevisService._();
  FirebaseDemandeDevisService._();

  final FirebaseFirestore _firestore = FirestoreHelper.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ✅ SERVICE SÉCURISÉ CENTRALISÉ
  SecureAuthService get _authService => SecureAuthService.instance;

  // Getters sécurisés
  String? get _currentUserId => _authService.currentUserId;
  UserRole? get _currentUserRole => _authService.currentUserRole;
  dynamic get _currentUser => _authService.currentUser;

  /// ✅ VÉRIFICATION D'AUTHENTIFICATION OBLIGATOIRE
  void _ensureAuthenticated() {
    if (_currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }
  }

  /// ✅ UPLOAD D'IMAGE SÉCURISÉ
  Future<String?> uploadImage(File file, String storagePath) async {
    try {
      _ensureAuthenticated();

      // Validation du fichier
      if (!file.existsSync()) {
        throw Exception('Fichier inexistant');
      }

      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Fichier trop volumineux (max 10MB)');
      }

      // Validation du type de fichier
      final extension = path.extension(file.path).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.pdf'];
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Type de fichier non autorisé');
      }

      // Chemin sécurisé avec userId
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

  /// ✅ UPLOAD MULTIPLE OPTIMISÉ
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

  /// ✅ CRÉATION DE DEMANDE DE DEVIS AVEC SÉCURITÉ
  Future<String> createDemandeDevis(Map<String, dynamic> data) async {
    try {
      _ensureAuthenticated();

      // Validation des données obligatoires
      if (data['description'] == null || data['description'].toString().trim().isEmpty) {
        throw Exception('Description du projet requise');
      }

      if (data['zones'] == null || (data['zones'] as List).isEmpty) {
        throw Exception('Au moins une zone corporelle doit être sélectionnée');
      }

      // ✅ DONNÉES SÉCURISÉES DE LA DEMANDE
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

        // ✅ DONNÉES FLASH SI APPLICABLE
        'isFlashBooking': data['isFlashBooking'] ?? false,
        'flashData': data['flashData'],
        'targetTattooerId': data['targetTattooerId'],
        'targetTatoueurName': data['targetTatoueurName'],
        'requestType': data['requestType'] ?? 'custom_design',
        'isFlashMinute': data['isFlashMinute'] ?? false,
        'flashMinuteDiscount': data['flashMinuteDiscount'],
        'urgentUntil': data['urgentUntil'],

        // Données client enrichies
        'clientProfile': data['clientProfile'],
        'estimatedBudget': data['estimatedBudget'],
        'urgency': data['urgency'] ?? 'normal',
        'preferredStyle': data['preferredStyle'],
        'colorPreference': data['colorPreference'],

        // Contraintes application
        'acceptedTerms': data['acceptedTerms'] ?? false,
        'agreeToAppOnlyContact': data['agreeToAppOnlyContact'] ?? false,
        'mustUseAppForBooking': data['mustUseAppForBooking'] ?? true,
        'commissionRate': data['commissionRate'] ?? 0.01,

        // Métadonnées système
        'status': 'pending',
        'priority': data['isFlashMinute'] == true ? 'urgent' : 'normal',
        'source': 'mobile_app',
        'version': '2.0',
        'complexity': data['complexity'] ?? 'medium',

        // Sécurité et traçabilité
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': _currentUserId,

        // Métadonnées pour matching
        'totalImages': (data['fichiersReferenceUrls'] as List? ?? []).length + 
                      (data['imagesGenerees'] as List? ?? []).length,
        'hasPhotoEmplacement': data['photoEmplacementUrl'] != null,
        'zonesCount': (data['zones'] as List).length,
        'descriptionLength': data['description'].toString().trim().length,
        'submissionTimestamp': DateTime.now().toIso8601String(),
      };

      // ✅ CRÉATION AVEC ID GÉNÉRÉ
      final docRef = await _firestore.collection('demandes_devis').add(demandeData);

      // ✅ LOG DE TRAÇABILITÉ
      await _firestore.collection('devis_logs').add({
        'action': 'demande_created',
        'demandeId': docRef.id,
        'clientId': _currentUserId,
        'requestType': data['requestType'] ?? 'custom_design',
        'isFlashBooking': data['isFlashBooking'] ?? false,
        'isFlashMinute': data['isFlashMinute'] ?? false,
        'targetTattooerId': data['targetTattooerId'],
        'zonesCount': (data['zones'] as List).length,
        'hasImages': (data['fichiersReferenceUrls'] as List? ?? []).isNotEmpty,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ Demande de devis créée - ID: ${docRef.id}, Type: ${data['requestType'] ?? 'custom'}');
      return docRef.id;
      
    } catch (e) {
      print('❌ Erreur création demande devis: $e');
      rethrow;
    }
  }

  /// ✅ RÉCUPÉRER LES DEMANDES DE L'UTILISATEUR
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

  /// ✅ STREAM DES DEMANDES EN TEMPS RÉEL
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

  /// ✅ METTRE À JOUR LE STATUT D'UNE DEMANDE
  Future<void> updateDemandeStatus(String demandeId, String newStatus) async {
    try {
      _ensureAuthenticated();

      // Vérifier que la demande appartient à l'utilisateur ou est admin
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

      // Log de traçabilité
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

  /// ✅ SUPPRIMER UNE DEMANDE (si en attente)
  Future<void> deleteDemandeDevis(String demandeId) async {
    try {
      _ensureAuthenticated();

      final demandeDoc = await _firestore.collection('demandes_devis').doc(demandeId).get();

      if (!demandeDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final demandeData = demandeDoc.data()!;

      // Vérifications de sécurité
      if (demandeData['clientId'] != _currentUserId && _currentUserRole != UserRole.admin) {
        throw Exception('Permission refusée');
      }

      if (demandeData['status'] != 'pending') {
        throw Exception('Impossible de supprimer une demande déjà traitée');
      }

      // Supprimer les fichiers associés
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

      // Supprimer la demande
      await _firestore.collection('demandes_devis').doc(demandeId).delete();

      // Log de traçabilité
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

  /// ✅ STATISTIQUES DES DEMANDES
  Future<Map<String, dynamic>> getDemandesStats() async {
    try {
      _ensureAuthenticated();

      final snapshot = await _firestore
          .collection('demandes_devis')
          .where('clientId', isEqualTo: _currentUserId)
          .get();

      final total = snapshot.docs.length;
      int pending = 0, accepted = 0, rejected = 0, completed = 0;
      int flashBookings = 0, flashMinute = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Compter par statut
        switch (data['status']) {
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

        // Compter les réservations flash
        if (data['isFlashBooking'] == true) {
          flashBookings++;
          if (data['isFlashMinute'] == true) {
            flashMinute++;
          }
        }
      }

      return {
        'total': total,
        'pending': pending,
        'accepted': accepted,
        'rejected': rejected,
        'completed': completed,
        'flashBookings': flashBookings,
        'flashMinute': flashMinute,
      };
    } catch (e) {
      print('❌ Erreur stats demandes: $e');
      return {
        'total': 0,
        'pending': 0,
        'accepted': 0,
        'rejected': 0,
        'completed': 0,
        'flashBookings': 0,
        'flashMinute': 0,
      };
    }
  }

  /// ✅ RÉCUPÉRER UNE DEMANDE SPÉCIFIQUE
  Future<Map<String, dynamic>?> getDemandeById(String demandeId) async {
    try {
      _ensureAuthenticated();

      final doc = await _firestore.collection('demandes_devis').doc(demandeId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      // Vérifier les permissions
      final isOwner = data['clientId'] == _currentUserId;
      final isTargetTatoueur = data['targetTattooerId'] == _currentUserId;
      final isAdmin = _currentUserRole == UserRole.admin;

      if (!isOwner && !isTargetTatoueur && !isAdmin) {
        throw Exception('Permission refusée');
      }

      return data;
    } catch (e) {
      print('❌ Erreur récupération demande: $e');
      return null;
    }
  }

  /// ✅ UTILITAIRE POUR DÉTERMINER LE TYPE MIME
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

  /// ✅ DIAGNOSTIC DU SERVICE
  Future<void> debugDemandeDevisService() async {
    try {
      print('🔍 Debug FirebaseDemandeDevisService:');
      print('  - Utilisateur connecté: ${_currentUserId != null}');
      print('  - User ID: $_currentUserId');
      print('  - User Role: $_currentUserRole');
      print('  - Firestore: ${_firestore.app.name}');

      if (_currentUserId != null) {
        final stats = await getDemandesStats();
        print('  - Demandes totales: ${stats['total']}');
        print('  - En attente: ${stats['pending']}');
        print('  - Acceptées: ${stats['accepted']}');
        print('  - Flash bookings: ${stats['flashBookings']}');
        print('  - Flash Minute: ${stats['flashMinute']}');
      }

      final connectionOk = await FirestoreHelper.checkConnection();
      print('  - Connexion Firestore: ${connectionOk ? "OK" : "ERREUR"}');
    } catch (e) {
      print('❌ Erreur debug service: $e');
    }
  }
}