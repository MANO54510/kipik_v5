// lib/pages/pro/booking/guest_system/guest_proposal_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/kipik_theme.dart';
import '../../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../../widgets/common/buttons/tattoo_assistant_button.dart';
import 'guest_contract_page.dart';

enum ProposalMode { create, respond }
enum ProposalType { seekingShop, offeringGuest }

class GuestProposalPage extends StatefulWidget {
  final ProposalMode mode;
  final Map<String, dynamic>? targetOffer;
  
  const GuestProposalPage({
    Key? key,
    required this.mode,
    this.targetOffer,
  }) : super(key: key);

  @override
  State<GuestProposalPage> createState() => _GuestProposalPageState();
}

class _GuestProposalPageState extends State<GuestProposalPage> 
    with TickerProviderStateMixin {
  
  final _formKey = GlobalKey<FormState>();
  late AnimationController _slideController;
  late AnimationController _stepController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _stepAnimation;

  // Contrôleurs de formulaire
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();

  // État du formulaire
  ProposalType _proposalType = ProposalType.seekingShop;
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedStyles = [];
  String _selectedLocation = '';
  double _commissionRate = 20.0;
  bool _accommodationRequired = false;
  bool _accommodationOffered = false;
  String _experienceLevel = 'Intermédiaire';
  List<String> _availability = [];
  bool _isFlexibleDates = false;
  int _currentStep = 0;
  bool _isLoading = false;

  final List<String> _tattooStyles = [
    'Réalisme', 'Traditionnel', 'Neo-traditionnel', 'Japonais', 'Tribal',
    'Black & Grey', 'Couleur', 'Minimaliste', 'Géométrique', 'Biomécanique',
    'Portrait', 'Lettering', 'Dotwork', 'Watercolor', 'Old School'
  ];

  final List<String> _cities = [
    'Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice', 'Nantes',
    'Bordeaux', 'Lille', 'Rennes', 'Strasbourg', 'Montpellier'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFromTarget();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _stepController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _messageController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _stepController = AnimationController(
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
    
    _stepAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stepController, curve: Curves.easeOut),
    );

    _slideController.forward();
    _stepController.forward();
  }

  void _initializeFromTarget() {
    if (widget.targetOffer != null) {
      final offer = widget.targetOffer!;
      _selectedLocation = offer['location'].split(',')[0];
      _selectedStyles = List<String>.from(offer['styles']);
      _commissionRate = offer['commission'].toDouble();
      _accommodationOffered = offer['accommodation'] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: widget.mode == ProposalMode.create ? 'Nouvelle Proposition' : 'Répondre à l\'offre',
        subtitle: 'Étape ${_currentStep + 1}/4',
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
            _buildProgressIndicator(),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: PageController(initialPage: _currentStep),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                  _stepController.reset();
                  _stepController.forward();
                },
                children: [
                  _buildStep1ProposalType(),
                  _buildStep2Details(),
                  _buildStep3Terms(),
                  _buildStep4Message(),
                ],
              ),
            ),
            _buildNavigationButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? KipikTheme.rouge : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStepTitle(index),
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? KipikTheme.rouge : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1ProposalType() {
    return FadeTransition(
      opacity: _stepAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildStepCard(
              title: 'Type de proposition',
              icon: Icons.handshake,
              child: Column(
                children: [
                  // Info sur l'offre cible si mode réponse
                  if (widget.mode == ProposalMode.respond && widget.targetOffer != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Vous répondez à l\'offre de:',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.targetOffer!['name']} - ${widget.targetOffer!['location']}',
                            style: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            widget.targetOffer!['description'],
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Sélection du type de proposition
                  const Text(
                    'Que proposez-vous ?',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Column(
                    children: [
                      _buildProposalTypeCard(
                        ProposalType.seekingShop,
                        'Je cherche un shop',
                        'Je veux faire un guest dans un shop',
                        Icons.store,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildProposalTypeCard(
                        ProposalType.offeringGuest,
                        'J\'accueille un guest',
                        'Je propose mon shop pour accueillir',
                        Icons.person_add,
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Details() {
    return FadeTransition(
      opacity: _stepAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildStepCard(
              title: 'Détails de la proposition',
              icon: Icons.info,
              child: Column(
                children: [
                  // Titre
                  TextFormField(
                    controller: _titleController,
                    validator: (value) => 
                        value == null || value.isEmpty ? 'Le titre est obligatoire' : null,
                    decoration: _buildInputDecoration(
                      labelText: 'Titre de votre proposition',
                      hintText: 'Ex: Guest réalisme disponible été 2025',
                      prefixIcon: Icons.title,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Localisation
                  DropdownButtonFormField<String>(
                    value: _selectedLocation.isNotEmpty ? _selectedLocation : null,
                    validator: (value) => value == null ? 'Sélectionnez une ville' : null,
                    decoration: _buildInputDecoration(
                      labelText: 'Ville',
                      prefixIcon: Icons.location_city,
                    ),
                    items: _cities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectStartDate,
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date début',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _startDate != null 
                                          ? _formatDate(_startDate!)
                                          : 'Sélectionner',
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 14,
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
                          onTap: _selectEndDate,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.event, color: KipikTheme.rouge),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date fin',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _endDate != null 
                                          ? _formatDate(_endDate!)
                                          : 'Sélectionner',
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 14,
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
                  
                  const SizedBox(height: 16),
                  
                  // Dates flexibles
                  CheckboxListTile(
                    title: const Text(
                      'Dates flexibles',
                      style: TextStyle(fontFamily: 'Roboto'),
                    ),
                    subtitle: const Text(
                      'Je peux m\'adapter selon les disponibilités',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: _isFlexibleDates,
                    activeColor: KipikTheme.rouge,
                    onChanged: (value) {
                      setState(() {
                        _isFlexibleDates = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Styles
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Styles de tatouage',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tattooStyles.map((style) {
                      final isSelected = _selectedStyles.contains(style);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedStyles.remove(style);
                            } else {
                              _selectedStyles.add(style);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? KipikTheme.rouge : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? KipikTheme.rouge : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            style,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Terms() {
    return FadeTransition(
      opacity: _stepAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildStepCard(
              title: 'Conditions financières',
              icon: Icons.euro,
              child: Column(
                children: [
                  // Commission
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Commission proposée',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _commissionRate,
                          min: 10,
                          max: 50,
                          divisions: 8,
                          activeColor: KipikTheme.rouge,
                          label: '${_commissionRate.toInt()}%',
                          onChanged: (value) {
                            setState(() {
                              _commissionRate = value;
                            });
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: KipikTheme.rouge.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_commissionRate.toInt()}%',
                          style: TextStyle(
                            fontFamily: 'PermanentMarker',
                            fontSize: 16,
                            color: KipikTheme.rouge,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Hébergement
                  if (_proposalType == ProposalType.seekingShop) ...[
                    CheckboxListTile(
                      title: const Text(
                        'Hébergement souhaité',
                        style: TextStyle(fontFamily: 'Roboto'),
                      ),
                      subtitle: const Text(
                        'Je recherche un hébergement pendant mon guest',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: _accommodationRequired,
                      activeColor: KipikTheme.rouge,
                      onChanged: (value) {
                        setState(() {
                          _accommodationRequired = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ] else ...[
                    CheckboxListTile(
                      title: const Text(
                        'Hébergement offert',
                        style: TextStyle(fontFamily: 'Roboto'),
                      ),
                      subtitle: const Text(
                        'Je peux fournir un hébergement au guest',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: _accommodationOffered,
                      activeColor: KipikTheme.rouge,
                      onChanged: (value) {
                        setState(() {
                          _accommodationOffered = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Niveau d'expérience
                  DropdownButtonFormField<String>(
                    value: _experienceLevel,
                    decoration: _buildInputDecoration(
                      labelText: 'Niveau d\'expérience',
                      prefixIcon: Icons.star,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Débutant', child: Text('Débutant (< 2 ans)')),
                      DropdownMenuItem(value: 'Intermédiaire', child: Text('Intermédiaire (2-5 ans)')),
                      DropdownMenuItem(value: 'Confirmé', child: Text('Confirmé (5-10 ans)')),
                      DropdownMenuItem(value: 'Expert', child: Text('Expert (> 10 ans)')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _experienceLevel = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Récapitulatif
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
                        const Row(
                          children: [
                            Icon(Icons.summarize, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Récapitulatif',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        _buildSummaryRow('Commission', '${_commissionRate.toInt()}%'),
                        _buildSummaryRow('Hébergement', 
                          _proposalType == ProposalType.seekingShop 
                              ? (_accommodationRequired ? 'Demandé' : 'Non nécessaire')
                              : (_accommodationOffered ? 'Offert' : 'Non offert')),
                        _buildSummaryRow('Expérience', _experienceLevel),
                        if (_startDate != null && _endDate != null)
                          _buildSummaryRow('Durée', 
                            '${_endDate!.difference(_startDate!).inDays} jours'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Message() {
    return FadeTransition(
      opacity: _stepAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildStepCard(
              title: 'Message personnel',
              icon: Icons.message,
              child: Column(
                children: [
                  // Description générale
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    validator: (value) => 
                        value == null || value.isEmpty ? 'La description est obligatoire' : null,
                    decoration: _buildInputDecoration(
                      labelText: 'Description de votre proposition',
                      hintText: 'Présentez votre projet, vos attentes...',
                      prefixIcon: Icons.description,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Message personnalisé
                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: _buildInputDecoration(
                      labelText: 'Message personnel (optionnel)',
                      hintText: 'Pourquoi cette collaboration vous intéresse...',
                      prefixIcon: Icons.chat_bubble_outline,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Portfolio/références
                  TextFormField(
                    controller: _portfolioController,
                    decoration: _buildInputDecoration(
                      labelText: 'Liens portfolio/Instagram',
                      hintText: 'https://instagram.com/votre_compte',
                      prefixIcon: Icons.link,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Options d'envoi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.send, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Options d\'envoi',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        CheckboxListTile(
                          title: const Text(
                            'Proposer un appel vidéo',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                            ),
                          ),
                          value: true,
                          dense: true,
                          activeColor: KipikTheme.rouge,
                          onChanged: (value) {},
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        CheckboxListTile(
                          title: const Text(
                            'Notification de lecture',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                            ),
                          ),
                          value: true,
                          dense: true,
                          activeColor: KipikTheme.rouge,
                          onChanged: (value) {},
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text(
                  'Précédent',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : 
                  (_currentStep < 3 ? _nextStep : _submitProposal),
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _currentStep < 3 ? Icons.arrow_forward : Icons.send,
                      size: 18,
                    ),
              label: Text(
                _isLoading ? 'Envoi...' : 
                    (_currentStep < 3 ? 'Suivant' : 'Envoyer proposition'),
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
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
              Icon(icon, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildProposalTypeCard(
    ProposalType type,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _proposalType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _proposalType = type;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
          ) : null,
          color: isSelected ? null : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 16,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
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
  void _nextStep() {
    if (_currentStep < 3) {
      // Validation par étape
      bool canProceed = true;
      
      switch (_currentStep) {
        case 0:
          // Pas de validation spéciale pour l'étape 1
          break;
        case 1:
          canProceed = _titleController.text.isNotEmpty && 
                      _selectedLocation.isNotEmpty &&
                      _selectedStyles.isNotEmpty;
          break;
        case 2:
          // Validation des conditions déjà faite
          break;
        case 3:
          canProceed = _descriptionController.text.isNotEmpty;
          break;
      }
      
      if (canProceed) {
        setState(() {
          _currentStep++;
        });
        _stepController.reset();
        _stepController.forward();
      } else {
        _showValidationError();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _stepController.reset();
      _stepController.forward();
    }
  }

  void _submitProposal() async {
    if (!_formKey.currentState!.validate()) {
      _showValidationError();
      return;
    }
    
    setState(() => _isLoading = true);
    
    HapticFeedback.mediumImpact();
    
    try {
      // Simulation d'envoi
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _showSuccessDialog();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
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

  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veuillez remplir tous les champs obligatoires'),
        backgroundColor: Colors.red,
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
              'Proposition envoyée !',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre proposition a été envoyée. Vous recevrez une notification dès que la personne aura répondu.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Fermer dialog
                      Navigator.pop(context); // Retourner à marketplace
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                    ),
                    child: const Text(
                      'Retour',
                      style: TextStyle(fontFamily: 'Roboto'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Fermer dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GuestContractPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Voir contrats',
                      style: TextStyle(fontFamily: 'Roboto'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 7)),
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
        _startDate = picked;
        // Ajuster la date de fin si nécessaire
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 7));
        }
      });
    }
  }

  void _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? 
          (_startDate?.add(const Duration(days: 7)) ?? DateTime.now().add(const Duration(days: 14))),
      firstDate: _startDate ?? DateTime.now(),
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
        _endDate = picked;
      });
    }
  }

  // Helper methods
  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Type';
      case 1:
        return 'Détails';
      case 2:
        return 'Conditions';
      case 3:
        return 'Message';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    
    return '${date.day} ${months[date.month - 1]}';
  }
}