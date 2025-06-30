import 'package:flutter/material.dart';

class ProAgendaCreateEventPage extends StatelessWidget {
  const ProAgendaCreateEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Création d’un événement",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
