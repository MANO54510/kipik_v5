// lib/pages/pro/booking/booking_day_view_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../widgets/common/buttons/tattoo_assistant_button.dart';
import 'dart:math';

enum EventType { tattoo, consultation, retouche, devis, deplacement, personnel, convention, formation, guest }
enum EventStatus { pending, confirmed, inProgress, completed, cancelled }
enum ViewMode { timeline, list, grid }
enum FilterType { all, today, upcoming, completed }

class DayEvent {
  final String id;
  final String title;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final EventStatus status;
  final String? description;
  final String? location;
  final double? price;
  final double? deposit;
  final String? notes;
  final Color? customColor;
  final bool isFlashMinute;
  final bool hasReminder;
  final List<String>? attachments;

  DayEvent({
    required this.id,
    required this.title,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.status = EventStatus.pending,
    this.description,
    this.location,
    this.price,
    this.deposit,
    this.notes,
    this.customColor,
    this.isFlashMinute = false,
    this.hasReminder = false,
    this.attachments,
  });

  Duration get duration => endTime.difference(startTime);
  
  Color get eventColor {
    if (customColor != null) return customColor!;
    if (isFlashMinute) return Colors.orange;
    
    switch (type) {
      case EventType.tattoo:
        return KipikTheme.rouge;
      case EventType.consultation:
        return Colors.blue;
      case EventType.retouche:
        return Colors.orange;
      case EventType.devis:
        return Colors.purple;
      case EventType.deplacement:
        return Colors.green;
      case EventType.personnel:
        return Colors.grey;
      case EventType.convention:
        return Colors.indigo;
      case EventType.formation:
        return Colors.teal;
      case EventType.guest:
        return Colors.amber;
    }
  }

  Color get statusColor {
    switch (status) {
      case EventStatus.pending:
        return Colors.orange;
      case EventStatus.confirmed:
        return Colors.blue;
      case EventStatus.inProgress:
        return Colors.green;
      case EventStatus.completed:
        return Colors.green.shade700;
      case EventStatus.cancelled:
        return Colors.red;
    }
  }

  String get statusText {
    switch (status) {
      case EventStatus.pending:
        return 'En attente';
      case EventStatus.confirmed:
        return 'Confirmé';
      case EventStatus.inProgress:
        return 'En cours';
      case EventStatus.completed:
        return 'Terminé';
      case EventStatus.cancelled:
        return 'Annulé';
    }
  }

  bool get canStart => status == EventStatus.confirmed && DateTime.now().isAfter(startTime.subtract(const Duration(minutes: 15)));
  bool get canComplete => status == EventStatus.inProgress;
  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isToday => startTime.day == DateTime.now().day && startTime.month == DateTime.now().month && startTime.year == DateTime.now().year;
}

class BookingDayViewPage extends StatefulWidget {
  final DateTime? initialDate;
  
  const BookingDayViewPage({
    Key? key,
    this.initialDate,
  }) : super(key: key);

  @override
  State<BookingDayViewPage> createState() => _BookingDayViewPageState();
}

class _BookingDayViewPageState extends State<BookingDayViewPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _timelineController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _timelineAnimation;

  final ScrollController _timelineScrollController = ScrollController();
  final PageController _datePageController = PageController(initialPage: 1000);

  // État de la page
  DateTime _selectedDate = DateTime.now();
  ViewMode _viewMode = ViewMode.timeline;
  FilterType _filterType = FilterType.all;
  bool _isLoading = false;
  bool _showWorkingHoursOnly = true;
  bool _showCompletedEvents = true;
  
  // Données
  List<DayEvent> _allEvents = [];
  List<DayEvent> _filteredEvents = [];
  
  // Configuration
  final TimeOfDay _workStartTime = const TimeOfDay(hour: 8, minute: 0);
  final TimeOfDay _workEndTime = const TimeOfDay(hour: 20, minute: 0);
  final int _slotDuration = 30; // minutes
  
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _initializeAnimations();
    _loadEvents();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _timelineController.dispose();
    _timelineScrollController.dispose();
    _datePageController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _timelineController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _timelineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timelineController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _scaleController.forward();
    _timelineController.forward();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    // Simulation du chargement
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() {
      _allEvents = _generateSampleEvents();
      _applyFilters();
      _isLoading = false;
    });
  }

  List<DayEvent> _generateSampleEvents() {
    final now = DateTime.now();
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    return [
      DayEvent(
        id: '1',
        title: 'Consultation Tatouage Dragon',
        clientName: 'Marie Dubois',
        clientPhone: '+33 6 12 34 56 78',
        clientEmail: 'marie.dubois@email.com',
        startTime: selectedDay.add(const Duration(hours: 9)),
        endTime: selectedDay.add(const Duration(hours: 10)),
        type: EventType.consultation,
        status: EventStatus.confirmed,
        description: 'Première consultation pour tatouage dragon japonais sur le dos',
        location: 'Salon principal',
        price: 80.0,
        hasReminder: true,
      ),
      
      DayEvent(
        id: '2',
        title: 'Séance Tatouage - Rose Minimaliste',
        clientName: 'Sophie Martin',
        clientPhone: '+33 6 98 76 54 32',
        clientEmail: 'sophie.martin@email.com',
        startTime: selectedDay.add(const Duration(hours: 10, minutes: 30)),
        endTime: selectedDay.add(const Duration(hours: 13)),
        type: EventType.tattoo,
        status: DateTime.now().hour >= 10 ? EventStatus.inProgress : EventStatus.confirmed,
        description: 'Tatouage rose minimaliste sur l\'avant-bras',
        location: 'Salon principal',
        price: 280.0,
        deposit: 84.0,
        hasReminder: true,
      ),
      
      DayEvent(
        id: '3',
        title: 'Flash Minute - Tribal',
        clientName: 'Alex Rodriguez',
        clientPhone: '+33 6 55 44 33 22',
        startTime: selectedDay.add(const Duration(hours: 14)),
        endTime: selectedDay.add(const Duration(hours: 15, minutes: 30)),
        type: EventType.tattoo,
        status: EventStatus.confirmed,
        description: 'Flash Minute - Tatouage tribal moderne',
        location: 'Salon principal',
        price: 120.0,
        isFlashMinute: true,
        hasReminder: false,
      ),
      
      DayEvent(
        id: '4',
        title: 'Retouche Phoenix',
        clientName: 'Jean Dupont',
        clientPhone: '+33 6 77 88 99 00',
        startTime: selectedDay.add(const Duration(hours: 16)),
        endTime: selectedDay.add(const Duration(hours: 17)),
        type: EventType.retouche,
        status: EventStatus.pending,
        description: 'Retouche couleurs sur tatouage phoenix',
        location: 'Salon principal',
        price: 150.0,
        hasReminder: true,
      ),
      
      DayEvent(
        id: '5',
        title: 'Formation - Nouvelles Techniques',
        startTime: selectedDay.add(const Duration(hours: 18)),
        endTime: selectedDay.add(const Duration(hours: 20)),
        type: EventType.formation,
        status: EventStatus.confirmed,
        description: 'Formation sur les nouvelles techniques de tatouage',
        location: 'Salle de formation',
        hasReminder: true,
      ),
    ];
  }

  void _applyFilters() {
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        switch (_filterType) {
          case FilterType.all:
            return true;
          case FilterType.today:
            return event.isToday;
          case FilterType.upcoming:
            return event.isUpcoming && event.status != EventStatus.cancelled;
          case FilterType.completed:
            return event.status == EventStatus.completed;
        }
      }).toList();
      
      if (!_showCompletedEvents) {
        _filteredEvents = _filteredEvents.where((e) => e.status != EventStatus.completed).toList();
      }
      
      _filteredEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
  }

  void _scrollToCurrentTime() {
    if (!_timelineScrollController.hasClients) return;
    
    final now = DateTime.now();
    if (!_isToday(_selectedDate)) return;
    
    final hour = now.hour;
    final minute = now.minute;
    
    // Calculer la position de scroll (80px par heure)
    final targetOffset = ((hour - _workStartTime.hour) * 80.0) + (minute / 60.0 * 80.0) - 200;
    
    if (targetOffset > 0) {
      _timelineScrollController.animateTo(
        targetOffset.clamp(0.0, _timelineScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Vue Jour Détaillée',
        subtitle: _formatSelectedDate(),
        showBackButton: true,
        useProStyle: true,
        actions: [
          IconButton(
            onPressed: _toggleViewMode,
            icon: Icon(_getViewModeIcon(), color: Colors.white),
            tooltip: 'Changer la vue',
          ),
          IconButton(
            onPressed: _showFilterMenu,
            icon: const Icon(Icons.filter_list, color: Colors.white),
            tooltip: 'Filtres',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_event',
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Ajouter RDV', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_day',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Exporter journée', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print_schedule',
                child: Row(
                  children: [
                    Icon(Icons.print, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Imprimer planning', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            onSelected: _handleMenuAction,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add_event',
            backgroundColor: KipikTheme.rouge,
            onPressed: _addNewEvent,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const TattooAssistantButton(),
        ],
      ),
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
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoading ? _buildLoadingView() : _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: KipikTheme.rouge,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chargement de la journée...',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildDayHeader(),
          const SizedBox(height: 16),
          _buildDateSelector(),
          const SizedBox(height: 16),
          _buildDayStats(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildCurrentView(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              KipikTheme.rouge.withOpacity(0.9),
              KipikTheme.rouge.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: KipikTheme.rouge.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayAbbreviation(_selectedDate),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_selectedDate.day}',
                    style: const TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 20,
                      color: Colors.white,
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDayStatusText(),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            if (_isToday(_selectedDate))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "AUJOURD'HUI",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 80,
      child: PageView.builder(
        controller: _datePageController,
        onPageChanged: (index) {
          final newDate = DateTime.now().add(Duration(days: index - 1000));
          setState(() {
            _selectedDate = newDate;
          });
          _loadEvents();
        },
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 1000));
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isToday(date);
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _loadEvents();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: isSelected 
                    ? LinearGradient(
                        colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected 
                    ? Border.all(color: KipikTheme.rouge, width: 2)
                    : null,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: KipikTheme.rouge.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayAbbreviation(date),
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 18,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    _getMonthAbbreviation(date),
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayStats() {
    final eventsCount = _filteredEvents.length;
    final completedCount = _filteredEvents.where((e) => e.status == EventStatus.completed).length;
    final totalRevenue = _filteredEvents.where((e) => e.price != null).fold<double>(0, (sum, e) => sum + e.price!);
    final workingHours = _calculateWorkingHours();
    
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(child: _buildStatItem('RDV', '$eventsCount', Icons.event, Colors.blue)),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          Expanded(child: _buildStatItem('Terminés', '$completedCount', Icons.check_circle, Colors.green)),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          Expanded(child: _buildStatItem('Revenus', '${totalRevenue.toInt()}€', Icons.euro, KipikTheme.rouge)),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          Expanded(child: _buildStatItem('Durée', workingHours, Icons.schedule, Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentView() {
    switch (_viewMode) {
      case ViewMode.timeline:
        return _buildTimelineView();
      case ViewMode.list:
        return _buildListView();
      case ViewMode.grid:
        return _buildGridView();
    }
  }

  Widget _buildTimelineView() {
    return FadeTransition(
      opacity: _timelineAnimation,
      child: Container(
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
            // Header timeline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade100,
                    Colors.grey.shade50,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: KipikTheme.rouge, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Timeline de la journée',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _scrollToCurrentTime,
                    icon: Icon(Icons.my_location, color: KipikTheme.rouge, size: 20),
                    tooltip: 'Aller à maintenant',
                  ),
                ],
              ),
            ),
            
            // Timeline content
            Expanded(
              child: SingleChildScrollView(
                controller: _timelineScrollController,
                physics: const BouncingScrollPhysics(),
                child: _buildTimelineContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineContent() {
    final startHour = _showWorkingHoursOnly ? _workStartTime.hour : 0;
    final endHour = _showWorkingHoursOnly ? _workEndTime.hour : 24;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(endHour - startHour, (index) {
          final hour = startHour + index;
          return _buildTimelineHour(hour);
        }),
      ),
    );
  }

  Widget _buildTimelineHour(int hour) {
    final hourEvents = _filteredEvents.where((event) => event.startTime.hour == hour).toList();
    final isCurrentHour = _isToday(_selectedDate) && DateTime.now().hour == hour;
    final isPastHour = _isToday(_selectedDate) && DateTime.now().hour > hour;
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isCurrentHour 
                ? KipikTheme.rouge.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.2),
            width: isCurrentHour ? 2 : 1,
          ),
        ),
        color: isPastHour ? Colors.grey.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          // Colonne heure
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
          
          // Colonne événements
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                children: [
                  // Indicateur heure actuelle
                  if (isCurrentHour && _isToday(_selectedDate))
                    Positioned(
                      top: _getCurrentMinutePosition(),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: KipikTheme.rouge,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  
                  // Événements
                  ...hourEvents.map((event) => _buildTimelineEventCard(event)),
                  
                  // Slot libre si aucun événement
                  if (hourEvents.isEmpty)
                    GestureDetector(
                      onTap: () => _addEventAtTime(hour),
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.grey, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Créneau libre',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEventCard(DayEvent event) {
    final duration = event.duration.inMinutes;
    final height = (duration * 0.8).clamp(40.0, 200.0);
    final top = event.startTime.minute * 0.8;
    
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: GestureDetector(
        onTap: () => _showEventDetails(event),
        onLongPress: () => _showEventActions(event),
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
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.isFlashMinute)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                          Icon(Icons.access_time, size: 12, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text(
                            '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                          ),
                          const Spacer(),
                          if (event.price != null)
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
                      ),
                    ],
                  ],
                ),
              ),
              
              // Indicateur de statut
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: event.statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: event.statusColor.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Actions rapides
              if (event.canStart || event.canComplete)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _handleQuickAction(event),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        event.canStart ? Icons.play_arrow : Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade100,
                  Colors.grey.shade50,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.list, color: KipikTheme.rouge, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Liste des rendez-vous',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredEvents.length,
              itemBuilder: (context, index) {
                final event = _filteredEvents[index];
                return _buildListEventCard(event);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListEventCard(DayEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: event.eventColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: event.eventColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
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
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.statusText,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: event.statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (event.clientName != null)
                  Text(
                    event.clientName!,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    if (event.price != null)
                      Text(
                        '${event.price!.toInt()}€',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: event.eventColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              IconButton(
                onPressed: () => _showEventDetails(event),
                icon: const Icon(Icons.visibility, color: Colors.grey),
                iconSize: 20,
              ),
              if (event.canStart || event.canComplete)
                IconButton(
                  onPressed: () => _handleQuickAction(event),
                  icon: Icon(
                    event.canStart ? Icons.play_arrow : Icons.check,
                    color: Colors.green,
                  ),
                  iconSize: 20,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade100,
                  Colors.grey.shade50,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.grid_view, color: KipikTheme.rouge, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Vue grille',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _filteredEvents.length,
              itemBuilder: (context, index) {
                final event = _filteredEvents[index];
                return _buildGridEventCard(event);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridEventCard(DayEvent event) {
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              event.eventColor.withOpacity(0.8),
              event.eventColor.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: event.eventColor.withOpacity(0.3),
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
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: event.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (event.clientName != null)
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (event.price != null)
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
            ),
          ],
        ),
      ),
    );
  }

  // Actions et méthodes utilitaires
  void _toggleViewMode() {
    setState(() {
      switch (_viewMode) {
        case ViewMode.timeline:
          _viewMode = ViewMode.list;
          break;
        case ViewMode.list:
          _viewMode = ViewMode.grid;
          break;
        case ViewMode.grid:
          _viewMode = ViewMode.timeline;
          break;
      }
    });
  }

  IconData _getViewModeIcon() {
    switch (_viewMode) {
      case ViewMode.timeline:
        return Icons.timeline;
      case ViewMode.list:
        return Icons.list;
      case ViewMode.grid:
        return Icons.grid_view;
    }
  }

  void _showFilterMenu() {
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
              'Filtres et Options',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            // Filtres
            const Text(
              'Affichage',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...FilterType.values.map((filter) {
              return RadioListTile<FilterType>(
                title: Text(_getFilterLabel(filter)),
                value: filter,
                groupValue: _filterType,
                activeColor: KipikTheme.rouge,
                onChanged: (value) {
                  setState(() => _filterType = value!);
                  _applyFilters();
                  Navigator.pop(context);
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
            
            const SizedBox(height: 16),
            
            // Options
            SwitchListTile(
              title: const Text('Heures de travail seulement'),
              value: _showWorkingHoursOnly,
              activeColor: KipikTheme.rouge,
              onChanged: (value) {
                setState(() => _showWorkingHoursOnly = value);
                Navigator.pop(context);
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            SwitchListTile(
              title: const Text('Afficher les RDV terminés'),
              value: _showCompletedEvents,
              activeColor: KipikTheme.rouge,
              onChanged: (value) {
                setState(() => _showCompletedEvents = value);
                _applyFilters();
                Navigator.pop(context);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_event':
        _addNewEvent();
        break;
      case 'export_day':
        _exportDay();
        break;
      case 'print_schedule':
        _printSchedule();
        break;
    }
  }

  void _addNewEvent() {
    Navigator.pushNamed(context, '/booking/add', arguments: {
      'preselectedDate': _selectedDate,
    });
  }

  void _addEventAtTime(int hour) {
    Navigator.pushNamed(context, '/booking/add', arguments: {
      'preselectedDate': _selectedDate,
      'preselectedTime': TimeOfDay(hour: hour, minute: 0),
    });
  }

  void _showEventDetails(DayEvent event) {
    Navigator.pushNamed(context, '/booking/edit', arguments: event);
  }

  void _showEventActions(DayEvent event) {
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
          children: [
            Text(
              event.title,
              style: const TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Voir détails'),
              onTap: () {
                Navigator.pop(context);
                _showEventDetails(event);
              },
            ),
            
            if (event.canStart)
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Colors.green),
                title: const Text('Commencer'),
                onTap: () {
                  Navigator.pop(context);
                  _handleQuickAction(event);
                },
              ),
            
            if (event.canComplete)
              ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: const Text('Terminer'),
                onTap: () {
                  Navigator.pop(context);
                  _handleQuickAction(event);
                },
              ),
            
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                _showEventDetails(event);
              },
            ),
            
            if (event.clientPhone != null)
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.blue),
                title: const Text('Appeler client'),
                onTap: () {
                  Navigator.pop(context);
                  _callClient(event);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _handleQuickAction(DayEvent event) {
    if (event.canStart) {
      _startEvent(event);
    } else if (event.canComplete) {
      _completeEvent(event);
    }
  }

  void _startEvent(DayEvent event) {
    HapticFeedback.mediumImpact();
    _showSuccessSnackBar('RDV "${event.title}" commencé');
    _loadEvents(); // Recharger pour mettre à jour le statut
  }

  void _completeEvent(DayEvent event) {
    HapticFeedback.mediumImpact();
    _showSuccessSnackBar('RDV "${event.title}" terminé');
    _loadEvents(); // Recharger pour mettre à jour le statut
  }

  void _callClient(DayEvent event) {
    _showInfoSnackBar('Appel vers ${event.clientPhone} - À implémenter');
  }

  void _exportDay() {
    _showInfoSnackBar('Export de la journée - À implémenter');
  }

  void _printSchedule() {
    _showInfoSnackBar('Impression du planning - À implémenter');
  }

  // Méthodes utilitaires
  double _getCurrentMinutePosition() {
    final now = DateTime.now();
    return (now.minute / 60.0) * 64; // 64px de hauteur par heure
  }

  String _calculateWorkingHours() {
    final totalMinutes = _filteredEvents.fold<int>(0, (sum, event) => sum + event.duration.inMinutes);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  String _formatSelectedDate() {
    final now = DateTime.now();
    if (_isSameDay(_selectedDate, now)) {
      return "Aujourd'hui";
    } else if (_isSameDay(_selectedDate, now.add(const Duration(days: 1)))) {
      return 'Demain';
    } else if (_isSameDay(_selectedDate, now.subtract(const Duration(days: 1)))) {
      return 'Hier';
    } else {
      return _getFullDateString(_selectedDate);
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

  String _getDayAbbreviation(DateTime date) {
    const days = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
    return days[date.weekday - 1];
  }

  String _getMonthAbbreviation(DateTime date) {
    const months = ['JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUN', 'JUL', 'AOÛ', 'SEP', 'OCT', 'NOV', 'DÉC'];
    return months[date.month - 1];
  }

  String _getDayStatusText() {
    if (_isToday(_selectedDate)) {
      final upcomingCount = _filteredEvents.where((e) => e.isUpcoming).length;
      if (upcomingCount > 0) {
        return '$upcomingCount RDV restants aujourd\'hui';
      } else {
        return 'Journée terminée';
      }
    } else if (_selectedDate.isAfter(DateTime.now())) {
      return '${_filteredEvents.length} RDV programmés';
    } else {
      final completedCount = _filteredEvents.where((e) => e.status == EventStatus.completed).length;
      return '$completedCount/${_filteredEvents.length} RDV terminés';
    }
  }

  String _getFilterLabel(FilterType filter) {
    switch (filter) {
      case FilterType.all:
        return 'Tous les RDV';
      case FilterType.today:
        return "Aujourd'hui seulement";
      case FilterType.upcoming:
        return 'RDV à venir';
      case FilterType.completed:
        return 'RDV terminés';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KipikTheme.rouge,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}