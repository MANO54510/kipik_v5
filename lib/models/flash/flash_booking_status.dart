// lib/models/flash/flash_booking_status.dart

/// États possibles d'une réservation de flash
enum FlashBookingStatus {
  /// Demande en attente de validation par le tatoueur
  pending,
  
  /// ✅ AJOUTÉ: Devis envoyé par le tatoueur, en attente de paiement
  quoteSent,
  
  /// ✅ AJOUTÉ: Acompte payé, en attente de validation finale
  depositPaid,
  
  /// RDV confirmé par le tatoueur
  confirmed,
  
  /// RDV terminé avec succès
  completed,
  
  /// RDV annulé par le client
  cancelled,
  
  /// RDV refusé par le tatoueur
  rejected,
  
  /// ✅ AJOUTÉ: Réservation expirée (délai dépassé)
  expired;

  /// Convertir depuis une string
  static FlashBookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return FlashBookingStatus.pending;
      case 'quotesent':
      case 'quote_sent':
        return FlashBookingStatus.quoteSent;
      case 'depositpaid':
      case 'deposit_paid':
        return FlashBookingStatus.depositPaid;
      case 'confirmed':
        return FlashBookingStatus.confirmed;
      case 'completed':
        return FlashBookingStatus.completed;
      case 'cancelled':
        return FlashBookingStatus.cancelled;
      case 'rejected':
        return FlashBookingStatus.rejected;
      case 'expired':
        return FlashBookingStatus.expired;
      default:
        return FlashBookingStatus.pending;
    }
  }

  /// Convertir vers une string
  @override
  String toString() {
    switch (this) {
      case FlashBookingStatus.pending:
        return 'pending';
      case FlashBookingStatus.quoteSent:
        return 'quoteSent';
      case FlashBookingStatus.depositPaid:
        return 'depositPaid';
      case FlashBookingStatus.confirmed:
        return 'confirmed';
      case FlashBookingStatus.completed:
        return 'completed';
      case FlashBookingStatus.cancelled:
        return 'cancelled';
      case FlashBookingStatus.rejected:
        return 'rejected';
      case FlashBookingStatus.expired:
        return 'expired';
    }
  }

  /// Texte affiché à l'utilisateur
  String get displayText {
    switch (this) {
      case FlashBookingStatus.pending:
        return 'En attente';
      case FlashBookingStatus.quoteSent:
        return 'Devis envoyé';
      case FlashBookingStatus.depositPaid:
        return 'Acompte payé';
      case FlashBookingStatus.confirmed:
        return 'Confirmé';
      case FlashBookingStatus.completed:
        return 'Terminé';
      case FlashBookingStatus.cancelled:
        return 'Annulé';
      case FlashBookingStatus.rejected:
        return 'Refusé';
      case FlashBookingStatus.expired:
        return 'Expiré';
    }
  }

  /// ✅ AJOUTÉ: Description détaillée pour l'utilisateur
  String get description {
    switch (this) {
      case FlashBookingStatus.pending:
        return 'Demande en cours de traitement par le tatoueur';
      case FlashBookingStatus.quoteSent:
        return 'Devis personnalisé reçu, en attente de paiement';
      case FlashBookingStatus.depositPaid:
        return 'Acompte payé, validation du tatoueur en cours';
      case FlashBookingStatus.confirmed:
        return 'Rendez-vous confirmé et planifié';
      case FlashBookingStatus.completed:
        return 'Tatouage réalisé avec succès';
      case FlashBookingStatus.cancelled:
        return 'Réservation annulée';
      case FlashBookingStatus.rejected:
        return 'Demande refusée par le tatoueur';
      case FlashBookingStatus.expired:
        return 'Délai de réponse dépassé';
    }
  }

  /// ✅ AJOUTÉ: Couleur pour l'interface utilisateur
  String get colorHex {
    switch (this) {
      case FlashBookingStatus.pending:
        return '#FF9800'; // Orange
      case FlashBookingStatus.quoteSent:
        return '#2196F3'; // Bleu
      case FlashBookingStatus.depositPaid:
        return '#9C27B0'; // Violet
      case FlashBookingStatus.confirmed:
        return '#4CAF50'; // Vert
      case FlashBookingStatus.completed:
        return '#00C853'; // Vert foncé
      case FlashBookingStatus.cancelled:
        return '#9E9E9E'; // Gris
      case FlashBookingStatus.rejected:
        return '#F44336'; // Rouge
      case FlashBookingStatus.expired:
        return '#795548'; // Marron
    }
  }

  /// ✅ AJOUTÉ: Icône Material pour l'UI
  String get iconName {
    switch (this) {
      case FlashBookingStatus.pending:
        return 'hourglass_empty';
      case FlashBookingStatus.quoteSent:
        return 'description';
      case FlashBookingStatus.depositPaid:
        return 'payment';
      case FlashBookingStatus.confirmed:
        return 'check_circle';
      case FlashBookingStatus.completed:
        return 'done_all';
      case FlashBookingStatus.cancelled:
        return 'close';
      case FlashBookingStatus.rejected:
        return 'cancel';
      case FlashBookingStatus.expired:
        return 'schedule';
    }
  }

  /// ✅ AJOUTÉ: Vérifier si le statut est actif (en cours)
  bool get isActive {
    return [
      FlashBookingStatus.pending,
      FlashBookingStatus.quoteSent,
      FlashBookingStatus.depositPaid,
      FlashBookingStatus.confirmed,
    ].contains(this);
  }

  /// ✅ AJOUTÉ: Vérifier si le statut est terminal
  bool get isTerminal {
    return [
      FlashBookingStatus.completed,
      FlashBookingStatus.rejected,
      FlashBookingStatus.cancelled,
      FlashBookingStatus.expired,
    ].contains(this);
  }

  /// ✅ AJOUTÉ: Vérifier si un paiement est impliqué
  bool get hasPayment {
    return [
      FlashBookingStatus.depositPaid,
      FlashBookingStatus.confirmed,
      FlashBookingStatus.completed,
    ].contains(this);
  }

  /// ✅ AJOUTÉ: Vérifier si le client peut agir
  bool get clientCanAct {
    return [
      FlashBookingStatus.quoteSent, // Peut payer l'acompte
    ].contains(this);
  }

  /// ✅ AJOUTÉ: Vérifier si le tatoueur peut agir  
  bool get artistCanAct {
    return [
      FlashBookingStatus.pending, // Peut envoyer devis
      FlashBookingStatus.depositPaid, // Peut valider RDV
    ].contains(this);
  }

  /// ✅ AJOUTÉ: Étape dans le workflow (0-4)
  int get workflowStep {
    switch (this) {
      case FlashBookingStatus.pending:
        return 1; // Étape 1: Demande
      case FlashBookingStatus.quoteSent:
        return 2; // Étape 2: Devis
      case FlashBookingStatus.depositPaid:
        return 3; // Étape 3: Acompte
      case FlashBookingStatus.confirmed:
        return 4; // Étape 4: Confirmation
      case FlashBookingStatus.completed:
        return 5; // Étape 5: Terminé
      default:
        return 0; // États d'erreur
    }
  }

  /// ✅ AJOUTÉ: Prochaines étapes possibles
  List<FlashBookingStatus> get possibleNextStatuses {
    switch (this) {
      case FlashBookingStatus.pending:
        return [FlashBookingStatus.quoteSent, FlashBookingStatus.rejected];
      case FlashBookingStatus.quoteSent:
        return [FlashBookingStatus.depositPaid, FlashBookingStatus.cancelled, FlashBookingStatus.expired];
      case FlashBookingStatus.depositPaid:
        return [FlashBookingStatus.confirmed, FlashBookingStatus.rejected];
      case FlashBookingStatus.confirmed:
        return [FlashBookingStatus.completed, FlashBookingStatus.cancelled];
      default:
        return []; // États terminaux
    }
  }
}