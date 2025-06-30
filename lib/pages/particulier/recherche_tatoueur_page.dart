// lib/pages/particulier/recherche_tatoueur_page.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../widgets/common/drawers/custom_drawer_particulier.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../pro/profil_tatoueur.dart';
import 'accueil_particulier_page.dart';


class RechercheTatoueurPage extends StatefulWidget {
  const RechercheTatoueurPage({Key? key}) : super(key: key);

  @override
  State<RechercheTatoueurPage> createState() => _RechercheTatoueurPageState();
}

class _RechercheTatoueurPageState extends State<RechercheTatoueurPage> {
  // géolocalisation vs ville
  bool _asked = false,
       _geoGranted = false,
       _loadingPos = false,
       _villeMode = false;
  Position? _pos;
  final _villeController = TextEditingController();
  
  // suggestions de villes pendant la saisie
  List<Map<String, dynamic>> _villeSuggestions = [];
  bool _loadingSuggestions = false;
  
  // recherche par nom
  final _searchC = TextEditingController();
  
  // vue carte / liste
  String _view = 'map';
  
  // filtres
  String? _dist, _avail;
  List<String> _styles = [];
  final distances = ['5km', '10km', '20km', '50km', '100km'];
  final disponibilites = [
    "Aujourd'hui",
    '3 jours',
    '2 semaines',
    '1 mois',
    'Plus d\'1 mois',
    'Plus de 6 mois'
  ];
  
  final stylesList = [
    'Abstrait',
    'Anime',
    'Aquarelle',
    'Biomécanique',
    'Blackwork',
    'Celtiques',
    'Chicano',
    'Couleur',
    'Esquisse',
    'Géométrique',
    'Horreur',
    'Illustratif',
    'Japonais (Irezumi)',
    'Lettering',
    'Line fin',
    'Maori',
    'Micro-réalisme',
    'Minimaliste',
    'Néo-traditionnel',
    'Noir et gris',
    'Ornemental',
    'Pointillisme',
    'Polynésien',
    'Portrait',
    'Réaliste',
    'Sticker Sleeve',
    'Surréalisme',
    'Traditionnel',
    'Trash Polka',
    'Tribal',
  ];
  
  // stub tatoueurs
  List<Map<String, dynamic>> _all = [], _filtered = [];
  
  // fond aléatoire
  late final String _bg;
  
  // Votre clé API Google Maps (avec Places API et Geocoding API activées)
  static const _geocodeApiKey = 'AIzaSyAXHDIXeZZXVPnABpT3O8GmBzUNeyFoSp8';

  @override
  void initState() {
    super.initState();
    _bg = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ][Random().nextInt(4)];
    _loadTatoueurs();
  }

  Future<void> _loadTatoueurs() async {
    // Version améliorée des tatoueurs avec informations plus détaillées
    _all = [
      {
        'name': 'Jean Dupont',
        'studio': 'InkMaster',
        'style': 'Réaliste',
        'lat': 48.692054,
        'lng': 6.184417,
        'avail': '3 jours',
        'avatar': 'assets/avatars/tatoueur1.jpg',
        'note': 4.8,
        'adresse': '15 Rue Saint-Dizier, 54000 Nancy',
        'instagram': '@jeandupont_tattoo',
        'ville': 'Nancy',
        'distance': '1.2 km',
      },
      {
        'name': 'Marie Lefevre',
        'studio': 'Dark Ink',
        'style': 'Traditionnel',
        'lat': 48.693,
        'lng': 6.18,
        'avail': "Aujourd'hui",
        'avatar': 'assets/avatars/tatoueur2.jpg',
        'note': 4.9,
        'adresse': '8 Place des Vosges, 54000 Nancy',
        'instagram': '@marielefevre_ink',
        'ville': 'Nancy',
        'distance': '1.5 km',
      },
      {
        'name': 'Lucas Martin',
        'studio': 'MinimalInk',
        'style': 'Minimaliste',
        'lat': 48.694,
        'lng': 6.185,
        'avail': '2 semaines',
        'avatar': 'assets/avatars/tatoueur3.jpg',
        'note': 4.7,
        'adresse': '12 Rue Stanislas, 54000 Nancy',
        'instagram': '@lucasmartin_tattoo',
        'ville': 'Nancy',
        'distance': '2.3 km',
      },
      {
        'name': 'Sophie Bernard',
        'studio': 'Tattoo Factory',
        'style': 'Japonais (Irezumi)',
        'lat': 48.690,
        'lng': 6.175,
        'avail': '1 mois',
        'avatar': 'assets/avatars/tatoueur4.jpg',
        'note': 4.6,
        'adresse': '22 Avenue de la Libération, 54000 Nancy',
        'instagram': '@sophiebernard_irezumi',
        'ville': 'Nancy',
        'distance': '3.1 km',
      },
      {
        'name': 'Alexandre Petit',
        'studio': 'Blackwork Studio',
        'style': 'Blackwork',
        'lat': 48.687,
        'lng': 6.182,
        'avail': '2 semaines',
        'avatar': 'assets/avatars/tatoueur5.jpg',
        'note': 4.7,
        'adresse': '7 Rue des Dominicains, 54000 Nancy',
        'instagram': '@alexpetit_blackwork',
        'ville': 'Nancy',
        'distance': '2.8 km',
      },
      {
        'name': 'Camille Dubois',
        'studio': 'Studio Géométrique',
        'style': 'Géométrique',
        'lat': 48.6871,
        'lng': 6.2182,
        'avail': "Aujourd'hui",
        'avatar': 'assets/avatars/avatar1.jpg',
        'note': 4.9,
        'adresse': '5 Avenue de la Paix, 54510 Tomblaine',
        'instagram': '@camilledubois_geo',
        'ville': 'Tomblaine',
        'distance': '0.5 km',
      },
      // Ajout d'un tatoueur avec disponibilité "Plus d'1 mois"
      {
        'name': 'Emma Durand',
        'studio': 'Ink Paradise',
        'style': 'Aquarelle',
        'lat': 48.6890,
        'lng': 6.1790,
        'avail': "Plus d'1 mois",
        'avatar': 'assets/avatars/avatar2.jpg',
        'note': 4.9,
        'adresse': '32 Rue de la République, 54000 Nancy',
        'instagram': '@emmadurand_aqua',
        'ville': 'Nancy',
        'distance': '2.0 km',
      },
      // Ajout d'un tatoueur avec disponibilité "Plus de 6 mois"
      {
        'name': 'Thomas Roche',
        'studio': 'Elite Tattoo',
        'style': 'Réaliste',
        'lat': 48.6950,
        'lng': 6.1950,
        'avail': "Plus de 6 mois",
        'avatar': 'assets/avatars/avatar3.jpg',
        'note': 5.0,
        'adresse': '10 Rue des Carmes, 54000 Nancy',
        'instagram': '@thomasroche_elite',
        'ville': 'Nancy',
        'distance': '3.5 km',
      },
    ];
    _filtered = List.from(_all);
    setState(() {});
  }

  void _maybeAskLoc() {
    if (!_asked) {
      _asked = true;
      _askPermission();
    }
  }

  Future<void> _askPermission() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Partager ma localisation ?',
          style: TextStyle(color: Colors.white, fontFamily: 'PermanentMarker'),
        ),
        content: const Text(
          'Autorisez la géolocalisation ou saisissez votre ville.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white)
                .copyWith(overlayColor: MaterialStateProperty.all(KipikTheme.rouge)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white)
                .copyWith(overlayColor: MaterialStateProperty.all(KipikTheme.rouge)),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
        ],
      ),
    );
    if (res == true) {
      setState(() => _villeMode = false);
      _initGeo();
    } else {
      setState(() => _villeMode = true);
    }
  }

  Future<void> _initGeo() async {
    setState(() => _loadingPos = true);
    
    try {
      // Vérifier si les services de localisation sont activés
      final service = await Geolocator.isLocationServiceEnabled();
      if (!service) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Services de localisation désactivés. Veuillez les activer.'))
        );
        setState(() {
          _loadingPos = false;
          _villeMode = true; // Passer en mode de saisie de ville si échec de la géolocalisation
        });
        return;
      }
      
      // Vérifier les permissions
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
        
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissions de localisation refusées'))
          );
          setState(() {
            _loadingPos = false;
            _villeMode = true; // Passer en mode de saisie de ville si permissions refusées
          });
          return;
        }
      }
      
      // Récupérer la position actuelle
      _pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Ajouter un délai pour éviter de bloquer indéfiniment
      );
      
      print("Position obtenue: ${_pos!.latitude}, ${_pos!.longitude}");
      
      setState(() {
        _geoGranted = true;
        _loadingPos = false;
      });
      
      _updateDistances();
      _applyFilters();
    } catch (e) {
      print("Erreur de géolocalisation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de géolocalisation: $e'))
      );
      setState(() {
        _loadingPos = false;
        _villeMode = true; // Passer en mode de saisie de ville en cas d'erreur
      });
    }
  }
  
  // Mettre à jour les distances en fonction de la position actuelle
  void _updateDistances() {
    if (_pos == null) return;
    
    for (var tatoueur in _all) {
      final distance = Geolocator.distanceBetween(
        _pos!.latitude, 
        _pos!.longitude, 
        tatoueur['lat'], 
        tatoueur['lng']
      );
      
      // Formater la distance
      if (distance < 1000) {
        tatoueur['distance'] = '${distance.round()} m';
      } else {
        tatoueur['distance'] = '${(distance / 1000).toStringAsFixed(1)} km';
      }
    }
  }

  // Recherche par nom d'artiste
  Future<void> _searchByName() async {
    _searchC.clear();
    final query = await showDialog<String>(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(ctx).copyWith(
          splashColor: KipikTheme.rouge,
          highlightColor: KipikTheme.rouge,
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: KipikTheme.rouge.withOpacity(0.3),
          ),
        ),
        child: AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rechercher par nom',
              style: TextStyle(color: Colors.white, fontFamily: 'PermanentMarker')),
          content: TextField(
            controller: _searchC,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nom de l\'artiste ou du studio',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: KipikTheme.rouge, width: 2)),
            ),
            cursorColor: KipikTheme.rouge,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white)
                  .copyWith(overlayColor: MaterialStateProperty.all(KipikTheme.rouge)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white)
                  .copyWith(overlayColor: MaterialStateProperty.all(KipikTheme.rouge)),
              onPressed: () => Navigator.pop(ctx, _searchC.text.trim()),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (query != null && query.isNotEmpty) {
      setState(() {
        _filtered = _all
            .where((t) => 
                (t['name'] as String).toLowerCase().contains(query.toLowerCase()) ||
                (t['studio'] as String).toLowerCase().contains(query.toLowerCase())
            )
            .toList();
      });
    }
  }

  // Suggestions de villes pendant la saisie
  Future<void> _getSuggestions(String input) async {
    // Afficher des informations de débogage
    print("Recherche de suggestions pour: $input");
    
    if (input.length < 2) {
      setState(() => _villeSuggestions = []);
      return;
    }
    
    setState(() => _loadingSuggestions = true);
    
    try {
      // Si la clé API n'est pas configurée, utiliser des suggestions mockées pour le développement
      if (_geocodeApiKey == 'VOTRE_CLE_SERVER_GEOCODING') {
        // Simulation des suggestions pour le développement
        await Future.delayed(const Duration(milliseconds: 300)); // Simuler le délai réseau
        
        final mockSuggestions = [
          {'description': 'Paris, France', 'place_id': 'mock_paris'},
          {'description': 'Lyon, France', 'place_id': 'mock_lyon'},
          {'description': 'Marseille, France', 'place_id': 'mock_marseille'},
          {'description': 'Toulouse, France', 'place_id': 'mock_toulouse'},
          {'description': 'Nice, France', 'place_id': 'mock_nice'},
        ].where((city) => 
          city['description'].toString().toLowerCase().contains(input.toLowerCase())
        ).toList();
        
        setState(() {
          _villeSuggestions = mockSuggestions;
          _loadingSuggestions = false;
        });
        
        // Afficher les suggestions pour le débogage
        print("Suggestions mockées: ${_villeSuggestions.length}");
        return;
      }
      
      // Utiliser l'API Places pour obtenir des suggestions réelles
      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
        'input': input,
        'types': '(cities)',
        'language': 'fr',
        'components': 'country:fr',
        'key': _geocodeApiKey,
      });
      
      final response = await http.get(uri);
      final data = json.decode(response.body);
      
      print("Réponse API: ${response.statusCode}");
      print("Statut API: ${data['status']}");
      
      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List;
        print("Nombre de prédictions: ${predictions.length}");
        
        setState(() {
          _villeSuggestions = predictions.map((prediction) {
            return {
              'description': prediction['description'],
              'place_id': prediction['place_id'],
            };
          }).toList();
          _loadingSuggestions = false;
        });
      } else {
        print("Erreur API: ${data['status']}");
        setState(() {
          _villeSuggestions = [];
          _loadingSuggestions = false;
        });
      }
    } catch (e) {
      print("Exception lors de la récupération des suggestions: $e");
      setState(() {
        _villeSuggestions = [];
        _loadingSuggestions = false;
      });
    }
  }
  
  // Sélectionner une ville et obtenir ses coordonnées
  Future<void> _selectVille(Map<String, dynamic> ville) async {
    print("Sélection de ville: ${ville['description']}");
    setState(() => _loadingPos = true);
    
    try {
      // Si c'est une suggestion mockée
      if (ville['place_id'].toString().startsWith('mock_')) {
        // Coordonnées mockées pour le développement
        Map<String, double> mockLocation = {
          'mock_paris': {'lat': 48.8566, 'lng': 2.3522},
          'mock_lyon': {'lat': 45.7640, 'lng': 4.8357},
          'mock_marseille': {'lat': 43.2965, 'lng': 5.3698},
          'mock_toulouse': {'lat': 43.6043, 'lng': 1.4437},
          'mock_nice': {'lat': 43.7102, 'lng': 7.2620},
        }[ville['place_id']] ?? {'lat': 48.8566, 'lng': 2.3522};
        
        _pos = Position(
          latitude: mockLocation['lat']!,
          longitude: mockLocation['lng']!,
          timestamp: DateTime.now(),
          accuracy: 1,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          headingAccuracy: 0,
          altitudeAccuracy: 0,
        );
        
        _villeController.text = ville['description'];
        
        setState(() {
          _geoGranted = true;
          _villeMode = false;
          _villeSuggestions = [];
        });
        
        _updateDistances();
        _applyFilters();
        return;
      }
      
      // Utiliser l'API Places Details pour obtenir les coordonnées
      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
        'place_id': ville['place_id'],
        'fields': 'geometry',
        'key': _geocodeApiKey,
      });
      
      final response = await http.get(uri);
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        
        _pos = Position(
          latitude: location['lat'],
          longitude: location['lng'],
          timestamp: DateTime.now(),
          accuracy: 1,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          headingAccuracy: 0,
          altitudeAccuracy: 0,
        );
        
        _villeController.text = ville['description'];
        
        setState(() {
          _geoGranted = true;
          _villeMode = false;
          _villeSuggestions = [];
        });
        
        _updateDistances();
        _applyFilters();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de localiser cette ville'))
        );
      }
    } catch (e) {
      print("Erreur lors de la sélection de ville: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'))
      );
    }
    
    setState(() => _loadingPos = false);
  }

  // Applique les filtres
  void _applyFilters() {
    if (_pos == null) return;
    final lat0 = _pos!.latitude, lng0 = _pos!.longitude;
    setState(() {
      _filtered = _all.where((t) {
        var ok = true;
        
        // Filtre de distance
        if (_dist != null) {
          final d = Geolocator.distanceBetween(lat0, lng0, t['lat'], t['lng']) / 1000;
          ok &= d <= int.parse(_dist!.replaceAll('km', ''));
        }
        
        // Filtre de disponibilité avec logique cumulative
        if (_avail != null) {
          // Convertir les disponibilités en valeurs numériques pour comparaison
          final dispValues = {
            "Aujourd'hui": 0,
            '3 jours': 3,
            '2 semaines': 14,
            '1 mois': 30,
            'Plus d\'1 mois': 31,
            'Plus de 6 mois': 180
          };
          
          // Obtenir la valeur numérique de la disponibilité du tatoueur
          int tatoueurDispValue;
          switch (t['avail']) {
            case "Aujourd'hui":
              tatoueurDispValue = 0;
              break;
            case '3 jours':
              tatoueurDispValue = 3;
              break;
            case '2 semaines':
              tatoueurDispValue = 14;
              break;
            case '1 mois':
              tatoueurDispValue = 30;
              break;
            case 'Plus d\'1 mois':
              tatoueurDispValue = 31;
              break;
            case 'Plus de 6 mois':
              tatoueurDispValue = 180;
              break;
            default:
              tatoueurDispValue = 999; // Valeur par défaut élevée
          }
          
          // Valeur du filtre sélectionné
          final filterDispValue = dispValues[_avail] ?? 0;
          
          // Le tatoueur est visible si sa disponibilité est inférieure ou égale au filtre
          ok &= tatoueurDispValue <= filterDispValue;
        }
        
        // Filtre de style
        if (_styles.isNotEmpty) ok &= _styles.contains(t['style']);
        
        return ok;
      }).toList();
    });
  }

  // Fiche détaillée du tatoueur
  void _showPreview(Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(t['avatar'] as String),
            ),
            const SizedBox(height: 16),
            Text(t['name'] as String,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'PermanentMarker')),
                    
            const SizedBox(height: 8),
            Text(t['studio'] as String, 
                 style: const TextStyle(color: Colors.white, fontSize: 18)),
                 
            const SizedBox(height: 12),
            
            // Style et note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: KipikTheme.rouge.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    t['style'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${t['note']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Adresse et distance
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    t['adresse'] as String,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            Text('Distance : ${t['distance']}',
                style: const TextStyle(color: Colors.white54)),
                
            const SizedBox(height: 8),
            Text('Disponibilité : ${t['avail']}',
                style: const TextStyle(color: Colors.white54)),
                
            const SizedBox(height: 12),
            Text(t['instagram'] as String,
                style: const TextStyle(color: Colors.blue)),
                
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilTatoueur(
                      name: t['name'] as String,
                      style: t['style'] as String,
                      avatar: t['avatar'] as String,
                      availability: t['avail'] as String,
                      studio: t['studio'] as String,
                      address: t['adresse'] as String,
                      note: t['note'] as double,
                      instagram: t['instagram'] as String,
                      distance: t['distance'] as String,
                      location: t['ville'] as String,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              icon: const Icon(Icons.person, color: Colors.white),
              label: const Text('Voir Profil', style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }

  void _retourAccueil() {
    print("Méthode _retourAccueil appelée");
    // Navigation directe vers la page d'accueil particulier
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AccueilParticulierPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskLoc());
    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: const CustomDrawerParticulier(),
      appBar: const CustomAppBarParticulier(
        title: 'Trouve ton tatoueur',
        showBackButton: true,
        showBurger: true,
        showNotificationIcon: true,
        redirectToHome: true,
      ),
      floatingActionButton: const TattooAssistantButton(
        allowImageGeneration: false,
      ),
      body: Stack(fit: StackFit.expand, children: [
        Image.asset(_bg, fit: BoxFit.cover),
        SafeArea(
          bottom: true,
          child: _loadingPos
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: Colors.redAccent),
                      SizedBox(height: 16),
                      Text(
                        'Localisation en cours...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : (_villeMode
                  ? _buildVilleSelector()
                  : (_geoGranted && _pos != null ? _buildMain() : const SizedBox())),
        ),
      ]),
    );
  }

  Widget _buildVilleSelector() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Entrez votre ville pour trouver les tatoueurs à proximité',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'PermanentMarker',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _villeController,
            onChanged: _getSuggestions,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Entrez votre ville',
              hintStyle: TextStyle(fontFamily: 'Roboto'),
              prefixIcon: Icon(Icons.location_city),
              enabledBorder:
                  OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent, width: 2)),
            ),
            style: const TextStyle(fontFamily: 'Roboto', color: Colors.black87),
            cursorColor: KipikTheme.rouge,
          ),
          
          const SizedBox(height: 4),
          
          if (_loadingSuggestions)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
            
          if (_villeSuggestions.isEmpty && _villeController.text.length >= 2 && !_loadingSuggestions)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text(
                'Aucune ville trouvée',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            
          Expanded(
            child: ListView.builder(
              itemCount: _villeSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _villeSuggestions[index];
                return Card(
                  color: Colors.black.withOpacity(0.7),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      suggestion['description'] as String,
                      style: const TextStyle(color: Colors.white),
                    ),
                    leading: const Icon(Icons.location_on, color: Colors.white70),
                    onTap: () => _selectVille(suggestion),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Bouton pour revenir à la géolocalisation
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _villeMode = false;
                _geoGranted = false;
              });
              _initGeo();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.my_location, color: Colors.white),
            label: const Text('Utiliser ma position actuelle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMain() {
    return Column(children: [
      SizedBox(
        height: 60,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            _drop('Distance', distances, _dist, (v) {
              setState(() => _dist = v);
              _applyFilters();
            }),
            const SizedBox(width: 8),
            _drop('Disponibilité', disponibilites, _avail, (v) {
              setState(() => _avail = v);
              _applyFilters();
            }),
            const SizedBox(width: 8),
            _styleSelector(),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          Expanded(child: _actionCard(label: 'Rechercher', onTap: _searchByName)),
          const SizedBox(width: 8),
          Expanded(
              child: _actionCard(
                  label: '${_filtered.length}\ntrouvé(s)',
                  onTap: () =>
                      setState(() => _view = (_view == 'map' ? 'list' : 'map')))),
        ]),
      ),
      Expanded(
        child: _view == 'map'
            ? GoogleMap(
                initialCameraPosition: CameraPosition(
                    target: LatLng(_pos!.latitude, _pos!.longitude), zoom: 13),
                myLocationEnabled: true,
                markers: _filtered
                    .map((t) => Marker(
                          markerId: MarkerId(t['name'] as String),
                          position: LatLng(t['lat'], t['lng']),
                          infoWindow: InfoWindow(
                            title: t['name'] as String,
                            snippet: t['style'] as String,
                            onTap: () => _showPreview(t),
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          // Nous ne pouvons pas utiliser directement l'avatar comme marqueur
                          // Cela nécessiterait une implémentation personnalisée avec des
                          // BitmapDescriptor générés à partir d'images, ce qui peut être
                          // ajouté dans une future mise à jour
                        ))
                    .toSet(),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final t = _filtered[i];
                  return Card(
                    color: Colors.black.withOpacity(0.7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => _showPreview(t),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Avatar du tatoueur
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: KipikTheme.rouge.withOpacity(0.3),
                              backgroundImage: AssetImage(t['avatar'] as String),
                            ),
                            const SizedBox(width: 16),
                            
                            // Informations du tatoueur
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['name'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontFamily: 'PermanentMarker',
                                    ),
                                  ),
                                  Text(
                                    t['studio'] as String,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.white54, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        t['ville'] as String,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.event_available, color: Colors.white54, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        t['avail'] as String,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: KipikTheme.rouge.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          t['style'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${t['note']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          const Icon(Icons.social_distance, color: Colors.white54, size: 14),
                                          const SizedBox(width: 2),
                                          Text(
                                            t['distance'] as String,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _drop(String hint, List<String> items, String? val,
          ValueChanged<String?> onCh) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: KipikTheme.rouge, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<String>(
          hint: Text(hint,
              style: const TextStyle(
                  fontFamily: 'PermanentMarker', color: Colors.black87)),
          value: val,
          underline: const SizedBox(),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e,
                        style: const TextStyle(
                            fontFamily: 'PermanentMarker', color: Colors.black87)),
                  ))
              .toList(),
          onChanged: onCh,
        ),
      );

  Widget _styleSelector() {
    return InkWell(
      onTap: () async {
        final temp = List<String>.from(_styles);
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.black87,
          shape:
              const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Style',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'PermanentMarker',
                            fontSize: 18)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (ctx2, sbSet) => ListView(
                          children: stylesList.map((s) {
                            return CheckboxListTile(
                              activeColor: KipikTheme.rouge,
                              title: Text(s, style: const TextStyle(color: Colors.white)),
                              value: temp.contains(s),
                              onChanged: (b) {
                                sbSet(() {
                                  if (b == true)
                                    temp.add(s);
                                  else
                                    temp.remove(s);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _styles = temp);
                        _applyFilters();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
                      child: const Text('OK', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: KipikTheme.rouge, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _styles.isEmpty ? 'Style' : '${_styles.length} sélectionné(s)',
          style: const TextStyle(fontFamily: 'PermanentMarker', color: Colors.black87),
        ),
      ),
    );
  }

  Widget _actionCard({required String label, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: KipikTheme.rouge, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87, fontFamily: 'PermanentMarker')),
        ),
      );
}
