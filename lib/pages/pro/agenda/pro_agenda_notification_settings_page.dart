import 'package:flutter/material.dart';

class ProAgendaNotificationSettingsPage extends StatelessWidget {
  const ProAgendaNotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Paramètres des notifications de l'agenda",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
