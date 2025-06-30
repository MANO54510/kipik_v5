import 'package:flutter/material.dart';

class ProAgendaLocalisationPage extends StatelessWidget {
  const ProAgendaLocalisationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Localisation temporaire",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
