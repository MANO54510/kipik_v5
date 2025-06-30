import 'package:flutter/material.dart';

class InkSpreadEffect extends CustomPainter {
  final double progress;

  InkSpreadEffect(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final double centerX = size.width * 0.1; // Point de départ : à gauche
    final double centerY = size.height * 0.5; // Milieu de l'écran

    final radius = size.width * progress * 2.5;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
  }

  @override
  bool shouldRepaint(InkSpreadEffect oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
