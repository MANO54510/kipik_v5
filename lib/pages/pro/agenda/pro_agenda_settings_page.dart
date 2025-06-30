import 'package:flutter/material.dart';

class ProAgendaSettingsPage extends StatelessWidget {
  const ProAgendaSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres de l’agenda'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SwitchListTile(
            title: const Text('Rappel 3 jours avant', style: TextStyle(color: Colors.white)),
            value: true,
            onChanged: (bool value) {},
          ),
          SwitchListTile(
            title: const Text('Rappel 1 jour avant', style: TextStyle(color: Colors.white)),
            value: true,
            onChanged: (bool value) {},
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          const Text(
            'Affichage de l’agenda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          ListTile(
            title: const Text('Vue par défaut : Semaine', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () {
              // Action à venir
            },
          ),
          ListTile(
            title: const Text('Activer les couleurs par type de rendez-vous', style: TextStyle(color: Colors.white)),
            trailing: Switch(value: true, onChanged: (bool value) {}),
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          const Text(
            'Localisation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          ListTile(
            title: const Text('Modifier la localisation temporaire', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.location_on, color: Colors.white),
            onTap: () {
              // Redirection future
            },
          ),
        ],
      ),
    );
  }
}
