// lib/pages/conventions/convention_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/widgets/common/buttons/tattoo_assistant_button.dart';
import 'package:kipik_v5/models/convention.dart';
import 'package:kipik_v5/models/user_role.dart';
import 'package:kipik_v5/enums/convention_enums.dart';

// Pages "feature"
import 'package:kipik_v5/pages/conventions/convention_booking_page.dart';
import 'package:kipik_v5/pages/conventions/convention_tattooers_list_page.dart';

// Pages "shared convention system"
import 'package:kipik_v5/pages/shared/conventions/convention_system/interactive_convention_map.dart';
import 'package:kipik_v5/pages/shared/conventions/convention_system/convention_pro_management_page.dart';
import 'package:kipik_v5/pages/shared/conventions/convention_system/convention_stand_optimizer.dart';

class ConventionDetailPage extends StatefulWidget {
  final String conventionId;
  final UserRole? userRole;

  const ConventionDetailPage({
    Key? key,
    required this.conventionId,
    this.userRole,
  }) : super(key: key);

  @override
  State<ConventionDetailPage> createState() => _ConventionDetailPageState();
}

class _ConventionDetailPageState extends State<ConventionDetailPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;
  
  Convention? _convention;
  UserRole _currentUserRole = UserRole.particulier;
  bool _isLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _currentUserRole = widget.userRole ?? UserRole.particulier;
    _initializeAnimations();
    _loadConventionData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  void _loadConventionData() {
    // Simulation chargement données avec style KIPIK
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        _convention = Convention(
          id: widget.conventionId,
          title: 'Paris Tattoo Convention 2025',
          location: 'Paris Expo, Porte de Versailles, Hall 1',
          start: DateTime(2025, 8, 15),
          end: DateTime(2025, 8, 17),
          description: '''🎨 LA PLUS GRANDE CONVENTION TATTOO DE FRANCE !

Retrouvez plus de 300 artistes tatoueurs internationaux, des concours prestigieux, des démonstrations live et bien plus encore dans l'ambiance unique KIPIK.

Cette édition 2025 propose :
• 🏆 Concours du meilleur tatouage par catégorie
• 🎓 Ateliers de formation pour débutants
• 💎 Zone dédiée aux piercings premium
• 🛠️ Stands de matériel professionnel
• 🎵 Concerts et animations live
• 🔥 Zone FLASH MINUTE exclusive''',
          imageUrl: 'https://example.com/paris-tattoo-2025.jpg',
          isOpen: true,
          isPremium: true,
          artists: ['Alex "Ink Master" Martin', 'Emma "Black Rose" Dubois', 'Marco "Neo Spirit" Silva', 'Sophie "Fine Line" Chen'],
          events: [
            '🏆 Concours Best of Show - Samedi 20h',
            '🎓 Atelier débutant KIPIK - Dimanche 14h',
            '🎸 Concert punk rock - Samedi 22h',
            '👗 Défilé de mode tatouée - Dimanche 18h',
            '⚡ Flash Minute Battle - Dimanche 16h'
          ],
          proSpots: 85,
          merchandiseSpots: 25,
          dayTicketPrice: 25,
          weekendTicketPrice: 45,
          website: 'https://paristattooconvention.com',
        );
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: DrawerFactory.of(context),
      extendBodyBehindAppBar: true,
      appBar: CustomAppBarKipik(
        title: _convention?.title ?? 'Convention',
        subtitle: _getRoleDisplayName(_currentUserRole),
        showBackButton: true,
        showBurger: true,
        useProStyle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareConvention,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border, 
              color: _isFavorite ? KipikTheme.rouge : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      floatingActionButton: const TattooAssistantButton(),
      body: Stack(
        children: [
          // Background KIPIK
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.grey.shade900,
                  Colors.black,
                ],
              ),
            ),
          ),

          // Pattern KIPIK subtil
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/background_charbon.png',
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),

          // Contenu principal
          _isLoading ? _buildLoadingKIPIK() : _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildLoadingKIPIK() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo/Animation KIPIK style
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: KipikTheme.rouge,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'CHARGEMENT CONVENTION',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Préparation de l\'expérience KIPIK...',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          slivers: [
            _buildHeroSliver(),
            _buildContentSliver(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSliver() {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: false,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image avec overlay KIPIK
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: _convention?.imageUrl != null
                  ? Image.network(
                      _convention!.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              KipikTheme.rouge.withOpacity(0.3),
                              Colors.black,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.event, size: 120, color: Colors.white30),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            KipikTheme.rouge.withOpacity(0.3),
                            Colors.black,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.event, size: 120, color: Colors.white30),
                      ),
                    ),
            ),
            
            // Overlay informations KIPIK
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - _cardAnimation.value)),
                    child: Opacity(
                      opacity: _cardAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge Premium KIPIK
                          if (_convention?.isPremium == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: KipikTheme.rouge.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'PREMIUM KIPIK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      fontFamily: 'Roboto',
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Titre avec style KIPIK
                          Text(
                            _convention?.title ?? '',
                            style: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 32,
                              color: Colors.white,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  blurRadius: 15.0,
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                ),
                                Shadow(
                                  blurRadius: 25.0,
                                  color: Colors.black54,
                                  offset: Offset(4, 4),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Localisation avec icône KIPIK
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: KipikTheme.rouge.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, color: KipikTheme.rouge, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _convention?.location ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCardsKIPIK(),
            const SizedBox(height: 32),
            _buildNavigationActions(),
            const SizedBox(height: 32),
            _buildDescriptionKIPIK(),
            const SizedBox(height: 32),
            _buildArtistsSectionKIPIK(),
            const SizedBox(height: 32),
            _buildEventsSectionKIPIK(),
            const SizedBox(height: 32),
            _buildActionButtonsKIPIK(),
            const SizedBox(height: 120), // Espace pour FAB
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCardsKIPIK() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Row(
            children: [
              Expanded(
                child: _buildInfoCardKIPIK(
                  icon: Icons.calendar_today,
                  title: 'DATES',
                  content: _formatDateRange(),
                  color: KipikTheme.rouge,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCardKIPIK(
                  icon: Icons.people,
                  title: 'STATUT',
                  content: _convention?.isOpen == true ? 'OUVERT' : 'FERMÉ',
                  color: _convention?.isOpen == true ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCardKIPIK(
                  icon: Icons.euro,
                  title: 'ENTRÉE',
                  content: '${_convention?.dayTicketPrice ?? 0}€',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCardKIPIK({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            Colors.black.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: KipikTheme.rouge, size: 24),
            const SizedBox(width: 12),
            const Text(
              'ACTIONS RAPIDES',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Actions selon le rôle utilisateur avec style KIPIK
        if (_currentUserRole == UserRole.particulier) ...[
          _buildActionCardKIPIK(
            icon: Icons.calendar_month,
            title: 'RÉSERVER UN CRÉNEAU',
            subtitle: 'Prendre RDV avec un tatoueur premium',
            color: KipikTheme.rouge,
            onTap: () => _navigateToBooking(),
          ),
          const SizedBox(height: 16),
          _buildActionCardKIPIK(
            icon: Icons.map,
            title: 'PLAN INTERACTIF',
            subtitle: 'Explorer la convention en 3D',
            color: Colors.blue,
            onTap: () => _navigateToInteractiveMap(),
          ),
          const SizedBox(height: 16),
          _buildActionCardKIPIK(
            icon: Icons.people,
            title: 'ARTISTES PRÉSENTS',
            subtitle: 'Découvrir tous les tatoueurs',
            color: Colors.purple,
            onTap: () => _navigateToTattooersList(),
          ),
        ],
        
        if (_currentUserRole == UserRole.tatoueur) ...[
          _buildActionCardKIPIK(
            icon: Icons.business_center,
            title: 'GESTION PRO',
            subtitle: 'Gérer mes stands et réservations',
            color: KipikTheme.rouge,
            onTap: () => _navigateToProManagement(),
          ),
          const SizedBox(height: 16),
          _buildActionCardKIPIK(
            icon: Icons.map,
            title: 'MON STAND',
            subtitle: 'Mode tatoueur - Gérer mon espace',
            color: Colors.blue,
            onTap: () => _navigateToInteractiveMap(),
          ),
        ],
        
        if (_currentUserRole == UserRole.organisateur || _currentUserRole == UserRole.admin) ...[
          _buildActionCardKIPIK(
            icon: Icons.tune,
            title: 'OPTIMISEUR STANDS',
            subtitle: 'Maximiser la rentabilité',
            color: Colors.green,
            onTap: () => _navigateToStandOptimizer(),
          ),
          const SizedBox(height: 16),
          _buildActionCardKIPIK(
            icon: Icons.admin_panel_settings,
            title: 'PANNEAU ADMIN',
            subtitle: 'Contrôle total de la convention',
            color: KipikTheme.rouge,
            onTap: () => _navigateToProManagement(),
          ),
        ],
      ],
    );
  }

  Widget _buildActionCardKIPIK({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              Colors.black.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionKIPIK() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _cardAnimation.value)),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: KipikTheme.rouge, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'À PROPOS',
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.grey.shade900.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: KipikTheme.rouge.withOpacity(0.2)),
                  ),
                  child: Text(
                    _convention?.description ?? '',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.6,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtistsSectionKIPIK() {
    if (_convention?.artists?.isEmpty ?? true) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette, color: KipikTheme.rouge, size: 24),
            const SizedBox(width: 12),
            const Text(
              'ARTISTES CONFIRMÉS',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _convention!.artists!.map((artist) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    KipikTheme.rouge.withOpacity(0.2),
                    KipikTheme.rouge.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: KipikTheme.rouge.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: KipikTheme.rouge.withOpacity(0.1),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                artist,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEventsSectionKIPIK() {
    if (_convention?.events?.isEmpty ?? true) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_note, color: KipikTheme.rouge, size: 24),
            const SizedBox(width: 12),
            const Text(
              'ÉVÉNEMENTS SPÉCIAUX',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.grey.shade900.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KipikTheme.rouge.withOpacity(0.2)),
          ),
          child: Column(
            children: _convention!.events!.asMap().entries.map((entry) {
              int index = entry.key;
              String event = entry.value;
              bool isLast = index == _convention!.events!.length - 1;
              
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: isLast ? null : Border(
                    bottom: BorderSide(color: Colors.grey.shade800, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            KipikTheme.rouge.withOpacity(0.3),
                            KipikTheme.rouge.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.event, color: KipikTheme.rouge, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        event,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsKIPIK() {
    return Column(
      children: [
        if (_convention?.isOpen == true) ...[
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: KipikTheme.rouge.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _navigateToBooking,
              icon: const Icon(Icons.calendar_month, color: Colors.white, size: 24),
              label: const Text(
                'RÉSERVER MAINTENANT',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        Container(
          width: double.infinity,
          height: 60,
          child: OutlinedButton.icon(
            onPressed: _openWebsite,
            icon: const Icon(Icons.language, size: 24),
            label: const Text(
              'SITE WEB OFFICIEL',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Navigation methods
  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConventionBookingPage(
          conventionId: widget.conventionId,
        ),
      ),
    );
  }

  void _navigateToTattooersList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConventionTattooersListPage(
          conventionId: widget.conventionId,
        ),
      ),
    );
  }

  void _navigateToInteractiveMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InteractiveConventionMap(
          conventionId: widget.conventionId,
          initialMode: _getModeForRole(),
          userType: _currentUserRole,
          currentUserId: 'current-user-id',
        ),
      ),
    );
  }

  void _navigateToProManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConventionProManagementPage(
          conventionId: widget.conventionId,  // ✅ Paramètre ajouté
        ),
      ),
    );
  }

  void _navigateToStandOptimizer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConventionStandOptimizer(
          conventionId: widget.conventionId,  // ✅ CORRECTION ICI : Utilise widget.conventionId
          userType: _currentUserRole,
        ),
      ),
    );
  }

  MapMode _getModeForRole() {
    switch (_currentUserRole) {
      case UserRole.organisateur:
      case UserRole.admin:
        return MapMode.organizer;
      case UserRole.tatoueur:
        return MapMode.tattooer;
      default:
        return MapMode.visitor;
    }
  }

  void _shareConvention() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.share, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              'Convention partagée !',
              style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? KipikTheme.rouge : Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              _isFavorite ? 'Ajouté aux favoris !' : 'Retiré des favoris',
              style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: _isFavorite ? Colors.green : Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openWebsite() {
    if (_convention?.website != null) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.language, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Ouverture de ${_convention!.website}',
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _formatDateRange() {
    if (_convention == null) return '';
    final start = _convention!.start;
    final end = _convention!.end;
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.particulier:
        return 'Visiteur';
      case UserRole.tatoueur:
        return 'Tatoueur';
      case UserRole.organisateur:
        return 'Organisateur';
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.client:
        return 'Client';
    }
  }
}