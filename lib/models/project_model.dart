import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String titre;
  final String style;
  final String endroit;
  final String tatoueur;
  final double montant;
  final double acompte;
  final String statut;
  final String dateDevis;
  final String? dateCloture;
  final List<Map<String, dynamic>> sessions;

  ProjectModel({
    required this.id,
    required this.titre,
    required this.style,
    required this.endroit,
    required this.tatoueur,
    required this.montant,
    required this.acompte,
    required this.statut,
    required this.dateDevis,
    this.dateCloture,
    required this.sessions,
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ProjectModel(
      id: doc.id,
      titre: data['titre'] ?? '',
      style: data['style'] ?? '',
      endroit: data['endroit'] ?? '',
      tatoueur: data['tatoueur'] ?? '',
      montant: (data['montant'] ?? 0).toDouble(),
      acompte: (data['acompte'] ?? 0).toDouble(),
      statut: data['statut'] ?? '',
      dateDevis: data['dateDevis'] ?? '',
      dateCloture: data['dateCloture'],
      sessions: (data['sessions'] as List<dynamic>?)
              ?.map((session) => Map<String, dynamic>.from(session))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'style': style,
      'endroit': endroit,
      'tatoueur': tatoueur,
      'montant': montant,
      'acompte': acompte,
      'statut': statut,
      'dateDevis': dateDevis,
      'dateCloture': dateCloture,
      'sessions': sessions,
    };
  }
}
