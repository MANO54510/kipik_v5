// lib/models/project_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum pour les statuts de projet
enum ProjectStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  onHold;

  static ProjectStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'en_attente':
        return ProjectStatus.pending;
      case 'accepted':
      case 'accepte':
        return ProjectStatus.accepted;
      case 'inprogress':
      case 'in_progress':
      case 'en_cours':
        return ProjectStatus.inProgress;
      case 'completed':
      case 'termine':
        return ProjectStatus.completed;
      case 'cancelled':
      case 'annule':
        return ProjectStatus.cancelled;
      case 'onhold':
      case 'on_hold':
      case 'en_pause':
        return ProjectStatus.onHold;
      default:
        return ProjectStatus.pending;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ProjectStatus.pending:
        return 'pending';
      case ProjectStatus.accepted:
        return 'accepted';
      case ProjectStatus.inProgress:
        return 'inProgress';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.cancelled:
        return 'cancelled';
      case ProjectStatus.onHold:
        return 'onHold';
    }
  }

  String get displayName {
    switch (this) {
      case ProjectStatus.pending:
        return 'En attente';
      case ProjectStatus.accepted:
        return 'Accepté';
      case ProjectStatus.inProgress:
        return 'En cours';
      case ProjectStatus.completed:
        return 'Terminé';
      case ProjectStatus.cancelled:
        return 'Annulé';
      case ProjectStatus.onHold:
        return 'En pause';
    }
  }
}

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String tattooistId;
  final String tattooistName;
  final ProjectStatus status;
  final String category;
  final String bodyPart;
  final String size;
  final String style;
  final List<String> colors;
  final double? budget;
  final double? estimatedPrice;
  final double? finalPrice;
  final List<String> referenceImages;
  final List<String> sketchImages;
  final List<String> finalImages;
  final DateTime? appointmentDate;
  final DateTime? completionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String notes;
  final bool isPublic;
  final List<String> tags;
  final int? duration;
  final String difficulty;
  final String location;
  final double? deposit;
  final bool depositPaid;
  final double? rating;
  final String? review;
  final DateTime? lastChatActivity;
  
  // Propriétés pour compatibilité avec votre ancien modèle
  final List<Map<String, dynamic>> sessions;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.tattooistId,
    required this.tattooistName,
    required this.status,
    required this.category,
    required this.bodyPart,
    required this.size,
    required this.style,
    required this.colors,
    this.budget,
    this.estimatedPrice,
    this.finalPrice,
    required this.referenceImages,
    required this.sketchImages,
    required this.finalImages,
    this.appointmentDate,
    this.completionDate,
    required this.createdAt,
    required this.updatedAt,
    required this.notes,
    required this.isPublic,
    required this.tags,
    this.duration,
    required this.difficulty,
    required this.location,
    this.deposit,
    required this.depositPaid,
    this.rating,
    this.review,
    this.lastChatActivity,
    this.sessions = const [],
  });

  // Factory pour créer depuis Firestore (nouveau format)
  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ProjectModel(
      id: doc.id,
      title: data['title'] ?? data['titre'] ?? '',
      description: data['description'] ?? data['style'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      tattooistId: data['tattooistId'] ?? '',
      tattooistName: data['tattooistName'] ?? data['tatoueur'] ?? '',
      status: ProjectStatus.fromString(data['status'] ?? data['statut'] ?? 'pending'),
      category: data['category'] ?? data['style'] ?? '',
      bodyPart: data['bodyPart'] ?? data['endroit'] ?? '',
      size: data['size'] ?? '',
      style: data['style'] ?? '',
      colors: List<String>.from(data['colors'] ?? []),
      budget: (data['budget'] ?? data['montant'])?.toDouble(),
      estimatedPrice: (data['estimatedPrice'] ?? data['montant'])?.toDouble(),
      finalPrice: (data['finalPrice'] ?? data['montant'])?.toDouble(),
      referenceImages: List<String>.from(data['referenceImages'] ?? []),
      sketchImages: List<String>.from(data['sketchImages'] ?? []),
      finalImages: List<String>.from(data['finalImages'] ?? []),
      appointmentDate: _parseDateTime(data['appointmentDate']),
      completionDate: _parseDateTime(data['completionDate']) ?? _parseDateTime(data['dateCloture']),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
      notes: data['notes'] ?? '',
      isPublic: data['isPublic'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      duration: data['duration'],
      difficulty: data['difficulty'] ?? 'medium',
      location: data['location'] ?? data['endroit'] ?? '',
      deposit: (data['deposit'] ?? data['acompte'])?.toDouble(),
      depositPaid: data['depositPaid'] ?? (data['acompte'] != null && data['acompte'] > 0),
      rating: data['rating']?.toDouble(),
      review: data['review'],
      lastChatActivity: _parseDateTime(data['lastChatActivity']),
      sessions: (data['sessions'] as List<dynamic>?)
              ?.map((session) => Map<String, dynamic>.from(session))
              .toList() ??
          [],
    );
  }

  /// Factory pour withConverter - Version optimisée
  factory ProjectModel.fromMap(String id, Map<String, dynamic> data) {
    return ProjectModel(
      id: id,
      title: data['title'] ?? data['titre'] ?? '',
      description: data['description'] ?? data['style'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      tattooistId: data['tattooistId'] ?? '',
      tattooistName: data['tattooistName'] ?? data['tatoueur'] ?? '',
      status: ProjectStatus.fromString(data['status'] ?? data['statut'] ?? 'pending'),
      category: data['category'] ?? data['style'] ?? '',
      bodyPart: data['bodyPart'] ?? data['endroit'] ?? '',
      size: data['size'] ?? '',
      style: data['style'] ?? '',
      colors: List<String>.from(data['colors'] ?? []),
      budget: (data['budget'] ?? data['montant'])?.toDouble(),
      estimatedPrice: (data['estimatedPrice'] ?? data['montant'])?.toDouble(),
      finalPrice: (data['finalPrice'] ?? data['montant'])?.toDouble(),
      referenceImages: List<String>.from(data['referenceImages'] ?? []),
      sketchImages: List<String>.from(data['sketchImages'] ?? []),
      finalImages: List<String>.from(data['finalImages'] ?? []),
      appointmentDate: _parseDateTime(data['appointmentDate']),
      completionDate: _parseDateTime(data['completionDate']) ?? _parseDateTime(data['dateCloture']),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
      notes: data['notes'] ?? '',
      isPublic: data['isPublic'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      duration: data['duration'],
      difficulty: data['difficulty'] ?? 'medium',
      location: data['location'] ?? data['endroit'] ?? '',
      deposit: (data['deposit'] ?? data['acompte'])?.toDouble(),
      depositPaid: data['depositPaid'] ?? (data['acompte'] != null && data['acompte'] > 0),
      rating: data['rating']?.toDouble(),
      review: data['review'],
      lastChatActivity: _parseDateTime(data['lastChatActivity']),
      sessions: (data['sessions'] as List<dynamic>?)
              ?.map((session) => Map<String, dynamic>.from(session))
              .toList() ??
          [],
    );
  }

  // Factory pour créer depuis votre ancien format
  factory ProjectModel.fromLegacyMap(Map<String, dynamic> data, String id) {
    return ProjectModel(
      id: id,
      title: data['titre'] ?? '',
      description: data['style'] ?? '',
      clientId: '',
      clientName: '',
      clientEmail: '',
      tattooistId: '',
      tattooistName: data['tatoueur'] ?? '',
      status: ProjectStatus.fromString(data['statut'] ?? 'pending'),
      category: data['style'] ?? '',
      bodyPart: data['endroit'] ?? '',
      size: '',
      style: data['style'] ?? '',
      colors: [],
      budget: (data['montant'] ?? 0).toDouble(),
      estimatedPrice: (data['montant'] ?? 0).toDouble(),
      finalPrice: (data['montant'] ?? 0).toDouble(),
      referenceImages: [],
      sketchImages: [],
      finalImages: [],
      appointmentDate: null,
      completionDate: _parseStringDate(data['dateCloture']),
      createdAt: _parseStringDate(data['dateDevis']) ?? DateTime.now(),
      updatedAt: DateTime.now(),
      notes: '',
      isPublic: false,
      tags: [],
      duration: null,
      difficulty: 'medium',
      location: data['endroit'] ?? '',
      deposit: (data['acompte'] ?? 0).toDouble(),
      depositPaid: (data['acompte'] ?? 0) > 0,
      rating: null,
      review: null,
      lastChatActivity: null,
      sessions: (data['sessions'] as List<dynamic>?)
              ?.map((session) => Map<String, dynamic>.from(session))
              .toList() ??
          [],
    );
  }

  // Méthodes utilitaires pour parsing des dates
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is String) {
      return DateTime.tryParse(dateValue);
    }
    
    return null;
  }

  static DateTime? _parseStringDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    return DateTime.tryParse(dateString);
  }

  // Convertir vers Map pour Firestore (nouveau format)
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'tattooistId': tattooistId,
      'tattooistName': tattooistName,
      'status': status.toString(),
      'category': category,
      'bodyPart': bodyPart,
      'size': size,
      'style': style,
      'colors': colors,
      'budget': budget,
      'estimatedPrice': estimatedPrice,
      'finalPrice': finalPrice,
      'referenceImages': referenceImages,
      'sketchImages': sketchImages,
      'finalImages': finalImages,
      'appointmentDate': appointmentDate != null ? Timestamp.fromDate(appointmentDate!) : null,
      'completionDate': completionDate != null ? Timestamp.fromDate(completionDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
      'isPublic': isPublic,
      'tags': tags,
      'duration': duration,
      'difficulty': difficulty,
      'location': location,
      'deposit': deposit,
      'depositPaid': depositPaid,
      'rating': rating,
      'review': review,
      'lastChatActivity': lastChatActivity != null ? Timestamp.fromDate(lastChatActivity!) : null,
      'sessions': sessions,
    };
  }

  /// Méthode pour withConverter - Version optimisée
  Map<String, dynamic> toMap() {
    return toFirestore();
  }

  // Convertir vers Map pour compatibilité avec ancien format
  Map<String, dynamic> toLegacyMap() {
    return {
      'titre': title,
      'style': style,
      'endroit': bodyPart.isNotEmpty ? bodyPart : location,
      'tatoueur': tattooistName,
      'montant': finalPrice ?? estimatedPrice ?? budget ?? 0.0,
      'acompte': deposit ?? 0.0,
      'statut': status.toString(),
      'dateDevis': createdAt.toIso8601String(),
      'dateCloture': completionDate?.toIso8601String(),
      'sessions': sessions,
    };
  }

  // Créer une copie avec modifications
  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? tattooistId,
    String? tattooistName,
    ProjectStatus? status,
    String? category,
    String? bodyPart,
    String? size,
    String? style,
    List<String>? colors,
    double? budget,
    double? estimatedPrice,
    double? finalPrice,
    List<String>? referenceImages,
    List<String>? sketchImages,
    List<String>? finalImages,
    DateTime? appointmentDate,
    DateTime? completionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? isPublic,
    List<String>? tags,
    int? duration,
    String? difficulty,
    String? location,
    double? deposit,
    bool? depositPaid,
    double? rating,
    String? review,
    DateTime? lastChatActivity,
    List<Map<String, dynamic>>? sessions,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      tattooistId: tattooistId ?? this.tattooistId,
      tattooistName: tattooistName ?? this.tattooistName,
      status: status ?? this.status,
      category: category ?? this.category,
      bodyPart: bodyPart ?? this.bodyPart,
      size: size ?? this.size,
      style: style ?? this.style,
      colors: colors ?? this.colors,
      budget: budget ?? this.budget,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      referenceImages: referenceImages ?? this.referenceImages,
      sketchImages: sketchImages ?? this.sketchImages,
      finalImages: finalImages ?? this.finalImages,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      completionDate: completionDate ?? this.completionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      location: location ?? this.location,
      deposit: deposit ?? this.deposit,
      depositPaid: depositPaid ?? this.depositPaid,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      lastChatActivity: lastChatActivity ?? this.lastChatActivity,
      sessions: sessions ?? this.sessions,
    );
  }

  // GETTERS POUR COMPATIBILITÉ AVEC VOTRE ANCIEN CODE
  String get titre => title;
  String get endroit => bodyPart.isNotEmpty ? bodyPart : location;
  String get tatoueur => tattooistName;
  double get montant => finalPrice ?? estimatedPrice ?? budget ?? 0.0;
  double get acompte => deposit ?? 0.0;
  String get statut => status.toString();
  String get dateDevis => createdAt.toIso8601String();
  String? get dateCloture => completionDate?.toIso8601String();

  @override
  String toString() {
    return 'ProjectModel(id: $id, title: $title, status: ${status.displayName}, tatoueur: $tattooistName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}