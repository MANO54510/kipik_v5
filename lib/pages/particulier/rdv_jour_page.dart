import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';

class RdvJourPage extends StatefulWidget {
  const RdvJourPage({Key? key}) : super(key: key);

  @override
  State<RdvJourPage> createState() => _RdvJourPageState();
}

class _RdvJourPageState extends State<RdvJourPage> {
  final List<Appointment> _appointments = [
    Appointment(
      id: '1',
      dateTime: DateTime.now().add(const Duration(hours: 4)),
      tattooerName: 'Jean Dupont',
      studio: 'InkMaster Studio',
      address: '15 Rue Saint-Dizier, 54000 Nancy',
      avatar: 'assets/avatars/tatoueur1.jpg',
    ),
    // ... autres rendez-vous ...
  ];

  @override
  void initState() {
    super.initState();
    _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> _openMaps(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir le plan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: 'Mes rendez-vous',
        showBackButton: true,
        redirectToHome: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final appt = _appointments[i];
          return Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KipikTheme.rouge, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artiste + avatar
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage(appt.avatar),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          appt.tattooerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'PermanentMarker',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appt.studio,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  // Date & heure
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(appt.dateTime),
                        style: const TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(appt.dateTime),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bouton Itinéraire
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _openMaps(appt.address),
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text(
                        'Plan',
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KipikTheme.rouge,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class Appointment {
  final String id;
  final DateTime dateTime;
  final String tattooerName;
  final String studio;
  final String address;
  final String avatar;

  Appointment({
    required this.id,
    required this.dateTime,
    required this.tattooerName,
    required this.studio,
    required this.address,
    required this.avatar,
  });
}
