import 'package:flutter/material.dart';

class ConventionBookingPage extends StatelessWidget {
  const ConventionBookingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réserver un créneau'),
      ),
      body: const Center(
        child: Text('Formulaire pour réserver un rendez-vous sur la convention'),
      ),
    );
  }
}
