// lib/models/rdv_model.dart
import 'rdv_classes.dart';

class RdvService {
  Future<List<RdvModel>> getRendezVous() async {
    // Simulation de données de rendez-vous
    final now = DateTime.now();
    
    final List<RdvModel> rendezVous = [
      RdvModel(
        date: DateTime(now.year, now.month, now.day, 14, 30),
        type: 'tatouage',
        tatoueur: Tatoueur(
          nom: 'Alex Noir',
          photo: 'assets/tatoueurs/tatoueur1.jpg',
          email: 'alex@studio-ink.com',
          note: 4.8,
          specialite: 'Blackwork',
        ),
        studio: Studio(
          nom: 'Studio Ink',
          adresse: '15 rue des Arts, 75003 Paris',
          lat: 48.8612,
          lng: 2.3652,
        ),
        prix: 250.0,
        duree: const Duration(hours: 3),
        dureeTrajet: const Duration(minutes: 25),
        status: 'confirmé',
        zoneCorps: 'Avant-bras gauche',
        taille: '20 x 15 cm',
        description: 'Tatouage géométrique avec motifs floraux en style blackwork.',
        imagesReference: [
          'assets/references/ref1.jpg',
          'assets/references/ref2.jpg',
        ],
      ),
      
      RdvModel(
        date: DateTime(now.year, now.month, now.day + 3, 11, 0),
        type: 'consultation',
        tatoueur: Tatoueur(
          nom: 'Marie Encre',
          photo: 'assets/tatoueurs/tatoueur2.jpg',
          email: 'marie@kipik-studio.com',
          note: 4.9,
          specialite: 'Neo-traditional',
        ),
        studio: Studio(
          nom: 'Kipik Studio',
          adresse: '28 boulevard Saint-Germain, 75006 Paris',
          lat: 48.8520,
          lng: 2.3366,
        ),
        prix: 50.0,
        duree: const Duration(minutes: 45),
        dureeTrajet: const Duration(minutes: 35),
        status: 'confirmé',
        zoneCorps: 'Dos',
        taille: 'À déterminer',
        description: 'Consultation pour un projet de tatouage néo-traditionnel représentant un phénix.',
        imagesReference: [
          'assets/references/ref3.jpg',
        ],
      ),
      
      RdvModel(
        date: DateTime(now.year, now.month, now.day + 7, 16, 0),
        type: 'tatouage',
        tatoueur: Tatoueur(
          nom: 'Lucas Skin',
          photo: 'assets/tatoueurs/tatoueur3.jpg',
          email: 'lucas@dark-art.com',
          note: 4.7,
          specialite: 'Réalisme',
        ),
        studio: Studio(
          nom: 'Dark Art Tattoo',
          adresse: '42 rue Oberkampf, 75011 Paris',
          lat: 48.8648,
          lng: 2.3713,
        ),
        prix: 400.0,
        duree: const Duration(hours: 5),
        dureeTrajet: const Duration(minutes: 20),
        status: 'en attente',
        zoneCorps: 'Mollet droit',
        taille: '25 x 20 cm',
        description: 'Portrait réaliste d\'un loup dans la forêt avec effets de lumière.',
        imagesReference: [
          'assets/references/ref4.jpg',
          'assets/references/ref5.jpg',
          'assets/references/ref6.jpg',
        ],
      ),
      
      RdvModel(
        date: DateTime(now.year, now.month, now.day + 14, 10, 0),
        type: 'retouche',
        tatoueur: Tatoueur(
          nom: 'Alex Noir',
          photo: 'assets/tatoueurs/tatoueur1.jpg',
          email: 'alex@studio-ink.com',
          note: 4.8,
          specialite: 'Blackwork',
        ),
        studio: Studio(
          nom: 'Studio Ink',
          adresse: '15 rue des Arts, 75003 Paris',
          lat: 48.8612,
          lng: 2.3652,
        ),
        prix: 80.0,
        duree: const Duration(hours: 1, minutes: 30),
        dureeTrajet: const Duration(minutes: 25),
        status: 'confirmé',
        zoneCorps: 'Avant-bras gauche',
        taille: '20 x 15 cm',
        description: 'Retouche et renforcement des lignes du tatouage floral réalisé précédemment.',
        imagesReference: [
          'assets/references/ref1.jpg',
        ],
      ),
      
      RdvModel(
        date: DateTime(now.year, now.month, now.day + 21, 14, 0),
        type: 'coverup',
        tatoueur: Tatoueur(
          nom: 'Cécile Tinta',
          photo: 'assets/tatoueurs/tatoueur4.jpg',
          email: 'cecile@blackrose.com',
          note: 4.9,
          specialite: 'Cover-up',
        ),
        studio: Studio(
          nom: 'Black Rose Tattoo',
          adresse: '7 rue Saint-Sauveur, 75002 Paris',
          lat: 48.8663,
          lng: 2.3481,
        ),
        prix: 350.0,
        duree: const Duration(hours: 4),
        dureeTrajet: const Duration(minutes: 30),
        status: 'en attente',
        zoneCorps: 'Épaule droite',
        taille: '18 x 18 cm',
        description: 'Cover-up d\'un ancien tatouage tribal par un design floral et ornemental.',
        imagesReference: [
          'assets/references/ref7.jpg',
          'assets/references/ref8.jpg',
        ],
      ),
      
      // Ajout d'un rendez-vous pour aujourd'hui (en plus)
      RdvModel(
        date: DateTime(now.year, now.month, now.day, 18, 0),
        type: 'consultation',
        tatoueur: Tatoueur(
          nom: 'Tom Lazuli',
          photo: 'assets/tatoueurs/tatoueur5.jpg',
          email: 'tom@lazuli-ink.com',
          note: 4.6,
          specialite: 'Aquarelle',
        ),
        studio: Studio(
          nom: 'Lazuli Ink',
          adresse: '38 rue de Charonne, 75011 Paris',
          lat: 48.8531,
          lng: 2.3774,
        ),
        prix: 40.0,
        duree: const Duration(minutes: 45),
        dureeTrajet: const Duration(minutes: 15),
        status: 'confirmé',
        zoneCorps: 'Avant-bras droit',
        taille: 'À déterminer',
        description: 'Consultation pour un projet de tatouage aquarelle inspiré du Japon.',
        imagesReference: [
          'assets/references/ref9.jpg',
        ],
      ),
      
      // Ajout d'un rendez-vous dans deux jours
      RdvModel(
        date: DateTime(now.year, now.month, now.day + 2, 13, 0),
        type: 'tatouage',
        tatoueur: Tatoueur(
          nom: 'Nina Steel',
          photo: 'assets/tatoueurs/tatoueur6.jpg',
          email: 'nina@steel-art.com',
          note: 4.7,
          specialite: 'Minimaliste',
        ),
        studio: Studio(
          nom: 'Steel Art Tattoo',
          adresse: '17 rue du Faubourg Montmartre, 75009 Paris',
          lat: 48.8739,
          lng: 2.3425,
        ),
        prix: 200.0,
        duree: const Duration(hours: 2),
        dureeTrajet: const Duration(minutes: 22),
        status: 'confirmé',
        zoneCorps: 'Poignet gauche',
        taille: '8 x 4 cm',
        description: 'Petit tatouage minimaliste avec motifs géométriques et symboliques.',
        imagesReference: [
          'assets/references/ref10.jpg',
          'assets/references/ref11.jpg',
        ],
      ),
      
      // Ajout d'un rendez-vous pour la semaine suivante
      RdvModel(
        date: DateTime(now.year, now.month, now.day + 10, 11, 30),
        type: 'tatouage',
        tatoueur: Tatoueur(
          nom: 'Marie Encre',
          photo: 'assets/tatoueurs/tatoueur2.jpg',
          email: 'marie@kipik-studio.com',
          note: 4.9,
          specialite: 'Neo-traditional',
        ),
        studio: Studio(
          nom: 'Kipik Studio',
          adresse: '28 boulevard Saint-Germain, 75006 Paris',
          lat: 48.8520,
          lng: 2.3366,
        ),
        prix: 320.0,
        duree: const Duration(hours: 4),
        dureeTrajet: const Duration(minutes: 35),
        status: 'confirmé',
        zoneCorps: 'Dos',
        taille: '30 x 20 cm',
        description: 'Première session pour le tatouage du phénix en style néo-traditionnel.',
        imagesReference: [
          'assets/references/ref3.jpg',
          'assets/references/ref12.jpg',
        ],
      ),
      
      // Rendez-vous pour le mois prochain
      RdvModel(
        date: DateTime(now.year, now.month + 1, 5, 14, 0),
        type: 'tatouage',
        tatoueur: Tatoueur(
          nom: 'Marie Encre',
          photo: 'assets/tatoueurs/tatoueur2.jpg',
          email: 'marie@kipik-studio.com',
          note: 4.9,
          specialite: 'Neo-traditional',
        ),
        studio: Studio(
          nom: 'Kipik Studio',
          adresse: '28 boulevard Saint-Germain, 75006 Paris',
          lat: 48.8520,
          lng: 2.3366,
        ),
        prix: 320.0,
        duree: const Duration(hours: 4),
        dureeTrajet: const Duration(minutes: 35),
        status: 'confirmé',
        zoneCorps: 'Dos',
        taille: '30 x 20 cm',
        description: 'Deuxième session pour le tatouage du phénix en style néo-traditionnel.',
        imagesReference: [
          'assets/references/ref3.jpg',
          'assets/references/ref12.jpg',
        ],
      ),
    ];
    
    return rendezVous;
  }
}