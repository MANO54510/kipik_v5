import 'package:flutter/material.dart';

class ConventionAdminPage extends StatelessWidget {
  const ConventionAdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Conventions (Admin)'),
      ),
      body: const Center(
        child: Text('Ajouter, modifier ou supprimer des conventions'),
      ),
    );
  }
}
