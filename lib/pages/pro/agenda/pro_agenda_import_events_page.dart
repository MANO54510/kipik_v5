import 'package:flutter/material.dart';

class ProAgendaImportEventsPage extends StatelessWidget {
  const ProAgendaImportEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Importer les événements existants",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
