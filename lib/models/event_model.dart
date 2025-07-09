// lib/models/event_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_model.g.dart';

/// 🎪 Modèle pour les événements/conventions
/// Gestion complète des événements avec billetterie et candidatures
@JsonSerializable()
class Event {
  final String id;
  final String organiserId; // Organisateur de l'événement
  final String title;
  final String description;
  final EventType type;
  final String category;
  final EventLocation location;
  final EventDates dates;
  final EventPricing pricing;
  final EventCapacity capacity;
  final List<String> features;
  final EventSettings settings;
  final EventOrganizer organizer;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.organiserId,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.location,
    required this.dates,
    required this.pricing,
    required this.capacity,
    required this.features,
    required this.settings,
    required this.organizer,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory pour création depuis Firestore
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Conversion vers Firestore (sans l'ID)
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  /// JSON serialization
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  Map<String, dynamic> toJson() => _$EventToJson(this);

  /// Copy with pour immutabilité
  Event copyWith({
    String? id,
    String? organiserId,
    String? title,
    String? description,
    EventType? type,
    String? category,
    EventLocation? location,
    EventDates? dates,
    EventPricing? pricing,
    EventCapacity? capacity,
    List<String>? features,
    EventSettings? settings,
    EventOrganizer? organizer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      organiserId: organiserId ?? this.organiserId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      location: location ?? this.location,
      dates: dates ?? this.dates,
      pricing: pricing ?? this.pricing,
      capacity: capacity ?? this.capacity,
      features: features ?? this.features,
      settings: settings ?? this.settings,
      organizer: organizer ?? this.organizer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Getters utilitaires
  bool get isPublic => settings.isPublic;
  bool get requiresApproval => settings.requiresApproval;
  bool get allowsOnlineTicketing => settings.allowsOnlineTicketing;
  bool get allowsRefunds => settings.allowsRefunds;
  
  /// Statut de l'événement
  EventStatus get status {
    final now = DateTime.now();
    if (now.isBefore(dates.startDate)) return EventStatus.upcoming;
    if (now.isAfter(dates.endDate)) return EventStatus.completed;
    return EventStatus.ongoing;
  }

  /// Validation business
  bool get isComplete {
    return title.isNotEmpty &&
           description.isNotEmpty &&
           location.isComplete &&
           dates.isValid &&
           organizer.isComplete;
  }

  /// Durée de l'événement
  Duration get duration {
    return dates.endDate.difference(dates.startDate);
  }

  /// Nombre de jours
  int get durationInDays {
    return duration.inDays + 1; // +1 pour inclure le dernier jour
  }

  /// Places disponibles
  int get availableSpots {
    return capacity.maxVisitors - capacity.currentRegistrations;
  }

  /// Places tatoueurs disponibles
  int get availableTattooistSpots {
    return capacity.maxTattooists - capacity.currentApplications;
  }

  /// Pourcentage de remplissage
  double get fillPercentage {
    if (capacity.maxVisitors == 0) return 0.0;
    return (capacity.currentRegistrations / capacity.maxVisitors) * 100;
  }

  /// Prix minimum
  int get minPrice {
    final prices = [
      pricing.public.dayPass,
      pricing.public.weekendPass,
      pricing.professional.dayPass,
      pricing.professional.weekendPass,
    ];
    return prices.reduce((a, b) => a < b ? a : b);
  }

  @override
  String toString() => 'Event(id: $id, title: $title, organiserId: $organiserId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 📍 Localisation de l'événement
@JsonSerializable()
class EventLocation {
  final String venue;
  final String address;
  final String city;
  final String country;
  final EventCoordinates? coordinates;

  const EventLocation({
    required this.venue,
    required this.address,
    required this.city,
    required this.country,
    this.coordinates,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) => _$EventLocationFromJson(json);
  Map<String, dynamic> toJson() => _$EventLocationToJson(this);

  /// Adresse complète formatée
  String get fullAddress => '$venue, $address, $city, $country';
  
  /// Validation de complétude
  bool get isComplete {
    return venue.isNotEmpty &&
           address.isNotEmpty &&
           city.isNotEmpty &&
           country.isNotEmpty;
  }

  EventLocation copyWith({
    String? venue,
    String? address,
    String? city,
    String? country,
    EventCoordinates? coordinates,
  }) {
    return EventLocation(
      venue: venue ?? this.venue,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

/// 🗺️ Coordonnées GPS de l'événement
@JsonSerializable()
class EventCoordinates {
  final double latitude;
  final double longitude;

  const EventCoordinates({
    required this.latitude,
    required this.longitude,
  });

  factory EventCoordinates.fromJson(Map<String, dynamic> json) => _$EventCoordinatesFromJson(json);
  Map<String, dynamic> toJson() => _$EventCoordinatesToJson(this);

  EventCoordinates copyWith({
    double? latitude,
    double? longitude,
  }) {
    return EventCoordinates(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// 📅 Dates de l'événement
@JsonSerializable()
class EventDates {
  final DateTime startDate;
  final DateTime endDate;
  final String timezone;

  const EventDates({
    required this.startDate,
    required this.endDate,
    required this.timezone,
  });

  factory EventDates.fromJson(Map<String, dynamic> json) => _$EventDatesFromJson(json);
  Map<String, dynamic> toJson() => _$EventDatesToJson(this);

  /// Validation des dates
  bool get isValid => endDate.isAfter(startDate);

  /// Durée de l'événement
  Duration get duration => endDate.difference(startDate);

  /// Formatage des dates
  String get formattedDates {
    final start = startDate;
    final end = endDate;
    
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      // Même jour
      return '${start.day}/${start.month}/${start.year}';
    } else if (start.year == end.year && start.month == end.month) {
      // Même mois
      return '${start.day}-${end.day}/${start.month}/${start.year}';
    } else if (start.year == end.year) {
      // Même année
      return '${start.day}/${start.month} - ${end.day}/${end.month}/${start.year}';
    } else {
      // Années différentes
      return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
    }
  }

  EventDates copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? timezone,
  }) {
    return EventDates(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timezone: timezone ?? this.timezone,
    );
  }
}

/// 💰 Tarification de l'événement
@JsonSerializable()
class EventPricing {
  final EventTicketPricing public;
  final EventTicketPricing professional;

  const EventPricing({
    required this.public,
    required this.professional,
  });

  factory EventPricing.fromJson(Map<String, dynamic> json) => _$EventPricingFromJson(json);
  Map<String, dynamic> toJson() => _$EventPricingToJson(this);

  EventPricing copyWith({
    EventTicketPricing? public,
    EventTicketPricing? professional,
  }) {
    return EventPricing(
      public: public ?? this.public,
      professional: professional ?? this.professional,
    );
  }
}

/// 🎫 Tarifs des billets
@JsonSerializable()
class EventTicketPricing {
  final int dayPass;
  final int weekendPass;

  const EventTicketPricing({
    required this.dayPass,
    required this.weekendPass,
  });

  factory EventTicketPricing.fromJson(Map<String, dynamic> json) => _$EventTicketPricingFromJson(json);
  Map<String, dynamic> toJson() => _$EventTicketPricingToJson(this);

  /// Économie réalisée avec le pass weekend
  int get weekendSavings {
    return (dayPass * 2) - weekendPass;
  }

  /// Pourcentage d'économie
  double get weekendSavingsPercentage {
    final fullPrice = dayPass * 2;
    if (fullPrice == 0) return 0.0;
    return (weekendSavings / fullPrice) * 100;
  }

  EventTicketPricing copyWith({
    int? dayPass,
    int? weekendPass,
  }) {
    return EventTicketPricing(
      dayPass: dayPass ?? this.dayPass,
      weekendPass: weekendPass ?? this.weekendPass,
    );
  }
}

/// 👥 Capacité de l'événement
@JsonSerializable()
class EventCapacity {
  final int maxVisitors;
  final int maxTattooists;
  final int currentRegistrations;
  final int currentApplications;

  const EventCapacity({
    required this.maxVisitors,
    required this.maxTattooists,
    required this.currentRegistrations,
    required this.currentApplications,
  });

  factory EventCapacity.fromJson(Map<String, dynamic> json) => _$EventCapacityFromJson(json);
  Map<String, dynamic> toJson() => _$EventCapacityToJson(this);

  /// Places disponibles visiteurs
  int get availableVisitorSpots => maxVisitors - currentRegistrations;

  /// Places disponibles tatoueurs
  int get availableTattooistSpots => maxTattooists - currentApplications;

  /// Événement complet (visiteurs)
  bool get isVisitorFull => currentRegistrations >= maxVisitors;

  /// Événement complet (tatoueurs)
  bool get isTattooistFull => currentApplications >= maxTattooists;

  /// Pourcentage de remplissage visiteurs
  double get visitorFillPercentage {
    if (maxVisitors == 0) return 0.0;
    return (currentRegistrations / maxVisitors) * 100;
  }

  /// Pourcentage de remplissage tatoueurs
  double get tattooistFillPercentage {
    if (maxTattooists == 0) return 0.0;
    return (currentApplications / maxTattooists) * 100;
  }

  EventCapacity copyWith({
    int? maxVisitors,
    int? maxTattooists,
    int? currentRegistrations,
    int? currentApplications,
  }) {
    return EventCapacity(
      maxVisitors: maxVisitors ?? this.maxVisitors,
      maxTattooists: maxTattooists ?? this.maxTattooists,
      currentRegistrations: currentRegistrations ?? this.currentRegistrations,
      currentApplications: currentApplications ?? this.currentApplications,
    );
  }
}

/// ⚙️ Paramètres de l'événement
@JsonSerializable()
class EventSettings {
  final bool isPublic;
  final bool requiresApproval; // Pour les tatoueurs
  final bool allowsOnlineTicketing;
  final bool allowsRefunds;

  const EventSettings({
    required this.isPublic,
    required this.requiresApproval,
    required this.allowsOnlineTicketing,
    required this.allowsRefunds,
  });

  factory EventSettings.fromJson(Map<String, dynamic> json) => _$EventSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$EventSettingsToJson(this);

  /// Factory pour settings par défaut
  factory EventSettings.defaultSettings() {
    return const EventSettings(
      isPublic: true,
      requiresApproval: true,
      allowsOnlineTicketing: true,
      allowsRefunds: false,
    );
  }

  EventSettings copyWith({
    bool? isPublic,
    bool? requiresApproval,
    bool? allowsOnlineTicketing,
    bool? allowsRefunds,
  }) {
    return EventSettings(
      isPublic: isPublic ?? this.isPublic,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      allowsOnlineTicketing: allowsOnlineTicketing ?? this.allowsOnlineTicketing,
      allowsRefunds: allowsRefunds ?? this.allowsRefunds,
    );
  }
}

/// 👤 Organisateur de l'événement
@JsonSerializable()
class EventOrganizer {
  final String name;
  final EventOrganizerContact contact;

  const EventOrganizer({
    required this.name,
    required this.contact,
  });

  factory EventOrganizer.fromJson(Map<String, dynamic> json) => _$EventOrganizerFromJson(json);
  Map<String, dynamic> toJson() => _$EventOrganizerToJson(this);

  /// Validation de complétude
  bool get isComplete {
    return name.isNotEmpty && contact.isComplete;
  }

  EventOrganizer copyWith({
    String? name,
    EventOrganizerContact? contact,
  }) {
    return EventOrganizer(
      name: name ?? this.name,
      contact: contact ?? this.contact,
    );
  }
}

/// 📞 Contact de l'organisateur
@JsonSerializable()
class EventOrganizerContact {
  final String email;
  final String? phone;

  const EventOrganizerContact({
    required this.email,
    this.phone,
  });

  factory EventOrganizerContact.fromJson(Map<String, dynamic> json) => _$EventOrganizerContactFromJson(json);
  Map<String, dynamic> toJson() => _$EventOrganizerContactToJson(this);

  /// Validation de complétude
  bool get isComplete => email.isNotEmpty;

  EventOrganizerContact copyWith({
    String? email,
    String? phone,
  }) {
    return EventOrganizerContact(
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

/// 🎭 Types d'événements
enum EventType {
  @JsonValue('convention')
  convention,
  @JsonValue('expo')
  expo,
  @JsonValue('contest')
  contest,
  @JsonValue('workshop')
  workshop,
  @JsonValue('meetup')
  meetup;

  String get displayName {
    switch (this) {
      case EventType.convention:
        return 'Convention';
      case EventType.expo:
        return 'Exposition';
      case EventType.contest:
        return 'Concours';
      case EventType.workshop:
        return 'Atelier';
      case EventType.meetup:
        return 'Rencontre';
    }
  }

  String get emoji {
    switch (this) {
      case EventType.convention:
        return '🎪';
      case EventType.expo:
        return '🖼️';
      case EventType.contest:
        return '🏆';
      case EventType.workshop:
        return '🛠️';
      case EventType.meetup:
        return '🤝';
    }
  }
}

/// 📊 Statut de l'événement
enum EventStatus {
  upcoming,
  ongoing,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case EventStatus.upcoming:
        return 'À venir';
      case EventStatus.ongoing:
        return 'En cours';
      case EventStatus.completed:
        return 'Terminé';
      case EventStatus.cancelled:
        return 'Annulé';
    }
  }

  Color get color {
    switch (this) {
      case EventStatus.upcoming:
        return Colors.blue;
      case EventStatus.ongoing:
        return Colors.green;
      case EventStatus.completed:
        return Colors.grey;
      case EventStatus.cancelled:
        return Colors.red;
    }
  }
}

/// 🏷️ Extensions utilitaires
extension EventListExtensions on List<Event> {
  /// Filtrer par ville
  List<Event> filterByCity(String city) {
    return where((event) => 
      event.location.city.toLowerCase().contains(city.toLowerCase())
    ).toList();
  }

  /// Filtrer par type
  List<Event> filterByType(EventType type) {
    return where((event) => event.type == type).toList();
  }

  /// Filtrer par statut
  List<Event> filterByStatus(EventStatus status) {
    return where((event) => event.status == status).toList();
  }

  /// Filtrer par dates (événements dans une période)
  List<Event> filterByDateRange(DateTime start, DateTime end) {
    return where((event) => 
      event.dates.startDate.isBefore(end) && 
      event.dates.endDate.isAfter(start)
    ).toList();
  }

  /// Trier par date (plus proche en premier)
  List<Event> sortByDate() {
    final sorted = List<Event>.from(this);
    sorted.sort((a, b) => a.dates.startDate.compareTo(b.dates.startDate));
    return sorted;
  }

  /// Trier par popularité (taux de remplissage)
  List<Event> sortByPopularity() {
    final sorted = List<Event>.from(this);
    sorted.sort((a, b) => b.fillPercentage.compareTo(a.fillPercentage));
    return sorted;
  }

  /// Événements publics
  List<Event> get publicEvents {
    return where((event) => event.isPublic).toList();
  }

  /// Événements à venir
  List<Event> get upcomingEvents {
    return filterByStatus(EventStatus.upcoming);
  }

  /// Événements en cours
  List<Event> get ongoingEvents {
    return filterByStatus(EventStatus.ongoing);
  }

  /// Événements avec places disponibles
  List<Event> get availableEvents {
    return where((event) => event.availableSpots > 0).toList();
  }

  /// Recherche textuelle
  List<Event> searchText(String query) {
    final lowerQuery = query.toLowerCase();
    return where((event) =>
        event.title.toLowerCase().contains(lowerQuery) ||
        event.description.toLowerCase().contains(lowerQuery) ||
        event.location.city.toLowerCase().contains(lowerQuery) ||
        event.location.venue.toLowerCase().contains(lowerQuery) ||
        event.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}