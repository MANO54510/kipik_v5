// lib/services/auth/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/models/user.dart' as AppUser;
import 'package:kipik_v5/models/pro_user.dart';
import 'package:kipik_v5/utils/constants.dart'; // Import UserRole depuis constants.dart

class AuthService {
  // Singleton accessible partout
  static final AuthService instance = AuthService._internal();
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Utilisateur courant
  AppUser.User? _currentUser;
  UserRole? _currentUserRole;
  
  // État d'authentification
  bool _isLoading = false;
  
  // Getters
  bool get isAuthenticated => _auth.currentUser != null;
  bool get isLoading => _isLoading;
  AppUser.User? get currentUser => _currentUser;
  UserRole? get currentUserRole => _currentUserRole;
  
  // Constructeur privé
  AuthService._internal() {
    // Écouter les changements d'authentification
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  /// Initialiser l'AuthService
  Future<void> initialize() async {
    _isLoading = true;
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserData(user);
    }
    _isLoading = false;
  }
  
  /// Écoute les changements d'état d'authentification
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser);
    } else {
      _currentUser = null;
      _currentUserRole = null;
    }
  }
  
  /// Charge les données utilisateur depuis Firestore
  Future<void> _loadUserData(User firebaseUser) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        
        // Créer l'objet User de l'app
        _currentUser = AppUser.User(
          id: firebaseUser.uid,
          name: data['name'] ?? firebaseUser.displayName ?? 'Utilisateur',
          email: firebaseUser.email,
          profileImageUrl: data['profileImageUrl'],
          bannerImageUrl: data['bannerImageUrl'],
        );
        
        // Déterminer le rôle en utilisant UserRoleExtension
        final roleString = data['role'] as String?;
        _currentUserRole = roleString != null ? UserRoleExtension.fromString(roleString) : null;
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
    }
  }
  
  /// Connexion avec email/mot de passe
  Future<UserRole?> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        await _loadUserData(credential.user!);
        return _currentUserRole;
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      print('Erreur de connexion Firebase: ${e.code} - ${e.message}');
      rethrow; // Re-lancer l'erreur pour une gestion plus fine
    } catch (e) {
      print('Erreur de connexion: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
  
  /// Créer un compte utilisateur
  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      _isLoading = true;
      
      // Créer le compte Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        // Créer le document utilisateur dans Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email.trim(),
          'role': role.value, // Utilise l'extension pour récupérer la valeur string
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'profileImageUrl': null,
          'bannerImageUrl': null,
          ...?extraData,
        });
        
        // Mettre à jour le profil Firebase
        await credential.user!.updateDisplayName(name);
        
        // Charger les données
        await _loadUserData(credential.user!);
        
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      print('Erreur de création de compte Firebase: ${e.code} - ${e.message}');
      rethrow; // Re-lancer pour gestion d'erreur fine
    } catch (e) {
      print('Erreur de création de compte: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
  
  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _currentUserRole = null;
    } catch (e) {
      print('Erreur de déconnexion: $e');
      rethrow;
    }
  }
  
  /// Vérifications de rôles
  bool isAdmin() => _currentUserRole == UserRole.admin;
  bool isOrganisateur() => _currentUserRole == UserRole.organisateur;
  bool isTatoueur() => _currentUserRole == UserRole.tatoueur;
  bool isClient() => _currentUserRole == UserRole.client;
  
  /// Renvoie les informations de l'utilisateur pro actuel
  Future<ProUser?> getCurrentProUser() async {
    if (!isTatoueur() || _currentUser == null) return null;
    
    try {
      final proDoc = await _firestore
          .collection('pros')
          .doc(_currentUser!.id)
          .get();
      
      if (!proDoc.exists) return null;
      
      final data = proDoc.data()!;
      return ProUser(
        id: _currentUser!.id,
        email: _currentUser!.email ?? '',
        nomEntreprise: data['nomEntreprise'] ?? '',
        siret: data['siret'] ?? '',
        telephone: data['telephone'] ?? '',
        adresse: data['adresse'] ?? '',
        codePostal: data['codePostal'] ?? '',
        ville: data['ville'] ?? '',
        pays: data['pays'] ?? 'France',
        abonnementType: data['abonnementType'] ?? 'Free',
        abonnementDateDebut: (data['abonnementDateDebut'] as Timestamp?)?.toDate() ?? DateTime.now(),
        abonnementDateFin: (data['abonnementDateFin'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isActive: data['isActive'] ?? true,
        roles: List<String>.from(data['roles'] ?? ['user']),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur pro: $e');
      return null;
    }
  }
  
  /// Méthode helper pour créer le premier admin (à utiliser une seule fois)
  Future<bool> createFirstAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    return await createUserWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
      role: UserRole.admin,
      extraData: {
        'permissions': ['full_access'],
        'isSuperAdmin': true,
      },
    );
  }
  
  // Compatibilité avec l'ancien système
  Future<bool> registerParticulier({
    required String email,
    required String password,
    required Map<String, dynamic> extraFields,
  }) async {
    return await createUserWithEmailAndPassword(
      email: email,
      password: password,
      name: extraFields['name'] ?? 'Client',
      role: UserRole.client,
      extraData: extraFields,
    );
  }
  
  Future<bool> registerPro({
    required String email,
    required String password,
    required Map<String, dynamic> extraFields,
  }) async {
    return await createUserWithEmailAndPassword(
      email: email,
      password: password,
      name: extraFields['name'] ?? 'Tatoueur',
      role: UserRole.tatoueur,
      extraData: extraFields,
    );
  }
  
  Future<bool> registerOrganisateur({
    required String email,
    required String password,
    required String name,
    required String company,
    required String phone,
    String? website,
  }) async {
    return await createUserWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
      role: UserRole.organisateur,
      extraData: {
        'company': company,
        'phone': phone,
        'website': website,
      },
    );
  }
  
  // Compatibilité avec l'ancien système
  Future<bool> signIn(String email, String password) async {
    final role = await signInWithEmailAndPassword(email, password);
    return role != null;
  }

  // AJOUT : Méthode pour mettre à jour l'utilisateur (pour compatibilité)
  set currentUser(AppUser.User? user) {
    _currentUser = user;
  }

  // AJOUT : Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Erreur lors de la réinitialisation: ${e.message}');
      rethrow;
    }
  }

  // AJOUT : Vérifier l'email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de vérification: $e');
      rethrow;
    }
  }
}