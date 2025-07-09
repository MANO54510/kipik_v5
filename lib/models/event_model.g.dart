// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  id: json['id'] as String,
  organiserId: json['organiserId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  type: $enumDecode(_$EventTypeEnumMap, json['type']),
  category: json['category'] as String,
  location: EventLocation.fromJson(json['location'] as Map<String, dynamic>),
  dates: EventDates.fromJson(json['dates'] as Map<String, dynamic>),
  pricing: EventPricing.fromJson(json['pricing'] as Map<String, dynamic>),
  capacity: EventCapacity.fromJson(json['capacity'] as Map<String, dynamic>),
  features:
      (json['features'] as List<dynamic>).map((e) => e as String).toList(),
  settings: EventSettings.fromJson(json['settings'] as Map<String, dynamic>),
  organizer: EventOrganizer.fromJson(json['organizer'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
  'id': instance.id,
  'organiserId': instance.organiserId,
  'title': instance.title,
  'description': instance.description,
  'type': _$EventTypeEnumMap[instance.type]!,
  'category': instance.category,
  'location': instance.location,
  'dates': instance.dates,
  'pricing': instance.pricing,
  'capacity': instance.capacity,
  'features': instance.features,
  'settings': instance.settings,
  'organizer': instance.organizer,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$EventTypeEnumMap = {
  EventType.convention: 'convention',
  EventType.expo: 'expo',
  EventType.contest: 'contest',
  EventType.workshop: 'workshop',
  EventType.meetup: 'meetup',
};

EventLocation _$EventLocationFromJson(Map<String, dynamic> json) =>
    EventLocation(
      venue: json['venue'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      coordinates:
          json['coordinates'] == null
              ? null
              : EventCoordinates.fromJson(
                json['coordinates'] as Map<String, dynamic>,
              ),
    );

Map<String, dynamic> _$EventLocationToJson(EventLocation instance) =>
    <String, dynamic>{
      'venue': instance.venue,
      'address': instance.address,
      'city': instance.city,
      'country': instance.country,
      'coordinates': instance.coordinates,
    };

EventCoordinates _$EventCoordinatesFromJson(Map<String, dynamic> json) =>
    EventCoordinates(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$EventCoordinatesToJson(EventCoordinates instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

EventDates _$EventDatesFromJson(Map<String, dynamic> json) => EventDates(
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  timezone: json['timezone'] as String,
);

Map<String, dynamic> _$EventDatesToJson(EventDates instance) =>
    <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'timezone': instance.timezone,
    };

EventPricing _$EventPricingFromJson(Map<String, dynamic> json) => EventPricing(
  public: EventTicketPricing.fromJson(json['public'] as Map<String, dynamic>),
  professional: EventTicketPricing.fromJson(
    json['professional'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$EventPricingToJson(EventPricing instance) =>
    <String, dynamic>{
      'public': instance.public,
      'professional': instance.professional,
    };

EventTicketPricing _$EventTicketPricingFromJson(Map<String, dynamic> json) =>
    EventTicketPricing(
      dayPass: (json['dayPass'] as num).toInt(),
      weekendPass: (json['weekendPass'] as num).toInt(),
    );

Map<String, dynamic> _$EventTicketPricingToJson(EventTicketPricing instance) =>
    <String, dynamic>{
      'dayPass': instance.dayPass,
      'weekendPass': instance.weekendPass,
    };

EventCapacity _$EventCapacityFromJson(Map<String, dynamic> json) =>
    EventCapacity(
      maxVisitors: (json['maxVisitors'] as num).toInt(),
      maxTattooists: (json['maxTattooists'] as num).toInt(),
      currentRegistrations: (json['currentRegistrations'] as num).toInt(),
      currentApplications: (json['currentApplications'] as num).toInt(),
    );

Map<String, dynamic> _$EventCapacityToJson(EventCapacity instance) =>
    <String, dynamic>{
      'maxVisitors': instance.maxVisitors,
      'maxTattooists': instance.maxTattooists,
      'currentRegistrations': instance.currentRegistrations,
      'currentApplications': instance.currentApplications,
    };

EventSettings _$EventSettingsFromJson(Map<String, dynamic> json) =>
    EventSettings(
      isPublic: json['isPublic'] as bool,
      requiresApproval: json['requiresApproval'] as bool,
      allowsOnlineTicketing: json['allowsOnlineTicketing'] as bool,
      allowsRefunds: json['allowsRefunds'] as bool,
    );

Map<String, dynamic> _$EventSettingsToJson(EventSettings instance) =>
    <String, dynamic>{
      'isPublic': instance.isPublic,
      'requiresApproval': instance.requiresApproval,
      'allowsOnlineTicketing': instance.allowsOnlineTicketing,
      'allowsRefunds': instance.allowsRefunds,
    };

EventOrganizer _$EventOrganizerFromJson(Map<String, dynamic> json) =>
    EventOrganizer(
      name: json['name'] as String,
      contact: EventOrganizerContact.fromJson(
        json['contact'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$EventOrganizerToJson(EventOrganizer instance) =>
    <String, dynamic>{'name': instance.name, 'contact': instance.contact};

EventOrganizerContact _$EventOrganizerContactFromJson(
  Map<String, dynamic> json,
) => EventOrganizerContact(
  email: json['email'] as String,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$EventOrganizerContactToJson(
  EventOrganizerContact instance,
) => <String, dynamic>{'email': instance.email, 'phone': instance.phone};
