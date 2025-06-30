import 'package:flutter/material.dart';

class ConventionDetailPage extends StatelessWidget {
  const ConventionDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la convention'),
      ),
      body: const Center(
        child: Text('Informations détaillées sur la convention'),
      ),
    );
  }
}
