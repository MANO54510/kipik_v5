import 'package:flutter/material.dart';

class ProAgendaPreferencesPage extends StatelessWidget {
  const ProAgendaPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Préférences de l'agenda",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
