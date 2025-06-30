import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/gpt_app_bar.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_kipik.dart';

class ContestAdminPage extends StatelessWidget {
  const ContestAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final selectedBackground = backgrounds[Random().nextInt(backgrounds.length)];

    final List<_AdminModule> modules = [
      _AdminModule('Accueil', Icons.dashboard, '/admin/home'),
      _AdminModule('Conventions', Icons.event, '/admin/conventions'),
      _AdminModule('Tatoueurs', Icons.people, '/admin/tattooers'),
      _AdminModule('Flashs', Icons.flash_on, '/admin/flash'),
      _AdminModule('Notifications', Icons.notifications, '/admin/notifications'),
      _AdminModule('Sponsors', Icons.star, '/admin/sponsors'),
      _AdminModule('Statistiques', Icons.bar_chart, '/admin/stats'),
      _AdminModule('Éditeur de plan', Icons.map, '/admin/map_editor'),
    ];

    return Scaffold(
      appBar: const GptAppBar(
        title: 'Dashboard Admin',
        showNotificationIcon: true,
        showBackButton: false,
      ),
      drawer: const CustomDrawerKipik(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(selectedBackground, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: modules.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final module = modules[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, module.route);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(module.icon, size: 40, color: Colors.black),
                        const SizedBox(height: 10),
                        Text(
                          module.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminModule {
  final String title;
  final IconData icon;
  final String route;

  _AdminModule(this.title, this.icon, this.route);
}
