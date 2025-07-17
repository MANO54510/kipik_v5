// lib/enums/convention_enums.dart
import 'package:flutter/material.dart';

enum StandStatus {
  available,    // Disponible à la réservation
  booked,       // Réservé mais pas encore occupé
  occupied,     // Actuellement occupé par un tatoueur
  maintenance,  // En maintenance, indisponible
}

enum MapMode {
  organizer,    // Mode organisateur - gestion complète
  tattooer,     // Mode tatoueur - vue de son stand + concurrence
  visitor,      // Mode visiteur - recherche et réservation
}

enum LayoutElement {
  stage,        // Scène principale
  bar,          // Bar/buvette
  toilet,       // Sanitaires
  storage,      // Stockage/vestiaire
  foodTruck,    // Food truck
  entrance,     // Entrée principale
  exit,         // Sortie
  pillar,       // Pilier/obstacle
  emergency,    // Sortie de secours
}

enum StandType {
  tattoo,       // Stand tatoueur
  merchant,     // Stand marchand
}

enum ZoneType {
  premium,      // Zone premium (près entrée, visible)
  standard,     // Zone standard
  discount,     // Zone moins chère (fond, coin)
  forbidden,    // Zone interdite
}

extension StandStatusExtension on StandStatus {
  String get displayName {
    switch (this) {
      case StandStatus.available:
        return 'Disponible';
      case StandStatus.booked:
        return 'Réservé';
      case StandStatus.occupied:
        return 'Occupé';
      case StandStatus.maintenance:
        return 'Maintenance';
    }
  }
  
  Color get statusColor {
    switch (this) {
      case StandStatus.available:
        return Colors.green;
      case StandStatus.booked:
        return Colors.orange;
      case StandStatus.occupied:
        return Colors.red;
      case StandStatus.maintenance:
        return Colors.grey;
    }
  }
}