import 'package:flutter/material.dart';

class ProAgendaRdvDetailsPage extends StatelessWidget {
  const ProAgendaRdvDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Détails du rendez-vous",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
