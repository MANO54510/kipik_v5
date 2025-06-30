import 'package:flutter/material.dart';

class InkSplashPainter extends CustomPainter {
  final double progress;

  InkSplashPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final center = Offset(size.width * 0.1, size.height * 0.5);
    final radius = size.width * progress * 2; // Propagation rapide

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(InkSplashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
