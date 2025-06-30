// lib/pages/particulier/flash_dispo_page.dart
import 'package:flutter/material.dart';
class FlashDispoPage extends StatelessWidget {
  const FlashDispoPage({Key? key}) : super(key: key);
  @override Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('La chance est avec toi')),
    body: const Center(child: Text('Flashs disponibles aujourd’hui')),
  );
}
