// lib/services/project/firebase_project_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/models/project_model.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ MIGRATION
import 'package:kipik_v5/models/user_role.dart'; // ✅ MIGRATION

class FirebaseProjectService {
  static FirebaseProjectService? _instance;
  static FirebaseProjectService get instance => _instance ??= FirebaseProjectService._();
  FirebaseProjectService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'projects';

  /// Collection avec converter pour une gestion automatique des types
  CollectionReference<ProjectModel> get _projectsCollection {
    return _firestore
        .collection(_collection)
        .withConverter<ProjectModel>(
          fromFirestore: (snapshot, _) => ProjectModel.fromMap(snapshot.id, snapshot.data()!),
          toFirestore: (project, _) => project.toMap(),
        );
  }

  /// ✅ MIGRATION: Getter sécurisé pour l'utilisateur actuel
  String? get _currentUserId => SecureAuthService.instance.currentUserId;
  UserRole? get _currentUserRole => SecureAuthService.instance.currentUserRole;
  dynamic get _currentUser => SecureAuthService.instance.currentUser;

  /// ✅ SÉCURITÉ: Vérification d'authentification obligatoire
  void _ensureAuthenticated() {
    if (_currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }
  }

  /// Récupérer tous les projets de l'utilisateur connecté
  Future<List<ProjectModel>> fetchProjects() async {
    try {
      _ensureAuthenticated(); // ✅ Vérification sécurisée

      final snapshot = await _projectsCollection
          .where('tattooistId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des projets: $e');
    }
  }

  /// Récupérer un projet par son ID avec vérification des permissions
  Future<ProjectModel?> fetchProjectById(String projectId) async {
    try {
      _ensureAuthenticated();

      final doc = await _projectsCollection.doc(projectId).get();
      
      if (!doc.exists) {
        return null;
      }

      final project = doc.data()!;
      
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur peut accéder à ce projet
      if (!await canAccessProject(projectId)) {
        throw Exception('Accès refusé à ce projet');
      }

      return project;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du projet: $e');
    }
  }

  /// Créer un nouveau projet
  Future<String> createProject(ProjectModel project) async {
    try {
      _ensureAuthenticated(); // ✅ Vérification sécurisée
      
      // ✅ MIGRATION: Récupération sécurisée des informations utilisateur
      final tattooistName = _currentUser != null 
          ? (_currentUser['displayName'] ?? _currentUser['name'] ?? 'Tatoueur')
          : 'Tatoueur';

      // ✅ SÉCURITÉ: S'assurer que le tatoueur est bien l'utilisateur actuel
      final projectWithUserInfo = project.copyWith(
        tattooistId: _currentUserId!,
        tattooistName: tattooistName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _projectsCollection.add(projectWithUserInfo);
      
      // ✅ LOG: Création de projet
      print('✅ Projet créé: ${project.title} (ID: ${docRef.id})');
      
      return docRef.id;
    } catch (e) {
      print('❌ Erreur création projet: $e');
      throw Exception('Erreur lors de la création du projet: $e');
    }
  }

  /// Mettre à jour un projet avec un objet ProjectModel complet
  Future<void> updateProjectModel(ProjectModel project) async {
    try {
      _ensureAuthenticated();
      
      // ✅ SÉCURITÉ: Vérifier les permissions avant mise à jour
      if (!await canAccessProject(project.id)) {
        throw Exception('Accès refusé pour modifier ce projet');
      }

      final updatedProject = project.copyWith(updatedAt: DateTime.now());
      await _projectsCollection.doc(project.id).set(updatedProject);
      
      print('✅ Projet mis à jour: ${project.title}');
    } catch (e) {
      print('❌ Erreur mise à jour projet: $e');
      throw Exception('Erreur lors de la mise à jour du projet: $e');
    }
  }

  /// Mettre à jour un projet avec des champs spécifiques
  Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    try {
      _ensureAuthenticated();
      
      // ✅ SÉCURITÉ: Vérifier les permissions
      if (!await canAccessProject(projectId)) {
        throw Exception('Accès refusé pour modifier ce projet');
      }

      // ✅ SÉCURITÉ: Empêcher la modification de certains champs sensibles
      final forbiddenFields = ['tattooistId', 'id', 'createdAt'];
      for (final field in forbiddenFields) {
        if (updates.containsKey(field)) {
          updates.remove(field);
          print('⚠️ Champ protégé ignoré: $field');
        }
      }

      // Convertir les DateTime en Timestamp si nécessaire
      if (updates.containsKey('appointmentDate') && updates['appointmentDate'] is DateTime) {
        updates['appointmentDate'] = Timestamp.fromDate(updates['appointmentDate']);
      }
      if (updates.containsKey('completionDate') && updates['completionDate'] is DateTime) {
        updates['completionDate'] = Timestamp.fromDate(updates['completionDate']);
      }
      
      updates['updatedAt'] = FieldValue.serverTimestamp();
      updates['updatedBy'] = _currentUserId; // ✅ Traçabilité
      
      await _firestore.collection(_collection).doc(projectId).update(updates);
      
      print('✅ Projet mis à jour: $projectId');
    } catch (e) {
      print('❌ Erreur mise à jour projet: $e');
      throw Exception('Erreur lors de la mise à jour du projet: $e');
    }
  }

  /// Changer le statut d'un projet
  Future<void> updateProjectStatus(String projectId, ProjectStatus status) async {
    try {
      _ensureAuthenticated();
      
      // ✅ SÉCURITÉ: Vérifier les permissions
      if (!await canAccessProject(projectId)) {
        throw Exception('Accès refusé pour modifier ce projet');
      }

      final updates = <String, dynamic>{
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': _currentUserId, // ✅ Traçabilité
      };

      // Ajouter la date de completion si le statut est completed
      if (status == ProjectStatus.completed) {
        updates['completionDate'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_collection).doc(projectId).update(updates);
      
      print('✅ Statut projet mis à jour: $projectId -> ${status.toString()}');
    } catch (e) {
      print('❌ Erreur mise à jour statut: $e');
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  /// Ajouter des images à un projet
  Future<void> addImagesToProject(
    String projectId, 
    List<String> imageUrls, 
    String imageType // 'reference', 'sketch', 'final'
  ) async {
    try {
      _ensureAuthenticated();
      
      // ✅ SÉCURITÉ: Vérifier les permissions
      if (!await canAccessProject(projectId)) {
        throw Exception('Accès refusé pour modifier ce projet');
      }

      // ✅ VALIDATION: Types d'images autorisés
      final allowedTypes = ['reference', 'sketch', 'final'];
      if (!allowedTypes.contains(imageType)) {
        throw Exception('Type d\'image non autorisé: $imageType');
      }

      final fieldName = '${imageType}Images';
      await _firestore.collection(_collection).doc(projectId).update({
        fieldName: FieldValue.arrayUnion(imageUrls),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastImageUpdate': FieldValue.serverTimestamp(),
        'lastImageUpdateBy': _currentUserId,
      });
      
      print('✅ Images ajoutées: $projectId ($imageType: ${imageUrls.length})');
    } catch (e) {
      print('❌ Erreur ajout images: $e');
      throw Exception('Erreur lors de l\'ajout des images: $e');
    }
  }

  /// Supprimer des images d'un projet
  Future<void> removeImagesFromProject(
    String projectId, 
    List<String> imageUrls, 
    String imageType
  ) async {
    try {
      _ensureAuthenticated();
      
      // ✅ SÉCURITÉ: Vérifier les permissions
      if (!await canAccessProject(projectId)) {
        throw Exception('Accès refusé pour modifier ce projet');
      }

      final allowedTypes = ['reference', 'sketch', 'final'];
      if (!allowedTypes.contains(imageType)) {
        throw Exception('Type d\'image non autorisé: $imageType');
      }

      final fieldName = '${imageType}Images';
      await _firestore.collection(_collection).doc(projectId).update({
        fieldName: FieldValue.arrayRemove(imageUrls),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastImageRemoval': FieldValue.serverTimestamp(),
        'lastImageRemovalBy': _currentUserId,
      });
      
      print('✅ Images supprimées: $projectId ($imageType: ${imageUrls.length})');
    } catch (e) {
      print('❌ Erreur suppression images: $e');
      throw Exception('Erreur lors de la suppression des images: $e');
    }
  }

  /// Supprimer un projet
  Future<void> deleteProject(String projectId) async {
    try {
      _ensureAuthenticated();
      
      // ✅ SÉCURITÉ: Vérifier les permissions
      if (!await canAccessProject(projectId)) {
        throw Exception('Accès refusé pour supprimer ce projet');
      }

      // ✅ SÉCURITÉ: Seul le tatoueur propriétaire ou un admin peut supprimer
      final doc = await _firestore.collection(_collection).doc(projectId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final tattooistId = data['tattooistId'] as String?;
        
        if (tattooistId != _currentUserId && _currentUserRole != UserRole.admin) {
          throw Exception('Seul le tatoueur propriétaire peut supprimer ce projet');
        }
      }

      await _projectsCollection.doc(projectId).delete();
      
      print('✅ Projet supprimé: $projectId');
    } catch (e) {
      print('❌ Erreur suppression projet: $e');
      throw Exception('Erreur lors de la suppression du projet: $e');
    }
  }

  /// Rechercher des projets par critères
  Future<List<ProjectModel>> searchProjects({
    String? status,
    String? category,
    String? style,
    String? clientId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isPublic,
  }) async {
    try {
      _ensureAuthenticated(); // ✅ Vérification sécurisée

      Query<ProjectModel> query = _projectsCollection
          .where('tattooistId', isEqualTo: _currentUserId);

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (style != null && style.isNotEmpty) {
        query = query.where('style', isEqualTo: style);
      }

      if (clientId != null && clientId.isNotEmpty) {
        query = query.where('clientId', isEqualTo: clientId);
      }

      if (isPublic != null) {
        query = query.where('isPublic', isEqualTo: isPublic);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      final results = snapshot.docs.map((doc) => doc.data()).toList();
      
      print('✅ Recherche projets: ${results.length} résultats');
      return results;
    } catch (e) {
      print('❌ Erreur recherche projets: $e');
      throw Exception('Erreur lors de la recherche de projets: $e');
    }
  }

  /// Obtenir les projets d'un client spécifique
  Future<List<ProjectModel>> getProjectsByClient(String clientId) async {
    try {
      _ensureAuthenticated(); // ✅ Vérification sécurisée

      final snapshot = await _projectsCollection
          .where('tattooistId', isEqualTo: _currentUserId)
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      final results = snapshot.docs.map((doc) => doc.data()).toList();
      print('✅ Projets client $clientId: ${results.length}');
      return results;
    } catch (e) {
      print('❌ Erreur projets client: $e');
      throw Exception('Erreur lors de la récupération des projets du client: $e');
    }
  }

  /// Obtenir les projets publics pour le portfolio
  Future<List<ProjectModel>> getPublicProjects({int? limit}) async {
    try {
      _ensureAuthenticated(); // ✅ Vérification sécurisée

      Query<ProjectModel> query = _projectsCollection
          .where('tattooistId', isEqualTo: _currentUserId)
          .where('isPublic', isEqualTo: true)
          .where('status', isEqualTo: 'completed')
          .orderBy('completionDate', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final results = snapshot.docs.map((doc) => doc.data()).toList();
      
      print('✅ Projets publics: ${results.length}');
      return results;
    } catch (e) {
      print('❌ Erreur projets publics: $e');
      throw Exception('Erreur lors de la récupération des projets publics: $e');
    }
  }

  /// Stream des projets (temps réel)
  Stream<List<ProjectModel>> projectsStream() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return Stream.empty();
    }

    return _projectsCollection
        .where('tattooistId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Stream d'un projet spécifique avec vérification des permissions
  Stream<ProjectModel?> projectStream(String projectId) {
    return _projectsCollection
        .doc(projectId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return null;
      
      // ✅ SÉCURITÉ: Vérifier les permissions en temps réel
      try {
        if (!await canAccessProject(projectId)) {
          return null; // Retourner null si pas d'accès
        }
        return doc.data();
      } catch (e) {
        print('❌ Erreur vérification permissions stream: $e');
        return null;
      }
    });
  }

  /// Mettre à jour l'activité de chat d'un projet
  Future<void> updateChatActivity(String projectId) async {
    try {
      _ensureAuthenticated();
      
      // ✅ SÉCURITÉ: Vérifier les permissions
      if (!await canAccessProject(projectId)) {
        throw Exception('Accès refusé pour ce projet');
      }

      await _firestore.collection(_collection).doc(projectId).update({
        'lastChatActivity': FieldValue.serverTimestamp(),
        'lastChatActivityBy': _currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Activité chat mise à jour: $projectId');
    } catch (e) {
      print('❌ Erreur mise à jour chat: $e');
      throw Exception('Erreur lors de la mise à jour de l\'activité de chat: $e');
    }
  }

  /// Obtenir les statistiques des projets
  Future<Map<String, int>> getProjectStats() async {
    try {
      _ensureAuthenticated(); // ✅ Vérification sécurisée

      final snapshot = await _firestore
          .collection(_collection)
          .where('tattooistId', isEqualTo: _currentUserId)
          .get();

      int pending = 0;
      int accepted = 0;
      int inProgress = 0;
      int completed = 0;
      int cancelled = 0;
      int onHold = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final status = data['status'] as String?;
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'accepted':
            accepted++;
            break;
          case 'inProgress':
            inProgress++;
            break;
          case 'completed':
            completed++;
            break;
          case 'cancelled':
            cancelled++;
            break;
          case 'onHold':
            onHold++;
            break;
        }
      }

      final stats = {
        'total': snapshot.docs.length,
        'pending': pending,
        'accepted': accepted,
        'inProgress': inProgress,
        'completed': completed,
        'cancelled': cancelled,
        'onHold': onHold,
      };

      print('✅ Stats projets calculées: ${stats['total']} total');
      return stats;
    } catch (e) {
      print('❌ Erreur stats projets: $e');
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// ✅ SÉCURITÉ: Vérifier si l'utilisateur actuel peut accéder à un projet
  Future<bool> canAccessProject(String projectId) async {
    try {
      final currentUserId = _currentUserId;
      final currentUserRole = _currentUserRole;
      
      if (currentUserId == null) {
        print('❌ Accès refusé: utilisateur non connecté');
        return false;
      }
      
      final doc = await _firestore.collection(_collection).doc(projectId).get();
      if (!doc.exists) {
        print('❌ Projet inexistant: $projectId');
        return false;
      }
      
      final data = doc.data()!;
      final tattooistId = data['tattooistId'] as String?;
      final clientId = data['clientId'] as String?;
      
      // ✅ Admin peut tout voir
      if (currentUserRole == UserRole.admin) {
        print('✅ Accès admin autorisé: $projectId');
        return true;
      }
      
      // ✅ Tatoueur peut voir ses propres projets
      if (tattooistId == currentUserId) {
        print('✅ Accès tatoueur propriétaire: $projectId');
        return true;
      }
      
      // ✅ Client peut voir ses propres projets
      if (clientId == currentUserId) {
        print('✅ Accès client propriétaire: $projectId');
        return true;
      }
      
      print('❌ Accès refusé au projet: $projectId');
      return false;
    } catch (e) {
      print('❌ Erreur vérification accès: $e');
      return false;
    }
  }

  /// ✅ NOUVEAU: Obtenir les projets visibles par l'utilisateur actuel
  Future<List<ProjectModel>> getAccessibleProjects() async {
    try {
      _ensureAuthenticated();
      
      if (_currentUserRole == UserRole.admin) {
        // Admin voit tous les projets
        final snapshot = await _firestore
            .collection(_collection)
            .orderBy('updatedAt', descending: true)
            .get();
        
        return _convertDocumentsToProjects(snapshot.docs);
      } else {
        // Utilisateurs normaux voient seulement leurs projets
        return await fetchProjects();
      }
    } catch (e) {
      print('❌ Erreur projets accessibles: $e');
      throw Exception('Erreur lors de la récupération des projets accessibles: $e');
    }
  }

  /// ✅ UTILITAIRE: Conversion des documents en projets
  List<ProjectModel> _convertDocumentsToProjects(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) => _convertDocumentToProject(doc)).toList();
  }

  /// ✅ UTILITAIRE: Conversion d'un document en projet
  ProjectModel _convertDocumentToProject(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ProjectModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      tattooistId: data['tattooistId'] ?? '',
      tattooistName: data['tattooistName'] ?? '',
      status: ProjectStatus.fromString(data['status'] ?? 'pending'),
      category: data['category'] ?? '',
      bodyPart: data['bodyPart'] ?? '',
      size: data['size'] ?? '',
      style: data['style'] ?? '',
      colors: List<String>.from(data['colors'] ?? []),
      budget: (data['budget'] as num?)?.toDouble(),
      estimatedPrice: (data['estimatedPrice'] as num?)?.toDouble(),
      finalPrice: (data['finalPrice'] as num?)?.toDouble(),
      referenceImages: List<String>.from(data['referenceImages'] ?? []),
      sketchImages: List<String>.from(data['sketchImages'] ?? []),
      finalImages: List<String>.from(data['finalImages'] ?? []),
      appointmentDate: (data['appointmentDate'] as Timestamp?)?.toDate(),
      completionDate: (data['completionDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] ?? '',
      isPublic: data['isPublic'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      duration: data['duration'],
      difficulty: data['difficulty'] ?? 'medium',
      location: data['location'] ?? '',
      deposit: (data['deposit'] as num?)?.toDouble(),
      depositPaid: data['depositPaid'] ?? false,
      rating: data['rating'],
      review: data['review'],
      lastChatActivity: (data['lastChatActivity'] as Timestamp?)?.toDate(),
    );
  }

  /// ✅ DÉVELOPPEMENT: Créer des projets de test
  Future<void> createSampleProjects() async {
    try {
      _ensureAuthenticated(); // ✅ Vérification sécurisée
      
      // ✅ SÉCURITÉ: Seuls les admins peuvent créer des données de test
      if (_currentUserRole != UserRole.admin && _currentUserRole != UserRole.tatoueur) {
        throw Exception('Seuls les admins et tatoueurs peuvent créer des projets de test');
      }

      final tattooistName = _currentUser != null 
          ? (_currentUser['displayName'] ?? _currentUser['name'] ?? 'Tatoueur')
          : 'Tatoueur';

      final sampleProjects = [
        ProjectModel(
          id: '',
          title: 'Dragon japonais - Bras complet',
          description: 'Tatouage traditionnel japonais représentant un dragon sur le bras complet',
          clientId: 'client_001',
          clientName: 'Marie Dubois',
          clientEmail: 'marie.dubois@email.com',
          tattooistId: _currentUserId!,
          tattooistName: tattooistName,
          status: ProjectStatus.inProgress,
          category: 'Traditionnel japonais',
          bodyPart: 'Bras',
          size: 'Large',
          style: 'Japonais',
          colors: ['Noir', 'Rouge', 'Bleu'],
          budget: 800.0,
          estimatedPrice: 750.0,
          referenceImages: ['https://example.com/dragon1.jpg'],
          sketchImages: [],
          finalImages: [],
          duration: 8,
          difficulty: 'expert',
          deposit: 150.0,
          depositPaid: true,
          isPublic: true,
          tags: ['dragon', 'japonais', 'bras'],
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          notes: 'Projet complexe nécessitant plusieurs séances',
          location: 'Shop principal',
        ),
        ProjectModel(
          id: '',
          title: 'Rose minimaliste',
          description: 'Petit tatouage de rose dans un style minimaliste',
          clientId: 'client_002',
          clientName: 'Sophie Martin',
          clientEmail: 'sophie.martin@email.com',
          tattooistId: _currentUserId!,
          tattooistName: tattooistName,
          status: ProjectStatus.completed,
          category: 'Minimaliste',
          bodyPart: 'Poignet',
          size: 'Petit',
          style: 'Minimaliste',
          colors: ['Noir'],
          budget: 120.0,
          estimatedPrice: 100.0,
          finalPrice: 100.0,
          referenceImages: [],
          sketchImages: [],
          finalImages: ['https://example.com/rose_final.jpg'],
          duration: 1,
          difficulty: 'débutant',
          deposit: 30.0,
          depositPaid: true,
          isPublic: true,
          completionDate: DateTime.now().subtract(const Duration(days: 5)),
          tags: ['rose', 'minimaliste', 'poignet'],
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          notes: 'Client très satisfait',
          location: 'Shop principal',
        ),
        ProjectModel(
          id: '',
          title: 'Mandala géométrique',
          description: 'Mandala complexe avec des motifs géométriques précis',
          clientId: 'client_003',
          clientName: 'Thomas Leroy',
          clientEmail: 'thomas.leroy@email.com',
          tattooistId: _currentUserId!,
          tattooistName: tattooistName,
          status: ProjectStatus.pending,
          category: 'Géométrique',
          bodyPart: 'Épaule',
          size: 'Moyen',
          style: 'Géométrique',
          colors: ['Noir'],
          budget: 400.0,
          estimatedPrice: 350.0,
          referenceImages: ['https://example.com/mandala_ref.jpg'],
          sketchImages: [],
          finalImages: [],
          duration: 4,
          difficulty: 'intermédiaire',
          deposit: 70.0,
          depositPaid: false,
          isPublic: false,
          tags: ['mandala', 'géométrique', 'épaule'],
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          notes: 'En attente de validation du design',
          location: 'Shop principal',
        ),
      ];

      int created = 0;
      for (final project in sampleProjects) {
        try {
          final projectId = await createProject(project);
          print('✅ Projet de test créé: ${project.title} (ID: $projectId)');
          created++;
        } catch (e) {
          print('❌ Erreur création projet ${project.title}: $e');
        }
      }
      
      print('✅ Projets de test créés: $created/${sampleProjects.length}');
    } catch (e) {
      print('❌ Erreur création projets de test: $e');
      throw Exception('Erreur lors de la création des projets de test: $e');
    }
  }

  /// ✅ NOUVEAU: Méthode de diagnostic pour debug
  Future<void> debugProjectService() async {
    print('🔍 DIAGNOSTIC FirebaseProjectService:');
    
    try {
      print('  - User ID: ${_currentUserId ?? 'Non connecté'}');
      print('  - User Role: ${_currentUserRole?.name ?? 'Aucun'}');
      
      if (_currentUserId != null) {
        final projects = await fetchProjects();
        print('  - Projets utilisateur: ${projects.length}');
        
        final stats = await getProjectStats();
        print('  - Stats: ${stats}');
        
        if (_currentUserRole == UserRole.admin) {
          final allProjects = await getAccessibleProjects();
          print('  - Total projets (admin): ${allProjects.length}');
        }
      }
    } catch (e) {
      print('  - Erreur: $e');
    }
  }
}