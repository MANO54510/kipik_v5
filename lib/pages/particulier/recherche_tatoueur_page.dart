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
import '../../core/database_manager.dart'; // ✅ AJOUTÉ pour mode démo
import '../../models/tatoueur_summary.dart'; // ✅ AJOUTÉ pour utiliser le modèle
import '../../models/user_role.dart'; // ✅ AJOUTÉ : Import manquant pour UserRole
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
  
  // ✅ MIGRATION : Utilisation des modèles TatoueurSummary
  List<TatoueurSummary> _all = [], _filtered = [];
  
  // fond aléatoire
  late final String _bg;
  
  // ✅ SÉCURISÉ : Clé API Google Maps (remplacez par votre vraie clé)
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

  @override
  void dispose() {
    _villeController.dispose();
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadTatoueurs() async {
    try {
      // ✅ MIGRATION : Utilisation des données selon le mode
      if (DatabaseManager.instance.isDemoMode) {
        // Données de démonstration avec le modèle TatoueurSummary
        _all = TatoueurSummaryDemo.generateDemoList(count: 12);
      } else {
        // En production, charger depuis la base de données
        // TODO: Implémenter le service de récupération des tatoueurs
        _all = TatoueurSummaryDemo.generateDemoList(count: 8);
      }
      
      _filtered = List.from(_all);
      setState(() {});
    } catch (e) {
      print("Erreur lors du chargement des tatoueurs: $e");
      // Fallback vers les données de démo
      _all = TatoueurSummaryDemo.generateDemoList(count: 8);
      _filtered = List.from(_all);
      setState(() {});
    }
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
                .copyWith(overlayColor: WidgetStateProperty.all(KipikTheme.rouge)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white)
                .copyWith(overlayColor: WidgetStateProperty.all(KipikTheme.rouge)),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Services de localisation désactivés. Veuillez les activer.'),
              backgroundColor: Colors.red,
            )
          );
        }
        setState(() {
          _loadingPos = false;
          _villeMode = true;
        });
        return;
      }
      
      // Vérifier les permissions
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
        
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permissions de localisation refusées'),
                backgroundColor: Colors.red,
              )
            );
          }
          setState(() {
            _loadingPos = false;
            _villeMode = true;
          });
          return;
        }
      }
      
      // Récupérer la position actuelle
      _pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de géolocalisation: $e'),
            backgroundColor: Colors.orange,
          )
        );
      }
      setState(() {
        _loadingPos = false;
        _villeMode = true;
      });
    }
  }
  
  // ✅ CORRIGÉ : Mettre à jour les distances avec le modèle TatoueurSummary
  void _updateDistances() {
    if (_pos == null) return;
    
    for (var tatoueur in _all) {
      final distance = Geolocator.distanceBetween(
        _pos!.latitude, 
        _pos!.longitude, 
        tatoueur.latitude, 
        tatoueur.longitude
      );
      
      // ✅ Mise à jour de la distance dans le modèle
      final index = _all.indexOf(tatoueur);
      _all[index] = tatoueur.copyWith(distanceKm: distance / 1000);
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
                  .copyWith(overlayColor: WidgetStateProperty.all(KipikTheme.rouge)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white)
                  .copyWith(overlayColor: WidgetStateProperty.all(KipikTheme.rouge)),
              onPressed: () => Navigator.pop(ctx, _searchC.text.trim()),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    
    if (query != null && query.isNotEmpty) {
      setState(() {
        _filtered = _all.where((t) => t.matchesSearch(query)).toList();
      });
    }
  }

  // ✅ OPTIMISÉ : Suggestions de villes avec gestion d'erreur améliorée
  Future<void> _getSuggestions(String input) async {
    print("Recherche de suggestions pour: $input");
    
    if (input.length < 2) {
      setState(() => _villeSuggestions = []);
      return;
    }
    
    setState(() => _loadingSuggestions = true);
    
    try {
      // Mode développement avec suggestions mockées
      if (_geocodeApiKey == 'AIzaSyAXHDIXeZZXVPnABpT3O8GmBzUNeyFoSp8' || 
          DatabaseManager.instance.isDemoMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        
        final mockSuggestions = [
          {'description': 'Nancy, France', 'place_id': 'mock_nancy'},
          {'description': 'Paris, France', 'place_id': 'mock_paris'},
          {'description': 'Lyon, France', 'place_id': 'mock_lyon'},
          {'description': 'Marseille, France', 'place_id': 'mock_marseille'},
          {'description': 'Toulouse, France', 'place_id': 'mock_toulouse'},
          {'description': 'Nice, France', 'place_id': 'mock_nice'},
          {'description': 'Strasbourg, France', 'place_id': 'mock_strasbourg'},
          {'description': 'Metz, France', 'place_id': 'mock_metz'},
        ].where((city) => 
          city['description'].toString().toLowerCase().contains(input.toLowerCase())
        ).toList();
        
        setState(() {
          _villeSuggestions = mockSuggestions;
          _loadingSuggestions = false;
        });
        return;
      }
      
      // API Google Places pour production
      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
        'input': input,
        'types': '(cities)',
        'language': 'fr',
        'components': 'country:fr',
        'key': _geocodeApiKey,
      });
      
      final response = await http.get(uri);
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List;
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
  
  // ✅ OPTIMISÉ : Sélection de ville avec coordonnées mockées améliorées
  Future<void> _selectVille(Map<String, dynamic> ville) async {
    print("Sélection de ville: ${ville['description']}");
    setState(() => _loadingPos = true);
    
    try {
      // Coordonnées mockées pour le développement
      if (ville['place_id'].toString().startsWith('mock_')) {
        final mockLocations = {
          'mock_nancy': {'lat': 48.6921, 'lng': 6.1844},
          'mock_paris': {'lat': 48.8566, 'lng': 2.3522},
          'mock_lyon': {'lat': 45.7640, 'lng': 4.8357},
          'mock_marseille': {'lat': 43.2965, 'lng': 5.3698},
          'mock_toulouse': {'lat': 43.6043, 'lng': 1.4437},
          'mock_nice': {'lat': 43.7102, 'lng': 7.2620},
          'mock_strasbourg': {'lat': 48.5734, 'lng': 7.7521},
          'mock_metz': {'lat': 49.1193, 'lng': 6.1757},
        };
        
        final mockLocation = mockLocations[ville['place_id']] ?? 
                            {'lat': 48.6921, 'lng': 6.1844}; // Nancy par défaut
        
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
          _loadingPos = false;
        });
        
        _updateDistances();
        _applyFilters();
        return;
      }
      
      // API Google Places Details pour production
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
          _loadingPos = false;
        });
        
        _updateDistances();
        _applyFilters();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de localiser cette ville'),
              backgroundColor: Colors.orange,
            )
          );
        }
      }
    } catch (e) {
      print("Erreur lors de la sélection de ville: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
    
    setState(() => _loadingPos = false);
  }

  // ✅ MIGRATION : Filtres utilisant le modèle TatoueurSummary
  void _applyFilters() {
    if (_pos == null) return;
    
    setState(() {
      _filtered = _all.where((tatoueur) {
        var ok = true;
        
        // Filtre de distance
        if (_dist != null) {
          final maxDistanceKm = double.parse(_dist!.replaceAll('km', ''));
          ok &= (tatoueur.distanceKm ?? 0.0) <= maxDistanceKm;
        }
        
        // Filtre de disponibilité
        if (_avail != null) {
          ok &= _matchesAvailability(tatoueur.availability, _avail!);
        }
        
        // Filtre de style
        if (_styles.isNotEmpty) {
          ok &= tatoueur.hasAnySpecialty(_styles);
        }
        
        return ok;
      }).toList();
      
      // Trier par distance
      _filtered.sort((a, b) => (a.distanceKm ?? 0.0).compareTo(b.distanceKm ?? 0.0));
    });
  }

  // ✅ AJOUTÉ : Méthode pour vérifier la disponibilité
  bool _matchesAvailability(String tatoueurAvail, String filterAvail) {
    final dispValues = {
      "Aujourd'hui": 0,
      '3 jours': 3,
      '2 semaines': 14,
      '1 mois': 30,
      'Plus d\'1 mois': 31,
      'Plus de 6 mois': 180
    };
    
    final tatoueurValue = dispValues[tatoueurAvail] ?? 999;
    final filterValue = dispValues[filterAvail] ?? 0;
    
    return tatoueurValue <= filterValue;
  }

  // ✅ MIGRATION : Fiche détaillée utilisant TatoueurSummary
  void _showPreview(TatoueurSummary tatoueur) {
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
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: KipikTheme.rouge.withOpacity(0.3),
              backgroundImage: tatoueur.avatarUrl.isNotEmpty 
                  ? NetworkImage(tatoueur.avatarUrl)
                  : null,
              child: tatoueur.avatarUrl.isEmpty 
                  ? Text(
                      tatoueur.name.isNotEmpty ? tatoueur.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Nom
            Text(
              tatoueur.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'PermanentMarker'),
            ),
            const SizedBox(height: 8),
            
            // Studio
            Text(
              tatoueur.studioName ?? 'Studio indépendant',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
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
                    tatoueur.specialtiesText,
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
                      tatoueur.ratingText,
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
            
            // Localisation et distance
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    tatoueur.location,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            Text(
              'Distance : ${tatoueur.distanceText}',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 8),
            Text(
              'Disponibilité : ${tatoueur.availability}',
              style: const TextStyle(color: Colors.white54),
            ),
            
            // ✅ Indicateur mode démo
            if (DatabaseManager.instance.isDemoMode) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🎭 Profil de démonstration',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilTatoueur(
                      tatoueurId: tatoueur.id,
                      forceMode: UserRole.client, // ✅ CORRIGÉ : forceMode au lieu de userRole
                      name: tatoueur.name,
                      studio: tatoueur.studioName ?? 'Studio indépendant',
                      style: tatoueur.specialtiesText,
                      location: tatoueur.location,
                      availability: tatoueur.availability,
                      note: tatoueur.rating ?? 4.5,
                      instagram: tatoueur.instagram ?? '@tatoueur',
                      distance: tatoueur.distanceText,
                      address: 'Adresse du studio', // Vous pouvez ajouter cette propriété au modèle
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
      appBar: CustomAppBarParticulier(
        title: DatabaseManager.instance.isDemoMode 
            ? 'Trouve ton tatoueur 🎭'
            : 'Trouve ton tatoueur',
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
              ? _buildLoadingState()
              : (_villeMode
                  ? _buildVilleSelector()
                  : (_geoGranted && _pos != null ? _buildMain() : const SizedBox())),
        ),
      ]),
    );
  }

  // ✅ AJOUTÉ : État de chargement amélioré
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: DatabaseManager.instance.isDemoMode 
                ? Colors.orange 
                : Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            DatabaseManager.instance.isDemoMode
                ? 'Chargement des tatoueurs de démonstration...'
                : 'Localisation en cours...',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (DatabaseManager.instance.isDemoMode) ...[
            const SizedBox(height: 8),
            const Text(
              '🎭 Mode démonstration',
              style: TextStyle(color: Colors.orange, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVilleSelector() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DatabaseManager.instance.isDemoMode
                ? '🎭 Mode démo - Entrez une ville pour simuler la recherche'
                : 'Entrez votre ville pour trouver les tatoueurs à proximité',
            style: const TextStyle(
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
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Entrez votre ville',
              hintStyle: const TextStyle(fontFamily: 'Roboto'),
              prefixIcon: const Icon(Icons.location_city),
              suffixIcon: DatabaseManager.instance.isDemoMode 
                  ? const Icon(Icons.science, color: Colors.orange)
                  : null,
              enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent)),
              focusedBorder: const OutlineInputBorder(
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
                    leading: Icon(
                      Icons.location_on, 
                      color: DatabaseManager.instance.isDemoMode 
                          ? Colors.orange 
                          : Colors.white70,
                    ),
                    trailing: DatabaseManager.instance.isDemoMode 
                        ? const Icon(Icons.science, color: Colors.orange, size: 16)
                        : null,
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
            label: const Text(
              'Utiliser ma position actuelle', 
              style: TextStyle(color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMain() {
    return Column(children: [
      // ✅ Indicateur mode démo dans les filtres
      if (DatabaseManager.instance.isDemoMode) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.orange.withOpacity(0.1),
          child: const Text(
            '🎭 Mode démonstration - Données fictives',
            style: TextStyle(color: Colors.orange, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
      
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
            ? _buildMapView()
            : _buildListView(),
      ),
    ]);
  }

  // ✅ MIGRATION : Vue carte utilisant TatoueurSummary
  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
          target: LatLng(_pos!.latitude, _pos!.longitude), zoom: 13),
      myLocationEnabled: true,
      markers: _filtered
          .map((tatoueur) => Marker(
                markerId: MarkerId(tatoueur.id),
                position: LatLng(tatoueur.latitude, tatoueur.longitude),
                infoWindow: InfoWindow(
                  title: tatoueur.name,
                  snippet: tatoueur.specialtiesText,
                  onTap: () => _showPreview(tatoueur),
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  DatabaseManager.instance.isDemoMode 
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueRed
                ),
              ))
          .toSet(),
    );
  }

  // ✅ MIGRATION : Vue liste utilisant TatoueurSummary
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final tatoueur = _filtered[i];
        return Card(
          color: Colors.black.withOpacity(0.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _showPreview(tatoueur),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Avatar du tatoueur
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: DatabaseManager.instance.isDemoMode 
                        ? Colors.orange.withOpacity(0.3)
                        : KipikTheme.rouge.withOpacity(0.3),
                    backgroundImage: tatoueur.avatarUrl.isNotEmpty 
                        ? NetworkImage(tatoueur.avatarUrl)
                        : null,
                    child: tatoueur.avatarUrl.isEmpty 
                        ? Text(
                            tatoueur.name.isNotEmpty ? tatoueur.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Informations du tatoueur
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tatoueur.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontFamily: 'PermanentMarker',
                                ),
                              ),
                            ),
                            if (DatabaseManager.instance.isDemoMode) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'DÉMO',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          tatoueur.studioName ?? 'Studio indépendant',
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
                              tatoueur.location,
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
                              tatoueur.availability,
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
                                color: DatabaseManager.instance.isDemoMode 
                                    ? Colors.orange.withOpacity(0.7)
                                    : KipikTheme.rouge.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tatoueur.specialtiesText,
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
                              tatoueur.ratingText,
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
                                  tatoueur.distanceText,
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
    );
  }

  Widget _drop(String hint, List<String> items, String? val,
          ValueChanged<String?> onCh) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: DatabaseManager.instance.isDemoMode 
                ? Colors.orange 
                : KipikTheme.rouge, 
            width: 2
          ),
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
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                    Row(
                      children: [
                        const Text('Style',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'PermanentMarker',
                                fontSize: 18)),
                        const Spacer(),
                        if (DatabaseManager.instance.isDemoMode) ...[
                          const Icon(Icons.science, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'DÉMO',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (ctx2, sbSet) => ListView(
                          children: stylesList.map((s) {
                            return CheckboxListTile(
                              activeColor: DatabaseManager.instance.isDemoMode 
                                  ? Colors.orange 
                                  : KipikTheme.rouge,
                              title: Text(s, style: const TextStyle(color: Colors.white)),
                              value: temp.contains(s),
                              onChanged: (b) {
                                sbSet(() {
                                  if (b == true) {
                                    temp.add(s);
                                  } else {
                                    temp.remove(s);
                                  }
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DatabaseManager.instance.isDemoMode 
                            ? Colors.orange 
                            : KipikTheme.rouge,
                      ),
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
          border: Border.all(
            color: DatabaseManager.instance.isDemoMode 
                ? Colors.orange 
                : KipikTheme.rouge, 
            width: 2
          ),
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
            border: Border.all(
              color: DatabaseManager.instance.isDemoMode 
                  ? Colors.orange 
                  : KipikTheme.rouge, 
              width: 2
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87, fontFamily: 'PermanentMarker')),
        ),
      );
}