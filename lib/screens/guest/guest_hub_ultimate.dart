// lib/screens/guest/guest_hub_ultimate.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../models/guest_mission.dart';
import '../../services/guest/guest_service.dart';
import 'widgets/guest_mission_card.dart';
import 'widgets/guest_opportunity_card.dart';
import 'widgets/quick_stats_widget.dart';
import '../../pages/pro/booking/guest_system/guest_marketplace_page.dart';
import '../../pages/pro/booking/guest_system/guest_contract_page.dart';
import '../../pages/pro/booking/guest_system/guest_notifications.dart';
import '../../pages/pro/booking/guest_system/guest_tracking_page.dart';
import '../../pages/pro/booking/guest_system/guest_proposal_page.dart';

// 🎯 Utilise le GuestStats de ton widget existant
// Import depuis ton widget
// Model simple pour opportunités (à adapter selon tes besoins)
class GuestOpportunity {
  final String id;
  final String ownerName;
  final String location;
  final List<String> styles;
  final String description;
  final double commissionRate;
  final bool accommodationProvided;
  final String experienceLevel;
  final double rating;
  final int reviewCount;
  final bool isGuestOffer;

  const GuestOpportunity({
    required this.id,
    required this.ownerName,
    required this.location,
    required this.styles,
    required this.description,
    required this.commissionRate,
    required this.accommodationProvided,
    required this.experienceLevel,
    required this.rating,
    required this.reviewCount,
    required this.isGuestOffer,
  });
}

class GuestHubUltimate extends StatefulWidget {
  const GuestHubUltimate({super.key});

  @override
  State<GuestHubUltimate> createState() => _GuestHubUltimateState();
}

class _GuestHubUltimateState extends State<GuestHubUltimate>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _cardController;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _cardAnimation;
  
  bool _isLoading = false;
  String _currentUserId = 'demo_user';
  
  // Données Guest System (compatible avec tes widgets)
  List<GuestMission> _activeMissions = [];
  List<GuestMission> _pendingRequests = [];
  List<GuestMission> _incomingRequests = [];
  List<GuestOpportunity> _suggestedOpportunities = [];
  // Utilise le GuestStats de ton widget

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadGuestData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
    
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardController.forward();
    });
  }

  void _loadGuestData() {
    // Stats compatibles avec ton widget GuestStats
    // Utilise les mêmes noms de propriétés que ton widget
    
    // Missions actives
    _activeMissions = [
      GuestMission(
        id: 'mission_1',
        guestId: 'emma_chen',
        shopId: _currentUserId,
        guestName: 'Emma Chen',
        shopName: 'Mon Studio',
        location: 'Mon studio',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 9)),
        type: GuestMissionType.incoming,
        status: GuestMissionStatus.active,
        commissionRate: 0.25,
        accommodationIncluded: false,
        styles: ['Japonais', 'Traditionnel'],
        description: 'Mission guest japonais traditionnel',
        totalRevenue: 1250.0,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      GuestMission(
        id: 'mission_2',
        guestId: _currentUserId,
        shopId: 'ink_studio_paris',
        guestName: 'Moi',
        shopName: 'Ink Studio Paris',
        location: 'Paris 9ème',
        startDate: DateTime.now().add(const Duration(days: 20)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        type: GuestMissionType.outgoing,
        status: GuestMissionStatus.accepted,
        commissionRate: 0.20,
        accommodationIncluded: true,
        styles: ['Réalisme', 'Portrait'],
        description: 'Guest dans studio parisien réputé',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    // Demandes reçues
    _incomingRequests = [
      GuestMission(
        id: 'incoming_1',
        guestId: 'alex_martin',
        shopId: _currentUserId,
        guestName: 'Alex Martin',
        shopName: 'Mon Studio',
        location: 'Mon studio',
        startDate: DateTime.now().add(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 25)),
        type: GuestMissionType.incoming,
        status: GuestMissionStatus.pending,
        commissionRate: 0.25,
        accommodationIncluded: true,
        styles: ['Réalisme', 'Portrait'],
        description: 'Guest réalisme expérimenté recherche collaboration',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      GuestMission(
        id: 'incoming_2',
        guestId: 'sofia_rodriguez',
        shopId: _currentUserId,
        guestName: 'Sofia Rodriguez',
        shopName: 'Mon Studio',
        location: 'Mon studio',
        startDate: DateTime.now().add(const Duration(days: 60)),
        endDate: DateTime.now().add(const Duration(days: 81)),
        type: GuestMissionType.incoming,
        status: GuestMissionStatus.pending,
        commissionRate: 0.30,
        accommodationIncluded: true,
        styles: ['Couleur', 'Neo-traditionnel'],
        description: 'Artiste couleur recherche studio accueillant',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    // Opportunités suggérées (format compatible avec ton widget)
    _suggestedOpportunities = [
      const GuestOpportunity(
        id: 'opp_1',
        ownerName: 'Nice Tattoo Studio',
        location: 'Nice',
        styles: ['Tous styles'],
        description: 'Studio en bord de mer recherche guest talentueux pour l\'été',
        commissionRate: 0.20,
        accommodationProvided: true,
        experienceLevel: 'Confirmé',
        rating: 4.8,
        reviewCount: 156,
        isGuestOffer: false,
      ),
      const GuestOpportunity(
        id: 'opp_2',
        ownerName: 'Marie Dubois',
        location: 'Bordeaux',
        styles: ['Minimaliste', 'Fine line'],
        description: 'Artiste fine line disponible pour guest d\'une semaine',
        commissionRate: 0.25,
        accommodationProvided: false,
        experienceLevel: 'Expert',
        rating: 4.9,
        reviewCount: 89,
        isGuestOffer: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Guest Hub',
        subtitle: 'Centre de contrôle Premium',
        showBackButton: true,
        useProStyle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => _navigateToNotifications(),
              ),
              if (_getUnreadNotificationsCount() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_getUnreadNotificationsCount()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActions(),
      body: Stack(
        children: [
          // Background charbon
          Image.asset(
            'assets/background_charbon.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          
          SafeArea(
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Chargement de votre espace Guest...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: CustomScrollView(
          slivers: [
            // Hero Section
            SliverToBoxAdapter(child: _buildHeroSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Quick Stats
            SliverToBoxAdapter(child: _buildQuickStats()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Navigation rapide
            SliverToBoxAdapter(child: _buildQuickNavigation()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Demandes urgentes
            if (_incomingRequests.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildUrgentRequests()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
            
            // Missions actives
            SliverToBoxAdapter(child: _buildActiveMissions()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Opportunités suggérées
            SliverToBoxAdapter(child: _buildSuggestedOpportunities()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Actions rapides
            SliverToBoxAdapter(child: _buildQuickActions()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  KipikTheme.rouge.withOpacity(0.9),
                  Colors.purple.withOpacity(0.8),
                  Colors.blue.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: KipikTheme.rouge.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.handshake,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GUEST SYSTEM',
                            style: TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Premium • Hub de contrôle unifié',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Colors.green,
                                  size: 8,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'ACTIF',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Stats hero (simplifiées pour correspondre à tes widgets)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroStat('${_activeMissions.length}', 'Missions\nactives', Icons.play_circle),
                    _buildHeroStat('${_incomingRequests.length}', 'Demandes\nreçues', Icons.inbox),
                    _buildHeroStat('1250€', 'Revenus\nce mois', Icons.trending_up),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
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
    );
  }

  Widget _buildQuickStats() {
    // Crée les données directement ici pour éviter les conflits de types
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              KipikTheme.rouge.withOpacity(0.8),
              Colors.purple.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Aperçu Guest',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
                       
            const SizedBox(height: 20),
                       
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Missions',
                  '${_activeMissions.length}',
                  Icons.handshake,
                  'actives',
                ),
                _buildStatItem(
                  'Revenus',
                  '1250€',
                  Icons.euro,
                  'ce mois',
                ),
                _buildStatItem(
                  'Note',
                  '4.7',
                  Icons.star,
                  '23 avis',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickNavigation() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: KipikTheme.rouge, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Navigation rapide',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildNavCard('Marketplace', '🏪', 'Chercher\nopportunités', () => _navigateToMarketplace())),
                const SizedBox(width: 12),
                Expanded(child: _buildNavCard('Contrats', '📄', 'Gérer\ncontrats', () => _navigateToContracts())),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(child: _buildNavCard('Suivi', '📊', 'Revenus &\nmétriques', () => _navigateToTracking())),
                const SizedBox(width: 12),
                Expanded(child: _buildNavCard('Calendrier', '📅', 'Planning\nGuest', () => _navigateToCalendar())),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavCard(String title, String emoji, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              KipikTheme.rouge.withOpacity(0.1),
              KipikTheme.rouge.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KipikTheme.rouge.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: KipikTheme.rouge,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentRequests() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: _buildSection(
            title: '🚨 Demandes urgentes',
            subtitle: '${_incomingRequests.length} demande${_incomingRequests.length > 1 ? 's' : ''} en attente',
            urgent: true,
            children: _incomingRequests.take(2).map((request) => 
              GuestMissionCard(
                mission: request,
                type: GuestMissionCardType.incoming,
                onTap: () => _onMissionTap(request),
                onAccept: () => _onAcceptRequest(request),
                onDecline: () => _onDeclineRequest(request),
              ),
            ).toList(),
            action: _incomingRequests.length > 2 ? TextButton(
              onPressed: () => _navigateToContracts(),
              child: Text(
                'Voir toutes les demandes →',
                style: TextStyle(
                  color: KipikTheme.rouge,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ) : null,
          ),
        );
      },
    );
  }

  Widget _buildActiveMissions() {
    if (_activeMissions.isEmpty) {
      return _buildEmptySection(
        '🎯 Missions actives',
        'Aucune mission en cours',
        'Explorez le marketplace pour trouver de nouvelles opportunités',
        Icons.search,
        () => _navigateToMarketplace(),
      );
    }

    return _buildSection(
      title: '🎯 Missions actives',
      subtitle: '${_activeMissions.length} mission${_activeMissions.length > 1 ? 's' : ''} en cours',
      children: _activeMissions.map((mission) => 
        GuestMissionCard(
          mission: mission,
          type: GuestMissionCardType.active,
          onTap: () => _onMissionTap(mission),
          onViewContract: () => _onViewContract(mission),
        ),
      ).toList(),
    );
  }

  Widget _buildSuggestedOpportunities() {
    if (_suggestedOpportunities.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: '✨ Opportunités suggérées',
      subtitle: 'Basées sur votre profil et localisation',
      children: _suggestedOpportunities.take(2).map((opportunity) => 
        GuestOpportunityCard(
          opportunity: {
            'ownerName': opportunity.ownerName,
            'location': opportunity.location,
            'styles': opportunity.styles,
            'description': opportunity.description,
            'commissionRate': opportunity.commissionRate,
            'accommodationProvided': opportunity.accommodationProvided,
            'experienceLevel': opportunity.experienceLevel,
            'rating': opportunity.rating,
            'reviewCount': opportunity.reviewCount,
            'isGuestOffer': opportunity.isGuestOffer,
          },
          onTap: () => _onOpportunityTap(opportunity),
          onApply: () => _onApplyToOpportunity(opportunity),
        ),
      ).toList(),
      action: _suggestedOpportunities.length > 2 ? TextButton(
        onPressed: () => _navigateToMarketplace(),
        child: Text(
          'Voir toutes les opportunités →',
          style: TextStyle(
            color: KipikTheme.rouge,
            fontWeight: FontWeight.w600,
          ),
        ),
      ) : null,
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Actions rapides',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Créer proposition',
                  Icons.add_circle,
                  KipikTheme.rouge,
                  () => _createProposal(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Rechercher',
                  Icons.search,
                  Colors.blue,
                  () => _navigateToMarketplace(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
    bool urgent = false,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent 
              ? Colors.orange.withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
          width: urgent ? 2 : 1,
        ),
        boxShadow: urgent ? [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: urgent ? Colors.orange : Colors.black87,
                        fontFamily: 'PermanentMarker',
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (urgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
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
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...children,
          ],
          if (action != null) ...[
            const SizedBox(height: 12),
            action,
          ],
        ],
      ),
    );
  }

  Widget _buildEmptySection(
    String title,
    String emptyTitle,
    String emptySubtitle,
    IconData icon,
    VoidCallback onAction,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'PermanentMarker',
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: KipikTheme.rouge.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: KipikTheme.rouge,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  emptySubtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KipikTheme.rouge,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Explorer maintenant',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Rechercher
        FloatingActionButton(
          heroTag: "search",
          onPressed: () {
            HapticFeedback.lightImpact();
            _navigateToMarketplace();
          },
          backgroundColor: KipikTheme.rouge,
          child: const Icon(Icons.search, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Créer une demande
        FloatingActionButton.extended(
          heroTag: "create",
          onPressed: () {
            HapticFeedback.mediumImpact();
            _createProposal();
          },
          backgroundColor: Colors.purple,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nouvelle demande',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto',
            ),
          ),
        ),
        const SizedBox(height: 12),
        const TattooAssistantButton(),
      ],
    );
  }

  // ==================== ACTIONS ====================

  void _navigateToMarketplace() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GuestMarketplacePage()),
    );
  }

  void _navigateToContracts() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GuestContractPage()),
    );
  }

  void _navigateToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GuestNotifications()),
    );
  }

  void _navigateToTracking() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GuestTrackingPage()),
    );
  }

  void _navigateToCalendar() {
    _showInfoSnackBar('Calendrier Guest - Navigation à implémenter');
  }

  void _createProposal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GuestProposalPage(mode: ProposalMode.create),
      ),
    );
  }

  void _onMissionTap(GuestMission mission) {
    HapticFeedback.selectionClick();
    _navigateToTracking();
  }

  void _onOpportunityTap(GuestOpportunity opportunity) {
    HapticFeedback.selectionClick();
    _navigateToMarketplace();
  }

  void _onApplyToOpportunity(GuestOpportunity opportunity) {
    HapticFeedback.mediumImpact();
    _createProposal();
  }

  void _onAcceptRequest(GuestMission request) async {
    HapticFeedback.mediumImpact();
    _showSuccessSnackBar('Mission acceptée ! Contrat en cours de génération.');
    
    setState(() {
      _incomingRequests.removeWhere((r) => r.id == request.id);
      _activeMissions.add(request.copyWith(status: GuestMissionStatus.active));
    });
  }

  void _onDeclineRequest(GuestMission request) async {
    HapticFeedback.lightImpact();
    _showInfoSnackBar('Mission refusée. Le demandeur sera notifié.');
    
    setState(() {
      _incomingRequests.removeWhere((r) => r.id == request.id);
    });
  }

  void _onViewContract(GuestMission mission) {
    _navigateToContracts();
  }

  void _refreshData() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isLoading = false);
    _showSuccessSnackBar('Données actualisées !');
  }

  // ==================== HELPER METHODS ====================

  int _getUnreadNotificationsCount() {
    return _incomingRequests.length + _pendingRequests.where((r) => r.isPending).length;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ==================== EXTENSIONS ====================

// Extension pour copyWith sur GuestMission  
extension GuestMissionCopyWith on GuestMission {
  GuestMission copyWith({
    String? id,
    String? guestId,
    String? shopId,
    String? guestName,
    String? shopName,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    GuestMissionType? type,
    GuestMissionStatus? status,
    double? commissionRate,
    bool? accommodationIncluded,
    List<String>? styles,
    String? description,
    double? totalRevenue,
    String? contractId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GuestMission(
      id: id ?? this.id,
      guestId: guestId ?? this.guestId,
      shopId: shopId ?? this.shopId,
      guestName: guestName ?? this.guestName,
      shopName: shopName ?? this.shopName,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      status: status ?? this.status,
      commissionRate: commissionRate ?? this.commissionRate,
      accommodationIncluded: accommodationIncluded ?? this.accommodationIncluded,
      styles: styles ?? this.styles,
      description: description ?? this.description,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      contractId: contractId ?? this.contractId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}