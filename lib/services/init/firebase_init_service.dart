// lib/services/init/firebase_init_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/services/firebase_collections_service.dart'; // ← AJOUTER CETTE LIGNE

class FirebaseInitService {
  static FirebaseInitService? _instance;
  static FirebaseInitService get instance => _instance ??= FirebaseInitService._();
  FirebaseInitService._();

  late final FirebaseFirestore _firestore;
  bool _isInitialized = false;

  void _initializeFirestore() {
    // ✅ Utilisation de la base nommée "kipik" au lieu de "default"
    _firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'kipik');
    print('✅ Firestore configuré (base: kipik)');
  }

  Future<void> initializeKipikFirebase({bool forceReinit = false}) async {
    if (_isInitialized && !forceReinit) {
      print('✅ Firebase déjà initialisé');
      return;
    }
    try {
      print('🚀 Initialisation Firebase KIPIK...');
      _initializeFirestore();

      await _createBaseCollections();
      await _createNewSubscriptionPlans();
      await _initializeTrialTracking();
      await _createDemoData();
      await _initializeAdminStats();
      await _createInitialPromoCodes();
      
      // ✨ NOUVELLE LIGNE : Créer les collections business manquantes
      await _createBusinessCollections();

      _isInitialized = true;
      print('🎉 Firebase KIPIK initialisé avec succès !');
    } catch (e) {
      print('❌ Erreur initialisation Firebase: $e');
      rethrow;
    }
  }

  // ✨ NOUVELLE MÉTHODE : Créer les collections business
  Future<void> _createBusinessCollections() async {
    print('🏗️ Création des collections business KIPIK...');
    try {
      await FirebaseCollectionsService().createMissingCollections();
      print('  ✅ Collections business créées avec succès');
    } catch (e) {
      print('  ❌ Erreur création collections business: $e');
      // Ne pas faire échouer l'initialisation complète pour ça
    }
  }

  Future<void> _createBaseCollections() async {
    print('📁 Création des collections de base...');
    final collections = [
      'users','subscription_plans','trial_tracking','appointments',
      'projects','chats','quotes','notifications','photos',
      'payments','admin_stats','reports','conventions',
      'promo_codes','referrals'
    ];
    for (final name in collections) {
      try {
        final snap = await _firestore.collection(name).limit(1).get();
        if (snap.docs.isEmpty) {
          await _firestore.collection(name).doc('_init').set({
            '_initialized': true,
            '_createdAt': FieldValue.serverTimestamp(),
            '_note': 'Document d\'initialisation - peut être supprimé'
          });
          print('  ✅ Collection $name créée');
        } else {
          print('  ✅ Collection $name existe déjà');
        }
      } catch (e) {
        print('  ❌ Erreur création collection $name: $e');
      }
    }
  }

  Future<void> _createNewSubscriptionPlans() async {
    print('💳 Création des plans d\'abonnement KIPIK...');
    final plans = <Map<String, dynamic>>[
      {
        'planId': 'free_trial',
        'name': 'Essai Gratuit',
        'type': 'trial',
        'price': 0.0,
        'currency': 'EUR',
        'billingPeriod': 'one_time',
        'trialDays': 30,
        'description': 'Découvrez toutes les fonctionnalités pendant 30 jours',
        'features': [
          'conventions',
          'guest_management',
          'forum',
          'advanced_analytics',
          'unlimited_projects',
          'unlimited_quotes',
          'calendar_management',
          'client_management',
          'photo_gallery',
          'chat_support'
        ],
        'excludedFeatures': [],
        'maxProjects': -1,
        'maxClients': -1,
        'maxPhotos': -1,
        'isPopular': false,
        'isActive': true,
        'sortOrder': 0,
      },
      {
        'planId': 'monthly_pro_promo',
        'name': 'PRO Mensuel - Promo 100 premiers',
        'type': 'monthly',
        'price': 79.0,
        'originalPrice': 99.0,
        'currency': 'EUR',
        'billingPeriod': 'monthly',
        'trialDays': 0,
        'description': 'Offre spéciale limitée aux 100 premiers utilisateurs',
        'features': [
          'conventions',
          'guest_management',
          'forum',
          'advanced_analytics',
          'unlimited_projects',
          'unlimited_quotes',
          'calendar_management',
          'client_management',
          'photo_gallery',
          'chat_support',
          'priority_support',
          'custom_branding'
        ],
        'excludedFeatures': [],
        'maxProjects': -1,
        'maxClients': -1,
        'maxPhotos': -1,
        'isPopular': true,
        'isActive': true,
        'sortOrder': 1,
        'promoCode': 'FIRST100',
        'promoEndCondition': 'first_100_users',
      },
      {
        'planId': 'monthly_pro',
        'name': 'PRO Mensuel',
        'type': 'monthly',
        'price': 99.0,
        'currency': 'EUR',
        'billingPeriod': 'monthly',
        'trialDays': 0,
        'description': 'Abonnement mensuel pour professionnels du tatouage',
        'features': [
          'conventions',
          'guest_management',
          'forum',
          'advanced_analytics',
          'unlimited_projects',
          'unlimited_quotes',
          'calendar_management',
          'client_management',
          'photo_gallery',
          'chat_support',
          'priority_support'
        ],
        'excludedFeatures': [],
        'maxProjects': -1,
        'maxClients': -1,
        'maxPhotos': -1,
        'isPopular': false,
        'isActive': true,
        'sortOrder': 2,
      },
      {
        'planId': 'yearly_pro',
        'name': 'PRO Annuel',
        'type': 'yearly',
        'price': 999.0,
        'currency': 'EUR',
        'billingPeriod': 'yearly',
        'trialDays': 0,
        'description': 'Abonnement annuel avec 2 mois offerts',
        'features': [
          'conventions',
          'guest_management',
          'forum',
          'advanced_analytics',
          'unlimited_projects',
          'unlimited_quotes',
          'calendar_management',
          'client_management',
          'photo_gallery',
          'chat_support',
          'priority_support',
          'custom_branding',
          'advanced_reporting',
          'api_access'
        ],
        'excludedFeatures': [],
        'maxProjects': -1,
        'maxClients': -1,
        'maxPhotos': -1,
        'isPopular': false,
        'isActive': true,
        'sortOrder': 3,
        'savings': '2 mois offerts',
      }
    ];
    
    for (final planData in plans) {
      try {
        final planId = planData['planId'] as String;
        final ref = _firestore.collection('subscription_plans').doc(planId);
        final doc = await ref.get();
        final data = {
          ...planData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (!doc.exists) {
          await ref.set(data);
          print('  ✅ Plan créé: ${planData['name']}');
        } else {
          await ref.update(data);
          print('  ✅ Plan mis à jour: ${planData['name']}');
        }
      } catch (e) {
        print('  ❌ Erreur création plan ${planData['name']}: $e');
      }
    }
  }

  Future<void> _initializeTrialTracking() async {
    print('🎯 Initialisation tracking essais gratuits et promo 100 premiers...');
    try {
      final globalRef = _firestore.collection('trial_tracking').doc('global_stats');
      if (!(await globalRef.get()).exists) {
        await globalRef.set({
          'totalTrialsStarted': 0,
          'activeTrials': 0,
          'expiredTrials': 0,
          'trialsConvertedToPaid': 0,
          'trialsExpiredWithoutPayment': 0,
          'blockedAccountsAwaitingPayment': 0,
          'conversionRate': 0.0,
          'averageTrialDuration': 30,
          'trialPolicy': {
            'durationDays': 30,
            'requiresPaymentMethod': false,
            'blocksAccountAfterExpiry': true,
            'notificationSchedule': {
              'day_7': 'Plus que 7 jours',
              'day_3': 'Plus que 3 jours',
              'day_1': 'Dernier jour',
              'expired': 'Compte bloqué - Choisissez un abonnement'
            }
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      final promoRef = _firestore.collection('trial_tracking').doc('promo_100_first');
      if (!(await promoRef.get()).exists) {
        await promoRef.set({
          'totalSlots': 100,
          'usedSlots': 0,
          'remainingSlots': 100,
          'subscribers': [],
          'isActive': true,
          'promoPrice': 79.0,
          'regularPrice': 99.0,
          'savings': 20.0,
          'startDate': FieldValue.serverTimestamp(),
          'endCondition': 'until_100_subscribers',
          'currentWaitingList': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      print('  ✅ Tracking essais gratuits et promo 100 premiers initialisé');
    } catch (e) {
      print('  ❌ Erreur initialisation tracking: $e');
    }
  }

  Future<void> _createDemoData() async {
    print('🧪 Création données de démo...');
    try {
      await _createDemoUser();
      await _createDemoProject();
      await _createDemoNotification();
      print('  ✅ Données de démo créées');
    } catch (e) {
      print('  ❌ Erreur création données démo: $e');
    }
  }

  /// --- DÉBUT des méthodes de démo ---

  Future<void> _createDemoUser() async {
    final ref = _firestore.collection('users').doc('demo_pro_123');
    final doc = await ref.get();
    if (doc.exists) return;
    final start = DateTime.now();
    final end = start.add(const Duration(days: 30));
    await ref.set({
      'userType': 'pro',
      'email': 'demo.pro@kipik.fr',
      'displayName': 'Demo Tatoueur',
      'profile': {
        'firstName': 'Alex',
        'lastName': 'Tatoueur',
        'phone': '06 12 34 56 78',
        'proInfo': {
          'shopName': 'Studio Demo Ink',
          'shopAddress': '123 Rue de la Démo, 75001 Paris',
          'style': 'Réaliste',
          'bio': 'Tatoueur professionnel de démonstration pour KIPIK',
          'experienceYears': 5,
          'location': 'Paris',
          'rating': 4.8,
          'reviewsCount': 42
        }
      },
      'subscription': {
        'planId': 'free_trial',
        'status': 'trialing',
        'price': 0.0,
        'currency': 'EUR',
        'isFreeTrial': true,
        'trialStartDate': Timestamp.fromDate(start),
        'trialEndDate': Timestamp.fromDate(end),
        'trialDaysRemaining': 30,
        'hasPaymentMethod': false,
        'willBlockAfterTrial': true,
        'autoRenew': false,
        'nextPlanId': null,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'permissions': {
        'isVerified': true,
        'canUseApp': true,
        'accountBlocked': false,
      },
      'security': {
        'termsAccepted': true,
        'privacyPolicyAccepted': true,
      },
      'inscriptionCompleted': true,
      'profileComplete': true,
      'trialHistory': {
        'hasUsedFreeTrial': true,
        'freeTrialStartDate': Timestamp.fromDate(start),
        'isEligibleForPromo100': true,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
    });
    print('    ✅ Utilisateur démo créé');
  }

  Future<void> _createDemoProject() async {
    final ref = _firestore.collection('projects').doc('demo_project_123');
    final doc = await ref.get();
    if (doc.exists) return;
    await ref.set({
      'clientId': 'demo_pro_123',
      'clientName': 'Marie Démo',
      'title': 'Tatouage Dragon Japonais',
      'description': 'Dragon traditionnel japonais sur l\'épaule droite',
      'status': 'seeking_artist',
      'style': 'Japonais',
      'size': 'Moyen',
      'placement': 'Épaule',
      'budget': {'min': 300, 'max': 500, 'currency': 'EUR'},
      'images': [],
      'quotesReceived': 0,
      'viewsCount': 12,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('    ✅ Projet démo créé');
  }

  Future<void> _createDemoNotification() async {
    await _firestore.collection('notifications').add({
      'userId': 'demo_pro_123',
      'type': 'trial_welcome',
      'title': 'Bienvenue sur KIPIK ! 🎉',
      'message': 'Votre essai gratuit de 30 jours a commencé. Découvrez toutes les fonctionnalités !',
      'read': false,
      'priority': 'high',
      'actionButton': {
        'text': 'Découvrir',
        'action': 'navigate_to_dashboard'
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('    ✅ Notification démo créée');
  }
  /// --- FIN des méthodes de démo ---

  Future<void> _initializeAdminStats() async {
    print('📊 Initialisation stats admin...');
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final ref = _firestore.collection('admin_stats').doc(today);
      if (!(await ref.get()).exists) {
        await ref.set({
          'users': {
            'total': 0,
            'particuliers': 0,
            'pros': 0,
            'organisateurs': 0,
            'admin': 1,
            'newToday': 0,
            'activeToday': 0
          },
          'subscriptions': {
            'totalActive': 0,
            'freeTrials': 0,
            'monthlyBasicPromo': 0,
            'monthlyBasic': 0,
            'yearlyBasic': 0,
            'monthlyPremium': 0,
            'yearlyPremium': 0,
            'expiredTrials': 0,
            'blockedAccounts': 0,
            'trialConversions': 0,
            'churnRate': 0,
            'newSubscriptionsToday': 0
          },
          'revenue': {
            'totalMonthly': 0,
            'monthlyBasicPromo': 0,
            'monthlyBasic': 0,
            'monthlyPremium': 0,
            'yearlyBasic': 0,
            'yearlyPremium': 0,
            'projectedAnnual': 0,
            'averageRevenuePerUser': 0,
            'trialConversionRevenue': 0
          },
          'payments': {
            'totalToday': 0,
            'stripeVolume': 0,
            'sepaVolume': 0,
            'failedPayments': 0,
            'stripeFees': 0
          },
          'promoStatus': {
            'promo100Used': 0,
            'promo100Remaining': 100,
            'promo100Active': true,
            'waitingListCount': 0
          },
          'trialStatus': {
            'activeTrials': 0,
            'expiredTrials': 0,
            'conversionRate': 0,
            'averageTrialLength': 30,
            'notificationsSent': 0
          },
          'updatedAt': FieldValue.serverTimestamp()
        });
        print('  ✅ Stats admin initialisées pour $today');
      }
    } catch (e) {
      print('  ❌ Erreur initialisation stats admin: $e');
    }
  }

  Future<void> _createInitialPromoCodes() async {
    print('🎟️ Création codes promo pour nouvelle stratégie...');
    final promoCodes = <Map<String, dynamic>>[
      {
        'code': 'FIRST100',
        'type': 'percentage',
        'value': 20.0,
        'description': 'Réduction 20% pour les 100 premiers utilisateurs',
        'isActive': true,
        'usageLimit': 100,
        'usageCount': 0,
        'validFrom': DateTime.now(),
        'validTo': DateTime.now().add(const Duration(days: 365)),
        'applicablePlans': ['monthly_pro'],
        'userType': 'all',
        'isRecurring': false,
        'minimumAmount': 0,
        'excludeTrials': true,
      },
      {
        'code': 'WELCOME30',
        'type': 'percentage',
        'value': 30.0,
        'description': 'Réduction de bienvenue 30% premier mois',
        'isActive': true,
        'usageLimit': -1,
        'usageCount': 0,
        'validFrom': DateTime.now(),
        'validTo': DateTime.now().add(const Duration(days: 90)),
        'applicablePlans': ['monthly_pro', 'yearly_pro'],
        'userType': 'new',
        'isRecurring': false,
        'minimumAmount': 50,
        'excludeTrials': true,
      },
      {
        'code': 'LOYALTY50',
        'type': 'fixed',
        'value': 50.0,
        'description': 'Réduction fidélité 50€',
        'isActive': true,
        'usageLimit': -1,
        'usageCount': 0,
        'validFrom': DateTime.now(),
        'validTo': DateTime.now().add(const Duration(days: 180)),
        'applicablePlans': ['yearly_pro'],
        'userType': 'existing',
        'isRecurring': false,
        'minimumAmount': 200,
        'excludeTrials': true,
      }
    ];
    
    for (final promo in promoCodes) {
      try {
        final code = promo['code'] as String;
        final ref = _firestore.collection('promo_codes').doc(code);
        if (!(await ref.get()).exists) {
          await ref.set({
            ...promo,
            'validFrom': Timestamp.fromDate(promo['validFrom'] as DateTime),
            'validTo': Timestamp.fromDate(promo['validTo'] as DateTime),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('  ✅ Code promo créé: $code');
        } else {
          print('  ✅ Code promo existe déjà: $code');
        }
      } catch (e) {
        print('  ❌ Erreur création code promo ${promo['code']}: $e');
      }
    }
  }

  Future<Map<String, dynamic>> getInitializationStatus() async {
    try {
      final status = <String, dynamic>{};
      for (var col in ['subscription_plans','trial_tracking','admin_stats']) {
        status[col] = (await _firestore.collection(col).limit(1).get()).docs.isNotEmpty;
      }
      status['trial_plan_exists']   = (await _firestore.collection('subscription_plans').doc('free_trial').get()).exists;
      status['monthly_plan_exists'] = (await _firestore.collection('subscription_plans').doc('monthly_pro').get()).exists;
      status['yearly_plan_exists']  = (await _firestore.collection('subscription_plans').doc('yearly_pro').get()).exists;
      
      // ✨ NOUVEAU : Vérifier les collections business
      final businessCollections = await FirebaseCollectionsService().getCollectionsStatus();
      status['business_collections'] = businessCollections;
      status['business_collections_complete'] = businessCollections.values.every((exists) => exists);
      
      status['fully_initialized']   = status.values.where((v) => v is bool).every((v) => v == true);
      status['checked_at']          = DateTime.now().toIso8601String();
      status['strategy']            = 'free_trial_for_all';
      return status;
    } catch (e) {
      return {
        'error': e.toString(),
        'fully_initialized': false,
        'checked_at': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<void> debugInitService() async {
    print('🔍 DIAGNOSTIC FirebaseInitService:');
    try {
      final s = await getInitializationStatus();
      print('  - Initialisé: $_isInitialized');
      print('  - Status: $s');
      print(s['fully_initialized'] == true
          ? '  ✅ Tout bon'
          : '  ⚠️ Incomplet');
    } catch (e) {
      print('  ❌ Erreur diagnostic: $e');
    }
  }

  FirebaseFirestore get firestore => _firestore;
}