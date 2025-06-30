import 'package:flutter/material.dart';

class ProAgendaImportPage extends StatelessWidget {
  const ProAgendaImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importer mon agenda'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.import_export, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Connecte ton agenda existant',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Intégration à venir : Google, Apple, Outlook
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Importer depuis Google Calendar'),
            ),
          ],
        ),
      ),
    );
  }
}
