// lib/utils/auth_helper.dart
import 'package:kipik_v5/services/auth/auth_service.dart';

// Export des enums pour compatibilité
export 'package:kipik_v5/services/auth/auth_service.dart' show UserRole;

/// Vérifie les crédentials via Firebase Auth et renvoie le rôle de l'utilisateur
Future<UserRole?> checkUserCredentials(String email, String password) async {
  try {
    // Utiliser le nouveau AuthService connecté à Firebase
    final role = await AuthService.instance.signInWithEmailAndPassword(email, password);
    return role;
  } catch (e) {
    print('Erreur lors de la vérification des crédentials: $e');
    return null;
  }
}

/// Fonction helper pour créer le premier admin
/// À utiliser une seule fois pour vous créer votre compte
Future<bool> createFirstAdminAccount() async {
  try {
    final success = await AuthService.instance.createFirstAdmin(
      email: 'mano@kipik.ink',
      password: 'VotreMotDePasseSecurise123!', // ← Changez ça !
      name: 'Mano Admin',
    );
    
    if (success) {
      print('✅ Compte admin créé avec succès !');
      print('📧 Email: mano@kipik.ink');
      print('🔑 Mot de passe: VotreMotDePasseSecurise123!');
    } else {
      print('❌ Erreur lors de la création du compte admin');
    }
    
    return success;
  } catch (e) {
    print('❌ Erreur: $e');
    return false;
  }
}

/// Fonction pour créer des comptes de test (optionnel)
Future<void> createTestAccounts() async {
  final authService = AuthService.instance;
  
  // Créer un client de test
  await authService.createUserWithEmailAndPassword(
    email: 'client@kipik.ink',
    password: 'Client123!',
    name: 'Client Test',
    role: UserRole.client,
  );
  
  // Créer un tatoueur de test
  await authService.createUserWithEmailAndPassword(
    email: 'tatoueur@kipik.ink',
    password: 'Tatoueur123!',
    name: 'Tatoueur Test',
    role: UserRole.tatoueur,
  );
  
  // Créer un organisateur de test
  await authService.createUserWithEmailAndPassword(
    email: 'organisateur@kipik.ink',
    password: 'Orga123!',
    name: 'Organisateur Test',
    role: UserRole.organisateur,
  );
  
  print('✅ Comptes de test créés !');
}