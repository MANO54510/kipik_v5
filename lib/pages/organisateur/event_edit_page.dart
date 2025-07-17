// lib/pages/organisateur/event_edit_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/common/drawers/drawer_factory.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../core/helpers/service_helper.dart';
import '../../core/helpers/widget_helper.dart';

enum ConventionType { tattoo, piercing, mixed, art }

class EventEditPage extends StatefulWidget {
  final String? conventionId;
  
  const EventEditPage({Key? key, this.conventionId}) : super(key: key);

  @override
  State<EventEditPage> createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> with TickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSaving = false;

  // 📝 Form controllers - Map pour éviter la redondance
  final Map<String, TextEditingController> _controllers = {};
  
  // 📊 Form data centralisé
  final Map<String, dynamic> _formData = {
    'type': ConventionType.tattoo,
    'startDate': null,
    'endDate': null,
    'startTime': null,
    'endTime': null,
    'maxTattooers': 50,
    'expectedVisitors': 500,
    'standPrice': 300.0,
    'ticketPrice': 15.0,
    'allowOnlineBooking': true,
    'allowFractionalPayment': true,
    'selectedAmenities': <String>[],
    'hasZonePricing': false,
    'pricingZones': <Map<String, dynamic>>[],
    'selectedImage': null,
  };

  final _formKey = GlobalKey<FormState>();
  List<String> _validationErrors = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _loadData();
  }

  void _initializeControllers() {
    final fields = ['name', 'description', 'location', 'address', 'website', 'email', 'phone'];
    for (final field in fields) {
      _controllers[field] = TextEditingController();
    }
  }

  void _initializeAnimations() {
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  void _loadData() async {
    if (widget.conventionId == null) return;
    
    setState(() => _isLoading = true);
    
    final data = await ServiceHelper.getConventionData(widget.conventionId!);
    if (data.isNotEmpty && mounted) {
      _populateForm(data);
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  void _populateForm(Map<String, dynamic> data) {
    // 📝 Populate controllers
    _controllers['name']?.text = data['basic']?['name'] ?? '';
    _controllers['description']?.text = data['basic']?['description'] ?? '';
    _controllers['location']?.text = data['location']?['venue'] ?? '';
    _controllers['address']?.text = data['location']?['address'] ?? '';
    _controllers['email']?.text = data['contact']?['email'] ?? '';
    _controllers['phone']?.text = data['contact']?['phone'] ?? '';
    _controllers['website']?.text = data['contact']?['website'] ?? '';

    // 📊 Populate form data
    setState(() {
      _formData['type'] = _parseType(data['basic']?['type']);
      _formData['maxTattooers'] = data['location']?['capacity'] ?? 50;
      _formData['expectedVisitors'] = data['dates']?['expectedVisitors'] ?? 500;
      _formData['standPrice'] = (data['pricing']?['standPrice'] ?? 300.0).toDouble();
      _formData['ticketPrice'] = (data['pricing']?['ticketPrice'] ?? 15.0).toDouble();
      _formData['allowOnlineBooking'] = data['settings']?['onlineBooking'] ?? true;
      _formData['allowFractionalPayment'] = data['settings']?['fractionalPayment'] ?? true;
      _formData['selectedAmenities'] = List<String>.from(data['settings']?['amenities'] ?? []);
      _formData['hasZonePricing'] = data['pricing']?['hasZonePricing'] ?? false;
      _formData['pricingZones'] = List<Map<String, dynamic>>.from(data['pricing']?['zones'] ?? []);
      _formData['selectedImage'] = data['media']?['coverImage'];
      
      // Dates
      final startTimestamp = data['dates']?['start'];
      if (startTimestamp is Timestamp) {
        final startDateTime = startTimestamp.toDate();
        _formData['startDate'] = startDateTime;
        _formData['startTime'] = TimeOfDay.fromDateTime(startDateTime);
      }
      
      final endTimestamp = data['dates']?['end'];
      if (endTimestamp is Timestamp) {
        final endDateTime = endTimestamp.toDate();
        _formData['endDate'] = endDateTime;
        _formData['endTime'] = TimeOfDay.fromDateTime(endDateTime);
      }
    });
  }

  ConventionType _parseType(String? type) {
    switch (type) {
      case 'tattoo': return ConventionType.tattoo;
      case 'piercing': return ConventionType.piercing;
      case 'mixed': return ConventionType.mixed;
      case 'art': return ConventionType.art;
      default: return ConventionType.tattoo;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ServiceHelper.isAuthenticated) {
      return KipikTheme.errorState(
        title: 'Non connecté',
        message: 'Vous devez être connecté pour accéder à cette page',
        onRetry: () => Navigator.pushReplacementNamed(context, '/login'),
      );
    }

    return KipikTheme.scaffoldWithoutBackground(
      backgroundColor: KipikTheme.noir,
      endDrawer: DrawerFactory.of(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBarKipik(
          title: widget.conventionId != null ? 'Modifier Convention' : 'Nouvelle Convention',
          subtitle: 'Étape ${_currentStep + 1}/4',
          showBackButton: true,
          useProStyle: true,
          actions: [
            if (_currentStep > 0)
              IconButton(
                icon: _isSaving 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save_outlined, color: Colors.white),
                onPressed: _isSaving ? null : _saveDraft,
              ),
          ],
        ),
      ),
      child: Stack(
        children: [
          KipikTheme.withSpecificBackground('assets/background_charbon.png', child: Container()),
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoading ? Center(child: KipikTheme.loading()) : _buildContent(),
            ),
          ),
          
          // ✅ ASSISTANT IA CONTEXTUEL
          TattooAssistantButton(
            currentStep: _currentStep,
            formData: _formData,
            contextData: 'event_creation',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildProgress(),
        const SizedBox(height: 16),
        if (_validationErrors.isNotEmpty) _buildValidationErrors(),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentStep = index),
            children: [
              _buildBasicInfoStep(),
              _buildLocationDateStep(),
              _buildConfigurationStep(),
              _buildFinalizationStep(),
            ],
          ),
        ),
        _buildNavigation(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: WidgetHelper.buildProgressIndicator(
        currentStep: _currentStep + 1,
        totalSteps: 4,
        stepTitle: _getStepTitle(_currentStep),
      ),
    );
  }

  Widget _buildValidationErrors() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                const Text('Erreurs à corriger', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            ..._validationErrors.map((error) => Text('• $error', style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              WidgetHelper.buildStepHeader('Informations de Base', 'Nom, type et description', Icons.info),
              const SizedBox(height: 24),
              
              WidgetHelper.buildFormField(
                label: 'Nom de la convention *',
                controller: _controllers['name']!,
                hint: 'Ex: Paris Tattoo Convention 2025',
                validator: (value) => value?.isEmpty == true ? 'Le nom est obligatoire' : null,
              ),
              const SizedBox(height: 20),
              
              _buildTypeSelector(),
              const SizedBox(height: 20),
              
              WidgetHelper.buildFormField(
                label: 'Description *',
                controller: _controllers['description']!,
                hint: 'Décrivez votre convention...',
                maxLines: 4,
                validator: (value) => (value?.length ?? 0) < 50 ? 'Description trop courte (min. 50 caractères)' : null,
              ),
              const SizedBox(height: 20),
              
              _buildImageSelector(),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: WidgetHelper.buildFormField(
                      label: 'Email',
                      controller: _controllers['email']!,
                      hint: 'contact@convention.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: WidgetHelper.buildFormField(
                      label: 'Téléphone',
                      controller: _controllers['phone']!,
                      hint: '01 23 45 67 89',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              WidgetHelper.buildFormField(
                label: 'Site web',
                controller: _controllers['website']!,
                hint: 'https://www.votre-convention.com',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDateStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            WidgetHelper.buildStepHeader('Lieu et Dates', 'Où et quand se déroulera votre convention', Icons.location_on),
            const SizedBox(height: 24),
            
            WidgetHelper.buildFormField(
              label: 'Nom du lieu *',
              controller: _controllers['location']!,
              hint: 'Ex: Paris Expo, Centre des Congrès...',
              validator: (value) => value?.isEmpty == true ? 'Le lieu est obligatoire' : null,
            ),
            const SizedBox(height: 20),
            
            WidgetHelper.buildFormField(
              label: 'Adresse complète *',
              controller: _controllers['address']!,
              hint: 'Adresse, ville, code postal',
              maxLines: 2,
              validator: (value) => value?.isEmpty == true ? 'L\'adresse est obligatoire' : null,
            ),
            const SizedBox(height: 20),
            
            _buildDateSelection(),
            const SizedBox(height: 20),
            
            _buildTimeSelection(),
            const SizedBox(height: 20),
            
            _buildCapacitySettings(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            WidgetHelper.buildStepHeader('Configuration', 'Prix et options', Icons.settings),
            const SizedBox(height: 24),
            
            _buildZonePricingSection(),
            const SizedBox(height: 20),
            
            if (!_formData['hasZonePricing']) _buildPricingSection(),
            const SizedBox(height: 20),
            
            _buildBookingOptions(),
            const SizedBox(height: 20),
            
            WidgetHelper.buildAmenitiesSelector(
              selectedAmenities: _formData['selectedAmenities'],
              onChanged: (amenities) => setState(() => _formData['selectedAmenities'] = amenities),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalizationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            WidgetHelper.buildStepHeader('Finalisation', 'Vérifiez et publiez', Icons.check_circle),
            const SizedBox(height: 24),
            
            _buildSummary(),
            const SizedBox(height: 20),
            
            _buildRevenueProjection(),
            const SizedBox(height: 20),
            
            _buildPublishOptions(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return WidgetHelper.buildTypeSelector<ConventionType>(
      label: 'Type de convention *',
      options: ConventionType.values,
      selectedValue: _formData['type'],
      getLabel: _getTypeLabel,
      getIcon: _getTypeIcon,
      onChanged: (type) => setState(() => _formData['type'] = type),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dates de la convention *',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: WidgetHelper.buildDateCard(
                'Date de début',
                _formData['startDate'],
                (date) => setState(() => _formData['startDate'] = date),
                context,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: WidgetHelper.buildDateCard(
                'Date de fin',
                _formData['endDate'],
                (date) => setState(() => _formData['endDate'] = date),
                context,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horaires d\'ouverture',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: WidgetHelper.buildTimeCard(
                'Ouverture',
                _formData['startTime'],
                (time) => setState(() => _formData['startTime'] = time),
                context,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: WidgetHelper.buildTimeCard(
                'Fermeture',
                _formData['endTime'],
                (time) => setState(() => _formData['endTime'] = time),
                context,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image de couverture',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectImage,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _formData['selectedImage'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _formData['selectedImage']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'Ajouter une image',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapacitySettings() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capacités',
            style: TextStyle(
              fontFamily: KipikTheme.fontTitle,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          WidgetHelper.buildSliderSetting(
            label: 'Nombre maximum de tatoueurs',
            value: _formData['maxTattooers'].toDouble(),
            min: 10,
            max: 200,
            onChanged: (value) => setState(() => _formData['maxTattooers'] = value.toInt()),
            displayValue: '${_formData['maxTattooers']} tatoueurs',
            context: context,
          ),
          
          const SizedBox(height: 16),
          
          WidgetHelper.buildSliderSetting(
            label: 'Visiteurs attendus',
            value: _formData['expectedVisitors'].toDouble(),
            min: 100,
            max: 5000,
            onChanged: (value) => setState(() => _formData['expectedVisitors'] = value.toInt()),
            displayValue: '${_formData['expectedVisitors']} visiteurs',
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildZonePricingSection() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              Text(
                'Système de Prix par Zones',
                style: TextStyle(
                  fontFamily: KipikTheme.fontTitle,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          WidgetHelper.buildSwitchTile(
            title: 'Activer les prix par zones',
            subtitle: _formData['hasZonePricing'] 
                ? 'Différents prix selon l\'emplacement (premium, standard, économique)'
                : 'Prix unique pour tous les stands',
            value: _formData['hasZonePricing'],
            onChanged: (value) {
              setState(() {
                _formData['hasZonePricing'] = value;
                if (value && _formData['pricingZones'].isEmpty) {
                  _initializeDefaultZones();
                }
              });
            },
          ),
          
          if (_formData['hasZonePricing']) ...[
            const SizedBox(height: 16),
            _buildZonesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildZonesList() {
    final zones = _formData['pricingZones'] as List<Map<String, dynamic>>;
    
    return Column(
      children: [
        ...zones.asMap().entries.map((entry) {
          final index = entry.key;
          final zone = entry.value;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: zone['name']?.toString() ?? '',
                        decoration: InputDecoration(
                          labelText: 'Nom de la zone',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            zones[index]['name'] = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          zones.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: zone['pricePerM2']?.toString() ?? '',
                        decoration: InputDecoration(
                          labelText: 'Prix/m²',
                          border: OutlineInputBorder(),
                          suffixText: '€',
                          contentPadding: EdgeInsets.all(8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final price = double.tryParse(value);
                          if (price != null) {
                            setState(() {
                              zones[index]['pricePerM2'] = price;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: zone['type']?.toString() ?? 'standard',
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8),
                        ),
                        items: [
                          DropdownMenuItem(value: 'premium', child: Text('Premium')),
                          DropdownMenuItem(value: 'standard', child: Text('Standard')),
                          DropdownMenuItem(value: 'economic', child: Text('Économique')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              zones[index]['type'] = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addPricingZone,
            icon: Icon(Icons.add, size: 16),
            label: Text('Ajouter une zone'),
            style: OutlinedButton.styleFrom(
              foregroundColor: KipikTheme.rouge,
              side: BorderSide(color: KipikTheme.rouge),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.euro, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              Text(
                'Tarification',
                style: TextStyle(
                  fontFamily: KipikTheme.fontTitle,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prix stand (€/m²)',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _formData['standPrice'].toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: '€/m²',
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: (value) {
                        final price = double.tryParse(value);
                        if (price != null) {
                          setState(() => _formData['standPrice'] = price);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prix billet (€)',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _formData['ticketPrice'].toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: '€',
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: (value) {
                        final price = double.tryParse(value);
                        if (price != null) {
                          setState(() => _formData['ticketPrice'] = price);
                        }
                      },
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

  Widget _buildBookingOptions() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              Text(
                'Options de Réservation',
                style: TextStyle(
                  fontFamily: KipikTheme.fontTitle,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          WidgetHelper.buildSwitchTile(
            title: 'Réservation en ligne',
            subtitle: 'Permettre aux tatoueurs de réserver via l\'app',
            value: _formData['allowOnlineBooking'],
            onChanged: (value) => setState(() => _formData['allowOnlineBooking'] = value),
          ),
          
          WidgetHelper.buildSwitchTile(
            title: 'Paiement fractionné',
            subtitle: 'Autoriser le paiement en 2, 3 ou 4 fois',
            value: _formData['allowFractionalPayment'],
            onChanged: (value) => setState(() => _formData['allowFractionalPayment'] = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final summaryData = {
      'Nom': _controllers['name']?.text ?? '',
      'Type': _getTypeLabel(_formData['type']),
      'Lieu': _controllers['location']?.text ?? '',
      'Capacité': '${_formData['maxTattooers']} tatoueurs',
      'Prix stand': '${_formData['standPrice'].toStringAsFixed(0)}€/m²',
      'Prix billet': '${_formData['ticketPrice'].toStringAsFixed(0)}€',
    };

    if (_formData['startDate'] != null && _formData['endDate'] != null) {
      summaryData['Dates'] = '${ServiceHelper.formatDate(_formData['startDate'])} - ${ServiceHelper.formatDate(_formData['endDate'])}';
    }

    return WidgetHelper.buildSummaryCard(
      title: 'Résumé de la Convention',
      summaryData: summaryData,
    );
  }

  Widget _buildRevenueProjection() {
    // Calcul intelligent selon le système de prix
    double standRevenue = 0;
    if (_formData['hasZonePricing'] && (_formData['pricingZones'] as List).isNotEmpty) {
      // Calcul avec zones : moyenne pondérée
      final zones = _formData['pricingZones'] as List<Map<String, dynamic>>;
      final avgPrice = zones.fold(0.0, (sum, zone) {
        final price = zone['pricePerM2'];
        if (price is num) return sum + price.toDouble();
        return sum;
      }) / zones.length;
      standRevenue = _formData['maxTattooers'] * avgPrice * 6.0; // 6m² moyenne par stand
    } else {
      standRevenue = _formData['maxTattooers'] * _formData['standPrice'] * 6.0;
    }
    
    final ticketRevenue = _formData['expectedVisitors'] * _formData['ticketPrice'];
    final totalRevenue = standRevenue + ticketRevenue;
    final kipikCommission = totalRevenue * 0.01; // 1% commission Kipik
    final netRevenue = totalRevenue - kipikCommission;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Projection de Revenus',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildRevenueRow('Revenus stands', ServiceHelper.formatCurrency(standRevenue)),
          _buildRevenueRow('Revenus billets', ServiceHelper.formatCurrency(ticketRevenue)),
          Divider(color: Colors.white54),
          _buildRevenueRow('Total brut', ServiceHelper.formatCurrency(totalRevenue)),
          _buildRevenueRow('Commission Kipik (1%)', '-${ServiceHelper.formatCurrency(kipikCommission)}'),
          Divider(color: Colors.white54),
          _buildRevenueRow('Total net', ServiceHelper.formatCurrency(netRevenue), isBold: true),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Projection basée sur ${_formData['maxTattooers']} stands de 6m² et ${_formData['expectedVisitors']} visiteurs',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.white70,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: isBold ? 'PermanentMarker' : 'Roboto',
              fontSize: isBold ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishOptions() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.publish, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              Text(
                'Publication',
                style: TextStyle(
                  fontFamily: KipikTheme.fontTitle,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: WidgetHelper.buildActionButton(
                  text: 'Sauvegarder brouillon',
                  onPressed: _saveDraft,
                  isPrimary: false,
                  isLoading: _isSaving,
                  icon: Icons.save,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WidgetHelper.buildActionButton(
                  text: 'Publier maintenant',
                  onPressed: _publishConvention,
                  isLoading: _isSaving,
                  icon: Icons.publish,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: WidgetHelper.buildActionButton(
                text: 'Précédent',
                onPressed: _previousStep,
                isPrimary: false,
                icon: Icons.arrow_back,
              ),
            ),
          if (_currentStep > 0 && _currentStep < 3) const SizedBox(width: 12),
          if (_currentStep < 3)
            Expanded(
              child: WidgetHelper.buildActionButton(
                text: 'Suivant',
                onPressed: _nextStep,
                icon: Icons.arrow_forward,
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Informations de base';
      case 1: return 'Lieu et dates';
      case 2: return 'Configuration et prix';
      case 3: return 'Finalisation';
      default: return '';
    }
  }

  IconData _getTypeIcon(ConventionType type) {
    switch (type) {
      case ConventionType.tattoo: return Icons.brush;
      case ConventionType.piercing: return Icons.circle;
      case ConventionType.mixed: return Icons.palette;
      case ConventionType.art: return Icons.art_track;
    }
  }

  String _getTypeLabel(ConventionType type) {
    switch (type) {
      case ConventionType.tattoo: return 'Tatouage';
      case ConventionType.piercing: return 'Piercing';
      case ConventionType.mixed: return 'Mixte';
      case ConventionType.art: return 'Art corporel';
    }
  }

  bool _validateCurrentStep() {
    _validationErrors.clear();

    switch (_currentStep) {
      case 0:
        if (_controllers['name']?.text.isEmpty == true) {
          _validationErrors.add('Le nom de la convention est obligatoire');
        }
        if ((_controllers['description']?.text.length ?? 0) < 50) {
          _validationErrors.add('La description doit faire au moins 50 caractères');
        }
        break;
      case 1:
        if (_controllers['location']?.text.isEmpty == true) {
          _validationErrors.add('Le lieu est obligatoire');
        }
        if (_controllers['address']?.text.isEmpty == true) {
          _validationErrors.add('L\'adresse est obligatoire');
        }
        if (_formData['startDate'] == null) {
          _validationErrors.add('La date de début est obligatoire');
        }
        if (_formData['endDate'] == null) {
          _validationErrors.add('La date de fin est obligatoire');
        }
        if (_formData['startDate'] != null && _formData['endDate'] != null && 
            _formData['endDate'].isBefore(_formData['startDate'])) {
          _validationErrors.add('La date de fin doit être après la date de début');
        }
        break;
      case 2:
        if (!_formData['hasZonePricing'] && _formData['standPrice'] <= 0) {
          _validationErrors.add('Le prix du stand doit être supérieur à 0');
        }
        if (_formData['hasZonePricing'] && (_formData['pricingZones'] as List).isEmpty) {
          _validationErrors.add('Au moins une zone de prix est requise');
        }
        if (_formData['ticketPrice'] <= 0) {
          _validationErrors.add('Le prix du billet doit être supérieur à 0');
        }
        break;
      case 3:
        // Validation finale complète
        if (_controllers['name']?.text.isEmpty == true) {
          _validationErrors.add('Le nom est obligatoire pour publier');
        }
        if (_formData['startDate'] == null) {
          _validationErrors.add('Les dates sont obligatoires pour publier');
        }
        break;
    }

    setState(() {});
    return _validationErrors.isEmpty;
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (_validateCurrentStep() && _currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _initializeDefaultZones() {
    _formData['pricingZones'] = [
      {
        'name': 'Zone Premium',
        'type': 'premium',
        'pricePerM2': _formData['standPrice'] * 1.5,
        'description': 'Emplacements privilégiés (entrée, passages principaux)',
      },
      {
        'name': 'Zone Standard',
        'type': 'standard',
        'pricePerM2': _formData['standPrice'],
        'description': 'Emplacements centraux, bonne visibilité',
      },
      {
        'name': 'Zone Économique',
        'type': 'economic',
        'pricePerM2': _formData['standPrice'] * 0.7,
        'description': 'Emplacements périphériques, tarif réduit',
      },
    ];
  }

  void _addPricingZone() {
    setState(() {
      (_formData['pricingZones'] as List).add({
        'name': 'Nouvelle Zone',
        'type': 'standard',
        'pricePerM2': _formData['standPrice'],
        'description': '',
      });
    });
  }

  void _selectImage() {
    // Simulation sélection d'image
    setState(() {
      _formData['selectedImage'] = 'assets/convention_placeholder.jpg';
    });
    KipikTheme.showInfoSnackBar(
      context, 
      'Image sélectionnée ! (Intégration Firebase Storage à venir)'
    );
  }

  // Firebase Actions
  Future<void> _saveDraft() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);

    try {
      final conventionData = _buildConventionData('draft');
      
      if (widget.conventionId != null) {
        await ServiceHelper.update('conventions', widget.conventionId!, conventionData);
      } else {
        await ServiceHelper.create('conventions', conventionData);
      }

      if (mounted) {
        KipikTheme.showInfoSnackBar(context, 'Convention sauvegardée en brouillon');
      }
    } catch (e) {
      if (mounted) {
        KipikTheme.showErrorSnackBar(context, 'Erreur lors de la sauvegarde: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _publishConvention() async {
    if (!_validateCurrentStep() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final conventionData = _buildConventionData('published');
      
      if (widget.conventionId != null) {
        await ServiceHelper.update('conventions', widget.conventionId!, conventionData);
      } else {
        await ServiceHelper.create('conventions', conventionData);
      }

      if (mounted) {
        KipikTheme.showSuccessSnackBar(context, 'Convention publiée avec succès ! 🎉');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        KipikTheme.showErrorSnackBar(context, 'Erreur lors de la publication: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Map<String, dynamic> _buildConventionData(String status) {
    final startDateTime = _formData['startDate'] != null && _formData['startTime'] != null
        ? DateTime(
            _formData['startDate'].year,
            _formData['startDate'].month,
            _formData['startDate'].day,
            _formData['startTime'].hour,
            _formData['startTime'].minute,
          )
        : null;
    
    final endDateTime = _formData['endDate'] != null && _formData['endTime'] != null
        ? DateTime(
            _formData['endDate'].year,
            _formData['endDate'].month,
            _formData['endDate'].day,
            _formData['endTime'].hour,
            _formData['endTime'].minute,
          )
        : null;

    return {
      'basic': {
        'name': _controllers['name']?.text ?? '',
        'description': _controllers['description']?.text ?? '',
        'type': _formData['type'].toString().split('.').last,
        'status': status,
        'organizerId': ServiceHelper.currentUserId,
      },
      'location': {
        'venue': _controllers['location']?.text ?? '',
        'address': _controllers['address']?.text ?? '',
        'capacity': _formData['maxTattooers'],
        'coordinates': null,
      },
      'dates': {
        'start': startDateTime != null ? Timestamp.fromDate(startDateTime) : null,
        'end': endDateTime != null ? Timestamp.fromDate(endDateTime) : null,
        'timezone': 'Europe/Paris',
        'expectedVisitors': _formData['expectedVisitors'],
      },
      'pricing': {
        'hasZonePricing': _formData['hasZonePricing'],
        'standPrice': _formData['hasZonePricing'] ? null : _formData['standPrice'],
        'ticketPrice': _formData['ticketPrice'],
        'currency': 'EUR',
        'zones': _formData['hasZonePricing'] ? _formData['pricingZones'] : null,
      },
      'settings': {
        'onlineBooking': _formData['allowOnlineBooking'],
        'fractionalPayment': _formData['allowFractionalPayment'],
        'amenities': _formData['selectedAmenities'],
      },
      'contact': {
        'email': _controllers['email']?.text ?? '',
        'phone': _controllers['phone']?.text ?? '',
        'website': _controllers['website']?.text ?? '',
      },
      'stats': {
        'tattooersCount': 0,
        'maxTattooers': _formData['maxTattooers'],
        'ticketsSold': 0,
        'expectedVisitors': _formData['expectedVisitors'],
        'revenue': {
          'total': 0.0,
          'stands': 0.0,
          'tickets': 0.0,
          'kipikCommission': 0.0,
        },
      },
      'media': {
        'coverImage': _formData['selectedImage'],
        'gallery': [],
      },
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}