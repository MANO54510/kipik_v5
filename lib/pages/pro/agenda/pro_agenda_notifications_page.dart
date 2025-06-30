import 'package:flutter/material.dart';
import 'package:kipik_v5/pages/pro/home_page_pro.dart';

class ProAgendaNotificationsPage extends StatelessWidget {
  const ProAgendaNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Notifications Agenda',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePagePro()),
            );
          },
        ),
      ),
      body: const Center(
        child: Text(
          "Notifications de l'agenda",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}