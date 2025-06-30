import 'package:flutter/material.dart';

class RealInkSpreadEffect extends CustomPainter {
  final double progress;

  RealInkSpreadEffect(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final double centerX = size.width * 0.1;
    final double centerY = size.height * 0.5;

    final radius = size.width * progress * 2.5;

    Path path = Path();

    // Création d'une forme "dynamique" avec irrégularités
    path.moveTo(centerX, centerY);
    path.addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));

    // Ajout de petits débordements pour l'effet fumé
    if (progress > 0.1) {
      path.addOval(Rect.fromCircle(center: Offset(centerX + radius * 0.2, centerY - radius * 0.3), radius: radius * 0.1));
      path.addOval(Rect.fromCircle(center: Offset(centerX - radius * 0.3, centerY + radius * 0.4), radius: radius * 0.15));
      path.addOval(Rect.fromCircle(center: Offset(centerX + radius * 0.4, centerY + radius * 0.1), radius: radius * 0.12));
    }

    if (progress > 0.5) {
      path.addOval(Rect.fromCircle(center: Offset(centerX + radius * 0.5, centerY - radius * 0.5), radius: radius * 0.2));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RealInkSpreadEffect oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
