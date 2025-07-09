// 🎯 STRUCTURE COMPLÈTE DES COLLECTIONS KIPIK
// Toutes créées maintenant, implémentées progressivement
// Version: 1.0
// Dernière mise à jour: 8 juillet 2025

/// Documentation complète des structures de données Firestore pour KIPIK
/// 
/// Ce fichier sert de référence pour:
/// - Structure des collections Firestore
/// - Champs obligatoires et optionnels
/// - Types de données attendus
/// - Relations entre collections
/// - Règles de validation côté client

class KipikCollectionsStructure {
  
  // ===== COLLECTIONS PRIORITÉ 1 - MVP =====

  /// 🏪 SHOPS - Boutiques des tatoueurs
  /// Permet aux clients de découvrir les shops et aux organisateurs de valider
  static Map<String, dynamic> get shopStructure => {
    "id": "shop_123",
    "tattooistId": "user_456", // Propriétaire (String, required)
    "name": "Ink Paradise", // String, required
    "description": "Studio de tatouage spécialisé en réalisme", // String, optional
    "address": {
      "street": "123 rue de la Paix", // String, required
      "city": "Paris", // String, required
      "postalCode": "75001", // String, required
      "country": "France", // String, required
      "coordinates": {
        "latitude": 48.8566, // double, optional
        "longitude": 2.3522 // double, optional
      }
    },
    "contact": {
      "phone": "+33123456789", // String, optional
      "email": "contact@inkparadise.com", // String, optional
      "website": "https://inkparadise.com", // String, optional
      "socialMedia": {
        "instagram": "@inkparadise", // String, optional
        "facebook": "inkparadise" // String, optional
      }
    },
    "specialties": ["Réalisme", "Portrait", "Noir et gris"], // List<String>, required
    "services": [
      {
        "name": "Tatouage custom", // String, required
        "description": "Création sur mesure", // String, optional
        "priceRange": {
          "min": 80, // int, required
          "max": 200, // int, required
          "unit": "hour" // String, required (hour, session, piece)
        }
      }
    ],
    "schedule": {
      "monday": {"open": "09:00", "close": "18:00", "closed": false},
      "tuesday": {"open": "09:00", "close": "18:00", "closed": false},
      "wednesday": {"open": "09:00", "close": "18:00", "closed": false},
      "thursday": {"open": "09:00", "close": "18:00", "closed": false},
      "friday": {"open": "09:00", "close": "18:00", "closed": false},
      "saturday": {"open": "10:00", "close": "17:00", "closed": false},
      "sunday": {"open": "00:00", "close": "00:00", "closed": true}
    },
    "settings": {
      "isPublic": true, // bool, required
      "acceptsWalkIns": false, // bool, required
      "allowsBooking": true, // bool, required
      "allowsGuests": false, // bool, required (Premium feature)
      "maxGuestsPerMonth": 2 // int, optional (Premium feature)
    },
    "stats": {
      "totalTattoos": 150, // int, calculated
      "rating": 4.8, // double, calculated
      "reviewCount": 45 // int, calculated
    },
    "createdAt": "Timestamp", // Timestamp, auto
    "updatedAt": "Timestamp" // Timestamp, auto
  };

  /// 🎨 PORTFOLIOS - Réalisations des tatoueurs
  /// Visibles par clients pour navigation et organisateurs pour validation
  static Map<String, dynamic> get portfolioStructure => {
    "id": "portfolio_123",
    "tattooistId": "user_456", // String, required
    "shopId": "shop_123", // String, optional
    "title": "Portrait réaliste", // String, required
    "description": "Portrait en noir et gris, 4h de travail", // String, optional
    "images": [
      {
        "url": "https://storage.../image1.jpg", // String, required
        "thumbnailUrl": "https://storage.../thumb1.jpg", // String, optional
        "order": 1 // int, required
      }
    ],
    "tags": ["portrait", "réalisme", "noir-et-gris"], // List<String>, optional
    "category": "Réalisme", // String, required
    "style": "Noir et gris", // String, required
    "bodyPart": "Bras", // String, required
    "duration": 4, // int, heures
    "size": {
      "width": 15, // int, cm
      "height": 20 // int, cm
    },
    "settings": {
      "isPublic": true, // bool, required
      "allowComments": true, // bool, required
      "isFeatured": false // bool, required
    },
    "stats": {
      "views": 250, // int, calculated
      "likes": 35, // int, calculated
      "shares": 5 // int, calculated
    },
    "createdAt": "Timestamp", // Timestamp, auto
    "updatedAt": "Timestamp" // Timestamp, auto
  };

  /// 🎪 EVENTS - Événements/Conventions
  /// Gestion complète des événements avec billetterie et candidatures
  static Map<String, dynamic> get eventStructure => {
    "id": "event_123",
    "organiserId": "user_789", // String, required
    "title": "Convention Tattoo Paris 2025", // String, required
    "description": "La plus grande convention de tatouage de France", // String, required
    "type": "convention", // String, required (convention, expo, contest)
    "category": "Tatouage", // String, required
    "location": {
      "venue": "Parc des Expositions", // String, required
      "address": "1 Place de la Porte de Versailles, 75015 Paris", // String, required
      "city": "Paris", // String, required
      "country": "France", // String, required
      "coordinates": {
        "latitude": 48.8306, // double, optional
        "longitude": 2.2878 // double, optional
      }
    },
    "dates": {
      "startDate": "2025-09-15T09:00:00Z", // DateTime, required
      "endDate": "2025-09-17T18:00:00Z", // DateTime, required
      "timezone": "Europe/Paris" // String, required
    },
    "pricing": {
      "public": {
        "dayPass": 25, // int, required
        "weekendPass": 40 // int, required
      },
      "professional": {
        "dayPass": 15, // int, required
        "weekendPass": 25 // int, required
      }
    },
    "capacity": {
      "maxVisitors": 5000, // int, required
      "maxTattooists": 150, // int, required
      "currentRegistrations": 1247, // int, calculated
      "currentApplications": 89 // int, calculated
    },
    "features": [
      "Live tattooing",
      "Competitions", 
      "Workshops",
      "Exhibitions"
    ], // List<String>, optional
    "settings": {
      "isPublic": true, // bool, required
      "requiresApproval": true, // bool, required (pour tatoueurs)
      "allowsOnlineTicketing": true, // bool, required
      "allowsRefunds": true // bool, required
    },
    "organizer": {
      "name": "Paris Tattoo Events", // String, required
      "contact": {
        "email": "contact@paristattoo.com", // String, required
        "phone": "+33123456789" // String, optional
      }
    },
    "createdAt": "Timestamp", // Timestamp, auto
    "updatedAt": "Timestamp" // Timestamp, auto
  };

  /// ⭐ FAVORITES - Tatoueurs favoris des clients
  /// Système de favoris personnel pour chaque client
  static Map<String, dynamic> get favoriteStructure => {
    "id": "fav_123",
    "userId": "client_456", // String, required (client qui ajoute)
    "tattooistId": "tatoueur_789", // String, required (tatoueur favorisé)
    "shopId": "shop_123", // String, optional
    "addedAt": "Timestamp", // Timestamp, auto
    "notes": "Style réalisme parfait pour mon projet", // String, optional (notes privées)
    "tags": ["réalisme", "portrait"], // List<String>, optional (tags personnels)
    "priority": 1 // int, optional (1=haute, 2=moyenne, 3=basse)
  };

  // ===== COLLECTIONS PRIORITÉ 2 - INTERACTIONS =====

  /// 💌 CONTACT_FORMS - Formulaires de contact
  /// Communication entre clients/tatoueurs/organisateurs
  static Map<String, dynamic> get contactFormStructure => {
    "id": "contact_123",
    "fromUserId": "client_456", // String, required
    "toUserId": "tatoueur_789", // String, required
    "type": "project_inquiry", // String, required (project_inquiry, event_question, general)
    "subject": "Demande de devis pour tatouage", // String, required
    "message": "Bonjour, je souhaiterais un tatouage réaliste...", // String, required
    "attachments": ["image1.jpg", "image2.jpg"], // List<String>, optional
    "projectDetails": {
      "style": "Réalisme", // String, optional
      "bodyPart": "Bras", // String, optional
      "size": "Medium", // String, optional
      "budget": {
        "min": 500, // int, optional
        "max": 800 // int, optional
      },
      "timeline": "Dans 2 mois" // String, optional
    },
    "status": "sent", // String, required (sent, read, replied, archived)
    "replies": [
      {
        "fromUserId": "tatoueur_789", // String, required
        "message": "Merci pour votre demande...", // String, required
        "sentAt": "Timestamp" // Timestamp, required
      }
    ],
    "sentAt": "Timestamp", // Timestamp, auto
    "readAt": "Timestamp?" // Timestamp, optional
  };

  /// 🎫 EVENT_REGISTRATIONS - Réservations clients pour événements
  /// Système de billetterie et réservations
  static Map<String, dynamic> get eventRegistrationStructure => {
    "id": "reg_123",
    "eventId": "event_456", // String, required
    "clientId": "client_789", // String, required
    "organiserId": "organizer_123", // String, required
    "ticketType": "weekend_pass", // String, required (day_pass, weekend_pass)
    "ticketCategory": "public", // String, required (public, professional)
    "quantity": 2, // int, required
    "pricing": {
      "unitPrice": 40, // int, required
      "totalPrice": 80, // int, calculated
      "fees": 5, // int, calculated
      "finalPrice": 85 // int, calculated
    },
    "attendees": [
      {
        "name": "John Doe", // String, required
        "email": "john@email.com", // String, required
        "type": "adult" // String, required
      }
    ],
    "payment": {
      "method": "stripe", // String, required
      "paymentIntentId": "pi_123", // String, required
      "status": "paid" // String, required (pending, paid, failed, refunded)
    },
    "status": "confirmed", // String, required (pending, confirmed, cancelled)
    "registeredAt": "Timestamp", // Timestamp, auto
    "confirmedAt": "Timestamp?" // Timestamp, optional
  };

  /// 🏢 EVENT_APPLICATIONS - Candidatures tatoueurs pour événements
  /// Système de candidature et validation pour événements
  static Map<String, dynamic> get eventApplicationStructure => {
    "id": "app_123",
    "eventId": "event_456", // String, required
    "tattooistId": "tatoueur_789", // String, required
    "organiserId": "organizer_123", // String, required
    "shopId": "shop_123", // String, optional
    "application": {
      "motivation": "Je souhaite participer car...", // String, required
      "experience": "5 ans d'expérience en conventions", // String, required
      "specialties": ["Réalisme", "Portrait"], // List<String>, required
      "portfolio": ["portfolio1.jpg", "portfolio2.jpg"], // List<String>, required
      "boothPreferences": {
        "size": "standard", // String, required (small, standard, large)
        "location": "main_hall", // String, optional
        "electricalNeeds": true // bool, required
      }
    },
    "status": "submitted", // String, required (draft, submitted, under_review, accepted, rejected)
    "review": {
      "reviewedBy": "organizer_123", // String, optional
      "notes": "Excellent portfolio, accepté", // String, optional
      "score": 8.5, // double, optional
      "reviewedAt": "Timestamp?" // Timestamp, optional
    },
    "fees": {
      "boothFee": 300, // int, required
      "insurance": 50, // int, required
      "totalFee": 350, // int, calculated
      "paymentStatus": "pending" // String, required (pending, paid, overdue)
    },
    "submittedAt": "Timestamp", // Timestamp, auto
    "reviewedAt": "Timestamp?" // Timestamp, optional
  };

  // ===== COLLECTIONS PRIORITÉ 3 - PREMIUM =====

  /// 🏃‍♂️ GUEST_APPLICATIONS - Candidatures mobilité tatoueur→shop (PREMIUM)
  /// Système de mobilité pour tatoueurs Premium
  static Map<String, dynamic> get guestApplicationStructure => {
    "id": "guest_app_123",
    "tattooistId": "tatoueur_456", // String, required (candidat)
    "shopId": "shop_789", // String, required (shop ciblé)
    "shopOwnerId": "owner_123", // String, required (propriétaire du shop)
    "dates": {
      "startDate": "2025-08-01", // String, required (YYYY-MM-DD)
      "endDate": "2025-08-15", // String, required (YYYY-MM-DD)
      "flexible": true // bool, required
    },
    "application": {
      "motivation": "Je souhaite découvrir votre région...", // String, required
      "portfolio": ["work1.jpg", "work2.jpg"], // List<String>, required
      "experience": "3 ans en guest spots", // String, required
      "specialties": ["Japonais", "Géométrique"], // List<String>, required
      "clientele": "Principalement walk-ins et réservations courtes" // String, optional
    },
    "terms": {
      "proposedSplit": 60, // int, required (% pour le guest)
      "dailyFee": 0, // int, required
      "materialsCovered": false, // bool, required
      "accommodationNeeded": true // bool, required
    },
    "status": "submitted", // String, required (draft, submitted, accepted, declined, expired)
    "response": {
      "respondedBy": "owner_123", // String, optional
      "message": "Votre profil nous intéresse...", // String, optional
      "counterOffer": {
        "split": 55, // int, optional
        "dailyFee": 25 // int, optional
      },
      "respondedAt": "Timestamp?" // Timestamp, optional
    },
    "submittedAt": "Timestamp" // Timestamp, auto
  };

  /// 🏪 GUEST_OFFERS - Propositions shop→tatoueur (PREMIUM)
  /// Propositions de collaboration de shops vers tatoueurs
  static Map<String, dynamic> get guestOfferStructure => {
    "id": "guest_offer_123",
    "shopId": "shop_456", // String, required
    "shopOwnerId": "owner_789", // String, required (qui propose)
    "tattooistId": "tatoueur_123", // String, required (tatoueur ciblé)
    "dates": {
      "startDate": "2025-07-01", // String, required
      "endDate": "2025-07-31", // String, required
      "flexibility": "negotiable" // String, required
    },
    "offer": {
      "message": "Nous serions ravis de vous accueillir...", // String, required
      "reasons": ["Style complémentaire", "Réputation excellente"], // List<String>, optional
      "benefits": [
        "Clientèle fidèle",
        "Matériel haut de gamme", 
        "Logement fourni"
      ] // List<String>, optional
    },
    "terms": {
      "split": 65, // int, required (% pour le guest)
      "dailyFee": 0, // int, required
      "accommodationProvided": true, // bool, required
      "materialsIncluded": true, // bool, required
      "minimumDays": 10 // int, required
    },
    "status": "sent", // String, required (draft, sent, accepted, declined, expired)
    "response": {
      "respondedBy": "tatoueur_123", // String, optional
      "message": "Merci pour cette opportunité...", // String, optional
      "decision": "accepted", // String, optional (accepted, declined, counter_offer)
      "respondedAt": "Timestamp?" // Timestamp, optional
    },
    "sentAt": "Timestamp" // Timestamp, auto
  };

  /// 🤝 GUEST_COLLABORATIONS - Collaborations actives (PREMIUM)
  /// Suivi des collaborations guest en cours et historique
  static Map<String, dynamic> get guestCollaborationStructure => {
    "id": "collab_123",
    "guestTattooistId": "tatoueur_456", // String, required
    "hostShopOwnerId": "owner_789", // String, required
    "shopId": "shop_123", // String, required
    "period": {
      "startDate": "2025-08-01", // String, required
      "endDate": "2025-08-15", // String, required
      "actualStartDate": "2025-08-01", // String, optional
      "actualEndDate": null // String?, optional (null si en cours)
    },
    "agreement": {
      "split": 60, // int, required (% guest)
      "dailyFee": 30, // int, required
      "accommodationProvided": true, // bool, required
      "materialsIncluded": false // bool, required
    },
    "performance": {
      "totalRevenue": 2500, // int, calculated
      "guestShare": 1500, // int, calculated
      "hostShare": 1000, // int, calculated
      "dailyFees": 450, // int, calculated
      "completedTattoos": 12, // int, calculated
      "averageRating": 4.9 // double, calculated
    },
    "status": "active", // String, required (planned, active, completed, terminated)
    "feedback": {
      "guestToHost": {
        "rating": 5, // int, optional (1-5)
        "comment": "Excellent accueil, super équipe", // String, optional
        "submittedAt": "Timestamp?" // Timestamp, optional
      },
      "hostToGuest": {
        "rating": 5, // int, optional (1-5)
        "comment": "Tatoueur professionnel et talentueux", // String, optional
        "submittedAt": "Timestamp?" // Timestamp, optional
      }
    },
    "createdAt": "Timestamp", // Timestamp, auto
    "completedAt": "Timestamp?" // Timestamp, optional
  };

  // ===== COLLECTIONS PRIORITÉ 4 - FONCTIONNALITÉS AVANCÉES =====

  /// ⭐ REVIEWS - Avis clients sur tatoueurs/événements
  /// Système d'avis et notation avec modération
  static Map<String, dynamic> get reviewStructure => {
    "id": "review_123",
    "reviewerId": "client_456", // String, required (qui donne l'avis)
    "targetType": "tatoueur", // String, required (tatoueur, shop, event)
    "targetId": "tatoueur_789", // String, required (ID de la cible)
    "projectId": "project_123", // String, optional (projet lié pour tatoueurs)
    "eventId": "event_456", // String, optional (événement lié pour événements)
    "rating": 5, // int, required (1 à 5 étoiles)
    "aspects": {
      "quality": 5, // int, required
      "professionalism": 5, // int, required
      "cleanliness": 5, // int, required
      "communication": 4, // int, required
      "value": 4 // int, required
    },
    "review": {
      "title": "Excellent travail !", // String, required
      "content": "Très satisfait du résultat, tatouage magnifique...", // String, required
      "images": ["result1.jpg", "result2.jpg"] // List<String>, optional
    },
    "verified": true, // bool, required (vérifié par système)
    "status": "published", // String, required (pending, published, flagged, hidden)
    "helpful": {
      "upvotes": 15, // int, calculated
      "downvotes": 1 // int, calculated
    },
    "response": {
      "fromTargetId": "tatoueur_789", // String, optional
      "message": "Merci beaucoup pour cet avis !", // String, optional
      "respondedAt": "Timestamp?" // Timestamp, optional
    },
    "createdAt": "Timestamp", // Timestamp, auto
    "moderatedAt": "Timestamp?" // Timestamp, optional
  };

  /// 🛒 SHOP_PRODUCTS - Produits des boutiques (E-commerce)
  /// Système e-commerce intégré pour les shops
  static Map<String, dynamic> get shopProductStructure => {
    "id": "product_123",
    "shopId": "shop_456", // String, required
    "tattooistId": "tatoueur_789", // String, required
    "name": "Crème cicatrisante premium", // String, required
    "description": "Crème spécialement formulée pour la cicatrisation des tatouages", // String, required
    "category": "Soins", // String, required (Soins, Bijoux, Vêtements, Art)
    "subcategory": "Cicatrisation", // String, optional
    "images": [
      {
        "url": "https://storage.../product1.jpg", // String, required
        "thumbnailUrl": "https://storage.../thumb1.jpg", // String, optional
        "order": 1 // int, required
      }
    ],
    "pricing": {
      "price": 25.99, // double, required
      "currency": "EUR", // String, required
      "compareAtPrice": 29.99, // double, optional (prix barré)
      "costPrice": 15.00 // double, optional (prix de revient, privé)
    },
    "inventory": {
      "sku": "CREME-CIC-001", // String, required
      "quantity": 50, // int, required
      "lowStockThreshold": 10, // int, required
      "trackInventory": true // bool, required
    },
    "specifications": {
      "brand": "TattooHeal", // String, optional
      "size": "50ml", // String, optional
      "ingredients": "Aloe vera, vitamine E...", // String, optional
      "usage": "Appliquer 2-3 fois par jour" // String, optional
    },
    "shipping": {
      "weight": 60, // int, required (grammes)
      "dimensions": {
        "length": 5, // int, required
        "width": 5, // int, required
        "height": 8 // int, required
      },
      "fragile": false // bool, required
    },
    "seo": {
      "metaTitle": "Crème cicatrisante tatouage - TattooHeal 50ml", // String, optional
      "metaDescription": "Crème spécialisée pour la cicatrisation optimale des tatouages", // String, optional
      "tags": ["cicatrisation", "soin", "tatouage", "crème"] // List<String>, optional
    },
    "status": "active", // String, required (draft, active, archived)
    "stats": {
      "views": 125, // int, calculated
      "sales": 23, // int, calculated
      "revenue": 597.77 // double, calculated
    },
    "createdAt": "Timestamp", // Timestamp, auto
    "updatedAt": "Timestamp" // Timestamp, auto
  };

  /// 🎟️ EVENT_TICKETS - Billets/entrées événements détaillés
  /// Système de billetterie avec QR codes et contrôle d'accès
  static Map<String, dynamic> get eventTicketStructure => {
    "id": "ticket_123",
    "eventId": "event_456", // String, required
    "registrationId": "reg_789", // String, required
    "ticketNumber": "TTX2025-001234", // String, required (unique)
    "qrCode": "base64_qr_code_data", // String, required
    "attendee": {
      "name": "John Doe", // String, required
      "email": "john@email.com", // String, required
      "phone": "+33123456789" // String, optional
    },
    "ticketType": "weekend_pass", // String, required
    "ticketCategory": "public", // String, required
    "pricing": {
      "price": 40, // int, required
      "fees": 5, // int, required
      "total": 45 // int, calculated
    },
    "validity": {
      "validFrom": "2025-09-15T00:00:00Z", // DateTime, required
      "validUntil": "2025-09-17T23:59:59Z", // DateTime, required
      "singleUse": false // bool, required
    },
    "access": {
      "zones": ["main_hall", "food_court", "exhibitions"], // List<String>, required
      "restrictions": [], // List<String>, optional
      "specialAccess": [] // List<String>, optional
    },
    "usage": {
      "checkedIn": false, // bool, calculated
      "checkInTime": null, // DateTime?, calculated
      "checkInLocation": null, // String?, calculated
      "usageCount": 0 // int, calculated
    },
    "status": "valid", // String, required (valid, used, cancelled, refunded)
    "issuedAt": "Timestamp", // Timestamp, auto
    "lastUsedAt": "Timestamp?" // Timestamp, optional
  };

  /// 📅 AVAILABILITY_SLOTS - Créneaux disponibilité tatoueurs
  /// Système de réservation et calendrier intégré
  static Map<String, dynamic> get availabilitySlotStructure => {
    "id": "slot_123",
    "tattooistId": "tatoueur_456", // String, required
    "shopId": "shop_789", // String, required
    "date": "2025-08-15", // String, required (YYYY-MM-DD)
    "timeSlots": [
      {
        "startTime": "09:00", // String, required (HH:mm)
        "endTime": "12:00", // String, required (HH:mm)
        "duration": 180, // int, calculated (minutes)
        "status": "available", // String, required (available, booked, blocked)
        "sessionType": "consultation", // String, required (consultation, small_tattoo, large_session)
        "price": 200, // int, required
        "bookingId": null // String?, optional (si réservé)
      }
    ],
    "settings": {
      "allowOnlineBooking": true, // bool, required
      "requiresDeposit": true, // bool, required
      "depositAmount": 50, // int, optional
      "cancellationPolicy": "24h", // String, required
      "notes": "Merci de venir avec vos références" // String, optional
    },
    "isRecurring": false, // bool, required (si créneau récurrent)
    "recurringPattern": null, // Map?, optional
    "createdAt": "Timestamp", // Timestamp, auto
    "updatedAt": "Timestamp" // Timestamp, auto
  };

  // ===== MÉTHODES UTILITAIRES =====

  /// Retourne la liste de toutes les collections par priorité
  static Map<String, List<String>> get collectionsByPriority => {
    "priorite_1_mvp": [
      "shops",
      "portfolios", 
      "events",
      "favorites"
    ],
    "priorite_2_interactions": [
      "contact_forms",
      "event_registrations",
      "event_applications"
    ],
    "priorite_3_premium": [
      "guest_applications",
      "guest_offers", 
      "guest_collaborations"
    ],
    "priorite_4_avancees": [
      "reviews",
      "shop_products",
      "event_tickets",
      "availability_slots"
    ]
  };

  /// Retourne les collections nécessitant un abonnement Premium
  static List<String> get premiumCollections => [
    "guest_applications",
    "guest_offers",
    "guest_collaborations"
  ];

  /// Retourne les collections nécessitant un abonnement Standard ou Premium
  static List<String> get paidCollections => [
    "shop_products",
    "availability_slots",
    "event_tickets"
  ];

  /// Retourne les collections accessibles pendant la période d'essai
  static List<String> get trialCollections => [
    "shops",
    "portfolios",
    "events", 
    "favorites",
    "contact_forms",
    "event_registrations",
    "event_applications",
    "reviews"
  ];

  /// Valide qu'un utilisateur peut accéder à une collection selon son abonnement
  static bool canAccessCollection(String collection, String? subscription, bool isInTrial) {
    if (isInTrial && trialCollections.contains(collection)) return true;
    if (subscription == 'premium') return true;
    if (subscription == 'standard' && !premiumCollections.contains(collection)) return true;
    return false;
  }
}

/// Énumérations pour les valeurs contrôlées

/// Types d'événements possibles
enum EventType {
  convention,
  expo, 
  contest,
  workshop,
  meetup
}

/// Statuts de candidature pour événements
enum ApplicationStatus {
  draft,
  submitted, 
  under_review,
  accepted,
  rejected,
  expired
}

/// Types de billets pour événements
enum TicketType {
  day_pass,
  weekend_pass,
  vip_pass,
  professional_pass
}

/// Catégories de billets
enum TicketCategory {
  public,
  professional,
  student,
  senior
}

/// Statuts de collaboration guest
enum CollaborationStatus {
  planned,
  active,
  completed,
  terminated,
  cancelled
}

/// Types de session pour availability slots
enum SessionType {
  consultation,
  small_tattoo,
  medium_session,
  large_session,
  touch_up
}

/// Tailles de stand pour événements
enum BoothSize {
  small,
  standard,
  large,
  premium
}