import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import 'package:kipik_v5/services/photo/photo_service.dart';
import 'package:kipik_v5/services/photo/firebase_photo_service.dart';

class AjoutPhotosShopPage extends StatefulWidget {
  /// Injection du service Firebase (par défaut)
  AjoutPhotosShopPage({
    Key? key,
    PhotoService? photoService,
  })  : photoService = photoService ?? FirebasePhotoService.instance,
        super(key: key);

  final PhotoService photoService;

  @override
  State<AjoutPhotosShopPage> createState() => _AjoutPhotosShopPageState();
}

class _AjoutPhotosShopPageState extends State<AjoutPhotosShopPage> {
  final List<String> _photosUrls = [];
  static const int maxPhotos = 5;

  Future<void> _pickImage() async {
    if (_photosUrls.length >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous avez atteint la limite de 5 photos.')),
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

    try {
      // 1️⃣ Vérification de sécurité
      final isSafe = await widget.photoService.checkImageSafety(file);
      if (!isSafe) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo refusée pour contenu inapproprié.')),
        );
        return;
      }

      // 2️⃣ Upload
      final uploadedUrl = await widget.photoService.uploadImage(
        file,
        'shops_photos/demo_user/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (uploadedUrl != null) {
        setState(() => _photosUrls.add(uploadedUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo validée et ajoutée.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'upload: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() => _photosUrls.removeAt(index));
    // TODO: plus tard, appeler widget.photoService.deleteImage(...) si implémenté
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Mes Photos de Shop',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Ajouter une Photo'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: _photosUrls.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (_, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _photosUrls[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => _removePhoto(i),
                        child: const Icon(Icons.cancel, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}