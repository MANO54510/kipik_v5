import 'package:flutter/material.dart';

class GptAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Le titre centré.
  final String title;

  /// Affiche l'icône de notification.
  final bool showNotificationIcon;

  /// Affiche le bouton “back” à gauche.
  final bool showBackButton;

  /// Affiche le burger à droite et ouvre l'endDrawer.
  final bool showMenu;

  const GptAppBar({
    Key? key,
    required this.title,
    this.showNotificationIcon = true,
    this.showBackButton = false,
    this.showMenu = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (showNotificationIcon)
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: implémenter la notification
            },
          ),
        if (showMenu)
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Ouvrir le menu',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
