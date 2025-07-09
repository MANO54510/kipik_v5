// lib/services/firebase_collections_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import '../core/database_manager.dart';

/// 🏗️ Service pour créer et initialiser les collections business KIPIK
/// Crée les collections manquantes : shops, portfolios, events, favorites, etc.
class FirebaseCollectionsService {
  static final FirebaseCollectionsService _instance = FirebaseCollectionsService._internal();
  factory FirebaseCollectionsService() => _instance;
  FirebaseCollectionsService._internal();

  /// ✅ CORRECTION: Utiliser la base nommée 'kipik' au lieu de 'default'
  FirebaseFirestore get _firestore {
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'kipik',
    );
  }

  /// 🎯 Créer toutes les collections business manquantes
  Future<void> createMissingCollections() async {
    print('🏗️ Création des collections business manquantes...');
    
    try {
      // ✅ CORRECTION: Utiliser _firestore au lieu de FirebaseFirestore.instance
      final firestore = _firestore;
      
      // 🏪 1. SHOPS - Boutiques tatoueurs
      await _createShopsCollection(firestore);
      
      // 🎨 2. PORTFOLIOS - Réalisations tatoueurs  
      await _createPortfoliosCollection(firestore);
      
      // 🎪 3. EVENTS - Événements/Conventions
      await _createEventsCollection(firestore);
      
      // ⭐ 4. FAVORITES - Favoris clients
      await _createFavoritesCollection(firestore);
      
      // 💌 5. CONTACT_FORMS - Formulaires de contact
      await _createContactFormsCollection(firestore);
      
      // 🎫 6. EVENT_REGISTRATIONS - Réservations événements
      await _createEventRegistrationsCollection(firestore);
      
      // 🏢 7. EVENT_APPLICATIONS - Candidatures événements
      await _createEventApplicationsCollection(firestore);

      // 🏃‍♂️ 8. GUEST SYSTEM - Collections Premium
      await _createGuestSystemCollections(firestore);

      print('🎉 Toutes les collections business ont été créées avec succès !');
      
    } catch (e) {
      print('❌ Erreur création collections: $e');
      rethrow;
    }
  }

  /// 🏪 Créer collection SHOPS
  Future<void> _createShopsCollection(FirebaseFirestore firestore) async {
    await firestore
        .collection('shops')
        .doc('demo_shop_123')
        .set({
      'id': 'demo_shop_123',
      'tattooistId': 'demo_tatoueur_123',
      'name': 'Ink Paradise',
      'description': 'Boutique de tatouage moderne dans le centre-ville',
      'address': '123 Rue de la Tattoo, Paris',
      'phone': '+33123456789',
      'email': 'contact@inkparadise.fr',
      'website': 'https://inkparadise.fr',
      'isPublic': true,
      'isOpenToGuests': false,
      'categories': ['traditionnel', 'realiste'],
      'priceRange': 'medium',
      'openingHours': {
        'monday': '10:00-18:00',
        'tuesday': '10:00-18:00',
        'wednesday': '10:00-18:00',
        'thursday': '10:00-18:00',
        'friday': '10:00-20:00',
        'saturday': '10:00-20:00',
        'sunday': 'closed'
      },
      'socialMedia': {
        'instagram': '@inkparadise_paris',
        'facebook': 'InkParadiseParis'
      },
      'photos': ['shop_photo_1.jpg', 'shop_photo_2.jpg'],
      'rating': 4.5,
      'reviewCount': 156,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'version': '1.0',
        'source': 'demo_data'
      }
    });
    print('  ✅ Collection shops créée');
  }

  /// 🎨 Créer collection PORTFOLIOS
  Future<void> _createPortfoliosCollection(FirebaseFirestore firestore) async {
    await firestore
        .collection('portfolios')
        .doc('demo_portfolio_123')
        .set({
      'id': 'demo_portfolio_123',
      'tattooistId': 'demo_tatoueur_123',
      'title': 'Portfolio Réaliste',
      'description': 'Mes meilleures réalisations en style réaliste',
      'category': 'realiste',
      'style': 'realiste',
      'isPublic': true,
      'isFeatured': true,
      'photos': [
        {
          'id': 'photo_1',
          'url': 'portfolio_1.jpg',
          'description': 'Portrait réaliste noir et blanc',
          'tags': ['portrait', 'realiste', 'noir_blanc'],
          'bodyPart': 'bras',
          'duration': '8h',
          'completedAt': '2024-06-15'
        },
        {
          'id': 'photo_2', 
          'url': 'portfolio_2.jpg',
          'description': 'Rose réaliste couleur',
          'tags': ['fleur', 'realiste', 'couleur'],
          'bodyPart': 'avant_bras',
          'duration': '4h',
          'completedAt': '2024-06-20'
        }
      ],
      'stats': {
        'viewCount': 1250,
        'likeCount': 89,
        'shareCount': 12
      },
      'seo': {
        'keywords': ['tatouage réaliste Paris', 'portrait tattoo'],
        'metaDescription': 'Portfolio de tatouages réalistes par un artiste parisien'
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'version': '1.0',
        'source': 'demo_data'
      }
    });
    print('  ✅ Collection portfolios créée');
  }

  /// 🎪 Créer collection EVENTS
  Future<void> _createEventsCollection(FirebaseFirestore firestore) async {
    await firestore
        .collection('events')
        .doc('demo_event_123')
        .set({
      'id': 'demo_event_123',
      'organiserId': 'demo_organisateur_123',
      'title': 'Convention Tattoo Paris 2025',
      'description': 'La plus grande convention de tatouage de France',
      'shortDescription': 'Convention tattoo avec 200+ artistes',
      'category': 'convention',
      'type': 'convention',
      'isPublic': true,
      'status': 'upcoming',
      'dates': {
        'startDate': '2025-09-15',
        'endDate': '2025-09-17',
        'registrationDeadline': '2025-09-01'
      },
      'location': {
        'venue': 'Porte de Versailles',
        'address': 'Place de la Porte de Versailles, Paris',
        'city': 'Paris',
        'country': 'France',
        'coordinates': {
          'latitude': 48.8356,
          'longitude': 2.2869
        }
      },
      'pricing': {
        'clientEntry': 15.0,
        'tattooistBooth': 250.0,
        'currency': 'EUR'
      },
      'capacity': {
        'maxTattooists': 200,
        'maxClients': 2000,
        'currentTattooists': 45,
        'currentClients': 340
      },
      'features': [
        'concours_tatouage',
        'demonstrations',
        'boutique_materiel',
        'food_trucks'
      ],
      'schedule': [
        {
          'day': '2025-09-15',
          'events': [
            {'time': '10:00', 'title': 'Ouverture', 'description': 'Ouverture des portes'},
            {'time': '14:00', 'title': 'Concours Flash', 'description': 'Concours de tatouages flash'}
          ]
        }
      ],
      'socialMedia': {
        'instagram': '@convention_tattoo_paris',
        'facebook': 'ConventionTattooParis',
        'website': 'https://convention-tattoo-paris.fr'
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'version': '1.0',
        'source': 'demo_data'
      }
    });
    print('  ✅ Collection events créée');
  }

  /// ⭐ Créer collection FAVORITES
  Future<void> _createFavoritesCollection(FirebaseFirestore firestore) async {
    await firestore
        .collection('favorites')
        .doc('demo_favorite_123')
        .set({
      'id': 'demo_favorite_123',
      'userId': 'demo_client_123',
      'tattooistId': 'demo_tatoueur_123',
      'shopId': 'demo_shop_123',
      'type': 'tatoueur',
      'addedAt': FieldValue.serverTimestamp(),
      'notes': 'Style réaliste impressionnant, très professionnel',
      'tags': ['realiste', 'portrait', 'paris'],
      'priority': 'high',
      'notificationEnabled': true,
      'metadata': {
        'version': '1.0',
        'source': 'demo_data'
      }
    });
    print('  ✅ Collection favorites créée');
  }

  /// 💌 Créer collection CONTACT_FORMS
  Future<void> _createContactFormsCollection(FirebaseFirestore firestore) async {
    await firestore
        .collection('contact_forms')
        .doc('demo_contact_123')
        .set({
      'id': 'demo_contact_123',
      'fromUserId': 'demo_client_123',
      'toUserId': 'demo_tatoueur_123',
      'type': 'project_inquiry',
      'subject': 'Demande de devis - Portrait réaliste',
      'message': 'Bonjour, je souhaiterais un devis pour un portrait réaliste sur le bras.',
      'status': 'sent',
      'priority': 'normal',
      'attachments': [],
      'projectDetails': {
        'style': 'realiste',
        'bodyPart': 'bras',
        'size': 'medium',
        'estimatedBudget': '500-800'
      },
      'sentAt': FieldValue.serverTimestamp(),
      'readAt': null,
      'repliedAt': null,
      'metadata': {
        'version': '1.0',
        'source': 'demo_data'
      }
    });
    print('  ✅ Collection contact_forms créée');
  }

  /// 🎫 Créer collection EVENT_REGISTRATIONS
  Future<void> _createEventRegistrationsCollection(FirebaseFirestore firestore) async {
    await firestore
        .collection('event_registrations')
        .doc('demo_registration_123')
        .set({
      'id': 'demo_registration_123',
      'eventId': 'demo_event_123',
      'clientId': 'demo_client_123',
      'organiserId': 'demo_organisateur_123',
      'type': 'client_entry',
      'status': 'confirmed',
      'ticketType': 'standard',
      'quantity': 2,
      'totalAmount': 30.0,
      'currency': 'EUR',
      'paymentStatus': 'paid',
      'paymentMethod': 'card',
      'registrationDate': FieldValue.serverTimestamp(),
      'attendeeInfo': {
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '+33123456789',
        'specialRequests': 'Accès PMR'
      },
      'metadata': {
        'version': '1.0',
        'source': 'demo_data'
      }
    });
    print('  ✅ Collection event_registrations créée');
  }

  /// 🏢 Créer collection EVENT_APPLICATIONS
  Future<void> _createEventApplicationsCollection(FirebaseFirestore firestore) async {
    await firestore
        .collection('event_applications')
        .doc('demo_application_123')
        .set({
      'id': 'demo_application_123',
      'eventId': 'demo_event_123',
      'tattooistId': 'demo_tatoueur_123',
      'organiserId': 'demo_organisateur_123',
      'status': 'pending',
      'applicationDate': FieldValue.serverTimestamp(),
      'boothPreferences': {
        'size': 'medium',
        'location': 'entrance_area',
        'specialRequests': 'Près de la zone de démonstration'
      },
      'portfolio': {
        'portfolioId': 'demo_portfolio_123',
        'selectedWorks': ['photo_1', 'photo_2'],
        'experienceYears': 8,
        'specialties': ['realiste', 'portrait']
      },
      'businessInfo': {
        'shopName': 'Ink Paradise',
        'website': 'https://inkparadise.fr',
        'instagram': '@inkparadise_paris'
      },
      'fees': {
        'boothFee': 250.0,
        'currency': 'EUR',
        'paymentStatus': 'pending'
      },
      'metadata': {
        'version': '1.0',
        'source': 'demo_data'
      }
    });
    print('  ✅ Collection event_applications créée');
  }

  /// 🏃‍♂️ Créer collections GUEST SYSTEM (Premium)
  Future<void> _createGuestSystemCollections(FirebaseFirestore firestore) async {
    // GUEST_APPLICATIONS
    await firestore
        .collection('guest_applications')
        .doc('demo_guest_app_123')
        .set({
      'id': 'demo_guest_app_123',
      'tattooistId': 'demo_tatoueur_123',
      'shopOwnerId': 'demo_shop_owner_456',
      'shopId': 'demo_shop_456',
      'status': 'pending',
      'message': 'Bonjour, je serais intéressé pour être tatoueur guest dans votre shop',
      'proposedDates': {
        'startDate': '2025-10-01',
        'endDate': '2025-10-15'
      },
      'appliedAt': FieldValue.serverTimestamp(),
      'metadata': {'version': '1.0', 'source': 'demo_data'}
    });

    // GUEST_OFFERS
    await firestore
        .collection('guest_offers')
        .doc('demo_guest_offer_123')
        .set({
      'id': 'demo_guest_offer_123',
      'shopOwnerId': 'demo_shop_owner_456',
      'tattooistId': 'demo_tatoueur_789',
      'shopId': 'demo_shop_456',
      'status': 'sent',
      'message': 'Nous aimerions vous proposer une collaboration dans notre shop',
      'proposedDates': {
        'startDate': '2025-11-01',
        'endDate': '2025-11-30'
      },
      'sentAt': FieldValue.serverTimestamp(),
      'metadata': {'version': '1.0', 'source': 'demo_data'}
    });

    // GUEST_COLLABORATIONS
    await firestore
        .collection('guest_collaborations')
        .doc('demo_collaboration_123')
        .set({
      'id': 'demo_collaboration_123',
      'guestTattooistId': 'demo_tatoueur_123',
      'hostShopOwnerId': 'demo_shop_owner_456',
      'shopId': 'demo_shop_456',
      'status': 'active',
      'startDate': '2025-08-01',
      'endDate': '2025-08-31',
      'terms': {
        'commission': 30,
        'minimumBookings': 15
      },
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': {'version': '1.0', 'source': 'demo_data'}
    });

    print('  ✅ Collections Guest System créées');
  }

  /// 🔍 Vérifier si les collections existent
  Future<bool> checkCollectionExists(String collectionName) async {
    try {
      // ✅ CORRECTION: Utiliser _firestore au lieu de FirebaseFirestore.instance
      final snapshot = await _firestore
          .collection(collectionName)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 📊 Obtenir le statut de toutes les collections
  Future<Map<String, bool>> getCollectionsStatus() async {
    final collections = [
      'shops',
      'portfolios', 
      'events',
      'favorites',
      'contact_forms',
      'event_registrations',
      'event_applications',
      'guest_applications',
      'guest_offers',
      'guest_collaborations'
    ];

    final status = <String, bool>{};
    for (final collection in collections) {
      status[collection] = await checkCollectionExists(collection);
    }
    return status;
  }
}