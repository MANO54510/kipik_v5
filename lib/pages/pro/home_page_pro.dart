import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_kipik.dart';
import 'package:kipik_v5/widgets/common/buttons/tattoo_assistant_button.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/models/user.dart';

// Imports pour la navigation
import 'package:kipik_v5/pages/pro/agenda/pro_agenda_home_page.dart';
import 'package:kipik_v5/pages/pro/agenda/pro_agenda_notifications_page.dart';
import 'dashboard_page.dart';

// Modèles pour les rendez-vous
enum AppointmentType { consultation, session, retouche, suivi }

class TodayAppointment {
  final String id;
  final DateTime time;
  final String clientName;
  final String? projectName;
  final AppointmentType type;
  final Duration estimatedDuration;
  final String? notes;

  TodayAppointment({
    required this.id,
    required this.time,
    required this.clientName,
    this.projectName,
    required this.type,
    required this.estimatedDuration,
    this.notes,
  });
}

class HomePagePro extends StatefulWidget {
  const HomePagePro({Key? key}) : super(key: key);

  @override
  State<HomePagePro> createState() => _HomePageProState();
}

class _HomePageProState extends State<HomePagePro> {
  User? _user;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Données du profil/stats
  final double _monthlyRevenue = 3850.00;
  final int _monthlyAppointments = 15;
  final int _newClientsThisMonth = 7;
  final int _notifications = 3;

  // Rendez-vous du jour (exemple)
  late final List<TodayAppointment> _todayAppointments;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _initializeTodayAppointments();
  }

  void _initializeUser() {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      // Rediriger vers la page de connexion si pas d'utilisateur
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    _user = currentUser;
  }

  void _initializeTodayAppointments() {
    final now = DateTime.now();
    _todayAppointments = [
      TodayAppointment(
        id: '1',
        time: DateTime(now.year, now.month, now.day, 10, 0),
        clientName: 'Marie Dubois',
        projectName: 'Rose géométrique',
        type: AppointmentType.consultation,
        estimatedDuration: const Duration(hours: 1),
        notes: 'Première consultation',
      ),
      TodayAppointment(
        id: '2',
        time: DateTime(now.year, now.month, now.day, 14, 30),
        clientName: 'Jean Martin',
        projectName: 'Tribal bras',
        type: AppointmentType.session,
        estimatedDuration: const Duration(hours: 3),
        notes: 'Session 2/3',
      ),
      TodayAppointment(
        id: '3',
        time: DateTime(now.year, now.month, now.day, 18, 0),
        clientName: 'Sophie Laurent',
        type: AppointmentType.suivi,
        estimatedDuration: const Duration(minutes: 30),
        notes: 'Contrôle cicatrisation',
      ),
    ];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Bonjour";
    if (hour < 18) return "Bon après-midi";
    return "Bonsoir";
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _handleNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProAgendaNotificationsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Protection si l'utilisateur n'est pas initialisé
    if (_user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF0A0A0A), // Noir profond
        extendBodyBehindAppBar: true,
        endDrawer: const CustomDrawerKipik(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Espace Pro',
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _handleNotifications,
                  ),
                  if (_notifications > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: KipikTheme.rouge,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$_notifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _openDrawer,
              ),
            ),
          ],
        ),
        floatingActionButton: const TattooAssistantButton(
          allowImageGeneration: false,
        ),
        body: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Carte de profil avec stats intégrées
                _buildProfileCard(),
                
                const SizedBox(height: 32),
                
                // Titre planning du jour
                _buildSectionHeader(
                  'Planning d\'aujourd\'hui',
                  Icons.calendar_today,
                  _todayAppointments.length,
                ),
                
                const SizedBox(height: 16),
                
                // Planning du jour
                _buildTodaySchedule(),
                
                const SizedBox(height: 32),
                
                // Bouton dashboard complet
                _buildDashboardButton(),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête profil
          Row(
            children: [
              GestureDetector(
                onTap: _pickProfileImage,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: KipikTheme.rouge.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: KipikTheme.rouge.withOpacity(0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _user!.profileImageUrl?.isNotEmpty == true
                          ? Image.network(
                              _user!.profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                'assets/avatars/avatar_neutre.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/avatars/avatar_neutre.png',
                              fit: BoxFit.cover,
                            ),
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
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user!.name,
                      style: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 24,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tatoueur Professionnel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          
          // Titre des récapitulatifs mensuels
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: KipikTheme.rouge,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Récapitulatifs du mois',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats du mois en mini-cartes avec taille fixe
          Row(
            children: [
              Expanded(
                child: _buildStatMiniCard(
                  'Chiffre d\'affaires',
                  '${_monthlyRevenue.toStringAsFixed(0)}€',
                  Icons.trending_up,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatMiniCard(
                  'Rendez-vous',
                  '$_monthlyAppointments',
                  Icons.event,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatMiniCard(
                  'Nouveaux clients',
                  '$_newClientsThisMonth',
                  Icons.person_add,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMiniCard(String label, String value, IconData icon, Color color) {
    return Container(
      height: 120, // Hauteur augmentée pour éviter la coupure
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Répartit l'espace uniformément
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 15,
              color: color,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: KipikTheme.rouge.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: KipikTheme.rouge,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySchedule() {
    if (_todayAppointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.free_breakfast,
                size: 32,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun rendez-vous',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Profitez de cette journée libre pour vous reposer !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _todayAppointments.map((appointment) => 
        _buildAppointmentCard(appointment)
      ).toList(),
    );
  }

  Widget _buildAppointmentCard(TodayAppointment appointment) {
    final typeColor = _getAppointmentTypeColor(appointment.type);
    final typeLabel = _getAppointmentTypeLabel(appointment.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Heure et durée
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${appointment.time.hour.toString().padLeft(2, '0')}:${appointment.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 16,
                    color: typeColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${appointment.estimatedDuration.inMinutes}min',
                  style: TextStyle(
                    fontSize: 10,
                    color: typeColor.withOpacity(0.7),
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Informations du RDV
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.clientName,
                  style: const TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 16,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (appointment.projectName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    appointment.projectName!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: typeColor,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bouton action
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              color: typeColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAppointmentTypeColor(AppointmentType type) {
    switch (type) {
      case AppointmentType.consultation:
        return const Color(0xFF3B82F6);
      case AppointmentType.session:
        return KipikTheme.rouge;
      case AppointmentType.retouche:
        return const Color(0xFFF59E0B);
      case AppointmentType.suivi:
        return const Color(0xFF10B981);
    }
  }

  String _getAppointmentTypeLabel(AppointmentType type) {
    switch (type) {
      case AppointmentType.consultation:
        return 'Consultation';
      case AppointmentType.session:
        return 'Séance tatouage';
      case AppointmentType.retouche:
        return 'Retouche';
      case AppointmentType.suivi:
        return 'Suivi';
    }
  }

  Widget _buildDashboardButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KipikTheme.rouge,
            KipikTheme.rouge.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: KipikTheme.rouge.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DashboardPage(),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dashboard_outlined,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Tableau de bord complet',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    final XFile? image = await openFile(acceptedTypeGroups: [typeGroup]);

    if (image != null) {
      // TODO: Upload vers Firebase Storage et mettre à jour le profil utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Photo de profil mise à jour !',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}