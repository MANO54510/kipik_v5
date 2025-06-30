// lib/pages/particulier/offres_mois_page.dart
import 'package:flutter/material.dart';
class OffresMoisPage extends StatelessWidget {
  const OffresMoisPage({Key? key}) : super(key: key);
  @override Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Offres du mois')),
    body: const Center(child: Text('Vos offres spéciales')),
  );
}
