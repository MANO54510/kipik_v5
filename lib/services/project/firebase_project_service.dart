// lib/services/project/firebase_project_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/models/project_model.dart';
import '../../core/firestore_helper.dart'; // ✅ AJOUTÉ
import '../../core/database_manager.dart'; // ✅ AJOUTÉ pour détecter le mode
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/models/user_role.dart';

/// Service de gestion des projets unifié (Production + Démo)
/// En mode démo : simule les projets avec données factices et gestion en mémoire
/// En mode production : utilise Firestore réel
class FirebaseProjectService {
  static FirebaseProjectService? _instance;
  static FirebaseProjectService get instance => _instance ??= FirebaseProjectService._();
  FirebaseProjectService._();

  final FirebaseFirestore _firestore = FirestoreHelper.instance; // ✅ CHANGÉ
  static const String _collection = 'projects';

  // ✅ DONNÉES MOCK POUR LES DÉMOS
  final Map<String, List<ProjectModel>> _mockUserProjects = {};
  final List<ProjectModel> _mockTemplateProjects = [];

  /// ✅ MÉTHODE PRINCIPALE - Détection automatique du mode
  bool get _isDemoMode => DatabaseManager.instance.isDemoMode;

  /// Collection avec converter pour une gestion automatique des types
  CollectionReference<ProjectModel> get _projectsCollection {
    return _firestore
        .collection(_collection)
        .withConverter<ProjectModel>(
          fromFirestore: (snapshot, _) => ProjectModel.fromMap(snapshot.id, snapshot.data()!),
          toFirestore: (project, _) => project.toMap(),
        );
  }

  /// ✅ Getter sécurisé pour l'utilisateur actuel
  String? get _currentUserId => SecureAuthService.instance.currentUserId;
  UserRole? get _currentUserRole => SecureAuthService.instance.currentUserRole;
  dynamic get _currentUser => SecureAuthService.instance.currentUser;

  /// ✅ SÉCURITÉ: Vérification d'authentification obligatoire
  void _ensureAuthenticated() {
    if (_currentUserId == null) {
      throw Exception(_isDemoMode ? '[DÉMO] Utilisateur non connecté' : 'Utilisateur non connecté');
    }
  }

  /// ✅ RÉCUPÉRER PROJETS UTILISATEUR (mode auto)
  Future<List<ProjectModel>> fetchProjects() async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Récupération projets factices');
      return await _fetchProjectsMock();
    } else {
      print('🏭 Mode production - Récupération projets Firebase');
      return await _fetchProjectsFirebase();
    }
  }

  /// ✅ FIREBASE - Récupération projets réels
  Future<List<ProjectModel>> _fetchProjectsFirebase() async {
    try {
      _ensureAuthenticated();

      final snapshot = await _projectsCollection
          .where('tattooistId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des projets Firebase: $e');
    }
  }

  /// ✅ MOCK - Récupération projets factices
  Future<List<ProjectModel>> _fetchProjectsMock() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    _ensureAuthenticated();

    if (!_mockUserProjects.containsKey(_currentUserId)) {
      _initializeMockUserProjects();
    }

    final projects = _mockUserProjects[_currentUserId] ?? [];
    print('✅ Projets démo récupérés: ${projects.length}');
    
    return List<ProjectModel>.from(projects);
  }

  /// ✅ INITIALISER PROJETS DÉMO UTILISATEUR
  void _initializeMockUserProjects() {
    if (_currentUserId == null) return;

    _initializeMockTemplateProjects();

    final tattooistName = _currentUser != null 
        ? (_currentUser['displayName'] ?? _currentUser['name'] ?? 'Tatoueur Démo')
        : 'Tatoueur Démo';

    final projectCount = Random().nextInt(6) + 4; // 4-9 projets
    final projects = <ProjectModel>[];

    for (int i = 0; i < projectCount; i++) {
      final template = _mockTemplateProjects[Random().nextInt(_mockTemplateProjects.length)];
      final statuses = [ProjectStatus.pending, ProjectStatus.accepted, ProjectStatus.inProgress, ProjectStatus.completed, ProjectStatus.onHold];
      final randomStatus = statuses[Random().nextInt(statuses.length)];
      
      final project = template.copyWith(
        id: 'demo_project_${_currentUserId}_$i',
        tattooistId: _currentUserId!,
        tattooistName: tattooistName,
        status: randomStatus,
        clientId: 'demo_client_$i',
        clientName: 'Client Démo ${i + 1}',
        clientEmail: 'client.demo$i@kipik-demo.com',
        createdAt: DateTime.now().subtract(Duration(days: Random().nextInt(60))),
        updatedAt: DateTime.now().subtract(Duration(days: Random().nextInt(7))),
        budget: (Random().nextDouble() * 800 + 100).roundToDouble(),
        estimatedPrice: (Random().nextDouble() * 700 + 80).roundToDouble(),
        depositPaid: Random().nextBool(),
        isPublic: Random().nextBool(),
      );

      if (randomStatus == ProjectStatus.completed) {
        projects.add(project.copyWith(
          completionDate: DateTime.now().subtract(Duration(days: Random().nextInt(30))),
          finalPrice: project.estimatedPrice,
          rating: Random().nextInt(3) + 3, // 3-5 étoiles
          review: 'Très satisfait du résultat ! Travail de grande qualité.',
        ));
      } else {
        projects.add(project);
      }
    }

    _mockUserProjects[_currentUserId!] = projects;
    print('🎭 ${projects.length} projets démo initialisés pour $tattooistName');
  }

  /// ✅ INITIALISER TEMPLATES DE PROJETS DÉMO
  void _initializeMockTemplateProjects() {
    if (_mockTemplateProjects.isNotEmpty) return;

    _mockTemplateProjects.addAll([
      ProjectModel(
        id: '',
        title: 'Dragon japonais - Bras complet',
        description: 'Tatouage traditionnel japonais représentant un dragon sur le bras complet avec des détails complexes',
        category: 'Traditionnel japonais',
        bodyPart: 'Bras',
        size: 'Large',
        style: 'Japonais',
        colors: ['Noir', 'Rouge', 'Bleu'],
        duration: 8,
        difficulty: 'expert',
        deposit: 150.0,
        tags: ['dragon', 'japonais', 'bras'],
        notes: 'Projet complexe nécessitant plusieurs séances',
        location: 'Shop principal',
        referenceImages: ['https://picsum.photos/seed/dragon/600/400'],
        sketchImages: [], // ✅ AJOUTÉ
        finalImages: [], // ✅ AJOUTÉ
        tattooistId: '',
        tattooistName: '',
        clientId: '',
        clientName: '',
        clientEmail: '',
        status: ProjectStatus.pending,
        isPublic: false, // ✅ AJOUTÉ
        depositPaid: false, // ✅ AJOUTÉ
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProjectModel(
        id: '',
        title: 'Rose minimaliste',
        description: 'Petit tatouage de rose dans un style minimaliste et épuré',
        category: 'Minimaliste',
        bodyPart: 'Poignet',
        size: 'Petit',
        style: 'Minimaliste',
        colors: ['Noir'],
        duration: 1,
        difficulty: 'débutant',
        deposit: 30.0,
        tags: ['rose', 'minimaliste', 'poignet'],
        notes: 'Design simple et élégant',
        location: 'Shop principal',
        referenceImages: ['https://picsum.photos/seed/rose/400/400'],
        sketchImages: [], // ✅ AJOUTÉ
        finalImages: [], // ✅ AJOUTÉ
        tattooistId: '',
        tattooistName: '',
        clientId: '',
        clientName: '',
        clientEmail: '',
        status: ProjectStatus.pending,
        isPublic: false, // ✅ AJOUTÉ
        depositPaid: false, // ✅ AJOUTÉ
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProjectModel(
        id: '',
        title: 'Mandala géométrique',
        description: 'Mandala complexe avec des motifs géométriques précis et symétriques',
        category: 'Géométrique',
        bodyPart: 'Épaule',
        size: 'Moyen',
        style: 'Géométrique',
        colors: ['Noir'],
        duration: 4,
        difficulty: 'intermédiaire',
        deposit: 70.0,
        tags: ['mandala', 'géométrique', 'épaule'],
        notes: 'Précision requise pour les motifs géométriques',
        location: 'Shop principal',
        referenceImages: ['https://picsum.photos/seed/mandala/500/500'],
        sketchImages: [], // ✅ AJOUTÉ
        finalImages: [], // ✅ AJOUTÉ
        tattooistId: '',
        tattooistName: '',
        clientId: '',
        clientName: '',
        clientEmail: '',
        status: ProjectStatus.pending,
        isPublic: false, // ✅ AJOUTÉ
        depositPaid: false, // ✅ AJOUTÉ
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProjectModel(
        id: '',
        title: 'Loup réaliste',
        description: 'Portrait de loup dans un style réaliste avec des détails saisissants',
        category: 'Réaliste',
        bodyPart: 'Cuisse',
        size: 'Large',
        style: 'Réaliste',
        colors: ['Noir', 'Gris'],
        duration: 6,
        difficulty: 'expert',
        deposit: 120.0,
        tags: ['loup', 'réaliste', 'cuisse', 'animal'],
        notes: 'Style réaliste demandant beaucoup de technique',
        location: 'Shop principal',
        referenceImages: ['https://picsum.photos/seed/wolf/600/500'],
        sketchImages: [], // ✅ AJOUTÉ
        finalImages: [], // ✅ AJOUTÉ
        tattooistId: '',
        tattooistName: '',
        clientId: '',
        clientName: '',
        clientEmail: '',
        status: ProjectStatus.pending,
        isPublic: false, // ✅ AJOUTÉ
        depositPaid: false, // ✅ AJOUTÉ
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProjectModel(
        id: '',
        title: 'Ancre old school',
        description: 'Tatouage d\'ancre dans le style old school traditionnel',
        category: 'Old School',
        bodyPart: 'Avant-bras',
        size: 'Moyen',
        style: 'Old School',
        colors: ['Noir', 'Rouge', 'Bleu'],
        duration: 3,
        difficulty: 'intermédiaire',
        deposit: 60.0,
        tags: ['ancre', 'old school', 'avant-bras', 'marin'],
        notes: 'Style classique avec couleurs vives',
        location: 'Shop principal',
        referenceImages: ['https://picsum.photos/seed/anchor/400/500'],
        sketchImages: [], // ✅ AJOUTÉ
        finalImages: [], // ✅ AJOUTÉ
        tattooistId: '',
        tattooistName: '',
        clientId: '',
        clientName: '',
        clientEmail: '',
        status: ProjectStatus.pending,
        isPublic: false, // ✅ AJOUTÉ
        depositPaid: false, // ✅ AJOUTÉ
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
  }

  /// ✅ RÉCUPÉRER PROJET PAR ID (mode auto)
  Future<ProjectModel?> fetchProjectById(String projectId) async {
    if (_isDemoMode) {
      return await _fetchProjectByIdMock(projectId);
    } else {
      return await _fetchProjectByIdFirebase(projectId);
    }
  }

  /// ✅ FIREBASE - Récupération projet par ID
  Future<ProjectModel?> _fetchProjectByIdFirebase(String projectId) async {
    try {
      _ensureAuthenticated();

      final doc = await _projectsCollection.doc(projectId).get();
      
      if (!doc.exists) {
        return null;
      }

      final project = doc.data()!;
      
      if (!await canAccessProject(projectId)) {
        throw Exception('Accès refusé à ce projet');
      }

      return project;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du projet Firebase: $e');
    }
  }

  /// ✅ MOCK - Récupération projet par ID
  Future<ProjectModel?> _fetchProjectByIdMock(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    _ensureAuthenticated();

    if (!_mockUserProjects.containsKey(_currentUserId)) {
      _initializeMockUserProjects();
    }

    final projects = _mockUserProjects[_currentUserId] ?? [];
    
    try {
      final project = projects.firstWhere((p) => p.id == projectId);
      print('✅ Projet démo trouvé: ${project.title}');
      return project;
    } catch (e) {
      print('❌ Projet démo introuvable: $projectId');
      return null;
    }
  }

  /// ✅ CRÉER PROJET (mode auto)
  Future<String> createProject(ProjectModel project) async {
    if (_isDemoMode) {
      print('🎭 Mode démo - Création projet factice');
      return await _createProjectMock(project);
    } else {
      print('🏭 Mode production - Création projet Firebase');
      return await _createProjectFirebase(project);
    }
  }

  /// ✅ FIREBASE - Création projet réel
  Future<String> _createProjectFirebase(ProjectModel project) async {
    try {
      _ensureAuthenticated();
      
      final tattooistName = _currentUser != null 
          ? (_currentUser['displayName'] ?? _currentUser['name'] ?? 'Tatoueur')
          : 'Tatoueur';

      final projectWithUserInfo = project.copyWith(
        tattooistId: _currentUserId!,
        tattooistName: tattooistName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _projectsCollection.add(projectWithUserInfo);
      
      print('✅ Projet Firebase créé: ${project.title} (ID: ${docRef.id})');
      
      return docRef.id;
    } catch (e) {
      print('❌ Erreur création projet Firebase: $e');
      throw Exception('Erreur lors de la création du projet: $e');
    }
  }

  /// ✅ MOCK - Création projet factice
  Future<String> _createProjectMock(ProjectModel project) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    _ensureAuthenticated();

    final tattooistName = _currentUser != null 
        ? (_currentUser['displayName'] ?? _currentUser['name'] ?? 'Tatoueur Démo')
        : 'Tatoueur Démo';

    final projectId = 'demo_project_${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}';
    
    final projectWithUserInfo = project.copyWith(
      id: projectId,
      tattooistId: _currentUserId!,
      tattooistName: tattooistName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (!_mockUserProjects.containsKey(_currentUserId)) {
      _mockUserProjects[_currentUserId!] = [];
    }

    _mockUserProjects[_currentUserId!]!.insert(0, projectWithUserInfo);
    
    print('✅ Projet démo créé: ${project.title} (ID: $projectId)');
    
    return projectId;
  }

  /// ✅ METTRE À JOUR PROJET (mode auto)
  Future<void> updateProjectModel(ProjectModel project) async {
    if (_isDemoMode) {
      await _updateProjectModelMock(project);
    } else {
      await _updateProjectModelFirebase(project);
    }
  }

  /// ✅ FIREBASE - Mise à jour projet réel
  Future<void> _updateProjectModelFirebase(ProjectModel project) async {
    try {
      _ensureAuthenticated();
      
      if (!await canAccessProject(project.id)) {
        throw Exception('Accès refusé pour modifier ce projet');
      }

      final updatedProject = project.copyWith(updatedAt: DateTime.now());
      await _projectsCollection.doc(project.id).set(updatedProject);
      
      print('✅ Projet Firebase mis à jour: ${project.title}');
    } catch (e) {
      print('❌ Erreur mise à jour projet Firebase: $e');
      throw Exception('Erreur lors de la mise à jour du projet: $e');
    }
  }

  /// ✅ MOCK - Mise à jour projet factice
  Future<void> _updateProjectModelMock(ProjectModel project) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _ensureAuthenticated();

    if (!_mockUserProjects.containsKey(_currentUserId)) {
      _initializeMockUserProjects();
    }

    final projects = _mockUserProjects[_currentUserId!]!;
    final index = projects.indexWhere((p) => p.id == project.id);
    
    if (index != -1) {
      final updatedProject = project.copyWith(updatedAt: DateTime.now());
      projects[index] = updatedProject;
      print('✅ Projet démo mis à jour: ${project.title}');
    } else {
      throw Exception('[DÉMO] Projet introuvable: ${project.id}');
    }
  }

  /// ✅ METTRE À JOUR STATUT (mode auto)
  Future<void> updateProjectStatus(String projectId, ProjectStatus status) async {
    if (_isDemoMode) {
      await _updateProjectStatusMock(projectId, status);
    } else {
      await _updateProjectStatusFirebase(projectId, status);
    }
  }

  /// ✅ FIREBASE - Mise à jour statut réel
  Future<void> _updateProjectStatusFirebase(String projectId, ProjectStatus status) async {
    try {
      _ensureAuthenticated();
      
      if (!await canAccessProject(projectId)) {
        throw Exception('Accès refusé pour modifier ce projet');
      }

      final updates = <String, dynamic>{
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': _currentUserId,
      };

      if (status == ProjectStatus.completed) {
        updates['completionDate'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_collection).doc(projectId).update(updates);
      
      print('✅ Statut projet Firebase mis à jour: $projectId -> ${status.toString()}');
    } catch (e) {
      print('❌ Erreur mise à jour statut Firebase: $e');
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  /// ✅ MOCK - Mise à jour statut factice
  Future<void> _updateProjectStatusMock(String projectId, ProjectStatus status) async {
    await Future.delayed(const Duration(milliseconds: 250));
    
    _ensureAuthenticated();

    if (!_mockUserProjects.containsKey(_currentUserId)) {
      _initializeMockUserProjects();
    }

    final projects = _mockUserProjects[_currentUserId!]!;
    final index = projects.indexWhere((p) => p.id == projectId);
    
    if (index != -1) {
      final project = projects[index];
      final updatedProject = project.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        completionDate: status == ProjectStatus.completed ? DateTime.now() : project.completionDate,
      );
      
      projects[index] = updatedProject;
      print('✅ Statut projet démo mis à jour: $projectId -> ${status.toString()}');
    } else {
      throw Exception('[DÉMO] Projet introuvable: $projectId');
    }
  }

  /// ✅ SUPPRIMER PROJET (mode auto)
  Future<void> deleteProject(String projectId) async {
    if (_isDemoMode) {
      await _deleteProjectMock(projectId);
    } else {
      await _deleteProjectFirebase(projectId);
    }
  }

  /// ✅ FIREBASE - Suppression projet réel
  Future<void> _deleteProjectFirebase(String projectId) async {
    try {
      _ensureAuthenticated();
      
      if (!await canAccessProject(projectId)) {
        throw Exception('Accès refusé pour supprimer ce projet');
      }

      final doc = await _firestore.collection(_collection).doc(projectId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final tattooistId = data['tattooistId'] as String?;
        
        if (tattooistId != _currentUserId && _currentUserRole != UserRole.admin) {
          throw Exception('Seul le tatoueur propriétaire peut supprimer ce projet');
        }
      }

      await _projectsCollection.doc(projectId).delete();
      
      print('✅ Projet Firebase supprimé: $projectId');
    } catch (e) {
      print('❌ Erreur suppression projet Firebase: $e');
      throw Exception('Erreur lors de la suppression du projet: $e');
    }
  }

  /// ✅ MOCK - Suppression projet factice
  Future<void> _deleteProjectMock(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _ensureAuthenticated();

    if (!_mockUserProjects.containsKey(_currentUserId)) {
      _initializeMockUserProjects();
    }

    final projects = _mockUserProjects[_currentUserId!]!;
    final index = projects.indexWhere((p) => p.id == projectId);
    
    if (index != -1) {
      final project = projects.removeAt(index);
      print('✅ Projet démo supprimé: ${project.title}');
    } else {
      throw Exception('[DÉMO] Projet introuvable: $projectId');
    }
  }

  /// ✅ STATISTIQUES PROJETS (mode auto)
  Future<Map<String, int>> getProjectStats() async {
    if (_isDemoMode) {
      return await _getProjectStatsMock();
    } else {
      return await _getProjectStatsFirebase();
    }
  }

  /// ✅ FIREBASE - Statistiques réelles
  Future<Map<String, int>> _getProjectStatsFirebase() async {
    try {
      _ensureAuthenticated();

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

      print('✅ Stats projets Firebase calculées: ${stats['total']} total');
      return stats;
    } catch (e) {
      print('❌ Erreur stats projets Firebase: $e');
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// ✅ MOCK - Statistiques factices
  Future<Map<String, int>> _getProjectStatsMock() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    _ensureAuthenticated();

    if (!_mockUserProjects.containsKey(_currentUserId)) {
      _initializeMockUserProjects();
    }

    final projects = _mockUserProjects[_currentUserId!] ?? [];
    
    int pending = 0;
    int accepted = 0;
    int inProgress = 0;
    int completed = 0;
    int cancelled = 0;
    int onHold = 0;

    for (final project in projects) {
      switch (project.status) {
        case ProjectStatus.pending:
          pending++;
          break;
        case ProjectStatus.accepted:
          accepted++;
          break;
        case ProjectStatus.inProgress:
          inProgress++;
          break;
        case ProjectStatus.completed:
          completed++;
          break;
        case ProjectStatus.cancelled:
          cancelled++;
          break;
        case ProjectStatus.onHold:
          onHold++;
          break;
      }
    }

    final stats = {
      'total': projects.length,
      'pending': pending,
      'accepted': accepted,
      'inProgress': inProgress,
      'completed': completed,
      'cancelled': cancelled,
      'onHold': onHold,
    };

    print('✅ Stats projets démo calculées: ${stats['total']} total');
    return stats;
  }

  /// ✅ PROJETS PUBLICS (mode auto)
  Future<List<ProjectModel>> getPublicProjects({int? limit}) async {
    if (_isDemoMode) {
      return await _getPublicProjectsMock(limit: limit);
    } else {
      return await _getPublicProjectsFirebase(limit: limit);
    }
  }

  /// ✅ FIREBASE - Projets publics réels
  Future<List<ProjectModel>> _getPublicProjectsFirebase({int? limit}) async {
    try {
      _ensureAuthenticated();

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
      
      print('✅ Projets publics Firebase: ${results.length}');
      return results;
    } catch (e) {
      print('❌ Erreur projets publics Firebase: $e');
      throw Exception('Erreur lors de la récupération des projets publics: $e');
    }
  }

  /// ✅ MOCK - Projets publics factices
  Future<List<ProjectModel>> _getPublicProjectsMock({int? limit}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _ensureAuthenticated();

    if (!_mockUserProjects.containsKey(_currentUserId)) {
      _initializeMockUserProjects();
    }

    final projects = _mockUserProjects[_currentUserId!] ?? [];
    final publicProjects = projects
        .where((p) => p.isPublic && p.status == ProjectStatus.completed)
        .toList();

    publicProjects.sort((a, b) => (b.completionDate ?? DateTime.now()).compareTo(a.completionDate ?? DateTime.now()));

    final result = limit != null 
        ? publicProjects.take(limit).toList()
        : publicProjects;
    
    print('✅ Projets publics démo: ${result.length}');
    return result;
  }

  /// ✅ VÉRIFIER ACCÈS PROJET (mode auto)
  Future<bool> canAccessProject(String projectId) async {
    if (_isDemoMode) {
      return await _canAccessProjectMock(projectId);
    } else {
      return await _canAccessProjectFirebase(projectId);
    }
  }

  /// ✅ FIREBASE - Vérification accès réel
  Future<bool> _canAccessProjectFirebase(String projectId) async {
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
      
      if (currentUserRole == UserRole.admin) {
        print('✅ Accès admin autorisé: $projectId');
        return true;
      }
      
      if (tattooistId == currentUserId) {
        print('✅ Accès tatoueur propriétaire: $projectId');
        return true;
      }
      
      if (clientId == currentUserId) {
        print('✅ Accès client propriétaire: $projectId');
        return true;
      }
      
      print('❌ Accès refusé au projet: $projectId');
      return false;
    } catch (e) {
      print('❌ Erreur vérification accès Firebase: $e');
      return false;
    }
  }

  /// ✅ MOCK - Vérification accès factice
  Future<bool> _canAccessProjectMock(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    final currentUserId = _currentUserId;
    final currentUserRole = _currentUserRole;
    
    if (currentUserId == null) {
      print('❌ Accès démo refusé: utilisateur non connecté');
      return false;
    }

    if (currentUserRole == UserRole.admin) {
      print('✅ Accès admin démo autorisé: $projectId');
      return true;
    }

    // En mode démo, l'utilisateur peut accéder à tous ses projets mock
    if (_mockUserProjects.containsKey(currentUserId)) {
      final hasProject = _mockUserProjects[currentUserId]!.any((p) => p.id == projectId);
      if (hasProject) {
        print('✅ Accès propriétaire démo: $projectId');
        return true;
      }
    }
    
    print('❌ Accès démo refusé au projet: $projectId');
    return false;
  }

  /// ✅ STREAM PROJETS (mode auto)
  Stream<List<ProjectModel>> projectsStream() {
    if (_isDemoMode) {
      // En mode démo, retourner un stream avec les données mock
      return Stream.periodic(const Duration(seconds: 5), (_) {
        final currentUserId = _currentUserId;
        if (currentUserId == null) return <ProjectModel>[];
        
        if (!_mockUserProjects.containsKey(currentUserId)) {
          _initializeMockUserProjects();
        }
        
        return _mockUserProjects[currentUserId] ?? <ProjectModel>[];
      });
    } else {
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
  }

  /// ✅ MÉTHODE DE DIAGNOSTIC
  Future<void> debugProjectService() async {
    print('🔍 Debug FirebaseProjectService:');
    print('  - Mode démo: $_isDemoMode');
    print('  - Base active: ${DatabaseManager.instance.activeDatabaseConfig.name}');
    print('  - User ID: ${_currentUserId ?? 'Non connecté'}');
    print('  - User Role: ${_currentUserRole?.name ?? 'Aucun'}');
    
    if (_currentUserId != null) {
      try {
        final projects = await fetchProjects();
        print('  - Projets utilisateur: ${projects.length}');
        
        final stats = await getProjectStats();
        print('  - Stats: $stats');
        
        if (_isDemoMode) {
          print('  - Utilisateurs mock: ${_mockUserProjects.length}');
          print('  - Templates disponibles: ${_mockTemplateProjects.length}');
        }
        
        final publicProjects = await getPublicProjects();
        print('  - Projets publics: ${publicProjects.length}');
      } catch (e) {
        print('  - Erreur: $e');
      }
    }
  }

  // ✅ MÉTHODES RESTANTES (adaptées ou inchangées selon le besoin)
  
  /// Mettre à jour un projet avec des champs spécifiques (mode auto)
  Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    if (_isDemoMode) {
      // Version simplifiée pour le mode démo
      final project = await fetchProjectById(projectId);
      if (project != null) {
        // Appliquer les updates basiques sur le projet
        await updateProjectModel(project);
      }
    } else {
      // Version complète Firebase
      try {
        _ensureAuthenticated();
        
        if (!await canAccessProject(projectId)) {
          throw Exception('Accès refusé pour modifier ce projet');
        }

        final forbiddenFields = ['tattooistId', 'id', 'createdAt'];
        for (final field in forbiddenFields) {
          if (updates.containsKey(field)) {
            updates.remove(field);
            print('⚠️ Champ protégé ignoré: $field');
          }
        }

        if (updates.containsKey('appointmentDate') && updates['appointmentDate'] is DateTime) {
          updates['appointmentDate'] = Timestamp.fromDate(updates['appointmentDate']);
        }
        if (updates.containsKey('completionDate') && updates['completionDate'] is DateTime) {
          updates['completionDate'] = Timestamp.fromDate(updates['completionDate']);
        }
        
        updates['updatedAt'] = FieldValue.serverTimestamp();
        updates['updatedBy'] = _currentUserId;
        
        await _firestore.collection(_collection).doc(projectId).update(updates);
        
        print('✅ Projet Firebase mis à jour: $projectId');
      } catch (e) {
        print('❌ Erreur mise à jour projet Firebase: $e');
        throw Exception('Erreur lors de la mise à jour du projet: $e');
      }
    }
  }

  /// Rechercher des projets par critères (simplifié pour démo)
  Future<List<ProjectModel>> searchProjects({
    String? status,
    String? category,
    String? style,
    String? clientId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isPublic,
  }) async {
    final allProjects = await fetchProjects();
    
    var filteredProjects = allProjects;
    
    if (status != null && status.isNotEmpty) {
      filteredProjects = filteredProjects.where((p) => p.status.toString().contains(status)).toList();
    }
    
    if (category != null && category.isNotEmpty) {
      filteredProjects = filteredProjects.where((p) => p.category.contains(category)).toList();
    }
    
    if (style != null && style.isNotEmpty) {
      filteredProjects = filteredProjects.where((p) => p.style.contains(style)).toList();
    }
    
    if (isPublic != null) {
      filteredProjects = filteredProjects.where((p) => p.isPublic == isPublic).toList();
    }
    
    print('✅ Recherche projets (${_isDemoMode ? 'démo' : 'production'}): ${filteredProjects.length} résultats');
    return filteredProjects;
  }

  /// Obtenir les projets d'un client spécifique
  Future<List<ProjectModel>> getProjectsByClient(String clientId) async {
    final allProjects = await fetchProjects();
    final clientProjects = allProjects.where((p) => p.clientId == clientId).toList();
    
    print('✅ Projets client $clientId (${_isDemoMode ? 'démo' : 'production'}): ${clientProjects.length}');
    return clientProjects;
  }

  /// Mettre à jour l'activité de chat (simplifié)
  Future<void> updateChatActivity(String projectId) async {
    if (_isDemoMode) {
      // Simulation simple
      await Future.delayed(const Duration(milliseconds: 100));
      print('✅ Activité chat démo mise à jour: $projectId');
    } else {
      try {
        _ensureAuthenticated();
        
        if (!await canAccessProject(projectId)) {
          throw Exception('Accès refusé pour ce projet');
        }

        await _firestore.collection(_collection).doc(projectId).update({
          'lastChatActivity': FieldValue.serverTimestamp(),
          'lastChatActivityBy': _currentUserId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Activité chat Firebase mise à jour: $projectId');
      } catch (e) {
        print('❌ Erreur mise à jour chat Firebase: $e');
        throw Exception('Erreur lors de la mise à jour de l\'activité de chat: $e');
      }
    }
  }

  /// Ajouter des images à un projet (simplifié)
  Future<void> addImagesToProject(
    String projectId, 
    List<String> imageUrls, 
    String imageType
  ) async {
    final project = await fetchProjectById(projectId);
    if (project == null) {
      throw Exception('Projet introuvable');
    }

    ProjectModel updatedProject;
    switch (imageType) {
      case 'reference':
        updatedProject = project.copyWith(
          referenceImages: [...project.referenceImages, ...imageUrls],
        );
        break;
      case 'sketch':
        updatedProject = project.copyWith(
          sketchImages: [...project.sketchImages, ...imageUrls],
        );
        break;
      case 'final':
        updatedProject = project.copyWith(
          finalImages: [...project.finalImages, ...imageUrls],
        );
        break;
      default:
        throw Exception('Type d\'image non autorisé: $imageType');
    }

    await updateProjectModel(updatedProject);
    print('✅ Images ajoutées (${_isDemoMode ? 'démo' : 'production'}): $projectId ($imageType: ${imageUrls.length})');
  }

  /// Supprimer des images d'un projet (simplifié)
  Future<void> removeImagesFromProject(
    String projectId, 
    List<String> imageUrls, 
    String imageType
  ) async {
    final project = await fetchProjectById(projectId);
    if (project == null) {
      throw Exception('Projet introuvable');
    }

    ProjectModel updatedProject;
    switch (imageType) {
      case 'reference':
        final newImages = project.referenceImages.where((url) => !imageUrls.contains(url)).toList();
        updatedProject = project.copyWith(referenceImages: newImages);
        break;
      case 'sketch':
        final newImages = project.sketchImages.where((url) => !imageUrls.contains(url)).toList();
        updatedProject = project.copyWith(sketchImages: newImages);
        break;
      case 'final':
        final newImages = project.finalImages.where((url) => !imageUrls.contains(url)).toList();
        updatedProject = project.copyWith(finalImages: newImages);
        break;
      default:
        throw Exception('Type d\'image non autorisé: $imageType');
    }

    await updateProjectModel(updatedProject);
    print('✅ Images supprimées (${_isDemoMode ? 'démo' : 'production'}): $projectId ($imageType: ${imageUrls.length})');
  }

  /// Stream d'un projet spécifique (adapté pour démo)
  Stream<ProjectModel?> projectStream(String projectId) {
    if (_isDemoMode) {
      return Stream.periodic(const Duration(seconds: 3), (_) async {
        return await fetchProjectById(projectId);
      }).asyncMap((future) => future);
    } else {
      return _projectsCollection
          .doc(projectId)
          .snapshots()
          .asyncMap((doc) async {
        if (!doc.exists) return null;
        
        try {
          if (!await canAccessProject(projectId)) {
            return null;
          }
          return doc.data();
        } catch (e) {
          print('❌ Erreur vérification permissions stream: $e');
          return null;
        }
      });
    }
  }
}