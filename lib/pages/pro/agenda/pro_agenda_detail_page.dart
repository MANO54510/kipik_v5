import 'package:flutter/material.dart';

class ProAgendaDetailPage extends StatelessWidget {
  const ProAgendaDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Détail du rendez-vous",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
