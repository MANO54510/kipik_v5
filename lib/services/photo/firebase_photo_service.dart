// lib/services/photo/firebase_photo_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../../core/database_manager.dart'; // ✅ AJOUTÉ pour détecter le mode
import '../auth/secure_auth_service.dart';
import '../../models/user_role.dart';

/// Service de gestion des photos unifié (Production + Démo)
/// En mode démo : simule les uploads avec URLs factices et gestion en mémoire
/// En mode production : utilise Firebase Storage réel
class FirebasePhotoService {
  static FirebasePhotoService? _instance;
  static FirebasePhotoService get instance => _instance ??= FirebasePhotoService._();
  FirebasePhotoService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ✅ DONNÉES MOCK POUR LES DÉMOS
  final Map<String, List<String>> _mockUserImages = {};
  final Map<String, Map<String, dynamic>> _mockImageMetadata = {};
  final List<String> _mockImageUrls = [
    'https://picsum.photos/seed/demo1/800/600',
    'https://picsum.photos/seed/demo2/800/600',
    'https://picsum.photos/seed/demo3/800/600',
    'https://picsum.photos/seed/demo4/800/600',
    'https://picsum.photos/seed/demo5/800/600',
    'https://picsum.photos/seed/demo6/800/600',
    'https://picsum.photos/seed/demo7/800/600',
    'https://picsum.photos/seed/demo8/800/600',
  ];

  /// ✅ MÉTHODE PRINCIPALE - Détection automatique du mode
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  /// ✅ Getters sécurisés
  String? get _currentUserId => SecureAuthService.instance.currentUserId;
  UserRole? get _currentUserRole => SecureAuthService.instance.currentUserRole;
  dynamic get _currentUser => SecureAuthService.instance.currentUser;

  /// ✅ SÉCURITÉ: Vérification d'authentification obligatoire
  void _ensureAuthenticated() {
    if (_currentUserId == null) {
      throw Exception(_isDemoMode ? '[DÉMO] Utilisateur non connecté' : 'Utilisateur non connecté');
    }
  }

  /// ✅ UPLOAD IMAGE (mode auto)
  Future<String> uploadImage(File file, String basePath) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Simulation upload image');
      return await _uploadImageMock(file, basePath);
    } else {
      print('🏭 Mode production - Upload image réel');
      return await _uploadImageFirebase(file, basePath);
    }
  }

  /// ✅ FIREBASE - Upload réel
  Future<String> _uploadImageFirebase(File file, String basePath) async {
    try {
      _ensureAuthenticated();

      if (!await file.exists()) {
        throw Exception('Le fichier n\'existe pas');
      }

      final isSafe = await checkImageSafety(file);
      if (!isSafe) {
        throw Exception('L\'image ne respecte pas les critères de sécurité');
      }

      final userPath = '$basePath/$_currentUserId';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final fullPath = '$userPath/$fileName';

      final optimizedFile = await _optimizeImage(file);
      final ref = _storage.ref().child(fullPath);
      
      final metadata = SettableMetadata(
        contentType: _getContentType(file.path),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': path.basename(file.path),
          'uploadedBy': _currentUserId!,
          'userRole': _currentUserRole?.name ?? 'unknown',
          'fileSize': (await file.length()).toString(),
        },
      );

      final uploadTask = ref.putData(optimizedFile, metadata);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Image uploadée Firebase: $fileName (${(await file.length() / 1024).toStringAsFixed(1)} KB)');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ Erreur Firebase Storage: ${e.message}');
      throw Exception('Erreur Firebase Storage: ${e.message}');
    } catch (e) {
      print('❌ Erreur upload Firebase: $e');
      throw Exception('Erreur lors de l\'upload: $e');
    }
  }

  /// ✅ MOCK - Upload factice
  Future<String> _uploadImageMock(File file, String basePath) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simuler upload
    
    _ensureAuthenticated();

    if (!await file.exists()) {
      throw Exception('[DÉMO] Le fichier n\'existe pas');
    }

    final isSafe = await checkImageSafety(file);
    if (!isSafe) {
      throw Exception('[DÉMO] L\'image ne respecte pas les critères de sécurité');
    }

    // Simuler progression d'upload
    for (int i = 0; i <= 100; i += 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      print('Upload progress: $i%');
    }

    // Générer URL factice
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    final mockUrl = _mockImageUrls[Random().nextInt(_mockImageUrls.length)] + '?demo=$fileName';

    // Stocker en mémoire
    if (!_mockUserImages.containsKey(_currentUserId)) {
      _mockUserImages[_currentUserId!] = [];
    }
    _mockUserImages[_currentUserId]!.add(mockUrl);

    // Métadonnées factices
    _mockImageMetadata[mockUrl] = {
      'uploadedAt': DateTime.now().toIso8601String(),
      'originalName': path.basename(file.path),
      'uploadedBy': _currentUserId!,
      'userRole': _currentUserRole?.name ?? 'unknown',
      'fileSize': (await file.length()).toString(),
      'basePath': basePath,
      '_source': 'mock',
      '_demoData': true,
    };

    final fileSizeKB = (await file.length() / 1024).toStringAsFixed(1);
    print('✅ Image démo uploadée: $fileName ($fileSizeKB KB) → $mockUrl');
    
    return mockUrl;
  }

  /// ✅ UPLOAD MULTIPLE (mode auto)
  Future<List<String>> uploadMultipleImages(
    List<File> files,
    String basePath, {
    Function(int current, int total)? onProgress,
  }) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Simulation upload multiple');
      return await _uploadMultipleImagesMock(files, basePath, onProgress: onProgress);
    } else {
      print('🏭 Mode production - Upload multiple réel');
      return await _uploadMultipleImagesFirebase(files, basePath, onProgress: onProgress);
    }
  }

  /// ✅ FIREBASE - Upload multiple réel
  Future<List<String>> _uploadMultipleImagesFirebase(
    List<File> files,
    String basePath, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      _ensureAuthenticated();

      if (files.isEmpty) {
        throw Exception('Aucun fichier à uploader');
      }

      const maxConcurrentUploads = 3;
      if (files.length > maxConcurrentUploads) {
        final results = <String>[];
        for (int i = 0; i < files.length; i += maxConcurrentUploads) {
          final batch = files.skip(i).take(maxConcurrentUploads).toList();
          final batchResults = await Future.wait(
            batch.map((file) => _uploadImageFirebase(file, basePath)),
          );
          results.addAll(batchResults);
          onProgress?.call(i + batch.length, files.length);
        }
        return results;
      } else {
        final results = <String>[];
        for (int i = 0; i < files.length; i++) {
          onProgress?.call(i, files.length);
          final url = await _uploadImageFirebase(files[i], basePath);
          results.add(url);
        }
        onProgress?.call(files.length, files.length);
        return results;
      }
    } catch (e) {
      print('❌ Erreur upload multiple Firebase: $e');
      throw Exception('Erreur lors de l\'upload multiple: $e');
    }
  }

  /// ✅ MOCK - Upload multiple factice
  Future<List<String>> _uploadMultipleImagesMock(
    List<File> files,
    String basePath, {
    Function(int current, int total)? onProgress,
  }) async {
    _ensureAuthenticated();

    if (files.isEmpty) {
      throw Exception('[DÉMO] Aucun fichier à uploader');
    }

    final results = <String>[];
    for (int i = 0; i < files.length; i++) {
      onProgress?.call(i, files.length);
      final url = await _uploadImageMock(files[i], basePath);
      results.add(url);
      await Future.delayed(const Duration(milliseconds: 200)); // Espacement pour réalisme
    }
    onProgress?.call(files.length, files.length);
    
    print('✅ Upload multiple démo terminé: ${results.length} images');
    return results;
  }

  /// ✅ CRÉER THUMBNAIL (mode auto)
  Future<String> createThumbnail(
    File file, 
    String basePath, {
    int size = 300,
    int quality = 80,
  }) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Simulation création thumbnail');
      return await _createThumbnailMock(file, basePath, size: size, quality: quality);
    } else {
      print('🏭 Mode production - Création thumbnail réelle');
      return await _createThumbnailFirebase(file, basePath, size: size, quality: quality);
    }
  }

  /// ✅ FIREBASE - Thumbnail réelle
  Future<String> _createThumbnailFirebase(
    File file, 
    String basePath, {
    int size = 300,
    int quality = 80,
  }) async {
    try {
      _ensureAuthenticated();

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Impossible de décoder l\'image');
      }

      final thumbnail = img.copyResize(
        image, 
        width: size, 
        height: size,
        interpolation: img.Interpolation.linear,
      );
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: quality);

      final userPath = '$basePath/$_currentUserId/thumbnails';
      final fileName = 'thumb_${size}x${size}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$userPath/$fileName');
      
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
      print('✅ Thumbnail Firebase créée: ${size}x$size');
      return url;
    } catch (e) {
      print('❌ Erreur création thumbnail Firebase: $e');
      throw Exception('Erreur lors de la création de la thumbnail: $e');
    }
  }

  /// ✅ MOCK - Thumbnail factice
  Future<String> _createThumbnailMock(
    File file, 
    String basePath, {
    int size = 300,
    int quality = 80,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    _ensureAuthenticated();

    // Simuler validation image
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('[DÉMO] Impossible de décoder l\'image');
    }

    // Générer URL thumbnail factice
    final fileName = 'thumb_${size}x${size}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final thumbnailUrl = 'https://picsum.photos/seed/thumb${Random().nextInt(1000)}/$size/$size?demo=$fileName';

    // Stocker métadonnées
    _mockImageMetadata[thumbnailUrl] = {
      'type': 'thumbnail',
      'size': '${size}x$size',
      'quality': quality.toString(),
      'createdAt': DateTime.now().toIso8601String(),
      'uploadedBy': _currentUserId!,
      'basePath': basePath,
      '_source': 'mock',
      '_demoData': true,
    };

    print('✅ Thumbnail démo créée: ${size}x$size → $thumbnailUrl');
    return thumbnailUrl;
  }

  /// ✅ SUPPRIMER IMAGE (mode auto)
  Future<void> deleteImage(String imageUrl) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Simulation suppression image');
      await _deleteImageMock(imageUrl);
    } else {
      print('🏭 Mode production - Suppression image réelle');
      await _deleteImageFirebase(imageUrl);
    }
  }

  /// ✅ FIREBASE - Suppression réelle
  Future<void> _deleteImageFirebase(String imageUrl) async {
    try {
      _ensureAuthenticated();

      final ref = _storage.refFromURL(imageUrl);
      
      final metadata = await ref.getMetadata();
      final uploadedBy = metadata.customMetadata?['uploadedBy'];
      
      if (uploadedBy != _currentUserId && _currentUserRole != UserRole.admin) {
        throw Exception('Vous ne pouvez supprimer que vos propres images');
      }

      await ref.delete();
      print('✅ Image Firebase supprimée: ${ref.name}');
    } catch (e) {
      print('❌ Erreur suppression image Firebase: $e');
    }
  }

  /// ✅ MOCK - Suppression factice
  Future<void> _deleteImageMock(String imageUrl) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    _ensureAuthenticated();

    // Vérifier propriété
    final metadata = _mockImageMetadata[imageUrl];
    if (metadata != null) {
      final uploadedBy = metadata['uploadedBy'];
      if (uploadedBy != _currentUserId && _currentUserRole != UserRole.admin) {
        throw Exception('[DÉMO] Vous ne pouvez supprimer que vos propres images');
      }
    }

    // Supprimer de la mémoire
    _mockUserImages[_currentUserId]?.remove(imageUrl);
    _mockImageMetadata.remove(imageUrl);
    
    print('✅ Image démo supprimée: $imageUrl');
  }

  /// ✅ SUPPRIMER MULTIPLE (mode auto)
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    _ensureAuthenticated();
    
    for (final url in imageUrls) {
      await deleteImage(url);
    }
    print('✅ ${imageUrls.length} images supprimées (${_isDemoMode ? 'démo' : 'production'})');
  }

  /// ✅ OBTENIR IMAGES UTILISATEUR (mode auto)
  Future<List<String>> getUserImages(String basePath) async {
    if (_isDemoMode) {
      return await _getUserImagesMock(basePath);
    } else {
      return await _getUserImagesFirebase(basePath);
    }
  }

  /// ✅ FIREBASE - Images utilisateur réelles
  Future<List<String>> _getUserImagesFirebase(String basePath) async {
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
      
      print('✅ ${urls.length} images Firebase récupérées');
      return urls;
    } catch (e) {
      print('❌ Erreur récupération images Firebase: $e');
      throw Exception('Erreur lors de la récupération des images: $e');
    }
  }

  /// ✅ MOCK - Images utilisateur factices
  Future<List<String>> _getUserImagesMock(String basePath) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _ensureAuthenticated();

    if (!_mockUserImages.containsKey(_currentUserId)) {
      // Générer quelques images de démo pour l'utilisateur
      _initializeMockUserImages();
    }

    final images = _mockUserImages[_currentUserId] ?? [];
    print('✅ ${images.length} images démo récupérées');
    
    return List<String>.from(images);
  }

  /// ✅ INITIALISER IMAGES DÉMO UTILISATEUR
  void _initializeMockUserImages() {
    if (_currentUserId == null) return;

    _mockUserImages[_currentUserId!] = [];
    final imageCount = Random().nextInt(5) + 3; // 3-7 images

    for (int i = 0; i < imageCount; i++) {
      final demoUrl = _mockImageUrls[Random().nextInt(_mockImageUrls.length)] + '?demo=init$i';
      _mockUserImages[_currentUserId!]!.add(demoUrl);
      
      _mockImageMetadata[demoUrl] = {
        'uploadedAt': DateTime.now().subtract(Duration(days: Random().nextInt(30))).toIso8601String(),
        'originalName': 'demo_image_$i.jpg',
        'uploadedBy': _currentUserId!,
        'userRole': _currentUserRole?.name ?? 'tatoueur',
        'fileSize': '${Random().nextInt(500) + 200}000', // 200-700KB
        '_source': 'mock',
        '_demoData': true,
      };
    }

    print('🎭 ${imageCount} images démo initialisées pour l\'utilisateur');
  }

  /// ✅ STATISTIQUES STOCKAGE (mode auto)
  Future<Map<String, dynamic>> getUserStorageStats() async {
    if (_isDemoMode) {
      return await _getUserStorageStatsMock();
    } else {
      return await _getUserStorageStatsFirebase();
    }
  }

  /// ✅ FIREBASE - Stats réelles
  Future<Map<String, dynamic>> _getUserStorageStatsFirebase() async {
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
          totalFiles++;
        }
      }
      
      final stats = {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'userId': _currentUserId,
        '_source': 'firebase',
      };

      print('✅ Stats Firebase: $totalFiles fichiers, ${stats['totalSizeMB']} MB');
      return stats;
    } catch (e) {
      print('❌ Erreur stats Firebase: $e');
      throw Exception('Erreur récupération statistiques: $e');
    }
  }

  /// ✅ MOCK - Stats factices
  Future<Map<String, dynamic>> _getUserStorageStatsMock() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    _ensureAuthenticated();

    if (!_mockUserImages.containsKey(_currentUserId)) {
      _initializeMockUserImages();
    }

    final images = _mockUserImages[_currentUserId] ?? [];
    int totalSize = 0;

    // Calculer taille simulée
    for (final url in images) {
      final metadata = _mockImageMetadata[url];
      if (metadata != null) {
        totalSize += int.tryParse(metadata['fileSize'] ?? '0') ?? 0;
      }
    }

    final stats = {
      'totalFiles': images.length,
      'totalSize': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'userId': _currentUserId,
      '_source': 'mock',
      '_demoData': true,
    };

    print('✅ Stats démo: ${images.length} fichiers, ${stats['totalSizeMB']} MB');
    return stats;
  }

  /// ✅ VÉRIFIER SÉCURITÉ IMAGE (inchangé - fonctionne en mode auto)
  Future<bool> checkImageSafety(File file) async {
    try {
      if (!await _isValidImageFile(file)) {
        print('❌ Fichier image invalide');
        return false;
      }

      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        print('❌ Fichier trop volumineux: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB');
        throw Exception('Le fichier est trop volumineux (max 10MB)');
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        print('❌ Impossible de décoder l\'image');
        return false;
      }

      if (image.width > 4000 || image.height > 4000) {
        print('❌ Image trop grande: ${image.width}x${image.height}');
        throw Exception('L\'image est trop grande (max 4000x4000 pixels)');
      }

      if (image.width < 100 || image.height < 100) {
        print('❌ Image trop petite: ${image.width}x${image.height}');
        throw Exception('L\'image est trop petite (min 100x100 pixels)');
      }

      final aspectRatio = image.width / image.height;
      if (aspectRatio > 3.0 || aspectRatio < 0.33) {
        print('❌ Ratio d\'aspect non autorisé: ${aspectRatio.toStringAsFixed(2)}');
        throw Exception('Format d\'image non autorisé (ratio trop extrême)');
      }

      final prefix = _isDemoMode ? '[DÉMO] ' : '';
      print('✅ ${prefix}Image validée: ${image.width}x${image.height}, ${(fileSize / 1024).toStringAsFixed(1)} KB');
      return true;
    } catch (e) {
      print('❌ Erreur vérification sécurité: $e');
      return false;
    }
  }

  /// ✅ NETTOYAGE ANCIENS FICHIERS (mode auto)
  Future<void> cleanupUserOldFiles(int daysOld) async {
    if (_isDemoMode) {
      await _cleanupUserOldFilesMock(daysOld);
    } else {
      await _cleanupUserOldFilesFirebase(daysOld);
    }
  }

  /// ✅ FIREBASE - Nettoyage réel
  Future<void> _cleanupUserOldFilesFirebase(int daysOld) async {
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
            print('✅ Ancien fichier Firebase supprimé: ${item.name}');
          }
        } catch (e) {
          print('❌ Erreur suppression ${item.name}: $e');
        }
      }
      
      print('✅ Nettoyage Firebase terminé: $deletedCount fichiers supprimés');
    } catch (e) {
      print('❌ Erreur nettoyage Firebase: $e');
      throw Exception('Erreur nettoyage: $e');
    }
  }

  /// ✅ MOCK - Nettoyage factice
  Future<void> _cleanupUserOldFilesMock(int daysOld) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    _ensureAuthenticated();

    if (!_mockUserImages.containsKey(_currentUserId)) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final images = _mockUserImages[_currentUserId]!;
    int deletedCount = 0;

    final imagesToRemove = <String>[];
    for (final url in images) {
      final metadata = _mockImageMetadata[url];
      if (metadata != null) {
        final uploadDate = DateTime.tryParse(metadata['uploadedAt'] ?? '');
        if (uploadDate != null && uploadDate.isBefore(cutoffDate)) {
          imagesToRemove.add(url);
          deletedCount++;
        }
      }
    }

    for (final url in imagesToRemove) {
      images.remove(url);
      _mockImageMetadata.remove(url);
    }

    print('✅ Nettoyage démo terminé: $deletedCount fichiers supprimés');
  }

  /// ✅ MÉTHODE DE DIAGNOSTIC
  Future<void> debugPhotoService() async {
    print('🔍 Debug FirebasePhotoService:');
    print('  - Mode démo: $_isDemoMode');
    print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');
    print('  - User ID: ${_currentUserId ?? 'Non connecté'}');
    print('  - User Role: ${_currentUserRole?.name ?? 'Aucun'}');
    
    if (_currentUserId != null) {
      try {
        final stats = await getUserStorageStats();
        print('  - Photos utilisateur: ${stats['totalFiles']}');
        print('  - Espace utilisé: ${stats['totalSizeMB']} MB');
        print('  - Source: ${stats['_source'] ?? 'unknown'}');
        
        if (_isDemoMode) {
          print('  - Images mock en mémoire: ${_mockUserImages.length} utilisateurs');
          print('  - Métadonnées mock: ${_mockImageMetadata.length} fichiers');
        }
      } catch (e) {
        print('  - Erreur: $e');
      }
    }
  }

  // ✅ MÉTHODES UTILITAIRES (inchangées)
  Future<Uint8List> _optimizeImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        print('⚠️ Impossible d\'optimiser, utilisation fichier original');
        return await file.readAsBytes();
      }

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

  Future<bool> _isValidImageFile(File file) async {
    try {
      final extension = path.extension(file.path).toLowerCase();
      const validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      
      if (!validExtensions.contains(extension)) {
        print('❌ Extension non autorisée: $extension');
        return false;
      }

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
}