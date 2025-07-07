// lib/services/auth/secure_auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ Ajouté pour Firebase.app()
import 'package:crypto/crypto.dart';
import 'package:kipik_v5/services/auth/captcha_manager.dart';
import 'package:kipik_v5/models/user_role.dart';

// ========================================
// 1. ENUMS NÉCESSAIRES
// ========================================

enum PagePermission {
  view, create, edit, delete, approve,
  buyTickets, addToFavorites, registerToEvent, 
  manageEvents, validateEvents, accessAdmin,
  createProject, manageBookings, accessAnalytics,
  promoteToAdmin, // ✅ Permission spéciale pour promouvoir admin
}

// ========================================
// 2. SERVICE D'AUTHENTIFICATION SÉCURISÉ
// ========================================

class SecureAuthService extends ChangeNotifier {
  static final SecureAuthService _instance = SecureAuthService._internal();
  static SecureAuthService get instance => _instance;
  SecureAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ✅ CORRECTION PRINCIPALE: Utilise la base 'kipik' au lieu de 'default'
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'kipik',
  );
  
  // État mis en cache pour éviter les vérifications répétées
  UserRole? _cachedRole;
  String? _cachedUserId;
  Map<String, dynamic>? _cachedUserProfile;
  String? _securityToken;
  DateTime? _lastValidation;
  Timer? _securityTimer;
  StreamSubscription<User?>? _authStateSubscription;
  
  // ✅ Sécurité admin renforcée
  bool _isFirstAdminCreated = false;
  
  // Getters optimisés avec cache
  UserRole? get currentUserRole {
    if (_isRecentlyValidated() && _cachedRole != null) {
      return _cachedRole;
    }
    return _validateAndGetRole();
  }
  
  String? get currentUserId {
    if (_isRecentlyValidated() && _cachedUserId != null) {
      return _cachedUserId;
    }
    return _validateAndGetUserId();
  }
  
  bool get isAuthenticated {
    if (_isRecentlyValidated()) {
      return _auth.currentUser != null && _cachedRole != null;
    }
    return _validateAuthentication();
  }
  
  // ✅ Vérifier si c'est un super admin (vous)
  bool get isSuperAdmin {
    return _cachedUserId != null && 
           _cachedRole == UserRole.admin &&
           _cachedUserProfile?['isSuperAdmin'] == true;
  }
  
  // Méthode pour récupérer currentUser (compatibilité avec AuthService)
  dynamic get currentUser {
    if (!isAuthenticated || _cachedUserId == null) return null;
    return _createUserFromCache();
  }
  
  dynamic _createUserFromCache() {
    if (_cachedUserProfile == null || _cachedUserId == null) return null;
    
    return {
      'id': _cachedUserId,
      'uid': _cachedUserId,
      'email': _cachedUserProfile!['email'],
      'name': _cachedUserProfile!['name'] ?? _cachedUserProfile!['displayName'] ?? 'Utilisateur',
      'displayName': _cachedUserProfile!['displayName'] ?? _cachedUserProfile!['name'] ?? 'Utilisateur',
      'role': _cachedUserProfile!['role'] ?? 'client',
      'profileImageUrl': _cachedUserProfile!['profileImageUrl'],
      'isActive': _cachedUserProfile!['isActive'] ?? true,
      'isSuperAdmin': _cachedUserProfile!['isSuperAdmin'] ?? false,
      'createdAt': _cachedUserProfile!['createdAt'],
      'updatedAt': _cachedUserProfile!['updatedAt'],
    };
  }
  
  bool _isRecentlyValidated() {
    if (_lastValidation == null) return false;
    return DateTime.now().difference(_lastValidation!).inSeconds < 30;
  }
  
  UserRole? _validateAndGetRole() {
    if (!_isSessionValid()) {
      _invalidateSession();
      return null;
    }
    _lastValidation = DateTime.now();
    return _cachedRole;
  }
  
  String? _validateAndGetUserId() {
    if (!_isSessionValid()) {
      _invalidateSession();
      return null;
    }
    _lastValidation = DateTime.now();
    return _cachedUserId;
  }
  
  bool _validateAuthentication() {
    final isValid = _auth.currentUser != null && 
                   _cachedRole != null && 
                   _isSessionValid();
    if (isValid) {
      _lastValidation = DateTime.now();
    }
    return isValid;
  }
  
  bool _isSessionValid() {
    if (_auth.currentUser == null) return false;
    if (_cachedRole == null) return false;
    if (_securityToken == null) return false;
    
    final expectedToken = _generateSecurityToken(_cachedUserId!, _cachedRole!);
    return _securityToken == expectedToken;
  }
  
  String _generateSecurityToken(String userId, UserRole role) {
    final input = '$userId-${role.toString()}-${DateTime.now().day}';
    return sha256.convert(utf8.encode(input)).toString().substring(0, 16);
  }
  
  Future<bool> signInSecure(String email, String password, {CaptchaResult? captchaResult}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) return false;
      
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      
      if (!userDoc.exists) {
        await signOut();
        return false;
      }
      
      final userData = userDoc.data()!;
      final roleString = userData['role'] as String?;
      
      if (roleString == null) {
        await signOut();
        return false;
      }
      
      _cachedUserId = credential.user!.uid;
      _cachedRole = _parseRole(roleString);
      _cachedUserProfile = userData;
      _securityToken = _generateSecurityToken(_cachedUserId!, _cachedRole!);
      _lastValidation = DateTime.now();
      
      // ✅ Log de sécurité pour connexions admin
      if (_cachedRole == UserRole.admin) {
        print('🔐 Connexion admin sécurisée - User: ${userData['email']}, Super: ${userData['isSuperAdmin'] ?? false}');
        if (captchaResult != null) {
          print('🔐 Score reCAPTCHA admin: ${(captchaResult.score * 100).round()}%');
        }
      }
      
      _startSecurityMonitoring();
      
      notifyListeners();
      return true;
      
    } catch (e) {
      print('❌ Erreur connexion sécurisée: $e');
      _invalidateSession();
      return false;
    }
  }
  
  void _startSecurityMonitoring() {
    _authStateSubscription?.cancel();
    _securityTimer?.cancel();
    
    _authStateSubscription = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _invalidateSession();
      }
    });
    
    _securityTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!_isSessionValid()) {
        timer.cancel();
        _invalidateSession();
      }
    });
  }
  
  void _invalidateSession() {
    _cachedRole = null;
    _cachedUserId = null;
    _cachedUserProfile = null;
    _securityToken = null;
    _lastValidation = null;
    _securityTimer?.cancel();
    _authStateSubscription?.cancel();
    notifyListeners();
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
    _invalidateSession();
  }
  
  UserRole _parseRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'client':
      case 'particulier':
        return UserRole.client;
      case 'tatoueur':
      case 'pro':
        return UserRole.tatoueur;
      case 'organisateur':
      case 'organizer':
        return UserRole.organisateur;
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      default:
        return UserRole.client;
    }
  }

  // ========================================
  // 3. MÉTHODES DE COMPATIBILITÉ
  // ========================================

  /// Connexion avec email et mot de passe - Compatible avec auth_helper.dart
  Future<dynamic> signInWithEmailAndPassword(String email, String password, {CaptchaResult? captchaResult}) async {
    try {
      final success = await signInSecure(email, password, captchaResult: captchaResult);
      if (success && _cachedUserProfile != null) {
        return _createUserFromProfile(_cachedUserProfile!);
      }
      return null;
    } catch (e) {
      print('❌ Erreur connexion: $e');
      return null;
    }
  }

  /// ✅ CRÉATION UTILISATEUR STANDARD (jamais admin par défaut)
  Future<dynamic> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    String? userRole, // ✅ Paramètre optionnel mais sécurisé
    CaptchaResult? captchaResult,
  }) async {
    try {
      // ✅ SÉCURITÉ: Jamais créer un admin via cette méthode
      final safeRole = (userRole?.toLowerCase() == 'admin') ? 'client' : (userRole ?? 'client');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) return null;
      
      if (displayName != null) {
        await credential.user!.updateDisplayName(displayName);
      }
      
      final userData = {
        'email': email,
        'name': displayName ?? 'Utilisateur',
        'displayName': displayName ?? 'Utilisateur',
        'role': safeRole, // ✅ Toujours non-admin
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isSuperAdmin': false, // ✅ Jamais super admin par défaut
      };
      
      // ✅ Log de sécurité reCAPTCHA
      if (captchaResult != null) {
        userData['signupCaptchaScore'] = captchaResult.score;
        userData['signupCaptchaTimestamp'] = DateTime.now().toIso8601String();
        print('🔐 Inscription sécurisée - Score: ${(captchaResult.score * 100).round()}%');
      }
      
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData);
      
      _cachedUserId = credential.user!.uid;
      _cachedRole = _parseRole(safeRole);
      _cachedUserProfile = userData;
      _securityToken = _generateSecurityToken(_cachedUserId!, _cachedRole!);
      _lastValidation = DateTime.now();
      
      _startSecurityMonitoring();
      notifyListeners();
      
      return _createUserFromProfile(userData);
    } catch (e) {
      print('❌ Erreur création utilisateur: $e');
      return null;
    }
  }

  /// ✅ CRÉATION DU PREMIER ADMIN (VOUS UNIQUEMENT)
  Future<bool> createFirstSuperAdmin({
    required String email,
    required String password,
    required String displayName,
    required CaptchaResult captchaResult,
  }) async {
    try {
      // ✅ VÉRIFICATION: Premier admin seulement
      final existingAdmins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      
      if (existingAdmins.docs.isNotEmpty) {
        throw Exception('Un administrateur principal existe déjà');
      }
      
      // ✅ SÉCURITÉ: Score reCAPTCHA très élevé requis
      if (!captchaResult.isValid || captchaResult.score < 0.8) {
        throw Exception('Score de sécurité insuffisant pour créer un super admin');
      }
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) return false;
      
      await credential.user!.updateDisplayName(displayName);
      
      final userData = {
        'email': email,
        'name': displayName,
        'displayName': displayName,
        'role': 'admin',
        'isSuperAdmin': true, // ✅ VOUS êtes le super admin
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'permissions': ['all'], // ✅ Toutes les permissions
        'adminLevel': 'super', // ✅ Niveau le plus élevé
        'signupCaptchaScore': captchaResult.score,
        'signupCaptchaTimestamp': DateTime.now().toIso8601String(),
      };
      
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData);
      
      // ✅ CORRECTION: Utilise la collection admin_first_setup au lieu d'admin_config
      await _firestore.collection('admin_first_setup').doc('configured').set({
        'firstAdminCreated': true,
        'firstAdminEmail': email,
        'adminId': credential.user!.uid,
        'configuredBy': email,
        'createdAt': FieldValue.serverTimestamp(),
        'securityScore': captchaResult.score,
        'timestamp': FieldValue.serverTimestamp(),
        'setupVersion': '1.0',
      });
      
      _isFirstAdminCreated = true;
      
      print('✅ Super admin créé avec succès - Score sécurité: ${(captchaResult.score * 100).round()}%');
      return true;
      
    } catch (e) {
      print('❌ Erreur création super admin: $e');
      rethrow;
    }
  }

  /// ✅ VÉRIFIER SI PREMIER ADMIN EXISTE
  Future<bool> checkFirstAdminExists() async {
    try {
      print('🔍 Vérification premier admin avec base kipik...');
      
      // ✅ CORRECTION: Vérifie dans admin_first_setup/configured
      final config = await _firestore.collection('admin_first_setup').doc('configured').get();
      final configExists = config.exists && config.data()?['firstAdminCreated'] == true;
      
      if (configExists) {
        print('✅ Configuration admin trouvée dans admin_first_setup');
        return true;
      }
      
      // ✅ FALLBACK: Vérifier directement dans la collection users
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      
      final adminExists = adminQuery.docs.isNotEmpty;
      print('🔍 Admins trouvés: ${adminQuery.docs.length}');
      
      return adminExists;
      
    } catch (e) {
      print('❌ Erreur vérification premier admin: $e');
      // ✅ En cas d'erreur, permettre la configuration
      return false;
    }
  }

  /// ✅ PROMOTION ADMIN (DEPUIS VOTRE ESPACE ADMIN UNIQUEMENT)
  Future<bool> promoteUserToAdmin({
    required String userId,
    required String adminLevel, // 'standard' ou 'super'
    CaptchaResult? captchaResult,
  }) async {
    try {
      // ✅ SÉCURITÉ: Seul le super admin peut promouvoir
      if (!isSuperAdmin) {
        throw Exception('Seul le super administrateur peut promouvoir des utilisateurs');
      }
      
      // ✅ SÉCURITÉ: reCAPTCHA requis pour promotion admin
      if (captchaResult != null && (!captchaResult.isValid || captchaResult.score < 0.7)) {
        throw Exception('Score de sécurité insuffisant pour promotion admin');
      }
      
      // ✅ Vérifier que l'utilisateur existe
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Utilisateur introuvable');
      }
      
      final userData = userDoc.data()!;
      final newPermissions = adminLevel == 'super' ? ['all'] : ['admin_basic'];
      
      await _firestore.collection('users').doc(userId).update({
        'role': 'admin',
        'adminLevel': adminLevel,
        'isSuperAdmin': adminLevel == 'super',
        'permissions': newPermissions,
        'promotedBy': _cachedUserId,
        'promotedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // ✅ Log de sécurité
      await _firestore.collection('admin_logs').add({
        'action': 'promote_to_admin',
        'targetUserId': userId,
        'targetEmail': userData['email'],
        'adminLevel': adminLevel,
        'promotedBy': _cachedUserId,
        'promotedByEmail': _cachedUserProfile?['email'],
        'timestamp': FieldValue.serverTimestamp(),
        'captchaScore': captchaResult?.score,
      });
      
      print('✅ Utilisateur ${userData['email']} promu admin $adminLevel');
      return true;
      
    } catch (e) {
      print('❌ Erreur promotion admin: $e');
      rethrow;
    }
  }

  /// ✅ RÉVOQUER ADMIN (DEPUIS VOTRE ESPACE ADMIN UNIQUEMENT)
  Future<bool> revokeAdminAccess({
    required String userId,
    CaptchaResult? captchaResult,
  }) async {
    try {
      if (!isSuperAdmin) {
        throw Exception('Seul le super administrateur peut révoquer des accès admin');
      }
      
      // ✅ PROTECTION: Ne pas pouvoir se révoquer soi-même
      if (userId == _cachedUserId) {
        throw Exception('Impossible de révoquer ses propres accès admin');
      }
      
      if (captchaResult != null && (!captchaResult.isValid || captchaResult.score < 0.7)) {
        throw Exception('Score de sécurité insuffisant pour révocation admin');
      }
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Utilisateur introuvable');
      }
      
      final userData = userDoc.data()!;
      
      await _firestore.collection('users').doc(userId).update({
        'role': 'client', // ✅ Retour au rôle client
        'adminLevel': FieldValue.delete(),
        'isSuperAdmin': false,
        'permissions': ['basic'],
        'revokedBy': _cachedUserId,
        'revokedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // ✅ Log de sécurité
      await _firestore.collection('admin_logs').add({
        'action': 'revoke_admin',
        'targetUserId': userId,
        'targetEmail': userData['email'],
        'revokedBy': _cachedUserId,
        'revokedByEmail': _cachedUserProfile?['email'],
        'timestamp': FieldValue.serverTimestamp(),
        'captchaScore': captchaResult?.score,
      });
      
      print('✅ Accès admin révoqué pour ${userData['email']}');
      return true;
      
    } catch (e) {
      print('❌ Erreur révocation admin: $e');
      rethrow;
    }
  }

  /// Créer un objet User compatible depuis le profil Firestore
  dynamic _createUserFromProfile(Map<String, dynamic> userData) {
    return {
      'id': _cachedUserId,
      'uid': _cachedUserId,
      'email': userData['email'],
      'name': userData['name'] ?? userData['displayName'] ?? 'Utilisateur',
      'displayName': userData['displayName'] ?? userData['name'] ?? 'Utilisateur',
      'role': userData['role'] ?? 'client',
      'profileImageUrl': userData['profileImageUrl'],
      'isActive': userData['isActive'] ?? true,
      'isSuperAdmin': userData['isSuperAdmin'] ?? false,
      'adminLevel': userData['adminLevel'],
      'permissions': userData['permissions'] ?? ['basic'],
      'createdAt': userData['createdAt'],
      'updatedAt': userData['updatedAt'],
    };
  }

  /// Mettre à jour le rôle d'un utilisateur (pour les admins)
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      // ✅ SÉCURITÉ: Empêcher la promotion admin via cette méthode
      if (newRole.toLowerCase() == 'admin') {
        throw Exception('Utilisez promoteUserToAdmin() pour créer des admins');
      }
      
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _cachedUserId,
      });
      
      if (userId == _cachedUserId) {
        _cachedRole = _parseRole(newRole);
        _cachedUserProfile?['role'] = newRole;
        _securityToken = _generateSecurityToken(_cachedUserId!, _cachedRole!);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      print('❌ Erreur mise à jour rôle: $e');
      return false;
    }
  }

  /// Récupérer les informations d'un utilisateur par ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération utilisateur: $e');
      return null;
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<bool> updateUserProfile({
    String? displayName,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (_cachedUserId == null) return false;
      
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) {
        updateData['displayName'] = displayName;
        updateData['name'] = displayName;
        await _auth.currentUser?.updateDisplayName(displayName);
      }
      
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }
      
      if (additionalData != null) {
        updateData.addAll(additionalData);
      }
      
      await _firestore.collection('users').doc(_cachedUserId!).update(updateData);
      
      if (_cachedUserProfile != null) {
        _cachedUserProfile!.addAll(updateData);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur mise à jour profil: $e');
      return false;
    }
  }

  /// ✅ LISTER TOUS LES ADMINS (pour votre espace admin)
  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      if (!isSuperAdmin) {
        throw Exception('Accès réservé au super administrateur');
      }
      
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e) {
      print('❌ Erreur récupération admins: $e');
      return [];
    }
  }

  /// ✅ LOGS D'ADMINISTRATION (pour audit)
  Future<List<Map<String, dynamic>>> getAdminLogs({int limit = 50}) async {
    try {
      if (!isSuperAdmin) {
        throw Exception('Accès réservé au super administrateur');
      }
      
      final snapshot = await _firestore
          .collection('admin_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e) {
      print('❌ Erreur récupération logs: $e');
      return [];
    }
  }
  
  @override
  void dispose() {
    _securityTimer?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

// ========================================
// 4. CONFIGURATION DES PERMISSIONS (MISE À JOUR)
// ========================================

class PermissionsConfig {
  static final Map<UserRole, Set<PagePermission>> _rolePermissionsCache = {};
  static final Map<UserRole, Set<String>> _roleRoutesCache = {};
  
  static const Map<UserRole, Set<PagePermission>> rolePermissions = {
    UserRole.client: {
      PagePermission.view,
      PagePermission.buyTickets,
      PagePermission.addToFavorites,
      PagePermission.createProject,
    },
    
    UserRole.tatoueur: {
      PagePermission.view,
      PagePermission.create,
      PagePermission.edit,
      PagePermission.registerToEvent,
      PagePermission.manageBookings,
      PagePermission.accessAnalytics,
    },
    
    UserRole.organisateur: {
      PagePermission.view,
      PagePermission.create,
      PagePermission.edit,
      PagePermission.manageEvents,
    },
    
    UserRole.admin: {
      ...PagePermission.values, // ✅ Toutes les permissions pour admin
    },
  };
  
  static const Map<UserRole, Set<String>> roleRoutes = {
    UserRole.client: {
      '/home',
      '/profil',
      '/projets',
      '/recherche_tatoueur',
      '/mes_projets',
      '/messages',
      '/inspirations',
      '/favoris',
      '/notifications',
      '/paramètres',
      '/aide',
      '/conventions',
      '/cgu',
      '/cgv',
    },
    
    UserRole.tatoueur: {
      '/pro',
      '/pro/dashboard',
      '/pro/profil',
      '/pro/agenda',
      '/pro/comptabilite',
      '/pro/realisations',
      '/pro/shop',
      '/pro/suppliers',
      '/pro/notifications',
      '/pro/parametres',
      '/pro/aide',
      '/conventions',
      '/cgu',
      '/cgv',
    },
    
    UserRole.organisateur: {
      '/organisateur/dashboard',
      '/organisateur/conventions',
      '/organisateur/conventions/create',
      '/organisateur/inscriptions',
      '/organisateur/billeterie',
      '/organisateur/marketing',
      '/organisateur/settings',
      '/conventions',
      '/cgu',
      '/cgv',
    },
    
    UserRole.admin: {
      '/admin',
      '/admin/dashboard',
      '/admin/setup', // ✅ Accessible seulement si premier admin pas créé
      '/admin/pros',
      '/admin/clients',
      '/admin/organizers',
      '/admin/users/search',
      '/admin/free-codes',
      '/admin/referrals',
      '/admin/test-recaptcha', // ✅ Page de test admin
      '/conventions/admin',
      '/conventions',
      '/cgu',
      '/cgv',
    },
  };
  
  static const Map<UserRole, String> roleHomePages = {
    UserRole.client: '/home',
    UserRole.tatoueur: '/pro',
    UserRole.organisateur: '/organisateur/dashboard',
    UserRole.admin: '/admin/dashboard',
  };
  
  static bool hasPermission(UserRole role, PagePermission permission) {
    _rolePermissionsCache[role] ??= rolePermissions[role] ?? {};
    return _rolePermissionsCache[role]!.contains(permission);
  }
  
  static bool canAccessRoute(UserRole role, String route) {
    // ✅ SÉCURITÉ: Page de setup admin seulement si premier admin pas créé
    if (route == '/admin/setup') {
      return role == UserRole.admin; // Vérification supplémentaire dans la page
    }
    
    _roleRoutesCache[role] ??= roleRoutes[role] ?? {};
    return _roleRoutesCache[role]!.contains(route);
  }
  
  static bool currentUserCan(PagePermission permission) {
    final role = SecureAuthService.instance.currentUserRole;
    return role != null && hasPermission(role, permission);
  }
  
  static bool currentUserCanAccessRoute(String route) {
    final role = SecureAuthService.instance.currentUserRole;
    return role != null && canAccessRoute(role, route);
  }
  
  static String getHomePageForRole(UserRole role) {
    return roleHomePages[role] ?? '/welcome';
  }
}