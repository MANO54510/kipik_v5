// lib/utils/screenshot_helper.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class ScreenshotHelper {
  /// Capture l'avatar avec les sélections de zones corporelles
  static Future<String?> captureAvatar(BuildContext context, GlobalKey avatarKey) async {
    try {
      // Vérifier que la clé existe et a un contexte
      if (avatarKey.currentContext == null) {
        print('❌ Avatar key context est null');
        return null;
      }

      // Récupérer le RenderObject
      final RenderObject? renderObject = avatarKey.currentContext!.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        print('❌ RenderObject non trouvé ou pas un RenderRepaintBoundary');
        return null;
      }

      // Capturer l'image
      final RenderRepaintBoundary boundary = renderObject as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        print('❌ Impossible de convertir l\'image en ByteData');
        return null;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/avatar_zones_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      print('✅ Capture avatar sauvegardée: $filePath');
      return filePath;
      
    } catch (e) {
      print('❌ Erreur lors de la capture avatar: $e');
      return null;
    }
  }

  /// Capture une zone spécifique de l'écran
  static Future<String?> captureWidget(GlobalKey widgetKey, {String? filename}) async {
    try {
      if (widgetKey.currentContext == null) {
        print('❌ Widget key context est null');
        return null;
      }

      final RenderObject? renderObject = widgetKey.currentContext!.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        print('❌ RenderObject non trouvé ou pas un RenderRepaintBoundary');
        return null;
      }

      final RenderRepaintBoundary boundary = renderObject as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        print('❌ Impossible de convertir l\'image en ByteData');
        return null;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = filename ?? 'widget_capture_$timestamp';
      final filePath = '${directory.path}/$name.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      print('✅ Capture widget sauvegardée: $filePath');
      return filePath;
      
    } catch (e) {
      print('❌ Erreur lors de la capture widget: $e');
      return null;
    }
  }

  /// Nettoyer les anciens fichiers de capture
  static Future<void> cleanupOldCaptures({int maxAgeHours = 24}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final entities = directory.listSync();
      final now = DateTime.now();

      for (final entity in entities) {
        if (entity is File && 
            (entity.path.contains('avatar_') || entity.path.contains('widget_capture_')) &&
            entity.path.endsWith('.png')) {
          
          final fileStat = await entity.stat();
          final age = now.difference(fileStat.modified);
          
          if (age.inHours > maxAgeHours) {
            await entity.delete();
            print('🗑️ Fichier de capture supprimé: ${entity.path}');
          }
        }
      }
    } catch (e) {
      print('❌ Erreur nettoyage captures: $e');
    }
  }

  /// Obtenir la taille du fichier en MB
  static Future<double> getFileSizeMB(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        return size / (1024 * 1024); // Conversion en MB
      }
      return 0;
    } catch (e) {
      print('❌ Erreur calcul taille fichier: $e');
      return 0;
    }
  }

  /// Vérifier si un fichier de capture existe
  static Future<bool> captureExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      print('❌ Erreur vérification existence capture: $e');
      return false;
    }
  }
}