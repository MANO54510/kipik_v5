import 'package:flutter/material.dart';

class ProAgendaWeekViewPage extends StatelessWidget {
  const ProAgendaWeekViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Vue hebdomadaire de l'agenda",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
