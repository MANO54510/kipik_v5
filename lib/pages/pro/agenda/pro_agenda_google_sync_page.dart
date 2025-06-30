import 'package:flutter/material.dart';

class ProAgendaGoogleSyncPage extends StatelessWidget {
  const ProAgendaGoogleSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Synchronisation avec Google Agenda",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
