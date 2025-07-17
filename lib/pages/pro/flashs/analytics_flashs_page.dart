// lib/pages/pro/flashs/analytics_flashs_page.dart

import 'package:flutter/material.dart';
import 'dart:math';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';

class AnalyticsFlashsPage extends StatefulWidget {
  const AnalyticsFlashsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsFlashsPage> createState() => _AnalyticsFlashsPageState();
}

class _AnalyticsFlashsPageState extends State<AnalyticsFlashsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _barAnimationController;
  late Animation<double> _barAnimation;
  
  bool _isLoading = true;
  String _selectedPeriod = '30J';
  
  // Données analytics
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _topFlashs = [];
  List<Map<String, dynamic>> _revenueData = [];
  Map<String, int> _stylePerformance = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _barAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barAnimationController, curve: Curves.elasticOut),
    );
    
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _barAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      // Simuler le chargement des données
      await Future.delayed(const Duration(seconds: 2));
      
      _generateAnalyticsData();
      _animationController.forward();
      _barAnimationController.forward();
      
    } catch (e) {
      print('❌ Erreur chargement analytics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateAnalyticsData() {
    final random = Random();
    
    // Données générales
    _analyticsData = {
      'totalFlashs': 24,
      'activeFlashs': 18,
      'flashMinuteCount': 6,
      'totalViews': 1247,
      'totalLikes': 189,
      'totalSaves': 76,
      'conversionRate': 12.3,
      'averagePrice': 185.50,
      'totalRevenue': 3780.0,
      'flashMinuteRevenue': 1240.0,
      'topViewsIncrease': 23.4,
      'likesIncrease': 18.9,
      'revenueIncrease': 31.2,
    };
    
    // Top flashs
    _topFlashs = [
      {
        'title': 'Rose Minimaliste',
        'views': 156,
        'likes': 23,
        'revenue': 450.0,
        'conversionRate': 18.5,
        'style': 'Minimaliste',
        'trend': 'up',
      },
      {
        'title': 'Lion Géométrique',
        'views': 134,
        'likes': 19,
        'revenue': 420.0,
        'conversionRate': 15.2,
        'style': 'Géométrique',
        'trend': 'up',
      },
      {
        'title': 'Mandala Lotus',
        'views': 98,
        'likes': 15,
        'revenue': 380.0,
        'conversionRate': 12.8,
        'style': 'Mandala',
        'trend': 'down',
      },
      {
        'title': 'Papillon Aquarelle',
        'views': 87,
        'likes': 12,
        'revenue': 320.0,
        'conversionRate': 10.1,
        'style': 'Aquarelle',
        'trend': 'stable',
      },
    ];
    
    // Données de revenus sur 30 jours
    _revenueData = List.generate(30, (index) {
      return {
        'day': index + 1,
        'revenue': 50 + random.nextInt(300).toDouble(),
        'flashMinute': random.nextInt(150).toDouble(),
      };
    });
    
    // Performance par style
    _stylePerformance = {
      'Minimaliste': 28,
      'Géométrique': 22,
      'Réalisme': 18,
      'Mandala': 15,
      'Aquarelle': 10,
      'Autres': 7,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Analytics Flashs',
        subtitle: 'Performance et insights',
        showBackButton: true,
        useProStyle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Exporter rapport', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Paramètres', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: KipikTheme.rouge,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Calcul des analytics...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildPeriodSelector(),
          _buildOverviewCards(),
          _buildTabSection(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['7J', '30J', '90J', '1A'];
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? KipikTheme.rouge : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMetricCard(
            'Revenus Total',
            '${_analyticsData['totalRevenue'].toStringAsFixed(0)}€',
            Icons.euro,
            Colors.green,
            '+${_analyticsData['revenueIncrease']}%',
            0,
          ),
          _buildMetricCard(
            'Vues Total',
            '${_analyticsData['totalViews']}',
            Icons.visibility,
            Colors.blue,
            '+${_analyticsData['topViewsIncrease']}%',
            1,
          ),
          _buildMetricCard(
            'Taux Conversion',
            '${_analyticsData['conversionRate']}%',
            Icons.trending_up,
            Colors.orange,
            '+2.1%',
            2,
          ),
          _buildMetricCard(
            'Flash Minute',
            '${_analyticsData['flashMinuteRevenue'].toStringAsFixed(0)}€',
            Icons.flash_on,
            Colors.purple,
            '+45.8%',
            3,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title, 
    String value, 
    IconData icon, 
    Color color,
    String trend,
    int index,
  ) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const Spacer(),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 500 + (index * 200)),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trend,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 800 + (index * 200)),
                    style: TextStyle(
                      color: color,
                      fontSize: 20 * _fadeAnimation.value,
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text(value),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabSection() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: KipikTheme.rouge,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Top Flashs'),
                  Tab(text: 'Revenus'),
                  Tab(text: 'Styles'),
                  Tab(text: 'Insights'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTopFlashsTab(),
                  _buildRevenueTab(),
                  _buildStylesTab(),
                  _buildInsightsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopFlashsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topFlashs.length,
      itemBuilder: (context, index) {
        final flash = _topFlashs[index];
        return _buildFlashAnalyticsCard(flash, index + 1);
      },
    );
  }

  Widget _buildFlashAnalyticsCard(Map<String, dynamic> flash, int rank) {
    final trendColor = flash['trend'] == 'up' 
        ? Colors.green 
        : flash['trend'] == 'down' 
            ? Colors.red 
            : Colors.grey;
    
    final trendIcon = flash['trend'] == 'up' 
        ? Icons.trending_up 
        : flash['trend'] == 'down' 
            ? Icons.trending_down 
            : Icons.trending_flat;

    return AnimatedBuilder(
      animation: _barAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _barAnimation.value)),
          child: Opacity(
            opacity: _barAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: rank <= 3 ? Border.all(color: KipikTheme.rouge.withOpacity(0.3)) : null,
              ),
              child: Row(
                children: [
                  // Rang avec animation
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (rank * 100)),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank <= 3 ? KipikTheme.rouge : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Infos flash
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                flash['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _barAnimation.value,
                              duration: const Duration(milliseconds: 800),
                              child: Icon(trendIcon, color: trendColor, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          flash['style'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMiniMetric('👁️', '${flash['views']}'),
                            const SizedBox(width: 12),
                            _buildMiniMetric('❤️', '${flash['likes']}'),
                            const SizedBox(width: 12),
                            _buildMiniMetric('💰', '${flash['revenue'].toStringAsFixed(0)}€'),
                            const SizedBox(width: 12),
                            _buildMiniMetric('📈', '${flash['conversionRate']}%'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniMetric(String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Résumé revenus
          Row(
            children: [
              Expanded(
                child: _buildRevenueCard(
                  'Flashs Normaux',
                  '${(_analyticsData['totalRevenue'] - _analyticsData['flashMinuteRevenue']).toStringAsFixed(0)}€',
                  KipikTheme.rouge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRevenueCard(
                  'Flash Minute',
                  '${_analyticsData['flashMinuteRevenue'].toStringAsFixed(0)}€',
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Graphique natif
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Évolution des revenus (30 derniers jours)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildNativeLineChart(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Flashs normaux', KipikTheme.rouge),
                      const SizedBox(width: 24),
                      _buildLegendItem('Flash Minute', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNativeLineChart() {
    final maxRevenue = _revenueData.map((d) => d['revenue'] as double).reduce(max);
    
    return AnimatedBuilder(
      animation: _barAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: LineChartPainter(
            revenueData: _revenueData,
            maxValue: maxRevenue,
            animation: _barAnimation.value,
            primaryColor: KipikTheme.rouge,
            secondaryColor: Colors.orange,
          ),
        );
      },
    );
  }

  Widget _buildRevenueCard(String title, String value, Color color) {
    return AnimatedBuilder(
      animation: _barAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _barAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStylesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance par style',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildNativePieChart(),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _stylePerformance.entries.map((entry) {
              final colors = [
                KipikTheme.rouge,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
                Colors.teal,
              ];
              final index = _stylePerformance.keys.toList().indexOf(entry.key);
              
              return _buildLegendItem(entry.key, colors[index % colors.length]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNativePieChart() {
    return AnimatedBuilder(
      animation: _barAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: PieChartPainter(
            data: _stylePerformance,
            animation: _barAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildInsightsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommandations intelligentes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildInsightCard(
                  '🎯 Optimisation pricing',
                  'Vos flashs minimalistes performent +23% mieux à 180€ qu\'à 150€',
                  'Augmenter le prix de vos flashs minimalistes',
                  Colors.green,
                  0,
                ),
                _buildInsightCard(
                  '⚡ Flash Minute efficace',
                  'Flash Minute génère 45% de revenus supplémentaires avec -20% de réduction',
                  'Activer plus souvent Flash Minute',
                  Colors.orange,
                  1,
                ),
                _buildInsightCard(
                  '📅 Meilleur timing',
                  'Vos flashs publiés le vendredi ont 35% plus de vues',
                  'Programmer vos publications le vendredi',
                  Colors.blue,
                  2,
                ),
                _buildInsightCard(
                  '🎨 Style tendance',
                  'Le style géométrique gagne +18% de popularité ce mois',
                  'Créer plus de flashs géométriques',
                  KipikTheme.rouge,
                  3,
                ),
                _buildInsightCard(
                  '📱 Réseaux sociaux',
                  'Vos flashs avec hashtag Instagram ont 2x plus d\'engagement',
                  'Ajouter des hashtags à tous vos flashs',
                  Colors.purple,
                  4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title, 
    String description, 
    String action, 
    Color color,
    int index,
  ) {
    return AnimatedBuilder(
      animation: _barAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _barAnimation.value)),
          child: Opacity(
            opacity: _barAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          action,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: color, size: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showExportDialog();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Exporter le rapport',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF Détaillé', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel/CSV', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Paramètres Analytics',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Notifications insights', style: TextStyle(color: Colors.white)),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Analyse automatique', style: TextStyle(color: Colors.white)),
              value: true,
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: KipikTheme.rouge)),
          ),
        ],
      ),
    );
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Rapport PDF en cours de génération...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Export Excel en cours...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Custom Painter pour le graphique en ligne natif
class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> revenueData;
  final double maxValue;
  final double animation;
  final Color primaryColor;
  final Color secondaryColor;

  LineChartPainter({
    required this.revenueData,
    required this.maxValue,
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paint2 = Paint()
      ..color = secondaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint1 = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    final path2 = Path();
    final fillPath1 = Path();

    final stepX = size.width / (revenueData.length - 1);

    for (int i = 0; i < revenueData.length; i++) {
      final x = i * stepX;
      final y1 = size.height - (revenueData[i]['revenue'] / maxValue * size.height * animation);
      final y2 = size.height - (revenueData[i]['flashMinute'] / maxValue * size.height * animation);

      if (i == 0) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
        fillPath1.moveTo(x, size.height);
        fillPath1.lineTo(x, y1);
      } else {
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
        fillPath1.lineTo(x, y1);
      }

      if (i == revenueData.length - 1) {
        fillPath1.lineTo(x, size.height);
        fillPath1.close();
      }
    }

    canvas.drawPath(fillPath1, fillPaint1);
    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter pour le graphique en camembert natif
class PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  final double animation;

  PieChartPainter({required this.data, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 3;
    
    final colors = [
      const Color(0xFFE53E3E), // rouge
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    final total = data.values.reduce((a, b) => a + b);
    double startAngle = -pi / 2;

    int colorIndex = 0;
    for (final entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * pi * animation;
      
      final paint = Paint()
        ..color = colors[colorIndex % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
      colorIndex++;
    }

    // Cercle central
    final centerPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.6, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}