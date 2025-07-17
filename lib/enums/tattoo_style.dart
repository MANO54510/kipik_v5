// lib/enums/tattoo_style.dart
import 'package:flutter/material.dart';

enum TattooStyle {
  realism,      // Réalisme
  japanese,     // Japonais
  geometric,    // Géométrique
  traditional,  // Traditionnel
  blackwork,    // Blackwork
  watercolor,   // Aquarelle
  tribal,       // Tribal
  minimalist,   // Minimaliste
}

extension TattooStyleExtension on TattooStyle {
  String get displayName {
    switch (this) {
      case TattooStyle.realism:
        return 'Réalisme';
      case TattooStyle.japanese:
        return 'Japonais';
      case TattooStyle.geometric:
        return 'Géométrique';
      case TattooStyle.traditional:
        return 'Traditionnel';
      case TattooStyle.blackwork:
        return 'Blackwork';
      case TattooStyle.watercolor:
        return 'Aquarelle';
      case TattooStyle.tribal:
        return 'Tribal';
      case TattooStyle.minimalist:
        return 'Minimaliste';
    }
  }
  
  IconData get iconData {
    switch (this) {
      case TattooStyle.realism:
        return Icons.photo;
      case TattooStyle.japanese:
        return Icons.nature;
      case TattooStyle.geometric:
        return Icons.category;
      case TattooStyle.traditional:
        return Icons.flag;
      case TattooStyle.blackwork:
        return Icons.brush;
      case TattooStyle.watercolor:
        return Icons.palette;
      case TattooStyle.tribal:
        return Icons.waves;
      case TattooStyle.minimalist:
        return Icons.minimize;
    }
  }

  // ✅ NOUVELLE PROPRIÉTÉ COLOR MANQUANTE
  Color get color {
    switch (this) {
      case TattooStyle.realism:
        return Colors.blue;
      case TattooStyle.japanese:
        return Colors.red;
      case TattooStyle.geometric:
        return Colors.purple;
      case TattooStyle.traditional:
        return Colors.green;
      case TattooStyle.blackwork:
        return Colors.grey.shade800;
      case TattooStyle.watercolor:
        return Colors.pink;
      case TattooStyle.tribal:
        return Colors.orange;
      case TattooStyle.minimalist:
        return Colors.teal;
    }
  }

  // ✅ MÉTHODE UTILITAIRE POUR OBTENIR UNE COULEUR AVEC OPACITÉ
  Color withOpacity(double opacity) {
    return color.withOpacity(opacity);
  }
}