// lib/pages/pro/booking/booking_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../widgets/common/buttons/tattoo_assistant_button.dart';
import 'dart:math';

enum NotificationFrequency { immediate, hourly, daily, weekly }
enum DefaultView { day, week, month }
enum WorkingHours { full, custom, flexible }
enum ReminderTiming { minutes15, minutes30, hour1, hours2, hours24 }
enum CalendarSync { none, googleOnly, appleOnly, both }

class BookingSettingsPage extends StatefulWidget {
  const BookingSettingsPage({Key? key}) : super(key: key);

  @override
  State<BookingSettingsPage> createState() => _BookingSettingsPageState();
}

class _BookingSettingsPageState extends State<BookingSettingsPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _settingsController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _settingsAnimation;

  // États des paramètres
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _clientReminders = true;
  bool _flashMinuteAlerts = true;
  bool _weekendWork = false;
  bool _autoConfirm = false;
  bool _doubleBookingPrevention = true;
  bool _calendarSync = true;
  bool _locationTracking = false;
  bool _advancedStats = true;
  bool _darkMode = false;
  bool _hapticFeedback = true;
  bool _soundNotifications = true;
  
  NotificationFrequency _notificationFrequency = NotificationFrequency.immediate;
  DefaultView _defaultView = DefaultView.day;
  WorkingHours _workingHours = WorkingHours.custom;
  ReminderTiming _clientReminderTiming = ReminderTiming.hours24;
  CalendarSync _calendarSyncType = CalendarSync.googleOnly;
  
  TimeOfDay _workStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _workEndTime = const TimeOfDay(hour: 18, minute: 0);
  int _breakDuration = 60; // minutes
  int _defaultSlotDuration = 120; // minutes
  double _defaultPrice = 150.0;
  double _depositPercentage = 30.0;
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _settingsController.dispose();
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
    
    _settingsController = AnimationController(
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
    
    _settingsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _settingsController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _scaleController.forward();
    _settingsController.forward();
  }

  Future<void> _loadSettings() async {
    // Simulation du chargement des paramètres
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Paramètres Booking',
        subtitle: 'Personnalisation et notifications',
        showBackButton: true,
        useProStyle: true,
        actions: [
          if (_hasChanges)
            IconButton(
              onPressed: _saveSettings,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              tooltip: 'Sauvegarder',
            ),
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Réinitialiser',
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
            'Chargement des paramètres...',
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
          _buildSettingsHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNotificationsSection(),
                  const SizedBox(height: 16),
                  _buildScheduleSection(),
                  const SizedBox(height: 16),
                  _buildCalendarSection(),
                  const SizedBox(height: 16),
                  _buildDefaultsSection(),
                  const SizedBox(height: 16),
                  _buildAdvancedSection(),
                  const SizedBox(height: 16),
                  _buildAppearanceSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader() {
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.settings_rounded,
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
                    'Configuration Avancée',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Personnalisez votre expérience booking',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuickStat('Notifications', _notificationsEnabled ? 'ON' : 'OFF'),
                      const SizedBox(width: 16),
                      _buildQuickStat('Sync', _calendarSync ? 'Activée' : 'Désactivée'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSettingsSection(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      child: Column(
        children: [
          // Switch principal notifications
          _buildSwitchTile(
            'Notifications activées',
            'Recevoir des alertes pour les RDV',
            _notificationsEnabled,
            (value) => setState(() {
              _notificationsEnabled = value;
              _markHasChanges();
            }),
            icon: Icons.notifications,
          ),
          
          if (_notificationsEnabled) ...[
            const SizedBox(height: 12),
            
            // Types de notifications
            _buildSwitchTile(
              'Notifications push',
              'Alertes sur l\'appareil',
              _pushNotifications,
              (value) => setState(() {
                _pushNotifications = value;
                _markHasChanges();
              }),
              icon: Icons.phone_android,
            ),
            
            _buildSwitchTile(
              'Notifications email',
              'Alertes par email',
              _emailNotifications,
              (value) => setState(() {
                _emailNotifications = value;
                _markHasChanges();
              }),
              icon: Icons.email,
            ),
            
            _buildSwitchTile(
              'Notifications SMS',
              'Alertes par SMS (Premium)',
              _smsNotifications,
              (value) => setState(() {
                _smsNotifications = value;
                _markHasChanges();
              }),
              icon: Icons.sms,
              isPremium: true,
            ),
            
            const SizedBox(height: 16),
            
            // Fréquence notifications
            _buildDropdownTile(
              'Fréquence des notifications',
              'Grouper les notifications',
              _notificationFrequency,
              NotificationFrequency.values,
              (value) => setState(() {
                _notificationFrequency = value;
                _markHasChanges();
              }),
              getLabel: _getNotificationFrequencyLabel,
            ),
            
            const SizedBox(height: 12),
            
            // Flash Minute alerts
            _buildSwitchTile(
              'Alertes Flash Minute',
              'Notifications pour créneaux libres',
              _flashMinuteAlerts,
              (value) => setState(() {
                _flashMinuteAlerts = value;
                _markHasChanges();
              }),
              icon: Icons.flash_on,
            ),
            
            // Rappels clients
            _buildSwitchTile(
              'Rappels clients automatiques',
              'Envoyer des rappels aux clients',
              _clientReminders,
              (value) => setState(() {
                _clientReminders = value;
                _markHasChanges();
              }),
              icon: Icons.schedule_send,
            ),
            
            if (_clientReminders) ...[
              const SizedBox(height: 12),
              _buildDropdownTile(
                'Timing des rappels',
                'Délai avant le RDV',
                _clientReminderTiming,
                ReminderTiming.values,
                (value) => setState(() {
                  _clientReminderTiming = value;
                  _markHasChanges();
                }),
                getLabel: _getReminderTimingLabel,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return _buildSettingsSection(
      title: 'Planning & Horaires',
      icon: Icons.schedule_outlined,
      child: Column(
        children: [
          // Heures de travail
          _buildDropdownTile(
            'Heures de travail',
            'Configuration des créneaux',
            _workingHours,
            WorkingHours.values,
            (value) => setState(() {
              _workingHours = value;
              _markHasChanges();
            }),
            getLabel: _getWorkingHoursLabel,
          ),
          
          if (_workingHours == WorkingHours.custom) ...[
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectWorkStartTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Début',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _workStartTime.format(context),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: GestureDetector(
                    onTap: _selectWorkEndTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fin',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _workEndTime.format(context),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Durée de pause
            _buildSliderTile(
              'Pause déjeuner',
              'Durée en minutes',
              _breakDuration.toDouble(),
              0,
              120,
              (value) => setState(() {
                _breakDuration = value.round();
                _markHasChanges();
              }),
              suffix: 'min',
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Weekend
          _buildSwitchTile(
            'Travail le weekend',
            'Autoriser les RDV samedi/dimanche',
            _weekendWork,
            (value) => setState(() {
              _weekendWork = value;
              _markHasChanges();
            }),
            icon: Icons.weekend,
          ),
          
          // Prévention double booking
          _buildSwitchTile(
            'Prévention double réservation',
            'Empêcher les créneaux en conflit',
            _doubleBookingPrevention,
            (value) => setState(() {
              _doubleBookingPrevention = value;
              _markHasChanges();
            }),
            icon: Icons.block,
          ),
          
          // Auto-confirmation
          _buildSwitchTile(
            'Confirmation automatique',
            'Confirmer les RDV sans validation',
            _autoConfirm,
            (value) => setState(() {
              _autoConfirm = value;
              _markHasChanges();
            }),
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return _buildSettingsSection(
      title: 'Calendriers & Synchronisation',
      icon: Icons.calendar_today_outlined,
      child: Column(
        children: [
          // Sync principal
          _buildSwitchTile(
            'Synchronisation calendriers',
            'Synchroniser avec calendriers externes',
            _calendarSync,
            (value) => setState(() {
              _calendarSync = value;
              _markHasChanges();
            }),
            icon: Icons.sync,
          ),
          
          if (_calendarSync) ...[
            const SizedBox(height: 16),
            
            _buildDropdownTile(
              'Type de synchronisation',
              'Calendriers à synchroniser',
              _calendarSyncType,
              CalendarSync.values,
              (value) => setState(() {
                _calendarSyncType = value;
                _markHasChanges();
              }),
              getLabel: _getCalendarSyncLabel,
            ),
            
            const SizedBox(height: 16),
            
            // Status sync
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Synchronisation active',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Dernière sync: ${_getLastSyncTime()}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _manualSync,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      foregroundColor: Colors.green,
                    ),
                    child: const Text('Synchroniser'),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Vue par défaut
          _buildDropdownTile(
            'Vue par défaut',
            'Vue affichée à l\'ouverture',
            _defaultView,
            DefaultView.values,
            (value) => setState(() {
              _defaultView = value;
              _markHasChanges();
            }),
            getLabel: _getDefaultViewLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultsSection() {
    return _buildSettingsSection(
      title: 'Valeurs par Défaut',
      icon: Icons.settings_applications_outlined,
      child: Column(
        children: [
          // Durée créneau par défaut
          _buildSliderTile(
            'Durée de créneau par défaut',
            'Minutes par RDV',
            _defaultSlotDuration.toDouble(),
            30,
            300,
            (value) => setState(() {
              _defaultSlotDuration = value.round();
              _markHasChanges();
            }),
            suffix: 'min',
            step: 15,
          ),
          
          const SizedBox(height: 16),
          
          // Prix par défaut
          _buildSliderTile(
            'Prix par défaut',
            'Euros par session',
            _defaultPrice,
            50,
            500,
            (value) => setState(() {
              _defaultPrice = value;
              _markHasChanges();
            }),
            suffix: '€',
            step: 10,
          ),
          
          const SizedBox(height: 16),
          
          // Pourcentage acompte
          _buildSliderTile(
            'Acompte par défaut',
            'Pourcentage du prix total',
            _depositPercentage,
            0,
            50,
            (value) => setState(() {
              _depositPercentage = value;
              _markHasChanges();
            }),
            suffix: '%',
            step: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return _buildSettingsSection(
      title: 'Fonctionnalités Avancées',
      icon: Icons.extension_outlined,
      child: Column(
        children: [
          // Localisation
          _buildSwitchTile(
            'Suivi de localisation',
            'Géolocalisation pour Guests/Conventions',
            _locationTracking,
            (value) => setState(() {
              _locationTracking = value;
              _markHasChanges();
            }),
            icon: Icons.location_on,
            isPremium: true,
          ),
          
          // Stats avancées
          _buildSwitchTile(
            'Statistiques avancées',
            'Analytics détaillées du planning',
            _advancedStats,
            (value) => setState(() {
              _advancedStats = value;
              _markHasChanges();
            }),
            icon: Icons.analytics,
            isPremium: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSettingsSection(
      title: 'Apparence & Interface',
      icon: Icons.palette_outlined,
      child: Column(
        children: [
          // Mode sombre
          _buildSwitchTile(
            'Mode sombre',
            'Interface sombre pour l\'agenda',
            _darkMode,
            (value) => setState(() {
              _darkMode = value;
              _markHasChanges();
            }),
            icon: Icons.dark_mode,
          ),
          
          // Feedback haptique
          _buildSwitchTile(
            'Retour haptique',
            'Vibrations lors des interactions',
            _hapticFeedback,
            (value) => setState(() {
              _hapticFeedback = value;
              _markHasChanges();
            }),
            icon: Icons.vibration,
          ),
          
          // Sons
          _buildSwitchTile(
            'Sons de notification',
            'Sons pour les alertes',
            _soundNotifications,
            (value) => setState(() {
              _soundNotifications = value;
              _markHasChanges();
            }),
            icon: Icons.volume_up,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Bouton principal
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _hasChanges && !_isLoading ? _saveSettings : null,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save, size: 20),
            label: Text(
              _isLoading ? 'Sauvegarde...' : 'Sauvegarder les paramètres',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasChanges ? KipikTheme.rouge : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: _hasChanges ? 4 : 0,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Actions secondaires
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportSettings,
                icon: const Icon(Icons.download, size: 18),
                label: const Text(
                  'Exporter',
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
                onPressed: _importSettings,
                icon: const Icon(Icons.upload, size: 18),
                label: const Text(
                  'Importer',
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

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: _settingsAnimation,
      child: Container(
        width: double.infinity,
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
                Icon(icon, color: KipikTheme.rouge, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    IconData? icon,
    bool isPremium = false,
  }) {
    return ListTile(
      leading: icon != null 
          ? Icon(icon, color: KipikTheme.rouge, size: 20)
          : null,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        activeColor: KipikTheme.rouge,
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdownTile<T>(
    String title,
    String subtitle,
    T value,
    List<T> items,
    ValueChanged<T> onChanged, {
    required String Function(T) getLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                getLabel(item),
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String suffix = '',
    double step = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: KipikTheme.rouge.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()}$suffix',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: KipikTheme.rouge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: KipikTheme.rouge,
            inactiveTrackColor: KipikTheme.rouge.withOpacity(0.2),
            thumbColor: KipikTheme.rouge,
            overlayColor: KipikTheme.rouge.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / step).round(),
            onChanged: (newValue) {
              onChanged(newValue);
              _markHasChanges();
            },
          ),
        ),
      ],
    );
  }

  // Actions
  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulation de sauvegarde
      await Future.delayed(const Duration(seconds: 1));
      
      HapticFeedback.mediumImpact();
      
      setState(() {
        _hasChanges = false;
      });
      
      _showSuccessSnackBar('Paramètres sauvegardés avec succès');
      
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les paramètres'),
        content: const Text('Voulez-vous vraiment restaurer les paramètres par défaut ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreDefaults();
            },
            style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _restoreDefaults() {
    setState(() {
      _notificationsEnabled = true;
      _emailNotifications = true;
      _pushNotifications = true;
      _smsNotifications = false;
      _clientReminders = true;
      _flashMinuteAlerts = true;
      _weekendWork = false;
      _autoConfirm = false;
      _doubleBookingPrevention = true;
      _calendarSync = true;
      _locationTracking = false;
      _advancedStats = true;
      _darkMode = false;
      _hapticFeedback = true;
      _soundNotifications = true;
      
      _notificationFrequency = NotificationFrequency.immediate;
      _defaultView = DefaultView.day;
      _workingHours = WorkingHours.custom;
      _clientReminderTiming = ReminderTiming.hours24;
      _calendarSyncType = CalendarSync.googleOnly;
      
      _workStartTime = const TimeOfDay(hour: 9, minute: 0);
      _workEndTime = const TimeOfDay(hour: 18, minute: 0);
      _breakDuration = 60;
      _defaultSlotDuration = 120;
      _defaultPrice = 150.0;
      _depositPercentage = 30.0;
      
      _markHasChanges();
    });
    
    _showSuccessSnackBar('Paramètres par défaut restaurés');
  }

  void _selectWorkStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workStartTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: KipikTheme.rouge,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _workStartTime = picked;
        _markHasChanges();
      });
    }
  }

  void _selectWorkEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workEndTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: KipikTheme.rouge,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _workEndTime = picked;
        _markHasChanges();
      });
    }
  }

  void _manualSync() {
    _showInfoSnackBar('Synchronisation en cours...');
  }

  void _exportSettings() {
    _showInfoSnackBar('Export des paramètres - À implémenter');
  }

  void _importSettings() {
    _showInfoSnackBar('Import des paramètres - À implémenter');
  }

  void _markHasChanges() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  // Helper methods
  String _getNotificationFrequencyLabel(NotificationFrequency frequency) {
    switch (frequency) {
      case NotificationFrequency.immediate:
        return 'Immédiate';
      case NotificationFrequency.hourly:
        return 'Horaire';
      case NotificationFrequency.daily:
        return 'Quotidienne';
      case NotificationFrequency.weekly:
        return 'Hebdomadaire';
    }
  }

  String _getWorkingHoursLabel(WorkingHours hours) {
    switch (hours) {
      case WorkingHours.full:
        return '24h/24 - 7j/7';
      case WorkingHours.custom:
        return 'Personnalisées';
      case WorkingHours.flexible:
        return 'Flexibles';
    }
  }

  String _getReminderTimingLabel(ReminderTiming timing) {
    switch (timing) {
      case ReminderTiming.minutes15:
        return '15 minutes avant';
      case ReminderTiming.minutes30:
        return '30 minutes avant';
      case ReminderTiming.hour1:
        return '1 heure avant';
      case ReminderTiming.hours2:
        return '2 heures avant';
      case ReminderTiming.hours24:
        return '24 heures avant';
    }
  }

  String _getCalendarSyncLabel(CalendarSync sync) {
    switch (sync) {
      case CalendarSync.none:
        return 'Aucune';
      case CalendarSync.googleOnly:
        return 'Google Calendar seulement';
      case CalendarSync.appleOnly:
        return 'Apple Calendar seulement';
      case CalendarSync.both:
        return 'Google et Apple';
    }
  }

  String _getDefaultViewLabel(DefaultView view) {
    switch (view) {
      case DefaultView.day:
        return 'Vue jour';
      case DefaultView.week:
        return 'Vue semaine';
      case DefaultView.month:
        return 'Vue mois';
    }
  }

  String _getLastSyncTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
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