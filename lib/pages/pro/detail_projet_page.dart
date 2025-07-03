// lib/pages/pro/detail_projet_page.dart

import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../services/project/firebase_project_service.dart'; // ✅ MIGRATION

class DetailProjetPage extends StatefulWidget {
  final String projectId;
  final FirebaseProjectService? projectService; // ✅ MIGRATION: Optionnel car on utilise l'instance

  const DetailProjetPage({
    Key? key,
    required this.projectId,
    this.projectService, // ✅ MIGRATION: Maintenant optionnel
  }) : super(key: key);

  @override
  State<DetailProjetPage> createState() => _DetailProjetPageState();
}

class _DetailProjetPageState extends State<DetailProjetPage> {
  late Future<ProjectModel?> _futureProject;
  ProjectModel? _currentProject;
  bool _isLoading = false;

  // ✅ MIGRATION: Utiliser l'instance singleton
  FirebaseProjectService get _projectService => 
      widget.projectService ?? FirebaseProjectService.instance;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  // ✅ MIGRATION: Méthode de chargement avec gestion d'erreurs améliorée
  Future<void> _loadProject() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final project = await _projectService.fetchProjectById(widget.projectId);
      if (mounted) {
        setState(() {
          _currentProject = project;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NOUVEAU: Méthode pour mettre à jour le statut
  Future<void> _updateStatus(ProjectStatus newStatus) async {
    try {
      await _projectService.updateProjectStatus(widget.projectId, newStatus);
      await _loadProject(); // Recharger le projet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Statut mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NOUVEAU: Widget pour afficher le statut avec couleur
  Widget _buildStatusChip(ProjectStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case ProjectStatus.pending:
        color = Colors.orange;
        label = 'En attente';
        break;
      case ProjectStatus.accepted:
        color = Colors.blue;
        label = 'Accepté';
        break;
      case ProjectStatus.inProgress:
        color = Colors.purple;
        label = 'En cours';
        break;
      case ProjectStatus.completed:
        color = Colors.green;
        label = 'Terminé';
        break;
      case ProjectStatus.cancelled:
        color = Colors.red;
        label = 'Annulé';
        break;
      case ProjectStatus.onHold:
        color = Colors.grey;
        label = 'En pause';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
    );
  }

  // ✅ NOUVEAU: Bouton d'action selon le statut
  Widget? _buildActionButton() {
    if (_currentProject == null) return null;

    switch (_currentProject!.status) {
      case ProjectStatus.pending:
        return ElevatedButton(
          onPressed: () => _updateStatus(ProjectStatus.accepted),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Accepter le projet'),
        );
      case ProjectStatus.accepted:
        return ElevatedButton(
          onPressed: () => _updateStatus(ProjectStatus.inProgress),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          child: const Text('Commencer le projet'),
        );
      case ProjectStatus.inProgress:
        return ElevatedButton(
          onPressed: () => _updateStatus(ProjectStatus.completed),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Marquer comme terminé'),
        );
      default:
        return null;
    }
  }

  // ✅ NOUVEAU: Widget pour les images
  Widget _buildImageSection(String title, List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(images[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _currentProject?.title ?? 'Détail du projet',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ✅ NOUVEAU: Menu d'actions
          if (_currentProject != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    // TODO: Navigation vers page d'édition
                    break;
                  case 'delete':
                    // Confirmation avant suppression
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer'),
                        content: const Text('Supprimer définitivement ce projet ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await _projectService.deleteProject(widget.projectId);
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')),
                          );
                        }
                      }
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Modifier'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _currentProject == null
              ? const Center(
                  child: Text(
                    'Projet introuvable ou accès refusé',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProject,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ En-tête du projet
                        Card(
                          color: Colors.grey[900],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _currentProject!.title,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    _buildStatusChip(_currentProject!.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_currentProject!.description.isNotEmpty) ...[
                                  Text(
                                    _currentProject!.description,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ✅ Informations client
                        Card(
                          color: Colors.grey[900],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Client',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _InfoRow('Nom', _currentProject!.clientName),
                                _InfoRow('Email', _currentProject!.clientEmail),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ✅ Détails du tatouage
                        Card(
                          color: Colors.grey[900],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Détails du tatouage',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_currentProject!.category.isNotEmpty)
                                  _InfoRow('Catégorie', _currentProject!.category),
                                if (_currentProject!.style.isNotEmpty)
                                  _InfoRow('Style', _currentProject!.style),
                                if (_currentProject!.bodyPart.isNotEmpty)
                                  _InfoRow('Partie du corps', _currentProject!.bodyPart),
                                if (_currentProject!.size.isNotEmpty)
                                  _InfoRow('Taille', _currentProject!.size),
                                if (_currentProject!.colors.isNotEmpty)
                                  _InfoRow('Couleurs', _currentProject!.colors.join(', ')),
                                if (_currentProject!.difficulty.isNotEmpty)
                                  _InfoRow('Difficulté', _currentProject!.difficulty),
                                if (_currentProject!.duration != null)
                                  _InfoRow('Durée estimée', '${_currentProject!.duration}h'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ✅ Informations financières
                        if (_currentProject!.budget != null ||
                            _currentProject!.estimatedPrice != null ||
                            _currentProject!.finalPrice != null) ...[
                          Card(
                            color: Colors.grey[900],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informations financières',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_currentProject!.budget != null)
                                    _InfoRow('Budget client', '${_currentProject!.budget!.toStringAsFixed(0)}€'),
                                  if (_currentProject!.estimatedPrice != null)
                                    _InfoRow('Devis estimé', '${_currentProject!.estimatedPrice!.toStringAsFixed(0)}€'),
                                  if (_currentProject!.finalPrice != null)
                                    _InfoRow('Prix final', '${_currentProject!.finalPrice!.toStringAsFixed(0)}€'),
                                  if (_currentProject!.deposit != null) ...[
                                    _InfoRow('Acompte', '${_currentProject!.deposit!.toStringAsFixed(0)}€'),
                                    _InfoRow('Acompte payé', _currentProject!.depositPaid ? 'Oui' : 'Non'),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ✅ Images de référence
                        if (_currentProject!.referenceImages.isNotEmpty) ...[
                          Card(
                            color: Colors.grey[900],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildImageSection(
                                'Images de référence',
                                _currentProject!.referenceImages,
                              ),
                            ),
                          ),
                        ],

                        // ✅ Esquisses
                        if (_currentProject!.sketchImages.isNotEmpty) ...[
                          Card(
                            color: Colors.grey[900],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildImageSection(
                                'Esquisses',
                                _currentProject!.sketchImages,
                              ),
                            ),
                          ),
                        ],

                        // ✅ Images finales
                        if (_currentProject!.finalImages.isNotEmpty) ...[
                          Card(
                            color: Colors.grey[900],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildImageSection(
                                'Résultat final',
                                _currentProject!.finalImages,
                              ),
                            ),
                          ),
                        ],

                        // ✅ Dates importantes
                        Card(
                          color: Colors.grey[900],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dates importantes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _InfoRow('Créé le', _formatDate(_currentProject!.createdAt)),
                                _InfoRow('Mis à jour le', _formatDate(_currentProject!.updatedAt)),
                                if (_currentProject!.appointmentDate != null)
                                  _InfoRow('Rendez-vous', _formatDate(_currentProject!.appointmentDate!)),
                                if (_currentProject!.completionDate != null)
                                  _InfoRow('Terminé le', _formatDate(_currentProject!.completionDate!)),
                              ],
                            ),
                          ),
                        ),

                        // ✅ Notes
                        if (_currentProject!.notes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Card(
                            color: Colors.grey[900],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Notes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _currentProject!.notes,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // ✅ Bouton d'action
                        const SizedBox(height: 24),
                        if (_buildActionButton() != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: _buildActionButton()!,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  // ✅ Utilitaire: Formatage des dates
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ✅ Widget utilitaire pour afficher les informations
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}