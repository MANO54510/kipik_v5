// lib/pages/particulier/mes_projets_particulier_page.dart
import 'package:flutter/material.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../widgets/common/drawers/custom_drawer_particulier.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import 'dart:math';
import 'accueil_particulier_page.dart';
import 'detail_projet_particulier_page.dart';

class MesProjetsParticulierPage extends StatefulWidget {
  const MesProjetsParticulierPage({Key? key}) : super(key: key);

  @override
  State<MesProjetsParticulierPage> createState() => _MesProjetsParticulierPageState();
}

class _MesProjetsParticulierPageState extends State<MesProjetsParticulierPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final String _bg;
  
  // Données fictives des projets
  final List<Map<String, dynamic>> _projetsEnCours = [
    {
      'id': '1',
      'titre': 'Mandala sur l\'épaule',
      'tatoueur': 'Marie Lefevre',
      'studio': 'Dark Ink',
      'avatar': 'assets/avatars/tatoueur2.jpg',
      'date_debut': '15/04/2025',
      'prochainRdv': '25/05/2025',
      'statusRdv': 'Confirmé',
      'nbSeances': 2,
      'seancesTerminees': 0,
      'montantDevis': '350€',
      'typePreRdv': 'En physique', // 'En physique', 'En distanciel', 'Aucun'
      'preRdvEffectue': true,
      'dernierMessage': 'Bonjour, j\'ai quelques questions sur le dessin...',
      'dateMessage': '10/05/2025',
      'nouvellePhoto': true,
      'nouveauMessage': true,
      'nouveauDocument': false,
      'status': 'Projet validé', // 'En attente', 'Projet validé', 'Séance en cours', 'En finition'
      'couverture': 'assets/background1.png',
    },
    {
      'id': '2',
      'titre': 'Tatouage géométrique avant-bras',
      'tatoueur': 'Alexandre Petit',
      'studio': 'Blackwork Studio',
      'avatar': 'assets/avatars/tatoueur5.jpg',
      'date_debut': '02/05/2025',
      'prochainRdv': '17/05/2025',
      'statusRdv': 'En attente',
      'nbSeances': 1,
      'seancesTerminees': 0,
      'montantDevis': '280€',
      'typePreRdv': 'En distanciel',
      'preRdvEffectue': false,
      'dernierMessage': 'Voici les modifications du design comme discuté',
      'dateMessage': '08/05/2025',
      'nouvellePhoto': false,
      'nouveauMessage': true,
      'nouveauDocument': true,
      'status': 'En attente',
      'couverture': 'assets/background2.png',
    },
    {
      'id': '3',
      'titre': 'Fleur japonaise sur le mollet',
      'tatoueur': 'Sophie Bernard',
      'studio': 'Tattoo Factory',
      'avatar': 'assets/avatars/tatoueur4.jpg',
      'date_debut': '20/03/2025',
      'prochainRdv': '22/05/2025',
      'statusRdv': 'Confirmé',
      'nbSeances': 3,
      'seancesTerminees': 1,
      'montantDevis': '450€',
      'typePreRdv': 'Aucun',
      'preRdvEffectue': false,
      'dernierMessage': 'La première séance s\'est bien passée, rappel des soins...',
      'dateMessage': '12/05/2025',
      'nouvellePhoto': true,
      'nouveauMessage': false,
      'nouveauDocument': false,
      'status': 'Séance en cours',
      'couverture': 'assets/background3.png',
    },
  ];
  
  final List<Map<String, dynamic>> _projetsTermines = [
    {
      'id': '4',
      'titre': 'Petit oiseau poignet',
      'tatoueur': 'Jean Dupont',
      'studio': 'InkMaster',
      'avatar': 'assets/avatars/tatoueur1.jpg',
      'date_debut': '10/02/2025',
      'date_fin': '10/03/2025',
      'nbSeances': 1,
      'seancesTerminees': 1,
      'montantFinal': '150€',
      'typePreRdv': 'En physique',
      'preRdvEffectue': true,
      'noteTatoueur': 4.8,
      'commentaire': 'Très satisfait du résultat, Jean a été très pro !',
      'photosFinales': 3,
      'facture': true,
      'status': 'Terminé',
      'couverture': 'assets/background4.png',
    },
    {
      'id': '5',
      'titre': 'Bracelet tribal',
      'tatoueur': 'Camille Dubois',
      'studio': 'Studio Géométrique',
      'avatar': 'assets/avatars/avatar1.jpg',
      'date_debut': '05/01/2025',
      'date_fin': '15/02/2025',
      'nbSeances': 2,
      'seancesTerminees': 2,
      'montantFinal': '220€',
      'typePreRdv': 'En distanciel',
      'preRdvEffectue': true,
      'noteTatoueur': 5.0,
      'commentaire': 'Résultat parfait, je recommande !',
      'photosFinales': 4,
      'facture': true,
      'status': 'Terminé',
      'couverture': 'assets/background2.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bg = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ][Random().nextInt(4)];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: const CustomDrawerParticulier(),
      appBar: const CustomAppBarParticulier(
        title: 'Mes projets',
        showBackButton: true,
        showBurger: true,
        showNotificationIcon: true,
        redirectToHome: true,
      ),
      floatingActionButton: const TattooAssistantButton(
        allowImageGeneration: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond d'écran
          Image.asset(_bg, fit: BoxFit.cover),
          
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // TabBar personnalisé
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: KipikTheme.rouge, width: 2),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: KipikTheme.rouge,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 16,
                    ),
                    tabs: const [
                      Tab(text: 'En cours'),
                      Tab(text: 'Terminés'),
                    ],
                  ),
                ),
                
                // Contenu des onglets
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Onglet "En cours"
                      _projetsEnCours.isEmpty
                          ? _buildEmptyState('Aucun projet en cours', 'Consultez les tatoueurs disponibles pour commencer un nouveau projet.')
                          : _buildProjetsList(_projetsEnCours, true),
                      
                      // Onglet "Terminés"
                      _projetsTermines.isEmpty
                          ? _buildEmptyState('Aucun projet terminé', 'Vos projets terminés apparaîtront ici.')
                          : _buildProjetsList(_projetsTermines, false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // État vide (aucun projet)
  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.create_outlined,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'PermanentMarker',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AccueilParticulierPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Explorer les tatoueurs',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Liste des projets
  Widget _buildProjetsList(List<Map<String, dynamic>> projets, bool enCours) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projets.length,
      itemBuilder: (context, index) {
        final projet = projets[index];
        return _buildProjetCard(projet, enCours);
      },
    );
  }

  // Carte de projet
  Widget _buildProjetCard(Map<String, dynamic> projet, bool enCours) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailProjetParticulierPage(
              projetId: projet['id'],
              enCours: enCours,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(projet['status']),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image de couverture avec titre superposé
            Stack(
              children: [
                // Image du projet avec coins arrondis
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  child: Image.asset(
                    projet['couverture'],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Titre avec fond semi-transparent
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      projet['titre'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'PermanentMarker',
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Badge de status
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(projet['status']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      projet['status'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Informations principales
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne du tatoueur
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage(projet['avatar']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              projet['tatoueur'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              projet['studio'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (enCours && (projet['nouvellePhoto'] || projet['nouveauMessage'] || projet['nouveauDocument']))
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: KipikTheme.rouge,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      if (!enCours)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${projet['noteTatoueur']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Informations sur le projet
                  Row(
                    children: [
                      // Dates
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              enCours
                                ? 'Début: ${projet['date_debut']}'
                                : '${projet['date_debut']} - ${projet['date_fin']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Séances ou prix
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              enCours ? 'Séances' : 'Montant',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              enCours
                                ? '${projet['seancesTerminees']}/${projet['nbSeances']}'
                                : projet['montantFinal'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Informations sur le RDV ou les photos finales
                  enCours
                    ? _buildProchainRdvInfo(projet)
                    : Row(
                        children: [
                          const Icon(Icons.photo_library, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${projet['photosFinales']} photos finales',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.receipt_long, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            projet['facture'] ? 'Facture disponible' : 'Pas de facture',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                  
                  // Message pour les projets en cours
                  if (enCours && projet['dernierMessage'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.message, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              projet['dernierMessage'],
                              style: TextStyle(
                                color: projet['nouveauMessage'] ? Colors.white : Colors.white70,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            projet['dateMessage'],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Bouton pour voir les détails
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailProjetParticulierPage(
                          projetId: projet['id'],
                          enCours: enCours,
                        ),
                      ),
                    );
                  },
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          enCours ? 'Voir le projet' : 'Voir les détails',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Informations sur le prochain RDV
  Widget _buildProchainRdvInfo(Map<String, dynamic> projet) {
    final Color statusColor = projet['statusRdv'] == 'Confirmé'
        ? Colors.green
        : projet['statusRdv'] == 'En attente'
            ? Colors.orange
            : Colors.red;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            const Text(
              'Prochain RDV:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              projet['prochainRdv'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Text(
                projet['statusRdv'],
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (projet['typePreRdv'] != 'Aucun')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  projet['typePreRdv'] == 'En physique'
                      ? Icons.person
                      : Icons.videocam,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Pré-RDV ${projet['typePreRdv'].toLowerCase()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  projet['preRdvEffectue'] ? 'Effectué' : 'Non effectué',
                  style: TextStyle(
                    color: projet['preRdvEffectue'] ? Colors.green : Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Couleur en fonction du statut du projet
  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente':
        return Colors.orange;
      case 'Projet validé':
        return Colors.blue;
      case 'Séance en cours':
        return Colors.purple;
      case 'En finition':
        return Colors.teal;
      case 'Terminé':
        return Colors.green;
      default:
        return KipikTheme.rouge;
    }
  }
}
