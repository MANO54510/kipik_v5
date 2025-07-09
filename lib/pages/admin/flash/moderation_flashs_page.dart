// lib/pages/admin/flashs/moderation_flashs_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../models/user_role.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../../models/flash/flash.dart';
// TODO: Créer ce service selon votre structure
// import '../../../services/flash/flash_service.dart';

class ModerationFlashsPage extends StatefulWidget {
  const ModerationFlashsPage({Key? key}) : super(key: key);

  @override
  State<ModerationFlashsPage> createState() => _ModerationFlashsPageState();
}

class _ModerationFlashsPageState extends State<ModerationFlashsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isProcessing = false;

  // Services
  SecureAuthService get _authService => SecureAuthService.instance;

  // Données simulées pour la démonstration
  List<Flash> _pendingFlashs = [];
  List<Flash> _reportedFlashs = [];
  List<Flash> _recentlyModerated = [];

  // Statistiques
  int _totalPending = 0;
  int _totalReported = 0;
  int _validatedToday = 0;
  int _rejectedToday = 0;

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

    await _loadModerationData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadModerationData() async {
    try {
      // Dans un vrai projet, ces données viendraient de FlashService
      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        _pendingFlashs = _generatePendingFlashs();
        _reportedFlashs = _generateReportedFlashs();
        _recentlyModerated = _generateRecentlyModerated();
        
        _totalPending = _pendingFlashs.length;
        _totalReported = _reportedFlashs.length;
        _validatedToday = 12;
        _rejectedToday = 3;
      });
    } catch (e) {
      print('Erreur chargement données modération: $e');
    }
  }

  List<Flash> _generatePendingFlashs() {
    return [
      Flash(
        id: 'pending_1',
        title: 'Dragon Japonais',
        description: 'Tatouage dragon traditionnel japonais, style authentique',
        imageUrl: 'https://example.com/dragon.jpg',
        tattooArtistId: 'artist_123',
        tattooArtistName: 'Yuki Tanaka',
        studioName: 'Tokyo Ink Studio',
        style: 'Japonais',
        size: '15x20cm',
        sizeDescription: 'Parfait pour avant-bras ou mollet',
        price: 450.0,
        availableTimeSlots: [
          DateTime.parse('2025-01-20T14:00:00'),
          DateTime.parse('2025-01-21T10:00:00')
        ],
        status: FlashStatus.published, // Utilise votre enum
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        qualityScore: 4.2,
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
      ),
      Flash(
        id: 'pending_2',
        title: 'Rose Minimaliste',
        description: 'Rose simple et élégante pour poignet',
        imageUrl: 'https://example.com/rose.jpg',
        tattooArtistId: 'artist_456',
        tattooArtistName: 'Sophie Martin',
        studioName: 'Ink & Roses Studio',
        style: 'Minimaliste',
        size: '8x6cm',
        sizeDescription: 'Idéal pour poignet ou cheville',
        price: 150.0,
        availableTimeSlots: [DateTime.parse('2025-01-22T15:00:00')],
        status: FlashStatus.published,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        qualityScore: 4.7,
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
      ),
      Flash(
        id: 'pending_3',
        title: 'Géométrique Mandala',
        description: 'Mandala géométrique complexe',
        imageUrl: 'https://example.com/mandala.jpg',
        tattooArtistId: 'artist_789',
        tattooArtistName: 'Alex Dubois',
        studioName: 'Sacred Geometry Tattoo',
        style: 'Géométrique',
        size: '12x12cm',
        sizeDescription: 'Motif centré parfait',
        price: 280.0,
        availableTimeSlots: [
          DateTime.parse('2025-01-23T16:00:00'),
          DateTime.parse('2025-01-24T11:00:00')
        ],
        status: FlashStatus.published,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        qualityScore: 4.5,
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
      ),
    ];
  }

  List<Flash> _generateReportedFlashs() {
    return [
      Flash(
        id: 'reported_1',
        title: 'Skull Gothic',
        description: 'Tête de mort style gothique',
        imageUrl: 'https://example.com/skull.jpg',
        tattooArtistId: 'artist_999',
        tattooArtistName: 'Mike Shadow',
        studioName: 'Dark Ink Studio',
        style: 'Gothique',
        size: '10x8cm',
        sizeDescription: 'Style sombre et mystérieux',
        price: 200.0,
        availableTimeSlots: [DateTime.parse('2025-01-25T14:00:00')],
        status: FlashStatus.published,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        qualityScore: 3.8,
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
        // Note: reportCount et reportReasons ne sont pas dans votre modèle
        // Il faudra les ajouter ou gérer les signalements différemment
      ),
    ];
  }

  List<Flash> _generateRecentlyModerated() {
    return [
      Flash(
        id: 'moderated_1',
        title: 'Papillon Aquarelle',
        description: 'Papillon style aquarelle approuvé',
        imageUrl: 'https://example.com/butterfly.jpg',
        tattooArtistId: 'artist_111',
        tattooArtistName: 'Emma Rousseau',
        studioName: 'Watercolor Tattoo',
        style: 'Aquarelle',
        size: '9x7cm',
        sizeDescription: 'Couleurs vives et fluides',
        price: 180.0,
        availableTimeSlots: [DateTime.parse('2025-01-26T13:00:00')],
        status: FlashStatus.published,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        qualityScore: 4.6,
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
        // Note: moderatedAt, moderatedBy, moderationAction ne sont pas dans votre modèle
        // Il faudra les ajouter ou gérer la modération différemment
      ),
    ];
  }

  Future<void> _moderateFlash(String flashId, String action, {String? reason}) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Simuler traitement
      await Future.delayed(const Duration(milliseconds: 1000));

      // Dans un vrai projet, appeler FlashService.moderateFlash()
      
      if (action == 'approve') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Flash approuvé et publié'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (action == 'reject') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Flash rejeté${reason != null ? " : $reason" : ""}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Recharger les données
      await _loadModerationData();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
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
        title: 'Modération Flashs',
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
                      _buildStatsHeader(),
                      _buildTabBar(),
                      Expanded(
                        child: _buildTabBarView(),
                      ),
                    ],
                  ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
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
          const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Centre de Modération',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PermanentMarker',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'En attente',
                  _totalPending.toString(),
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Signalés',
                  _totalReported.toString(),
                  Icons.report,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Validés',
                  _validatedToday.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Rejetés',
                  _rejectedToday.toString(),
                  Icons.cancel,
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'PermanentMarker',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
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
          fontSize: 12,
        ),
        tabs: [
          Tab(
            text: 'En attente ($_totalPending)',
            icon: const Icon(Icons.pending_actions, size: 20),
          ),
          Tab(
            text: 'Signalés ($_totalReported)',
            icon: const Icon(Icons.report, size: 20),
          ),
          Tab(
            text: 'Récents',
            icon: const Icon(Icons.history, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPendingFlashsList(),
        _buildReportedFlashsList(),
        _buildRecentlyModeratedList(),
      ],
    );
  }

  Widget _buildPendingFlashsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingFlashs.length,
      itemBuilder: (context, index) {
        final flash = _pendingFlashs[index];
        return _buildFlashModerationCard(flash, 'pending');
      },
    );
  }

  Widget _buildReportedFlashsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reportedFlashs.length,
      itemBuilder: (context, index) {
        final flash = _reportedFlashs[index];
        return _buildFlashModerationCard(flash, 'reported');
      },
    );
  }

  Widget _buildRecentlyModeratedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentlyModerated.length,
      itemBuilder: (context, index) {
        final flash = _recentlyModerated[index];
        return _buildFlashModerationCard(flash, 'moderated');
      },
    );
  }

  Widget _buildFlashModerationCard(Flash flash, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                      Text(
                        flash.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PermanentMarker',
                        ),
                      ),
                      Text(
                        'Par ${flash.tattooArtistName}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      Text(
                        '${flash.price.toStringAsFixed(0)}€ • ${flash.style} • ${flash.size}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
                if (type == 'reported') // Simuler signalements
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '3 signalements', // Valeur simulée
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              flash.description,
              style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'Roboto',
              ),
            ),
            
            if (type == 'reported') // Simuler raisons de signalement
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raisons du signalement:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 12,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Contenu inapproprié',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    Text(
                      '• Qualité douteuse',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    Text(
                      '• Plagiat possible',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            if (type == 'pending' || type == 'reported')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _moderateFlash(flash.id, 'approve'),
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontFamily: 'PermanentMarker',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRejectDialog(flash),
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontFamily: 'PermanentMarker',
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (type == 'moderated')
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1), // Simuler approbation
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Approuvé',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Il y a 30 min',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'Roboto',
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

  void _showRejectDialog(Flash flash) {
    String? selectedReason;
    String customReason = '';
    
    final reasons = [
      'Qualité insuffisante',
      'Contenu inapproprié',
      'Violation droits d\'auteur',
      'Informations manquantes',
      'Prix incohérent',
      'Autre (préciser)',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Rejeter "${flash.title}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Raison du rejet:'),
              const SizedBox(height: 8),
              ...reasons.map((reason) => RadioListTile<String>(
                title: Text(reason, style: const TextStyle(fontSize: 14)),
                value: reason,
                groupValue: selectedReason,
                onChanged: (value) {
                  setDialogState(() {
                    selectedReason = value;
                  });
                },
              )),
              if (selectedReason == 'Autre (préciser)')
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Précisez la raison...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => customReason = value,
                  maxLines: 2,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedReason != null ? () {
                Navigator.pop(context);
                final reason = selectedReason == 'Autre (préciser)' 
                    ? customReason 
                    : selectedReason;
                _moderateFlash(flash.id, 'reject', reason: reason);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rejeter'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'quelques secondes';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} h';
    } else {
      return '${difference.inDays} j';
    }
  }
}