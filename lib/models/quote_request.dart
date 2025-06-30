enum QuoteStatus { Pending, Quoted, Expired, Accepted, Refused }

class QuoteRequest {
  final String id;
  final String clientName;
  final DateTime createdAt;
  DateTime? proRespondBy;    // createdAt + 48h
  DateTime? clientRespondBy; // après envoi du devis
  QuoteStatus status;
  // TODO: ajouter fields devis (prix, description…)

  QuoteRequest({
    required this.id,
    required this.clientName,
    required this.createdAt,
    this.proRespondBy,
    this.clientRespondBy,
    this.status = QuoteStatus.Pending,
  });
}
