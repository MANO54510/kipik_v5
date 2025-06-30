// lib/widgets/common/app_bars/custom_app_bar_kipik.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/pages/pro/home_page_pro.dart'; // 🚨 IMPORT MANQUANT

class CustomAppBarKipik extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showBurger;
  final bool showNotificationIcon;
  final Function? onNotificationPressed;
  final int notificationCount;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed; // Nouveau paramètre pour personnaliser le retour
  final bool useProStyle; // Nouveau paramètre pour utiliser le style Pro

  const CustomAppBarKipik({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.showBurger = false,
    this.showNotificationIcon = false,
    this.onNotificationPressed,
    this.notificationCount = 0,
    this.actions,
    this.onBackPressed,
    this.useProStyle = false, // Par défaut false pour garder la compatibilité
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'PermanentMarker',
          fontSize: useProStyle ? 20 : 22,
          color: Colors.white,
          fontWeight: useProStyle ? FontWeight.w400 : FontWeight.normal,
          shadows: useProStyle ? null : [
            const Shadow(
              color: Colors.black54,
              offset: Offset(0, 1),
              blurRadius: 2,
            )
          ],
        ),
      ),
      centerTitle: true,
      leading: _buildLeading(context),
      actions: _buildActions(context),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (showBackButton) {
      if (useProStyle) {
        // Style Pro avec conteneur arrondi
        return Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: onBackPressed ?? () => _handleBackNavigation(context),
          ),
        );
      } else {
        // Style classique
        return IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBackPressed ?? () => _handleBackNavigation(context),
        );
      }
    } else if (showBurger) {
      if (useProStyle) {
        // Style Pro pour le menu burger
        return Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        );
      } else {
        // Style classique
        return IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        );
      }
    }
    return null;
  }

  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actionWidgets = [];
    
    // Ajouter le bouton de notification s'il doit être affiché
    if (showNotificationIcon) {
      if (useProStyle) {
        // Style Pro pour les notifications
        actionWidgets.add(
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: onNotificationPressed != null 
                      ? () => onNotificationPressed!() 
                      : () {},
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: KipikTheme.rouge,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        notificationCount > 9 ? '9+' : notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      } else {
        // Style classique
        actionWidgets.add(
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: onNotificationPressed != null 
                    ? () => onNotificationPressed!() 
                    : () {},
              ),
              if (notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: KipikTheme.rouge,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notificationCount > 9 ? '9+' : notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    }
    
    // Ajouter les autres actions passées en paramètre
    if (actions != null) {
      if (useProStyle) {
        // Appliquer le style Pro aux actions personnalisées
        actionWidgets.addAll(
          actions!.map((action) {
            // Si l'action est déjà dans un Container, on la retourne telle quelle
            if (action is Container) {
              return action;
            }
            // Sinon, on l'enveloppe dans le style Pro
            return Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: action,
            );
          }),
        );
      } else {
        actionWidgets.addAll(actions!);
      }
    }
    
    return actionWidgets;
  }

  /// Gestion intelligente de la navigation de retour
  void _handleBackNavigation(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Si on ne peut pas revenir en arrière, on va à la HomePage Pro
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePagePro()),
        (route) => false,
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}