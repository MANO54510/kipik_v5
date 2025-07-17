// lib/pages/organisateur/organisateur_marketing_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/common/drawers/drawer_factory.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../core/helpers/service_helper.dart';
import '../../core/helpers/widget_helper.dart';

enum CampaignType { email, social, push, sms }
enum CampaignStatus { draft, scheduled, active, paused, completed }

class OrganisateurMarketingPage extends StatefulWidget {
  const OrganisateurMarketingPage({Key? key}) : super(key: key);

  @override
  State<OrganisateurMarketingPage> createState() => _OrganisateurMarketingPageState();
}

class _OrganisateurMarketingPageState extends State<OrganisateurMarketingPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _cardController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;

  String? _selectedConventionId;
  String? _currentOrganizerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _cardController = AnimationController(
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
    
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  void _initializeData() {
    _currentOrganizerId = ServiceHelper.currentUserId;
    setState(() => _isLoading = false);
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
          title: 'Marketing & Communication',
          subtitle: 'Promotion temps réel',
          showBackButton: true,
          showBurger: true,
          useProStyle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics, color: Colors.white),
              onPressed: _viewDetailedAnalytics,
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _openMarketingSettings,
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "create_campaign",
            onPressed: _createCampaign,
            backgroundColor: Colors.purple,
            icon: const Icon(Icons.campaign, color: Colors.white),
            label: const Text(
              'Nouvelle Campagne',
              style: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
            ),
          ),
          const SizedBox(height: 16),
          const TattooAssistantButton(
            contextPage: 'marketing_organisateur',
            allowImageGeneration: true,
          ),
        ],
      ),
      child: Stack(
        children: [
          KipikTheme.withSpecificBackground('assets/background_charbon.png', child: Container()),
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoading ? Center(child: KipikTheme.loading()) : _buildContent(),
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConventionSelector(),
          const SizedBox(height: 24),
          _buildMarketingOverview(),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildActiveCampaigns(),
          const SizedBox(height: 32),
          _buildEngagementAnalytics(),
          const SizedBox(height: 32),
          _buildSocialMediaManagement(),
          const SizedBox(height: 32),
          _buildEmailMarketing(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildConventionSelector() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: WidgetHelper.buildStreamWidget<QuerySnapshot>(
            stream: ServiceHelper.getStream('conventions', where: {'basic.organizerId': _currentOrganizerId}),
            builder: (data) {
              return WidgetHelper.buildKipikContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event, color: KipikTheme.rouge, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Convention à Promouvoir',
                          style: TextStyle(
                            fontFamily: 'PermanentMarker',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedConventionId,
                      decoration: InputDecoration(
                        hintText: 'Choisir une convention',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Toutes les conventions'),
                        ),
                        ...data.docs.map((doc) {
                          final conventionData = doc.data() as Map<String, dynamic>;
                          final basicInfo = conventionData['basic'] as Map<String, dynamic>?;
                          
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(basicInfo?['name'] ?? 'Convention sans nom'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedConventionId = value;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMarketingOverview() {
    return WidgetHelper.buildStreamWidget<QuerySnapshot>(
      stream: ServiceHelper.getStream('marketing_analytics', where: {'organizerId': _currentOrganizerId}),
      builder: (analyticsData) {
        // ✅ VRAIES DONNÉES - Collection marketing_analytics Firebase
        final doc = analyticsData.docs.isNotEmpty ? analyticsData.docs.first : null;
        final data = doc?.data() as Map<String, dynamic>?;
        
        final reach = data?['reach']?['total'] ?? 0;
        final engagement = (data?['engagement']?['rate'] ?? 0.0).toDouble();
        final conversions = data?['conversions']?['total'] ?? 0;
        final roi = (data?['roi']?['percentage'] ?? 0.0).toDouble();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.pink.shade600],
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
                '📈 Performance Marketing',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildOverviewCard(
                    'Portée Totale',
                    _formatNumber(reach),
                    Icons.visibility,
                    Colors.white,
                  ),
                  _buildOverviewCard(
                    'Engagement',
                    '${(engagement * 100).toStringAsFixed(1)}%',
                    Icons.favorite,
                    Colors.white,
                  ),
                  _buildOverviewCard(
                    'Conversions',
                    conversions.toString(),
                    Icons.shopping_cart,
                    Colors.white,
                  ),
                  _buildOverviewCard(
                    'ROI',
                    '${roi.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.white,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      empty: _buildEmptyMarketingOverview(),
    );
  }

  Widget _buildEmptyMarketingOverview() {
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
            '📈 Performance Marketing',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune donnée marketing disponible.\nLancez votre première campagne pour voir les statistiques.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _createCampaign,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer ma première campagne'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'Campagne Email',
        'subtitle': 'Newsletter & promo',
        'icon': Icons.email,
        'color': Colors.blue,
        'onTap': () => _createSpecificCampaign(CampaignType.email),
      },
      {
        'title': 'Réseaux Sociaux',
        'subtitle': 'Posts automatiques',
        'icon': Icons.share,
        'color': Colors.purple,
        'onTap': () => _createSpecificCampaign(CampaignType.social),
      },
      {
        'title': 'Notifications Push',
        'subtitle': 'Alertes mobiles',
        'icon': Icons.notifications,
        'color': Colors.orange,
        'onTap': () => _createSpecificCampaign(CampaignType.push),
      },
      {
        'title': 'Templates',
        'subtitle': 'Modèles prêts',
        'icon': Icons.library_books, // ✅ CORRIGÉ - Icône valide
        'color': Colors.green,
        'onTap': _viewTemplates,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: KipikTheme.rouge, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Actions Rapides',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: actions.map((action) => _buildActionCard(action)).toList(),
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        action['onTap']();
      },
      child: WidgetHelper.buildKipikContainer(
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                action['icon'],
                color: action['color'],
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              action['title'],
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action['subtitle'],
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCampaigns() {
    return WidgetHelper.buildStreamWidget<QuerySnapshot>(
      stream: ServiceHelper.getStream('marketing_campaigns', 
        where: _selectedConventionId != null 
          ? {'organizerId': _currentOrganizerId, 'status': 'active', 'conventionId': _selectedConventionId}
          : {'organizerId': _currentOrganizerId, 'status': 'active'}, 
        limit: 3
      ),
      builder: (data) {
        return WidgetHelper.buildKipikContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign, color: KipikTheme.rouge, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Campagnes Actives',
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _viewAllCampaigns,
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (data.docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(
                    child: Text(
                      'Aucune campagne active',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                ...data.docs.map((doc) {
                  final campaignData = doc.data() as Map<String, dynamic>;
                  return _buildCampaignCard(doc.id, campaignData);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCampaignCard(String campaignId, Map<String, dynamic> data) {
    // ✅ VRAIES DONNÉES - Structure Firebase marketing_campaigns
    final campaignInfo = data['campaign'] as Map<String, dynamic>? ?? {};
    final metricsInfo = data['metrics'] as Map<String, dynamic>? ?? {};
    
    final type = _parseCampaignType(campaignInfo['type']);
    final status = _parseCampaignStatus(data['status']);
    
    return WidgetHelper.buildListItem(
      title: campaignInfo['name'] ?? 'Campagne',
      subtitle: '${metricsInfo['reach'] ?? 0} personnes atteintes • ${metricsInfo['engagement'] ?? 0} interactions',
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getCampaignTypeColor(type).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getCampaignTypeIcon(type),
          color: _getCampaignTypeColor(type),
          size: 20,
        ),
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            WidgetHelper.buildStatusBadge(data['status'] ?? 'active'),
            const SizedBox(height: 4),
            Text(
              '${((metricsInfo['engagement_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 12,
                color: _getCampaignTypeColor(type),
              ),
            ),
          ],
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.grey, size: 16),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 16),
                  SizedBox(width: 8),
                  Text('Voir détails'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'pause',
              child: Row(
                children: [
                  Icon(Icons.pause, size: 16),
                  SizedBox(width: 8),
                  Text('Mettre en pause'),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleCampaignAction(campaignId, value as String),
        ),
      ],
    );
  }

  Widget _buildEngagementAnalytics() {
    return WidgetHelper.buildStreamWidget<QuerySnapshot>(
      stream: ServiceHelper.getStream('social_engagement', 
        where: _selectedConventionId != null 
          ? {'organizerId': _currentOrganizerId, 'conventionId': _selectedConventionId}
          : {'organizerId': _currentOrganizerId}
      ),
      builder: (engagementData) {
        // ✅ VRAIES DONNÉES - Collection social_engagement Firebase
        final doc = engagementData.docs.isNotEmpty ? engagementData.docs.first : null;
        final data = doc?.data() as Map<String, dynamic>?;
        
        final likes = data?['metrics']?['likes'] ?? 0;
        final shares = data?['metrics']?['shares'] ?? 0;
        final comments = data?['metrics']?['comments'] ?? 0;
        final clicks = data?['metrics']?['clicks'] ?? 0;
        final rate = (data?['metrics']?['engagement_rate'] ?? 0.0).toDouble();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade600, Colors.blue.shade600],
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
                '💬 Analytics d\'Engagement',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: _buildEngagementMetric(
                      'Likes',
                      '$likes',
                      Icons.thumb_up,
                    ),
                  ),
                  Expanded(
                    child: _buildEngagementMetric(
                      'Partages',
                      '$shares',
                      Icons.share,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildEngagementMetric(
                      'Commentaires',
                      '$comments',
                      Icons.comment,
                    ),
                  ),
                  Expanded(
                    child: _buildEngagementMetric(
                      'Clics',
                      '$clicks',
                      Icons.mouse,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Taux d\'engagement moyen',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '${(rate * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontFamily: 'PermanentMarker',
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: rate,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      empty: _buildEmptyEngagementAnalytics(),
    );
  }

  Widget _buildEmptyEngagementAnalytics() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade600, Colors.grey.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Text(
            '💬 Analytics d\'Engagement',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Aucune donnée d\'engagement disponible.\nPubliez du contenu sur les réseaux sociaux pour voir les métriques.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetric(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaManagement() {
    return WidgetHelper.buildStreamWidget<QuerySnapshot>(
      stream: ServiceHelper.getStream('social_platforms', where: {'organizerId': _currentOrganizerId}),
      builder: (platformsData) {
        // ✅ VRAIES DONNÉES - Collection social_platforms Firebase
        final platforms = <Map<String, dynamic>>[];
        
        for (final doc in platformsData.docs) {
          final data = doc.data() as Map<String, dynamic>;
          platforms.add({
            'platform': data['platform'],
            'followers': data['followers'] ?? 0,
            'growth': data['growth_rate'] ?? 0.0,
            'icon': _getSocialIcon(data['platform']),
            'color': _getSocialColor(data['platform']),
          });
        }

        return WidgetHelper.buildKipikContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.share, color: KipikTheme.rouge, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Gestion Réseaux Sociaux',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (platforms.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(
                    child: Text(
                      'Aucun compte de réseau social connecté.\nConnectez vos comptes pour voir les statistiques.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                _buildSocialPlatformsGrid(platforms),
              
              const SizedBox(height: 16),
              
              WidgetHelper.buildActionButton(
                text: 'Programmer une publication',
                onPressed: _schedulePost,
                isPrimary: false,
                icon: Icons.schedule,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialPlatformsGrid(List<Map<String, dynamic>> platforms) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: platforms.length,
      itemBuilder: (context, index) {
        final platform = platforms[index];
        return _buildSocialPlatformCard(
          platform['platform'],
          platform['icon'],
          platform['color'],
          _formatNumber(platform['followers']),
          '${(platform['growth'] * 100).toStringAsFixed(1)}%',
        );
      },
    );
  }

  Widget _buildSocialPlatformCard(String platform, IconData icon, Color color, String followers, String growth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            platform,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            followers,
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            growth,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailMarketing() {
    return WidgetHelper.buildStreamWidget<QuerySnapshot>(
      stream: ServiceHelper.getStream('email_marketing', where: {'organizerId': _currentOrganizerId}),
      builder: (emailData) {
        // ✅ VRAIES DONNÉES - Collection email_marketing Firebase
        final doc = emailData.docs.isNotEmpty ? emailData.docs.first : null;
        final data = doc?.data() as Map<String, dynamic>?;
        
        final subscribers = data?['subscribers']?['total'] ?? 0;
        final openRate = (data?['metrics']?['open_rate'] ?? 0.0).toDouble();
        final clickRate = (data?['metrics']?['click_rate'] ?? 0.0).toDouble();
        final unsubscribes = data?['metrics']?['unsubscribes'] ?? 0;

        return WidgetHelper.buildKipikContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.email, color: KipikTheme.rouge, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Email Marketing',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildEmailMetric(
                          'Abonnés',
                          '$subscribers',
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEmailMetric(
                          'Taux d\'ouverture',
                          '${(openRate * 100).toStringAsFixed(1)}%',
                          Icons.mark_email_read,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildEmailMetric(
                          'Taux de clic',
                          '${(clickRate * 100).toStringAsFixed(1)}%',
                          Icons.mouse,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEmailMetric(
                          'Désabonnements',
                          '$unsubscribes',
                          Icons.unsubscribe,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _createNewsletter,
                      icon: const Icon(Icons.newspaper, size: 16),
                      label: const Text(
                        'Newsletter',
                        style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _manageSubscribers,
                      icon: const Icon(Icons.group, size: 16),
                      label: const Text(
                        'Abonnés',
                        style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      empty: _buildEmptyEmailMarketing(),
    );
  }

  Widget _buildEmptyEmailMarketing() {
    return WidgetHelper.buildKipikContainer(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.email, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Email Marketing',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune campagne email configurée.\nCommencez par créer votre première newsletter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createNewsletter,
            icon: const Icon(Icons.newspaper, size: 16),
            label: const Text('Créer ma première newsletter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram': return Icons.camera_alt;
      case 'facebook': return Icons.facebook;
      case 'tiktok': return Icons.music_note;
      case 'youtube': return Icons.play_arrow;
      case 'twitter': return Icons.alternate_email;
      case 'linkedin': return Icons.business;
      default: return Icons.share;
    }
  }

  Color _getSocialColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram': return Colors.purple;
      case 'facebook': return Colors.blue;
      case 'tiktok': return Colors.black;
      case 'youtube': return Colors.red;
      case 'twitter': return Colors.lightBlue;
      case 'linkedin': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  CampaignType _parseCampaignType(String? typeString) {
    switch (typeString) {
      case 'email': return CampaignType.email;
      case 'social': return CampaignType.social;
      case 'push': return CampaignType.push;
      case 'sms': return CampaignType.sms;
      default: return CampaignType.email;
    }
  }

  CampaignStatus _parseCampaignStatus(String? statusString) {
    switch (statusString) {
      case 'draft': return CampaignStatus.draft;
      case 'scheduled': return CampaignStatus.scheduled;
      case 'active': return CampaignStatus.active;
      case 'paused': return CampaignStatus.paused;
      case 'completed': return CampaignStatus.completed;
      default: return CampaignStatus.draft;
    }
  }

  Color _getCampaignTypeColor(CampaignType type) {
    switch (type) {
      case CampaignType.email: return Colors.blue;
      case CampaignType.social: return Colors.purple;
      case CampaignType.push: return Colors.orange;
      case CampaignType.sms: return Colors.green;
    }
  }

  IconData _getCampaignTypeIcon(CampaignType type) {
    switch (type) {
      case CampaignType.email: return Icons.email;
      case CampaignType.social: return Icons.share;
      case CampaignType.push: return Icons.notifications;
      case CampaignType.sms: return Icons.sms;
    }
  }

  // Actions Firebase avec vraies données
  void _viewDetailedAnalytics() async {
    try {
      await ServiceHelper.trackEvent('marketing_analytics_viewed', {
        'organizerId': _currentOrganizerId,
        'conventionId': _selectedConventionId,
      });
      
      Navigator.pushNamed(context, '/organisateur/marketing/analytics');
    } catch (e) {
      KipikTheme.showErrorSnackBar(context, 'Erreur lors de l\'ouverture des analytics');
    }
  }

  void _openMarketingSettings() {
    Navigator.pushNamed(context, '/organisateur/marketing/settings');
  }

  void _createCampaign() async {
    try {
      await ServiceHelper.trackEvent('marketing_campaign_creation_started', {
        'organizerId': _currentOrganizerId,
        'conventionId': _selectedConventionId,
      });
      
      Navigator.pushNamed(context, '/organisateur/marketing/create-campaign');
    } catch (e) {
      KipikTheme.showErrorSnackBar(context, 'Erreur lors de la création de campagne');
    }
  }

  void _createSpecificCampaign(CampaignType type) async {
    try {
      await ServiceHelper.trackEvent('specific_campaign_creation_started', {
        'organizerId': _currentOrganizerId,
        'campaignType': type.name,
        'conventionId': _selectedConventionId,
      });
      
      Navigator.pushNamed(
        context, 
        '/organisateur/marketing/create-campaign',
        arguments: {
          'type': type, 
          'conventionId': _selectedConventionId,
        },
      );
    } catch (e) {
      KipikTheme.showErrorSnackBar(context, 'Erreur lors de la création de campagne ${type.name}');
    }
  }

  void _viewTemplates() {
    Navigator.pushNamed(context, '/organisateur/marketing/templates');
  }

  void _viewAllCampaigns() {
    Navigator.pushNamed(context, '/organisateur/marketing/campaigns');
  }

  void _handleCampaignAction(String campaignId, String action) async {
    switch (action) {
      case 'view':
        Navigator.pushNamed(
          context, 
          '/organisateur/marketing/campaign-detail',
          arguments: campaignId,
        );
        break;
      case 'edit':
        Navigator.pushNamed(
          context, 
          '/organisateur/marketing/edit-campaign',
          arguments: campaignId,
        );
        break;
      case 'pause':
        await _pauseCampaign(campaignId);
        break;
    }
  }

  Future<void> _pauseCampaign(String campaignId) async {
    try {
      await ServiceHelper.update('marketing_campaigns', campaignId, {
        'status': 'paused',
        'pausedAt': FieldValue.serverTimestamp(),
        'pausedBy': _currentOrganizerId,
      });
      
      await ServiceHelper.trackEvent('campaign_paused', {
        'campaignId': campaignId,
        'organizerId': _currentOrganizerId,
      });
      
      if (mounted) {
        KipikTheme.showSuccessSnackBar(context, 'Campagne mise en pause');
      }
    } catch (e) {
      if (mounted) {
        KipikTheme.showErrorSnackBar(context, 'Erreur lors de la mise en pause: $e');
      }
    }
  }

  void _schedulePost() async {
    try {
      await ServiceHelper.trackEvent('social_post_scheduling_started', {
        'organizerId': _currentOrganizerId,
        'conventionId': _selectedConventionId,
      });
      
      Navigator.pushNamed(context, '/organisateur/marketing/schedule-post');
    } catch (e) {
      KipikTheme.showErrorSnackBar(context, 'Erreur lors de la programmation de publication');
    }
  }

  void _createNewsletter() async {
    try {
      await ServiceHelper.trackEvent('newsletter_creation_started', {
        'organizerId': _currentOrganizerId,
        'conventionId': _selectedConventionId,
      });
      
      Navigator.pushNamed(context, '/organisateur/marketing/create-newsletter');
    } catch (e) {
      KipikTheme.showErrorSnackBar(context, 'Erreur lors de la création de newsletter');
    }
  }

  void _manageSubscribers() {
    Navigator.pushNamed(context, '/organisateur/marketing/subscribers');
  }
}