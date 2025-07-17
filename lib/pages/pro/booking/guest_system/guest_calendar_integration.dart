// lib/pages/pro/booking/guest_system/guest_calendar_integration.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../theme/kipik_theme.dart';
import '../../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../../widgets/common/buttons/tattoo_assistant_button.dart';

enum IntegrationType { automatic, manual, selective }
enum SyncStatus { pending, syncing, completed, failed }

class GuestCalendarIntegration extends StatefulWidget {
  final Map<String, dynamic>? guestContract;
  
  const GuestCalendarIntegration({
    Key? key,
    this.guestContract,
  }) : super(key: key);

  @override
  State<GuestCalendarIntegration> createState() => _GuestCalendarIntegrationState();
}

class _GuestCalendarIntegrationState extends State<GuestCalendarIntegration> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  IntegrationType _selectedType = IntegrationType.automatic;
  SyncStatus _currentStatus = SyncStatus.pending;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  bool _isIntegrating = false;
  bool _locationChangeEnabled = true;
  bool _autoBlockSlots = true;
  bool _sendNotifications = true;
  bool _syncWithExternalCalendar = true;
  
  double _integrationProgress = 0.0;
  List<Map<String, dynamic>> _guestSlots = [];
  List<String> _integrationSteps = [];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGuestData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _slideController.forward();
  }

  void _initializeGuestData() {
    if (widget.guestContract != null) {
      _generateGuestSlots();
      _setupIntegrationSteps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Intégration Agenda',
        subtitle: 'Guest System Premium',
        showBackButton: true,
        useProStyle: true,
        actions: [
          IconButton(
            icon: Icon(
              _currentStatus == SyncStatus.completed ? Icons.cloud_done : Icons.sync,
              color: Colors.white,
            ),
            onPressed: _currentStatus != SyncStatus.syncing ? _syncCalendar : null,
          ),
        ],
      ),
      floatingActionButton: const TattooAssistantButton(),
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
              child: _buildContent(),
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
          if (widget.guestContract != null) ...[
            _buildGuestContractHeader(),
            const SizedBox(height: 16),
          ],
          _buildIntegrationTypeSelector(),
          const SizedBox(height: 16),
          if (_isIntegrating) ...[
            _buildIntegrationProgress(),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: _buildCalendarView(),
          ),
          if (!_isIntegrating) ...[
            const SizedBox(height: 16),
            _buildIntegrationOptions(),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGuestContractHeader() {
    final contract = widget.guestContract!;
    final isOutgoing = contract['type'] == 'outgoing';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOutgoing 
              ? [Colors.blue.withOpacity(0.8), Colors.blue.withOpacity(0.6)]
              : [Colors.purple.withOpacity(0.8), Colors.purple.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(16),
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
              isOutgoing ? Icons.flight_takeoff : Icons.flight_land,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract['partnerName'],
                  style: const TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${contract['startDate']} - ${contract['endDate']}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  isOutgoing ? 'Guest sortant' : 'Guest entrant',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              contract['location'],
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.integration_instructions, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Type d\'intégration',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Column(
            children: IntegrationType.values.map((type) {
              return _buildIntegrationTypeCard(type);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationTypeCard(IntegrationType type) {
    final isSelected = _selectedType == type;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
          HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(
              colors: [KipikTheme.rouge.withOpacity(0.8), KipikTheme.rouge.withOpacity(0.6)],
            ) : null,
            color: isSelected ? null : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? KipikTheme.rouge : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getIntegrationTypeIcon(type),
                color: isSelected ? Colors.white : KipikTheme.rouge,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getIntegrationTypeTitle(type),
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getIntegrationTypeDescription(type),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: isSelected ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntegrationProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Intégration en cours',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Barre de progression
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progression',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${(_integrationProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: KipikTheme.rouge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _integrationProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
                    minHeight: 8,
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Étapes
          Column(
            children: _integrationSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : 
                      (isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                      color: isCompleted ? Colors.green : 
                            (isCurrent ? KipikTheme.rouge : Colors.grey),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: isCompleted ? Colors.green : 
                                (isCurrent ? Colors.black87 : Colors.grey),
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Planning Guest',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_guestSlots.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_guestSlots.length} créneaux',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: TableCalendar<Map<String, dynamic>>(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: Colors.red),
                holidayTextStyle: const TextStyle(color: Colors.red),
                selectedDecoration: BoxDecoration(
                  color: KipikTheme.rouge,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: KipikTheme.rouge.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: true,
                titleTextStyle: const TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                ),
                formatButtonTextStyle: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                ),
                formatButtonDecoration: BoxDecoration(
                  color: KipikTheme.rouge.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          // Événements du jour sélectionné
          if (_selectedDay != null) ...[
            const SizedBox(height: 16),
            _buildDayEvents(),
          ],
        ],
      ),
    );
  }

  Widget _buildDayEvents() {
    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Aucun événement ce jour',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Événements du ${_formatDate(_selectedDay!)}',
          style: const TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...events.map((event) => _buildEventCard(event)),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event,
            color: Colors.blue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${event['startTime']} - ${event['endTime']}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'GUEST',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Options d\'intégration',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text(
              'Changement de localisation automatique',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 14),
            ),
            subtitle: const Text(
              'Votre localisation sera mise à jour pendant le guest',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            value: _locationChangeEnabled,
            activeColor: KipikTheme.rouge,
            onChanged: (value) {
              setState(() {
                _locationChangeEnabled = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          
          CheckboxListTile(
            title: const Text(
              'Blocage automatique des créneaux',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 14),
            ),
            subtitle: const Text(
              'Vos créneaux habituels seront bloqués pendant le guest',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            value: _autoBlockSlots,
            activeColor: KipikTheme.rouge,
            onChanged: (value) {
              setState(() {
                _autoBlockSlots = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          
          CheckboxListTile(
            title: const Text(
              'Notifications automatiques',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 14),
            ),
            subtitle: const Text(
              'Alertes pour les événements Guest importants',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            value: _sendNotifications,
            activeColor: KipikTheme.rouge,
            onChanged: (value) {
              setState(() {
                _sendNotifications = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          
          CheckboxListTile(
            title: const Text(
              'Synchronisation calendrier externe',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 14),
            ),
            subtitle: const Text(
              'Ajouter les événements Guest à Google/Apple Calendar',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            value: _syncWithExternalCalendar,
            activeColor: KipikTheme.rouge,
            onChanged: (value) {
              setState(() {
                _syncWithExternalCalendar = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: !_isIntegrating ? _startIntegration : null,
            icon: _isIntegrating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.integration_instructions, size: 20),
            label: Text(
              _isIntegrating ? 'Intégration en cours...' : 'Intégrer Guest à l\'agenda',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isIntegrating ? Colors.grey : KipikTheme.rouge,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: _isIntegrating ? 0 : 4,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previewIntegration,
                icon: const Icon(Icons.preview, size: 18),
                label: const Text(
                  'Aperçu',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveAsTemplate,
                icon: const Icon(Icons.save, size: 18),
                label: const Text(
                  'Modèle',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Actions
  void _startIntegration() async {
    setState(() {
      _isIntegrating = true;
      _currentStatus = SyncStatus.syncing;
      _integrationProgress = 0.0;
      _currentStep = 0;
    });
    
    _progressController.forward();
    
    // Simulation du processus d'intégration
    for (int i = 0; i < _integrationSteps.length; i++) {
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _currentStep = i + 1;
        _integrationProgress = (i + 1) / _integrationSteps.length;
      });
      
      if (i == _integrationSteps.length - 1) {
        setState(() {
          _currentStatus = SyncStatus.completed;
          _isIntegrating = false;
        });
        
        _showSuccessDialog();
      }
    }
  }

  void _syncCalendar() async {
    setState(() => _currentStatus = SyncStatus.syncing);
    
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _currentStatus = SyncStatus.completed);
    
    _showSuccessSnackBar('Calendrier synchronisé avec succès !');
  }

  void _previewIntegration() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: _buildPreviewContent(scrollController),
          );
        },
      ),
    );
  }

  Widget _buildPreviewContent(ScrollController scrollController) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Aperçu de l\'intégration',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreviewSection('Événements à créer', [
                    'Guest ${widget.guestContract?['partnerName']} - Arrivée',
                    'Période Guest - ${widget.guestContract?['duration']}',
                    'Guest ${widget.guestContract?['partnerName']} - Départ',
                  ]),
                  
                  _buildPreviewSection('Modifications de localisation', [
                    if (_locationChangeEnabled) 
                      'Localisation temporaire: ${widget.guestContract?['location']}'
                    else 
                      'Aucune modification',
                  ]),
                  
                  _buildPreviewSection('Créneaux bloqués', [
                    if (_autoBlockSlots)
                      '${_calculateBlockedSlots()} créneaux seront bloqués'
                    else
                      'Aucun blocage automatique',
                  ]),
                  
                  _buildPreviewSection('Notifications programmées', [
                    if (_sendNotifications) ...[
                      'Rappel 24h avant le guest',
                      'Notification d\'arrivée',
                      'Résumé quotidien des réalisations',
                    ] else
                      'Aucune notification',
                  ]),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                foregroundColor: Colors.white,
              ),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: KipikTheme.rouge, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _saveAsTemplate() {
    _showSuccessSnackBar('Modèle d\'intégration sauvegardé !');
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Intégration réussie !',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le Guest a été intégré à votre agenda avec toutes les options sélectionnées.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Parfait !',
                  style: TextStyle(fontFamily: 'Roboto'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  // Helper methods
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _guestSlots.where((slot) {
      final slotDate = DateTime.parse(slot['date']);
      return isSameDay(slotDate, day);
    }).toList();
  }

  void _generateGuestSlots() {
    if (widget.guestContract == null) return;
    
    final contract = widget.guestContract!;
    final startDate = DateTime.now().add(const Duration(days: 30));
    final endDate = startDate.add(const Duration(days: 10));
    
    _guestSlots = [
      {
        'date': startDate.toIso8601String(),
        'title': 'Arrivée Guest - ${contract['partnerName']}',
        'startTime': '10:00',
        'endTime': '11:00',
        'type': 'arrival',
      },
      {
        'date': startDate.add(const Duration(days: 1)).toIso8601String(),
        'title': 'Session Guest - Jour 1',
        'startTime': '14:00',
        'endTime': '18:00',
        'type': 'session',
      },
      {
        'date': startDate.add(const Duration(days: 5)).toIso8601String(),
        'title': 'Session Guest - Mi-parcours',
        'startTime': '10:00',
        'endTime': '17:00',
        'type': 'session',
      },
      {
        'date': endDate.toIso8601String(),
        'title': 'Départ Guest - ${contract['partnerName']}',
        'startTime': '16:00',
        'endTime': '17:00',
        'type': 'departure',
      },
    ];
  }

  void _setupIntegrationSteps() {
    _integrationSteps = [
      'Validation des créneaux Guest',
      'Création des événements agenda',
      'Configuration changement localisation',
      'Blocage des créneaux conflictuels',
      'Paramétrage des notifications',
      'Synchronisation calendrier externe',
      'Finalisation de l\'intégration',
    ];
  }

  String _getIntegrationTypeTitle(IntegrationType type) {
    switch (type) {
      case IntegrationType.automatic:
        return 'Intégration automatique';
      case IntegrationType.manual:
        return 'Intégration manuelle';
      case IntegrationType.selective:
        return 'Intégration sélective';
    }
  }

  String _getIntegrationTypeDescription(IntegrationType type) {
    switch (type) {
      case IntegrationType.automatic:
        return 'Toutes les options sont activées automatiquement';
      case IntegrationType.manual:
        return 'Vous contrôlez chaque étape de l\'intégration';
      case IntegrationType.selective:
        return 'Choisissez les options à activer';
    }
  }

  IconData _getIntegrationTypeIcon(IntegrationType type) {
    switch (type) {
      case IntegrationType.automatic:
        return Icons.auto_mode;
      case IntegrationType.manual:
        return Icons.touch_app;
      case IntegrationType.selective:
        return Icons.tune;
    }
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    
    return '$weekday $day $month';
  }

  int _calculateBlockedSlots() {
    // Calcul simulé du nombre de créneaux qui seront bloqués
    return 15;
  }
}