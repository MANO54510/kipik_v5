// lib/screens/subscription/widgets/break_even_calculator.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_subscription.dart';

class BreakEvenCalculator extends StatefulWidget {
  final SubscriptionType currentType;
  final SubscriptionType targetType;
  final VoidCallback? onUpgradeRecommended;
  final bool showFullVersion;

  const BreakEvenCalculator({
    super.key,
    required this.currentType,
    required this.targetType,
    this.onUpgradeRecommended,
    this.showFullVersion = false,
  });

  @override
  State<BreakEvenCalculator> createState() => _BreakEvenCalculatorState();
}

class _BreakEvenCalculatorState extends State<BreakEvenCalculator>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  double _monthlyCA = 5000.0;
  bool _isCalculated = false;
  
  // Résultats calculés
  double _breakEvenPoint = 0;
  double _monthlySavings = 0;
  double _yearlySavings = 0;
  bool _isRecommended = false;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _calculate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _calculate() {
    final priceDiff = widget.targetType.monthlyPrice - widget.currentType.monthlyPrice;
    final commissionDiff = widget.currentType.commissionRate - widget.targetType.commissionRate;
    
    _breakEvenPoint = priceDiff / commissionDiff;
    _monthlySavings = (_monthlyCA * commissionDiff) - priceDiff;
    _yearlySavings = _monthlySavings * 12;
    _isRecommended = _monthlyCA >= _breakEvenPoint;
    _isCalculated = true;
    
    setState(() {});
    
    // Animation pour recommandation positive
    if (_isRecommended) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
    
    // Vibration tactile si recommandé
    if (_isRecommended) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showFullVersion) {
      return _buildCompactVersion();
    }
    return _buildFullVersion();
  }

  Widget _buildCompactVersion() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRecommended 
              ? Colors.green.withOpacity(0.6)
              : Colors.orange.withOpacity(0.4),
          width: _isRecommended ? 2 : 1,
        ),
        boxShadow: _isRecommended ? [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecommended ? _pulseAnimation.value : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildCAInput(),
                  const SizedBox(height: 16),
                  _buildResult(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullVersion() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRecommended 
              ? Colors.green.withOpacity(0.6)
              : Colors.grey.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFullHeader(),
          const SizedBox(height: 24),
          _buildDetailedCAInput(),
          const SizedBox(height: 24),
          _buildCalculationBreakdown(),
          const SizedBox(height: 24),
          _buildRecommendationSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.targetType.subscriptionColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calculate,
            color: widget.targetType.subscriptionColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculateur Premium',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Standard → Premium rentable ?',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (_isRecommended)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '✅ RENTABLE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFullHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.targetType.subscriptionColor.withOpacity(0.8),
                widget.targetType.subscriptionColor,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.trending_up,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calculateur de Rentabilité Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Découvrez si Premium est rentable pour votre business',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCAInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre CA mensuel: ${_monthlyCA.toStringAsFixed(0)}€',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.targetType.subscriptionColor,
            thumbColor: widget.targetType.subscriptionColor,
            overlayColor: widget.targetType.subscriptionColor.withOpacity(0.2),
            inactiveTrackColor: Colors.grey[600],
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: _monthlyCA,
            min: 1000,
            max: 20000,
            divisions: 38,
            onChanged: (value) {
              setState(() => _monthlyCA = value);
              _calculate();
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1K€', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Text('20K€', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedCAInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💰 Votre chiffre d\'affaires mensuel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _monthlyCA.toInt().toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    suffixText: '€/mois',
                    suffixStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.targetType.subscriptionColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                  ),
                  onChanged: (value) {
                    final newValue = double.tryParse(value) ?? 0;
                    setState(() => _monthlyCA = newValue);
                    _calculate();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  _buildQuickButton('2K', 2000),
                  const SizedBox(height: 8),
                  _buildQuickButton('5K', 5000),
                  const SizedBox(height: 8),
                  _buildQuickButton('10K', 10000),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          _buildCAInput(),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String label, double value) {
    final isSelected = _monthlyCA == value;
    
    return GestureDetector(
      onTap: () {
        setState(() => _monthlyCA = value);
        _calculate();
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? widget.targetType.subscriptionColor
              : Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isRecommended 
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isRecommended 
              ? Colors.green.withOpacity(0.4)
              : Colors.orange.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _isRecommended ? Icons.trending_up : Icons.schedule,
                color: _isRecommended ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isRecommended 
                      ? '✅ Premium RENTABLE dès maintenant !'
                      : '⏱️ Premium rentable à ${_breakEvenPoint.toStringAsFixed(0)}€ CA/mois',
                  style: TextStyle(
                    color: _isRecommended ? Colors.green : Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          if (_isRecommended) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💰 Économies avec Premium:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${_monthlySavings.toStringAsFixed(0)}€/mois',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '+${_yearlySavings.toStringAsFixed(0)}€/an',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (widget.onUpgradeRecommended != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onUpgradeRecommended!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '🚀 Passer à Premium maintenant',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCalculationBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Détail des calculs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildCalculationRow(
            'Abonnement Standard',
            '${widget.currentType.monthlyPrice.toInt()}€/mois',
            Colors.grey[400]!,
          ),
          _buildCalculationRow(
            'Commission Standard (2%)',
            '${(_monthlyCA * widget.currentType.commissionRate).toStringAsFixed(0)}€/mois',
            Colors.grey[400]!,
          ),
          _buildCalculationRow(
            'Total Standard',
            '${(widget.currentType.monthlyPrice + (_monthlyCA * widget.currentType.commissionRate)).toStringAsFixed(0)}€/mois',
            Colors.orange,
            isBold: true,
          ),
          
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey[600]),
          const SizedBox(height: 12),
          
          _buildCalculationRow(
            'Abonnement Premium',
            '${widget.targetType.monthlyPrice.toInt()}€/mois',
            Colors.grey[400]!,
          ),
          _buildCalculationRow(
            'Commission Premium (1%)',
            '${(_monthlyCA * widget.targetType.commissionRate).toStringAsFixed(0)}€/mois',
            Colors.grey[400]!,
          ),
          _buildCalculationRow(
            'Total Premium',
            '${(widget.targetType.monthlyPrice + (_monthlyCA * widget.targetType.commissionRate)).toStringAsFixed(0)}€/mois',
            widget.targetType.subscriptionColor,
            isBold: true,
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isRecommended 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isRecommended 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Différence mensuelle:',
                  style: TextStyle(
                    color: _isRecommended ? Colors.green : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_monthlySavings >= 0 ? "+" : ""}${_monthlySavings.toStringAsFixed(0)}€',
                  style: TextStyle(
                    color: _isRecommended ? Colors.green : Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRecommended ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isRecommended ? [
                  Colors.green.withOpacity(0.8),
                  Colors.green,
                ] : [
                  Colors.orange.withOpacity(0.8),
                  Colors.orange,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (_isRecommended ? Colors.green : Colors.orange).withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  _isRecommended ? Icons.check_circle : Icons.schedule,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  _isRecommended 
                      ? 'Premium recommandé dès maintenant !'
                      : 'Premium sera rentable plus tard',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isRecommended
                      ? 'Vous économiserez ${_yearlySavings.toStringAsFixed(0)}€ par an'
                      : 'À partir de ${_breakEvenPoint.toStringAsFixed(0)}€ de CA mensuel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (_isRecommended && widget.onUpgradeRecommended != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onUpgradeRecommended!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '🚀 Upgrader vers Premium',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}