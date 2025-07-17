// lib/pages/pro/flashs/flash_minute_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'flash_minute_create_page.dart';
import 'demandes_rdv_page.dart';
import 'analytics_flashs_page.dart';

class FlashMinuteDashboardPage extends StatefulWidget {
  const FlashMinuteDashboardPage({Key? key}) : super(key: key);

  @override
  State<FlashMinuteDashboardPage> createState() => _FlashMinuteDashboardPageState();
}

class _FlashMinuteDashboardPageState extends State<FlashMinuteDashboardPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;
  
  // État de la page
  bool _isLoading = true;
  bool _hasActiveFlashMinute = false;
  
  // Données temps réel
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _activeFlashMinutes = [];
  List<Map<String, dynamic>> _recentDemandes = [];
  
  // Timers pour mise à jour temps réel
  Timer? _metricsTimer;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _slideController.dispose();
    _metricsTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startRealTimeUpdates() {
    // Mise à jour des métriques toutes les 30 secondes
    _metricsTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateMetrics();
    });
    
    // Vérification des notifications toutes les 10 secondes
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkNotifications();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      _dashboardData = await _generateDashboardData();
      _activeFlashMinutes = await _generateActiveFlashMinutes();
      _recentDemandes = await _generateRecentDemandes();
      
      _hasActiveFlashMinute = _activeFlashMinutes.isNotEmpty;
      
      _slideController.forward();
      
    } catch (e) {
      print('❌ Erreur chargement dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _generateDashboardData() async {
    final random = Random();
    final now = DateTime.now();
    
    return {
      'totalRevenue': 1847.50,
      'todayRevenue': 320.0,
      'activeFlashMinutes': 6,
      'totalViews': 342,
      'totalClicks': 89,
      'conversionRate': 26.0,
      'pendingDemandes': 4,
      'acceptedToday': 8,
      'urgentDemandes': 2,
      'averageResponseTime': 18, // minutes
      'nextExpiration': now.add(const Duration(minutes: 43)),
      'topPerformingFlash': 'Rose Minimaliste',
      'lastUpdate': now,
      'trends': {
        'revenue': 15.3, // % d'augmentation
        'views': 23.7,
        'conversion': -2.1,
      },
    };
  }

  Future<List<Map<String, dynamic>>> _generateActiveFlashMinutes() async {
    final now = DateTime.now();
    
    return [
      {
        'id': 'fm_001',
        'title': 'Rose Minimaliste',
        'imageUrl': 'assets/images/flash_rose.jpg',
        'originalPrice': 150.0,
        'flashPrice': 120.0,
        'discount': 20,
        'views': 89,
        'clicks': 23,
        'demandes': 5,
        'status': 'active',
        'priority': 'high',
        'startedAt': now.subtract(const Duration(hours: 2, minutes: 15)),
        'expiresAt': now.add(const Duration(hours: 5, minutes: 45)),
        'performance': 'excellent',
      },
      {
        'id': 'fm_002',
        'title': 'Lion Géométrique',
        'imageUrl': 'assets/images/flash_lion.jpg',
        'originalPrice': 280.0,
        'flashPrice': 224.0,
        'discount': 20,
        'views': 67,
        'clicks': 18,
        'demandes': 3,
        'status': 'active',
        'priority': 'medium',
        'startedAt': now.subtract(const Duration(hours: 1, minutes: 30)),
        'expiresAt': now.add(const Duration(hours: 6, minutes: 30)),
        'performance': 'good',
      },
      {
        'id': 'fm_003',
        'title': 'Mandala Lotus',
        'imageUrl': 'assets/images/flash_mandala.jpg',
        'originalPrice': 200.0,
        'flashPrice': 160.0,
        'discount': 20,
        'views': 34,
        'clicks': 8,
        'demandes': 1,
        'status': 'expiring',
        'priority': 'urgent',
        'startedAt': now.subtract(const Duration(hours: 7, minutes: 45)),
        'expiresAt': now.add(const Duration(minutes: 15)),
        'performance': 'poor',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _generateRecentDemandes() async {
    final now = DateTime.now();
    
    return [
      {
        'id': 'demande_001',
        'clientName': 'Sophie Martin',
        'flashTitle': 'Rose Minimaliste',
        'status': 'pending',
        'amount': 36.0,
        'createdAt': now.subtract(const Duration(minutes: 8)),
        'priority': 'high',
      },
      {
        'id': 'demande_002',
        'clientName': 'Lucas Dubois',
        'flashTitle': 'Lion Géométrique',
        'status': 'accepted',
        'amount': 67.2,
        'createdAt': now.subtract(const Duration(minutes: 25)),
        'priority': 'medium',
      },
      {
        'id': 'demande_003',
        'clientName': 'Emma Leroy',
        'flashTitle': 'Mandala Lotus',
        'status': 'negotiation',
        'amount': 48.0,
        'createdAt': now.subtract(const Duration(hours: 1, minutes: 12)),
        'priority': 'urgent',
      },
    ];
  }

  void _updateMetrics() {
    // Simulation de mise à jour des métriques en temps réel
    if (mounted) {
      setState(() {
        _dashboardData['totalViews'] += Random().nextInt(20);
        _dashboardData['totalClicks'] += Random().nextInt(5);
        _dashboardData['lastUpdate'] = DateTime.now();
      });
    }
  }

  void _checkNotifications() {
    // Vérifier les Flash Minute qui expirent bientôt
    final expiringSoon = _activeFlashMinutes.where((fm) {
      final expiresAt = fm['expiresAt'] as DateTime;
      final now = DateTime.now();
      return expiresAt.difference(now).inMinutes <= 30;
    }).toList();
    
    if (expiringSoon.isNotEmpty && mounted) {
      // Mettre à jour le statut
      setState(() {
        for (final fm in expiringSoon) {
          fm['status'] = 'expiring';
          fm['priority'] = 'urgent';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Flash Minute',
        subtitle: _getSubtitle(),
        showBackButton: true,
        useProStyle: true,
        actions: [
          // Indicateur temps réel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsFlashsPage()),
            ),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  String _getSubtitle() {
    if (_hasActiveFlashMinute) {
      final activeCount = _activeFlashMinutes.where((fm) => fm['status'] == 'active').length;
      final expiringCount = _activeFlashMinutes.where((fm) => fm['status'] == 'expiring').length;
      
      if (expiringCount > 0) {
        return '$activeCount actifs • $expiringCount expirent bientôt';
      }
      return '$activeCount Flash Minute actifs';
    }
    return 'Tableau de bord Flash Minute';
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
              color: Colors.orange,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chargement du dashboard...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_hasActiveFlashMinute) ...[
              _buildEmptyState(),
            ] else ...[
              _buildOverviewCards(),
              const SizedBox(height: 24),
              _buildActiveFlashMinutes(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
              const SizedBox(height: 24),
              _buildQuickActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withOpacity(0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * pi,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.orange,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun Flash Minute actif',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Créez votre premier Flash Minute pour optimiser vos créneaux libres et booster vos revenus !',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createFlashMinute,
            icon: const Icon(Icons.add),
            label: const Text('Créer un Flash Minute'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue d\'ensemble',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildMetricCard(
                'Revenus aujourd\'hui',
                '${_dashboardData['todayRevenue']}€',
                Icons.euro,
                Colors.green,
                '+${_dashboardData['trends']['revenue']}%',
              ),
              _buildMetricCard(
                'Vues totales',
                '${_dashboardData['totalViews']}',
                Icons.visibility,
                Colors.blue,
                '+${_dashboardData['trends']['views']}%',
              ),
              _buildMetricCard(
                'Taux conversion',
                '${_dashboardData['conversionRate']}%',
                Icons.trending_up,
                Colors.purple,
                '${_dashboardData['trends']['conversion']}%',
              ),
              _buildMetricCard(
                'Demandes en attente',
                '${_dashboardData['pendingDemandes']}',
                Icons.schedule,
                Colors.orange,
                'Urgent!',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title, 
    String value, 
    IconData icon, 
    Color color,
    String trend,
  ) {
    final isNegative = trend.startsWith('-');
    final trendColor = isNegative ? Colors.red : Colors.green;
    
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              if (trend != 'Urgent!') ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else ...[
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
    );
  }

  Widget _buildActiveFlashMinutes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Flash Minute actifs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _createFlashMinute,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nouveau'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _activeFlashMinutes.length,
          itemBuilder: (context, index) {
            final flashMinute = _activeFlashMinutes[index];
            return _buildFlashMinuteCard(flashMinute);
          },
        ),
      ],
    );
  }

  Widget _buildFlashMinuteCard(Map<String, dynamic> flashMinute) {
    final status = flashMinute['status'];
    final isExpiring = status == 'expiring';
    final performance = flashMinute['performance'];
    
    return AnimatedBuilder(
      animation: isExpiring ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: isExpiring ? _pulseAnimation.value : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPerformanceColor(performance).withOpacity(0.3),
                width: isExpiring ? 2 : 1,
              ),
              boxShadow: isExpiring ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Image flash
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[800],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          flashMinute['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Info flash
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  flashMinute['title'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildPerformanceBadge(performance),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${flashMinute['originalPrice']}€',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${flashMinute['flashPrice']}€',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '-${flashMinute['discount']}%',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Countdown
                    _buildCountdown(flashMinute),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Métriques
                _buildFlashMetrics(flashMinute),
                
                const SizedBox(height: 12),
                
                // Actions
                _buildFlashActions(flashMinute),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdown(Map<String, dynamic> flashMinute) {
    final expiresAt = flashMinute['expiresAt'] as DateTime;
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    final isUrgent = difference.inMinutes < 60;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            color: isUrgent ? Colors.red : Colors.blue,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            '${hours}h ${minutes}m',
            style: TextStyle(
              color: isUrgent ? Colors.red : Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashMetrics(Map<String, dynamic> flashMinute) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniMetric('Vues', '${flashMinute['views']}', Icons.visibility),
          ),
          Expanded(
            child: _buildMiniMetric('Clics', '${flashMinute['clicks']}', Icons.mouse),
          ),
          Expanded(
            child: _buildMiniMetric('Demandes', '${flashMinute['demandes']}', Icons.request_page),
          ),
          Expanded(
            child: _buildMiniMetric(
              'Taux',
              '${((flashMinute['clicks'] / flashMinute['views']) * 100).toStringAsFixed(1)}%',
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildFlashActions(Map<String, dynamic> flashMinute) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _extendFlashMinute(flashMinute['id']),
            icon: const Icon(Icons.schedule, size: 16),
            label: const Text('Prolonger'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _editFlashMinute(flashMinute['id']),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Modifier'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _stopFlashMinute(flashMinute['id']),
            icon: const Icon(Icons.stop, size: 16),
            label: const Text('Arrêter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBadge(String performance) {
    Color color;
    String text;
    
    switch (performance) {
      case 'excellent':
        color = Colors.green;
        text = 'Excellent';
        break;
      case 'good':
        color = Colors.blue;
        text = 'Bon';
        break;
      case 'poor':
        color = Colors.red;
        text = 'Faible';
        break;
      default:
        color = Colors.grey;
        text = 'Normal';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Activité récente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DemandesRdvPage()),
              ),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentDemandes.length,
          itemBuilder: (context, index) {
            final demande = _recentDemandes[index];
            return _buildActivityCard(demande);
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> demande) {
    final status = demande['status'];
    final statusColor = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${demande['clientName']} - ${demande['flashTitle']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStatusText(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${demande['amount']}€',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(demande['createdAt']),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Créer Flash Minute',
                'Nouveau créneau libre',
                Icons.flash_on,
                Colors.orange,
                _createFlashMinute,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Demandes RDV',
                '${_dashboardData['pendingDemandes']} en attente',
                Icons.schedule,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DemandesRdvPage()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Analytics',
                'Performance détaillée',
                Icons.analytics,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsFlashsPage()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Paramètres',
                'Configuration',
                Icons.settings,
                Colors.grey,
                _showSettings,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (!_hasActiveFlashMinute) return const SizedBox.shrink();
    
    final urgentCount = _dashboardData['urgentDemandes'] as int;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (urgentCount > 0)
          FloatingActionButton.extended(
            heroTag: 'urgent',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DemandesRdvPage()),
            ),
            backgroundColor: Colors.red,
            icon: const Icon(Icons.priority_high),
            label: Text('$urgentCount urgent${urgentCount > 1 ? 's' : ''}'),
          ),
        if (urgentCount > 0) const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'create',
          onPressed: _createFlashMinute,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  // Helper methods
  Color _getPerformanceColor(String performance) {
    switch (performance) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'negotiation':
        return Colors.blue;
      case 'refused':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Demande en attente';
      case 'accepted':
        return 'Demande acceptée';
      case 'negotiation':
        return 'En négociation';
      case 'refused':
        return 'Demande refusée';
      default:
        return status;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  // Actions
  void _createFlashMinute() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FlashMinuteCreatePage()),
    ).then((_) => _loadDashboardData());
  }

  void _extendFlashMinute(String flashMinuteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Prolonger Flash Minute', style: TextStyle(color: Colors.white)),
        content: const Text(
          'De combien d\'heures voulez-vous prolonger ce Flash Minute ?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performExtendFlashMinute(flashMinuteId, 2);
            },
            child: const Text('+2h'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performExtendFlashMinute(flashMinuteId, 4);
            },
            child: const Text('+4h'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performExtendFlashMinute(flashMinuteId, 8);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('+8h'),
          ),
        ],
      ),
    );
  }

  void _performExtendFlashMinute(String flashMinuteId, int hours) {
    setState(() {
      final flashMinute = _activeFlashMinutes.firstWhere((fm) => fm['id'] == flashMinuteId);
      final currentExpiry = flashMinute['expiresAt'] as DateTime;
      flashMinute['expiresAt'] = currentExpiry.add(Duration(hours: hours));
      if (flashMinute['status'] == 'expiring') {
        flashMinute['status'] = 'active';
      }
    });
    
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Flash Minute prolongé de ${hours}h'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editFlashMinute(String flashMinuteId) {
    // TODO: Implémenter l'édition
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Édition à implémenter')),
    );
  }

  void _stopFlashMinute(String flashMinuteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Arrêter Flash Minute', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Êtes-vous sûr de vouloir arrêter ce Flash Minute ? Cette action est irréversible.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performStopFlashMinute(flashMinuteId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Arrêter'),
          ),
        ],
      ),
    );
  }

  void _performStopFlashMinute(String flashMinuteId) {
    setState(() {
      _activeFlashMinutes.removeWhere((fm) => fm['id'] == flashMinuteId);
      _hasActiveFlashMinute = _activeFlashMinutes.isNotEmpty;
    });
    
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Flash Minute arrêté'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Paramètres Flash Minute',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.notifications, color: Colors.blue),
              title: Text('Notifications', style: TextStyle(color: Colors.white)),
              subtitle: Text('Gérer les alertes', style: TextStyle(color: Colors.grey)),
              trailing: Switch(value: true, onChanged: null),
            ),
            const ListTile(
              leading: Icon(Icons.schedule, color: Colors.orange),
              title: Text('Durée par défaut', style: TextStyle(color: Colors.white)),
              subtitle: Text('8 heures', style: TextStyle(color: Colors.grey)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ),
            const ListTile(
              leading: Icon(Icons.percent, color: Colors.green),
              title: Text('Réduction par défaut', style: TextStyle(color: Colors.white)),
              subtitle: Text('20%', style: TextStyle(color: Colors.grey)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}