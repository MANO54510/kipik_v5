// lib/pages/admin/flashs/flash_minute_monitoring_page.dart

import 'package:flutter/material.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../models/user_role.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../../models/flash/flash.dart';

class FlashMinuteMonitoringPage extends StatefulWidget {
  const FlashMinuteMonitoringPage({Key? key}) : super(key: key);

  @override
  State<FlashMinuteMonitoringPage> createState() => _FlashMinuteMonitoringPageState();
}

class _FlashMinuteMonitoringPageState extends State<FlashMinuteMonitoringPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Services
  SecureAuthService get _authService => SecureAuthService.instance;

  // Données
  List<Flash> _activeFlashMinute = [];
  List<Flash> _expiredFlashMinute = [];
  List<Flash> _suspiciousActivity = [];

  // Statistiques temps réel
  int _activeCount = 0;
  int _totalCreatedToday = 0;
  int _totalBookedToday = 0;
  double _averageDiscountPercent = 0.0;
  double _conversionRate = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializePage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    // Vérifier les privilèges admin
    if (_authService.currentUserRole != UserRole.admin) {
      Navigator.of(context).pushReplacementNamed('/admin/dashboard');
      return;
    }

    await _loadMonitoringData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMonitoringData() async {
    try {
      // Simuler chargement données
      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        _activeFlashMinute = _generateActiveFlashMinute();
        _expiredFlashMinute = _generateExpiredFlashMinute();
        _suspiciousActivity = _generateSuspiciousActivity();
        
        // Calculer statistiques
        _activeCount = _activeFlashMinute.length;
        _totalCreatedToday = 28;
        _totalBookedToday = 15;
        _averageDiscountPercent = 32.5;
        _conversionRate = 53.6;
      });
    } catch (e) {
      print('Erreur chargement monitoring Flash Minute: $e');
    }
  }

  List<Flash> _generateActiveFlashMinute() {
    return [
      Flash(
        id: 'minute_1',
        title: 'Rose Minimaliste',
        description: 'Rose simple pour poignet - Offre last-minute',
        imageUrl: 'https://example.com/rose.jpg',
        tattooArtistId: 'artist_123',
        tattooArtistName: 'Sophie Martin',
        studioName: 'Ink & Roses Studio',
        style: 'Minimaliste',
        size: '8x6cm',
        sizeDescription: 'Parfait pour poignet',
        price: 150.0,
        discountedPrice: 100.0,
        availableTimeSlots: [DateTime.parse('2025-01-15T16:00:00')],
        isMinuteFlash: true,
        minuteFlashDeadline: DateTime.now().add(const Duration(hours: 4)),
        urgencyReason: 'Créneau libéré dernière minute',
        flashType: FlashType.minute,
        status: FlashStatus.published,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        views: 45,
        qualityScore: 4.7,
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
      ),
      Flash(
        id: 'minute_2',
        title: 'Papillon Aquarelle',
        description: 'Papillon coloré - Promo flash',
        imageUrl: 'https://example.com/butterfly.jpg',
        tattooArtistId: 'artist_456',
        tattooArtistName: 'Emma Rousseau',
        studioName: 'Watercolor Tattoo',
        style: 'Aquarelle',
        size: '10x8cm',
        sizeDescription: 'Couleurs vives',
        price: 220.0,
        discountedPrice: 150.0,
        availableTimeSlots: [DateTime.parse('2025-01-15T18:00:00')],
        isMinuteFlash: true,
        minuteFlashDeadline: DateTime.now().add(const Duration(hours: 6)),
        urgencyReason: 'Annulation client',
        flashType: FlashType.minute,
        status: FlashStatus.published,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        views: 67,
        qualityScore: 4.5,
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
      ),
      Flash(
        id: 'minute_3',
        title: 'Géométrique Simple',
        description: 'Motif géométrique avant-bras',
        imageUrl: 'https://example.com/geometric.jpg',
        tattooArtistId: 'artist_789',
        tattooArtistName: 'Alex Dubois',
        studioName: 'Sacred Geometry Tattoo',
        style: 'Géométrique',
        size: '12x4cm',
        sizeDescription: 'Linéaire et précis',
        price: 180.0,
        discountedPrice: 130.0,
        availableTimeSlots: [DateTime.parse('2025-01-16T10:00:00')],
        isMinuteFlash: true,
        minuteFlashDeadline: DateTime.now().add(const Duration(hours: 22)),
        urgencyReason: 'Fin de journée disponible',
        flashType: FlashType.minute,
        status: FlashStatus.published,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        views: 23,
        qualityScore: 4.3,
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
      ),
    ];
  }

  List<Flash> _generateExpiredFlashMinute() {
    return [
      Flash(
        id: 'expired_1',
        title: 'Dragon Minimaliste',
        description: 'Dragon simple - Expiré sans réservation',
        imageUrl: 'https://example.com/dragon_mini.jpg',
        tattooArtistId: 'artist_111',
        tattooArtistName: 'Yuki Tanaka',
        studioName: 'Tokyo Ink Studio',
        style: 'Minimaliste',
        size: '10x6cm',
        sizeDescription: 'Dragon stylisé et minimaliste',
        price: 200.0,
        discountedPrice: 140.0,
        isMinuteFlash: true,
        minuteFlashDeadline: DateTime.now().subtract(const Duration(hours: 2)),
        urgencyReason: 'Slot libre imprévu',
        flashType: FlashType.minute,
        status: FlashStatus.expired,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
        views: 34,
        bookingRequests: 0,
        qualityScore: 4.1,
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
        // Note: expirationReason n'existe pas dans votre modèle
      ),
    ];
  }

  List<Flash> _generateSuspiciousActivity() {
    return [
      Flash(
        id: 'suspicious_1',
        title: 'Offre Trop Attractive',
        description: 'Réduction excessive détectée',
        imageUrl: 'https://example.com/suspicious.jpg',
        tattooArtistId: 'artist_999',
        tattooArtistName: 'Mike Suspect',
        studioName: 'Too Good Studio',
        style: 'Réalisme',
        size: '15x10cm',
        sizeDescription: 'Grand format réaliste',
        price: 500.0,
        discountedPrice: 50.0,
        isMinuteFlash: true,
        minuteFlashDeadline: DateTime.now().add(const Duration(hours: 12)),
        urgencyReason: 'Promo exceptionnelle',
        flashType: FlashType.minute,
        status: FlashStatus.published, // Pas de status flagged dans votre enum
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        views: 120,
        bookingRequests: 15,
        qualityScore: 3.2,
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
        // Note: flagReason et riskScore n'existent pas dans votre modèle
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Background aléatoire
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final bg = backgrounds[DateTime.now().millisecond % backgrounds.length];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Monitoring Flash Minute',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bg, fit: BoxFit.cover),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildRealTimeStats(),
                      _buildTabBar(),
                      Expanded(
                        child: _buildTabBarView(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMonitoringData,
        backgroundColor: Colors.red,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildRealTimeStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.speed, color: Colors.orange),
              ),
              const SizedBox(width: 8),
              const Text(
                'Flash Minute - Temps Réel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PermanentMarker',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Actifs',
                  _activeCount.toString(),
                  Icons.flash_on,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Créés/24h',
                  _totalCreatedToday.toString(),
                  Icons.add_circle,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Réservés/24h',
                  _totalBookedToday.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Réduction Moy.',
                  '${_averageDiscountPercent.toStringAsFixed(1)}%',
                  Icons.local_offer,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Taux Conversion',
                  '${_conversionRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Alertes',
                  _suspiciousActivity.length.toString(),
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'PermanentMarker',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.red,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.red,
        labelStyle: const TextStyle(
          fontFamily: 'PermanentMarker',
          fontSize: 11,
        ),
        tabs: [
          Tab(
            text: 'Actifs ($_activeCount)',
            icon: const Icon(Icons.flash_on, size: 18),
          ),
          Tab(
            text: 'Expirés (${_expiredFlashMinute.length})',
            icon: const Icon(Icons.timer_off, size: 18),
          ),
          Tab(
            text: 'Alertes (${_suspiciousActivity.length})',
            icon: const Icon(Icons.warning, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildActiveFlashList(),
        _buildExpiredFlashList(),
        _buildSuspiciousActivityList(),
      ],
    );
  }

  Widget _buildActiveFlashList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeFlashMinute.length,
      itemBuilder: (context, index) {
        final flash = _activeFlashMinute[index];
        return _buildFlashMinuteCard(flash, 'active');
      },
    );
  }

  Widget _buildExpiredFlashList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expiredFlashMinute.length,
      itemBuilder: (context, index) {
        final flash = _expiredFlashMinute[index];
        return _buildFlashMinuteCard(flash, 'expired');
      },
    );
  }

  Widget _buildSuspiciousActivityList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suspiciousActivity.length,
      itemBuilder: (context, index) {
        final flash = _suspiciousActivity[index];
        return _buildFlashMinuteCard(flash, 'suspicious');
      },
    );
  }

  Widget _buildFlashMinuteCard(Flash flash, String type) {
    final timeLeft = flash.minuteFlashDeadline?.difference(DateTime.now());
    final isExpired = timeLeft == null || timeLeft.isNegative;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: type == 'suspicious' 
            ? Border.all(color: Colors.red, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              flash.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PermanentMarker',
                              ),
                            ),
                          ),
                          if (type == 'active')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '⚡ FLASH',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            )
                          else if (type == 'suspicious')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '⚠️ ALERTE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'Par ${flash.tattooArtistName}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${flash.price.toStringAsFixed(0)}€',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${flash.discountedPrice?.toStringAsFixed(0)}€',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'PermanentMarker',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${flash.discountPercentage?.toStringAsFixed(0) ?? '30'}%',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (!isExpired && type == 'active')
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Expire dans ${_formatTimeLeft(timeLeft!)}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              )
            else if (type == 'expired')
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer_off, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Expiré: Temps écoulé', // Valeur fixe car expirationReason n'existe pas
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              )
            else if (type == 'suspicious')
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Réduction supérieure à 80% - Activité suspecte', // Valeur fixe
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Score de risque: 9.2/10', // Valeur fixe car riskScore n'existe pas
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Statistiques
            Row(
              children: [
                _buildMiniStat('👁️', '${flash.views}', 'vues'),
                const SizedBox(width: 16),
                _buildMiniStat('📅', '${flash.bookingRequests}', 'demandes'),
                const SizedBox(width: 16),
                _buildMiniStat('⭐', '${flash.qualityScore.toStringAsFixed(1)}', 'qualité'),
              ],
            ),
            
            if (type == 'suspicious')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _suspendFlash(flash.id),
                        icon: const Icon(Icons.pause_circle),
                        label: const Text('Suspendre'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontFamily: 'PermanentMarker',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _investigateFlash(flash.id),
                        icon: const Icon(Icons.search),
                        label: const Text('Enquêter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontFamily: 'PermanentMarker',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            fontFamily: 'PermanentMarker',
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }

  String _formatTimeLeft(Duration timeLeft) {
    if (timeLeft.inHours > 0) {
      return '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}min';
    } else {
      return '${timeLeft.inMinutes}min';
    }
  }

  Future<void> _suspendFlash(String flashId) async {
    // Simuler suspension
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏸️ Flash suspendu temporairement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _investigateFlash(String flashId) async {
    // Ouvrir détails pour investigation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Investigation Flash Minute'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Détails de l\'investigation:'),
            SizedBox(height: 8),
            Text('• Vérification historique tatoueur'),
            Text('• Analyse pattern prix'),
            Text('• Contrôle qualité images'),
            Text('• Validation studio'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔍 Investigation lancée'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Lancer Investigation'),
          ),
        ],
      ),
    );
  }
}