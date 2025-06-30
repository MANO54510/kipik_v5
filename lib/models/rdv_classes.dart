// lib/models/rdv_classes.dart

// Classe pour le tatoueur
class Tatoueur {
  final String nom;
  final String photo;
  final String email;
  final double note;
  final String specialite;

  Tatoueur({
    required this.nom,
    required this.photo,
    required this.email,
    required this.note,
    required this.specialite,
  });
}

// Classe pour le studio
class Studio {
  final String nom;
  final String adresse;
  final double lat;
  final double lng;

  Studio({
    required this.nom,
    required this.adresse,
    required this.lat,
    required this.lng,
  });
}

// Classe principale pour les rendez-vous
class RdvModel {
  final DateTime date;
  final String type;
  final Tatoueur tatoueur;
  final Studio studio;
  final double prix;
  final Duration duree;
  final Duration dureeTrajet;
  final String status;
  final String zoneCorps;
  final String taille;
  final String description;
  final List<String> imagesReference;

  RdvModel({
    required this.date,
    required this.type,
    required this.tatoueur,
    required this.studio,
    required this.prix,
    required this.duree,
    required this.dureeTrajet,
    required this.status,
    required this.zoneCorps,
    required this.taille,
    required this.description,
    required this.imagesReference,
  });
}