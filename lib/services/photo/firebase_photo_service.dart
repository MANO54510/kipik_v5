// lib/services/photo/firebase_photo_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../auth/secure_auth_service.dart'; // ✅ MIGRATION
import '../../models/user_role.dart'; // ✅ MIGRATION

class FirebasePhotoService {
  static FirebasePhotoService? _instance;
  static FirebasePhotoService get instance => _instance ??= FirebasePhotoService._();
  FirebasePhotoService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// ✅ MIGRATION: Getters sécurisés
  String? get _currentUserId => SecureAuthService.instance.currentUserId;
  UserRole? get _currentUserRole => SecureAuthService.instance.currentUserRole;
  dynamic get _currentUser => SecureAuthService.instance.currentUser;

  /// ✅ SÉCURITÉ: Vérification d'authentification obligatoire
  void _ensureAuthenticated() {
    if (_currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }
  }

  /// ✅ MIGRATION: Upload une image vers Firebase Storage avec sécurité renforcée
  Future<String> uploadImage(File file, String basePath) async {
    try {
      _ensureAuthenticated(); // ✅ Vérification obligatoire

      // Vérifier que le fichier existe
      if (!await file.exists()) {
        throw Exception('Le fichier n\'existe pas');
      }

      // Vérifier la sécurité de l'image
      final isSafe = await checkImageSafety(file);
      if (!isSafe) {
        throw Exception('L\'image ne respecte pas les critères de sécurité');
      }

      // ✅ SÉCURITÉ: Créer un chemin sécurisé avec l'ID utilisateur
      final userPath = '$basePath/$_currentUserId';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final fullPath = '$userPath/$fileName';

      // Optimiser l'image avant upload
      final optimizedFile = await _optimizeImage(file);
      
      // Créer une référence unique
      final ref = _storage.ref().child(fullPath);
      
      // ✅ MIGRATION: Métadonnées avec SecureAuthService
      final metadata = SettableMetadata(
        contentType: _getContentType(file.path),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': path.basename(file.path),
          'uploadedBy': _currentUserId!, // ✅ MIGRATION
          'userRole': _currentUserRole?.name ?? 'unknown',
          'fileSize': (await file.length()).toString(),
        },
      );

      // Upload du fichier
      final uploadTask = ref.putData(optimizedFile, metadata);
      
      // Monitoring du progrès
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Attendre la fin de l'upload
      final snapshot = await uploadTask;
      
      // Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Image uploadée: $fileName (${(await file.length() / 1024).toStringAsFixed(1)} KB)');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ Erreur Firebase Storage: ${e.message}');
      throw Exception('Erreur Firebase Storage: ${e.message}');
    } catch (e) {
      print('❌ Erreur upload: $e');
      throw Exception('Erreur lors de l\'upload: $e');
    }
  }

  /// ✅ AMÉLIORÉ: Vérifier la sécurité et la validité d'une image
  Future<bool> checkImageSafety(File file) async {
    try {
      // Vérifications basiques
      if (!await _isValidImageFile(file)) {
        print('❌ Fichier image invalide');
        return false;
      }

      // Vérifier la taille du fichier (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        print('❌ Fichier trop volumineux: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB');
        throw Exception('Le fichier est trop volumineux (max 10MB)');
      }

      // Vérifier les dimensions de l'image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        print('❌ Impossible de décoder l\'image');
        return false;
      }

      // Vérifier les dimensions maximales (4000x4000)
      if (image.width > 4000 || image.height > 4000) {
        print('❌ Image trop grande: ${image.width}x${image.height}');
        throw Exception('L\'image est trop grande (max 4000x4000 pixels)');
      }

      // Vérifier les dimensions minimales (100x100)
      if (image.width < 100 || image.height < 100) {
        print('❌ Image trop petite: ${image.width}x${image.height}');
        throw Exception('L\'image est trop petite (min 100x100 pixels)');
      }

      // ✅ SÉCURITÉ: Vérifier le ratio d'aspect pour éviter les images étranges
      final aspectRatio = image.width / image.height;
      if (aspectRatio > 3.0 || aspectRatio < 0.33) {
        print('❌ Ratio d\'aspect non autorisé: ${aspectRatio.toStringAsFixed(2)}');
        throw Exception('Format d\'image non autorisé (ratio trop extrême)');
      }

      print('✅ Image validée: ${image.width}x${image.height}, ${(fileSize / 1024).toStringAsFixed(1)} KB');
      return true;
    } catch (e) {
      print('❌ Erreur vérification sécurité: $e');
      return false;
    }
  }

  /// ✅ MIGRATION: Upload multiple images en parallèle avec sécurité
  Future<List<String>> uploadMultipleImages(
    List<File> files,
    String basePath, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      _ensureAuthenticated(); // ✅ Vérification obligatoire

      if (files.isEmpty) {
        throw Exception('Aucun fichier à uploader');
      }

      // ✅ SÉCURITÉ: Limiter le nombre de fichiers simultanés
      const maxConcurrentUploads = 3;
      if (files.length > maxConcurrentUploads) {
        // Upload séquentiel par petits lots
        final results = <String>[];
        for (int i = 0; i < files.length; i += maxConcurrentUploads) {
          final batch = files.skip(i).take(maxConcurrentUploads).toList();
          final batchResults = await Future.wait(
            batch.map((file) => uploadImage(file, basePath)),
          );
          results.addAll(batchResults);
          onProgress?.call(i + batch.length, files.length);
        }
        return results;
      } else {
        // Upload parallèle pour petites quantités
        final results = <String>[];
        for (int i = 0; i < files.length; i++) {
          onProgress?.call(i, files.length);
          final url = await uploadImage(files[i], basePath);
          results.add(url);
        }
        onProgress?.call(files.length, files.length);
        return results;
      }
    } catch (e) {
      print('❌ Erreur upload multiple: $e');
      throw Exception('Erreur lors de l\'upload multiple: $e');
    }
  }

  /// ✅ MIGRATION: Créer une thumbnail avec sécurité
  Future<String> createThumbnail(
    File file, 
    String basePath, {
    int size = 300,
    int quality = 80,
  }) async {
    try {
      _ensureAuthenticated(); // ✅ Vérification obligatoire

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Impossible de décoder l\'image');
      }

      // Créer une thumbnail carrée
      final thumbnail = img.copyResize(
        image, 
        width: size, 
        height: size,
        interpolation: img.Interpolation.linear,
      );
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: quality);

      // ✅ SÉCURITÉ: Chemin sécurisé pour la thumbnail
      final userPath = '$basePath/$_currentUserId/thumbnails';
      final fileName = 'thumb_${size}x${size}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$userPath/$fileName');
      
      // ✅ MIGRATION: Métadonnées avec SecureAuthService
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'type': 'thumbnail',
          'size': '${size}x$size',
          'quality': quality.toString(),
          'createdAt': DateTime.now().toIso8601String(),
          'uploadedBy': _currentUserId!,
        },
      );
      
      final uploadTask = ref.putData(Uint8List.fromList(thumbnailBytes), metadata);
      final snapshot = await uploadTask;
      
      final url = await snapshot.ref.getDownloadURL();
      print('✅ Thumbnail créée: ${size}x$size');
      return url;
    } catch (e) {
      print('❌ Erreur création thumbnail: $e');
      throw Exception('Erreur lors de la création de la thumbnail: $e');
    }
  }

  /// ✅ MIGRATION: Supprimer une image du storage avec vérification de propriété
  Future<void> deleteImage(String imageUrl) async {
    try {
      _ensureAuthenticated(); // ✅ Vérification obligatoire

      final ref = _storage.refFromURL(imageUrl);
      
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur peut supprimer cette image
      final metadata = await ref.getMetadata();
      final uploadedBy = metadata.customMetadata?['uploadedBy'];
      
      if (uploadedBy != _currentUserId && _currentUserRole != UserRole.admin) {
        throw Exception('Vous ne pouvez supprimer que vos propres images');
      }

      await ref.delete();
      print('✅ Image supprimée: ${ref.name}');
    } catch (e) {
      print('❌ Erreur suppression image: $e');
      // Ne pas throw pour éviter de bloquer l'app si l'image n'existe plus
    }
  }

  /// ✅ MIGRATION: Supprimer plusieurs images avec vérifications
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    try {
      _ensureAuthenticated();
      
      for (final url in imageUrls) {
        await deleteImage(url);
      }
      print('✅ ${imageUrls.length} images supprimées');
    } catch (e) {
      print('❌ Erreur suppression multiple: $e');
    }
  }

  /// ✅ MIGRATION: Obtenir les images de l'utilisateur actuel
  Future<List<String>> getUserImages(String basePath) async {
    try {
      _ensureAuthenticated();

      final userPath = '$basePath/$_currentUserId';
      final ref = _storage.ref().child(userPath);
      final listResult = await ref.listAll();
      
      final urls = <String>[];
      for (final item in listResult.items) {
        try {
          final url = await item.getDownloadURL();
          urls.add(url);
        } catch (e) {
          print('❌ Erreur récupération URL pour ${item.name}: $e');
        }
      }
      
      print('✅ ${urls.length} images récupérées pour l\'utilisateur');
      return urls;
    } catch (e) {
      print('❌ Erreur récupération images utilisateur: $e');
      throw Exception('Erreur lors de la récupération des images: $e');
    }
  }

  /// ✅ NOUVEAU: Obtenir les statistiques d'utilisation pour l'utilisateur actuel
  Future<Map<String, dynamic>> getUserStorageStats() async {
    try {
      _ensureAuthenticated();

      final userRef = _storage.ref().child('shops_photos/$_currentUserId');
      final listResult = await userRef.listAll();
      
      int totalFiles = 0;
      int totalSize = 0;
      
      for (final item in listResult.items) {
        try {
          final metadata = await item.getMetadata();
          totalFiles++;
          totalSize += metadata.size ?? 0;
        } catch (e) {
          totalFiles++; // Compter même si pas de métadonnées
        }
      }
      
      final stats = {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'userId': _currentUserId,
      };

      print('✅ Stats utilisateur: $totalFiles fichiers, ${stats['totalSizeMB']} MB');
      return stats;
    } catch (e) {
      print('❌ Erreur stats utilisateur: $e');
      throw Exception('Erreur récupération statistiques: $e');
    }
  }

  /// ✅ MIGRATION: Optimise une image pour réduire sa taille
  Future<Uint8List> _optimizeImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        print('⚠️ Impossible d\'optimiser, utilisation fichier original');
        return await file.readAsBytes();
      }

      // Redimensionner si trop grande (optimisation pour le web)
      img.Image resizedImage = image;
      const maxDimension = 1920;
      
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          resizedImage = img.copyResize(
            image,
            width: maxDimension,
            interpolation: img.Interpolation.linear,
          );
        } else {
          resizedImage = img.copyResize(
            image,
            height: maxDimension,
            interpolation: img.Interpolation.linear,
          );
        }
        print('✅ Image redimensionnée: ${image.width}x${image.height} → ${resizedImage.width}x${resizedImage.height}');
      }

      // Compresser l'image (qualité adaptée à la taille)
      int quality = 85;
      if (resizedImage.width > 1000) quality = 80;
      if (resizedImage.width > 1500) quality = 75;

      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      
      final originalSize = bytes.length;
      final optimizedSize = compressedBytes.length;
      final reduction = ((originalSize - optimizedSize) / originalSize * 100);
      
      print('✅ Image optimisée: ${(originalSize / 1024).toStringAsFixed(1)} KB → ${(optimizedSize / 1024).toStringAsFixed(1)} KB (-${reduction.toStringAsFixed(1)}%)');
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      print('⚠️ Erreur optimisation, utilisation fichier original: $e');
      return await file.readAsBytes();
    }
  }

  /// ✅ AMÉLIORÉ: Vérifie si le fichier est une image valide
  Future<bool> _isValidImageFile(File file) async {
    try {
      final extension = path.extension(file.path).toLowerCase();
      const validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      
      if (!validExtensions.contains(extension)) {
        print('❌ Extension non autorisée: $extension');
        return false;
      }

      // Essayer de décoder l'image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      final isValid = image != null;
      if (!isValid) {
        print('❌ Impossible de décoder l\'image');
      }
      
      return isValid;
    } catch (e) {
      print('❌ Erreur validation image: $e');
      return false;
    }
  }

  /// Détermine le type MIME en fonction de l'extension
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  /// ✅ NOUVEAU: Nettoyer les anciennes images de l'utilisateur
  Future<void> cleanupUserOldFiles(int daysOld) async {
    try {
      _ensureAuthenticated();

      final userRef = _storage.ref().child('shops_photos/$_currentUserId');
      final listResult = await userRef.listAll();
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      int deletedCount = 0;
      
      for (final item in listResult.items) {
        try {
          final metadata = await item.getMetadata();
          final uploadTime = metadata.timeCreated;
          
          if (uploadTime != null && uploadTime.isBefore(cutoffDate)) {
            await item.delete();
            deletedCount++;
            print('✅ Ancien fichier supprimé: ${item.name}');
          }
        } catch (e) {
          print('❌ Erreur suppression ${item.name}: $e');
        }
      }
      
      print('✅ Nettoyage terminé: $deletedCount fichiers supprimés');
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
      throw Exception('Erreur nettoyage: $e');
    }
  }

  /// ✅ NOUVEAU: Méthode de diagnostic pour debug
  Future<void> debugPhotoService() async {
    print('🔍 DIAGNOSTIC FirebasePhotoService:');
    
    try {
      print('  - User ID: ${_currentUserId ?? 'Non connecté'}');
      print('  - User Role: ${_currentUserRole?.name ?? 'Aucun'}');
      
      if (_currentUserId != null) {
        final stats = await getUserStorageStats();
        print('  - Photos utilisateur: ${stats['totalFiles']}');
        print('  - Espace utilisé: ${stats['totalSizeMB']} MB');
        
        final images = await getUserImages('shops_photos');
        print('  - URLs récupérées: ${images.length}');
      }
    } catch (e) {
      print('  - Erreur: $e');
    }
  }
}