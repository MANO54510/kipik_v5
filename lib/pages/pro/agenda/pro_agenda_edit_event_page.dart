import 'package:flutter/material.dart';

class ProAgendaEditEventPage extends StatelessWidget {
  const ProAgendaEditEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Modifier un événement",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

