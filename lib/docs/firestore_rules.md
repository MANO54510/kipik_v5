# 🔒 Règles de Sécurité Firestore - KIPIK

## 📋 Vue d'ensemble

Ce document détaille les règles de sécurité Firestore pour l'application KIPIK, garantissant un cloisonnement total entre utilisateurs et le respect des fonctionnalités Premium.

## 🎯 Modèle de Sécurité

### Principes Fondamentaux
- **Cloisonnement total** : Chaque utilisateur ne peut accéder qu'à ses propres données
- **Principe du moindre privilège** : Accès minimum nécessaire seulement
- **Filtrage obligatoire** : Toutes les requêtes list doivent être filtrées
- **Contrôle Premium** : Fonctionnalités Premium strictement contrôlées

### Rôles Utilisateurs
- **Client** : Recherche tatoueurs, réserve événements, gère ses projets
- **Tatoueur** : Gère son profil/shop/portfolio, accepte projets, candidate aux événements
- **Organisateur** : Gère ses événements, valide candidatures tatoueurs
- **Admin** : Accès complet pour modération et administration

## 🔐 Règles par Collection

### 👥 USERS - Profils Utilisateurs

#### Lecture
```javascript
allow read: if request.auth != null && (
  // Auto-accès complet
  request.auth.uid == userId ||
  
  // Profils tatoueurs publics (clients + organisateurs)
  (resource.data.role == 'tatoueur' && 
   resource.data.isPublic == true && 
   getUserRole() in ['client', 'organisateur']) ||
  
  // Profils clients (tatoueurs avec relation active)
  (resource.data.role == 'client' && 
   getUserRole() == 'tatoueur' && 
   hasActiveRelation(request.auth.uid, userId)) ||
   
  // Admins voient tout
  isAdmin()
);
```

#### Écriture
- ✅ **Propriétaire** : Modification de son propre profil
- ✅ **Admin** : Modification de tous les profils
- ❌ **Autres** : Interdiction totale

#### Liste
- ✅ **Clients** : Recherche tatoueurs publics (avec filtres obligatoires)
- ✅ **Organisateurs** : Liste tatoueurs pour validation
- ✅ **Admins** : Liste complète
- ❌ **Autres** : Interdiction

### 🏪 SHOPS - Boutiques Tatoueurs

#### Visibilité
- **Clients** : Shops publics pour navigation/recherche
- **Organisateurs** : Shops publics pour validation tatoueurs
- **Propriétaire** : Son propre shop (public + privé)
- **Admins** : Tous les shops

#### Contrôle d'accès
```javascript
allow read: if request.auth != null && (
  request.auth.uid == resource.data.tattooistId ||
  (getUserRole() in ['client', 'organisateur'] && 
   resource.data.isPublic == true) ||
  isAdmin()
);
```

### 🎨 PORTFOLIOS - Réalisations

#### Visibilité
- **Clients** : Portfolios publics pour découverte
- **Organisateurs** : Portfolios publics pour validation
- **Propriétaire** : Ses propres portfolios
- **Admins** : Tous les portfolios

#### Règles spéciales
- Filtrage obligatoire sur `isPublic: true` pour non-propriétaires
- Création seulement par le tatoueur propriétaire

### 🎪 EVENTS - Événements

#### Accès Public
- **Tous** : Lecture des événements publics
- **Organisateur** : Gestion complète de ses événements
- **Admins** : Accès total

#### Billetterie
- Intégration avec `event_registrations` et `event_tickets`
- Contrôle des capacités et disponibilités

### 🎫 EVENT_REGISTRATIONS - Réservations

#### Accès Restreint
- **Client** : Ses propres réservations
- **Organisateur** : Réservations pour ses événements
- **Admins** : Toutes les réservations

#### Validation
```javascript
allow create: if request.auth != null && 
               getUserRole() == 'client' &&
               request.auth.uid == request.resource.data.clientId;
```

### 🏢 EVENT_APPLICATIONS - Candidatures Événements

#### Workflow
1. **Tatoueur** : Soumet candidature
2. **Organisateur** : Évalue et répond
3. **Système** : Gère les notifications

#### Sécurité
- Tatoueur ne peut candidater que pour lui-même
- Organisateur ne peut répondre qu'à ses événements

## 💎 Collections Premium

### 🏃‍♂️ GUEST_APPLICATIONS - Mobilité Tatoueur→Shop

#### Restrictions Premium
```javascript
allow create: if request.auth != null && 
               getUserRole() == 'tatoueur' &&
               hasPremiumSubscription() &&
               request.auth.uid == request.resource.data.tattooistId;
```

#### Accès
- **Tatoueur candidat** : Sa candidature
- **Shop owner** : Candidatures reçues
- **Admins** : Toutes les candidatures

### 🏪 GUEST_OFFERS - Propositions Shop→Tatoueur

#### Workflow Premium
1. **Shop Premium** : Propose à un tatoueur
2. **Tatoueur** : Accepte/refuse/négocie
3. **Système** : Crée collaboration si accepté

### 🤝 GUEST_COLLABORATIONS - Collaborations Actives

#### Suivi Performance
- Revenus partagés
- Évaluations croisées
- Statistiques de performance

## 🛡️ Fonctions de Sécurité

### Validation des Rôles
```javascript
function getUserRole() {
  return request.auth.token.role;
}

function isAdmin() {
  return request.auth.token.role == 'admin';
}
```

### Contrôle Premium
```javascript
function hasPremiumSubscription() {
  return request.auth.token.subscription == 'premium';
}

function hasStandardOrPremium() {
  return request.auth.token.subscription in ['standard', 'premium'];
}

function isInTrialPeriod() {
  return request.auth.token.trialActive == true;
}
```

### Validation des Relations
```javascript
function hasActiveRelation(userId1, userId2) {
  return exists(/databases/$(database)/documents/appointments/$(userId1 + "_" + userId2)) ||
         exists(/databases/$(database)/documents/projects/$(userId1 + "_" + userId2));
}

function hasEventRelation(userId1, userId2) {
  return exists(/databases/$(database)/documents/event_registrations/$(userId1 + "_" + userId2));
}
```

## 🚨 Points Critiques de Sécurité

### ❌ Interdictions Absolues
- **Listing sans filtre** : Toutes les requêtes `list` doivent être filtrées
- **Accès croisé** : Un utilisateur ne peut pas lire les données d'un autre sans relation
- **Escalade de privilèges** : Impossible de modifier son rôle ou permissions
- **Bypass Premium** : Collections Premium strictement contrôlées

### ✅ Protections Actives
- **Custom Claims** : Rôles et abonnements vérifiés côté serveur
- **Audit Trail** : Toutes les opérations tracées par Firebase
- **Rate Limiting** : Protection contre le spam intégrée
- **Validation Schema** : Structures de données validées

## 🔧 Maintenance et Monitoring

### Logs à Surveiller
- Tentatives d'accès non autorisées
- Erreurs de permissions répétées
- Accès anormaux aux collections Premium
- Requêtes sans filtrage approprié

### Tests de Sécurité
```bash
# Tester les règles avec Firebase Emulator
firebase emulators:start --only firestore
npm run test:security-rules
```

### Mise à Jour des Règles
1. Modifier les règles en développement
2. Tester avec l'émulateur
3. Déployer sur Firestore Test
4. Valider en production
5. Déployer sur Firestore Production

## 📊 Métriques de Sécurité

### KPIs à Suivre
- **Taux d'erreurs de permissions** : < 0.1%
- **Temps de réponse règles** : < 50ms
- **Tentatives d'intrusion** : 0 succès
- **Conformité RGPD** : 100%

### Alertes Critiques
- Accès admin non autorisé
- Modification de données utilisateur par tiers
- Bypass détecté des restrictions Premium
- Volume anormal de requêtes refusées

---

## 📞 Support

Pour toute question sur les règles de sécurité :
- **Email** : security@kipik.ink
- **Documentation** : https://docs.kipik.ink/security
- **Incident** : security-incident@kipik.ink

---

*Dernière mise à jour : 8 juillet 2025*
*Version : 1.0*