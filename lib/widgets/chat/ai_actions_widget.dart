// lib/widgets/chat/ai_actions_widget.dart

import 'package:flutter/material.dart';
import '../../models/ai_action.dart';
import '../../theme/kipik_theme.dart';

class AIActionsWidget extends StatelessWidget {
  final List<AIAction> actions;
  final Function(AIAction)? onActionTap;

  const AIActionsWidget({
    Key? key,
    required this.actions,
    this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Actions suggérées :',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              fontFamily: 'PermanentMarker',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((action) => _buildActionChip(action, context)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(AIAction action, BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData iconData;

    // 🎨 Couleurs selon le type d'action
    switch (action.color) {
      case 'primary':
        backgroundColor = KipikTheme.rouge;
        textColor = Colors.white;
        break;
      case 'success':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        break;
      case 'purple':
        backgroundColor = Colors.purple;
        textColor = Colors.white;
        break;
      case 'orange':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        break;
      case 'info':
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        break;
      case 'gradient':
        backgroundColor = Colors.pinkAccent;
        textColor = Colors.white;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.black87;
    }

    // 🔤 Icônes selon le type
    switch (action.icon) {
      case 'search':
        iconData = Icons.search;
        break;
      case 'add_circle':
        iconData = Icons.add_circle_outline;
        break;
      case 'photo_library':
        iconData = Icons.photo_library_outlined;
        break;
      case 'calculate':
        iconData = Icons.calculate_outlined;
        break;
      case 'menu_book':
        iconData = Icons.menu_book_outlined;
        break;
      case 'image':
        iconData = Icons.image_outlined;
        break;
      default:
        iconData = Icons.arrow_forward;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onActionTap?.call(action),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconData,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  action.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}