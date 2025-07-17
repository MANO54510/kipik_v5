// lib/enums/guest_enums.dart

import 'package:flutter/material.dart';

enum GuestRequestStatus {
  draft,        // Brouillon, pas encore envoyé
  pending,      // En attente de réponse
  negotiation,  // En négociation
  accepted,     // Accepté
  rejected,     // Refusé
  cancelled,    // Annulé
  completed,    // Terminé avec succès
}

enum GuestType {
  incoming,     // Guest qui vient dans mon studio
  outgoing,     // Moi qui vais en guest ailleurs
}

enum PaymentStatus {
  pending,      // En attente de paiement
  partial,      // Partiellement payé
  paid,         // Entièrement payé
  refunded,     // Remboursé
  disputed,     // En litige
}

extension GuestRequestStatusExtension on GuestRequestStatus {
  String get displayName {
    switch (this) {
      case GuestRequestStatus.draft:
        return 'Brouillon';
      case GuestRequestStatus.pending:
        return 'En attente';
      case GuestRequestStatus.negotiation:
        return 'Négociation';
      case GuestRequestStatus.accepted:
        return 'Accepté';
      case GuestRequestStatus.rejected:
        return 'Refusé';
      case GuestRequestStatus.cancelled:
        return 'Annulé';
      case GuestRequestStatus.completed:
        return 'Terminé';
    }
  }
  
  Color get color {
    switch (this) {
      case GuestRequestStatus.draft:
        return Colors.grey;
      case GuestRequestStatus.pending:
        return Colors.orange;
      case GuestRequestStatus.negotiation:
        return Colors.blue;
      case GuestRequestStatus.accepted:
        return Colors.green;
      case GuestRequestStatus.rejected:
        return Colors.red;
      case GuestRequestStatus.cancelled:
        return Colors.red.shade300;
      case GuestRequestStatus.completed:
        return Colors.green.shade700;
    }
  }
  
  bool get isActive {
    return this == GuestRequestStatus.accepted || 
           this == GuestRequestStatus.negotiation;
  }
  
  bool get canEdit {
    return this == GuestRequestStatus.draft || 
           this == GuestRequestStatus.negotiation;
  }
}