// lib/screens/payment/sepa_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kipik_v5/models/payment_models.dart';
import 'package:kipik_v5/services/payment/firebase_payment_service.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class SepaManagementScreen extends StatefulWidget {
  const SepaManagementScreen({super.key});

  @override
  State<SepaManagementScreen> createState() => _SepaManagementScreenState();
}

class _SepaManagementScreenState extends State<SepaManagementScreen> {
  final _paymentService = FirebasePaymentService.instance;
  final _ibanController = TextEditingController();
  final _bicController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  SepaMandate? _currentMandate;
  List<SepaMandate> _mandateHistory = [];
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isValidating = false;
  String? _errorMessage;
  Map<String, dynamic>? _ibanValidation;
  
  // Nouvelles données critiques
  Map<String, dynamic>? _revocationRisks;
  bool _isCheckingRisks = false;

  @override
  void initState() {
    super.initState();
    _loadSepaData();
  }

  @override
  void dispose() {
    _ibanController.dispose();
    _bicController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSepaData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentMandate = await _paymentService.getCurrentSepaMandate();
      _mandateHistory = await _paymentService.getSepaHistory();
      
      if (_currentMandate != null) {
        await _loadRevocationRisks();
      }
      
    } catch (e) {
      _errorMessage = 'Erreur de chargement: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRevocationRisks() async {
    if (_currentMandate == null) return;
    
    try {
      final fractionalPayments = await _paymentService.getUserFractionalPayments();
      final activeFractionals = fractionalPayments.where((payment) => 
        payment['status'] == 'active' || payment['status'] == 'processing'
      ).toList();
      
      final accountStatus = await _paymentService.getAccountStatus();
      final hasActiveSubscription = accountStatus?['canReceivePayments'] == true;
      
      _revocationRisks = {
        'activeFractionalPayments': activeFractionals.length,
        'totalAmountAtRisk': activeFractionals.fold<double>(0, 
          (sum, payment) => sum + (payment['remainingAmount'] ?? 0.0)),
        'hasActiveSubscription': hasActiveSubscription,
        'subscriptionRisk': hasActiveSubscription ? 'suspension' : 'none',
        'clientsAffected': activeFractionals.map((p) => p['userId']).toSet().length,
      };
      
    } catch (e) {
      print('Erreur chargement risques: $e');
      _revocationRisks = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _buildContent(),
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
        '🏦 Gestion SEPA',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'PermanentMarker',
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadSepaData,
        ),
      ],
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
            'Chargement des informations SEPA...',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadSepaData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) _buildErrorBanner(),
            if (_errorMessage != null) SizedBox(height: 16),
            
            _buildCurrentMandateCard(),
            SizedBox(height: 24),
            
            if (_currentMandate == null) ...[
              _buildCreateMandateForm(),
              SizedBox(height: 24),
            ] else ...[
              _buildRevocationRisksCard(),
              SizedBox(height: 24),
            ],
            
            _buildBenefitsCard(),
            SizedBox(height: 24),
            
            if (_mandateHistory.isNotEmpty) ...[
              _buildHistoryCard(),
              SizedBox(height: 24),
            ],
            
            _buildSecurityInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMandateCard() {
    if (_currentMandate == null) {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.account_balance, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text(
              'Aucun mandat SEPA configuré',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Configurez un mandat SEPA pour recevoir les paiements fractionnés de vos clients',
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

    final mandate = _currentMandate!;
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.8),
            Colors.green,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mandat SEPA actif',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: _handleMandateAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'modify',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'revoke',
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Révoquer'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info),
                        SizedBox(width: 8),
                        Text('Détails'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          
          _buildMandateInfo('Titulaire', mandate.accountHolderName),
          SizedBox(height: 12),
          _buildMandateInfo('IBAN', mandate.maskedIban),
          SizedBox(height: 12),
          _buildMandateInfo('BIC', mandate.bic),
          SizedBox(height: 12),
          _buildMandateInfo('Référence', mandate.mandateId.substring(0, 8).toUpperCase()),
          
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Créé le ${_formatDate(mandate.createdAt)}',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMandateInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateMandateForm() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💳 Configurer un mandat SEPA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'PermanentMarker',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ajoutez vos informations bancaires pour recevoir les paiements',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            
            _buildFormField(
              controller: _ibanController,
              label: 'IBAN',
              hint: 'FR76 3000 6000 0112 3456 7890 189',
              validator: _validateIban,
              onChanged: _onIbanChanged,
              suffixIcon: _isValidating
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _ibanValidation != null
                      ? Icon(
                          _ibanValidation!['valid'] ? Icons.check : Icons.error,
                          color: _ibanValidation!['valid'] ? Colors.green : Colors.red,
                        )
                      : null,
            ),
            
            if (_ibanValidation != null && _ibanValidation!['valid']) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✅ ${_ibanValidation!['bankName'] ?? 'IBAN valide'}',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            ],
            
            SizedBox(height: 16),
            
            _buildFormField(
              controller: _bicController,
              label: 'BIC/SWIFT',
              hint: 'BNPAFRPP',
              validator: _validateBic,
            ),
            
            SizedBox(height: 16),
            
            _buildFormField(
              controller: _nameController,
              label: 'Nom du titulaire',
              hint: 'Jean Dupont',
              validator: _validateName,
            ),
            
            SizedBox(height: 24),
            
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
                onPressed: _isCreating ? null : _createMandate,
                child: _isCreating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Créer le mandat SEPA',
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Color(0xFF0F172A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: KipikTheme.rouge),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevocationRisksCard() {
    if (_revocationRisks == null) return SizedBox.shrink();
    
    final risks = _revocationRisks!;
    final activeFractionals = risks['activeFractionalPayments'] ?? 0;
    final amountAtRisk = risks['totalAmountAtRisk'] ?? 0.0;
    final hasSubscription = risks['hasActiveSubscription'] ?? false;
    final clientsAffected = risks['clientsAffected'] ?? 0;
    
    final hasHighRisk = activeFractionals > 0 || hasSubscription;
    final riskColor = hasHighRisk ? Colors.red : Colors.orange;
    final riskLevel = hasHighRisk ? 'ÉLEVÉ' : 'MODÉRÉ';
    
    if (!hasHighRisk && activeFractionals == 0) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: riskColor, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ Risques de révocation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'RISQUE $riskLevel',
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          if (activeFractionals > 0) ...[
            _buildRiskItem(
              Icons.payment,
              'Paiements fractionnés actifs',
              '$activeFractionals paiement(s) en cours',
              'Arrêt immédiat des prélèvements • $clientsAffected client(s) affecté(s)',
              riskColor,
            ),
            SizedBox(height: 12),
          ],
          
          if (amountAtRisk > 0) ...[
            _buildRiskItem(
              Icons.euro,
              'Montant à risque',
              '${amountAtRisk.toStringAsFixed(2)}€',
              'Échéances non encaissées • Perte de revenus',
              riskColor,
            ),
            SizedBox(height: 12),
          ],
          
          if (hasSubscription) ...[
            _buildRiskItem(
              Icons.block,
              'Abonnement KIPIK',
              'Suspension du compte',
              'Plus de prélèvement mensuel • Désactivation des fonctionnalités',
              Colors.red,
            ),
            SizedBox(height: 16),
          ],
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Actions recommandées',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Modifier le mandat au lieu de le révoquer\n'
                  '• Attendre la fin des paiements fractionnés\n'
                  '• Créer un nouveau mandat avant révocation',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskItem(IconData icon, String title, String value, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsCard() {
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
              Icon(Icons.star, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                'Avantages du mandat SEPA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _buildBenefitItem(
            Icons.payments,
            'Paiements fractionnés',
            'Permettez à vos clients de payer en 2, 3 ou 4 fois',
          ),
          SizedBox(height: 12),
          _buildBenefitItem(
            Icons.schedule,
            'Prélèvements automatiques',
            'Recevez vos paiements automatiquement aux dates prévues',
          ),
          SizedBox(height: 12),
          _buildBenefitItem(
            Icons.security,
            'Sécurisé et réglementé',
            'Conforme aux normes bancaires européennes SEPA',
          ),
          SizedBox(height: 12),
          _buildBenefitItem(
            Icons.trending_up,
            'Augmentez vos ventes',
            'Facilitez l\'achat pour vos clients avec des paiements étalés',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
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

  Widget _buildHistoryCard() {
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
            '📋 Historique des mandats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          ..._mandateHistory.map((mandate) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _buildHistoryItem(mandate),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(SepaMandate mandate) {
    final isActive = mandate.status == SepaMandateStatus.active;
    final statusColor = isActive ? Colors.green : Colors.orange;
    final statusText = isActive ? 'Actif' : 'Révoqué';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mandate.maskedIban,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  mandate.accountHolderName,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
                'Sécurité et confidentialité',
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
            Icons.lock,
            'Données chiffrées',
            'Vos informations bancaires sont chiffrées et sécurisées',
          ),
          SizedBox(height: 12),
          _buildSecurityItem(
            Icons.verified_user,
            'Conformité RGPD',
            'Traitement des données conforme au RGPD européen',
          ),
          SizedBox(height: 12),
          _buildSecurityItem(
            Icons.account_balance,
            'Réglementation bancaire',
            'Respect des normes SEPA et de la DSP2',
          ),
          SizedBox(height: 12),
          _buildSecurityItem(
            Icons.history,
            'Révocation facile',
            'Possibilité de révoquer le mandat à tout moment',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green, size: 16),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== VALIDATIONS =====

  String? _validateIban(String? value) {
    if (value == null || value.isEmpty) {
      return 'IBAN requis';
    }
    
    final cleanIban = value.replaceAll(' ', '').toUpperCase();
    if (!PaymentUtils.isValidIban(cleanIban)) {
      return 'IBAN invalide';
    }
    
    return null;
  }

  String? _validateBic(String? value) {
    if (value == null || value.isEmpty) {
      return 'BIC requis';
    }
    
    if (value.length < 8 || value.length > 11) {
      return 'BIC invalide (8-11 caractères)';
    }
    
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nom requis';
    }
    
    if (value.length < 2) {
      return 'Nom trop court';
    }
    
    return null;
  }

  // ===== ACTIONS =====

  void _onIbanChanged(String value) {
    final cleanIban = value.replaceAll(' ', '').toUpperCase();
    
    final formatted = PaymentUtils.formatIban(cleanIban);
    if (formatted != value) {
      _ibanController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    
    if (cleanIban.length >= 15) {
      _validateIbanWithApi(cleanIban);
    } else {
      setState(() {
        _ibanValidation = null;
      });
    }
  }

  Future<void> _validateIbanWithApi(String iban) async {
    setState(() {
      _isValidating = true;
    });

    try {
      final validation = await _paymentService.validateIbanWithApi(iban);
      setState(() {
        _ibanValidation = validation;
      });
    } catch (e) {
      setState(() {
        _ibanValidation = {'valid': false, 'error': 'Erreur validation'};
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  Future<void> _createMandate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final mandate = await _paymentService.createSepaMandate(
        iban: _ibanController.text.replaceAll(' ', ''),
        bic: _bicController.text.toUpperCase(),
        accountHolderName: _nameController.text,
      );

      setState(() {
        _currentMandate = mandate;
      });

      await _loadSepaData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Mandat SEPA créé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur création mandat: $e';
      });
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _handleMandateAction(String action) {
    switch (action) {
      case 'modify':
        _showModifyMandateDialog();
        break;
      case 'revoke':
        _showRevocationWarningDialog();
        break;
      case 'details':
        _showMandateDetails();
        break;
    }
  }

  void _showModifyMandateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Text(
          'Modifier le mandat SEPA',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Pour modifier vos informations bancaires, nous devons créer un nouveau mandat et révoquer l\'ancien automatiquement après validation.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              Navigator.pop(context);
              _startMandateModification();
            },
            child: Text('Continuer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startMandateModification() {
    if (_currentMandate != null) {
      _nameController.text = _currentMandate!.accountHolderName;
      _bicController.text = _currentMandate!.bic;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📝 Remplissez le formulaire ci-dessous pour créer le nouveau mandat'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showRevocationWarningDialog() async {
    setState(() => _isCheckingRisks = true);
    await _loadRevocationRisks();
    setState(() => _isCheckingRisks = false);
    
    if (!mounted) return;
    
    final risks = _revocationRisks;
    final activeFractionals = risks?['activeFractionalPayments'] ?? 0;
    final hasSubscription = risks?['hasActiveSubscription'] ?? false;
    final amountAtRisk = risks?['totalAmountAtRisk'] ?? 0.0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'ATTENTION - RÉVOCATION CRITIQUE',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeFractionals > 0) ...[
                _buildWarningItem(
                  '🚫 PAIEMENTS FRACTIONNÉS BLOQUÉS',
                  '$activeFractionals paiement(s) en cours seront arrêtés immédiatement',
                  '${amountAtRisk.toStringAsFixed(2)}€ de revenus perdus',
                ),
                SizedBox(height: 12),
              ],
              
              if (hasSubscription) ...[
                _buildWarningItem(
                  '⛔ SUSPENSION DU COMPTE',
                  'Votre abonnement KIPIK sera suspendu',
                  'Plus de prélèvement mensuel possible',
                ),
                SizedBox(height: 12),
              ],
              
              _buildWarningItem(
                '💼 IMPACT BUSINESS',
                'Vos clients ne pourront plus payer en plusieurs fois',
                'Perte de compétitivité commerciale',
              ),
              
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 ALTERNATIVES RECOMMANDÉES',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Modifier le mandat au lieu de le révoquer\n'
                      '• Créer un nouveau mandat avant révocation\n'
                      '• Attendre la fin des paiements en cours',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showModifyMandateDialog();
            },
            child: Text('Modifier plutôt', style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _showFinalRevocationConfirmation();
            },
            child: Text(
              'RÉVOQUER QUAND MÊME',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String title, String description, String impact) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
          Text(
            impact,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalRevocationConfirmation() {
    final confirmationController = TextEditingController();
    bool canRevoke = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          title: Text(
            'CONFIRMATION FINALE',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pour confirmer la révocation, tapez "RÉVOQUER" ci-dessous :',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              TextField(
                controller: confirmationController,
                onChanged: (value) {
                  setDialogState(() {
                    canRevoke = value == 'RÉVOQUER';
                  });
                },
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tapez RÉVOQUER',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canRevoke ? Colors.red : Colors.grey,
              ),
              onPressed: canRevoke
                  ? () {
                      Navigator.pop(context);
                      _revokeMandate();
                    }
                  : null,
              child: Text(
                'RÉVOQUER DÉFINITIVEMENT',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _revokeMandate() async {
    if (_currentMandate == null) return;

    try {
      await _paymentService.revokeSepaMandate(
        mandateId: _currentMandate!.mandateId,
        reason: 'user_requested',
      );

      setState(() {
        _currentMandate = null;
      });

      await _loadSepaData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mandat SEPA révoqué'),
          backgroundColor: Colors.orange,
        ),
      );

    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur révocation: $e';
      });
    }
  }

  void _showMandateDetails() {
    if (_currentMandate == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Text(
          'Détails du mandat',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Référence', _currentMandate!.mandateId),
            _buildDetailRow('IBAN', _currentMandate!.iban),
            _buildDetailRow('BIC', _currentMandate!.bic),
            _buildDetailRow('Titulaire', _currentMandate!.accountHolderName),
            _buildDetailRow('Créé le', _formatDate(_currentMandate!.createdAt)),
            _buildDetailRow('Statut', _currentMandate!.status.name.toUpperCase()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}