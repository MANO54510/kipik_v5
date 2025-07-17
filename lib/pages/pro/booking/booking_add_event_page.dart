// lib/pages/pro/booking/booking_add_event_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../widgets/common/buttons/tattoo_assistant_button.dart';
import 'dart:math';

enum EventType { tattoo, consultation, retouche, devis, deplacement, personnel, convention, formation, guest }
enum LocationType { studio, domicile, guest, convention, autre }
enum GuestType { outgoing, incoming } // Sortant (je vais chez qqn) ou Entrant (qqn vient chez moi)
enum DurationUnit { minutes, hours }

class BookingAddEventPage extends StatefulWidget {
  final DateTime? preselectedDate;
  final TimeOfDay? preselectedTime;
  
  const BookingAddEventPage({
    Key? key,
    this.preselectedDate,
    this.preselectedTime,
  }) : super(key: key);

  @override
  State<BookingAddEventPage> createState() => _BookingAddEventPageState();
}

class _BookingAddEventPageState extends State<BookingAddEventPage> 
    with TickerProviderStateMixin {
  
  final _formKey = GlobalKey<FormState>();
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Contrôleurs de formulaire
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _locationDetailsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // État du formulaire
  EventType _selectedEventType = EventType.tattoo;
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  int _durationValue = 2;
  DurationUnit _durationUnit = DurationUnit.hours;
  LocationType _locationType = LocationType.studio;
  double? _price;
  double? _deposit;
  bool _requiresDeposit = false;
  bool _sendConfirmationEmail = true;
  bool _addToCalendar = true;
  bool _isRecurring = false;
  String _recurringPattern = 'weekly';
  int _recurringCount = 1;
  
  // État de la page
  bool _isLoading = false;
  bool _showAdvancedOptions = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  
  // Variables Guest System
  bool _isGuestEvent = false;
  GuestType _guestType = GuestType.outgoing;
  String? _selectedGuestContract;
  String? _hostShopName;
  String? _hostShopAddress;
  double _guestCommissionRate = 20.0;
  bool _accommodationIncluded = false;
  bool _hasActiveFees = false;
  Map<String, dynamic>? _guestDetails;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _titleController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _locationDetailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    _scaleController.forward();
  }

  void _initializeForm() {
    _selectedDate = widget.preselectedDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedStartTime = widget.preselectedTime ?? const TimeOfDay(hour: 14, minute: 0);
    
    // Calculer l'heure de fin par défaut (2h après le début)
    if (_selectedStartTime != null) {
      final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
      final endMinutes = startMinutes + (_durationValue * 60);
      _selectedEndTime = TimeOfDay(
        hour: (endMinutes ~/ 60) % 24,
        minute: endMinutes % 60,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Nouveau RDV',
        subtitle: _getEventTypeLabel(_selectedEventType),
        showBackButton: true,
        useProStyle: true,
        actions: [
          if (_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: const TattooAssistantButton(),
      body: Stack(
        children: [
          // Background charbon
          Image.asset(
            'assets/background_charbon.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildEventTypeSelector(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 16),
                    _buildDateTimeSection(),
                    const SizedBox(height: 16),
                    _buildClientInfoSection(),
                    const SizedBox(height: 16),
                    _buildLocationSection(),
                    const SizedBox(height: 16),
                    _buildPricingSection(),
                    const SizedBox(height: 16),
                    _buildAdvancedOptionsToggle(),
                    if (_showAdvancedOptions) ...[
                      const SizedBox(height: 16),
                      _buildAdvancedOptionsSection(),
                    ],
                    if (_isGuestEvent) ...[
                      const SizedBox(height: 16),
                      _buildGuestSystemSection(),
                    ],
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeSelector() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              KipikTheme.rouge.withOpacity(0.9),
              KipikTheme.rouge.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: KipikTheme.rouge.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type de rendez-vous',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventType.values.map((type) {
                final isSelected = _selectedEventType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEventType = type;
                      // Activer automatiquement le mode Guest si sélectionné
                      if (type == EventType.guest) {
                        _isGuestEvent = true;
                      } else {
                        _isGuestEvent = false;
                      }
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? null : Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEventTypeIcon(type),
                          size: 16,
                          color: isSelected ? KipikTheme.rouge : Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getEventTypeLabel(type),
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: isSelected ? KipikTheme.rouge : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildFormSection(
      title: 'Informations générales',
      icon: Icons.info_outline,
      child: Column(
        children: [
          // Titre
          TextFormField(
            controller: _titleController,
            validator: (value) => 
                value == null || value.isEmpty ? 'Le titre est obligatoire' : null,
            decoration: _buildInputDecoration(
              labelText: 'Titre du RDV',
              hintText: 'Ex: Tatouage rose minimaliste',
              prefixIcon: Icons.title,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: _buildInputDecoration(
              labelText: 'Description (optionnelle)',
              hintText: 'Détails du projet, zone à tatouer, style...',
              prefixIcon: Icons.description,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return _buildFormSection(
      title: 'Date et heure',
      icon: Icons.schedule,
      child: Column(
        children: [
          // Date
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: KipikTheme.rouge),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date du RDV',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _selectedDate != null 
                              ? _formatDate(_selectedDate!)
                              : 'Sélectionner une date',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_more, color: Colors.grey),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Heure de début et durée
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectStartTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: KipikTheme.rouge),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Début',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _selectedStartTime?.format(context) ?? 'Choisir',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: GestureDetector(
                  onTap: _selectDuration,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: KipikTheme.rouge),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Durée',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDuration(),
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Heure de fin calculée
          if (_selectedStartTime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Fin prévue : ${_selectedEndTime?.format(context) ?? 'Non calculée'}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientInfoSection() {
    if (_selectedEventType == EventType.personnel || 
        _selectedEventType == EventType.deplacement ||
        _selectedEventType == EventType.formation) {
      return const SizedBox.shrink();
    }

    return _buildFormSection(
      title: 'Informations client',
      icon: Icons.person_outline,
      child: Column(
        children: [
          // Nom du client
          TextFormField(
            controller: _clientNameController,
            validator: (value) => 
                value == null || value.isEmpty ? 'Le nom du client est obligatoire' : null,
            decoration: _buildInputDecoration(
              labelText: 'Nom du client',
              hintText: 'Prénom Nom',
              prefixIcon: Icons.person,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Email et téléphone
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _clientEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    labelText: 'Email',
                    hintText: 'client@email.com',
                    prefixIcon: Icons.email,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _clientPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration(
                    labelText: 'Téléphone',
                    hintText: '06 12 34 56 78',
                    prefixIcon: Icons.phone,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _buildFormSection(
      title: 'Lieu du rendez-vous',
      icon: Icons.location_on_outlined,
      child: Column(
        children: [
          // Type de lieu
          DropdownButtonFormField<LocationType>(
            value: _locationType,
            decoration: _buildInputDecoration(
              labelText: 'Type de lieu',
              prefixIcon: Icons.place,
            ),
            items: LocationType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(_getLocationIcon(type), size: 16),
                    const SizedBox(width: 8),
                    Text(_getLocationLabel(type)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _locationType = value!;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Détails du lieu
          TextFormField(
            controller: _locationDetailsController,
            decoration: _buildInputDecoration(
              labelText: 'Adresse / Détails',
              hintText: _getLocationHint(_locationType),
              prefixIcon: Icons.location_on,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    if (_selectedEventType == EventType.personnel || 
        _selectedEventType == EventType.formation) {
      return const SizedBox.shrink();
    }

    return _buildFormSection(
      title: 'Tarification',
      icon: Icons.euro,
      child: Column(
        children: [
          // Prix
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _price = double.tryParse(value);
              if (_price != null && _price! > 200) {
                setState(() {
                  _requiresDeposit = true;
                  _deposit = _price! * 0.3;
                  _depositController.text = _deposit!.toInt().toString();
                });
              }
            },
            decoration: _buildInputDecoration(
              labelText: 'Prix (€)',
              hintText: '150',
              prefixIcon: Icons.euro,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Acompte
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CheckboxListTile(
                  title: const Text(
                    'Acompte requis',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _requiresDeposit,
                  activeColor: KipikTheme.rouge,
                  onChanged: (value) {
                    setState(() {
                      _requiresDeposit = value ?? false;
                      if (!_requiresDeposit) {
                        _deposit = null;
                        _depositController.clear();
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              
              if (_requiresDeposit) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _depositController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _deposit = double.tryParse(value);
                    },
                    decoration: _buildInputDecoration(
                      labelText: 'Acompte (€)',
                      hintText: '50',
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          // Récapitulatif prix
          if (_price != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Prix total:',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_price!.toInt()}€',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (_requiresDeposit && _deposit != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Acompte:',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${_deposit!.toInt()}€',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reste à payer:',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${(_price! - _deposit!).toInt()}€',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedOptionsToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAdvancedOptions = !_showAdvancedOptions;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.settings_outlined,
              color: KipikTheme.rouge,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Options avancées',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return _buildFormSection(
      title: 'Options avancées',
      icon: Icons.tune,
      child: Column(
        children: [
          // Options de notification
          SwitchListTile(
            title: const Text(
              'Envoyer email de confirmation',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
            value: _sendConfirmationEmail,
            activeColor: KipikTheme.rouge,
            onChanged: (value) {
              setState(() {
                _sendConfirmationEmail = value;
              });
            },
          ),
          
          SwitchListTile(
            title: const Text(
              'Ajouter au calendrier externe',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
            value: _addToCalendar,
            activeColor: KipikTheme.rouge,
            onChanged: (value) {
              setState(() {
                _addToCalendar = value;
              });
            },
          ),
          
          // RDV récurrent
          SwitchListTile(
            title: const Text(
              'Rendez-vous récurrent',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
            value: _isRecurring,
            activeColor: KipikTheme.rouge,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
              });
            },
          ),
          
          if (_isRecurring) ...[
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _recurringPattern,
                    decoration: _buildInputDecoration(
                      labelText: 'Fréquence',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
                      DropdownMenuItem(value: 'biweekly', child: Text('Bi-hebdomadaire')),
                      DropdownMenuItem(value: 'monthly', child: Text('Mensuel')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _recurringPattern = value!;
                      });
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: TextFormField(
                    initialValue: _recurringCount.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _recurringCount = int.tryParse(value) ?? 1;
                    },
                    decoration: _buildInputDecoration(
                      labelText: 'Nombre',
                      hintText: '4',
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Notes
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: _buildInputDecoration(
              labelText: 'Notes internes',
              hintText: 'Préparation spéciale, allergies...',
              prefixIcon: Icons.note_add,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestSystemSection() {
    return _buildFormSection(
      title: 'Guest System Premium',
      icon: Icons.handshake,
      child: Column(
        children: [
          // Info Premium
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.2),
                  Colors.orange.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Fonctionnalité Premium - Guest System automatisé',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Type de Guest
          Row(
            children: [
              Expanded(
                child: RadioListTile<GuestType>(
                  title: const Text(
                    'Je vais en Guest',
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Dans un autre shop',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: GuestType.outgoing,
                  groupValue: _guestType,
                  activeColor: KipikTheme.rouge,
                  onChanged: (value) {
                    setState(() {
                      _guestType = value!;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<GuestType>(
                  title: const Text(
                    'Je reçois un Guest',
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Dans mon shop',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: GuestType.incoming,
                  groupValue: _guestType,
                  activeColor: KipikTheme.rouge,
                  onChanged: (value) {
                    setState(() {
                      _guestType = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_guestType == GuestType.outgoing) 
            _buildOutgoingGuestSection()
          else 
            _buildIncomingGuestSection(),
        ],
      ),
    );
  }

  Widget _buildOutgoingGuestSection() {
    return Column(
      children: [
        // Sélection contrat Guest validé
        GestureDetector(
          onTap: _selectGuestContract,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contrat Guest validé',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _selectedGuestContract ?? 'Sélectionner un contrat validé',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
              ],
            ),
          ),
        ),
        
        if (_selectedGuestContract != null) ...[
          const SizedBox(height: 16),
          
          // Détails du contrat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Détails du contrat Guest',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                _buildContractDetail('Shop hôte', _hostShopName ?? 'Ink Studio Paris'),
                _buildContractDetail('Adresse', _hostShopAddress ?? '15 Rue des Martyrs, 75009 Paris'),
                _buildContractDetail('Commission', '${_guestCommissionRate.toInt()}% sur chaque tatouage'),
                _buildContractDetail('Hébergement', _accommodationIncluded ? 'Inclus' : 'Non inclus'),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Votre localisation sera automatiquement mise à jour',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIncomingGuestSection() {
    return Column(
      children: [
        // Sélection Guest entrant
        GestureDetector(
          onTap: _selectIncomingGuest,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_add, color: Colors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tatoueur Guest',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _guestDetails?['name'] ?? 'Sélectionner le tatoueur Guest',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.purple, size: 16),
              ],
            ),
          ),
        ),
        
        if (_guestDetails != null) ...[
          const SizedBox(height: 16),
          
          // Profil du Guest
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.purple.withOpacity(0.2),
                      backgroundImage: _guestDetails!['avatar'] != null
                          ? AssetImage(_guestDetails!['avatar'] as String)
                          : null,
                      child: _guestDetails!['avatar'] == null
                          ? const Icon(Icons.person, color: Colors.purple)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _guestDetails!['name'] ?? 'Guest Tatoueur',
                            style: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _guestDetails!['style'] ?? 'Style de tatouage',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${_guestDetails!['rating'] ?? 4.8}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _viewGuestProfile,
                      icon: const Icon(Icons.visibility, color: Colors.purple),
                      tooltip: 'Voir le profil',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Options de suivi
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Suivi réalisations en temps réel',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                          ),
                        ),
                        value: true,
                        dense: true,
                        activeColor: KipikTheme.rouge,
                        onChanged: (value) {},
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Notifications de facturation',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                          ),
                        ),
                        value: _hasActiveFees,
                        dense: true,
                        activeColor: KipikTheme.rouge,
                        onChanged: (value) {
                          setState(() {
                            _hasActiveFees = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContractDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canSave = _formKey.currentState?.validate() ?? false;

    return Column(
      children: [
        // Bouton principal
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: canSave && !_isLoading ? _saveEvent : null,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save, size: 20),
            label: Text(
              _isLoading ? 'Création en cours...' : 'Créer le RDV',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canSave ? KipikTheme.rouge : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: canSave ? 4 : 0,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Bouton secondaire
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _saveAsDraft,
            icon: const Icon(Icons.drafts, size: 18),
            label: const Text(
              'Enregistrer comme brouillon',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(
        fontFamily: 'Roboto',
        color: Colors.grey[600],
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: Colors.grey,
      ),
      prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, color: KipikTheme.rouge) 
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KipikTheme.rouge),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
    );
  }

  // Actions
  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: KipikTheme.rouge,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: KipikTheme.rouge,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        _calculateEndTime();
      });
    }
  }

  void _selectDuration() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Durée du RDV',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            // Sélecteur de durée
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Valeur', style: TextStyle(fontFamily: 'Roboto')),
                      const SizedBox(height: 8),
                      DropdownButton<int>(
                        value: _durationValue,
                        isExpanded: true,
                        items: List.generate(12, (index) => index + 1)
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _durationValue = value!;
                            _calculateEndTime();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Unité', style: TextStyle(fontFamily: 'Roboto')),
                      const SizedBox(height: 8),
                      DropdownButton<DurationUnit>(
                        value: _durationUnit,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: DurationUnit.minutes, child: Text('Minutes')),
                          DropdownMenuItem(value: DurationUnit.hours, child: Text('Heures')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _durationUnit = value!;
                            _calculateEndTime();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Valider'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateEndTime() {
    if (_selectedStartTime != null) {
      final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
      final durationMinutes = _durationUnit == DurationUnit.hours 
          ? _durationValue * 60 
          : _durationValue;
      final endMinutes = startMinutes + durationMinutes;
      
      setState(() {
        _selectedEndTime = TimeOfDay(
          hour: (endMinutes ~/ 60) % 24,
          minute: endMinutes % 60,
        );
      });
    }
  }

  void _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    HapticFeedback.mediumImpact();
    
    try {
      // Simulation de sauvegarde
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _showSuccessDialog();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveAsDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Brouillon enregistré'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'RDV Créé !',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le rendez-vous a été ajouté à votre planning',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Fermer dialog
                  Navigator.pop(context, true); // Retourner avec succès
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Parfait !',
                  style: TextStyle(fontFamily: 'Roboto'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Actions Guest System
  void _selectGuestContract() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contrats Guest validés',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            // Liste des contrats (simulation)
            ...['Ink Studio Paris - 15-20 Juin', 'Black Art Lyon - 3-7 Juillet', 'Urban Tattoo Marseille - 10-15 Août']
                .map((contract) => ListTile(
                  title: Text(
                    contract,
                    style: const TextStyle(fontFamily: 'Roboto'),
                  ),
                  leading: const Icon(Icons.description, color: Colors.blue),
                  onTap: () {
                    setState(() {
                      _selectedGuestContract = contract;
                      _hostShopName = contract.split(' - ')[0];
                      _hostShopAddress = '${contract.split(' - ')[0]} - Adresse';
                      _guestCommissionRate = 20.0;
                      _accommodationIncluded = true;
                    });
                    Navigator.pop(context);
                  },
                )),
            
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _goToGuestMarketplace();
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouveau contrat Guest'),
              style: OutlinedButton.styleFrom(
                foregroundColor: KipikTheme.rouge,
                side: BorderSide(color: KipikTheme.rouge),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectIncomingGuest() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Guests confirmés',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            // Liste des guests (simulation)
            ...List.generate(3, (index) {
              final guests = [
                {'name': 'Alex Martin', 'style': 'Réalisme', 'rating': 4.9, 'avatar': 'assets/avatars/guest1.png'},
                {'name': 'Emma Chen', 'style': 'Japonais', 'rating': 4.7, 'avatar': 'assets/avatars/guest2.png'},
                {'name': 'Lucas Dubois', 'style': 'Geometric', 'rating': 4.8, 'avatar': 'assets/avatars/guest3.png'},
              ];
              final guest = guests[index];
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage(guest['avatar'] as String),
                ),
                title: Text(
                  guest['name'] as String,
                  style: const TextStyle(fontFamily: 'Roboto'),
                ),
                subtitle: Text(
                  '${guest['style']} • ⭐ ${guest['rating']}',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  setState(() {
                    _guestDetails = guest;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _goToGuestMarketplace();
              },
              icon: const Icon(Icons.search),
              label: const Text('Chercher un Guest'),
              style: OutlinedButton.styleFrom(
                foregroundColor: KipikTheme.rouge,
                side: BorderSide(color: KipikTheme.rouge),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewGuestProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture du profil Guest - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goToGuestMarketplace() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirection vers Guest Marketplace - À implémenter'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    
    return '$weekday $day $month $year';
  }

  String _formatDuration() {
    final unit = _durationUnit == DurationUnit.hours ? 'h' : 'min';
    return '$_durationValue$unit';
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.tattoo:
        return 'Tatouage';
      case EventType.consultation:
        return 'Consultation';
      case EventType.retouche:
        return 'Retouche';
      case EventType.devis:
        return 'Devis';
      case EventType.deplacement:
        return 'Déplacement';
      case EventType.personnel:
        return 'Personnel';
      case EventType.convention:
        return 'Convention';
      case EventType.formation:
        return 'Formation';
      case EventType.guest:
        return 'Guest Shop';
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.tattoo:
        return Icons.brush;
      case EventType.consultation:
        return Icons.chat_bubble_outline;
      case EventType.retouche:
        return Icons.edit;
      case EventType.devis:
        return Icons.receipt_long;
      case EventType.deplacement:
        return Icons.flight;
      case EventType.personnel:
        return Icons.person;
      case EventType.convention:
        return Icons.event;
      case EventType.formation:
        return Icons.school;
      case EventType.guest:
        return Icons.store_mall_directory;
    }
  }

  String _getLocationLabel(LocationType type) {
    switch (type) {
      case LocationType.studio:
        return 'Studio';
      case LocationType.domicile:
        return 'À domicile';
      case LocationType.guest:
        return 'Guest shop';
      case LocationType.convention:
        return 'Convention';
      case LocationType.autre:
        return 'Autre';
    }
  }

  IconData _getLocationIcon(LocationType type) {
    switch (type) {
      case LocationType.studio:
        return Icons.home_work;
      case LocationType.domicile:
        return Icons.home;
      case LocationType.guest:
        return Icons.store;
      case LocationType.convention:
        return Icons.event;
      case LocationType.autre:
        return Icons.place;
    }
  }

  String _getLocationHint(LocationType type) {
    switch (type) {
      case LocationType.studio:
        return 'Salon principal, Cabinet 2...';
      case LocationType.domicile:
        return 'Adresse du client';
      case LocationType.guest:
        return 'Nom du shop + adresse';
      case LocationType.convention:
        return 'Nom + lieu de la convention';
      case LocationType.autre:
        return 'Préciser le lieu';
    }
  }
}