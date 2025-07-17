import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/pages/organisateur/organisateur_dashboard_page.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class ConfirmationInscriptionOrganisateurPage extends StatelessWidget {
  const ConfirmationInscriptionOrganisateurPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgrounds = KipikTheme.backgrounds;
    final bg = backgrounds[Random().nextInt(backgrounds.length)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: "Bienvenue",
        showBackButton: false,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bg, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône de succès
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: KipikTheme.rouge,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: KipikTheme.rouge.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Message de bienvenue
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            "🎉 Inscription validée !",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Bienvenue dans l'univers KIPIK ORGANISATEUR !\n\n"
                            "Votre compte organisateur est maintenant activé.\n"
                            "Vous pouvez dès à présent créer et gérer vos événements.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Bouton principal vers dashboard organisateur
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrganisateurDashboardPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KipikTheme.rouge,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: KipikTheme.rouge.withOpacity(0.3),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PermanentMarker',
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dashboard, size: 24),
                            SizedBox(width: 12),
                            Text("Accéder à mon espace organisateur"),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Conseil/astuce
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KipikTheme.rouge.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: KipikTheme.rouge.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.tips_and_updates, color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Astuce : Commencez par compléter votre profil et créez votre premier événement pour lancer votre aventure avec KIPIK !",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
