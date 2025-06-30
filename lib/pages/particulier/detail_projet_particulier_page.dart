// lib/pages/particulier/detail_projet_particulier_page.dart - Version corrigée

import 'package:flutter/material.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../widgets/utils/facture_widget.dart';
import '../../models/facture.dart';
import '../particulier/document_item.dart'; // Import du widget corrigé
import 'dart:math';

class DetailProjetParticulierPage extends StatefulWidget {
  final String projetId;
  final bool enCours;
  // Ajouter un callback pour retourner à la page précédente
  final VoidCallback? onBack;

  const DetailProjetParticulierPage({
    Key? key,
    required this.projetId,
    required this.enCours,
    this.onBack,
  }) : super(key: key);

  @override
  State<DetailProjetParticulierPage> createState() => _DetailProjetParticulierPageState();
}

class _DetailProjetParticulierPageState extends State<DetailProjetParticulierPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final String _bg;
  Map<String, dynamic>? _projet;

  // Données fictives des projets (serait normalement récupérées d'une base de données)
  final Map<String, Map<String, dynamic>> _projetsData = {
    '1': {
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
      'typePreRdv': 'En physique',
      'preRdvEffectue': true,
      'status': 'Projet validé',
      'couverture': 'assets/background1.png',
      'description': 'Mandala géométrique sur l\'épaule droite, style blackwork avec possibilité d\'ombres grises.',
      'taille': '20 cm de diamètre',
      'emplacement': 'Épaule droite',
      'date_devis': '10/04/2025',
      'chat': [
        {
          'expediteur': 'tatoueur',
          'message': 'Bonjour, j\'ai préparé le design selon vos indications. Qu\'en pensez-vous ?',
          'date': '12/04/2025',
          'heure': '14:30',
          'image': 'assets/background1.png',
        },
        {
          'expediteur': 'client',
          'message': 'J\'adore ! Est-ce qu\'on pourrait juste accentuer un peu plus la partie centrale ?',
          'date': '12/04/2025',
          'heure': '15:45',
        },
        {
          'expediteur': 'tatoueur',
          'message': 'Bien sûr, je vais modifier ça et vous envoyer une nouvelle version.',
          'date': '12/04/2025',
          'heure': '16:20',
        },
        {
          'expediteur': 'tatoueur',
          'message': 'Voici la version modifiée avec la partie centrale plus détaillée.',
          'date': '13/04/2025',
          'heure': '10:15',
          'image': 'assets/background4.png',
        },
        {
          'expediteur': 'client',
          'message': 'Parfait ! C\'est exactement ce que je voulais !',
          'date': '13/04/2025',
          'heure': '11:30',
        },
        {
          'expediteur': 'tatoueur',
          'message': 'Super ! Je viens de vous envoyer la fiche de soins et la fiche de décharge à signer avant notre rendez-vous.',
          'date': '14/04/2025',
          'heure': '09:45',
          'document': 'Fiche de soins.pdf',
        },
        {
          'expediteur': 'tatoueur',
          'message': 'Et voici également la fiche de décharge.',
          'date': '14/04/2025',
          'heure': '09:46',
          'document': 'Fiche de décharge.pdf',
        },
        {
          'expediteur': 'client',
          'message': 'Merci, je les ai signées et renvoyées. J\'ai quelques questions sur le dessin...',
          'date': '10/05/2025',
          'heure': '14:22',
        },
      ],
      'documents': [
        {
          'nom': 'Devis_Mandala_MLefevre.pdf',
          'type': 'Devis',
          'date': '10/04/2025',
          'taille': '125 Ko',
          'signé': true,
        },
        {
          'nom': 'Fiche_de_soins.pdf',
          'type': 'Fiche de soins',
          'date': '14/04/2025',
          'taille': '250 Ko',
          'signé': true,
        },
        {
          'nom': 'Fiche_de_décharge.pdf',
          'type': 'Fiche de décharge',
          'date': '14/04/2025',
          'taille': '180 Ko',
          'signé': true,
        },
      ],
      'rendezVous': [
        {
          'type': 'Pré-rendez-vous',
          'date': '20/04/2025',
          'heure': '14:00',
          'durée': '30 minutes',
          'mode': 'En physique',
          'statut': 'Effectué',
          'notes': 'Discussion sur le design final et prise de mesures',
        },
        {
          'type': 'Séance de tatouage #1',
          'date': '25/05/2025',
          'heure': '10:00',
          'durée': '3 heures',
          'mode': 'En physique',
          'statut': 'Confirmé',
          'notes': 'Première séance, contours et début d\'ombres',
        },
        {
          'type': 'Séance de tatouage #2',
          'date': 'À définir',
          'heure': 'À définir',
          'durée': '2 heures',
          'mode': 'En physique',
          'statut': 'À programmer',
          'notes': 'Finition et détails',
        },
      ],
      'photos': [
        {
          'titre': 'Design initial',
          'date': '12/04/2025',
          'url': 'assets/background1.png',
          'description': 'Première proposition de design',
        },
        {
          'titre': 'Design final',
          'date': '13/04/2025',
          'url': 'assets/background4.png',
          'description': 'Version finale avec partie centrale retravaillée',
        },
      ],
    },
    // Les autres projets...
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _bg = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ][Random().nextInt(4)];
    
    // Récupérer les données du projet
    _projet = _projetsData[widget.projetId];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_projet == null) {
      return Scaffold(
        appBar: const CustomAppBarParticulier(
          title: 'Détail du projet',
          showBackButton: true,
        ),
        body: const Center(
          child: Text('Projet non trouvé', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBarParticulier(
        title: _projet!['titre'],
        showBackButton: true,
        showNotificationIcon: true,
        // Utiliser le callback onBack s'il est fourni
        onBackButtonPressed: widget.onBack,
      ),
      floatingActionButton: widget.enCours 
        ? const TattooAssistantButton(allowImageGeneration: false)
        : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond d'écran
          Image.asset(_bg, fit: BoxFit.cover),
          
          // Contenu principal
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // En-tête du projet
                  _buildProjetHeader(),
                  
                  // TabBar personnalisé
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                        fontSize: 14,
                      ),
                      isScrollable: true,
                      tabs: [
                        Tab(text: widget.enCours ? 'Chat' : 'Résumé'),
                        const Tab(text: 'Photos'),
                        const Tab(text: 'Rendez-vous'),
                        const Tab(text: 'Documents'),
                        const Tab(text: 'Détails'),
                      ],
                    ),
                  ),
                  
                  // Contenu des onglets
                  SizedBox(
                    // Hauteur fixe pour les onglets, permettant le défilement dans chaque onglet
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Onglet "Chat" ou "Résumé"
                        widget.enCours ? _buildChat() : _buildResume(),
                        
                        // Onglet "Photos"
                        _buildPhotos(),
                        
                        // Onglet "Rendez-vous"
                        _buildRendezVous(),
                        
                        // Onglet "Documents"
                        _buildDocuments(),
                        
                        // Onglet "Détails"
                        _buildDetails(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // En-tête du projet
  Widget _buildProjetHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(_projet!['status']), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et statut
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _projet!['titre'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'PermanentMarker',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _projet!['description'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_projet!['status']),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _projet!['status'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informations tatoueur
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(_projet!['avatar']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _projet!['tatoueur'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _projet!['studio'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Afficher la note pour les projets terminés
              if (!widget.enCours && _projet!.containsKey('noteTatoueur'))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${_projet!['noteTatoueur']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Projet terminé',
                      style: TextStyle(
                        color: _getStatusColor(_projet!['status']),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Dates et informations clés
          Row(
            children: [
              // Dates
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Période',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      widget.enCours
                          ? 'Depuis le ${_projet!['date_debut']}'
                          : '${_projet!['date_debut']} - ${_projet!['date_fin']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Montant ou séances
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.enCours ? 'Devis' : 'Montant final',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      widget.enCours
                          ? _projet!['montantDevis']
                          : _projet!['montantFinal'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Séances
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Séances',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${_projet!['seancesTerminees']}/${_projet!['nbSeances']}',
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
        ],
      ),
    );
  }

  // Onglet Chat (pour les projets en cours)
  Widget _buildChat() {
    final List chatMessages = _projet!['chat'] ?? [];
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // En-tête du chat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(_projet!['avatar']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _projet!['tatoueur'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Chat disponible jusqu\'à la fin du projet',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: chatMessages.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun message pour le moment',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = chatMessages[index];
                      final bool isClient = message['expediteur'] == 'client';
                      
                      return Align(
                        alignment: isClient
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Column(
                            crossAxisAlignment: isClient
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // Info expéditeur et date
                              Padding(
                                padding: EdgeInsets.only(
                                  left: isClient ? 0 : 12,
                                  right: isClient ? 12 : 0,
                                  bottom: 4,
                                ),
                                child: Text(
                                  '${isClient ? 'Vous' : _projet!['tatoueur']} - ${message['date']} ${message['heure']}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              
                              // Bulle de message
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isClient
                                      ? KipikTheme.rouge.withOpacity(0.7)
                                      : Colors.grey[800],
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Texte du message
                                    Text(
                                      message['message'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    
                                    // Image si présente
                                    if (message['image'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.asset(
                                            message['image'],
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    
                                    // Document si présent
                                    if (message['document'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.insert_drive_file,
                                                color: Colors.white70,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  message['document'],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              const Icon(
                                                Icons.download,
                                                color: Colors.white70,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.white70),
                  onPressed: () {
                    // Logic pour joindre un fichier
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.photo, color: Colors.white70),
                  onPressed: () {
                    // Logic pour joindre une photo
                  },
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre message...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[800],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: KipikTheme.rouge,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      // Logic pour envoyer le message
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Onglet Résumé (pour les projets terminés)
  Widget _buildResume() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de résumé
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Résumé du projet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Informations principales
                _buildInfoRow('Titre', _projet!['titre']),
                _buildInfoRow('Style', _projet!['description'].split(',')[0]),
                _buildInfoRow('Emplacement', _projet!['emplacement']),
                _buildInfoRow('Taille', _projet!['taille']),
                _buildInfoRow('Nombre de séances', '${_projet!['nbSeances']}'),
                _buildInfoRow('Montant final', _projet!['montantFinal']),
                _buildInfoRow('Date de début', _projet!['date_debut']),
                _buildInfoRow('Date de fin', _projet!['date_fin']),
                
                const Divider(color: Colors.white24, height: 32),
                
                // Commentaire et note
                const Text(
                  'Votre avis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${_projet!['noteTatoueur']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _projet!['commentaire'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Photos du résultat final
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photos finales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 200,
                  child: _projet!.containsKey('photos') && _projet!['photos'].isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _projet!['photos'].length,
                        itemBuilder: (context, index) {
                          final photo = _projet!['photos'][index];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 160,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    photo['url'],
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.7),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        photo['titre'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text(
                          'Aucune photo disponible',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Documents importants
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Documents principaux',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Liste des documents importants (devis, facture)
                _projet!.containsKey('documents') && _projet!['documents'].isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _projet!['documents'].length,
                      itemBuilder: (context, index) {
                        final document = _projet!['documents'][index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            document['type'] == 'Facture'
                                ? Icons.receipt_long
                                : Icons.insert_drive_file,
                            color: document['type'] == 'Facture'
                                ? Colors.green
                                : Colors.white70,
                          ),
                          title: Text(
                            document['nom'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${document['type']} - ${document['date']}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              // Logique pour télécharger le document
                            },
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'Aucun document disponible',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Onglet Photos  
  Widget _buildPhotos() {
    final List photos = _projet!['photos'] ?? [];
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: photos.isEmpty
          ? const Center(
              child: Text(
                'Aucune photo disponible',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return GestureDetector(
                  onTap: () {
                    // Logic pour afficher la photo en plein écran
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            InteractiveViewer(
                              child: Image.asset(
                                photo['url'],
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 40,
                              right: 16,
                              child: CircleAvatar(
                                backgroundColor: Colors.black45,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 40,
                              left: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      photo['titre'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: ${photo['date']}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      photo['description'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          photo['url'],
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  photo['titre'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  photo['date'],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Onglet Rendez-vous
  Widget _buildRendezVous() {
    final List rendezVous = _projet!['rendezVous'] ?? [];
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: rendezVous.isEmpty
          ? const Center(
              child: Text(
                'Aucun rendez-vous programmé',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rendezVous.length,
              itemBuilder: (context, index) {
                final rdv = rendezVous[index];
                final IconData icon = rdv['mode'] == 'En physique'
                    ? Icons.person
                    : rdv['mode'] == 'En distanciel'
                        ? Icons.videocam
                        : Icons.event;
                        
                final Color statusColor = rdv['statut'] == 'Effectué'
                    ? Colors.green
                    : rdv['statut'] == 'Confirmé'
                        ? Colors.blue
                        : rdv['statut'] == 'En attente'
                            ? Colors.orange
                            : rdv['statut'] == 'À venir'
                                ? Colors.purple
                                : Colors.grey;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type et statut
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              rdv['type'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Text(
                              rdv['statut'],
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Date et heure
                      Row(
                        children: [
                          const Icon(Icons.event, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${rdv['date']} à ${rdv['heure']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            rdv['durée'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Mode
                      Row(
                        children: [
                          Icon(icon, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            rdv['mode'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      
                      // Notes
                      if (rdv['notes'] != null && rdv['notes'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.note, color: Colors.white70, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rdv['notes'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Boutons d'action (pour les RDV à venir)
                      if (rdv['statut'] == 'À venir' || rdv['statut'] == 'En attente' || rdv['statut'] == 'À confirmer')
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Logic pour confirmer le RDV
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                icon: const Icon(Icons.check, color: Colors.white, size: 16),
                                label: const Text('Confirmer', style: TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  // Logic pour reprogrammer le RDV
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: const Text('Reprogrammer'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Onglet Documents
  Widget _buildDocuments() {
    final List documents = _projet!['documents'] ?? [];
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: documents.isEmpty
          ? const Center(
              child: Text(
                'Aucun document disponible',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length + (widget.enCours ? 0 : 1), // Ajouter la facture pour les projets terminés
              itemBuilder: (context, index) {
                // Pour les projets terminés, ajouter la facture en haut de la liste
                if (!widget.enCours && index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.5), width: 1),
                    ),
                    child: Row(
                      children: [
                        // Icône du document
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Détails du document
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Facture finale',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text(
                                    'Facture',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.calendar_today, color: Colors.white54, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    _projet!['date_fin'],
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Badge acquitté
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'Acquittée',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Boutons d'action
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.white70),
                              onPressed: () {
                                // Afficher la facture
                                _showFacture();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.download, color: Colors.white70),
                              onPressed: () {
                                // Logique pour télécharger la facture
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                
                // Pour les autres documents
                final document = documents[widget.enCours ? index : index - 1];
                IconData iconData;
                Color iconColor;
                
                switch (document['type']) {
                  case 'Devis':
                  case 'Devis modifié':
                    iconData = Icons.description;
                    iconColor = Colors.blue;
                    break;
                  case 'Facture':
                    iconData = Icons.receipt_long;
                    iconColor = Colors.green;
                    break;
                  case 'Fiche de soins':
                    iconData = Icons.healing;
                    iconColor = Colors.purple;
                    break;
                  case 'Fiche de décharge':
                    iconData = Icons.assignment;
                    iconColor = Colors.orange;
                    break;
                  default:
                    iconData = Icons.insert_drive_file;
                    iconColor = Colors.grey;
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withOpacity(0.5), width: 1),
                  ),
                  child: Row(
                    children: [
                      // Icône du document
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Détails du document
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              document['nom'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  document['type'],
                                  style: TextStyle(
                                    color: iconColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.calendar_today, color: Colors.white54, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  document['date'],
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.data_usage, color: Colors.white54, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  document['taille'],
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Badge de signature (si applicable)
                            if (document['signé'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: document['signé']
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: document['signé'] ? Colors.green : Colors.orange,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    document['signé'] ? 'Signé' : 'Non signé',
                                    style: TextStyle(
                                      color: document['signé'] ? Colors.green : Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Boutons d'action
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.white70),
                            onPressed: () {
                              // Logique pour visualiser le document
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.white70),
                            onPressed: () {
                              // Logique pour télécharger le document
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
  
  // Afficher la facture en plein écran
  void _showFacture() {
    // Générer une facture à partir des données du projet
    final facture = Facture.genererDepuisProjet(
      _projet!,
      'John Doe', // Remplacer par les vraies données client
      '15 Rue de la République, 75001 Paris',
      'client@example.com',
    );
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // En-tête avec bouton fermer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: KipikTheme.rouge,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Facture',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Contenu de la facture
              Expanded(
                child: FactureWidget(facture: facture),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Onglet Détails
  Widget _buildDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte des détails du projet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détails du projet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Informations détaillées
                _buildInfoRow('Titre', _projet!['titre']),
                _buildInfoRow('Description', _projet!['description']),
                _buildInfoRow('Emplacement', _projet!['emplacement']),
                _buildInfoRow('Taille', _projet!['taille']),
                _buildInfoRow('Date de début', _projet!['date_debut']),
                if (!widget.enCours) _buildInfoRow('Date de fin', _projet!['date_fin']),
                _buildInfoRow('Tatoueur', _projet!['tatoueur']),
                _buildInfoRow('Studio', _projet!['studio']),
                _buildInfoRow('Nombre de séances prévues', '${_projet!['nbSeances']}'),
                _buildInfoRow('Séances effectuées', '${_projet!['seancesTerminees']}'),
                
                if (_projet!['typePreRdv'] != 'Aucun')
                  _buildInfoRow(
                    'Pré-rendez-vous',
                    '${_projet!['typePreRdv']} - ${_projet!['preRdvEffectue'] ? 'Effectué' : 'Non effectué'}',
                  ),
                
                _buildInfoRow(
                  widget.enCours ? 'Devis' : 'Montant final',
                  widget.enCours ? _projet!['montantDevis'] : _projet!['montantFinal'],
                ),
                
                if (!widget.enCours && _projet!.containsKey('noteTatoueur')) 
                  _buildInfoRow('Note attribuée', '${_projet!['noteTatoueur']}'),
                if (!widget.enCours && _projet!.containsKey('commentaire'))
                  _buildInfoRow('Commentaire', _projet!['commentaire']),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistiques du projet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistiques',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Progression
                const Text(
                  'Progression du projet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _projet!['seancesTerminees'] / _projet!['nbSeances'],
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(_projet!['status'])),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${_projet!['seancesTerminees']}/${_projet!['nbSeances']} séances réalisées',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Photos et documents
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.photo_library,
                        title: 'Photos',
                        value: '${_projet!['photos']?.length ?? 0}',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.file_copy,
                        title: 'Documents',
                        value: '${_projet!['documents']?.length ?? 0}',
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.event,
                        title: 'Rendez-vous',
                        value: '${_projet!['rendezVous']?.length ?? 0}',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                if (widget.enCours && _projet!.containsKey('chat'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.message,
                            title: 'Messages échangés',
                            value: '${_projet!['chat'].length}',
                            color: KipikTheme.rouge,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          if (widget.enCours)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'PermanentMarker',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Boutons d'action pour les projets en cours
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.message,
                        label: 'Contacter',
                        color: KipikTheme.rouge,
                        onTap: () {
                          // Naviguer vers l'onglet Chat
                          _tabController.animateTo(0);
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.camera_alt,
                        label: 'Ajouter photo',
                        color: Colors.blue,
                        onTap: () {
                          // Logic pour ajouter une photo
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.calendar_today,
                        label: 'RDV',
                        color: Colors.purple,
                        onTap: () {
                          // Naviguer vers l'onglet Rendez-vous
                          _tabController.animateTo(2);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper pour afficher une ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour afficher une carte de statistique
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper pour afficher un bouton d'action
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour obtenir la couleur en fonction du statut
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