import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class ScreenshotHelper {
  static final ScreenshotController screenshotController = ScreenshotController();

  /// Capture l'avatar avec les sélections
  static Future<String?> captureAvatar(BuildContext context, GlobalKey avatarKey) async {
    try {
      RenderRepaintBoundary boundary = avatarKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/avatar_selection_kipik.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      return file.path;
    } catch (e) {
      debugPrint('Erreur lors de la capture : $e');
      return null;
    }
  }
}
