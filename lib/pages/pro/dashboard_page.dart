// lib/pages/pro/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_kipik.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

// Imports pour la navigation
import 'package:kipik_v5/pages/pro/home_page_pro.dart';
import 'package:kipik_v5/pages/pro/agenda/pro_agenda_home_page.dart';
import 'package:kipik_v5/pages/pro/attente_devis_page.dart';
import 'package:kipik_v5/pages/chat_projet_page.dart';

// Import pour le dashboard abonnement
import 'package:kipik_v5/screens/subscription/subscription_dashboard.dart';

// Modèles pour les notifications
enum NotificationType { newMessage, newQuote, appointment, payment, review, urgent }

class DashboardNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isUrgent;
  final int? count;

  DashboardNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isUrgent = false,
    this.count,
  });
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Données de performance
  final double _chiffreAffaires = 12345.67;
  final double _caObjectif = 15000.00;
  final int _nouveauxClients = 7;
  
  // Données d'activité récente
  final int _devisEnAttente = 4;
  final int _messagesNonLus = 7;
  final int _rdvAConfirmer = 2;
  final int _paiementsEnAttente = 1;
  final int _rdvAujourdhui = 3;
  final int _notificationsUrgentes = 5;

  // Notifications récentes
  late final List<DashboardNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeNotifications() {
    final now = DateTime.now();
    _notifications = [
      DashboardNotification(
        id: '1',
        type: NotificationType.urgent,
        title: 'Urgent',
        description: 'Priorité',
        timestamp: now,
        isUrgent: true,
        count: _notificationsUrgentes,
      ),
      DashboardNotification(
        id: '2',
        type: NotificationType.newQuote,
        title: 'Devis',
        description: 'En attente',
        timestamp: now.subtract(const Duration(hours: 2)),
        isUrgent: _devisEnAttente > 0,
        count: _devisEnAttente,
      ),
      DashboardNotification(
        id: '3',
        type: NotificationType.appointment,
        title: 'RDV',
        description: 'Aujourd\'hui',
        timestamp: now.subtract(const Duration(minutes: 30)),
        isUrgent: false,
        count: _rdvAujourdhui,
      ),
      DashboardNotification(
        id: '4',
        type: NotificationType.newMessage,
        title: 'Messages',
        description: 'Non lus',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isUrgent: _messagesNonLus > 5,
        count: _messagesNonLus,
      ),
      DashboardNotification(
        id: '5',
        type: NotificationType.appointment,
        title: 'Confirmer',
        description: 'En attente',
        timestamp: now.subtract(const Duration(hours: 4)),
        isUrgent: true,
        count: _rdvAConfirmer,
      ),
      DashboardNotification(
        id: '6',
        type: NotificationType.payment,
        title: 'Paiements',
        description: 'Attente',
        timestamp: now.subtract(const Duration(hours: 6)),
        isUrgent: _paiementsEnAttente > 0,
        count: _paiementsEnAttente,
      ),
    ];
  }

  double get _progressCA => _chiffreAffaires / _caObjectif;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePagePro()),
        );
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF0A0A0A),
        extendBodyBehindAppBar: true,
        endDrawer: const CustomDrawerKipik(),
        appBar: CustomAppBarKipik(
          title: 'Tableau de bord',
          showBackButton: true,
          showNotificationIcon: true,
          notificationCount: _notificationsUrgentes,
          useProStyle: true,
          onBackPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePagePro()),
            );
          },
          onNotificationPressed: () {
            _showNotificationsModal();
          },
        ),
        body: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // 1. Bulle de salutation en premier
                _buildWelcomeSection(),
                
                const SizedBox(height: 24),
                
                // 2. Mini-cartes de notifications
                _buildNotificationCards(),
                
                const SizedBox(height: 32),
                
                // 3. Carte de performance
                _buildPerformanceCard(),
                
                const SizedBox(height: 32),
                
                // 4. Section rendez-vous du jour
                _buildTodayAppointments(),
                
                const SizedBox(height: 32),
                
                // 5. Actions rapides
                _buildQuickActions(),
                
                const SizedBox(height: 32),
                
                // 6. Activité récente
                _buildRecentActivity(),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: KipikTheme.rouge,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: KipikTheme.rouge.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Bonjour';
    } else if (hour < 18) {
      greeting = 'Bon après-midi';
    } else {
      greeting = 'Bonsoir';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KipikTheme.rouge.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: KipikTheme.rouge.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KipikTheme.rouge.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: KipikTheme.rouge.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  color: KipikTheme.rouge,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting !',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 24,
                    color: KipikTheme.rouge,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bienvenue dans votre espace professionnel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Gérez votre activité en un coup d\'œil',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCards() {
    final priorityNotifications = _notifications.where((n) => 
      n.count != null && n.count! >= 0
    ).take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Notifications prioritaires', Icons.priority_high),
        const SizedBox(height: 20),
        
        SizedBox(
          height: 200,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: priorityNotifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(priorityNotifications[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(DashboardNotification notification) {
    final color = _getNotificationColor(notification.type);
    final isUrgent = notification.isUrgent;
    final count = notification.count ?? 0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUrgent ? KipikTheme.rouge : color.withOpacity(0.2),
              width: isUrgent ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isUrgent 
                    ? KipikTheme.rouge.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isUrgent ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isUrgent ? KipikTheme.rouge : color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: isUrgent ? KipikTheme.rouge : color,
                          size: 16,
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isUrgent ? KipikTheme.rouge : color,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white,
                                  blurRadius: 1,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    notification.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isUrgent ? KipikTheme.rouge : const Color(0xFF0A0A0A),
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    notification.description,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: isUrgent ? KipikTheme.rouge.withOpacity(0.8) : const Color(0xFF6B7280),
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Performance du mois', Icons.trending_up),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_chiffreAffaires.toStringAsFixed(0)}€',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 32,
                            color: KipikTheme.rouge,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Chiffre d\'affaires',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_nouveauxClients',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 24,
                            color: Color(0xFF0A0A0A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Nouveaux\nclients',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Objectif mensuel',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _progressCA >= 1.0 
                              ? KipikTheme.rouge.withOpacity(0.1)
                              : const Color(0xFF0A0A0A).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(_progressCA * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: _progressCA >= 1.0 
                                ? KipikTheme.rouge
                                : const Color(0xFF374151),
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressCA > 1.0 ? 1.0 : _progressCA,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _progressCA >= 1.0 
                              ? KipikTheme.rouge
                              : const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Objectif: ${_caObjectif.toStringAsFixed(0)}€',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rendez-vous d\'aujourd\'hui', Icons.calendar_today),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.event,
                  color: Color(0xFF0A0A0A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$_rdvAujourdhui',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 24,
                            color: KipikTheme.rouge,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProAgendaHomePage()),
                            ),
                            child: const Text(
                              'rendez-vous',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Prochain RDV dans 2h30',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProAgendaHomePage()),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: KipikTheme.rouge.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: KipikTheme.rouge,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Actions rapides', Icons.flash_on),
        const SizedBox(height: 20),
        
        // Première rangée - Actions classiques
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Devis',
                Icons.request_quote_outlined,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Nouveau devis : Bientôt disponible !',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: KipikTheme.rouge,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionButton(
                'RDV',
                Icons.event_outlined,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProAgendaHomePage()),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Deuxième rangée - Bouton abonnement premium
        _buildPremiumSubscriptionButton(),
      ],
    );
  }

  Widget _buildPremiumSubscriptionButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A0A0A),
                KipikTheme.rouge,
                const Color(0xFF0A0A0A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: KipikTheme.rouge.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionDashboard(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Icône tatouage avec animation
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Texte
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Mon Abonnement Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'PermanentMarker',
                              fontWeight: FontWeight.w400,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Gérez votre plan et vos commissions',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Badge avec machine à tatouer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: KipikTheme.rouge.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KipikTheme.rouge.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: KipikTheme.rouge, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: KipikTheme.rouge,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentNotifications = _notifications.where((n) => !n.isUrgent).take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Activité récente', Icons.history),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: recentNotifications.asMap().entries.map((entry) {
              final index = entry.key;
              final notification = entry.value;
              final isLast = index == recentNotifications.length - 1;
              
              return _buildActivityItem(notification, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(DashboardNotification notification, bool isLast) {
    final color = _getNotificationColor(notification.type);
    final timeAgo = _getTimeAgo(notification.timestamp);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(
          bottom: BorderSide(
            color: Color(0xFFF3F4F6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(DashboardNotification notification) {
    switch (notification.type) {
      case NotificationType.newQuote:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AttenteDevisPage()),
        );
        break;
      case NotificationType.newMessage:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatProjetPage()),
        );
        break;
      case NotificationType.appointment:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProAgendaHomePage()),
        );
        break;
      case NotificationType.payment:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Paiements : Bientôt disponible !',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: KipikTheme.rouge,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        break;
      case NotificationType.urgent:
        _showNotificationsModal();
        break;
      default:
        break;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.newQuote:
        return Icons.request_quote_outlined;
      case NotificationType.appointment:
        return Icons.event_outlined;
      case NotificationType.payment:
        return Icons.payment_outlined;
      case NotificationType.review:
        return Icons.star_outline;
      case NotificationType.urgent:
        return Icons.priority_high;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return const Color(0xFF0A0A0A);
      case NotificationType.newQuote:
        return const Color(0xFF0A0A0A);
      case NotificationType.appointment:
        return const Color(0xFF0A0A0A);
      case NotificationType.payment:
        return const Color(0xFF0A0A0A);
      case NotificationType.review:
        return const Color(0xFF0A0A0A);
      case NotificationType.urgent:
        return KipikTheme.rouge;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KipikTheme.rouge,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationItem(notification, index == _notifications.length - 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(DashboardNotification notification, bool isLast) {
    final color = _getNotificationColor(notification.type);
    final timeAgo = _getTimeAgo(notification.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isUrgent ? KipikTheme.rouge.withOpacity(0.3) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: notification.isUrgent ? KipikTheme.rouge : const Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (notification.count != null && notification.count! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: notification.isUrgent ? KipikTheme.rouge : color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${notification.count}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
        ],
      ),
    );
  }
}