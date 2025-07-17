// lib/pages/pro/agenda/pro_agenda_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_kipik.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/buttons/tattoo_assistant_button.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/pages/pro/home_page_pro.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';

enum EventType { consultation, session, retouche, suivi, personnel, flashMinute }
enum ViewType { day, week, month }
enum LocationType { shop, guest, convention }

class AgendaEvent {
  final String id;
  final String title;
  final String? clientName;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final String? description;
  final String? location;
  final LocationType locationType;
  final bool isConfirmed;
  final String? phoneNumber;
  final String? email;
  final double? price;
  final bool isFlashMinute;
  final int? flashMinuteDiscount;
  final DateTime? flashMinuteExpiry;

  AgendaEvent({
    required this.id,
    required this.title,
    this.clientName,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.description,
    this.location,
    this.locationType = LocationType.shop,
    this.isConfirmed = false,
    this.phoneNumber,
    this.email,
    this.price,
    this.isFlashMinute = false,
    this.flashMinuteDiscount,
    this.flashMinuteExpiry,
  });

  Duration get duration => endTime.difference(startTime);
  
  bool isOnDay(DateTime day) {
    return startTime.year == day.year &&
           startTime.month == day.month &&
           startTime.day == day.day;
  }
  
  Color get eventColor {
    if (isFlashMinute) return Colors.orange;
    switch (type) {
      case EventType.consultation:
        return KipikTheme.rouge;
      case EventType.session:
        return const Color(0xFF2E7D32);
      case EventType.retouche:
        return const Color(0xFF1565C0);
      case EventType.suivi:
        return const Color(0xFF7B1FA2);
      case EventType.personnel:
        return const Color(0xFF424242);
      case EventType.flashMinute:
        return Colors.orange;
    }
  }

  String get typeLabel {
    if (isFlashMinute) return 'Flash Minute';
    switch (type) {
      case EventType.consultation:
        return 'Consultation';
      case EventType.session:
        return 'Séance tatouage';
      case EventType.retouche:
        return 'Retouche';
      case EventType.suivi:
        return 'Suivi';
      case EventType.personnel:
        return 'Personnel';
      case EventType.flashMinute:
        return 'Flash Minute';
    }
  }

  String get locationLabel {
    switch (locationType) {
      case LocationType.shop:
        return 'Salon';
      case LocationType.guest:
        return 'Guest';
      case LocationType.convention:
        return 'Convention';
    }
  }

  IconData get locationIcon {
    switch (locationType) {
      case LocationType.shop:
        return Icons.home_work;
      case LocationType.guest:
        return Icons.flight;
      case LocationType.convention:
        return Icons.event;
    }
  }

  bool get canActivateFlashMinute {
    return isConfirmed && 
           !isFlashMinute && 
           startTime.isAfter(DateTime.now()) &&
           startTime.difference(DateTime.now()).inHours >= 1 &&
           startTime.difference(DateTime.now()).inDays <= 1;
  }
}

class ProAgendaHomePage extends StatefulWidget {
  const ProAgendaHomePage({Key? key}) : super(key: key);

  @override
  State<ProAgendaHomePage> createState() => _ProAgendaHomePageState();
}

class _ProAgendaHomePageState extends State<ProAgendaHomePage> 
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late DateTime _selectedDate;
  ViewType _currentView = ViewType.day;
  late List<AgendaEvent> _events;
  final ScrollController _dayScrollController = ScrollController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _flashController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _flashAnimation;
  
  // État
  bool _showFlashMinuteBar = false;
  int _activeFlashMinutes = 0;
  Timer? _refreshTimer;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initializeAnimations();
    _initializeEvents();
    _startRefreshTimer();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentView == ViewType.day) {
        _scrollToCurrentHour();
      }
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _flashAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.elasticInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _flashController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _flashController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateFlashMinuteStatus();
        });
      }
    });
  }

  void _updateFlashMinuteStatus() {
    _activeFlashMinutes = _events.where((e) => 
      e.isFlashMinute && 
      e.flashMinuteExpiry != null &&
      e.flashMinuteExpiry!.isAfter(DateTime.now())
    ).length;
    
    _showFlashMinuteBar = _activeFlashMinutes > 0;
  }

  void _scrollToCurrentHour() {
    final hour = DateTime.now().hour;
    final targetOffset = (hour - 2) * 80.0;
    if (_dayScrollController.hasClients && targetOffset > 0) {
      _dayScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _initializeEvents() {
    final now = DateTime.now();
    _events = [
      AgendaEvent(
        id: '1',
        title: 'Séance Dragon Oriental',
        clientName: 'Jean Martin',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 17, 0),
        type: EventType.session,
        description: 'Session 2/3 - Finalisation du dragon',
        location: 'Salon principal',
        locationType: LocationType.shop,
        isConfirmed: true,
        phoneNumber: '+33 6 12 34 56 78',
        email: 'jean.martin@email.com',
        price: 450.0,
      ),
      
      AgendaEvent(
        id: '2',
        title: 'Consultation Rose Minimaliste',
        clientName: 'Marie Dubois',
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 10, 0),
        type: EventType.consultation,
        description: 'Première consultation pour tatouage poignet',
        location: 'Bureau consultation',
        locationType: LocationType.shop,
        isConfirmed: true,
        phoneNumber: '+33 6 98 76 54 32',
        email: 'marie.dubois@email.com',
        price: 80.0,
      ),
      
      AgendaEvent(
        id: '3',
        title: 'Flash Minute - Tribal',
        clientName: 'Alex Rodriguez',
        startTime: DateTime(now.year, now.month, now.day, 11, 30),
        endTime: DateTime(now.year, now.month, now.day, 13, 0),
        type: EventType.flashMinute,
        description: 'Flash réservé via Flash Minute - Tribal moderne',
        location: 'Salon principal',
        locationType: LocationType.shop,
        isConfirmed: true,
        phoneNumber: '+33 6 55 44 33 22',
        email: 'alex.rodriguez@email.com',
        price: 120.0,
        isFlashMinute: true,
        flashMinuteDiscount: 25,
        flashMinuteExpiry: DateTime.now().add(const Duration(hours: 6)),
      ),
      
      AgendaEvent(
        id: '4',
        title: 'Session Biomécanique',
        clientName: 'Tom Wilson',
        startTime: DateTime(now.year, now.month, now.day + 1, 15, 0),
        endTime: DateTime(now.year, now.month, now.day + 1, 18, 0),
        type: EventType.session,
        description: 'Session complète bras - Art biomécanique',
        location: 'Salon principal',
        locationType: LocationType.shop,
        isConfirmed: true,
        phoneNumber: '+33 6 11 22 33 44',
        email: 'tom.wilson@email.com',
        price: 600.0,
      ),
      
      AgendaEvent(
        id: '5',
        title: 'Retouche Phoenix',
        clientName: 'Sophie Chen',
        startTime: DateTime(now.year, now.month, now.day + 2, 10, 0),
        endTime: DateTime(now.year, now.month, now.day + 2, 11, 30),
        type: EventType.retouche,
        description: 'Retouche couleurs phoenix dos',
        location: 'Salon principal',
        locationType: LocationType.shop,
        isConfirmed: true,
        phoneNumber: '+33 6 77 88 99 00',
        email: 'sophie.chen@email.com',
        price: 150.0,
      ),
      
      AgendaEvent(
        id: '6',
        title: 'Convention Tattoo Paris',
        startTime: DateTime(now.year, now.month, now.day + 3, 10, 0),
        endTime: DateTime(now.year, now.month, now.day + 3, 18, 0),
        type: EventType.personnel,
        description: 'Participation convention Paris Expo',
        location: 'Paris Expo Porte de Versailles',
        locationType: LocationType.convention,
        isConfirmed: true,
      ),
    ];
    
    _updateFlashMinuteStatus();
  }

  List<AgendaEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) => event.isOnDay(day)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<AgendaEvent> _getFreeSlots(DateTime day) {
    final dayEvents = _getEventsForDay(day)
        .where((e) => e.isConfirmed && e.type != EventType.personnel)
        .toList();
    
    List<AgendaEvent> freeSlots = [];
    final startHour = 9;
    final endHour = 20;
    
    DateTime currentTime = DateTime(day.year, day.month, day.day, startHour, 0);
    final endTime = DateTime(day.year, day.month, day.day, endHour, 0);
    
    while (currentTime.isBefore(endTime)) {
      final slotEnd = currentTime.add(const Duration(hours: 2));
      
      bool isFree = !dayEvents.any((event) =>
        (currentTime.isBefore(event.endTime) && slotEnd.isAfter(event.startTime))
      );
      
      if (isFree && slotEnd.isBefore(endTime)) {
        freeSlots.add(AgendaEvent(
          id: 'free_${currentTime.hour}',
          title: 'Créneau libre',
          startTime: currentTime,
          endTime: slotEnd,
          type: EventType.personnel,
          description: 'Disponible pour Flash Minute',
          locationType: LocationType.shop,
          isConfirmed: false,
        ));
      }
      
      currentTime = currentTime.add(const Duration(minutes: 30));
    }
    
    return freeSlots;
  }

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
        endDrawer: const CustomDrawerKipik(),
        appBar: CustomAppBarKipik(
          title: 'Agenda Pro',
          showBackButton: true,
          useProStyle: true,
          actions: [
            // ✅ BOUTONS D'ACTIONS DANS L'APPBAR
            IconButton(
              icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 24),
              onPressed: _syncCalendar,
              tooltip: 'Synchroniser calendriers',
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
              onPressed: _showSettings,
              tooltip: 'Paramètres',
            ),
          ],
        ),
        floatingActionButton: _buildSmartFAB(),
        body: Stack(
          children: [
            // ✅ BACKGROUND CHARBON COMME TES AUTRES PAGES
            Image.asset(
              'assets/background_charbon.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            
            // ✅ CONTENU AVEC STRUCTURE KIPIK
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      
                      // ✅ BARRE FLASH MINUTE SI ACTIVE
                      if (_showFlashMinuteBar) _buildFlashMinuteBar(),
                      
                      // ✅ CONTRÔLES DE VUE AVANCÉS
                      _buildAdvancedViewControls(),
                      
                      const SizedBox(height: 16),
                      
                      // ✅ CONTENU PRINCIPAL
                      Expanded(child: _buildCurrentView()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashMinuteBar() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.9),
              Colors.orange.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _flashAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Flash Minute Actif',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PermanentMarker',
                    ),
                  ),
                  Text(
                    '$_activeFlashMinutes flash(s) en promotion',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: _goToFlashMinuteDashboard,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Gérer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedViewControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ PREMIÈRE LIGNE : SÉLECTEUR DE VUE + DATE
          Row(
            children: [
              // Sélecteur de vue
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ViewType.values.map((view) {
                      final isSelected = _currentView == view;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _changeView(view),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? KipikTheme.rouge : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getViewLabel(view),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 14,
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Sélecteur de date
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: _showPremiumDatePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: KipikTheme.rouge),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getFormattedDateRange(),
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: KipikTheme.rouge,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.expand_more, size: 16, color: KipikTheme.rouge),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // ✅ SECONDE LIGNE : NAVIGATION + STATISTIQUES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Navigation
              Row(
                children: [
                  _buildNavButton(Icons.chevron_left, _goToPrevious),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _goToToday,
                    style: TextButton.styleFrom(
                      backgroundColor: KipikTheme.rouge.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Aujourd'hui",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: KipikTheme.rouge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildNavButton(Icons.chevron_right, _goToNext),
                ],
              ),
              
              // Statistiques période
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPeriodInfo(),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: KipikTheme.rouge.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: KipikTheme.rouge.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 20, color: KipikTheme.rouge),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case ViewType.day:
        return _buildPremiumDayView();
      case ViewType.week:
        return _buildPremiumWeekView();
      case ViewType.month:
        return _buildPremiumMonthView();
    }
  }

  Widget _buildPremiumDayView() {
    final events = _getEventsForDay(_selectedDate);
    final freeSlots = _getFreeSlots(_selectedDate);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDayHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: _dayScrollController,
              physics: const BouncingScrollPhysics(),
              child: _buildDayTimeline(events, freeSlots),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader() {
    final isToday = _isToday(_selectedDate);
    final events = _getEventsForDay(_selectedDate);
    final totalRevenue = events.where((e) => e.price != null).fold<double>(
      0, (sum, e) => sum + e.price!
    );
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KipikTheme.rouge.withOpacity(0.9),
            KipikTheme.rouge.withOpacity(0.7),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // ✅ DATE COMME TES CARDS
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isToday ? Colors.white : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isToday ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getDayAbbreviation(_selectedDate),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    color: isToday ? KipikTheme.rouge : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_selectedDate.day}',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: isToday ? KipikTheme.rouge : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFullDateString(_selectedDate),
                  style: const TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildDayStatChip('${events.length} RDV', Icons.event, Colors.blue),
                    _buildDayStatChip('${totalRevenue.toInt()}€', Icons.euro, Colors.green),
                    if (_getFreeSlots(_selectedDate).isNotEmpty)
                      _buildDayStatChip('${_getFreeSlots(_selectedDate).length} créneaux libres', Icons.schedule, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStatChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTimeline(List<AgendaEvent> events, List<AgendaEvent> freeSlots) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(24, (hour) {
          return _buildHourSlot(hour, events, freeSlots);
        }),
      ),
    );
  }

  Widget _buildHourSlot(int hour, List<AgendaEvent> events, List<AgendaEvent> freeSlots) {
    final hourEvents = events.where((e) => e.startTime.hour == hour).toList();
    final hourFreeSlots = freeSlots.where((e) => e.startTime.hour == hour).toList();
    final isCurrentHour = DateTime.now().hour == hour && _isToday(_selectedDate);
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isCurrentHour ? KipikTheme.rouge.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
            width: isCurrentHour ? 2 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // ✅ HEURE STYLE KIPIK AVEC INDICATEUR ACTUEL
          SizedBox(
            width: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: isCurrentHour ? KipikTheme.rouge : Colors.black54,
                    fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (isCurrentHour)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: KipikTheme.rouge,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          
          // ✅ ÉVÉNEMENTS AVEC POSITIONNEMENT DYNAMIQUE
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                children: [
                  ...hourEvents.map((event) => _buildEventCard(event)),
                  ...hourFreeSlots.map((slot) => _buildFreeSlotCard(slot)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(AgendaEvent event) {
    final duration = event.duration.inMinutes;
    final height = (duration * 0.8).clamp(40.0, 200.0);
    
    return Positioned(
      top: event.startTime.minute * 0.8,
      left: 0,
      right: 0,
      height: height,
      child: GestureDetector(
        onTap: () => _showEventDetails(event),
        onLongPress: event.canActivateFlashMinute ? () => _showFlashMinuteDialog(event) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                event.eventColor,
                event.eventColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: event.eventColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.isFlashMinute)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FLASH',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    if (event.clientName != null && height > 60) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.clientName!,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    if (height > 80) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(event.locationIcon, size: 12, color: Colors.white60),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                          if (event.price != null) ...[
                            Text(
                              '${event.price!.toInt()}€',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              if (event.canActivateFlashMinute)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeSlotCard(AgendaEvent slot) {
    return Positioned(
      top: slot.startTime.minute * 0.8,
      left: 0,
      right: 0,
      height: 60,
      child: GestureDetector(
        onTap: () => _showFlashMinuteCreation(slot),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.flash_on_rounded, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Créneau libre',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tap pour Flash Minute',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_rounded, size: 16, color: Colors.orange),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumWeekView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_week_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Vue Semaine Premium',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Interface avancée avec planning semaine\n(à implémenter)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showInfoSnackBar('Vue Semaine - Prochainement disponible'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Prochainement'),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMonthView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<AgendaEvent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _selectedDate,
        calendarFormat: _calendarFormat,
        eventLoader: (day) => _getEventsForDay(day),
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: Colors.black54),
          holidayTextStyle: const TextStyle(color: Colors.black54),
          defaultTextStyle: const TextStyle(color: Colors.black87),
          todayDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
            ),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: KipikTheme.rouge.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontFamily: 'PermanentMarker',
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black87),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black87),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekendStyle: TextStyle(color: Colors.black54, fontFamily: 'Roboto'),
          weekdayStyle: TextStyle(color: Colors.black87, fontFamily: 'Roboto'),
        ),
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
            _currentView = ViewType.day;
          });
        },
      ),
    );
  }

  Widget _buildSmartFAB() {
    final hasFreeSlots = _getFreeSlots(_selectedDate).isNotEmpty;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasFreeSlots)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton(
              heroTag: 'flash_minute',
              backgroundColor: Colors.orange,
              onPressed: () => _showFlashMinuteCreation(null),
              child: const Icon(Icons.flash_on_rounded, color: Colors.white),
            ),
          ),
        
        const TattooAssistantButton(),
      ],
    );
  }

  // ✅ MÉTHODES UTILITAIRES COMPLÈTES
  void _changeView(ViewType view) {
    setState(() {
      _currentView = view;
    });
    
    if (view == ViewType.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentHour();
      });
    }
  }

  String _getFormattedDateRange() {
    switch (_currentView) {
      case ViewType.day:
        return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
      case ViewType.week:
        final startOfWeek = _getStartOfWeek(_selectedDate);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}';
      case ViewType.month:
        return '${_getMonthName(_selectedDate)} ${_selectedDate.year}';
    }
  }

  String _getFullDateString(DateTime date) {
    const monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    const dayNames = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    
    return '${dayNames[date.weekday - 1]} ${date.day} ${monthNames[date.month - 1]}';
  }

  String _getPeriodInfo() {
    final eventsCount = _getCurrentViewEventsCount();
    final revenue = _getCurrentViewRevenue();
    
    return '$eventsCount RDV • ${revenue.toInt()}€';
  }

  int _getCurrentViewEventsCount() {
    switch (_currentView) {
      case ViewType.day:
        return _getEventsForDay(_selectedDate).length;
      case ViewType.week:
        return _getEventsForWeek(_getStartOfWeek(_selectedDate)).length;
      case ViewType.month:
        final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        return _events.where((event) => 
          event.startTime.isAfter(firstDay.subtract(const Duration(days: 1))) &&
          event.startTime.isBefore(lastDay.add(const Duration(days: 1)))
        ).length;
    }
  }

  double _getCurrentViewRevenue() {
    switch (_currentView) {
      case ViewType.day:
        return _getEventsForDay(_selectedDate)
            .where((e) => e.price != null)
            .fold<double>(0, (sum, e) => sum + e.price!);
      case ViewType.week:
        return _getEventsForWeek(_getStartOfWeek(_selectedDate))
            .where((e) => e.price != null)
            .fold<double>(0, (sum, e) => sum + e.price!);
      case ViewType.month:
        final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        return _events.where((event) => 
          event.startTime.isAfter(firstDay.subtract(const Duration(days: 1))) &&
          event.startTime.isBefore(lastDay.add(const Duration(days: 1))) &&
          event.price != null
        ).fold<double>(0, (sum, e) => sum + e.price!);
    }
  }

  List<AgendaEvent> _getEventsForWeek(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return _events.where((event) {
      return event.startTime.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             event.startTime.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _getViewLabel(ViewType view) {
    switch (view) {
      case ViewType.day:
        return 'Jour';
      case ViewType.week:
        return 'Semaine';
      case ViewType.month:
        return 'Mois';
    }
  }

  String _getDayAbbreviation(DateTime date) {
    const days = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
    return days[date.weekday - 1];
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[date.month - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ✅ ACTIONS DE NAVIGATION
  void _goToPrevious() {
    setState(() {
      switch (_currentView) {
        case ViewType.day:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
        case ViewType.week:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          break;
        case ViewType.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
          break;
      }
    });
  }

  void _goToNext() {
    setState(() {
      switch (_currentView) {
        case ViewType.day:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
          break;
        case ViewType.week:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
          break;
        case ViewType.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          break;
      }
    });
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
    if (_currentView == ViewType.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentHour();
      });
    }
  }

  void _showPremiumDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: KipikTheme.rouge,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
              background: Colors.white,
              onBackground: Colors.black87,
              secondary: KipikTheme.rouge,
              onSecondary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    ).then((date) {
      if (date != null) {
        setState(() {
          _selectedDate = date;
        });
      }
    });
  }

  void _syncCalendar() {
    _showSyncDialog();
  }

  void _showSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.sync_rounded, color: KipikTheme.rouge),
            const SizedBox(width: 8),
            const Text(
              'Synchronisation Calendriers',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Connectez vos calendriers externes pour synchroniser automatiquement vos rendez-vous',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text(
                'Google Calendar',
                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Synchronisation bidirectionnelle',
                style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
              ),
              trailing: const Icon(Icons.link, color: Colors.grey),
              onTap: _connectGoogleCalendar,
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.grey),
              title: const Text(
                'Apple Calendar',
                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Import/Export automatique',
                style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
              ),
              trailing: const Icon(Icons.link, color: Colors.grey),
              onTap: _connectAppleCalendar,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fermer',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
          ),
        ],
      ),
    );
  }

  void _connectGoogleCalendar() {
    Navigator.pop(context);
    _showSuccessSnackBar('Google Calendar - Connexion en cours...');
  }

  void _connectAppleCalendar() {
    Navigator.pop(context);
    _showSuccessSnackBar('Apple Calendar - Connexion en cours...');
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paramètres Agenda',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                color: Colors.black87,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.sync_rounded, color: Colors.blue),
              title: const Text(
                'Synchronisation',
                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Gérer les calendriers connectés',
                style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
              ),
              onTap: _syncCalendar,
            ),
            ListTile(
              leading: const Icon(Icons.flash_on_rounded, color: Colors.orange),
              title: const Text(
                'Flash Minute',
                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Paramètres et gestion Flash Minute',
                style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
              ),
              onTap: _goToFlashMinuteDashboard,
            ),
            ListTile(
              leading: Icon(Icons.notifications_outlined, color: KipikTheme.rouge),
              title: const Text(
                'Notifications',
                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Rappels et alertes',
                style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
              ),
              onTap: () => _showInfoSnackBar('Notifications - À implémenter'),
            ),
          ],
        ),
      ),
    );
  }

  void _goToFlashMinuteDashboard() {
    Navigator.pushNamed(context, '/flash/minute/dashboard');
  }

  void _showEventDetails(AgendaEvent event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      event.eventColor.withOpacity(0.1),
                      event.eventColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: event.eventColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        event.isFlashMinute ? Icons.flash_on_rounded : Icons.event_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              color: Colors.black87,
                              fontSize: 18,
                            ),
                          ),
                          if (event.clientName != null)
                            Text(
                              event.clientName!,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.schedule_rounded,
                      'Horaire',
                      '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                    ),
                    _buildDetailRow(
                      Icons.timer_rounded,
                      'Durée',
                      '${event.duration.inHours}h ${event.duration.inMinutes % 60}min',
                    ),
                    _buildDetailRow(
                      Icons.category_rounded,
                      'Type',
                      event.typeLabel,
                    ),
                    if (event.price != null)
                      _buildDetailRow(
                        Icons.euro_rounded,
                        'Prix',
                        '${event.price!.toInt()}€',
                      ),
                    if (event.location != null)
                      _buildDetailRow(
                        event.locationIcon,
                        'Lieu',
                        '${event.location} (${event.locationLabel})',
                      ),
                    if (event.phoneNumber != null)
                      _buildDetailRow(
                        Icons.phone_rounded,
                        'Téléphone',
                        event.phoneNumber!,
                      ),
                    if (event.email != null)
                      _buildDetailRow(
                        Icons.email_rounded,
                        'Email',
                        event.email!,
                      ),
                    if (event.description != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.description!,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        if (event.canActivateFlashMinute)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showFlashMinuteDialog(event);
                              },
                              icon: const Icon(Icons.flash_on_rounded, size: 16),
                              label: const Text('Flash Minute'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        if (event.canActivateFlashMinute) const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditEventDialog(event);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Modifier'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: event.eventColor),
                              foregroundColor: event.eventColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFlashMinuteDialog(AgendaEvent event) {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.flash_on_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Activation Flash Minute',
              style: TextStyle(fontFamily: 'PermanentMarker'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le RDV "${event.title}" a été annulé ?',
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Optimisez votre planning !',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Activez Flash Minute pour proposer ce créneau avec remise et remplir votre planning rapidement.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler seulement',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _activateFlashMinute(event);
            },
            icon: const Icon(Icons.flash_on, size: 16),
            label: const Text(
              'Annuler + Flash Minute',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(AgendaEvent event) {
    _showInfoSnackBar('Modification RDV "${event.title}" - À implémenter');
  }

  void _activateFlashMinute(AgendaEvent event) {
    Navigator.pushNamed(
      context,
      '/flash/minute/create',
      arguments: {
        'timeSlot': event,
        'cancelledAppointment': true,
      },
    );
  }

  void _showFlashMinuteCreation(AgendaEvent? freeSlot) {
    Navigator.pushNamed(
      context,
      '/flash/minute/create',
      arguments: {
        'timeSlot': freeSlot,
        'cancelledAppointment': false,
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
            ),
          ],
        ),
        backgroundColor: KipikTheme.rouge,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}