// lib/pages/shared/booking/booking_flow_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/kipik_theme.dart';
import '../../../models/flash/flash.dart';
import '../../../models/flash/flash_booking.dart'; // ✅ Utilise votre modèle
import '../../../models/flash/flash_booking_status.dart'; // ✅ Import ajouté
import '../../../services/flash/flash_service.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart'; // ✅ Import correct

/// Page de workflow complet de réservation de flash (4 étapes)
class BookingFlowPage extends StatefulWidget {
  final Flash flash;
  final String? initialStep; // 'selection', 'validation', 'payment', 'confirmation'

  const BookingFlowPage({
    Key? key,
    required this.flash,
    this.initialStep,
  }) : super(key: key);

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends State<BookingFlowPage> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  int _currentStep = 0;
  bool _isLoading = false;

  // Données du booking
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String _notes = '';
  String _phone = '';
  FlashBooking? _pendingBooking;

  // Étapes du workflow
  final List<String> _stepTitles = [
    'Sélection créneau',
    'Validation',
    'Paiement acompte',
    'Confirmation'
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Initialiser l'étape si spécifiée
    if (widget.initialStep != null) {
      switch (widget.initialStep) {
        case 'validation':
          _currentStep = 1;
          break;
        case 'payment':
          _currentStep = 2;
          break;
        case 'confirmation':
          _currentStep = 3;
          break;
        default:
          _currentStep = 0;
      }
      _updateProgress();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    _progressController.animateTo((_currentStep + 1) / _stepTitles.length);
  }

  Future<void> _nextStep() async {
    if (_currentStep < _stepTitles.length - 1) {
      setState(() => _currentStep++);
      _updateProgress();
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _updateProgress();
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Réserver "${widget.flash.title}"',
        showBackButton: true,
        useProStyle: false, // Style particulier pour les clients
      ),
      body: Column(
        children: [
          // Barre de progression
          _buildProgressBar(),
          
          // Contenu des étapes
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSelectionStep(),
                _buildValidationStep(),
                _buildPaymentStep(),
                _buildConfirmationStep(),
              ],
            ),
          ),
          
          // Boutons navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Column(
        children: [
          // Titre étape courante
          Text(
            _stepTitles[_currentStep],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Barre de progression animée
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(3),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          
          // Indicateurs étapes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_stepTitles.length, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent 
                      ? KipikTheme.rouge 
                      : const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted 
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCompleted || isCurrent ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flash preview
          _buildFlashPreview(),
          const SizedBox(height: 32),
          
          // Sélection date
          _buildDateSelection(),
          const SizedBox(height: 24),
          
          // Sélection créneau
          if (_selectedDate != null) _buildTimeSlotSelection(),
          const SizedBox(height: 24),
          
          // Notes optionnelles
          _buildNotesSection(),
        ],
      ),
    );
  }

  Widget _buildFlashPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.flash.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: const Color(0xFF2A2A2A),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                ),
                const SizedBox(height: 4),
                Text(
                  widget.flash.tattooArtistName, // ✅ Corrigé : tattooArtistName au lieu de artistName
                  style: TextStyle(
                    color: KipikTheme.rouge,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: KipikTheme.rouge.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${widget.flash.price.toInt()}€', // ✅ Converti en int pour affichage
                    style: TextStyle(
                      color: KipikTheme.rouge,
                      fontWeight: FontWeight.bold,
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

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionnez une date',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
                  setState(() => _selectedDate = date);
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? KipikTheme.rouge : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? KipikTheme.rouge : const Color(0xFF2A2A2A),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date.weekday),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getMonthName(date.month),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
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

  Widget _buildTimeSlotSelection() {
    final availableSlots = _generateTimeSlots();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Créneaux disponibles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
                setState(() => _selectedTimeSlot = slot);
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? KipikTheme.rouge : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? KipikTheme.rouge : const Color(0xFF2A2A2A),
                  ),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (optionnel)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Précisions, questions, demandes spéciales...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: KipikTheme.rouge),
            ),
          ),
          onChanged: (value) => _notes = value,
        ),
      ],
    );
  }

  Widget _buildValidationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vérifiez votre demande',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Récapitulatif
          _buildBookingSummary(),
          const SizedBox(height: 32),
          
          // Contact
          _buildContactSection(),
          const SizedBox(height: 32),
          
          // Conditions
          _buildTermsSection(),
        ],
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif',
            style: TextStyle(
              color: KipikTheme.rouge,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Flash', widget.flash.title),
          _buildSummaryRow('Artiste', widget.flash.tattooArtistName), // ✅ Corrigé
          _buildSummaryRow('Date', _selectedDate != null 
              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
              : 'Non sélectionnée'),
          _buildSummaryRow('Heure', _selectedTimeSlot ?? 'Non sélectionnée'),
          _buildSummaryRow('Prix', '${widget.flash.price.toInt()}€'),
          if (_notes.isNotEmpty) _buildSummaryRow('Notes', _notes),
          const Divider(color: Color(0xFF2A2A2A)),
          _buildSummaryRow('Acompte à verser', '${(widget.flash.price * 0.3).toInt()}€',
              isHighlighted: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              style: TextStyle(
                color: isHighlighted ? KipikTheme.rouge : Colors.white,
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de téléphone',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '+33 6 12 34 56 78',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: KipikTheme.rouge),
            ),
          ),
          onChanged: (value) => _phone = value,
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              Text(
                'Conditions importantes',
                style: TextStyle(
                  color: KipikTheme.rouge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• L\'acompte de 30% sera débité immédiatement\n'
            '• Le tatoueur a 24h pour confirmer votre demande\n'
            '• En cas de refus, vous serez remboursé intégralement\n'
            '• Annulation possible jusqu\'à 48h avant le RDV',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Paiement de l\'acompte',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Montant
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KipikTheme.rouge),
            ),
            child: Column(
              children: [
                Text(
                  'Acompte à verser',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(widget.flash.price * 0.3).toInt()}€', // ✅ Acompte en int
                  style: TextStyle(
                    color: KipikTheme.rouge,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'sur ${widget.flash.price.toInt()}€ total', // ✅ Total en int
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Moyens de paiement
          _buildPaymentMethods(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Moyen de paiement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Carte bancaire
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: KipikTheme.rouge),
          ),
          child: Row(
            children: [
              Icon(Icons.credit_card, color: KipikTheme.rouge),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Carte bancaire',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Sécurité
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Paiement sécurisé par Stripe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
          ),
          const SizedBox(height: 32),
          
          const Text(
            'Demande envoyée !',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Votre demande de réservation a été transmise à ${widget.flash.tattooArtistName}.', // ✅ Corrigé
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Prochaines étapes
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prochaines étapes :',
                  style: TextStyle(
                    color: KipikTheme.rouge,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStepItem('1', 'Le tatoueur valide votre demande (24h max)'),
                _buildStepItem('2', 'Vous recevrez une notification de confirmation'),
                _buildStepItem('3', 'Un chat s\'ouvrira pour échanger avant le RDV'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/mes-rdv-flashs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KipikTheme.rouge,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Voir mes RDV',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: KipikTheme.rouge),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Accueil',
                    style: TextStyle(
                      color: KipikTheme.rouge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: KipikTheme.rouge,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0 && _currentStep < 3)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade600),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Retour',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          if (_currentStep > 0 && _currentStep < 3) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _getNextAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                      _getNextButtonText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextAction() {
    if (_isLoading) return null;
    
    switch (_currentStep) {
      case 0:
        return _canProceedFromSelection() ? _handleSelectionComplete : null;
      case 1:
        return _canProceedFromValidation() ? _handleValidationComplete : null;
      case 2:
        return _handlePaymentComplete;
      case 3:
        return null; // Dernière étape, pas de bouton suivant
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Continuer';
      case 1:
        return 'Procéder au paiement';
      case 2:
        return 'Payer ${(widget.flash.price * 0.3).toInt()}€'; // ✅ Acompte en int
      case 3:
        return 'Terminé';
      default:
        return 'Suivant';
    }
  }

  bool _canProceedFromSelection() {
    return _selectedDate != null && _selectedTimeSlot != null;
  }

  bool _canProceedFromValidation() {
    return _phone.isNotEmpty;
  }

  Future<void> _handleSelectionComplete() async {
    await _nextStep();
  }

  Future<void> _handleValidationComplete() async {
    await _nextStep();
  }

  Future<void> _handlePaymentComplete() async {
    setState(() => _isLoading = true);
    
    try {
      // Créer le booking avec votre modèle
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');
      
      final booking = FlashBooking(
        id: '',
        flashId: widget.flash.id,
        clientId: currentUser['uid'] ?? '',
        tattooArtistId: widget.flash.tattooArtistId, // ✅ Corrigé
        status: FlashBookingStatus.pending, // ✅ Utilise votre enum status
        requestedDate: DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          int.parse(_selectedTimeSlot!.split(':')[0]),
          int.parse(_selectedTimeSlot!.split(':')[1]),
        ),
        timeSlot: _selectedTimeSlot!,
        totalPrice: widget.flash.price,
        depositAmount: widget.flash.price * 0.3,
        clientNotes: _notes,
        clientPhone: _phone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Envoyer la demande
      await FlashService.instance.createBooking(booking);
      
      // Procéder au paiement (simulé pour la démo)
      await Future.delayed(const Duration(seconds: 2));
      
      await _nextStep();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _generateTimeSlots() {
    return [
      '09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00'
    ];
  }

  String _getDayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month - 1];
  }
}