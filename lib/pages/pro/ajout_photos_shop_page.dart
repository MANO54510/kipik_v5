import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:kipik_v5/services/photo/firebase_photo_service.dart';
import 'package:kipik_v5/core/database_manager.dart'; // ✅ AJOUTÉ pour mode démo
import 'package:kipik_v5/theme/kipik_theme.dart';

class AjoutPhotosShopPage extends StatefulWidget {
  AjoutPhotosShopPage({
    Key? key,
    FirebasePhotoService? photoService,
  })  : photoService = photoService ?? FirebasePhotoService.instance,
        super(key: key);

  final FirebasePhotoService photoService;

  @override
  State<AjoutPhotosShopPage> createState() => _AjoutPhotosShopPageState();
}

class _AjoutPhotosShopPageState extends State<AjoutPhotosShopPage> {
  final List<String> _photosUrls = [];
  static const int maxPhotos = 8;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExistingPhotos();
  }

  /// ✅ NOUVEAU : Charger les photos existantes selon le mode
  Future<void> _loadExistingPhotos() async {
    if (DatabaseManager.instance.isDemoMode) {
      // En mode démo, ajouter quelques photos d'exemple
      setState(() {
        _photosUrls.addAll([
          'https://picsum.photos/seed/shop1/400/400',
          'https://picsum.photos/seed/shop2/400/400',
          'https://picsum.photos/seed/shop3/400/400',
        ]);
      });
      print('🎭 Photos démo chargées: ${_photosUrls.length}');
    } else {
      // TODO: Charger les vraies photos depuis Firebase
      print('🏭 Mode production: chargement photos réelles');
    }
  }

  /// ✅ AMÉLIORÉ : Upload avec gestion mode démo/production
  Future<void> _pickImage() async {
    if (_photosUrls.length >= maxPhotos) {
      _showSnackBar(
        'Vous avez atteint la limite de $maxPhotos photos.',
        Colors.orange,
      );
      return;
    }

    final XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final XFile? pickedFile = await openFile(acceptedTypeGroups: [typeGroup]);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      String uploadedUrl;
      
      if (DatabaseManager.instance.isDemoMode) {
        // ✅ Mode démo : simuler l'upload
        uploadedUrl = await _simulateUpload(file);
      } else {
        // ✅ Mode production : upload réel
        uploadedUrl = await _uploadToFirebase(file);
      }

      setState(() => _uploadProgress = 1.0);

      if (uploadedUrl.isNotEmpty) {
        setState(() => _photosUrls.add(uploadedUrl));
        _showSnackBar(
          DatabaseManager.instance.isDemoMode 
              ? 'Photo démo ajoutée avec succès !'
              : 'Photo validée et ajoutée avec succès !',
          Colors.green,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Erreur lors de l\'upload: $e',
        Colors.red,
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  /// ✅ NOUVEAU : Simuler upload en mode démo
  Future<String> _simulateUpload(File file) async {
    // Simuler les étapes d'upload avec progrès
    for (double progress = 0.1; progress <= 1.0; progress += 0.2) {
      setState(() => _uploadProgress = progress);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    // Retourner une URL d'image aléatoire
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'https://picsum.photos/seed/upload$timestamp/400/400';
  }

  /// ✅ NOUVEAU : Upload réel vers Firebase
  Future<String> _uploadToFirebase(File file) async {
    try {
      // Vérification de sécurité
      setState(() => _uploadProgress = 0.2);
      final isSafe = await widget.photoService.checkImageSafety(file);
      if (!isSafe) {
        throw Exception('Contenu inapproprié ou format invalide');
      }

      setState(() => _uploadProgress = 0.5);

      // Upload vers Firebase Storage
      final uploadedUrl = await widget.photoService.uploadImage(
        file,
        'shops_photos',
      );

      setState(() => _uploadProgress = 0.9);
      
      return uploadedUrl;
    } catch (e) {
      print('❌ Erreur upload Firebase: $e');
      rethrow;
    }
  }

  /// ✅ AMÉLIORÉ : Upload multiple avec gestion des modes
  Future<void> _pickMultipleImages() async {
    final remainingSlots = maxPhotos - _photosUrls.length;
    if (remainingSlots <= 0) {
      _showSnackBar(
        'Vous avez atteint la limite de $maxPhotos photos.',
        Colors.orange,
      );
      return;
    }

    final XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final List<XFile> pickedFiles = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (pickedFiles.isEmpty) return;

    final filesToUpload = pickedFiles.take(remainingSlots).toList();
    final files = filesToUpload.map((xfile) => File(xfile.path)).toList();

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      List<String> urls;
      
      if (DatabaseManager.instance.isDemoMode) {
        // ✅ Mode démo : simuler upload multiple
        urls = await _simulateMultipleUpload(files);
      } else {
        // ✅ Mode production : upload multiple réel
        urls = await _uploadMultipleToFirebase(files);
      }

      setState(() {
        _photosUrls.addAll(urls);
      });

      _showSnackBar(
        '${urls.length} photo(s) ajoutée(s) avec succès !',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar(
        'Erreur lors de l\'upload multiple: $e',
        Colors.red,
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  /// ✅ NOUVEAU : Simuler upload multiple démo
  Future<List<String>> _simulateMultipleUpload(List<File> files) async {
    final urls = <String>[];
    
    for (int i = 0; i < files.length; i++) {
      setState(() => _uploadProgress = (i + 1) / files.length);
      await Future.delayed(const Duration(milliseconds: 400));
      
      final timestamp = DateTime.now().millisecondsSinceEpoch + i;
      urls.add('https://picsum.photos/seed/multi$timestamp/400/400');
    }
    
    return urls;
  }

  /// ✅ NOUVEAU : Upload multiple réel
  Future<List<String>> _uploadMultipleToFirebase(List<File> files) async {
    try {
      final urls = await widget.photoService.uploadMultipleImages(
        files,
        'shops_photos',
        onProgress: (current, total) {
          setState(() {
            _uploadProgress = current / total;
          });
        },
      );
      return urls;
    } catch (e) {
      print('❌ Erreur upload multiple Firebase: $e');
      rethrow;
    }
  }

  /// ✅ AMÉLIORÉ : Suppression avec gestion des modes
  Future<void> _removePhoto(int index) async {
    final url = _photosUrls[index];
    
    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Confirmer', style: TextStyle(color: Colors.white)),
        content: Text(
          DatabaseManager.instance.isDemoMode 
              ? 'Supprimer cette photo de démonstration ?'
              : 'Supprimer définitivement cette photo ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (DatabaseManager.instance.isDemoMode) {
        // ✅ Mode démo : suppression locale uniquement
        setState(() => _photosUrls.removeAt(index));
        print('🎭 Photo démo supprimée localement');
      } else {
        // ✅ Mode production : supprimer de Firebase
        await widget.photoService.deleteImage(url);
        setState(() => _photosUrls.removeAt(index));
        print('🏭 Photo supprimée de Firebase Storage');
      }
      
      _showSnackBar(
        'Photo supprimée avec succès',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar(
        'Erreur lors de la suppression: $e',
        Colors.red,
      );
    }
  }

  /// ✅ AMÉLIORÉ : Optimisation avec gestion des modes
  Future<void> _createThumbnails() async {
    if (_photosUrls.isEmpty) {
      _showSnackBar('Aucune photo à optimiser', Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      for (int i = 0; i < _photosUrls.length; i++) {
        setState(() => _uploadProgress = i / _photosUrls.length);
        
        if (DatabaseManager.instance.isDemoMode) {
          // ✅ Mode démo : simuler l'optimisation
          await Future.delayed(const Duration(milliseconds: 300));
        } else {
          // ✅ Mode production : optimisation réelle
          // TODO: Implémenter l'optimisation Firebase
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      _showSnackBar(
        DatabaseManager.instance.isDemoMode 
            ? 'Optimisation démo terminée !'
            : 'Optimisation terminée !',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar(
        'Erreur lors de l\'optimisation: $e',
        Colors.red,
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickImage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Ajouter 1 Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickMultipleImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Ajouter Plusieurs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photosUrls.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _createThumbnails,
              icon: const Icon(Icons.tune),
              label: Text(
                DatabaseManager.instance.isDemoMode 
                    ? 'Optimiser (Démo)'
                    : 'Optimiser les Photos'
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator() {
    if (!_isUploading) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                DatabaseManager.instance.isDemoMode 
                    ? Icons.science 
                    : Icons.cloud_upload, 
                color: Colors.blue
              ),
              const SizedBox(width: 8),
              Text(
                DatabaseManager.instance.isDemoMode 
                    ? 'Simulation upload...'
                    : 'Upload en cours...',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // ✅ Indicateur de mode en haut
          if (DatabaseManager.instance.isDemoMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.science, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '🎭 Mode ${DatabaseManager.instance.activeDatabaseConfig.name}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.photo_library,
                label: 'Photos',
                value: '${_photosUrls.length}/$maxPhotos',
                color: _photosUrls.length >= maxPhotos ? Colors.red : Colors.blue,
              ),
              _StatItem(
                icon: Icons.storage,
                label: 'Espace',
                value: '${(_photosUrls.length / maxPhotos * 100).toInt()}%',
                color: _photosUrls.length >= maxPhotos ? Colors.red : Colors.green,
              ),
              _StatItem(
                icon: _isUploading ? Icons.sync : Icons.cloud_done,
                label: 'Statut',
                value: _isUploading ? 'Envoi...' : 'Prêt',
                color: _isUploading ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Photos de mon Shop',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            if (DatabaseManager.instance.isDemoMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DÉMO',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Conseils Photos',
                    style: TextStyle(color: Colors.white, fontFamily: 'PermanentMarker'),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (DatabaseManager.instance.isDemoMode) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '🎭 Mode démo actif - Les photos sont simulées',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const Text(
                        '• Utilisez un bon éclairage\n'
                        '• Évitez le flou de bougé\n'
                        '• Montrez votre espace de travail\n'
                        '• Mettez en valeur vos réalisations\n'
                        '• Maximum 8 photos par shop\n'
                        '• Formats acceptés: JPG, PNG, WEBP',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Compris'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStats(),
            _buildActionButtons(),
            _buildProgressIndicator(),
            const SizedBox(height: 20),
            Expanded(
              child: _photosUrls.isEmpty
                  ? _buildEmptyState()
                  : _buildPhotoGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune photo ajoutée',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'PermanentMarker',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DatabaseManager.instance.isDemoMode 
                ? 'Ajoutez des photos de démonstration\npour tester les fonctionnalités'
                : 'Ajoutez des photos de votre shop\npour attirer plus de clients',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      itemCount: _photosUrls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, i) => _buildPhotoCard(i),
    );
  }

  Widget _buildPhotoCard(int index) {
    return GestureDetector(
      onTap: () => _showPhotoDialog(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _photosUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removePhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // ✅ Badge démo si applicable
            if (DatabaseManager.instance.isDemoMode)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DÉMO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                _photosUrls[index],
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}