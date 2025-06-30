// lib/pages/organisateur/event_edit_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/models/convention.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Ajouté pour générer des IDs

class EventEditPage extends StatefulWidget {
  final dynamic convention; // Accepte n'importe quel type d'argument
  
  const EventEditPage({Key? key, this.convention}) : super(key: key);

  @override
  _EventEditPageState createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  
  DateTime _startDate = DateTime.now().add(Duration(days: 30));
  DateTime _endDate = DateTime.now().add(Duration(days: 32));
  
  bool _isPremium = false;
  bool _isRegistrationOpen = true;
  
  int _proSpots = 50;
  int _merchandiseSpots = 10;
  
  double _dayTicketPrice = 15.0;
  double _weekendTicketPrice = 25.0;
  
  List<String> _artists = [];
  List<String> _events = [];
  
  bool _isLoading = false;
  bool _isNew = true;
  Convention? _conventionData;
  
  @override
  void initState() {
    super.initState();
    
    // Vérifier si nous avons reçu une convention valide
    if (widget.convention is Convention) {
      _conventionData = widget.convention as Convention;
      _isNew = false;
      _loadConventionData();
    } else {
      _isNew = true;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }
  
  void _loadConventionData() {
    if (_conventionData == null) return;
    
    final convention = _conventionData!;
    
    _titleController.text = convention.title;
    _locationController.text = convention.location;
    _descriptionController.text = convention.description;
    _websiteController.text = convention.website ?? '';
    
    _startDate = convention.start;
    _endDate = convention.end;
    
    _isPremium = convention.isPremium;
    _isRegistrationOpen = convention.isOpen;
    
    // Champs supplémentaires
    _proSpots = convention.proSpots ?? 50;
    _merchandiseSpots = convention.merchandiseSpots ?? 10;
    _dayTicketPrice = convention.dayTicketPrice ?? 15.0;
    _weekendTicketPrice = convention.weekendTicketPrice ?? 25.0;
    
    _artists = convention.artists ?? [];
    _events = convention.events ?? [];
  }
  
  Future<void> _saveConvention() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Générer un ID aléatoire pour les nouvelles conventions
      final id = _isNew ? Uuid().v4() : (_conventionData?.id ?? Uuid().v4());
      
      final updatedConvention = Convention(
        id: id,
        title: _titleController.text,
        location: _locationController.text,
        description: _descriptionController.text,
        website: _websiteController.text.isEmpty ? null : _websiteController.text,
        start: _startDate,
        end: _endDate,
        isPremium: _isPremium,
        isOpen: _isRegistrationOpen,
        imageUrl: _conventionData?.imageUrl ?? 'assets/background_charbon.png',
        artists: _artists,
        // Champs supplémentaires
        proSpots: _proSpots,
        merchandiseSpots: _merchandiseSpots,
        dayTicketPrice: _dayTicketPrice,
        weekendTicketPrice: _weekendTicketPrice,
        events: _events,
      );
      
      // TODO: Implémenter l'enregistrement réel
      // if (_isNew) {
      //   await conventionService.createConvention(updatedConvention);
      // } else {
      //   await conventionService.updateConvention(updatedConvention);
      // }
      
      // Simuler un délai d'enregistrement
      await Future.delayed(Duration(seconds: 1));
      
      setState(() {
        _isLoading = false;
      });
      
      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isNew ? 'Convention créée avec succès!' : 'Convention mise à jour avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Retourner à la liste des conventions
      Navigator.pop(context);
    } catch (e) {
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
  
  // Le reste de votre code reste inchangé
  // ...
  
  Future<void> _selectDate(bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final minDate = isStartDate 
        ? DateTime.now() 
        : _startDate.add(Duration(hours: 1));
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate.isBefore(DateTime.now()) ? DateTime.now() : minDate,
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: KipikTheme.rouge,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[800],
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      // Ouvrir le sélectionneur d'heure
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: KipikTheme.rouge,
                onPrimary: Colors.white,
                surface: Colors.grey[900]!,
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: Colors.grey[800],
            ),
            child: child!,
          );
        },
      );
      
      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            time.hour,
            time.minute,
          );
          
          if (isStartDate) {
            _startDate = newDateTime;
            // Mettre à jour la date de fin si nécessaire
            if (_endDate.isBefore(_startDate)) {
              _endDate = _startDate.add(Duration(days: 1));
            }
          } else {
            _endDate = newDateTime;
          }
        });
      }
    }
  }
  
  Future<void> _addArtist() async {
    final artistController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un artiste'),
        content: TextField(
          controller: artistController,
          decoration: InputDecoration(
            labelText: 'Nom de l\'artiste',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (artistController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
            ),
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
    
    if (added == true && artistController.text.isNotEmpty) {
      setState(() {
        _artists.add(artistController.text);
      });
    }
  }
  
  Future<void> _addEvent() async {
    final eventController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un événement'),
        content: TextField(
          controller: eventController,
          decoration: InputDecoration(
            labelText: 'Nom de l\'événement',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (eventController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
            ),
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
    
    if (added == true && eventController.text.isNotEmpty) {
      setState(() {
        _events.add(eventController.text);
      });
    }
  }
  
  void _removeArtist(int index) {
    setState(() {
      _artists.removeAt(index);
    });
  }
  
  void _removeEvent(int index) {
    setState(() {
      _events.removeAt(index);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final pageTitle = _isNew ? 'Créer une convention' : 'Modifier la convention';
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBarKipik(
        title: pageTitle,
        showBackButton: true,
        showBurger: true,
        showNotificationIcon: false,
      ),
      drawer: DrawerFactory.of(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arrière-plan
          Image.asset(
            'assets/background_charbon.png',
            fit: BoxFit.cover,
          ),
          
          // Contenu principal
          SafeArea(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: KipikTheme.rouge))
                : SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Informations de base
                          _buildSectionTitle('Informations de base'),
                          Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _titleController,
                                    decoration: InputDecoration(
                                      labelText: 'Titre de la convention',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      labelStyle: TextStyle(color: Colors.grey[300]),
                                    ),
                                    style: TextStyle(color: Colors.white),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer un titre';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  TextFormField(
                                    controller: _locationController,
                                    decoration: InputDecoration(
                                      labelText: 'Lieu',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      labelStyle: TextStyle(color: Colors.grey[300]),
                                    ),
                                    style: TextStyle(color: Colors.white),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer un lieu';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: InputDecoration(
                                      labelText: 'Description',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      labelStyle: TextStyle(color: Colors.grey[300]),
                                      alignLabelWithHint: true,
                                    ),
                                    style: TextStyle(color: Colors.white),
                                    maxLines: 5,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer une description';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  TextFormField(
                                    controller: _websiteController,
                                    decoration: InputDecoration(
                                      labelText: 'Site web (optionnel)',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      labelStyle: TextStyle(color: Colors.grey[300]),
                                    ),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Dates
                          _buildSectionTitle('Dates de l\'événement'),
                          Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      'Date de début',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(_startDate),
                                      style: TextStyle(color: Colors.grey[300]),
                                    ),
                                    trailing: Icon(Icons.calendar_today, color: KipikTheme.rouge),
                                    onTap: () => _selectDate(true),
                                  ),
                                  Divider(color: Colors.grey[700]),
                                  ListTile(
                                    title: Text(
                                      'Date de fin',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(_endDate),
                                      style: TextStyle(color: Colors.grey[300]),
                                    ),
                                    trailing: Icon(Icons.calendar_today, color: KipikTheme.rouge),
                                    onTap: () => _selectDate(false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Le reste du contenu reste inchangé
                          // ...
                          
                          // Emplacements et billets
                          _buildSectionTitle('Emplacements et billets'),
                          Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: _proSpots.toString(),
                                          decoration: InputDecoration(
                                            labelText: 'Emplacements tattooers',
                                            border: OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.grey[800],
                                            labelStyle: TextStyle(color: Colors.grey[300]),
                                          ),
                                          style: TextStyle(color: Colors.white),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            setState(() {
                                              _proSpots = int.tryParse(value) ?? 50;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: _merchandiseSpots.toString(),
                                          decoration: InputDecoration(
                                            labelText: 'Emplacements boutiques',
                                            border: OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.grey[800],
                                            labelStyle: TextStyle(color: Colors.grey[300]),
                                          ),
                                          style: TextStyle(color: Colors.white),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            setState(() {
                                              _merchandiseSpots = int.tryParse(value) ?? 10;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: _dayTicketPrice.toString(),
                                          decoration: InputDecoration(
                                            labelText: 'Prix ticket jour (€)',
                                            border: OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.grey[800],
                                            labelStyle: TextStyle(color: Colors.grey[300]),
                                          ),
                                          style: TextStyle(color: Colors.white),
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          onChanged: (value) {
                                            setState(() {
                                              _dayTicketPrice = double.tryParse(value) ?? 15.0;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: _weekendTicketPrice.toString(),
                                          decoration: InputDecoration(
                                            labelText: 'Prix ticket week-end (€)',
                                            border: OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.grey[800],
                                            labelStyle: TextStyle(color: Colors.grey[300]),
                                          ),
                                          style: TextStyle(color: Colors.white),
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          onChanged: (value) {
                                            setState(() {
                                              _weekendTicketPrice = double.tryParse(value) ?? 25.0;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Artistes et événements
                          _buildSectionTitle('Artistes et spectacles'),
                          Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Artistes invités',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle, color: KipikTheme.rouge),
                                        onPressed: _addArtist,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  _artists.isEmpty
                                      ? Center(
                                          child: Text(
                                            'Aucun artiste ajouté',
                                            style: TextStyle(color: Colors.grey[400]),
                                          ),
                                        )
                                      : Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: List.generate(
                                            _artists.length,
                                            (index) => Chip(
                                              label: Text(_artists[index]),
                                              deleteIcon: Icon(Icons.cancel, size: 18),
                                              onDeleted: () => _removeArtist(index),
                                              backgroundColor: Colors.grey[800],
                                              deleteIconColor: Colors.red,
                                              labelStyle: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                  Divider(color: Colors.grey[700], height: 32),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Événements / Spectacles',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle, color: KipikTheme.rouge),
                                        onPressed: _addEvent,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  _events.isEmpty
                                      ? Center(
                                          child: Text(
                                            'Aucun événement ajouté',
                                            style: TextStyle(color: Colors.grey[400]),
                                          ),
                                        )
                                      : Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: List.generate(
                                            _events.length,
                                            (index) => Chip(
                                              label: Text(_events[index]),
                                              deleteIcon: Icon(Icons.cancel, size: 18),
                                              onDeleted: () => _removeEvent(index),
                                              backgroundColor: Colors.grey[800],
                                              deleteIconColor: Colors.red,
                                              labelStyle: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Options
                          _buildSectionTitle('Options'),
                          Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    title: Text(
                                      'Convention Premium',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'Mise en avant dans les résultats de recherche',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                    value: _isPremium,
                                    onChanged: (value) {
                                      setState(() {
                                        _isPremium = value;
                                      });
                                    },
                                    activeColor: KipikTheme.rouge,
                                  ),
                                  Divider(color: Colors.grey[700]),
                                  SwitchListTile(
                                    title: Text(
                                      'Inscriptions ouvertes',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'Les tatoueurs peuvent postuler pour participer',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                    value: _isRegistrationOpen,
                                    onChanged: (value) {
                                      setState(() {
                                        _isRegistrationOpen = value;
                                      });
                                    },
                                    activeColor: KipikTheme.rouge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Bouton de sauvegarde
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: ElevatedButton(
                              onPressed: _saveConvention,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KipikTheme.rouge,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(double.infinity, 48),
                              ),
                              child: Text(
                                _isNew ? 'Créer la convention' : 'Enregistrer les modifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4, top: 24, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: KipikTheme.rouge,
          fontFamily: 'PermanentMarker',
        ),
      ),
    );
  }
}