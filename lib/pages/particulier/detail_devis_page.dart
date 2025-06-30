// lib/pages/particulier/detail_devis_page.dart
import 'package:flutter/material.dart';
import '../../theme/kipik_theme.dart';
import 'mes_devis_page.dart'; // pour le modèle Devis et StatutDevis

class DetailDevisPage extends StatelessWidget {
  final Devis devis;
  const DetailDevisPage({ required this.devis, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${devis.id} – ${devis.userLastName}_${devis.userFirstName}',
          style: const TextStyle(fontFamily: 'PermanentMarker', fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('TATTOEUR'),
            Text(devis.tattooerName,
                style: const TextStyle(color: Colors.white70, fontSize: 18)),

            const SizedBox(height: 16),
            _sectionTitle('DÉTAILS DU DEVIS'),
            _infoRow('Date de la demande',
                '${devis.date.day}/${devis.date.month}/${devis.date.year}'),
            _infoRow('Montant estimé', '${devis.montant.toStringAsFixed(2)} €'),
            _infoRow('Statut', devis.statut.label,
                valueColor: devis.statut.color),

            const SizedBox(height: 16),
            _sectionTitle('PLANIFICATION'),
            // Tu peux étendre ton modèle Devis pour y inclure ces champs :
            _infoRow('Date de réalisation', 'à définir'),
            _infoRow('Durée estimée', '2 heures'),
            _infoRow('Nombre d’heures', '2'),

            const SizedBox(height: 16),
            _sectionTitle('COMMENTAIRES DU TATOUEUR'),
            const Text(
              'Le tatoueur devra préciser ici les informations supplémentaires ou validations.',
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
                child: const Text(
                  'Retour',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14))),
          Expanded(
              flex: 5,
              child: Text(value,
                  style: TextStyle(
                      color: valueColor ?? Colors.white, fontSize: 14))),
        ],
      ),
    );
  }
}
