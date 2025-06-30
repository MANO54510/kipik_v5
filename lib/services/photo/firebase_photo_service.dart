// lib/services/photo/firebase_photo_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../auth/auth_service.dart';

class FirebasePhotoService {
  static FirebasePhotoService? _instance;
  static FirebasePhotoService get instance => _instance ??= FirebasePhotoService._();
  FirebasePhotoService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload une image vers Firebase Storage
  Future<String> uploadImage(File file, String uploadPath) async {
    try {
      // Vérifier que le fichier existe
      if (!await file.exists()) {
        throw Exception('Le fichier n\'existe pas');
      }

      // Vérifier la sécurité de l'image
      final isSafe = await checkImageSafety(file);
      if (!isSafe) {
        throw Exception('L\'image ne respecte pas les critères de sécurité');
      }

      // Optimiser l'image avant upload
      final optimizedFile = await _optimizeImage(file);
      
      // Créer une référence unique
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child(uploadPath).child(fileName);
      
      // Métadonnées pour l'upload
      final metadata = SettableMetadata(
        contentType: _getContentType(file.path),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': path.basename(file.path),
          'uploadedBy': AuthService.instance.currentUser?.uid ?? 'unknown',
        },
      );

      // Upload du fichier
      final uploadTask = ref.putData(optimizedFile, metadata);
      
      // Monitoring du progrès (optionnel)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Attendre la fin de l'upload
      final snapshot = await uploadTask;
      
      // Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Erreur Firebase Storage: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de l\'upload: $e');
    }
  }

  /// Vérifier la sécurité et la validité d'une image
  Future<bool> checkImageSafety(File file) async {
    try {
      // Vérifications basiques
      if (!await _isValidImageFile(file)) {
        return false;
      }

      // Vérifier la taille du fichier (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Le fichier est trop volumineux (max 10MB)');
      }

      // Vérifier les dimensions de l'image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return false;
      }

      // Vérifier les dimensions maximales (4000x4000)
      if (image.width > 4000 || image.height > 4000) {
        throw Exception('L\'image est trop grande (max 4000x4000 pixels)');
      }

      // Vérifier les dimensions minimales (100x100)
      if (image.width < 100 || image.height < 100) {
        throw Exception('L\'image est trop petite (min 100x100 pixels)');
      }

      // TODO: Intégrer Google Vision API pour la détection de contenu inapproprié
      // Pour l'instant, on fait des vérifications basiques
      
      return true;
    } catch (e) {
      print('Erreur lors de la vérification de sécurité: $e');
      return false;
    }
  }

  /// Upload multiple images en parallèle
  Future<List<String>> uploadMultipleImages(
    List<File> files,
    String uploadPath, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      final results = <String>[];
      
      for (int i = 0; i < files.length; i++) {
        onProgress?.call(i, files.length);
        final url = await uploadImage(files[i], uploadPath);
        results.add(url);
      }
      
      onProgress?.call(files.length, files.length);
      return results;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload multiple: $e');
    }
  }

  /// Créer une thumbnail d'une image
  Future<String> createThumbnail(
    File file, 
    String uploadPath, {
    int size = 300,
    int quality = 80,
  }) async {
    try {
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

      // Upload de la thumbnail
      final fileName = 'thumb_${size}x${size}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(uploadPath).child('thumbnails').child(fileName);
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'type': 'thumbnail',
          'size': '${size}x$size',
          'quality': quality.toString(),
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = ref.putData(Uint8List.fromList(thumbnailBytes), metadata);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur lors de la création de la thumbnail: $e');
    }
  }

  /// Créer plusieurs tailles de thumbnails
  Future<Map<String, String>> createMultipleThumbnails(
    File file,
    String uploadPath, {
    List<int> sizes = const [150, 300, 600],
  }) async {
    try {
      final results = <String, String>{};
      
      for (final size in sizes) {
        final thumbnailUrl = await createThumbnail(file, uploadPath, size: size);
        results['thumb_$size'] = thumbnailUrl;
      }
      
      return results;
    } catch (e) {
      throw Exception('Erreur lors de la création des thumbnails: $e');
    }
  }

  /// Supprimer une image du storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Erreur lors de la suppression de l\'image: $e');
      // Ne pas throw pour éviter de bloquer l'app si l'image n'existe plus
    }
  }

  /// Supprimer plusieurs images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    try {
      final deleteFutures = imageUrls.map((url) => deleteImage(url));
      await Future.wait(deleteFutures);
    } catch (e) {
      print('Erreur lors de la suppression multiple: $e');
    }
  }

  /// Obtenir les métadonnées d'une image
  Future<FullMetadata?> getImageMetadata(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('Erreur lors de la récupération des métadonnées: $e');
      return null;
    }
  }

  /// Obtenir la taille d'une image en bytes
  Future<int?> getImageSize(String imageUrl) async {
    try {
      final metadata = await getImageMetadata(imageUrl);
      return metadata?.size;
    } catch (e) {
      print('Erreur lors de la récupération de la taille: $e');
      return null;
    }
  }

  /// Copier une image vers un nouveau chemin
  Future<String> copyImage(String sourceUrl, String newPath) async {
    try {
      final sourceRef = _storage.refFromURL(sourceUrl);
      
      // Télécharger l'image source
      final data = await sourceRef.getData();
      if (data == null) throw Exception('Impossible de télécharger l\'image source');
      
      // Créer une nouvelle référence
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_copy.jpg';
      final newRef = _storage.ref().child(newPath).child(fileName);
      
      // Upload vers le nouveau chemin
      final uploadTask = newRef.putData(data);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur lors de la copie: $e');
    }
  }

  /// Redimensionner une image existante
  Future<String> resizeExistingImage(
    String imageUrl,
    String uploadPath, {
    int? width,
    int? height,
    int quality = 85,
  }) async {
    try {
      final sourceRef = _storage.refFromURL(imageUrl);
      final data = await sourceRef.getData();
      
      if (data == null) throw Exception('Impossible de télécharger l\'image');
      
      final image = img.decodeImage(data);
      if (image == null) throw Exception('Impossible de décoder l\'image');
      
      // Redimensionner
      final resized = img.copyResize(image, width: width, height: height);
      final resizedBytes = img.encodeJpg(resized, quality: quality);
      
      // Upload de l'image redimensionnée
      final fileName = 'resized_${width ?? 'auto'}x${height ?? 'auto'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(uploadPath).child(fileName);
      
      final uploadTask = ref.putData(
        Uint8List.fromList(resizedBytes),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur lors du redimensionnement: $e');
    }
  }

  /// Obtenir la liste des images dans un dossier
  Future<List<String>> listImagesInFolder(String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final listResult = await ref.listAll();
      
      final urls = <String>[];
      for (final item in listResult.items) {
        try {
          final url = await item.getDownloadURL();
          urls.add(url);
        } catch (e) {
          print('Erreur récupération URL pour ${item.name}: $e');
        }
      }
      
      return urls;
    } catch (e) {
      throw Exception('Erreur lors de la liste des images: $e');
    }
  }

  /// Compresser une image avec différents niveaux de qualité
  Future<Map<String, String>> compressImageMultipleLevels(
    File file,
    String uploadPath, {
    List<int> qualities = const [60, 80, 95],
  }) async {
    try {
      final results = <String, String>{};
      
      for (final quality in qualities) {
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        
        if (image == null) continue;
        
        final compressedBytes = img.encodeJpg(image, quality: quality);
        final fileName = 'compressed_q${quality}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child(uploadPath).child(fileName);
        
        final uploadTask = ref.putData(
          Uint8List.fromList(compressedBytes),
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'quality': quality.toString()},
          ),
        );
        
        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        results['quality_$quality'] = url;
      }
      
      return results;
    } catch (e) {
      throw Exception('Erreur lors de la compression multiple: $e');
    }
  }

  /// Méthodes utilitaires privées

  /// Optimise une image pour réduire sa taille
  Future<Uint8List> _optimizeImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Impossible de décoder l\'image');
      }

      // Redimensionner si trop grande
      img.Image resizedImage = image;
      if (image.width > 1920 || image.height > 1920) {
        resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1920 : null,
          interpolation: img.Interpolation.linear,
        );
      }

      // Compresser l'image (qualité 85%)
      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      // Si l'optimisation échoue, utiliser le fichier original
      print('Erreur optimisation, utilisation fichier original: $e');
      return await file.readAsBytes();
    }
  }

  /// Vérifie si le fichier est une image valide
  Future<bool> _isValidImageFile(File file) async {
    try {
      final extension = path.extension(file.path).toLowerCase();
      const validExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
      
      if (!validExtensions.contains(extension)) {
        return false;
      }

      // Essayer de décoder l'image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      return image != null;
    } catch (e) {
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

  /// Obtenir les statistiques d'utilisation du storage
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final root = _storage.ref();
      final listResult = await root.listAll();
      
      int totalFiles = 0;
      int totalSize = 0;
      
      // Parcourir récursivement tous les fichiers
      await _countFilesRecursively(root, (count, size) {
        totalFiles += count;
        totalSize += size;
      });
      
      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      throw Exception('Erreur récupération statistiques: $e');
    }
  }

  /// Méthode récursive pour compter les fichiers
  Future<void> _countFilesRecursively(
    Reference ref,
    Function(int count, int size) callback,
  ) async {
    try {
      final listResult = await ref.listAll();
      
      // Compter les fichiers dans le dossier actuel
      for (final item in listResult.items) {
        try {
          final metadata = await item.getMetadata();
          callback(1, metadata.size ?? 0);
        } catch (e) {
          callback(1, 0); // Fichier sans métadonnées
        }
      }
      
      // Parcourir les sous-dossiers
      for (final prefix in listResult.prefixes) {
        await _countFilesRecursively(prefix, callback);
      }
    } catch (e) {
      print('Erreur parcours dossier ${ref.fullPath}: $e');
    }
  }

  /// Nettoyer les anciens fichiers (plus de X jours)
  Future<void> cleanupOldFiles(String folderPath, int daysOld) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final listResult = await ref.listAll();
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      for (final item in listResult.items) {
        try {
          final metadata = await item.getMetadata();
          final uploadTime = metadata.timeCreated;
          
          if (uploadTime != null && uploadTime.isBefore(cutoffDate)) {
            await item.delete();
            print('Fichier supprimé: ${item.name}');
          }
        } catch (e) {
          print('Erreur suppression ${item.name}: $e');
        }
      }
    } catch (e) {
      throw Exception('Erreur nettoyage: $e');
    }
  }
}