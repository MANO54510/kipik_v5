// lib/widgets/forms/city_selector_widget.dart

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class CityData {
  final String name;
  final String postalCode;
  final String department;
  final String region;
  final double? latitude;
  final double? longitude;
  
  CityData({
    required this.name,
    required this.postalCode,
    required this.department,
    required this.region,
    this.latitude,
    this.longitude,
  });
  
  String get displayName => '$name ($postalCode)';
  String get fullAddress => '$name, $postalCode, $department';
  
  @override
  String toString() => displayName;
}

class CitySelectorWidget extends StatefulWidget {
  final String? initialPostalCode;
  final String? initialCity;
  final Function(CityData?) onCitySelected;
  final String labelText;
  final String? errorText;
  final bool isRequired;
  
  const CitySelectorWidget({
    Key? key,
    this.initialPostalCode,
    this.initialCity,
    required this.onCitySelected,
    this.labelText = 'Ville',
    this.errorText,
    this.isRequired = true,
  }) : super(key: key);

  @override
  State<CitySelectorWidget> createState() => _CitySelectorWidgetState();
}

class _CitySelectorWidgetState extends State<CitySelectorWidget> {
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  
  List<CityData> _availableCities = [];
  CityData? _selectedCity;
  bool _isLoadingCities = false;
  String? _postalCodeError;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.initialPostalCode != null) {
      _postalCodeController.text = widget.initialPostalCode!;
      _searchCitiesByPostalCode(widget.initialPostalCode!);
    }
    
    if (widget.initialCity != null) {
      _cityController.text = widget.initialCity!;
    }
  }
  
  @override
  void dispose() {
    _postalCodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ code postal
        TextFormField(
          controller: _postalCodeController,
          decoration: InputDecoration(
            labelText: 'Code postal${widget.isRequired ? ' *' : ''}',
            hintText: 'Ex: 75001',
            prefixIcon: const Icon(Icons.location_on_outlined),
            errorText: _postalCodeError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 5,
          onChanged: _onPostalCodeChanged,
          validator: widget.isRequired ? (value) {
            if (value == null || value.isEmpty) {
              return 'Code postal requis';
            }
            if (value.length != 5) {
              return 'Code postal invalide (5 chiffres)';
            }
            return null;
          } : null,
        ),
        
        const SizedBox(height: 16),
        
        // Champ ville
        if (_availableCities.isNotEmpty) ...[
          Text(
            'Sélectionnez votre ville${widget.isRequired ? ' *' : ''}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          
          // Affichage des villes disponibles
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (_isLoadingCities)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Recherche des villes...'),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableCities.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final city = _availableCities[index];
                      final isSelected = _selectedCity == city;
                      
                      return ListTile(
                        title: Text(
                          city.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text('${city.department} • ${city.region}'),
                        leading: Radio<CityData>(
                          value: city,
                          groupValue: _selectedCity,
                          onChanged: _selectCity,
                        ),
                        trailing: isSelected 
                          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                          : null,
                        onTap: () => _selectCity(city),
                        selected: isSelected,
                        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      );
                    },
                  ),
              ],
            ),
          ),
        ] else if (_postalCodeController.text.length == 5 && !_isLoadingCities) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucune ville trouvée pour ce code postal',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Ville sélectionnée
        if (_selectedCity != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.location_city, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ville sélectionnée',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _selectedCity!.fullAddress,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _selectCity(null),
                  tooltip: 'Effacer la sélection',
                ),
              ],
            ),
          ),
        ],
        
        // Erreur de validation
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
  
  void _onPostalCodeChanged(String value) {
    setState(() {
      _postalCodeError = null;
      _selectedCity = null;
      _availableCities.clear();
    });
    
    // Informer le parent que la sélection a été effacée
    widget.onCitySelected(null);
    
    if (value.length == 5) {
      _searchCitiesByPostalCode(value);
    }
  }
  
  Future<void> _searchCitiesByPostalCode(String postalCode) async {
    if (postalCode.length != 5) return;
    
    setState(() {
      _isLoadingCities = true;
      _postalCodeError = null;
    });
    
    try {
      // Méthode 1: Utiliser l'API française officielle (gratuite)
      final cities = await _fetchCitiesFromFrenchAPI(postalCode);
      
      if (cities.isNotEmpty) {
        setState(() {
          _availableCities = cities;
          _isLoadingCities = false;
        });
      } else {
        // Méthode 2: Fallback avec geocoding
        await _fallbackGeocodingSearch(postalCode);
      }
      
    } catch (e) {
      print('Erreur recherche villes: $e');
      setState(() {
        _isLoadingCities = false;
        _postalCodeError = 'Erreur lors de la recherche des villes';
      });
    }
  }
  
  Future<List<CityData>> _fetchCitiesFromFrenchAPI(String postalCode) async {
    try {
      // API française officielle (gratuite et complète)
      final uri = Uri.parse('https://geo.api.gouv.fr/communes?codePostal=$postalCode&fields=nom,codesPostaux,codeDepartement,departement,region&format=json');
      
      // Note: Vous devrez ajouter http package dans pubspec.yaml
      // final response = await http.get(uri);
      
      // Pour l'exemple, simulation de données
      // En réalité, parsez response.body ici
      
      // Simulation de réponse API
      return _simulateFrenchAPIResponse(postalCode);
      
    } catch (e) {
      print('Erreur API française: $e');
      return [];
    }
  }
  
  List<CityData> _simulateFrenchAPIResponse(String postalCode) {
    // Simulation de données réelles
    final Map<String, List<Map<String, String>>> mockData = {
      '75001': [
        {'name': 'Paris 1er Arrondissement', 'department': 'Paris', 'region': 'Île-de-France'},
      ],
      '13001': [
        {'name': 'Marseille 1er Arrondissement', 'department': 'Bouches-du-Rhône', 'region': 'Provence-Alpes-Côte d\'Azur'},
      ],
      '69001': [
        {'name': 'Lyon 1er Arrondissement', 'department': 'Rhône', 'region': 'Auvergne-Rhône-Alpes'},
      ],
      '33000': [
        {'name': 'Bordeaux', 'department': 'Gironde', 'region': 'Nouvelle-Aquitaine'},
      ],
      '06000': [
        {'name': 'Nice', 'department': 'Alpes-Maritimes', 'region': 'Provence-Alpes-Côte d\'Azur'},
      ],
      // Exemple avec plusieurs villes pour le même code postal
      '01000': [
        {'name': 'Bourg-en-Bresse', 'department': 'Ain', 'region': 'Auvergne-Rhône-Alpes'},
        {'name': 'Saint-Denis-lès-Bourg', 'department': 'Ain', 'region': 'Auvergne-Rhône-Alpes'},
      ],
    };
    
    final cities = mockData[postalCode];
    if (cities == null) return [];
    
    return cities.map((city) => CityData(
      name: city['name']!,
      postalCode: postalCode,
      department: city['department']!,
      region: city['region']!,
    )).toList();
  }
  
  Future<void> _fallbackGeocodingSearch(String postalCode) async {
    try {
      // Fallback avec package geocoding
      final locations = await locationFromAddress('$postalCode, France');
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final placemarks = await placemarkFromCoordinates(
          location.latitude, 
          location.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final city = CityData(
            name: placemark.locality ?? 'Ville inconnue',
            postalCode: postalCode,
            department: placemark.administrativeArea ?? '',
            region: placemark.country ?? 'France',
            latitude: location.latitude,
            longitude: location.longitude,
          );
          
          setState(() {
            _availableCities = [city];
            _isLoadingCities = false;
          });
        }
      } else {
        setState(() {
          _isLoadingCities = false;
          _postalCodeError = 'Code postal introuvable';
        });
      }
      
    } catch (e) {
      print('Erreur geocoding: $e');
      setState(() {
        _isLoadingCities = false;
        _postalCodeError = 'Erreur lors de la recherche';
      });
    }
  }
  
  void _selectCity(CityData? city) {
    setState(() {
      _selectedCity = city;
      if (city != null) {
        _cityController.text = city.name;
      }
    });
    
    // Informer le parent de la sélection
    widget.onCitySelected(city);
  }
}

// Widget d'utilisation dans votre formulaire d'inscription
class SignupFormWithCitySelector extends StatefulWidget {
  @override
  State<SignupFormWithCitySelector> createState() => _SignupFormWithCitySelectorState();
}

class _SignupFormWithCitySelectorState extends State<SignupFormWithCitySelector> {
  final _formKey = GlobalKey<FormState>();
  CityData? _selectedCity;
  String? _cityError;
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Vos autres champs du formulaire...
          
          // Sélecteur de ville
          CitySelectorWidget(
            onCitySelected: (city) {
              setState(() {
                _selectedCity = city;
                _cityError = null; // Effacer l'erreur quand une ville est sélectionnée
              });
            },
            errorText: _cityError,
          ),
          
          const SizedBox(height: 24),
          
          // Bouton de validation
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('S\'inscrire'),
          ),
        ],
      ),
    );
  }
  
  void _submitForm() {
    // Validation de la ville
    if (_selectedCity == null) {
      setState(() {
        _cityError = 'Veuillez sélectionner une ville';
      });
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      // Procéder à l'inscription
      print('Inscription avec ville: ${_selectedCity!.fullAddress}');
      
      // Ici vous pouvez envoyer les données à votre backend
      _performSignup();
    }
  }
  
  Future<void> _performSignup() async {
    try {
      // Votre logique d'inscription
      print('Données à envoyer:');
      print('- Ville: ${_selectedCity!.name}');
      print('- Code postal: ${_selectedCity!.postalCode}');
      print('- Département: ${_selectedCity!.department}');
      print('- Région: ${_selectedCity!.region}');
      
    } catch (e) {
      print('Erreur inscription: $e');
      // Afficher l'erreur à l'utilisateur
    }
  }
}