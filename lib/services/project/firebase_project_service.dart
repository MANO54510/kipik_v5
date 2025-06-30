// lib/services/project/firebase_project_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/project_model.dart';
import '../auth/auth_service.dart';

class FirebaseProjectService {
  static FirebaseProjectService? _instance;
  static FirebaseProjectService get instance => _instance ??= FirebaseProjectService._();
  FirebaseProjectService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'projects';

  /// Récupérer tous les projets de l'utilisateur connecté
  Future<List<ProjectModel>> fetchProjects() async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final snapshot = await _firestore
          .collection(_collection)
          .where('tattooistId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return _convertDocumentsToProjects(snapshot.docs);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des projets: $e');
    }
  }

  /// Récupérer un projet par son ID
  Future<ProjectModel?> fetchProjectById(String projectId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(projectId).get();
      
      if (!doc.exists) {
        return null;
      }

      return _convertDocumentToProject(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du projet: $e');
    }
  }

  /// Créer un nouveau projet
  Future<String> createProject(ProjectModel project) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final docRef = await _firestore.collection(_collection).add({
        'title': project.title,
        'description': project.description,
        'clientId': project.clientId,
        'clientName': project.clientName,
        'clientEmail': project.clientEmail,
        'tattooistId': currentUser.uid,
        'tattooistName': currentUser.displayName ?? '',
        'status': project.status.toString(),
        'category': project.category,
        'bodyPart': project.bodyPart,
        'size': project.size,
        'style': project.style,
        'colors': project.colors,
        'budget': project.budget,
        'estimatedPrice': project.estimatedPrice,
        'finalPrice': project.finalPrice,
        'referenceImages': project.referenceImages,
        'sketchImages': project.sketchImages,
        'finalImages': project.finalImages,
        'appointmentDate': project.appointmentDate != null 
            ? Timestamp.fromDate(project.appointmentDate!) : null,
        'completionDate': project.completionDate != null 
            ? Timestamp.fromDate(project.completionDate!) : null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'notes': project.notes,
        'isPublic': project.isPublic,
        'tags': project.tags,
        'duration': project.duration,
        'difficulty': project.difficulty,
        'location': project.location,
        'deposit': project.deposit,
        'depositPaid': project.depositPaid,
        'rating': project.rating,
        'review': project.review,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du projet: $e');
    }
  }

  /// Mettre à jour un projet avec un objet ProjectModel complet
  Future<void> updateProjectModel(ProjectModel project) async {
    try {
      await _firestore.collection(_collection).doc(project.id).update({
        'title': project.title,
        'description': project.description,
        'clientId': project.clientId,
        'clientName': project.clientName,
        'clientEmail': project.clientEmail,
        'status': project.status.toString(),
        'category': project.category,
        'bodyPart': project.bodyPart,
        'size': project.size,
        'style': project.style,
        'colors': project.colors,
        'budget': project.budget,
        'estimatedPrice': project.estimatedPrice,
        'finalPrice': project.finalPrice,
        'referenceImages': project.referenceImages,
        'sketchImages': project.sketchImages,
        'finalImages': project.finalImages,
        'appointmentDate': project.appointmentDate != null 
            ? Timestamp.fromDate(project.appointmentDate!) : null,
        'completionDate': project.completionDate != null 
            ? Timestamp.fromDate(project.completionDate!) : null,
        'notes': project.notes,
        'isPublic': project.isPublic,
        'tags': project.tags,
        'duration': project.duration,
        'difficulty': project.difficulty,
        'location': project.location,
        'deposit': project.deposit,
        'depositPaid': project.depositPaid,
        'rating': project.rating,
        'review': project.review,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du projet: $e');
    }
  }

  /// Mettre à jour un projet avec des champs spécifiques
  Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    try {
      // Convertir les DateTime en Timestamp si nécessaire
      if (updates.containsKey('appointmentDate') && updates['appointmentDate'] is DateTime) {
        updates['appointmentDate'] = Timestamp.fromDate(updates['appointmentDate']);
      }
      if (updates.containsKey('completionDate') && updates['completionDate'] is DateTime) {
        updates['completionDate'] = Timestamp.fromDate(updates['completionDate']);
      }
      
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(projectId).update(updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du projet: $e');
    }
  }

  /// Changer le statut d'un projet
  Future<void> updateProjectStatus(String projectId, ProjectStatus status) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Ajouter la date de completion si le statut est completed
      if (status == ProjectStatus.completed) {
        updates['completionDate'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_collection).doc(projectId).update(updates);
    } catch (e) {
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
      final fieldName = '${imageType}Images';
      await _firestore.collection(_collection).doc(projectId).update({
        fieldName: FieldValue.arrayUnion(imageUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
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
      final fieldName = '${imageType}Images';
      await _firestore.collection(_collection).doc(projectId).update({
        fieldName: FieldValue.arrayRemove(imageUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression des images: $e');
    }
  }

  /// Supprimer un projet
  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection(_collection).doc(projectId).delete();
    } catch (e) {
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
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      Query query = _firestore
          .collection(_collection)
          .where('tattooistId', isEqualTo: currentUser.uid);

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
      return _convertDocumentsToProjects(snapshot.docs);
    } catch (e) {
      throw Exception('Erreur lors de la recherche de projets: $e');
    }
  }

  /// Obtenir les projets d'un client spécifique
  Future<List<ProjectModel>> getProjectsByClient(String clientId) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final snapshot = await _firestore
          .collection(_collection)
          .where('tattooistId', isEqualTo: currentUser.uid)
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      return _convertDocumentsToProjects(snapshot.docs);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des projets du client: $e');
    }
  }

  /// Obtenir les projets publics pour le portfolio
  Future<List<ProjectModel>> getPublicProjects({int? limit}) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      Query query = _firestore
          .collection(_collection)
          .where('tattooistId', isEqualTo: currentUser.uid)
          .where('isPublic', isEqualTo: true)
          .where('status', isEqualTo: 'completed')
          .orderBy('completionDate', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return _convertDocumentsToProjects(snapshot.docs);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des projets publics: $e');
    }
  }

  /// Stream des projets (temps réel)
  Stream<List<ProjectModel>> projectsStream() {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      return Stream.empty();
    }

    return _firestore
        .collection(_collection)
        .where('tattooistId', isEqualTo: currentUser.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => _convertDocumentsToProjects(snapshot.docs));
  }

  /// Stream d'un projet spécifique
  Stream<ProjectModel?> projectStream(String projectId) {
    return _firestore
        .collection(_collection)
        .doc(projectId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return _convertDocumentToProject(doc);
    });
  }

  /// Mettre à jour l'activité de chat d'un projet
  Future<void> updateChatActivity(String projectId) async {
    try {
      await _firestore.collection(_collection).doc(projectId).update({
        'lastChatActivity': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'activité de chat: $e');
    }
  }

  /// Obtenir les statistiques des projets
  Future<Map<String, int>> getProjectStats() async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final snapshot = await _firestore
          .collection(_collection)
          .where('tattooistId', isEqualTo: currentUser.uid)
          .get();

      int pending = 0;
      int accepted = 0;
      int inProgress = 0;
      int completed = 0;
      int cancelled = 0;
      int onHold = 0;

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String?;
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

      return {
        'total': snapshot.docs.length,
        'pending': pending,
        'accepted': accepted,
        'inProgress': inProgress,
        'completed': completed,
        'cancelled': cancelled,
        'onHold': onHold,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// Méthodes utilitaires privées
  List<ProjectModel> _convertDocumentsToProjects(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) => _convertDocumentToProject(doc)).toList();
  }

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

  /// Créer des projets de test
  Future<void> createSampleProjects() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      print('Utilisateur non connecté - impossible de créer des projets de test');
      return;
    }

    final sampleProjects = [
      ProjectModel(
        id: '',
        title: 'Dragon japonais - Bras complet',
        description: 'Tatouage traditionnel japonais représentant un dragon sur le bras complet',
        clientId: 'client_001',
        clientName: 'Marie Dubois',
        clientEmail: 'marie.dubois@email.com',
        tattooistId: currentUser.uid,
        tattooistName: currentUser.displayName ?? 'Tatoueur',
        status: ProjectStatus.inProgress,
        category: 'Traditionnel japonais',
        bodyPart: 'Bras',
        size: 'Large',
        style: 'Japonais',
        colors: ['Noir', 'Rouge', 'Bleu'],
        budget: 800.0,
        estimatedPrice: 750.0,
        referenceImages: ['https://example.com/dragon1.jpg'],
        duration: 8,
        difficulty: 'expert',
        deposit: 150.0,
        depositPaid: true,
        isPublic: true,
        tags: ['dragon', 'japonais', 'bras'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ProjectModel(
        id: '',
        title: 'Rose minimaliste',
        description: 'Petit tatouage de rose dans un style minimaliste',
        clientId: 'client_002',
        clientName: 'Sophie Martin',
        clientEmail: 'sophie.martin@email.com',
        tattooistId: currentUser.uid,
        tattooistName: currentUser.displayName ?? 'Tatoueur',
        status: ProjectStatus.completed,
        category: 'Minimaliste',
        bodyPart: 'Poignet',
        size: 'Petit',
        style: 'Minimaliste',
        colors: ['Noir'],
        budget: 120.0,
        estimatedPrice: 100.0,
        finalPrice: 100.0,
        duration: 1,
        difficulty: 'débutant',
        deposit: 30.0,
        depositPaid: true,
        isPublic: true,
        completionDate: DateTime.now().subtract(const Duration(days: 5)),
        tags: ['rose', 'minimaliste', 'poignet'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    for (final project in sampleProjects) {
      try {
        await createProject(project);
        print('Projet créé: ${project.title}');
      } catch (e) {
        print('Erreur création projet ${project.title}: $e');
      }
    }
  }
}

// Enum pour les statuts de projet
enum ProjectStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  onHold;

  static ProjectStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ProjectStatus.pending;
      case 'accepted':
        return ProjectStatus.accepted;
      case 'inprogress':
      case 'in_progress':
        return ProjectStatus.inProgress;
      case 'completed':
        return ProjectStatus.completed;
      case 'cancelled':
        return ProjectStatus.cancelled;
      case 'onhold':
      case 'on_hold':
        return ProjectStatus.onHold;
      default:
        return ProjectStatus.pending;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ProjectStatus.pending:
        return 'pending';
      case ProjectStatus.accepted:
        return 'accepted';
      case ProjectStatus.inProgress:
        return 'inProgress';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.cancelled:
        return 'cancelled';
      case ProjectStatus.onHold:
        return 'onHold';
    }
  }

  String get displayName {
    switch (this) {
      case ProjectStatus.pending:
        return 'En attente';
      case ProjectStatus.accepted:
        return 'Accepté';
      case ProjectStatus.inProgress:
        return 'En cours';
      case ProjectStatus.completed:
        return 'Terminé';
      case ProjectStatus.cancelled:
        return 'Annulé';
      case ProjectStatus.onHold:
        return 'En pause';
    }
  }
}