// lib/models/quote_request.dart

enum QuoteStatus { 
  Pending, 
  Quoted, 
  Expired, 
  Accepted, 
  Refused 
}

class QuoteRequest {
  final String id;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String tattooistId;
  final String tattooistName;
  final String projectTitle;
  final String style;
  final String location;
  final String description;
  final double? budget;
  final double? totalPrice;
  final DateTime createdAt;
  final DateTime? proRespondBy;
  final DateTime? clientRespondBy;
  final QuoteStatus status;
  final List<Map<String, dynamic>> sessions;
  final Map<String, dynamic> paymentTerms;
  final List<String> referenceImages;
  final List<Map<String, dynamic>> requiredDocuments;

  const QuoteRequest({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.tattooistId,
    required this.tattooistName,
    required this.projectTitle,
    required this.style,
    required this.location,
    required this.description,
    this.budget,
    this.totalPrice,
    required this.createdAt,
    this.proRespondBy,
    this.clientRespondBy,
    required this.status,
    this.sessions = const [],
    this.paymentTerms = const {},
    this.referenceImages = const [],
    this.requiredDocuments = const [],
  });

  // Factory pour créer depuis Firestore
  factory QuoteRequest.fromFirestore(Map<String, dynamic> data, String id) {
    return QuoteRequest(
      id: id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      tattooistId: data['tattooistId'] ?? '',
      tattooistName: data['tattooistName'] ?? '',
      projectTitle: data['projectTitle'] ?? '',
      style: data['style'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      budget: (data['budget'] as num?)?.toDouble(),
      totalPrice: (data['totalPrice'] as num?)?.toDouble(),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      proRespondBy: _parseDateTime(data['proRespondBy']),
      clientRespondBy: _parseDateTime(data['clientRespondBy']),
      status: _parseStatus(data['status']),
      sessions: List<Map<String, dynamic>>.from(data['sessions'] ?? []),
      paymentTerms: Map<String, dynamic>.from(data['paymentTerms'] ?? {}),
      referenceImages: List<String>.from(data['referenceImages'] ?? []),
      requiredDocuments: List<Map<String, dynamic>>.from(data['requiredDocuments'] ?? []),
    );
  }

  // Convertir vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'tattooistId': tattooistId,
      'tattooistName': tattooistName,
      'projectTitle': projectTitle,
      'style': style,
      'location': location,
      'description': description,
      'budget': budget,
      'totalPrice': totalPrice,
      'createdAt': createdAt.toIso8601String(),
      'proRespondBy': proRespondBy?.toIso8601String(),
      'clientRespondBy': clientRespondBy?.toIso8601String(),
      'status': status.name,
      'sessions': sessions,
      'paymentTerms': paymentTerms,
      'referenceImages': referenceImages,
      'requiredDocuments': requiredDocuments,
    };
  }

  // ✅ Méthode copyWith OBLIGATOIRE pour le service
  QuoteRequest copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? tattooistId,
    String? tattooistName,
    String? projectTitle,
    String? style,
    String? location,
    String? description,
    double? budget,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? proRespondBy,
    DateTime? clientRespondBy,
    QuoteStatus? status,
    List<Map<String, dynamic>>? sessions,
    Map<String, dynamic>? paymentTerms,
    List<String>? referenceImages,
    List<Map<String, dynamic>>? requiredDocuments,
  }) {
    return QuoteRequest(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      tattooistId: tattooistId ?? this.tattooistId,
      tattooistName: tattooistName ?? this.tattooistName,
      projectTitle: projectTitle ?? this.projectTitle,
      style: style ?? this.style,
      location: location ?? this.location,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      proRespondBy: proRespondBy ?? this.proRespondBy,
      clientRespondBy: clientRespondBy ?? this.clientRespondBy,
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      referenceImages: referenceImages ?? this.referenceImages,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
    );
  }

  // Méthodes utilitaires privées
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static QuoteStatus _parseStatus(dynamic value) {
    if (value == null) return QuoteStatus.Pending;
    if (value is QuoteStatus) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'pending':
          return QuoteStatus.Pending;
        case 'quoted':
          return QuoteStatus.Quoted;
        case 'expired':
          return QuoteStatus.Expired;
        case 'accepted':
          return QuoteStatus.Accepted;
        case 'refused':
          return QuoteStatus.Refused;
        default:
          return QuoteStatus.Pending;
      }
    }
    return QuoteStatus.Pending;
  }

  // Getters utiles
  bool get isPending => status == QuoteStatus.Pending;
  bool get isQuoted => status == QuoteStatus.Quoted;
  bool get isAccepted => status == QuoteStatus.Accepted;
  bool get isRefused => status == QuoteStatus.Refused;
  bool get isExpired => status == QuoteStatus.Expired;

  bool get hasPrice => totalPrice != null && totalPrice! > 0;
  bool get hasSessions => sessions.isNotEmpty;
  bool get hasPaymentTerms => paymentTerms.isNotEmpty;
  bool get hasDocuments => requiredDocuments.isNotEmpty;

  String get statusDisplayName {
    switch (status) {
      case QuoteStatus.Pending:
        return 'En attente';
      case QuoteStatus.Quoted:
        return 'Devis envoyé';
      case QuoteStatus.Accepted:
        return 'Accepté';
      case QuoteStatus.Refused:
        return 'Refusé';
      case QuoteStatus.Expired:
        return 'Expiré';
    }
  }

  @override
  String toString() {
    return 'QuoteRequest(id: $id, projectTitle: $projectTitle, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuoteRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}