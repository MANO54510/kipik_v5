import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/pages/detail_projet_page.dart';
import 'package:kipik_v5/pages/pro/home_page_pro.dart';

class MesProjetsPage extends StatelessWidget {
  const MesProjetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: DrawerFactory.of(context),
      appBar: CustomAppBarKipik(
        title: 'Mes Projets',
        showBackButton: true,
        useProStyle: true,
        onBackPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePagePro()),
          );
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background_charbon.png', fit: BoxFit.cover),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildProjectList(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(BuildContext context) {
    final projets = [
      {
        'titre': 'Phénix Bras Droit',
        'tatoueur': 'InkMaster',
        'dateDevis': '12/05/2025',
        'statut': 'En attente',
        'montant': 250,
      },
      {
        'titre': 'Dragon Dos Complet',
        'tatoueur': 'DragonInk',
        'dateDevis': '02/06/2025',
        'statut': 'En cours',
        'montant': 1200,
      },
      {
        'titre': 'Lettrage minimaliste',
        'tatoueur': 'LetterArt',
        'dateDevis': '01/04/2025',
        'statut': 'Clôturé',
        'montant': 100,
        'dateCloture': '10/05/2025',
      },
    ];

    return ListView.separated(
      itemCount: projets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final Map<String, dynamic> projet = projets[index];
        final statut = projet['statut'] as String;
        final color = _getStatusColor(statut);
        final icon = _getStatusIcon(statut);

        return Card(
          color: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            title: Text(
              projet['titre'],
              style: const TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tatoueur : ${projet['tatoueur']}'),
                Text('Date demande : ${projet['dateDevis']}'),
                Text('Montant : ${projet['montant']} €'),
                const SizedBox(height: 4),
                if (statut == 'Clôturé' && projet.containsKey('dateCloture'))
                  Text(
                    'Clôturé le ${projet['dateCloture']} (archive jusqu\'au ${_getDateArchivage(projet['dateCloture'])})',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailProjetPage(projetData: projet),
                ),
              );
            },
          ),
        );
      },
    );
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

  IconData _getStatusIcon(String statut) {
    switch (statut) {
      case 'En attente':
        return Icons.hourglass_empty;
      case 'En cours':
        return Icons.work;
      case 'Clôturé':
        return Icons.lock;
      case 'Accepté':
        return Icons.check_circle;
      case 'Refusé':
        return Icons.cancel;
      default:
        return Icons.help_outline;
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