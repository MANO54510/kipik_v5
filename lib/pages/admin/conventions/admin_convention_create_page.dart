import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/gpt_app_bar.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_kipik.dart';

class AdminConventionCreatePage extends StatelessWidget {
  const AdminConventionCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final selectedBackground = backgrounds[Random().nextInt(backgrounds.length)];

    return Scaffold(
      appBar: const GptAppBar(
        title: 'Créer une Convention',
        showNotificationIcon: true,
        showBackButton: false,
      ),
      drawer: const CustomDrawerKipik(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(selectedBackground, fit: BoxFit.cover),
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Formulaire de création d’une nouvelle convention.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
