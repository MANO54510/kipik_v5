// lib/screens/payment/fractional_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/models/user_subscription.dart';
import 'package:kipik_v5/models/payment_models.dart';
import 'package:kipik_v5/services/payment/firebase_payment_service.dart';
import 'package:kipik_v5/screens/payment/fractional_payment_confirmation_screen.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class FractionalPaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String projectId;
  final String artistId;
  final SubscriptionType artistSubscriptionType;
  final String projectTitle;
  final String? projectImageUrl;

  const FractionalPaymentScreen({
    super.key,
    required this.totalAmount,
    required this.projectId,
    required this.artistId,
    required this.artistSubscriptionType,
    required this.projectTitle,
    this.projectImageUrl,
  });

  @override
  State<FractionalPaymentScreen> createState() => _FractionalPaymentScreenState();
}

class _FractionalPaymentScreenState extends State<FractionalPaymentScreen> {
  final _paymentService = FirebasePaymentService.instance;
  
  FractionalPaymentOption? _selectedOption;
  List<FractionalPaymentOption> _availableOptions = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentOptions();
  }

  Future<void> _loadPaymentOptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _availableOptions = await _paymentService.getAvailableFractionalOptions(
        artistId: widget.artistId,
        totalAmount: widget.totalAmount,
      );
      
      // Sélectionner l'option 2x par défaut si disponible
      if (_availableOptions.isNotEmpty) {
        _selectedOption = _availableOptions.firstWhere(
          (option) => option.installments == 2,
          orElse: () => _availableOptions.first,
        );
      }
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des options: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildPaymentContent(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0B),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Paiement en plusieurs fois',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'PermanentMarker',
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: KipikTheme.rouge),
          SizedBox(height: 16),
          Text(
            'Chargement des options de paiement...',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPaymentOptions,
              style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
              child: Text('Réessayer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProjectHeader(),
          SizedBox(height: 24),
          _buildAmountSummary(),
          SizedBox(height: 32),
          _buildPaymentOptions(),
          SizedBox(height: 32),
          if (_selectedOption != null) _buildPaymentSchedule(),
          SizedBox(height: 32),
          _buildSecurityInfo(),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Image du projet ou placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KipikTheme.rouge.withOpacity(0.3)),
            ),
            child: widget.projectImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.projectImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.palette,
                    color: KipikTheme.rouge,
                    size: 30,
                  ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.projectTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Projet tatouage',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.artistSubscriptionType.displayName,
              style: TextStyle(
                color: KipikTheme.rouge,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSummary() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0A),
            KipikTheme.rouge.withOpacity(0.1),
            Color(0xFF0A0A0A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KipikTheme.rouge.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Montant total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.totalAmount.toStringAsFixed(2)}€',
                style: TextStyle(
                  color: KipikTheme.rouge,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PermanentMarker',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paiement sécurisé par SEPA. Aucun frais supplémentaire.',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
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

  Widget _buildPaymentOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💳 Choisissez votre plan de paiement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'PermanentMarker',
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Divisez votre paiement selon vos préférences',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 20),
        
        if (_availableOptions.isEmpty)
          _buildNoOptionsMessage()
        else
          ..._availableOptions.map((option) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _buildPaymentOptionCard(option),
          )).toList(),
      ],
    );
  }

  Widget _buildNoOptionsMessage() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.block, color: Colors.orange, size: 48),
          SizedBox(height: 12),
          Text(
            'Paiement fractionné non disponible',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ce tatoueur n\'a pas activé le paiement en plusieurs fois ou le montant minimum n\'est pas atteint.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionCard(FractionalPaymentOption option) {
    final isSelected = _selectedOption?.installments == option.installments;
    final installmentAmount = option.installmentAmount;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedOption = option),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? KipikTheme.rouge.withOpacity(0.1) : Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? KipikTheme.rouge : Colors.grey.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: KipikTheme.rouge.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ] : null,
          ),
          child: Row(
            children: [
              // Radio button
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? KipikTheme.rouge : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: KipikTheme.rouge,
                          ),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 16),
              
              // Icône
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isSelected ? KipikTheme.rouge : Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getOptionIcon(option.installments),
                  color: isSelected ? KipikTheme.rouge : Colors.grey,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${option.installments}x ${installmentAmount.toStringAsFixed(2)}€',
                      style: TextStyle(
                        color: isSelected ? KipikTheme.rouge : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Paiement en ${option.installments} fois',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    if (option.installments > 2) ...[
                      SizedBox(height: 4),
                      Text(
                        'Premier paiement immédiat',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Badge recommandé
              if (option.installments == 2)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'POPULAIRE',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSchedule() {
    final option = _selectedOption!;
    final schedules = option.paymentSchedule;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 Calendrier de paiement',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          ...schedules.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;
            final isFirst = index == 0;
            
            return Padding(
              padding: EdgeInsets.only(bottom: index < schedules.length - 1 ? 12 : 0),
              child: Row(
                children: [
                  // Timeline
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isFirst ? KipikTheme.rouge : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (index < schedules.length - 1)
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                    ],
                  ),
                  SizedBox(width: 16),
                  
                  // Informations
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isFirst ? 'Aujourd\'hui' : _formatDate(schedule.dueDate),
                                style: TextStyle(
                                  color: isFirst ? KipikTheme.rouge : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                isFirst ? 'Paiement immédiat' : 'Prélèvement automatique',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${schedule.amount.toStringAsFixed(2)}€',
                            style: TextStyle(
                              color: isFirst ? KipikTheme.rouge : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Text(
                'Paiement 100% sécurisé',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _buildSecurityItem(
            Icons.verified_user,
            'Chiffrement bancaire',
            'Vos données sont protégées par un chiffrement de niveau bancaire',
          ),
          SizedBox(height: 12),
          _buildSecurityItem(
            Icons.account_balance,
            'Prélèvement SEPA',
            'Prélèvements automatiques sécurisés conformes à la réglementation européenne',
          ),
          SizedBox(height: 12),
          _buildSecurityItem(
            Icons.cancel,
            'Annulation facile',
            'Possibilité d\'annuler ou modifier vos prélèvements à tout moment',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomActions() {
    if (_isLoading || _availableOptions.isEmpty) return null;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedOption != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Premier paiement:',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${_selectedOption!.paymentSchedule.first.amount.toStringAsFixed(2)}€',
                    style: TextStyle(
                      color: KipikTheme.rouge,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedOption != null ? KipikTheme.rouge : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _selectedOption != null && !_isProcessing
                    ? _processPayment
                    : null,
                child: _isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _selectedOption != null
                            ? 'Confirmer le paiement fractionné'
                            : 'Sélectionnez une option',
                        style: TextStyle(
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

  IconData _getOptionIcon(int installments) {
    switch (installments) {
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      case 4:
        return Icons.looks_4;
      default:
        return Icons.payment;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  Future<void> _processPayment() async {
    if (_selectedOption == null) return;
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _paymentService.createFractionalPayment(
        projectId: widget.projectId,
        artistId: widget.artistId,
        totalAmount: widget.totalAmount,
        paymentOption: _selectedOption!,
      );

      if (result.success) {
        // Navigation vers confirmation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FractionalPaymentConfirmationScreen(
              paymentResult: result,
              selectedOption: _selectedOption!,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Erreur lors du paiement';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur technique: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

// Extension pour les couleurs des types d'abonnement
extension SubscriptionTypeColors on SubscriptionType {
  Color get primaryColor {
    switch (this) {
      case SubscriptionType.free:
        return Colors.grey;
      case SubscriptionType.standard:
        return const Color(0xFF10B981);
      case SubscriptionType.premium:
        return const Color(0xFF6366F1);
      case SubscriptionType.enterprise:
        return const Color(0xFF8B5CF6);
    }
  }
}