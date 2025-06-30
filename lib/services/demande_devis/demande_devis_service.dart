// lib/services/demande_devis_service.dart

import 'dart:io';

/// Contrat pour le service de gestion des demandes de devis.
abstract class DemandeDevisService {
  Future<String?> uploadImage(File file, String path);
  Future<void> createDemandeDevis(Map<String, dynamic> data);
}
