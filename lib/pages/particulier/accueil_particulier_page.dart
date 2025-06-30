// lib/pages/particulier/accueil_particulier_page.dart

import 'dart:math';
import 'package:flutter/material.dart';

import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';  // ← mis à jour
import '../../widgets/common/drawers/custom_drawer_particulier.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../theme/kipik_theme.dart';
import 'recherche_tatoueur_page.dart';

import 'rdv_jour_page.dart';
import 'mes_devis_page.dart';
import 'mes_projets_particulier_page.dart';
import 'messages_particulier_page.dart';

class AccueilParticulierPage extends StatefulWidget {
  const AccueilParticulierPage({Key? key}) : super(key: key);

  @override
  State<AccueilParticulierPage> createState() => _AccueilParticulierPageState();
}

class _AccueilParticulierPageState extends State<AccueilParticulierPage> {
  late final String _bgAsset;
  final String _userName        = 'Jean-Charles';
  final int    _requestsCount   = 3;
  final int    _projectsCount   = 2;
  final String _nextAppointment = '12/05/2025 • 14h00';
  String?      _avatarUrl;

  @override
  void initState() {
    super.initState();
    const backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    _bgAsset = backgrounds[Random().nextInt(backgrounds.length)];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardW = (w - 48 - 12) / 2;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        endDrawer: const CustomDrawerParticulier(),
        appBar: CustomAppBarParticulier(
          title: 'Accueil',
          showBackButton: false,
          showBurger: true,
          showNotificationIcon: true,
          redirectToHome: false,
        ),
        floatingActionButton: const TattooAssistantButton(
          allowImageGeneration: false,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_bgAsset, fit: BoxFit.cover),
            SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Bienvenue, $_userName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 26,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Encre tes idées, à toi de jouer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: cardW,
                      height: cardW,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _avatarUrl ?? 'assets/avatars/avatar_user_neutre.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: KipikTheme.rouge, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RechercheTatoueurPage(),
                          ),
                        ),
                        child: const Text(
                          'Rechercher mon tatoueur',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'PermanentMarker',
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _DashboardCard(
                            icon: Icons.event,
                            title: 'Prochain RDV',
                            value: _nextAppointment,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RdvJourPage(),
                              ),
                            ),
                          ),
                          _DashboardCard(
                            icon: Icons.request_quote,
                            title: 'Demande de devis\nen cours',
                            value: '$_requestsCount',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MesDevisPage(),
                              ),
                            ),
                          ),
                          _DashboardCard(
                            icon: Icons.work_outline,
                            title: 'Projets en cours',
                            value: '$_projectsCount',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MesProjetsParticulierPage(),
                              ),
                            ),
                          ),
                          _DashboardCard(
                            icon: Icons.chat_bubble,
                            title: 'Messages',
                            value: '0',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MessagesParticulierPage(),
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
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: KipikTheme.rouge.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'PermanentMarker',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}