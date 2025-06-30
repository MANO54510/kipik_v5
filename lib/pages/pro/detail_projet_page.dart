// lib/pages/pro/detail_projet_page.dart

import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../services/project/project_service.dart';

class DetailProjetPage extends StatefulWidget {
  final String projectId;
  final ProjectService projectService;

  const DetailProjetPage({
    Key? key,
    required this.projectId,
    required this.projectService,
  }) : super(key: key);

  @override
  State<DetailProjetPage> createState() => _DetailProjetPageState();
}

class _DetailProjetPageState extends State<DetailProjetPage> {
  late Future<ProjectModel?> _futureProject;

  @override
  void initState() {
    super.initState();
    _futureProject = widget.projectService.fetchProjectById(widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du projet'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<ProjectModel?>(
        future: _futureProject,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(child: Text('Impossible de charger le projet.'));
          }
          final p = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.titre, style: const TextStyle(fontSize: 24, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Style : ${p.style}', style: const TextStyle(color: Colors.white70)),
                Text('Endroit : ${p.endroit}', style: const TextStyle(color: Colors.white70)),
                Text('Statut : ${p.statut}', style: const TextStyle(color: Colors.white70)),
                const Divider(color: Colors.white24),
                Text('Devis : ${p.dateDevis} • Montant : €${p.montant}', style: const TextStyle(color: Colors.white)),
                if (p.dateCloture != null)
                  Text('Clôturé : ${p.dateCloture}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                const Text('Sessions', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 8),
                ...p.sessions.map((s) {
                  return Card(
                    color: Colors.grey[850],
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(s['date'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text(s['commentaire'], style: const TextStyle(color: Colors.white70)),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
