import 'package:flutter/material.dart';

class ProAgendaLocationOverridePage extends StatelessWidget {
  const ProAgendaLocationOverridePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Définir une localisation temporaire",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
