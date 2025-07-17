// lib/pages/conventions/convention_booking_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/common/drawers/drawer_factory.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../models/convention.dart';

class ConventionBookingPage extends StatefulWidget {
  final String conventionId;
  final String? tattooerId;

  const ConventionBookingPage({
    Key? key,
    required this.conventionId,
    this.tattooerId,
  }) : super(key: key);

  @override
  State<ConventionBookingPage> createState() => _ConventionBookingPageState();
}

class _ConventionBookingPageState extends State<ConventionBookingPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  // Données convention mockées
  Convention? _convention;
  TattooerInfo? _selectedTattooer;
  List<TattooerInfo> _availableTattooers = [];
  
  // État réservation
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String _selectedService = 'Consultation';
  final List<String> _services = [
    'Consultation',
    'Petit tatouage (1-2h)',
    'Tatouage moyen (3-4h)',
    'Grand tatouage (5h+)',
    'Retouche',
  ];
  
  // Formulaire
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadConventionData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _loadConventionData() {
    // Simulation chargement données
    setState(() {
      _convention = Convention(
        id: widget.conventionId,
        title: 'Paris Tattoo Convention 2025',
        location: 'Paris Expo, Porte de Versailles',
        start: DateTime(2025, 8, 15),
        end: DateTime(2025, 8, 17),
        description: 'La plus grande convention de tatouage de France',
        imageUrl: 'https://example.com/paris-tattoo.jpg',
        isOpen: true,
        isPremium: true,
      );

      _availableTattooers = _generateTattooers();
      
      if (widget.tattooerId != null) {
        _selectedTattooer = _availableTattooers.firstWhere(
          (t) => t.id == widget.tattooerId,
          orElse: () => _availableTattooers.first,
        );
      }
    });
  }

  List<TattooerInfo> _generateTattooers() {
    return [
      TattooerInfo(
        id: 'tat1',
        name: 'Alex Martin',
        style: 'Réalisme',
        rating: 4.8,
        standNumber: 'A12',
        availableSlots: {
          DateTime(2025, 8, 15): ['10:00', '14:00', '16:30'],
          DateTime(2025, 8, 16): ['09:00', '11:00', '15:00'],
          DateTime(2025, 8, 17): ['10:30', '13:00'],
        },
        priceRange: '150-300€',
      ),
      TattooerInfo(
        id: 'tat2',
        name: 'Emma Dubois',
        style: 'Japonais',
        rating: 4.9,
        standNumber: 'B05',
        availableSlots: {
          DateTime(2025, 8, 15): ['11:00', '15:30'],
          DateTime(2025, 8, 16): ['10:00', '14:00', '17:00'],
          DateTime(2025, 8, 17): ['09:30', '12:00', '16:00'],
        },
        priceRange: '200-400€',
      ),
      TattooerInfo(
        id: 'tat3',
        name: 'Marco Silva',
        style: 'Géométrique',
        rating: 4.7,
        standNumber: 'C18',
        availableSlots: {
          DateTime(2025, 8, 15): ['13:00', '17:00'],
          DateTime(2025, 8, 16): ['09:30', '12:30', '16:30'],
          DateTime(2025, 8, 17): ['11:00', '14:30'],
        },
        priceRange: '100-250€',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: DrawerFactory.of(context),
      appBar: CustomAppBarKipik(
        title: 'Réserver un Créneau',
        subtitle: _convention?.title ?? 'Convention',
        showBackButton: true,
        showBurger: true,
        useProStyle: false,
      ),
      floatingActionButton: const TattooAssistantButton(),
      body: Stack(
        children: [
          // Background
          Image.asset(
            'assets/background_charbon.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Contenu principal
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildConventionHeader(),
                      const SizedBox(height: 24),
                      _buildTattooerSelection(),
                      const SizedBox(height: 24),
                      if (_selectedTattooer != null) ...[
                        _buildDateSelection(),
                        const SizedBox(height: 24),
                        if (_selectedDate != null) ...[
                          _buildTimeSlotSelection(),
                          const SizedBox(height: 24),
                        ],
                        _buildServiceSelection(),
                        const SizedBox(height: 24),
                        _buildContactForm(),
                        const SizedBox(height: 24),
                        _buildBookingButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConventionHeader() {
    if (_convention == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.black54],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KipikTheme.rouge.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _convention!.title,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: KipikTheme.rouge, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _convention!.location,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, color: KipikTheme.rouge, size: 16),
              const SizedBox(width: 8),
              Text(
                '${_convention!.start.day}/${_convention!.start.month}/${_convention!.start.year} - ${_convention!.end.day}/${_convention!.end.month}/${_convention!.end.year}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTattooerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir un Tatoueur',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availableTattooers.length,
          itemBuilder: (context, index) {
            final tattooer = _availableTattooers[index];
            final isSelected = _selectedTattooer?.id == tattooer.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? KipikTheme.rouge.withOpacity(0.2) : Colors.black54,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? KipikTheme.rouge : Colors.grey.shade700,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: KipikTheme.rouge.withOpacity(0.3),
                  child: Text(
                    tattooer.name.substring(0, 2),
                    style: const TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: Text(
                  tattooer.name,
                  style: const TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Style: ${tattooer.style} • Stand ${tattooer.standNumber}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (i) => Icon(
                            Icons.star,
                            size: 12,
                            color: i < tattooer.rating.floor() 
                                ? Colors.amber 
                                : Colors.grey,
                          )),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tattooer.rating.toString(),
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          tattooer.priceRange,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Colors.green.shade300,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: isSelected 
                    ? Icon(Icons.check_circle, color: KipikTheme.rouge)
                    : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                onTap: () {
                  setState(() {
                    _selectedTattooer = tattooer;
                    _selectedDate = null;
                    _selectedTimeSlot = null;
                  });
                  HapticFeedback.lightImpact();
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    final availableDates = _selectedTattooer!.availableSlots.keys.toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir une Date',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: availableDates.map((date) {
              final isSelected = _selectedDate == date;
              final dayName = _getDayName(date.weekday);
              final dayNumber = date.day;
              final monthName = _getMonthName(date.month);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _selectedTimeSlot = null;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  width: 100,
                  decoration: BoxDecoration(
                    color: isSelected ? KipikTheme.rouge : Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? KipikTheme.rouge : Colors.grey.shade700,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 24,
                          color: isSelected ? Colors.white : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthName,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
    final availableSlots = _selectedTattooer!.availableSlots[_selectedDate!] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir un Horaire',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableSlots.map((slot) {
            final isSelected = _selectedTimeSlot == slot;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeSlot = slot;
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? KipikTheme.rouge : Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? KipikTheme.rouge : Colors.grey.shade700,
                  ),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de Prestation',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedService,
            decoration: const InputDecoration(
              border: InputBorder.none,
              labelText: 'Sélectionner une prestation',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            dropdownColor: Colors.grey.shade800,
            style: const TextStyle(color: Colors.white),
            items: _services.map((service) {
              return DropdownMenuItem(
                value: service,
                child: Text(service),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedService = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de Contact',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _nameController,
          label: 'Nom complet',
          icon: Icons.person,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Veuillez entrer votre nom';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Veuillez entrer votre email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _phoneController,
          label: 'Téléphone',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Veuillez entrer votre téléphone';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _descriptionController,
          label: 'Description du projet (optionnel)',
          icon: Icons.description,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: KipikTheme.rouge),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildBookingButton() {
    final canBook = _selectedTattooer != null && 
                   _selectedDate != null && 
                   _selectedTimeSlot != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canBook ? _submitBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: KipikTheme.rouge,
          disabledBackgroundColor: Colors.grey.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          canBook ? 'Confirmer la Réservation' : 'Complétez la sélection',
          style: const TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _submitBooking() {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Réservation Confirmée !',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            color: KipikTheme.rouge,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre créneau a été réservé :',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildConfirmationRow('Tatoueur', _selectedTattooer!.name),
            _buildConfirmationRow('Date', '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
            _buildConfirmationRow('Heure', _selectedTimeSlot!),
            _buildConfirmationRow('Service', _selectedService),
            _buildConfirmationRow('Stand', _selectedTattooer!.standNumber),
            const SizedBox(height: 16),
            Text(
              'Un email de confirmation sera envoyé à ${_emailController.text}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Fermer',
              style: TextStyle(color: KipikTheme.rouge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }
}

// Modèle pour les tatoueurs
class TattooerInfo {
  final String id;
  final String name;
  final String style;
  final double rating;
  final String standNumber;
  final Map<DateTime, List<String>> availableSlots;
  final String priceRange;

  TattooerInfo({
    required this.id,
    required this.name,
    required this.style,
    required this.rating,
    required this.standNumber,
    required this.availableSlots,
    required this.priceRange,
  });
}