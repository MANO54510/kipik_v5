// lib/pages/pro/booking/booking_import_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../widgets/common/buttons/tattoo_assistant_button.dart';
import 'dart:math';

enum CalendarProvider { google, apple, outlook, ical, csv }
enum SyncDirection { import, export, bidirectional }
enum SyncFrequency { manual, realtime, hourly, daily }
enum ImportStatus { idle, connecting, importing, success, error }

class CalendarAccount {
  final String id;
  final CalendarProvider provider;
  final String email;
  final String name;
  final bool isConnected;
  final DateTime? lastSync;
  final int eventsCount;
  final String? error;

  CalendarAccount({
    required this.id,
    required this.provider,
    required this.email,
    required this.name,
    this.isConnected = false,
    this.lastSync,
    this.eventsCount = 0,
    this.error,
  });
}

class ImportedEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final String? location;
  final CalendarProvider source;
  final bool isSelected;
  final bool hasConflict;
  final String? conflictReason;

  ImportedEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
    required this.source,
    this.isSelected = true,
    this.hasConflict = false,
    this.conflictReason,
  });
}

class BookingImportPage extends StatefulWidget {
  const BookingImportPage({Key? key}) : super(key: key);

  @override
  State<BookingImportPage> createState() => _BookingImportPageState();
}

class _BookingImportPageState extends State<BookingImportPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _syncController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _syncAnimation;

  // État de la page
  ImportStatus _importStatus = ImportStatus.idle;
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Données
  List<CalendarAccount> _accounts = [];
  List<ImportedEvent> _importedEvents = [];
  CalendarAccount? _selectedAccount;
  SyncDirection _syncDirection = SyncDirection.import;
  SyncFrequency _syncFrequency = SyncFrequency.daily;
  DateTimeRange? _importRange;
  
  // Filtres
  bool _importPersonalEvents = false;
  bool _skipConflicts = true;
  bool _mergeWithExisting = true;
  bool _createBackup = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAccounts();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _syncController.dispose();
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
    
    _syncController = AnimationController(
      duration: const Duration(seconds: 2),
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
    
    _syncAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _syncController, curve: Curves.linear),
    );

    _slideController.forward();
    _scaleController.forward();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    
    // Simulation du chargement des comptes
    await Future.delayed(const Duration(milliseconds: 1000));
    
    setState(() {
      _accounts = [
        CalendarAccount(
          id: '1',
          provider: CalendarProvider.google,
          email: 'tatoueur@gmail.com',
          name: 'Calendrier Principal',
          isConnected: true,
          lastSync: DateTime.now().subtract(const Duration(hours: 2)),
          eventsCount: 45,
        ),
        CalendarAccount(
          id: '2',
          provider: CalendarProvider.apple,
          email: 'tatoueur@icloud.com',
          name: 'iCloud Calendar',
          isConnected: false,
          eventsCount: 0,
        ),
        CalendarAccount(
          id: '3',
          provider: CalendarProvider.outlook,
          email: 'tatoueur@outlook.com',
          name: 'Outlook Calendar',
          isConnected: false,
          eventsCount: 0,
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Import Calendriers',
        subtitle: 'Synchronisation et import de données',
        showBackButton: true,
        useProStyle: true,
        actions: [
          IconButton(
            onPressed: _refreshAccounts,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
          ),
          IconButton(
            onPressed: _showImportHistory,
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Historique',
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
            'Chargement des calendriers...',
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
          _buildImportHeader(),
          const SizedBox(height: 16),
          _buildProgressIndicator(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildCurrentStepContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildImportHeader() {
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
                Icons.cloud_download_outlined,
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
                    'Import & Synchronisation',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Connectez vos calendriers existants',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildHeaderStat('Comptes', '${_accounts.where((a) => a.isConnected).length}'),
                      const SizedBox(width: 16),
                      _buildHeaderStat('Événements', '${_accounts.fold(0, (sum, a) => sum + a.eventsCount)}'),
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

  Widget _buildHeaderStat(String label, String value) {
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

  Widget _buildProgressIndicator() {
    final steps = ['Connexion', 'Configuration', 'Import', 'Finalisation'];
    
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent 
                            ? KipikTheme.rouge 
                            : Colors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted 
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: isCompleted || isCurrent ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: isCompleted || isCurrent ? KipikTheme.rouge : Colors.grey,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_currentStep + 1) / steps.length,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildConnectionStep();
      case 1:
        return _buildConfigurationStep();
      case 2:
        return _buildImportStep();
      case 3:
        return _buildFinalizationStep();
      default:
        return _buildConnectionStep();
    }
  }

  Widget _buildConnectionStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStepHeader(
            'Connexion aux Calendriers',
            'Connectez-vous à vos calendriers existants pour synchroniser vos rendez-vous',
          ),
          const SizedBox(height: 24),
          
          // Liste des comptes
          ...(_accounts.map((account) => _buildAccountCard(account))),
          
          const SizedBox(height: 24),
          
          // Boutons d'ajout
          _buildAddAccountSection(),
          
          const SizedBox(height: 32),
          
          // Navigation
          _buildStepNavigation(
            canContinue: _accounts.any((a) => a.isConnected),
            onContinue: () => setState(() => _currentStep = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStepHeader(
            'Configuration de l\'Import',
            'Définissez les paramètres de synchronisation selon vos besoins',
          ),
          const SizedBox(height: 24),
          
          // Sélection du compte
          _buildAccountSelector(),
          const SizedBox(height: 16),
          
          // Direction de sync
          _buildSyncDirectionSelector(),
          const SizedBox(height: 16),
          
          // Période d'import
          _buildDateRangeSelector(),
          const SizedBox(height: 16),
          
          // Options avancées
          _buildAdvancedOptions(),
          
          const SizedBox(height: 32),
          
          // Navigation
          _buildStepNavigation(
            canContinue: _selectedAccount != null,
            onContinue: _startImport,
            onBack: () => setState(() => _currentStep = 0),
          ),
        ],
      ),
    );
  }

  Widget _buildImportStep() {
    return Column(
      children: [
        _buildStepHeader(
          'Import en Cours',
          'Récupération et analyse de vos événements existants',
        ),
        const SizedBox(height: 24),
        
        if (_importStatus == ImportStatus.importing) 
          _buildImportProgress()
        else if (_importStatus == ImportStatus.success)
          Expanded(child: _buildImportResults())
        else if (_importStatus == ImportStatus.error)
          _buildImportError(),
        
        const SizedBox(height: 24),
        
        if (_importStatus == ImportStatus.success)
          _buildStepNavigation(
            canContinue: true,
            onContinue: () => setState(() => _currentStep = 3),
            onBack: () => setState(() => _currentStep = 1),
          ),
      ],
    );
  }

  Widget _buildFinalizationStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStepHeader(
            'Finalisation',
            'Import terminé avec succès ! Configurez la synchronisation continue',
          ),
          const SizedBox(height: 24),
          
          // Résumé de l'import
          _buildImportSummary(),
          const SizedBox(height: 24),
          
          // Configuration sync continue
          _buildContinuousSyncConfig(),
          const SizedBox(height: 32),
          
          // Actions finales
          _buildFinalActions(),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(CalendarAccount account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: account.isConnected 
              ? Colors.green.withOpacity(0.3) 
              : Colors.grey.withOpacity(0.3),
        ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getProviderColor(account.provider).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getProviderIcon(account.provider),
              color: _getProviderColor(account.provider),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  account.email,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (account.isConnected) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${account.eventsCount} événements',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => _toggleAccountConnection(account),
                style: ElevatedButton.styleFrom(
                  backgroundColor: account.isConnected ? Colors.orange : KipikTheme.rouge,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  account.isConnected ? 'Déconnecter' : 'Connecter',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                  ),
                ),
              ),
              if (account.lastSync != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Sync: ${_formatLastSync(account.lastSync!)}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Text(
            'Ajouter un nouveau calendrier',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildProviderButton(CalendarProvider.google),
              _buildProviderButton(CalendarProvider.apple),
              _buildProviderButton(CalendarProvider.outlook),
              _buildProviderButton(CalendarProvider.ical),
              _buildProviderButton(CalendarProvider.csv),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderButton(CalendarProvider provider) {
    return OutlinedButton.icon(
      onPressed: () => _connectProvider(provider),
      icon: Icon(_getProviderIcon(provider), size: 16),
      label: Text(_getProviderName(provider)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _getProviderColor(provider),
        side: BorderSide(color: _getProviderColor(provider)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAccountSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_circle, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Compte à synchroniser',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<CalendarAccount>(
            value: _selectedAccount,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: _accounts.where((a) => a.isConnected).map((account) {
              return DropdownMenuItem(
                value: account,
                child: Row(
                  children: [
                    Icon(_getProviderIcon(account.provider), size: 16),
                    const SizedBox(width: 8),
                    Text('${account.name} (${account.eventsCount} événements)'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (account) => setState(() => _selectedAccount = account),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncDirectionSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync_alt, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Direction de synchronisation',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...SyncDirection.values.map((direction) {
            return RadioListTile<SyncDirection>(
              title: Text(_getSyncDirectionLabel(direction)),
              subtitle: Text(_getSyncDirectionDescription(direction)),
              value: direction,
              groupValue: _syncDirection,
              activeColor: KipikTheme.rouge,
              onChanged: (value) => setState(() => _syncDirection = value!),
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Période d\'import',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: KipikTheme.rouge),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _importRange != null
                          ? '${_formatDate(_importRange!.start)} - ${_formatDate(_importRange!.end)}'
                          : 'Sélectionner une période',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.expand_more, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Options avancées',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Importer événements personnels'),
            subtitle: const Text('Inclure les événements non-professionnels'),
            value: _importPersonalEvents,
            activeColor: KipikTheme.rouge,
            onChanged: (value) => setState(() => _importPersonalEvents = value),
            contentPadding: EdgeInsets.zero,
          ),
          
          SwitchListTile(
            title: const Text('Ignorer les conflits'),
            subtitle: const Text('Ne pas importer les événements en conflit'),
            value: _skipConflicts,
            activeColor: KipikTheme.rouge,
            onChanged: (value) => setState(() => _skipConflicts = value),
            contentPadding: EdgeInsets.zero,
          ),
          
          SwitchListTile(
            title: const Text('Fusionner avec l\'existant'),
            subtitle: const Text('Combiner avec les RDV actuels'),
            value: _mergeWithExisting,
            activeColor: KipikTheme.rouge,
            onChanged: (value) => setState(() => _mergeWithExisting = value),
            contentPadding: EdgeInsets.zero,
          ),
          
          SwitchListTile(
            title: const Text('Créer une sauvegarde'),
            subtitle: const Text('Sauvegarder avant import (recommandé)'),
            value: _createBackup,
            activeColor: KipikTheme.rouge,
            onChanged: (value) => setState(() => _createBackup = value),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildImportProgress() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _syncController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _syncAnimation.value,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
                    ),
                  ),
                  Column(
                    children: [
                      Icon(
                        Icons.cloud_sync,
                        color: KipikTheme.rouge,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_syncAnimation.value * 100).round()}%',
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 18,
                          color: KipikTheme.rouge,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Import en cours...',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Récupération et analyse de vos événements',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportResults() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Import réussi !',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            '${_importedEvents.length} événements trouvés',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: _importedEvents.length,
              itemBuilder: (context, index) {
                final event = _importedEvents[index];
                return _buildImportedEventCard(event);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportedEventCard(ImportedEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: event.hasConflict 
            ? Colors.red.withOpacity(0.1) 
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: event.hasConflict ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: event.isSelected,
            activeColor: KipikTheme.rouge,
            onChanged: (value) {
              // Toggle selection
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_formatDateTime(event.startTime)} - ${_formatTime(event.endTime)}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                if (event.hasConflict) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.conflictReason ?? 'Conflit détecté',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            _getProviderIcon(event.source),
            color: _getProviderColor(event.source),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildImportError() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 24),
          const Text(
            'Erreur d\'import',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Une erreur est survenue lors de l\'import',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _retryImport,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Résumé de l\'import',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow('Événements importés', '${_importedEvents.where((e) => e.isSelected).length}'),
          _buildSummaryRow('Conflits détectés', '${_importedEvents.where((e) => e.hasConflict).length}'),
          _buildSummaryRow('Source', _selectedAccount?.name ?? ''),
          _buildSummaryRow('Période', _importRange != null 
              ? '${_formatDate(_importRange!.start)} - ${_formatDate(_importRange!.end)}'
              : 'Toutes les dates'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinuousSyncConfig() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.autorenew, color: KipikTheme.rouge, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Synchronisation continue',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<SyncFrequency>(
            value: _syncFrequency,
            decoration: InputDecoration(
              labelText: 'Fréquence de synchronisation',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: SyncFrequency.values.map((frequency) {
              return DropdownMenuItem(
                value: frequency,
                child: Text(_getSyncFrequencyLabel(frequency)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _syncFrequency = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _finishImport,
            icon: const Icon(Icons.check_circle, size: 20),
            label: const Text(
              'Terminer l\'import',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exporter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _viewInCalendar,
                icon: const Icon(Icons.calendar_view_day, size: 18),
                label: const Text('Voir agenda'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KipikTheme.rouge,
                  side: BorderSide(color: KipikTheme.rouge),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepNavigation({
    required bool canContinue,
    VoidCallback? onContinue,
    VoidCallback? onBack,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Retour'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canContinue ? onContinue : null,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Continuer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: canContinue ? KipikTheme.rouge : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  void _refreshAccounts() async {
    await _loadAccounts();
  }

  void _showImportHistory() {
    _showInfoSnackBar('Historique des imports - À implémenter');
  }

  void _toggleAccountConnection(CalendarAccount account) async {
    if (account.isConnected) {
      // Déconnexion
      setState(() {
        final index = _accounts.indexOf(account);
        _accounts[index] = CalendarAccount(
          id: account.id,
          provider: account.provider,
          email: account.email,
          name: account.name,
          isConnected: false,
          eventsCount: 0,
        );
      });
      _showSuccessSnackBar('Compte déconnecté');
    } else {
      // Connexion
      setState(() => _isLoading = true);
      
      try {
        // Simulation de connexion
        await Future.delayed(const Duration(seconds: 2));
        
        setState(() {
          final index = _accounts.indexOf(account);
          _accounts[index] = CalendarAccount(
            id: account.id,
            provider: account.provider,
            email: account.email,
            name: account.name,
            isConnected: true,
            lastSync: DateTime.now(),
            eventsCount: Random().nextInt(50) + 10,
          );
        });
        
        _showSuccessSnackBar('Compte connecté avec succès');
      } catch (e) {
        _showErrorSnackBar('Erreur de connexion');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _connectProvider(CalendarProvider provider) {
    _showInfoSnackBar('Connexion ${_getProviderName(provider)} - À implémenter');
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _importRange,
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
      setState(() => _importRange = picked);
    }
  }

  void _startImport() async {
    setState(() {
      _currentStep = 2;
      _importStatus = ImportStatus.importing;
    });
    
    _syncController.repeat();
    
    try {
      // Simulation de l'import
      await Future.delayed(const Duration(seconds: 3));
      
      // Génération d'événements factices
      _importedEvents = List.generate(15, (index) {
        final start = DateTime.now().add(Duration(days: index, hours: 9 + (index % 8)));
        return ImportedEvent(
          id: 'event_$index',
          title: 'RDV Client ${index + 1}',
          startTime: start,
          endTime: start.add(const Duration(hours: 2)),
          description: 'Description de l\'événement',
          location: 'Studio',
          source: _selectedAccount!.provider,
          hasConflict: index % 5 == 0,
          conflictReason: index % 5 == 0 ? 'Créneau déjà occupé' : null,
        );
      });
      
      setState(() => _importStatus = ImportStatus.success);
      _syncController.stop();
      
    } catch (e) {
      setState(() {
        _importStatus = ImportStatus.error;
        _errorMessage = e.toString();
      });
      _syncController.stop();
    }
  }

  void _retryImport() {
    _startImport();
  }

  void _finishImport() {
    Navigator.pop(context);
    _showSuccessSnackBar('Import terminé avec succès !');
  }

  void _exportData() {
    _showInfoSnackBar('Export des données - À implémenter');
  }

  void _viewInCalendar() {
    Navigator.pushReplacementNamed(context, '/booking/calendar');
  }

  // Helper methods
  Color _getProviderColor(CalendarProvider provider) {
    switch (provider) {
      case CalendarProvider.google:
        return Colors.blue;
      case CalendarProvider.apple:
        return Colors.grey;
      case CalendarProvider.outlook:
        return Colors.orange;
      case CalendarProvider.ical:
        return Colors.purple;
      case CalendarProvider.csv:
        return Colors.green;
    }
  }

  IconData _getProviderIcon(CalendarProvider provider) {
    switch (provider) {
      case CalendarProvider.google:
        return Icons.account_circle;
      case CalendarProvider.apple:
        return Icons.phone_iphone;
      case CalendarProvider.outlook:
        return Icons.email;
      case CalendarProvider.ical:
        return Icons.calendar_today;
      case CalendarProvider.csv:
        return Icons.table_chart;
    }
  }

  String _getProviderName(CalendarProvider provider) {
    switch (provider) {
      case CalendarProvider.google:
        return 'Google Calendar';
      case CalendarProvider.apple:
        return 'Apple Calendar';
      case CalendarProvider.outlook:
        return 'Outlook';
      case CalendarProvider.ical:
        return 'iCal / ICS';
      case CalendarProvider.csv:
        return 'Fichier CSV';
    }
  }

  String _getSyncDirectionLabel(SyncDirection direction) {
    switch (direction) {
      case SyncDirection.import:
        return 'Import seulement';
      case SyncDirection.export:
        return 'Export seulement';
      case SyncDirection.bidirectional:
        return 'Synchronisation bidirectionnelle';
    }
  }

  String _getSyncDirectionDescription(SyncDirection direction) {
    switch (direction) {
      case SyncDirection.import:
        return 'Importer les événements externes vers Kipik';
      case SyncDirection.export:
        return 'Exporter les RDV Kipik vers le calendrier externe';
      case SyncDirection.bidirectional:
        return 'Synchronisation automatique dans les deux sens';
    }
  }

  String _getSyncFrequencyLabel(SyncFrequency frequency) {
    switch (frequency) {
      case SyncFrequency.manual:
        return 'Manuelle';
      case SyncFrequency.realtime:
        return 'Temps réel';
      case SyncFrequency.hourly:
        return 'Toutes les heures';
      case SyncFrequency.daily:
        return 'Quotidienne';
    }
  }

  String _formatLastSync(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inMinutes}min';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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