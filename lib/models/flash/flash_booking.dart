// lib/models/flash/flash_booking.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'flash_booking_status.dart'; // ✅ Import de l'enum

/// Modèle pour les réservations de flashs - VERSION CORRIGÉE
class FlashBooking {
  final String id;
  final String flashId;
  final String clientId;
  final String tattooArtistId;
  final DateTime requestedDate;
  final String timeSlot;
  final FlashBookingStatus status; // ✅ Utilise le BON enum
  final double totalPrice;
  final double depositAmount;
  final String clientNotes; // ✅ Nom correct
  final String clientPhone;
  final String? artistNotes;
  final String? rejectionReason;
  final String? paymentIntentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashBooking({
    required this.id,
    required this.flashId,
    required this.clientId,
    required this.tattooArtistId,
    required this.requestedDate,
    required this.timeSlot,
    required this.status,
    required this.totalPrice,
    required this.depositAmount,
    this.clientNotes = '', // ✅ Nom correct
    this.clientPhone = '',
    this.artistNotes,
    this.rejectionReason,
    this.paymentIntentId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer depuis les données Firebase
  factory FlashBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>; // ✅ Typé correctement
    
    return FlashBooking(
      id: doc.id,
      flashId: data['flashId'] ?? '',
      clientId: data['clientId'] ?? '',
      tattooArtistId: data['tattooArtistId'] ?? '',
      requestedDate: data['requestedDate'] is Timestamp 
          ? (data['requestedDate'] as Timestamp).toDate()
          : DateTime.parse(data['requestedDate'] ?? DateTime.now().toIso8601String()),
      timeSlot: data['timeSlot'] ?? '',
      status: FlashBookingStatus.fromString(data['status'] ?? 'pending'), // ✅ Utilise le BON enum
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      depositAmount: (data['depositAmount'] ?? 0).toDouble(),
      clientNotes: data['clientNotes'] ?? '', // ✅ Nom correct
      clientPhone: data['clientPhone'] ?? '',
      artistNotes: data['artistNotes'],
      rejectionReason: data['rejectionReason'],
      paymentIntentId: data['paymentIntentId'],
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Créer depuis Map (pour API/JSON)
  factory FlashBooking.fromMap(Map<String, dynamic> map) {
    return FlashBooking(
      id: map['id'] ?? '',
      flashId: map['flashId'] ?? '',
      clientId: map['clientId'] ?? '',
      tattooArtistId: map['tattooArtistId'] ?? '',
      requestedDate: map['requestedDate'] is DateTime 
          ? map['requestedDate']
          : DateTime.parse(map['requestedDate'] ?? DateTime.now().toIso8601String()),
      timeSlot: map['timeSlot'] ?? '',
      status: FlashBookingStatus.fromString(map['status'] ?? 'pending'), // ✅ Utilise le BON enum
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      depositAmount: (map['depositAmount'] ?? 0).toDouble(),
      clientNotes: map['clientNotes'] ?? '', // ✅ Nom correct
      clientPhone: map['clientPhone'] ?? '',
      artistNotes: map['artistNotes'],
      rejectionReason: map['rejectionReason'],
      paymentIntentId: map['paymentIntentId'],
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt']
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is DateTime 
          ? map['updatedAt']
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'flashId': flashId,
      'clientId': clientId,
      'tattooArtistId': tattooArtistId,
      'requestedDate': Timestamp.fromDate(requestedDate),
      'timeSlot': timeSlot,
      'status': status.toString(), // ✅ Conversion enum vers string
      'totalPrice': totalPrice,
      'depositAmount': depositAmount,
      'clientNotes': clientNotes, // ✅ Nom correct
      'clientPhone': clientPhone,
      'artistNotes': artistNotes,
      'rejectionReason': rejectionReason,
      'paymentIntentId': paymentIntentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convertir vers Map simple
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flashId': flashId,
      'clientId': clientId,
      'tattooArtistId': tattooArtistId,
      'requestedDate': requestedDate.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status.toString(), // ✅ Conversion enum vers string
      'totalPrice': totalPrice,
      'depositAmount': depositAmount,
      'clientNotes': clientNotes, // ✅ Nom correct
      'clientPhone': clientPhone,
      'artistNotes': artistNotes,
      'rejectionReason': rejectionReason,
      'paymentIntentId': paymentIntentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Créer une copie avec modifications
  FlashBooking copyWith({
    String? id,
    String? flashId,
    String? clientId,
    String? tattooArtistId,
    DateTime? requestedDate,
    String? timeSlot,
    FlashBookingStatus? status,
    double? totalPrice,
    double? depositAmount,
    String? clientNotes,
    String? clientPhone,
    String? artistNotes,
    String? rejectionReason,
    String? paymentIntentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashBooking(
      id: id ?? this.id,
      flashId: flashId ?? this.flashId,
      clientId: clientId ?? this.clientId,
      tattooArtistId: tattooArtistId ?? this.tattooArtistId,
      requestedDate: requestedDate ?? this.requestedDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      clientNotes: clientNotes ?? this.clientNotes,
      clientPhone: clientPhone ?? this.clientPhone,
      artistNotes: artistNotes ?? this.artistNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ✅ PROPRIÉTÉS UTILITAIRES AJOUTÉES

  /// Prix effectif (alias pour compatibilité)
  double get effectivePrice => totalPrice;

  /// Vérifier si le booking peut être annulé
  bool get canBeCancelled {
    if (status != FlashBookingStatus.confirmed) return false;
    
    final now = DateTime.now();
    final timeDifference = requestedDate.difference(now);
    
    return timeDifference.inHours >= 48; // Annulation possible jusqu'à 48h avant
  }

  /// Vérifier si le booking est dans les prochaines 24h
  bool get isWithin24Hours {
    final now = DateTime.now();
    final timeDifference = requestedDate.difference(now);
    
    return timeDifference.inHours <= 24 && timeDifference.inHours >= 0;
  }

  @override
  String toString() {
    return 'FlashBooking(id: $id, flashId: $flashId, status: ${status.displayText}, date: $requestedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is FlashBooking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}