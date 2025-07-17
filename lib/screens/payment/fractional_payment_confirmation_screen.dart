// lib/screens/payment/fractional_payment_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/models/payment_models.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class FractionalPaymentConfirmationScreen extends StatelessWidget {
  final PaymentResult paymentResult;
  final FractionalPaymentOption selectedOption;

  const FractionalPaymentConfirmationScreen({
    super.key,
    required this.paymentResult,
    required this.selectedOption,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0B),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text(
          'Paiement confirmé',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PermanentMarker',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            _buildSuccessHeader(),
            SizedBox(height: 32),
            _buildPaymentSummary(),
            SizedBox(height: 24),
            _buildPaymentSchedule(),
            SizedBox(height: 24),
            _buildNextSteps(),
            SizedBox(height: 32),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.green.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 40,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Paiement confirmé !',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'PermanentMarker',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Votre paiement fractionné a été configuré avec succès',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: EdgeInsets.all(24),
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
              Icon(Icons.receipt, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Text(
                'Résumé du paiement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          _buildSummaryRow('Montant total', '${paymentResult.totalAmount.toStringAsFixed(2)}€'),
          _buildSummaryRow('Nombre de paiements', '${selectedOption.installments}x'),
          _buildSummaryRow('Montant par paiement', '${selectedOption.installmentAmount.toStringAsFixed(2)}€'),
          _buildSummaryRow('Premier paiement', 'Aujourd\'hui'),
          
          Divider(color: Colors.grey.withOpacity(0.3), height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Référence:',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              Text(
                paymentResult.transactionId.substring(0, 8).toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSchedule() {
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
            '📅 Vos prochains paiements',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          ...selectedOption.paymentSchedule.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;
            final isPaid = index == 0; // Premier paiement déjà effectué
            
            return Padding(
              padding: EdgeInsets.only(bottom: index < selectedOption.paymentSchedule.length - 1 ? 12 : 0),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.withOpacity(0.1) : Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPaid ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isPaid
                            ? Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPaid ? 'Payé aujourd\'hui' : _formatDate(schedule.dueDate),
                            style: TextStyle(
                              color: isPaid ? Colors.green : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            isPaid ? 'Paiement effectué' : 'Prélèvement automatique',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Text(
                      '${schedule.amount.toStringAsFixed(2)}€',
                      style: TextStyle(
                        color: isPaid ? Colors.green : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                'Prochaines étapes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _buildNextStepItem(
            Icons.email,
            'Confirmation par email',
            'Vous recevrez un email de confirmation avec tous les détails',
          ),
          SizedBox(height: 12),
          _buildNextStepItem(
            Icons.calendar_today,
            'Prélèvements automatiques',
            'Les paiements suivants seront prélevés automatiquement aux dates prévues',
          ),
          SizedBox(height: 12),
          _buildNextStepItem(
            Icons.notifications,
            'Rappels avant prélèvement',
            'Vous serez prévenu 2 jours avant chaque prélèvement',
          ),
          SizedBox(height: 12),
          _buildNextStepItem(
            Icons.palette,
            'Rendez-vous tatouage',
            'Votre tatoueur vous contactera pour planifier les séances',
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
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

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text(
              'Retour à l\'accueil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () => _sharePaymentDetails(context),
            child: Text(
              'Partager les détails',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  void _sharePaymentDetails(BuildContext context) {
    // TODO: Implémenter le partage des détails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage des détails - À implémenter'),
        backgroundColor: KipikTheme.rouge,
      ),
    );
  }
}