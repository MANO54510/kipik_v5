// lib/pages/organisateur/organisateur_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/common/drawers/drawer_factory.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../core/helpers/service_helper.dart';
import '../../core/helpers/widget_helper.dart';
import '../../services/payment/firebase_payment_service.dart'; // ✅ Votre service existant

enum NotificationType { email, push, sms }
enum PaymentMethod { stripe, paypal, bank_transfer }
enum SubscriptionPlan { free, pro, premium }

class OrganisateurSettingsPage extends StatefulWidget {
  const OrganisateurSettingsPage({Key? key}) : super(key: key);

  @override
  State<OrganisateurSettingsPage> createState() => _OrganisateurSettingsPageState();
}

class _OrganisateurSettingsPageState extends State<OrganisateurSettingsPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _sectionController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sectionAnimation;

  // Controllers pour les champs
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _siretController = TextEditingController();
  final _addressController = TextEditingController();

  String? _currentOrganizerId;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Settings state
  Map<String, bool> _notificationSettings = {
    'email_new_requests': true,
    'email_payments': true,
    'push_enabled': true,
    'email_reminders': true,
    'email_newsletter': false,
    '2fa_enabled': false,
  };
  Map<String, dynamic> _paymentSettings = {
    'preferred_method': 'stripe',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _sectionController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _siretController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _sectionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _sectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sectionController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _sectionController.forward();
    });
  }

  void _initializeData() {
    _currentOrganizerId = ServiceHelper.currentUserId;
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      if (_currentOrganizerId != null) {
        // Charger le profil organisateur
        final profileData = await ServiceHelper.getCurrentOrganizerData();
        _populateProfileData(profileData);
        
        // Charger les paramètres
        final settingsDoc = await ServiceHelper.get('organizer_settings', _currentOrganizerId!);
        if (settingsDoc.exists) {
          _populateSettingsData(settingsDoc.data() as Map<String, dynamic>);
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        KipikTheme.showErrorSnackBar(context, 'Erreur lors du chargement: $e');
      }
    }
  }

  void _populateProfileData(Map<String, dynamic> data) {
    final profile = data['profile'] as Map<String, dynamic>? ?? {};
    final company = data['company'] as Map<String, dynamic>? ?? {};
    
    setState(() {
      _nameController.text = profile['name'] ?? '';
      _emailController.text = profile['email'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _companyController.text = company['name'] ?? '';
      _siretController.text = company['siret'] ?? '';
      _addressController.text = company['address'] ?? '';
    });
  }

  void _populateSettingsData(Map<String, dynamic> data) {
    setState(() {
      _notificationSettings = Map<String, bool>.from(data['notifications'] ?? _notificationSettings);
      _paymentSettings = Map<String, dynamic>.from(data['payment'] ?? _paymentSettings);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ServiceHelper.isAuthenticated || _currentOrganizerId == null) {
      return _buildAuthenticationError();
    }

    return KipikTheme.scaffoldWithoutBackground(
      backgroundColor: KipikTheme.noir,
      endDrawer: DrawerFactory.of(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBarKipik(
          title: 'Paramètres Organisateur',
          subtitle: 'Configuration & abonnement',
          showBackButton: true,
          showBurger: true,
          useProStyle: true,
          actions: [
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
                  : const Icon(Icons.save, color: Colors.white),
              onPressed: _isSaving ? null : _saveAllSettings,
            ),
          ],
        ),
      ),
      floatingActionButton: const TattooAssistantButton(
        contextPage: 'settings_organisateur',
        allowImageGeneration: false,
      ),
      child: Stack(
        children: [
          KipikTheme.withSpecificBackground('assets/background_charbon.png', child: Container()),
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoading ? _buildLoadingState() : _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationError() {
    return KipikTheme.scaffoldWithoutBackground(
      backgroundColor: KipikTheme.noir,
      child: KipikTheme.errorState(
        title: 'Erreur d\'authentification',
        message: 'Vous devez être connecté en tant qu\'organisateur',
        onRetry: () => Navigator.pushReplacementNamed(context, '/connexion'),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: KipikTheme.loading());
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _sectionAnimation,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubscriptionSection(),
              const SizedBox(height: 32),
              _buildProfileSection(),
              const SizedBox(height: 32),
              _buildCompanySection(),
              const SizedBox(height: 32),
              _buildNotificationSettings(),
              const SizedBox(height: 32),
              _buildPaymentSettings(),
              const SizedBox(height: 32),
              _buildCommissionSettings(),
              const SizedBox(height: 32),
              _buildSecuritySection(),
              const SizedBox(height: 32),
              _buildDangerZone(),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Transform.translate(
      offset: Offset(0, 50 * (1 - _sectionAnimation.value)),
      child: Opacity(
        opacity: _sectionAnimation.value,
        child: WidgetHelper.buildStreamWidget<QuerySnapshot>(
          stream: ServiceHelper.getStream('subscriptions', where: {'userId': _currentOrganizerId}),
          builder: (querySnapshot) {
            final doc = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
            final subscriptionData = doc?.data() as Map<String, dynamic>? ?? {};
            final currentPlan = subscriptionData['plan'] ?? 'free';
            final nextBilling = subscriptionData['nextBilling'];
            final features = subscriptionData['features'] as List? ?? [];

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade600, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👑 Abonnement Premium',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan actuel: ${_getPlanLabel(currentPlan)}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (nextBilling != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Prochaine facturation: ${ServiceHelper.formatDate(ServiceHelper.timestampToDateTime(nextBilling))}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _managePlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.amber[700],
                        ),
                        child: const Text(
                          'Gérer',
                          style: TextStyle(fontFamily: 'Roboto'),
                        ),
                      ),
                    ],
                  ),
                  
                  if (features.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Fonctionnalités incluses:',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: features.map((feature) => 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            feature.toString(),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ],
              ),
            );
          },
          empty: _buildEmptySubscriptionSection(),
        ),
      ),
    );
  }

  Widget _buildEmptySubscriptionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade600, Colors.grey.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            '👑 Abonnement',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Plan Gratuit actuel\nPassez au Premium pour plus de fonctionnalités !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _managePlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Découvrir Premium'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Profil Personnel',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          WidgetHelper.buildFormField(
            label: 'Nom complet *',
            controller: _nameController,
            hint: 'Votre nom et prénom',
          ),
          const SizedBox(height: 16),
          WidgetHelper.buildFormField(
            label: 'Email *',
            controller: _emailController,
            hint: 'votre@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          WidgetHelper.buildFormField(
            label: 'Téléphone',
            controller: _phoneController,
            hint: '01 23 45 67 89',
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySection() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Informations Entreprise',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          WidgetHelper.buildFormField(
            label: 'Nom de l\'entreprise',
            controller: _companyController,
            hint: 'Votre société',
          ),
          const SizedBox(height: 16),
          WidgetHelper.buildFormField(
            label: 'SIRET',
            controller: _siretController,
            hint: '12345678901234',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          WidgetHelper.buildFormField(
            label: 'Adresse complète',
            controller: _addressController,
            hint: 'Adresse, ville, code postal',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildNotificationSwitch(
            'Nouvelles demandes de stands',
            'email_new_requests',
            'Recevez un email à chaque nouvelle demande',
          ),
          _buildNotificationSwitch(
            'Paiements reçus',
            'email_payments',
            'Notification lors des paiements confirmés',
          ),
          _buildNotificationSwitch(
            'Notifications push',
            'push_enabled',
            'Alertes mobiles importantes',
          ),
          _buildNotificationSwitch(
            'Rappels événements',
            'email_reminders',
            'Rappels avant vos conventions',
          ),
          _buildNotificationSwitch(
            'Newsletter Kipik',
            'email_newsletter',
            'Conseils et nouveautés organisateurs',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSettings() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Paiements & Facturation',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          const Text(
            'Méthode de paiement préférée:',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildPaymentMethodTile(
            'Stripe',
            'Cartes bancaires, virements SEPA',
            Icons.credit_card,
            'stripe',
          ),
          _buildPaymentMethodTile(
            'PayPal',
            'Compte PayPal Business',
            Icons.account_balance_wallet,
            'paypal',
          ),
          _buildPaymentMethodTile(
            'Virement bancaire',
            'RIB français uniquement',
            Icons.account_balance,
            'bank_transfer',
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Commissions Kipik',
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
                const Text(
                  '• 1% sur les ventes de billets\n• 1% sur les réservations de stands\n• Paiement mensuel automatique',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionSettings() {
    return WidgetHelper.buildStreamWidget<QuerySnapshot>(
      stream: ServiceHelper.getStream('organizers', where: {'id': _currentOrganizerId}),
      builder: (querySnapshot) {
        final doc = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
        final profileData = doc?.data() as Map<String, dynamic>? ?? {};
        final stats = profileData['stats'] as Map<String, dynamic>? ?? {};
        final totalRevenue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        final kipikCommission = totalRevenue * 0.01;

        return WidgetHelper.buildKipikContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.purple, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Commissions & Revenus',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _buildRevenueCard(
                      'Revenus Total',
                      ServiceHelper.formatCurrency(totalRevenue),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRevenueCard(
                      'Commission Kipik',
                      ServiceHelper.formatCurrency(kipikCommission),
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade100, Colors.teal.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💰 Optimisation des Revenus',
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Conseils pour maximiser vos revenus:',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Encouragez les réservations via Kipik\n• Utilisez le paiement fractionné\n• Activez les notifications automatiques\n• Proposez des tarifs préférentiels early-bird',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecuritySection() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Sécurité & Confidentialité',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.orange),
            title: const Text(
              'Changer le mot de passe',
              style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Dernière modification il y a 30 jours',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changePassword,
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.smartphone, color: Colors.blue),
            title: const Text(
              'Authentification à 2 facteurs',
              style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Sécurisez votre compte',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
            ),
            trailing: Switch(
              value: _notificationSettings['2fa_enabled'] ?? false,
              onChanged: (value) {
                setState(() {
                  _notificationSettings['2fa_enabled'] = value;
                });
              },
              activeColor: KipikTheme.rouge,
            ),
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.download, color: Colors.green),
            title: const Text(
              'Exporter mes données',
              style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Télécharger toutes vos données',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _exportData,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                'Zone de Danger',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ListTile(
            leading: Icon(Icons.pause_circle, color: Colors.orange.shade600),
            title: const Text(
              'Suspendre le compte temporairement',
              style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Désactiver temporairement votre activité',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _suspendAccount,
          ),
          
          const Divider(),
          
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade600),
            title: Text(
              'Supprimer définitivement le compte',
              style: TextStyle(
                fontFamily: 'Roboto', 
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            subtitle: const Text(
              'Action irréversible - toutes les données seront perdues',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSwitch(String title, String key, String subtitle) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      value: _notificationSettings[key] ?? false,
      onChanged: (value) {
        setState(() {
          _notificationSettings[key] = value;
        });
      },
      activeColor: KipikTheme.rouge,
    );
  }

  Widget _buildPaymentMethodTile(String title, String subtitle, IconData icon, String method) {
    final isSelected = _paymentSettings['preferred_method'] == method;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? KipikTheme.rouge : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? KipikTheme.rouge : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Radio<String>(
          value: method,
          groupValue: _paymentSettings['preferred_method'],
          onChanged: (value) {
            setState(() {
              _paymentSettings['preferred_method'] = value;
            });
          },
          activeColor: KipikTheme.rouge,
        ),
        onTap: () {
          setState(() {
            _paymentSettings['preferred_method'] = method;
          });
        },
      ),
    );
  }

  Widget _buildRevenueCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            amount,
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getPlanLabel(String plan) {
    switch (plan) {
      case 'free': return 'Gratuit';
      case 'pro': return 'Pro';
      case 'premium': return 'Premium';
      default: return 'Inconnu';
    }
  }

  // Actions Firebase avec vraies données
  Future<void> _saveAllSettings() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);

    try {
      // Sauvegarder le profil organisateur
      await ServiceHelper.update('organizers', _currentOrganizerId!, {
        'profile': {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
        },
        'company': {
          'name': _companyController.text,
          'siret': _siretController.text,
          'address': _addressController.text,
        },
      });

      // Sauvegarder les paramètres
      await ServiceHelper.update('organizer_settings', _currentOrganizerId!, {
        'notifications': _notificationSettings,
        'payment': _paymentSettings,
      });

      // Tracker l'événement
      await ServiceHelper.trackEvent('organizer_settings_updated', {
        'organizerId': _currentOrganizerId,
        'sections': ['profile', 'notifications', 'payment'],
      });

      if (mounted) {
        KipikTheme.showSuccessSnackBar(context, 'Paramètres sauvegardés avec succès');
      }
    } catch (e) {
      if (mounted) {
        KipikTheme.showErrorSnackBar(context, 'Erreur lors de la sauvegarde: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _managePlan() async {
    try {
      // Utiliser votre service de paiement existant
      final paymentService = FirebasePaymentService.instance;
      
      await ServiceHelper.trackEvent('subscription_management_accessed', {
        'organizerId': _currentOrganizerId,
      });
      
      Navigator.pushNamed(context, '/organisateur/subscription');
    } catch (e) {
      KipikTheme.showErrorSnackBar(context, 'Erreur d\'accès à la gestion d\'abonnement');
    }
  }

  void _changePassword() {
    Navigator.pushNamed(context, '/organisateur/change-password');
  }

  void _exportData() async {
    try {
      await ServiceHelper.trackEvent('data_export_requested', {
        'organizerId': _currentOrganizerId,
        'requestedAt': DateTime.now().toIso8601String(),
      });
      
      // Simuler la demande d'export
      await ServiceHelper.create('data_export_requests', {
        'userId': _currentOrganizerId,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        KipikTheme.showInfoSnackBar(context, 'Export demandé - vous recevrez un email avec vos données');
      }
    } catch (e) {
      if (mounted) {
        KipikTheme.showErrorSnackBar(context, 'Erreur lors de la demande d\'export: $e');
      }
    }
  }

  void _suspendAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspendre le compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir suspendre temporairement votre compte ? '
          'Vos conventions seront mises en pause.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSuspendAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer le compte',
          style: TextStyle(color: Colors.red.shade700),
        ),
        content: const Text(
          'ATTENTION: Cette action est irréversible. Toutes vos données, '
          'conventions et paramètres seront définitivement supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSuspendAccount() async {
    try {
      await ServiceHelper.update('organizers', _currentOrganizerId!, {
        'status': 'suspended',
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendedBy': _currentOrganizerId,
      });

      await ServiceHelper.trackEvent('account_suspended', {
        'organizerId': _currentOrganizerId,
        'reason': 'user_requested',
      });
      
      if (mounted) {
        KipikTheme.showInfoSnackBar(context, 'Compte suspendu temporairement');
        Navigator.pushReplacementNamed(context, '/connexion');
      }
    } catch (e) {
      if (mounted) {
        KipikTheme.showErrorSnackBar(context, 'Erreur lors de la suspension: $e');
      }
    }
  }

  Future<void> _performDeleteAccount() async {
    try {
      // Soft delete avec timestamp
      await ServiceHelper.update('organizers', _currentOrganizerId!, {
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _currentOrganizerId,
      });

      await ServiceHelper.trackEvent('account_deleted', {
        'organizerId': _currentOrganizerId,
        'reason': 'user_requested',
      });
      
      if (mounted) {
        KipikTheme.showInfoSnackBar(context, 'Compte supprimé définitivement');
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (e) {
      if (mounted) {
        KipikTheme.showErrorSnackBar(context, 'Erreur lors de la suppression: $e');
      }
    }
  }
}