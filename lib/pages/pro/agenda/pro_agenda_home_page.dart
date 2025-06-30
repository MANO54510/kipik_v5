// lib/pages/pro/agenda/pro_agenda_home_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/pages/pro/home_page_pro.dart';

enum EventType { consultation, session, retouche, suivi, personnel }
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
  });

  Duration get duration => endTime.difference(startTime);
  
  bool isOnDay(DateTime day) {
    return startTime.year == day.year &&
           startTime.month == day.month &&
           startTime.day == day.day;
  }
  
  Color get eventColor {
    switch (type) {
      case EventType.consultation:
        return KipikTheme.rouge;
      case EventType.session:
        return const Color(0xFF000000); // Noir pur
      case EventType.retouche:
        return const Color(0xFF1A1A1A); // Noir très foncé
      case EventType.suivi:
        return const Color(0xFF2D2D2D); // Gris très foncé
      case EventType.personnel:
        return const Color(0xFF404040); // Gris foncé
    }
  }

  String get typeLabel {
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
}

class ProAgendaHomePage extends StatefulWidget {
  const ProAgendaHomePage({Key? key}) : super(key: key);

  @override
  State<ProAgendaHomePage> createState() => _ProAgendaHomePageState();
}

class _ProAgendaHomePageState extends State<ProAgendaHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late DateTime _selectedDate;
  ViewType _currentView = ViewType.day;
  late List<AgendaEvent> _events;
  final ScrollController _dayScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initializeEvents();
    
    // Scroll vers l'heure actuelle au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentView == ViewType.day) {
        _scrollToCurrentHour();
      }
    });
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentHour() {
    final hour = DateTime.now().hour;
    final targetOffset = (hour - 2) * 60.0; // 60px par heure, décalé de 2h
    if (_dayScrollController.hasClients && targetOffset > 0) {
      _dayScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  void _initializeEvents() {
    final now = DateTime.now();
    _events = [
      // Événement long de 3h
      AgendaEvent(
        id: '1',
        title: 'Séance Tribal Bras Complet',
        clientName: 'Jean Martin',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 17, 0),
        type: EventType.session,
        description: 'Session 2/3 - Finalisation du tribal sur le bras',
        location: 'Salon principal',
        locationType: LocationType.shop,
        isConfirmed: true,
      ),
      // Consultation courte
      AgendaEvent(
        id: '2',
        title: 'Consultation Rose',
        clientName: 'Marie Dubois',
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 10, 0),
        type: EventType.consultation,
        description: 'Première consultation',
        location: 'Bureau consultation',
        locationType: LocationType.shop,
        isConfirmed: true,
      ),
      // Convention (weekend)
      AgendaEvent(
        id: '3',
        title: 'Convention Ink Masters',
        startTime: DateTime(now.year, now.month, now.day + 5, 10, 0),
        endTime: DateTime(now.year, now.month, now.day + 5, 18, 0),
        type: EventType.session,
        description: 'Stand Convention Paris',
        location: 'Parc des Expositions - Paris',
        locationType: LocationType.convention,
        isConfirmed: true,
      ),
      // Guest spot
      AgendaEvent(
        id: '4',
        title: 'Guest Spot Lyon',
        startTime: DateTime(now.year, now.month, now.day + 7, 13, 0),
        endTime: DateTime(now.year, now.month, now.day + 7, 19, 0),
        type: EventType.session,
        description: 'Guest dans salon partenaire',
        location: 'Tattoo Shop Lyon',
        locationType: LocationType.guest,
        isConfirmed: true,
      ),
      // Pause
      AgendaEvent(
        id: '5',
        title: 'Pause déjeuner',
        startTime: DateTime(now.year, now.month, now.day, 12, 0),
        endTime: DateTime(now.year, now.month, now.day, 13, 30),
        type: EventType.personnel,
        description: 'Pause déjeuner',
        locationType: LocationType.shop,
      ),
    ];
  }

  List<AgendaEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) => event.isOnDay(day)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
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
        backgroundColor: const Color(0xFF000000), // Noir profond
        endDrawer: const CustomDrawerKipik(),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildNavigationHeader(),
              Expanded(child: _buildCurrentView()),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF000000), // Noir pur
            const Color(0xFF1A1A1A), // Noir légèrement plus clair
          ],
        ),
      ),
      child: Column(
        children: [
          // Première ligne : Menu + Titre + Date + Paramètres
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, size: 24, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
                
                const SizedBox(width: 8),
                
                const Text(
                  'Agenda',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                const Spacer(),
                
                // Date picker
                GestureDetector(
                  onTap: _showDatePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2A2A2A),
                          const Color(0xFF1A1A1A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF444444)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getDateText(),
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Bouton paramètres
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 20, color: Colors.white),
                  onPressed: _showSettings,
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
          
          // Deuxième ligne : Navigation (Flèches + Aujourd'hui)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF333333), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 24, color: Colors.white),
                  onPressed: _goToPrevious,
                  padding: const EdgeInsets.all(8),
                ),
                
                const SizedBox(width: 16),
                
                TextButton(
                  onPressed: _goToToday,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2A2A2A),
                          const Color(0xFF1A1A1A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF444444)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: const Text(
                      'Aujourd\'hui',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 24, color: Colors.white),
                  onPressed: _goToNext,
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF000000),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2A2A2A),
                  const Color(0xFF1A1A1A),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF444444)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ViewType.values.map((view) {
                final isSelected = _currentView == view;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentView = view);
                    if (view == ViewType.day) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToCurrentHour();
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? LinearGradient(
                        colors: [
                          KipikTheme.rouge.withOpacity(0.8),
                          KipikTheme.rouge,
                        ],
                      ) : null,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: KipikTheme.rouge.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Text(
                      _getViewLabel(view),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFFBBBBBB),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const Spacer(),
          
          Text(
            _getPeriodInfo(),
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case ViewType.day:
        return Column(
          children: [
            Expanded(child: _buildDayView()),
            _buildEventLegend(),
          ],
        );
      case ViewType.week:
        return Column(
          children: [
            Expanded(child: _buildWeekView()),
            _buildEventLegend(),
          ],
        );
      case ViewType.month:
        return Column(
          children: [
            Expanded(child: _buildMonthView()),
            _buildEventLegend(),
          ],
        );
    }
  }

  Widget _buildEventLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF000000),
            const Color(0xFF1A1A1A),
          ],
        ),
        border: const Border(
          top: BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Types d\'événements',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: EventType.values.map((type) {
                final event = AgendaEvent(
                  id: '', 
                  title: '', 
                  startTime: DateTime.now(), 
                  endTime: DateTime.now(),
                  type: type,
                );
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: event.type == EventType.consultation
                              ? LinearGradient(
                                  colors: [
                                    KipikTheme.rouge.withOpacity(0.8),
                                    KipikTheme.rouge,
                                  ],
                                )
                              : null,
                          color: event.type != EventType.consultation ? event.eventColor : null,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Colors.white24,
                            width: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.typeLabel,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final events = _getEventsForDay(_selectedDate);
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
      ),
      child: Column(
        children: [
          _buildDayHeader(_selectedDate),
          Expanded(
            child: SingleChildScrollView(
              controller: _dayScrollController,
              child: _buildDayGrid(events, _selectedDate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(DateTime date) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF000000),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const SizedBox(width: 80),
          Expanded(
            child: Column(
              children: [
                Text(
                  _getDayAbbreviation(date),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: _isToday(date) ? LinearGradient(
                      colors: [
                        KipikTheme.rouge.withOpacity(0.8),
                        KipikTheme.rouge,
                      ],
                    ) : null,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isToday(date) ? Colors.transparent : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Widget _buildDayGrid(List<AgendaEvent> events, DateTime date) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
      ),
      child: Column(
        children: List.generate(24, (hour) {
          return Container(
            height: 60,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF222222), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Colonne heure
                Container(
                  width: 80,
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Zone événements
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Stack(
                      children: _buildEventsForHour(events, hour, date),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildEventsForHour(List<AgendaEvent> events, int hour, DateTime date) {
    List<Widget> widgets = [];
    
    for (AgendaEvent event in events) {
      // Vérifier si l'événement commence dans cette heure
      if (event.startTime.hour == hour) {
        
        // Calculer la hauteur totale de l'événement en minutes
        final totalMinutes = event.duration.inMinutes;
        final pixelsPerMinute = 1.0; // 1 pixel par minute
        final eventHeight = (totalMinutes * pixelsPerMinute).clamp(40.0, 300.0); // Hauteur minimum 40px, maximum 300px
        
        // Position de départ basée sur les minutes
        final startMinutes = event.startTime.minute;
        final top = startMinutes * pixelsPerMinute;
        
        widgets.add(
          Positioned(
            top: top,
            left: 0,
            right: 8,
            height: eventHeight,
            child: GestureDetector(
              onTap: () => _showEventDetails(event),
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: event.type == EventType.consultation
                      ? LinearGradient(
                          colors: [
                            KipikTheme.rouge.withOpacity(0.9),
                            KipikTheme.rouge,
                          ],
                        )
                      : null,
                  color: event.type != EventType.consultation ? event.eventColor : null,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white24,
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: event.type == EventType.consultation 
                          ? KipikTheme.rouge.withOpacity(0.3)
                          : Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre toujours affiché
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          event.locationIcon,
                          size: 12,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                    
                    // Client si hauteur > 50
                    if (event.clientName != null && eventHeight > 50) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.clientName!,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Horaires si hauteur > 70
                    if (eventHeight > 70) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 9,
                          color: Colors.white60,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return widgets;
  }

  Widget _buildWeekView() {
    final startOfWeek = _getStartOfWeek(_selectedDate);
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
      ),
      child: Column(
        children: [
          _buildWeekHeader(startOfWeek),
          Expanded(
            child: SingleChildScrollView(
              child: _buildWeekGrid(startOfWeek),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(DateTime startOfWeek) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF000000),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const SizedBox(width: 50), // Correspondre à la nouvelle largeur
          ...List.generate(7, (index) {
            final day = startOfWeek.add(Duration(days: index));
            final isToday = _isToday(day);
            final dayEvents = _getEventsForDay(day);
            
            return Expanded(
              child: Column(
                children: [
                  Text(
                    _getDayAbbreviation(day),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11, // Police légèrement plus petite
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28, // Légèrement plus petit
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: isToday 
                          ? LinearGradient(
                              colors: [
                                KipikTheme.rouge.withOpacity(0.8),
                                KipikTheme.rouge,
                              ],
                            )
                          : dayEvents.isNotEmpty
                              ? LinearGradient(
                                  colors: [
                                    KipikTheme.rouge.withOpacity(0.3),
                                    KipikTheme.rouge.withOpacity(0.5),
                                  ],
                                )
                              : null,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isToday || dayEvents.isNotEmpty 
                            ? Colors.transparent 
                            : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13, // Police légèrement plus petite
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeekGrid(DateTime startOfWeek) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
      ),
      child: Column(
        children: List.generate(24, (hour) {
          return Container(
            height: 60,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF222222), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Colonne heure plus petite en vue semaine
                Container(
                  width: 50, // Réduit de 80 à 50
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10, // Police plus petite
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Colonnes jours
                ...List.generate(7, (dayIndex) {
                  final day = startOfWeek.add(Duration(days: dayIndex));
                  final dayEvents = _getEventsForDay(day);
                  
                  return Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFF222222), width: 1),
                        ),
                      ),
                      child: Stack(
                        children: _buildEventsForHourWeek(dayEvents, hour, day),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildEventsForHourWeek(List<AgendaEvent> events, int hour, DateTime date) {
    List<Widget> widgets = [];
    
    for (AgendaEvent event in events) {
      // Vérifier si l'événement commence dans cette heure
      if (event.startTime.hour == hour) {
        
        // Calculer la hauteur totale de l'événement en minutes
        final totalMinutes = event.duration.inMinutes;
        final pixelsPerMinute = 1.0;
        final eventHeight = (totalMinutes * pixelsPerMinute).clamp(20.0, 180.0); // Plus petit pour la vue semaine
        
        // Position de départ basée sur les minutes
        final startMinutes = event.startTime.minute;
        final top = startMinutes * pixelsPerMinute;
        
        widgets.add(
          Positioned(
            top: top,
            left: 2,
            right: 2,
            height: eventHeight,
            child: GestureDetector(
              onTap: () => _showEventDetails(event),
              child: Container(
                margin: const EdgeInsets.only(bottom: 1),
                padding: const EdgeInsets.all(4), // Padding encore plus réduit
                decoration: BoxDecoration(
                  gradient: event.type == EventType.consultation
                      ? LinearGradient(
                          colors: [
                            KipikTheme.rouge.withOpacity(0.9),
                            KipikTheme.rouge,
                          ],
                        )
                      : null,
                  color: event.type != EventType.consultation ? event.eventColor : null,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white24,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre seulement
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 9, // Police très petite pour la vue semaine
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Client si hauteur > 30
                    if (event.clientName != null && eventHeight > 30) ...[
                      Text(
                        event.clientName!,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 8,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return widgets;
  }

  Widget _buildMonthView() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final startDate = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
      ),
      child: Column(
        children: [
          // En-tête des jours de la semaine
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF000000),
                ],
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF333333), width: 1),
              ),
            ),
            child: Row(
              children: ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'].map((day) =>
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
          
          // Grille du mois
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(1),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.8,
              ),
              itemCount: 42, // 6 semaines * 7 jours
              itemBuilder: (context, index) {
                final date = startDate.add(Duration(days: index));
                final isCurrentMonth = date.month == _selectedDate.month;
                final isToday = _isToday(date);
                final isSelected = _isSameDay(date, _selectedDate);
                final dayEvents = _getEventsForDay(date);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _currentView = ViewType.day;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      gradient: isSelected 
                          ? LinearGradient(
                              colors: [
                                KipikTheme.rouge.withOpacity(0.3),
                                KipikTheme.rouge.withOpacity(0.5),
                              ],
                            )
                          : null,
                      color: !isSelected ? const Color(0xFF000000) : null,
                      border: Border.all(
                        color: isSelected 
                            ? KipikTheme.rouge 
                            : const Color(0xFF222222),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: isToday ? LinearGradient(
                              colors: [
                                KipikTheme.rouge.withOpacity(0.8),
                                KipikTheme.rouge,
                              ],
                            ) : null,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isToday ? Colors.transparent : Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isCurrentMonth 
                                    ? Colors.white
                                    : const Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Column(
                            children: dayEvents.take(2).map((event) => // Limité à 2 événements pour éviter l'overflow
                              Container(
                                width: double.infinity,
                                height: 8, // Hauteur réduite
                                margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.5),
                                decoration: BoxDecoration(
                                  gradient: event.type == EventType.consultation
                                      ? LinearGradient(
                                          colors: [
                                            KipikTheme.rouge.withOpacity(0.8),
                                            KipikTheme.rouge,
                                          ],
                                        )
                                      : null,
                                  color: event.type != EventType.consultation ? event.eventColor : null,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                child: event.locationType != LocationType.shop
                                    ? Icon(
                                        event.locationIcon,
                                        size: 6, // Icône plus petite
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ).toList(),
                          ),
                        ),
                        if (dayEvents.length > 2) // Changé de 3 à 2
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '+${dayEvents.length - 2}',
                              style: const TextStyle(
                                fontSize: 7, // Police plus petite
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
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
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: Colors.transparent,
      elevation: 0,
      onPressed: _showAddEventDialog,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              KipikTheme.rouge.withOpacity(0.8),
              KipikTheme.rouge,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: KipikTheme.rouge.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  // Méthodes utilitaires
  String _getDateText() {
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

  String _getPeriodInfo() {
    final eventsCount = _getCurrentViewEventsCount();
    return eventsCount == 0 
        ? 'Aucun rendez-vous'
        : '$eventsCount rendez-vous';
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
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[date.month - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Actions de navigation
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

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: KipikTheme.rouge, // Rouge Kipik
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A), // Noir
              onSurface: Colors.white,
              background: Color(0xFF000000), // Noir profond
              onBackground: Colors.white,
              secondary: KipikTheme.rouge,
              onSecondary: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A1A),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
              titleLarge: TextStyle(color: Colors.white),
            ),
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

  void _syncWithExternalCalendar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Synchronisation',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSyncOption('Google Calendar', Icons.calendar_today),
              const SizedBox(height: 16),
              _buildSyncOption('Apple Calendar', Icons.calendar_month),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Fermer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncOption(String name, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronisation avec $name en cours...'),
            backgroundColor: KipikTheme.rouge,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2A2A2A),
              const Color(0xFF1A1A1A),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF444444)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.sync,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paramètres de l\'agenda',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingOption('Synchronisation', Icons.sync),
              _buildSettingOption('Notifications', Icons.notifications_outlined),
              _buildSettingOption('Géolocalisation', Icons.location_on_outlined),
              _buildSettingOption('Préférences', Icons.tune),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: () {
        Navigator.pop(context);
        if (title == 'Synchronisation') {
          _syncWithExternalCalendar();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title : À implémenter'),
              backgroundColor: KipikTheme.rouge,
            ),
          );
        }
      },
    );
  }

  void _showAddEventDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nouveau rendez-vous',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Titre',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: KipikTheme.rouge),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Date',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF444444)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF444444)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: KipikTheme.rouge),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Heure',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF444444)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF444444)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: KipikTheme.rouge),
                        ),
                        suffixIcon: const Icon(Icons.access_time, color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LocationType>(
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Lieu',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: KipikTheme.rouge),
                  ),
                ),
                items: LocationType.values.map((location) =>
                  DropdownMenuItem(
                    value: location,
                    child: Row(
                      children: [
                        Icon(_getLocationIcon(location), color: Colors.white),
                        const SizedBox(width: 8),
                        Text(_getLocationLabel(location)),
                      ],
                    ),
                  ),
                ).toList(),
                onChanged: (value) {},
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Rendez-vous ajouté !'),
                            backgroundColor: KipikTheme.rouge,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              KipikTheme.rouge.withOpacity(0.8),
                              KipikTheme.rouge,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Text(
                          'Ajouter',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLocationIcon(LocationType type) {
    switch (type) {
      case LocationType.shop:
        return Icons.home_work;
      case LocationType.guest:
        return Icons.flight;
      case LocationType.convention:
        return Icons.event;
    }
  }

  String _getLocationLabel(LocationType type) {
    switch (type) {
      case LocationType.shop:
        return 'Salon';
      case LocationType.guest:
        return 'Guest Spot';
      case LocationType.convention:
        return 'Convention';
    }
  }

  void _showEventDetails(AgendaEvent event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1A1A),
                const Color(0xFF000000),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête coloré
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: event.type == EventType.consultation
                      ? LinearGradient(
                          colors: [
                            KipikTheme.rouge.withOpacity(0.3),
                            KipikTheme.rouge.withOpacity(0.5),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            event.eventColor.withOpacity(0.3),
                            event.eventColor.withOpacity(0.5),
                          ],
                        ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: event.type == EventType.consultation
                                ? LinearGradient(
                                    colors: [
                                      KipikTheme.rouge.withOpacity(0.8),
                                      KipikTheme.rouge,
                                    ],
                                  )
                                : null,
                            color: event.type != EventType.consultation ? event.eventColor : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.typeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                event.locationIcon,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.locationLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    if (event.clientName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.clientName!,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Contenu des détails
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.access_time,
                      'Horaire',
                      '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                    ),
                    _buildDetailRow(
                      Icons.schedule,
                      'Durée',
                      '${event.duration.inHours}h ${event.duration.inMinutes % 60}min',
                    ),
                    if (event.location != null)
                      _buildDetailRow(
                        Icons.location_on,
                        'Lieu',
                        event.location!,
                      ),
                    if (event.description != null)
                      _buildDetailRow(
                        Icons.description,
                        'Description',
                        event.description!,
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: event.type == EventType.consultation ? KipikTheme.rouge : event.eventColor),
                            ),
                            child: Text(
                              'Modifier',
                              style: TextStyle(color: event.type == EventType.consultation ? KipikTheme.rouge : event.eventColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: event.type == EventType.consultation
                                    ? LinearGradient(
                                        colors: [
                                          KipikTheme.rouge.withOpacity(0.8),
                                          KipikTheme.rouge,
                                        ],
                                      )
                                    : null,
                                color: event.type != EventType.consultation ? event.eventColor : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: const Text(
                                'Contacter',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
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
          Icon(icon, size: 16, color: Colors.white70),
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
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.white,
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
}