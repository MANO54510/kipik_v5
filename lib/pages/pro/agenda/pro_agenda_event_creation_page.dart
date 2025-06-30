import 'package:flutter/material.dart';

class ProAgendaEventCreationPage extends StatelessWidget {
  const ProAgendaEventCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Créer un événement ou un déplacement",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
