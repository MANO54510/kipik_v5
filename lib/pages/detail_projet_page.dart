import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/gpt_app_bar.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_kipik.dart';

class DetailProjetPage extends StatelessWidget {
  final Map<String, dynamic> projetData;

  const DetailProjetPage({super.key, required this.projetData});

  @override
  Widget build(BuildContext context) {
    final statut = projetData['statut'] ?? 'Indéfini';
    final color = _getStatusColor(statut);

    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: const GptAppBar(title: 'Détail du Projet'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background_charbon.png', fit: BoxFit.cover),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Projet'),
                  _buildInfo('Titre', projetData['titre'] ?? 'Non renseigné'),
                  _buildInfo('Style', projetData['style'] ?? 'Non renseigné'),
                  _buildInfo('Endroit', projetData['endroit'] ?? 'Non renseigné'),
                  _buildInfo('Tatoueur', projetData['tatoueur'] ?? 'Non renseigné'),
                  _buildInfo('Montant total', '${projetData['montant'] ?? '0'} €'),
                  if (projetData.containsKey('acompte'))
                    _buildInfo('Acompte payé', '${projetData['acompte']} €'),
                  if (projetData.containsKey('modalites'))
                    _buildInfo('Modalités de paiement', projetData['modalites']),
                  _buildInfo('Statut', statut, color: color),
                  _buildInfo('Date de demande', projetData['dateDevis'] ?? 'Non renseigné'),
                  if (statut == 'Clôturé' && projetData.containsKey('dateCloture'))
                    _buildInfo(
                      'Projet clôturé',
                      'Le ${projetData['dateCloture']} (archive jusqu\'au ${_getDateArchivage(projetData['dateCloture'])})',
                    ),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Suivi des Séances'),
                  _buildSessions(projetData['sessions'] ?? []),
                  const SizedBox(height: 30),
                  if (statut == 'Accepté' || statut == 'En cours')
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO : Accéder au Chat Projet
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Accéder au Chat Projet',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'PermanentMarker',
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String value, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label :',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessions(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) {
      return const Text(
        'Aucune séance prévue.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: sessions.map((session) {
        final statut = _getSessionStatus(session['date']);
        final duration = _calculateDuration(session['startTime'], session['endTime']);

        return Card(
          color: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(
              statut == 'Réalisée' ? Icons.check_circle : Icons.access_time,
              color: statut == 'Réalisée' ? Colors.green : Colors.orangeAccent,
            ),
            title: Text('Séance prévue le ${session['date']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Début : ${session['startTime']}'),
                Text('Fin : ${session['endTime']}'),
                Text('Durée : $duration'),
                Text('Statut : $statut'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getSessionStatus(String dateStr) {
    final now = DateTime.now();
    final parts = dateStr.split('/');
    if (parts.length != 3) return 'À venir';

    final sessionDate = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );

    if (sessionDate.isBefore(now)) {
      return 'Réalisée';
    } else {
      return 'À venir';
    }
  }

  String _calculateDuration(String start, String end) {
    final startParts = start.split(':').map(int.parse).toList();
    final endParts = end.split(':').map(int.parse).toList();

    final startMinutes = startParts[0] * 60 + startParts[1];
    final endMinutes = endParts[0] * 60 + endParts[1];

    final durationMinutes = endMinutes - startMinutes;
    final hours = durationMinutes ~/ 60;

    return '${hours}h';
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'En attente':
        return Colors.orangeAccent;
      case 'En cours':
        return Colors.blueAccent;
      case 'Clôturé':
        return Colors.redAccent;
      case 'Accepté':
        return Colors.green;
      case 'Refusé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDateArchivage(String dateCloture) {
    final parts = dateCloture.split('/');
    if (parts.length == 3) {
      final day = parts[0];
      final month = parts[1];
      final year = int.parse(parts[2]) + 3;
      return '$day/$month/$year';
    }
    return dateCloture;
  }
}
