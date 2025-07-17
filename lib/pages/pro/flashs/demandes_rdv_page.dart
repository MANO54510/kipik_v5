// lib/pages/pro/flashs/demandes_rdv_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';

class DemandesRdvPage extends StatefulWidget {
  const DemandesRdvPage({Key? key}) : super(key: key);

  @override
  State<DemandesRdvPage> createState() => _DemandesRdvPageState();
}

class _DemandesRdvPageState extends State<DemandesRdvPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // État de la page
  bool _isLoading = true;
  String _selectedFilter = 'Toutes';
  
  // Données
  List<Map<String, dynamic>> _demandes = [];
  Map<String, Timer> _countdownTimers = {};
  
  // Filtres
  final List<String> _filters = ['Toutes', 'En attente', 'Négociation', 'Urgentes'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDemandes();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _disposeTimers();
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

  void _disposeTimers() {
    for (final timer in _countdownTimers.values) {
      timer.cancel();
    }
    _countdownTimers.clear();
  }

  Future<void> _loadDemandes() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Simuler les demandes
      _demandes = _generateDemandes();
      _startCountdownTimers();
      
    } catch (e) {
      print('❌ Erreur chargement demandes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _generateDemandes() {
    final random = Random();
    final now = DateTime.now();
    
    return [
      {
        'id': 'demande_001',
        'clientName': 'Sophie Martin',
        'clientAvatar': 'assets/avatars/client_1.jpg',
        'flashTitle': 'Rose Minimaliste',
        'flashId': 'flash_001',
        'flashImage': 'assets/images/flash_rose.jpg',
        'originalPrice': 150.0,
        'discountedPrice': 120.0,
        'originalSize': '8x6cm',
        'requestedSize': '10x8cm',
        'requestedChanges': 'Agrandir le tatouage et ajouter des feuilles',
        'hasModifications': true,
        'status': 'pending', // pending, negotiation, accepted, refused, expired
        'priority': 'high',
        'createdAt': now.subtract(const Duration(minutes: 15)),
        'expiresAt': now.add(const Duration(hours: 1, minutes: 45)),
        'clientMessage': 'Bonjour ! J\'adore ce flash mais j\'aimerais l\'agrandir un peu et ajouter quelques feuilles autour de la rose. C\'est possible ?',
        'acompteAmount': 36.0, // 30% de 120€
      },
      {
        'id': 'demande_002',
        'clientName': 'Lucas Dubois',
        'clientAvatar': 'assets/avatars/client_2.jpg',
        'flashTitle': 'Lion Géométrique',
        'flashId': 'flash_002',
        'flashImage': 'assets/images/flash_lion.jpg',
        'originalPrice': 280.0,
        'discountedPrice': 224.0,
        'originalSize': '12x10cm',
        'requestedSize': '12x10cm',
        'requestedChanges': null,
        'hasModifications': false,
        'status': 'pending',
        'priority': 'medium',
        'createdAt': now.subtract(const Duration(minutes: 32)),
        'expiresAt': now.add(const Duration(hours: 1, minutes: 28)),
        'clientMessage': 'Parfait comme ça ! Quand pouvez-vous me recevoir ?',
        'acompteAmount': 67.2, // 30% de 224€
      },
      {
        'id': 'demande_003',
        'clientName': 'Emma Leroy',
        'clientAvatar': 'assets/avatars/client_3.jpg',
        'flashTitle': 'Mandala Lotus',
        'flashId': 'flash_003',
        'flashImage': 'assets/images/flash_mandala.jpg',
        'originalPrice': 200.0,
        'discountedPrice': 160.0,
        'originalSize': '10x10cm',
        'requestedSize': '8x8cm',
        'requestedChanges': 'Simplifier le mandala et changer les couleurs',
        'hasModifications': true,
        'status': 'negotiation',
        'priority': 'high',
        'createdAt': now.subtract(const Duration(hours: 1, minutes: 10)),
        'expiresAt': now.add(const Duration(minutes: 50)),
        'clientMessage': 'Je voudrais une version plus simple et en noir et blanc uniquement.',
        'acompteAmount': 48.0, // 30% de 160€
      },
      {
        'id': 'demande_004',
        'clientName': 'Thomas Petit',
        'clientAvatar': 'assets/avatars/client_4.jpg',
        'flashTitle': 'Papillon Aquarelle',
        'flashId': 'flash_004',
        'flashImage': 'assets/images/flash_papillon.jpg',
        'originalPrice': 180.0,
        'discountedPrice': 144.0,
        'originalSize': '9x7cm',
        'requestedSize': '12x9cm',
        'requestedChanges': 'Ajouter plus de couleurs vives',
        'hasModifications': true,
        'status': 'pending',
        'priority': 'urgent',
        'createdAt': now.subtract(const Duration(hours: 1, minutes: 45)),
        'expiresAt': now.add(const Duration(minutes: 15)),
        'clientMessage': 'Flash Minute ! Pouvez-vous ajouter du violet et du turquoise ?',
        'acompteAmount': 43.2, // 30% de 144€
      },
    ];
  }

  void _startCountdownTimers() {
    for (final demande in _demandes) {
      if (demande['status'] == 'pending' || demande['status'] == 'negotiation') {
        final timerId = demande['id'];
        _countdownTimers[timerId] = Timer.periodic(
          const Duration(seconds: 1),
          (timer) => _updateCountdown(timerId),
        );
      }
    }
  }

  void _updateCountdown(String demandeId) {
    final demande = _demandes.firstWhere((d) => d['id'] == demandeId);
    final now = DateTime.now();
    final expiresAt = demande['expiresAt'] as DateTime;
    
    if (now.isAfter(expiresAt)) {
      // Demande expirée
      _expireDemande(demandeId);
    } else {
      // Mise à jour de l'UI si nécessaire
      if (mounted) {
        setState(() {
          // Forcer le rebuild pour mettre à jour les countdowns
        });
      }
    }
  }

  void _expireDemande(String demandeId) {
    setState(() {
      final demande = _demandes.firstWhere((d) => d['id'] == demandeId);
      demande['status'] = 'expired';
    });
    
    _countdownTimers[demandeId]?.cancel();
    _countdownTimers.remove(demandeId);
    
    HapticFeedback.heavyImpact();
    _showExpiredNotification(demandeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Demandes RDV',
        subtitle: _getSubtitle(),
        showBackButton: true,
        useProStyle: true,
        actions: [
          // Badge urgent
          if (_getUrgentCount() > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.priority_high, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_getUrgentCount()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDemandes,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: _buildQuickActionsButton(),
    );
  }

  String _getSubtitle() {
    final activeDemandes = _getFilteredDemandes().length;
    final urgentCount = _getUrgentCount();
    
    if (urgentCount > 0) {
      return '$activeDemandes demandes • $urgentCount urgentes !';
    }
    return '$activeDemandes demandes actives';
  }

  int _getUrgentCount() {
    return _demandes.where((d) => 
      (d['status'] == 'pending' || d['status'] == 'negotiation') &&
      _getRemainingMinutes(d) < 30
    ).length;
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
            'Chargement des demandes...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_demandes.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _buildDemandesList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune demande active',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les demandes de Flash Minute apparaîtront ici',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          final count = _getFilterCount(filter);
          
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? KipikTheme.rouge : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? KipikTheme.rouge : Colors.grey[700]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.2) : KipikTheme.rouge,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDemandesList() {
    final filteredDemandes = _getFilteredDemandes();
    
    if (filteredDemandes.isEmpty) {
      return Center(
        child: Text(
          'Aucune demande dans "$_selectedFilter"',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredDemandes.length,
      itemBuilder: (context, index) {
        final demande = filteredDemandes[index];
        return _buildDemandeCard(demande, index);
      },
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> demande, int index) {
    final isUrgent = _getRemainingMinutes(demande) < 30;
    final hasModifications = demande['hasModifications'] == true;
    final status = demande['status'];
    
    return AnimatedBuilder(
      animation: isUrgent ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: isUrgent ? _pulseAnimation.value : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor(status).withOpacity(0.3),
                width: isUrgent ? 2 : 1,
              ),
              boxShadow: isUrgent ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showDemandeDetails(demande),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDemandeHeader(demande),
                      const SizedBox(height: 12),
                      _buildFlashInfo(demande),
                      if (hasModifications) ...[
                        const SizedBox(height: 12),
                        _buildModificationInfo(demande),
                      ],
                      const SizedBox(height: 12),
                      _buildCountdownAndActions(demande),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDemandeHeader(Map<String, dynamic> demande) {
    final status = demande['status'];
    final priority = demande['priority'];
    
    return Row(
      children: [
        // Avatar client
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[800],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              demande['clientAvatar'],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[800],
                child: Icon(Icons.person, color: Colors.grey[600]),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Nom client
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                demande['clientName'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatTime(demande['createdAt']),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        // Badges statut
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStatusBadge(status),
            if (priority == 'urgent') ...[
              const SizedBox(height: 4),
              _buildPriorityBadge(priority),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFlashInfo(Map<String, dynamic> demande) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Image flash
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey[800],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                demande['flashImage'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Info flash
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demande['flashTitle'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${demande['originalPrice']}€',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${demande['discountedPrice']}€',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Acompte: ${demande['acompteAmount']}€',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildModificationInfo(Map<String, dynamic> demande) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Modifications demandées',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (demande['originalSize'] != demande['requestedSize'])
            Text(
              'Taille: ${demande['originalSize']} → ${demande['requestedSize']}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          if (demande['requestedChanges'] != null)
            Text(
              demande['requestedChanges'],
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildCountdownAndActions(Map<String, dynamic> demande) {
    final status = demande['status'];
    final remainingMinutes = _getRemainingMinutes(demande);
    final isExpired = status == 'expired';
    
    return Row(
      children: [
        // Countdown
        if (!isExpired) ...[
          Icon(
            Icons.access_time,
            color: remainingMinutes < 30 ? Colors.red : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _formatCountdown(remainingMinutes),
            style: TextStyle(
              color: remainingMinutes < 30 ? Colors.red : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else ...[
          const Icon(Icons.schedule_outlined, color: Colors.grey, size: 16),
          const SizedBox(width: 4),
          const Text(
            'Expiré',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
        
        const Spacer(),
        
        // Actions rapides
        if (status == 'pending' || status == 'negotiation') ...[
          OutlinedButton(
            onPressed: () => _refuseDemande(demande['id']),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 0),
            ),
            child: const Text('Refuser', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _acceptDemande(demande['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 0),
            ),
            child: Text(
              demande['hasModifications'] ? 'Négocier' : 'Accepter',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'En attente';
        icon = Icons.schedule;
        break;
      case 'negotiation':
        color = Colors.blue;
        text = 'Négociation';
        icon = Icons.chat;
        break;
      case 'accepted':
        color = Colors.green;
        text = 'Accepté';
        icon = Icons.check_circle;
        break;
      case 'refused':
        color = Colors.red;
        text = 'Refusé';
        icon = Icons.cancel;
        break;
      case 'expired':
        color = Colors.grey;
        text = 'Expiré';
        icon = Icons.schedule_outlined;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    if (priority != 'urgent') return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high, color: Colors.white, size: 10),
          SizedBox(width: 2),
          Text(
            'URGENT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsButton() {
    final urgentCount = _getUrgentCount();
    
    if (urgentCount == 0) return const SizedBox.shrink();
    
    return FloatingActionButton.extended(
      onPressed: _showQuickActions,
      backgroundColor: Colors.red,
      icon: const Icon(Icons.flash_on, color: Colors.white),
      label: Text(
        'Urgent ($urgentCount)',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper methods
  List<Map<String, dynamic>> _getFilteredDemandes() {
    switch (_selectedFilter) {
      case 'En attente':
        return _demandes.where((d) => d['status'] == 'pending').toList();
      case 'Négociation':
        return _demandes.where((d) => d['status'] == 'negotiation').toList();
      case 'Urgentes':
        return _demandes.where((d) => 
          (d['status'] == 'pending' || d['status'] == 'negotiation') &&
          _getRemainingMinutes(d) < 30
        ).toList();
      default:
        return _demandes.where((d) => 
          d['status'] != 'accepted' && d['status'] != 'refused'
        ).toList();
    }
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'En attente':
        return _demandes.where((d) => d['status'] == 'pending').length;
      case 'Négociation':
        return _demandes.where((d) => d['status'] == 'negotiation').length;
      case 'Urgentes':
        return _getUrgentCount();
      default:
        return _demandes.where((d) => 
          d['status'] != 'accepted' && d['status'] != 'refused'
        ).length;
    }
  }

  int _getRemainingMinutes(Map<String, dynamic> demande) {
    final expiresAt = demande['expiresAt'] as DateTime;
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    return difference.inMinutes.clamp(0, double.infinity).toInt();
  }

  String _formatCountdown(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${mins}min';
    } else {
      return '${mins}min';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'negotiation':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'refused':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Actions
  void _showDemandeDetails(Map<String, dynamic> demande) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDemandeDetailsSheet(demande),
    );
  }

  Widget _buildDemandeDetailsSheet(Map<String, dynamic> demande) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Demande de ${demande['clientName']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Contenu
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailFlashInfo(demande),
                      const SizedBox(height: 20),
                      _buildClientMessage(demande),
                      const SizedBox(height: 20),
                      if (demande['hasModifications'])
                        _buildNegotiationSection(demande),
                      const SizedBox(height: 100), // Espace pour les boutons
                    ],
                  ),
                ),
              ),
              
              // Actions
              _buildDetailActions(demande),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailFlashInfo(Map<String, dynamic> demande) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[800],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    demande['flashImage'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demande['flashTitle'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${demande['originalPrice']}€',
                          style: const TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${demande['discountedPrice']}€',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acompte: ${demande['acompteAmount']}€ (30%)',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientMessage(Map<String, dynamic> demande) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.message, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Message du client',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            demande['clientMessage'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationSection(Map<String, dynamic> demande) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Modifications demandées',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (demande['originalSize'] != demande['requestedSize']) ...[
            Row(
              children: [
                const Text('Taille: ', style: TextStyle(color: Colors.grey)),
                Text(
                  '${demande['originalSize']} → ${demande['requestedSize']}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (demande['requestedChanges'] != null) ...[
            const Text('Modifications: ', style: TextStyle(color: Colors.grey)),
            Text(
              demande['requestedChanges'],
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailActions(Map<String, dynamic> demande) {
    final status = demande['status'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        border: Border(
          top: BorderSide(color: Color(0xFF3A3A3A)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (status == 'pending' || status == 'negotiation') ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _refuseDemande(demande['id']);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _acceptDemande(demande['id']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    demande['hasModifications'] ? 'Accepter les modifications' : 'Accepter la demande',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _acceptDemande(String demandeId) {
    setState(() {
      final demande = _demandes.firstWhere((d) => d['id'] == demandeId);
      demande['status'] = 'accepted';
    });
    
    _countdownTimers[demandeId]?.cancel();
    _countdownTimers.remove(demandeId);
    
    HapticFeedback.heavyImpact();
    _showAcceptedSnackBar(demandeId);
  }

  void _refuseDemande(String demandeId) {
    setState(() {
      final demande = _demandes.firstWhere((d) => d['id'] == demandeId);
      demande['status'] = 'refused';
    });
    
    _countdownTimers[demandeId]?.cancel();
    _countdownTimers.remove(demandeId);
    
    HapticFeedback.mediumImpact();
    _showRefusedSnackBar(demandeId);
  }

  void _showQuickActions() {
    final urgentDemandes = _demandes.where((d) => 
      (d['status'] == 'pending' || d['status'] == 'negotiation') &&
      _getRemainingMinutes(d) < 30
    ).toList();
    
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
                children: [
                  const Text(
                    'Actions rapides - Demandes urgentes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _refuseAllUrgent();
                          },
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Refuser tout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _acceptAllUrgent();
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Accepter tout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
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
    );
  }

  void _acceptAllUrgent() {
    final urgentDemandes = _demandes.where((d) => 
      (d['status'] == 'pending' || d['status'] == 'negotiation') &&
      _getRemainingMinutes(d) < 30
    ).toList();
    
    for (final demande in urgentDemandes) {
      _acceptDemande(demande['id']);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${urgentDemandes.length} demandes urgentes acceptées'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _refuseAllUrgent() {
    final urgentDemandes = _demandes.where((d) => 
      (d['status'] == 'pending' || d['status'] == 'negotiation') &&
      _getRemainingMinutes(d) < 30
    ).toList();
    
    for (final demande in urgentDemandes) {
      _refuseDemande(demande['id']);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${urgentDemandes.length} demandes urgentes refusées'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showAcceptedSnackBar(String demandeId) {
    final demande = _demandes.firstWhere((d) => d['id'] == demandeId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande de ${demande['clientName']} acceptée ! Acompte: ${demande['acompteAmount']}€'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () => _showDemandeDetails(demande),
        ),
      ),
    );
  }

  void _showRefusedSnackBar(String demandeId) {
    final demande = _demandes.firstWhere((d) => d['id'] == demandeId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande de ${demande['clientName']} refusée'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showExpiredNotification(String demandeId) {
    final demande = _demandes.firstWhere((d) => d['id'] == demandeId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏰ Demande de ${demande['clientName']} expirée'),
        backgroundColor: Colors.grey[700],
      ),
    );
  }
}