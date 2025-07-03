// lib/widgets/payment/secure_payment_widget.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/auth/recaptcha_widget.dart';
import 'package:kipik_v5/utils/payment_security_helper.dart';
import 'package:kipik_v5/services/auth/captcha_manager.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class SecurePaymentWidget extends StatefulWidget {
  final String paymentType; // 'subscription', 'project', 'deposit'
  final double amount;
  final String? description;
  final Map<String, dynamic>? metadata;
  final Function(Map<String, dynamic> paymentResult) onPaymentSuccess;
  final Function(String error) onPaymentError;
  final String? projectId;
  final String? tattooistId;
  final String? planKey;
  final bool? promoMode;

  const SecurePaymentWidget({
    Key? key,
    required this.paymentType,
    required this.amount,
    required this.onPaymentSuccess,
    required this.onPaymentError,
    this.description,
    this.metadata,
    this.projectId,
    this.tattooistId,
    this.planKey,
    this.promoMode,
  }) : super(key: key);

  @override
  State<SecurePaymentWidget> createState() => _SecurePaymentWidgetState();
}

class _SecurePaymentWidgetState extends State<SecurePaymentWidget> {
  bool _isLoading = false;
  bool _captchaValidated = false;
  CaptchaResult? _captchaResult;
  PaymentValidationResult? _validationResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête du paiement
          _buildPaymentHeader(),
          
          const SizedBox(height: 20),
          
          // Détails du paiement
          _buildPaymentDetails(),
          
          const SizedBox(height: 20),
          
          // Section sécurité reCAPTCHA (OBLIGATOIRE pour paiements)
          _buildSecuritySection(),
          
          const SizedBox(height: 20),
          
          // Bouton de paiement sécurisé
          _buildSecurePaymentButton(),
          
          const SizedBox(height: 12),
          
          // Informations de sécurité
          _buildSecurityInfo(),
        ],
      ),
    );
  }

  Widget _buildPaymentHeader() {
    IconData icon;
    String title;
    Color color;

    switch (widget.paymentType) {
      case 'subscription':
        icon = Icons.card_membership;
        title = 'Abonnement KIPIK';
        color = Colors.purple;
        break;
      case 'project':
        icon = Icons.brush;
        title = 'Paiement Projet';
        color = Colors.blue;
        break;
      case 'deposit':
        icon = Icons.account_balance_wallet;
        title = 'Acompte Projet';
        color = Colors.green;
        break;
      default:
        icon = Icons.payment;
        title = 'Paiement';
        color = KipikTheme.rouge;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'PermanentMarker',
                ),
              ),
              if (widget.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Montant:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '€${widget.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: KipikTheme.rouge,
                  fontFamily: 'PermanentMarker',
                ),
              ),
            ],
          ),
          
          if (widget.paymentType == 'deposit') ...[
            const SizedBox(height: 8),
            Text(
              'Acompte de 30% requis',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Icons.security, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Paiement sécurisé par Stripe',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KipikTheme.rouge.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KipikTheme.rouge.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              Text(
                'Vérification de sécurité requise',
                style: TextStyle(
                  color: KipikTheme.rouge,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PermanentMarker',
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          Text(
            'Protection anti-fraude pour votre sécurité',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Widget reCAPTCHA avec score élevé requis pour paiements
          ReCaptchaWidget(
            action: 'payment',
            useInvisible: true,
            onValidated: (result) {
              setState(() {
                _captchaValidated = result.isValid && result.score >= 0.7;
                _captchaResult = result;
              });
              
              if (!_captchaValidated && result.score > 0) {
                _showLowSecurityWarning(result.score);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurePaymentButton() {
    bool canPay = _captchaValidated && !_isLoading;
    
    return ElevatedButton(
      onPressed: canPay ? _processSecurePayment : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canPay ? KipikTheme.rouge : Colors.grey[400],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: canPay ? 4 : 0,
      ),
      child: _isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Sécurisation en cours...'),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 20),
                const SizedBox(width: 8),
                Text(
                  canPay 
                      ? 'Payer €${widget.amount.toStringAsFixed(2)}'
                      : 'Vérification requise',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSecurityInfo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, color: Colors.grey[600], size: 16),
            const SizedBox(width: 8),
            Text(
              'Vos données bancaires ne transitent jamais par nos serveurs',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        
        if (_captchaResult != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getScoreColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getScoreColor().withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getScoreIcon(), color: _getScoreColor(), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Niveau sécurité: ${_getScoreText()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getScoreColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _getScoreColor() {
    if (_captchaResult == null) return Colors.grey;
    if (_captchaResult!.score >= 0.8) return Colors.green;
    if (_captchaResult!.score >= 0.5) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon() {
    if (_captchaResult == null) return Icons.help;
    if (_captchaResult!.score >= 0.8) return Icons.verified_user;
    if (_captchaResult!.score >= 0.5) return Icons.warning;
    return Icons.error;
  }

  String _getScoreText() {
    if (_captchaResult == null) return 'En attente';
    if (_captchaResult!.score >= 0.8) return 'Élevé';
    if (_captchaResult!.score >= 0.5) return 'Moyen';
    return 'Faible';
  }

  void _showLowSecurityWarning(double score) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Score de sécurité insuffisant pour le paiement (${(score * 100).round()}%). Un score de 70% minimum est requis.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _processSecurePayment() async {
    if (!_captchaValidated || _captchaResult == null) return;

    setState(() => _isLoading = true);

    try {
      // ÉTAPE 1: Validation sécurité AVANT Stripe
      print('🔐 Validation sécurité paiement...');
      final validation = await PaymentSecurityHelper.validatePaymentSecurity(
        paymentType: widget.paymentType,
        amount: widget.amount,
        metadata: widget.metadata,
      );

      if (!validation.isValid) {
        widget.onPaymentError(validation.error ?? 'Validation sécurité échouée');
        return;
      }

      _validationResult = validation;
      print('✅ Validation sécurité réussie - Score: ${(validation.captchaScore * 100).round()}%');

      // ÉTAPE 2: Traitement paiement selon le type
      Map<String, dynamic> paymentResult;

      switch (widget.paymentType) {
        case 'subscription':
          if (widget.planKey == null) {
            throw Exception('planKey requis pour paiement abonnement');
          }
          paymentResult = await PaymentSecurityHelper.processSecureSubscriptionPayment(
            planKey: widget.planKey!,
            promoMode: widget.promoMode ?? false,
            validation: validation,
          );
          break;

        case 'project':
          if (widget.projectId == null || widget.tattooistId == null) {
            throw Exception('projectId et tattooistId requis pour paiement projet');
          }
          paymentResult = await PaymentSecurityHelper.processSecureProjectPayment(
            projectId: widget.projectId!,
            amount: widget.amount,
            tattooistId: widget.tattooistId!,
            validation: validation,
            description: widget.description,
          );
          break;

        case 'deposit':
          if (widget.projectId == null || widget.tattooistId == null) {
            throw Exception('projectId et tattooistId requis pour acompte');
          }
          paymentResult = await PaymentSecurityHelper.processSecureDepositPayment(
            projectId: widget.projectId!,
            totalAmount: widget.amount,
            tattooistId: widget.tattooistId!,
            validation: validation,
          );
          break;

        default:
          throw Exception('Type de paiement non supporté: ${widget.paymentType}');
      }

      // ÉTAPE 3: Succès - Redirection vers Stripe
      print('🔄 Redirection vers Stripe...');
      widget.onPaymentSuccess(paymentResult);

    } catch (e) {
      print('❌ Erreur paiement sécurisé: $e');
      widget.onPaymentError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ✅ WIDGET HELPER pour intégration rapide dans vos pages

class QuickSecurePayment {
  /// Paiement abonnement rapide
  static Widget subscription({
    required String planKey,
    required double amount,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
    bool promoMode = false,
  }) {
    return SecurePaymentWidget(
      paymentType: 'subscription',
      amount: amount,
      planKey: planKey,
      promoMode: promoMode,
      description: 'Abonnement KIPIK Pro',
      onPaymentSuccess: onSuccess,
      onPaymentError: onError,
    );
  }

  /// Paiement projet rapide
  static Widget project({
    required String projectId,
    required String tattooistId,
    required double amount,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
    String? description,
  }) {
    return SecurePaymentWidget(
      paymentType: 'project',
      amount: amount,
      projectId: projectId,
      tattooistId: tattooistId,
      description: description ?? 'Paiement projet tatouage',
      onPaymentSuccess: onSuccess,
      onPaymentError: onError,
    );
  }

  /// Acompte rapide
  static Widget deposit({
    required String projectId,
    required String tattooistId,
    required double totalAmount,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) {
    final depositAmount = totalAmount * 0.3;
    return SecurePaymentWidget(
      paymentType: 'deposit',
      amount: depositAmount,
      projectId: projectId,
      tattooistId: tattooistId,
      description: 'Acompte projet (30%)',
      onPaymentSuccess: onSuccess,
      onPaymentError: onError,
    );
  }
}