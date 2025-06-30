// lib/pages/auth/inscription_page.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/pages/particulier/inscription_particulier_page.dart';
import 'package:kipik_v5/pages/pro/inscription_pro_page.dart';
import 'package:kipik_v5/pages/organisateur/inscription_organisateur_page.dart'; // Nouvelle import

class InscriptionPage extends StatelessWidget {
  const InscriptionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final bg = backgrounds[Random().nextInt(backgrounds.length)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBarKipik(
        title: tr('signup.choiceTitle'),
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bg, fit: BoxFit.cover),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildChoiceButton(
                    context,
                    tr('signup.particulier'),
                    InscriptionParticulierPage(),
                  ),
                  const SizedBox(height: 20),
                  _buildChoiceButton(
                    context,
                    tr('signup.pro'),
                    InscriptionProPage(),
                  ),
                  const SizedBox(height: 20),
                  _buildChoiceButton(
                    context,
                    tr('signup.organisateur'), // Nouveau texte à ajouter dans les traductions
                    InscriptionOrganisateurPage(), // Nouvelle page à créer
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(
    BuildContext context,
    String text,
    Widget page,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          shadowColor: Colors.black45,
          textStyle: const TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Text(text),
      ),
    );
  }
}