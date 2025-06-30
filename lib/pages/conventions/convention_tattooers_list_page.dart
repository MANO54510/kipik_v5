import 'package:flutter/material.dart';

class ConventionTattooersListPage extends StatelessWidget {
  const ConventionTattooersListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tatoueurs présents'),
      ),
      body: const Center(
        child: Text('Liste des tatoueurs inscrits à cet événement'),
      ),
    );
  }
}
