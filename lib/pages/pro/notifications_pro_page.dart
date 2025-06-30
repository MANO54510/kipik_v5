import 'package:flutter/material.dart';

import 'package:kipik_v5/widgets/common/app_bars/gpt_app_bar.dart';


class NotificationsProPage extends StatefulWidget {
  const NotificationsProPage({super.key});

  @override
  State<NotificationsProPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsProPage> {
  List<String> notifications = [
    'Votre rendez-vous a été confirmé !',
    'Un nouveau message de votre tatoueur.',
    'Votre projet a été mis à jour.',
    'Nouveaux flashs disponibles près de chez vous.',
  ];

  late final String selectedBackground;

  @override
  void initState() {
    super.initState();
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    backgrounds.shuffle();
    selectedBackground = backgrounds.first;
  }

  void _clearNotifications() {
    setState(() {
      notifications.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toutes les notifications ont été supprimées.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GptAppBar(title: 'Notifications'),
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            selectedBackground,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          if (notifications.isEmpty)
            const Center(
              child: Text(
                'Aucune notification pour le moment.',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.white12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.redAccent),
                    title: Text(
                      notifications[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: notifications.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _clearNotifications,
              backgroundColor: Colors.redAccent,
              icon: const Icon(Icons.delete),
              label: const Text('Tout supprimer'),
            )
          : null,
    );
  }
}
