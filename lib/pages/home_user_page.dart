import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/gpt_app_bar.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart'; // Nouveau import pour le DrawerFactory

class HomeUserPage extends StatelessWidget {
  const HomeUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GptAppBar(
        title: 'Mon espace',
        showNotificationIcon: true,
      ),
      // Remplacer le CustomDrawerKipik par DrawerFactory.of(context)
      endDrawer: DrawerFactory.of(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background_charbon.png', fit: BoxFit.cover),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.account_circle, size: 100, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Bienvenue dans votre espace !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}