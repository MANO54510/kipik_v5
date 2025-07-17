// lib/pages/pro/booking/booking_calendar_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';
import 'dart:math';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import '../flashs/flash_minute_create_page.dart';

class BookingCalendarPage extends StatefulWidget {
  const BookingCalendarPage({Key? key}) : super(key: key);

  @override
  State<BookingCalendarPage> createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // État du calendrier
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // État de la page
  bool _isLoading = true;
  bool _showFreeSlotsOnly = false;
  String _selectedView = 'Semaine';
  
  // Données RDV
  Map<DateTime, List<Map<String, dynamic>>> _appointments = {};
  List<Map<String, dynamic>> _dayAppointments = [];
  List<Map<String, dynamic>> _freeSlots = [];
  
  // Flash Minute
  bool _hasActiveFlashMinute = false;
  Map<String, dynamic>? _pendingCancellation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _selectedDay = _focusedDay;
    _loadCalendarData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      _appointments = await _generateAppointments();
      _updateDayAppointments();
      _detectFreeSlots();
      _checkActiveFlashMinute();
      
    } catch (e) {
      print('❌ Erreur chargement calendrier: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<DateTime, List<Map<String, dynamic>>>> _generateAppointments() async {
    final appointments = <DateTime, List<Map<String, dynamic>>>{};
    final now = DateTime.now();
    final random = Random();
    
    // Générer des RDV pour les 30 prochains jours
    for (int i = 0; i < 30; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      final dayAppointments = <Map<String, dynamic>>[];
      
      // Ajouter quelques RDV par jour (sauf dimanche)
      if (date.weekday != 7) {
        final numAppointments = random.nextInt(4) + 1;
        
        for (int j = 0; j < numAppointments; j++) {
          final hour = 9 + (j * 2) + random.nextInt(2);
          final startTime = DateTime(date.year, date.month, date.day, hour, 0);
          final duration = (random.nextInt(3) + 2) * 30; // 1h à 2h30
          
          dayAppointments.add({
            'id': 'rdv_${i}_$j',
            'title': _getRandomTattooStyle(),
            'clientName': _getRandomClientName(),
            'startTime': startTime,
            'endTime': startTime.add(Duration(minutes: duration)),
            'status': _getRandomStatus(),
            'type': 'tattoo',
            'price': (random.nextInt(200) + 100).toDouble(),
            'isFlashMinute': false,
            'canCancel': startTime.isAfter(now.add(const Duration(hours: 24))),
          });
        }
      }
      
      if (dayAppointments.isNotEmpty) {
        appointments[date] = dayAppointments;
      }
    }
    
    return appointments;
  }

  void _updateDayAppointments() {
    if (_selectedDay != null) {
      final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      _dayAppointments = _appointments[selectedDate] ?? [];
      _dayAppointments.sort((a, b) => a['startTime'].compareTo(b['startTime']));
    }
  }

  void _detectFreeSlots() {
    if (_selectedDay == null) return;
    
    _freeSlots.clear();
    final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final now = DateTime.now();
    
    // Ne détecter que pour aujourd'hui et les jours futurs
    if (selectedDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return;
    }
    
    final dayAppointments = _appointments[selectedDate] ?? [];
    
    // Heures d'ouverture : 9h-19h
    final startHour = 9;
    final endHour = 19;
    
    if (dayAppointments.isEmpty) {
      // Journée entièrement libre
      _freeSlots.add({
        'startTime': DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startHour, 0),
        'endTime': DateTime(selectedDate.year, selectedDate.month, selectedDate.day, endHour, 0),
        'duration': Duration(hours: endHour - startHour),
        'type': 'full_day',
      });
    } else {
      // Détecter les créneaux entre les RDV
      for (int hour = startHour; hour < endHour; hour++) {
        final slotStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, 0);
        final slotEnd = slotStart.add(const Duration(hours: 1));
        
        // Vérifier si ce créneau est libre
        final isOccupied = dayAppointments.any((appointment) {
          final appointmentStart = appointment['startTime'] as DateTime;
          final appointmentEnd = appointment['endTime'] as DateTime;
          
          return slotStart.isBefore(appointmentEnd) && slotEnd.isAfter(appointmentStart);
        });
        
        if (!isOccupied && slotStart.isAfter(now)) {
          _freeSlots.add({
            'startTime': slotStart,
            'endTime': slotEnd,
            'duration': const Duration(hours: 1),
            'type': 'slot',
          });
        }
      }
    }
  }

  void _checkActiveFlashMinute() {
    // Simuler la vérification d'un Flash Minute actif
    _hasActiveFlashMinute = Random().nextBool();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Planning & Réservations',
        subtitle: _getSubtitle(),
        showBackButton: true,
        useProStyle: true,
        actions: [
          // Bouton créneaux libres
          if (_freeSlots.isNotEmpty)
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
                  const Icon(Icons.access_time, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_freeSlots.length}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Flash Minute actif
          if (_hasActiveFlashMinute)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'ACTIF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Synchroniser', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Exporter', style: TextStyle(color: Colors.white)),
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  String _getSubtitle() {
    final todayAppointments = _appointments[DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)]?.length ?? 0;
    final freeCount = _freeSlots.length;
    
    if (freeCount > 0) {
      return '$todayAppointments RDV • $freeCount créneaux libres';
    }
    return '$todayAppointments RDV aujourd\'hui';
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
            'Chargement du planning...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildViewSelector(),
        _buildCalendar(),
        _buildDayHeader(),
        Expanded(
          child: _buildDayView(),
        ),
      ],
    );
  }

  Widget _buildViewSelector() {
    final views = ['Jour', 'Semaine', 'Mois'];
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: views.map((view) {
          final isSelected = view == _selectedView;
          return Expanded(
            child: GestureDetector(
              onTap: () => _changeView(view),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? KipikTheme.rouge : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  view,
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

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar<Map<String, dynamic>>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: (day) {
          final dateKey = DateTime(day.year, day.month, day.day);
          return _appointments[dateKey] ?? [];
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _updateDayAppointments();
            _detectFreeSlots();
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        // Style du calendrier
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(color: Colors.grey),
          selectedTextStyle: const TextStyle(color: Colors.white),
          todayTextStyle: const TextStyle(color: Colors.white),
          selectedDecoration: BoxDecoration(
            color: KipikTheme.rouge,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerDecoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.grey),
          weekendStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDayHeader() {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _formatSelectedDay(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _buildQuickFilter('Tous', !_showFreeSlotsOnly),
                  const SizedBox(width: 8),
                  _buildQuickFilter('Libres', _showFreeSlotsOnly),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDayStats(),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showFreeSlotsOnly = label == 'Libres';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? KipikTheme.rouge : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? KipikTheme.rouge : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDayStats() {
    return Row(
      children: [
        _buildStatChip('RDV', _dayAppointments.length, Icons.event, Colors.blue),
        const SizedBox(width: 12),
        _buildStatChip('Libres', _freeSlots.length, Icons.access_time, Colors.green),
        const SizedBox(width: 12),
        _buildStatChip('Revenus', '${_calculateDayRevenue()}€', Icons.euro, Colors.purple),
        const Spacer(),
        if (_freeSlots.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _proposeFlashMinute,
            icon: const Icon(Icons.flash_on, size: 16),
            label: const Text('Flash Minute'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip(String label, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    if (_showFreeSlotsOnly) {
      return _buildFreeSlotsView();
    } else {
      return _buildAppointmentsView();
    }
  }

  Widget _buildAppointmentsView() {
    if (_dayAppointments.isEmpty) {
      return _buildEmptyDayState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _dayAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _dayAppointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildFreeSlotsView() {
    if (_freeSlots.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun créneau libre',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Planning complet pour cette journée',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _freeSlots.length,
      itemBuilder: (context, index) {
        final slot = _freeSlots[index];
        return _buildFreeSlotCard(slot);
      },
    );
  }

  Widget _buildEmptyDayState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.free_breakfast,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          const Text(
            'Journée libre !',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucun RDV prévu pour cette journée',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _proposeFlashMinute,
            icon: const Icon(Icons.flash_on),
            label: const Text('Créer un Flash Minute'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'];
    final canCancel = appointment['canCancel'] ?? false;
    final startTime = appointment['startTime'] as DateTime;
    final endTime = appointment['endTime'] as DateTime;
    final isFlashMinute = appointment['isFlashMinute'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
        ),
        boxShadow: isFlashMinute ? [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAppointmentDetails(appointment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            appointment['clientName'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isFlashMinute)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'FLASH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '${appointment['price']}€',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (canCancel) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _cancelAppointment(appointment),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Annuler'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeSlotCard(Map<String, dynamic> slot) {
    final startTime = slot['startTime'] as DateTime;
    final endTime = slot['endTime'] as DateTime;
    final duration = slot['duration'] as Duration;
    final type = slot['type'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _createFlashMinuteForSlot(slot),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type == 'full_day' ? 'Journée complète libre' : 'Créneau libre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_formatTime(startTime)} - ${_formatTime(endTime)} (${_formatDuration(duration)})',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _createFlashMinuteForSlot(slot),
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('Flash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        text = 'Confirmé';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'En attente';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Annulé';
        break;
      default:
        color = Colors.grey;
        text = status;
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

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_freeSlots.isNotEmpty)
          FloatingActionButton.extended(
            heroTag: 'flash',
            onPressed: _proposeFlashMinute,
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.flash_on),
            label: const Text('Flash Minute'),
          ),
        if (_freeSlots.isNotEmpty) const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'add',
          onPressed: _addAppointment,
          backgroundColor: KipikTheme.rouge,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  // Helper methods
  String _formatSelectedDay() {
    if (_selectedDay == null) return '';
    
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    
    final weekday = weekdays[_selectedDay!.weekday - 1];
    final day = _selectedDay!.day;
    final month = months[_selectedDay!.month - 1];
    
    final today = DateTime.now();
    if (isSameDay(_selectedDay!, today)) {
      return 'Aujourd\'hui • $weekday $day $month';
    } else if (isSameDay(_selectedDay!, today.add(const Duration(days: 1)))) {
      return 'Demain • $weekday $day $month';
    } else {
      return '$weekday $day $month';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  int _calculateDayRevenue() {
    return _dayAppointments.fold<int>(0, (sum, appointment) {
      return sum + (appointment['price'] as double).toInt();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRandomTattooStyle() {
    final styles = ['Tatouage Réaliste', 'Flash Rose', 'Mandala', 'Géométrique', 'Aquarelle', 'Old School'];
    return styles[Random().nextInt(styles.length)];
  }

  String _getRandomClientName() {
    final names = ['Sophie M.', 'Lucas D.', 'Emma L.', 'Thomas P.', 'Marie C.', 'Antoine R.'];
    return names[Random().nextInt(names.length)];
  }

  String _getRandomStatus() {
    final statuses = ['confirmed', 'pending'];
    return statuses[Random().nextInt(statuses.length)];
  }

  // Actions
  void _changeView(String view) {
    setState(() {
      _selectedView = view;
      switch (view) {
        case 'Jour':
          _calendarFormat = CalendarFormat.week;
          break;
        case 'Semaine':
          _calendarFormat = CalendarFormat.week;
          break;
        case 'Mois':
          _calendarFormat = CalendarFormat.month;
          break;
      }
    });
  }

  void _proposeFlashMinute() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FlashMinuteCreatePage()),
    ).then((_) => _loadCalendarData());
  }

  void _createFlashMinuteForSlot(Map<String, dynamic> slot) {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.flash_on, color: Colors.orange),
            SizedBox(width: 8),
            Text('Flash Minute', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Créer un Flash Minute pour ce créneau ?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatTime(slot['startTime'])} - ${_formatTime(slot['endTime'])}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _proposeFlashMinute();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _cancelAppointment(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Annuler le RDV', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Annuler le RDV avec ${appointment['clientName']} ?',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Voulez-vous créer un Flash Minute pour ce créneau ?',
                      style: TextStyle(color: Colors.orange, fontSize: 14),
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
            child: const Text('Garder RDV'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCancelAppointment(appointment, false);
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Annuler seulement'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCancelAppointment(appointment, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Annuler + Flash'),
          ),
        ],
      ),
    );
  }

  void _performCancelAppointment(Map<String, dynamic> appointment, bool createFlash) {
    setState(() {
      appointment['status'] = 'cancelled';
    });
    
    HapticFeedback.heavyImpact();
    
    if (createFlash) {
      _slideController.forward().then((_) {
        _proposeFlashMinute();
        _slideController.reset();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('RDV annulé ! Créez votre Flash Minute maintenant.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Créer',
            onPressed: _proposeFlashMinute,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RDV annulé'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    _detectFreeSlots();
  }

  void _addAppointment() {
    // TODO: Implémenter l'ajout de RDV
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout de RDV à implémenter')),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Client: ${appointment['clientName']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Horaire: ${_formatTime(appointment['startTime'])} - ${_formatTime(appointment['endTime'])}',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prix: ${appointment['price']}€',
                    style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sync':
        _syncCalendar();
        break;
      case 'export':
        _exportCalendar();
        break;
      case 'settings':
        _showCalendarSettings();
        break;
    }
  }

  void _syncCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📅 Synchronisation avec Google Calendar...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Export du planning en cours...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCalendarSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres à implémenter')),
    );
  }
}