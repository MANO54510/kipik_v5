// lib/widgets/notification_badge.dart
import 'package:flutter/material.dart';
import '../../theme/kipik_theme.dart';

// Un petit badge qui montre le nombre de notifications
class NotificationBadge extends StatelessWidget {
  final int count;
  
  const NotificationBadge({
    Key? key,
    required this.count,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: KipikTheme.rouge,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 9 ? '9+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}