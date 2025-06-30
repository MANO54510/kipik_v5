import 'package:flutter/material.dart';

class ProAgendaDayViewPage extends StatelessWidget {
  const ProAgendaDayViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Vue quotidienne de l'agenda",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
