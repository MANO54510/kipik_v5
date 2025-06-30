// lib/pages/pro/comptabilite_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_kipik.dart';
import 'package:kipik_v5/pages/pro/home_page_pro.dart';

class ComptabilitePage extends StatelessWidget {
  const ComptabilitePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO : Remplacer par des données dynamiques issus du service de facturation

    // Données mock
    final double paiementsRecus = 12500.75;
    final double paiementsEnAttente = 3200.50;
    final double totalFactureMois = 15701.25;
    final List<Map<String, dynamic>> transactions = [
      { 'date': '01/05/2025', 'client': 'Sophie Durand', 'montant': 250.00, 'statut': 'Reçu' },
      { 'date': '03/05/2025', 'client': 'Thomas Lemoine', 'montant': 450.00, 'statut': 'En attente' },
      { 'date': '07/05/2025', 'client': 'Emma Martin', 'montant': 120.00, 'statut': 'Reçu' },
      // ...
    ];

    return Scaffold(
      appBar: CustomAppBarKipik(
        title: 'Comptabilité',
        showBurger: false,
        showBackButton: true,
        showNotificationIcon: true,
        onBackPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePagePro()),
          );
        },
      ),
      drawer: const CustomDrawerKipik(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cartes de synthèse
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryCard(
                  label: 'Paiements reçus',
                  value: paiementsRecus,
                  color: Colors.greenAccent,
                ),
                _SummaryCard(
                  label: 'En attente',
                  value: paiementsEnAttente,
                  color: Colors.orangeAccent,
                ),
                _SummaryCard(
                  label: 'Total facturé mois',
                  value: totalFactureMois,
                  color: Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Transactions récentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Text(tx['date'], style: const TextStyle(fontSize: 14)),
                      title: Text(tx['client']),
                      subtitle: Text('${tx['statut']}'),
                      trailing: Text(
                        '${tx['montant'].toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tx['statut'] == 'Reçu' ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de synthèse pour les totaux
class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 3 - 24,
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.darken(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${value.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color.darken(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension pour assombrir la couleur
extension ColorUtils on Color {
  Color darken([double amount = .2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}