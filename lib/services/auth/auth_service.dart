// lib/services/auth/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart' as AppUser;
import '../../models/user_role.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  AuthService._internal() {
    // Écouter les changements d'authentification
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser.User? _currentUser;
  UserRole? _currentUserRole;
  bool _isLoading = false;

  // Getters
  AppUser.User? get currentUser => _currentUser;
  UserRole? get currentUserRole => _currentUserRole;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  // Méthodes de vérification de rôle
  bool isAdmin() => _currentUserRole == UserRole.admin;
  bool isTatoueur() => _currentUserRole == UserRole.tatoueur;
  bool isOrganisateur() => _currentUserRole == UserRole.organisateur;
  bool isParticulier() => _currentUserRole == UserRole.client;

  // ========================================
  // CORRECTION 1: _onAuthStateChanged avec paramètre
  // ========================================
  Future<void> _onAuthStateChanged(auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser);
    } else {
      _currentUser = null;
      _currentUserRole = null;
    }
    notifyListeners();
  }

  // ========================================
  // CORRECTION 2: _loadUserData avec paramètre et votre modèle
  // ========================================
  Future<void> _loadUserData(auth.User firebaseUser) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        
        // Créer l'objet User de l'app avec TOUS les champs obligatoires
        _currentUser = AppUser.User(
          uid: firebaseUser.uid,
          name: data['name'] ?? firebaseUser.displayName ?? 'Utilisateur',
          email: data['email'] ?? firebaseUser.email,
          phone: data['phone'] as String?,
          profileImageUrl: data['profileImageUrl'] as String?,
          role: UserRoleExtension.fromString(data['role'] ?? 'client'),
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          lastLoginAt: data['lastLoginAt']?.toDate(),
          isActive: data['isActive'] ?? true,
          additionalData: data['additionalData'] as Map<String, dynamic>?,
        );

        // Le rôle est déjà défini dans l'objet User
        _currentUserRole = _currentUser!.role;
      } else {
        // Si le document n'existe pas, créer un utilisateur par défaut
        await _createUserDocument(firebaseUser);
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  // ========================================
  // CORRECTION 3: signInWithEmailAndPassword avec paramètres
  // ========================================
  Future<UserRole?> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Connexion Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Charger les données utilisateur
        await _loadUserData(credential.user!);
        
        // Mettre à jour la dernière connexion
        await _updateLastLogin();
        
        return _currentUserRole;
      }
      
      return null;
    } catch (e) {
      print('Erreur connexion: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // MÉTHODES SUPPLÉMENTAIRES UTILES
  // ========================================

  // Créer un document utilisateur s'il n'existe pas
  Future<void> _createUserDocument(auth.User firebaseUser) async {
    try {
      final newUser = AppUser.User(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Nouvel utilisateur',
        email: firebaseUser.email,
        role: UserRole.client, // Rôle par défaut
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toFirestore());

      _currentUser = newUser;
      _currentUserRole = newUser.role;
    } catch (e) {
      print('Erreur création document utilisateur: $e');
    }
  }

  // Mettre à jour la dernière connexion
  Future<void> _updateLastLogin() async {
    if (_currentUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .update({'lastLoginAt': FieldValue.serverTimestamp()});
        
        // Mettre à jour l'objet local
        _currentUser = _currentUser!.copyWith(lastLoginAt: DateTime.now());
      } catch (e) {
        print('Erreur mise à jour dernière connexion: $e');
      }
    }
  }

  // Inscription d'un nouvel utilisateur
  Future<UserRole?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.client,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Créer le compte Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Mettre à jour le profil Firebase
        await credential.user!.updateDisplayName(name);

        // Créer l'utilisateur dans notre système
        final newUser = AppUser.User(
          uid: credential.user!.uid,
          name: name,
          email: email,
          role: role,
          createdAt: DateTime.now(),
          isActive: true,
        );

        // Sauvegarder dans Firestore
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser.toFirestore());

        _currentUser = newUser;
        _currentUserRole = newUser.role;

        return _currentUserRole;
      }

      return null;
    } catch (e) {
      print('Erreur inscription: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _currentUserRole = null;
      notifyListeners();
    } catch (e) {
      print('Erreur déconnexion: $e');
    }
  }

  // Mettre à jour le profil utilisateur
  Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return false;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .update(updates);

        // Mettre à jour l'objet local
        _currentUser = _currentUser!.copyWith(
          name: name,
          phone: phone,
          profileImageUrl: profileImageUrl,
        );

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('Erreur mise à jour profil: $e');
      return false;
    }
  }

  // Réinitialiser le mot de passe
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Erreur réinitialisation mot de passe: $e');
      return false;
    }
  }

  // Recharger les données utilisateur
  Future<void> reloadUserData() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser);
      notifyListeners();
    }
  }

  // Supprimer le compte utilisateur
  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    try {
      // Supprimer le document Firestore
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .delete();

      // Supprimer le compte Firebase
      await _auth.currentUser?.delete();

      _currentUser = null;
      _currentUserRole = null;
      notifyListeners();

      return true;
    } catch (e) {
      print('Erreur suppression compte: $e');
      return false;
    }
  }
}