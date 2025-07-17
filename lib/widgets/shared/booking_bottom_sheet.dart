// lib/widgets/shared/booking_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/kipik_theme.dart';
import '../../models/flash/flash.dart';
import '../../models/flash/flash_booking.dart';
import '../../services/booking/flash_booking_service.dart';
import '../../services/auth/secure_auth_service.dart';

/// Bottom sheet sophistiqué pour la réservation de flashs
/// Gère le processus complet de sélection et validation
class BookingBottomSheet extends StatefulWidget {
  final Flash flash;
  final Function(FlashBooking booking)? onBookingCreated;
  final VoidCallback? onClose;

  const BookingBottomSheet({
    Key? key,
    required this.flash,
    this.onBookingCreated,
    this.onClose,
  }) : super(key: key);

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();

  /// Méthode statique pour afficher le bottom sheet
  static Future<FlashBooking?> show(
    BuildContext context,
    Flash flash,
  ) {
    return showModalBottomSheet<FlashBooking>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => BookingBottomSheet(
        flash: flash,
        onBookingCreated: (booking) => Navigator.of(context).pop(booking),
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _BookingBottomSheetState extends State<BookingBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  
  final PageController _pageController = PageController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Données de réservation
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String _selectedBodyPlacement = '';
  Map<String, dynamic> _customizations = {};
  
  final List<String> _availableTimeSlots = [
    '09:00', '10:00', '11:00', '14:00', 
    '15:00', '16:00', '17:00', '18:00'
  ];
  
  final List<String> _bodyPlacements = [
    'Avant-bras', 'Poignet', 'Cheville', 'Épaule', 
    'Dos', 'Torse', 'Cuisse', 'Mollet'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    
    _slideController.forward();
  }

  void _loadUserData() async {
    try {
      // TODO: Charger les données utilisateur sauvegardées
      // (téléphone, préférences, etc.)
    } catch (e) {
      print('Erreur chargement données utilisateur: $e');
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pageController.dispose();
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 200),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            minChildSize: 0.3,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHandle(),
                    _buildHeader(),
                    _buildProgressIndicator(),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _currentStep = index),
                        children: [
                          _buildDateTimeStep(scrollController),
                          _buildDetailsStep(scrollController),
                          _buildConfirmationStep(scrollController),
                        ],
                      ),
                    ),
                    _buildActionBar(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Image du flash
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.flash.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Infos flash
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.flash.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.flash.tattooArtistName,
                  style: TextStyle(
                    color: KipikTheme.rouge,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${widget.flash.effectivePrice.toInt()}€',
                      style: TextStyle(
                        color: KipikTheme.rouge,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.flash.discountedPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${widget.flash.price.toInt()}€',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Bouton fermer
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image,
        color: Colors.grey.shade600,
        size: 24,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive 
                    ? (isCompleted ? Colors.green : KipikTheme.rouge)
                    : Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateTimeStep(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisir une date et un créneau',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez votre créneau préféré',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Sélecteur de date
          _buildDateSelector(),
          
          const SizedBox(height: 24),
          
          // Sélecteur de créneaux
          if (_selectedDate != null)
            _buildTimeSlotSelector(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date souhaitée',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14, // 2 semaines
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index + 1));
              final isSelected = _selectedDate?.day == date.day &&
                                 _selectedDate?.month == date.month;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _selectedTimeSlot = null; // Reset time slot
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? KipikTheme.rouge : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? KipikTheme.rouge : Colors.grey.shade700,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getWeekday(date.weekday),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getMonth(date.month),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Créneau horaire',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableTimeSlots.map((timeSlot) {
            final isSelected = _selectedTimeSlot == timeSlot;
            final isAvailable = _isTimeSlotAvailable(timeSlot);
            
            return GestureDetector(
              onTap: isAvailable ? () {
                setState(() => _selectedTimeSlot = timeSlot);
                HapticFeedback.selectionClick();
              } : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? KipikTheme.rouge 
                      : isAvailable 
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? KipikTheme.rouge 
                        : isAvailable
                            ? Colors.grey.shade600
                            : Colors.grey.shade700,
                  ),
                ),
                child: Text(
                  timeSlot,
                  style: TextStyle(
                    color: isAvailable ? Colors.white : Colors.grey.shade500,
                    fontSize: 16,
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

  Widget _buildDetailsStep(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails de la réservation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personnalisez votre tatouage',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Emplacement corporel
          _buildBodyPlacementSelector(),
          
          const SizedBox(height: 24),
          
          // Notes spéciales
          _buildNotesInput(),
          
          const SizedBox(height: 24),
          
          // Téléphone
          _buildPhoneInput(),
          
          const SizedBox(height: 24),
          
          // Informations importantes
          _buildImportantInfo(),
        ],
      ),
    );
  }

  Widget _buildBodyPlacementSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emplacement souhaité',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _bodyPlacements.map((placement) {
            final isSelected = _selectedBodyPlacement == placement;
            
            return GestureDetector(
              onTap: () {
                setState(() => _selectedBodyPlacement = placement);
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? KipikTheme.rouge : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? KipikTheme.rouge : Colors.grey.shade600,
                  ),
                ),
                child: Text(
                  placement,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes spéciales (optionnel)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _notesController,
          maxLines: 3,
          maxLength: 200,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Modifications, préférences particulières...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: KipikTheme.rouge),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Téléphone',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '+33 6 12 34 56 78',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Icon(Icons.phone, color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: KipikTheme.rouge),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportantInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KipikTheme.rouge.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KipikTheme.rouge.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations importantes',
                style: TextStyle(
                  color: KipikTheme.rouge,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Un acompte de 30% sera demandé pour confirmer\n'
            '• Annulation possible jusqu\'à 48h avant le RDV\n'
            '• Pensez à bien hydrater votre peau\n'
            '• Évitez l\'alcool 24h avant la séance',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirmation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifiez les détails de votre réservation',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 32),
          
          _buildConfirmationSummary(),
        ],
      ),
    );
  }

  Widget _buildConfirmationSummary() {
    return Column(
      children: [
        // Flash info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flash sélectionné',
                style: TextStyle(
                  color: KipikTheme.rouge,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.flash.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.flash.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.flash.tattooArtistName,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.flash.effectivePrice.toInt()}€',
                    style: TextStyle(
                      color: KipikTheme.rouge,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Détails réservation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Détails de votre RDV',
                style: TextStyle(
                  color: KipikTheme.rouge,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildSummaryRow('Date', _formatSelectedDate()),
              _buildSummaryRow('Heure', _selectedTimeSlot ?? ''),
              _buildSummaryRow('Emplacement', _selectedBodyPlacement),
              if (_phoneController.text.isNotEmpty)
                _buildSummaryRow('Téléphone', _phoneController.text),
              if (_notesController.text.isNotEmpty)
                _buildSummaryRow('Notes', _notesController.text),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Paiement
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paiement',
                style: TextStyle(
                  color: KipikTheme.rouge,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildSummaryRow('Prix total', '${widget.flash.effectivePrice.toInt()}€'),
              _buildSummaryRow('Acompte (30%)', '${(widget.flash.effectivePrice * 0.3).toInt()}€'),
              _buildSummaryRow('Reste à payer', '${(widget.flash.effectivePrice * 0.7).toInt()}€'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          top: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Précédent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            
            if (_currentStep > 0) const SizedBox(width: 16),
            
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _getActionButtonText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getActionButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Continuer';
      case 1:
        return 'Confirmer';
      case 2:
        return 'Réserver maintenant';
      default:
        return 'Suivant';
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        HapticFeedback.lightImpact();
      }
    } else {
      _submitBooking();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_selectedDate == null) {
          _showErrorMessage('Veuillez sélectionner une date');
          return false;
        }
        if (_selectedTimeSlot == null) {
          _showErrorMessage('Veuillez sélectionner un créneau');
          return false;
        }
        return true;
      case 1:
        if (_selectedBodyPlacement.isEmpty) {
          _showErrorMessage('Veuillez sélectionner un emplacement');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _submitBooking() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final booking = await FlashBookingService.instance.requestBooking(
        flashId: widget.flash.id,
        clientId: currentUser['uid'],
        requestedDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        clientNotes: _notesController.text.trim(),
        clientPhone: _phoneController.text.trim(),
        customizations: {
          'bodyPlacement': _selectedBodyPlacement,
          ...(_customizations),
        },
      );

      HapticFeedback.heavyImpact();
      widget.onBookingCreated?.call(booking);
      
      _showSuccessMessage('Demande de réservation envoyée !');
    } catch (e) {
      _showErrorMessage('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isTimeSlotAvailable(String timeSlot) {
    // TODO: Vérifier la disponibilité réelle via l'API
    // Pour l'instant, on simule quelques créneaux indisponibles
    final random = DateTime.now().millisecond % 10;
    return random != 0; // 90% de disponibilité
  }

  String _formatSelectedDate() {
    if (_selectedDate == null) return '';
    return '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month - 1];
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}