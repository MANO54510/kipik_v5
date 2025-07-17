// lib/pages/shared/conventions/convention_system/convention_pro_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/kipik_theme.dart';
import '../../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../../widgets/common/buttons/tattoo_assistant_button.dart';
import '../../../../services/features/premium_feature_guard.dart';
import '../../../../models/user_subscription.dart';

enum StandRequestStatus { draft, pending, negotiating, accepted, rejected, cancelled, active, completed }
enum PaymentStatus { pending, processing, paid, failed, refunded, cancelled }

class ConventionProManagementPage extends StatefulWidget {
  final String conventionId;  // ✅ Changé pour accepter conventionId comme les autres pages
  
  const ConventionProManagementPage({
    Key? key,
    required this.conventionId,  // ✅ Required comme dans les autres pages
  }) : super(key: key);

  @override
  State<ConventionProManagementPage> createState() => _ConventionProManagementPageState();
}

class _ConventionProManagementPageState extends State<ConventionProManagementPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _cardController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;

  bool _isLoading = false;
  int _selectedTabIndex = 0;
  
  Map<String, dynamic>? _convention;  // ✅ Données convention chargées localement
  List<Map<String, dynamic>> _myStandRequests = [];
  List<Map<String, dynamic>> _availableConventions = [];
  Map<String, dynamic>? _activeLocationChange;
  
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadConventionData();  // ✅ Charger les données de la convention
    _loadProData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  // ✅ Nouvelle méthode pour charger les données de la convention
  Future<void> _loadConventionData() async {
    // TODO: En production, charger depuis Firebase avec widget.conventionId
    // final doc = await FirebaseFirestore.instance
    //     .collection('conventions')
    //     .doc(widget.conventionId)
    //     .get();
    
    // Pour la démo, données simulées
    setState(() {
      _convention = {
        'id': widget.conventionId,
        'name': 'Paris Tattoo Convention 2025',
        'location': 'Paris Expo, Porte de Versailles',
        'dates': '15-17 Mars 2025',
        'status': 'active',
      };
    });
  }

  void _loadProData() {
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _myStandRequests = _generateStandRequests();
        _availableConventions = _generateAvailableConventions();
        _activeLocationChange = _generateActiveLocationChange();
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumFeatureGuard(
      requiredFeature: PremiumFeature.conventions,
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Gestion Conventions',
        subtitle: _convention?['name'] ?? 'Chargement...',  // ✅ Affiche le nom de la convention
        showBackButton: true,
        useProStyle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notification_important, color: Colors.white),
            onPressed: _viewNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _viewHistory,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "newRequest",
            onPressed: _createNewStandRequest,
            backgroundColor: KipikTheme.rouge,
            child: const Icon(Icons.add_business, color: Colors.white),
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
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        _buildLocationStatus(),
        const SizedBox(height: 16),
        _buildTabBar(),
        const SizedBox(height: 16),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            children: [
              _buildMyRequestsTab(),
              _buildAvailableConventionsTab(),
              _buildStandManagementTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStatus() {
    if (_activeLocationChange == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🎪 Localisation temporaire active',
                              style: TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _activeLocationChange!['conventionName'],
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIF',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_city, color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Adresse actuelle: ${_activeLocationChange!['address']}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule, color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Fin: ${_activeLocationChange!['endDate']}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.store, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Stand ${_activeLocationChange!['standNumber']}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _viewLocationDetails,
                          icon: const Icon(Icons.info, size: 16),
                          label: const Text(
                            'Détails',
                            style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _manageLocationChange,
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text(
                            'Gérer',
                            style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6366F1),
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
      },
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
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
        child: Row(
          children: [
            _buildTabItem(0, 'Mes demandes', Icons.request_page),
            _buildTabItem(1, 'Conventions', Icons.event),
            _buildTabItem(2, 'Stands actifs', Icons.store),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(
              colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
            ) : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    if (_myStandRequests.isEmpty) {
      return _buildEmptyState(
        'Aucune demande de stand',
        'Commencez par rechercher des conventions qui vous intéressent',
        Icons.request_page,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        itemCount: _myStandRequests.length,
        itemBuilder: (context, index) {
          return _buildStandRequestCard(_myStandRequests[index]);
        },
      ),
    );
  }

  Widget _buildStandRequestCard(Map<String, dynamic> request) {
    final status = StandRequestStatus.values[request['status']];
    final payment = PaymentStatus.values[request['paymentStatus'] ?? 0];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête demande
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['conventionName'],
                        style: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            request['city'],
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            request['date'],
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusLabel(status),
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
            
            const SizedBox(height: 16),
            
            // Détails stand
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store, color: Colors.black87, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stand ${request['standType']} - ${request['standSize']}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${request['price']}€',
                                  style: TextStyle(
                                    fontFamily: 'PermanentMarker',
                                    fontSize: 16,
                                    color: KipikTheme.rouge,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPaymentColor(payment),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getPaymentLabel(payment),
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
                  
                  if (request['message'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              request['message'],
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Actions selon statut
            _buildRequestActions(request, status, payment),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestActions(Map<String, dynamic> request, StandRequestStatus status, PaymentStatus payment) {
    switch (status) {
      case StandRequestStatus.draft:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _editRequest(request),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _sendRequest(request),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Envoyer', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case StandRequestStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _cancelRequest(request),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Annuler', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _viewRequestDetails(request),
                icon: const Icon(Icons.info, size: 16),
                label: const Text('Détails', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case StandRequestStatus.negotiating:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewNegotiation(request),
                icon: const Icon(Icons.forum, size: 16),
                label: const Text('Négociation', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _respondToNegotiation(request),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Répondre', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case StandRequestStatus.accepted:
        if (payment == PaymentStatus.pending) {
          return Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _payStand(request),
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Payer maintenant', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          );
        }
        return _buildActiveStandActions(request);
        
      case StandRequestStatus.active:
        return _buildActiveStandActions(request);
        
      case StandRequestStatus.completed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _downloadInvoice(request),
                icon: const Icon(Icons.receipt, size: 16),
                label: const Text('Facture', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _rateConvention(request),
                icon: const Icon(Icons.star, size: 16),
                label: const Text('Noter', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      default:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewRequestDetails(request),
                icon: const Icon(Icons.info, size: 16),
                label: const Text('Voir détails', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActiveStandActions(Map<String, dynamic> request) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _viewStandDetails(request),
            icon: const Icon(Icons.info, size: 16),
            label: const Text('Détails stand', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _manageStand(request),
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Gérer', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _activateLocationChange(request),
            icon: const Icon(Icons.location_on, size: 16),
            label: const Text('Localiser', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableConventionsTab() {
    if (_availableConventions.isEmpty) {
      return _buildEmptyState(
        'Aucune convention disponible',
        'Les nouvelles conventions apparaîtront ici',
        Icons.event,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        itemCount: _availableConventions.length,
        itemBuilder: (context, index) {
          return _buildConventionCard(_availableConventions[index]);
        },
      ),
    );
  }

  Widget _buildConventionCard(Map<String, dynamic> convention) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        convention['name'],
                        style: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            convention['city'],
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            convention['date'],
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: convention['standsAvailable'] > 0 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${convention['standsAvailable']} stands',
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
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildConventionStat(
                    Icons.people,
                    '${convention['expectedAttendees']}',
                    'Visiteurs',
                  ),
                ),
                Expanded(
                  child: _buildConventionStat(
                    Icons.euro,
                    'À partir de ${convention['minStandPrice']}€',
                    'Stand',
                  ),
                ),
                Expanded(
                  child: _buildConventionStat(
                    Icons.schedule,
                    '${convention['duration']} jours',
                    'Durée',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewConventionDetails(convention),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text(
                      'Détails',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: convention['standsAvailable'] > 0 
                        ? () => _requestStand(convention)
                        : null,
                    icon: const Icon(Icons.store, size: 16),
                    label: const Text(
                      'Demander stand',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: convention['standsAvailable'] > 0 
                          ? KipikTheme.rouge 
                          : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConventionStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 12,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
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

  Widget _buildStandManagementTab() {
    final activeStands = _myStandRequests.where(
      (request) => StandRequestStatus.values[request['status']] == StandRequestStatus.active
    ).toList();

    if (activeStands.isEmpty) {
      return _buildEmptyState(
        'Aucun stand actif',
        'Vos stands acceptés et payés apparaîtront ici',
        Icons.store,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        itemCount: activeStands.length,
        itemBuilder: (context, index) {
          return _buildActiveStandCard(activeStands[index]);
        },
      ),
    );
  }

  Widget _buildActiveStandCard(Map<String, dynamic> stand) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stand['conventionName'],
                        style: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stand ${stand['standNumber']} - ${stand['standSize']}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ACTIF',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stand['address'],
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${stand['startDate']} - ${stand['endDate']}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${stand['price']}€',
                        style: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewStandAnalytics(stand),
                    icon: const Icon(Icons.analytics, size: 16),
                    label: const Text(
                      'Analytics',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _manageActiveStand(stand),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text(
                      'Gérer',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Chargement des données...',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods pour les couleurs et labels
  Color _getStatusColor(StandRequestStatus status) {
    switch (status) {
      case StandRequestStatus.draft:
        return Colors.grey;
      case StandRequestStatus.pending:
        return Colors.orange;
      case StandRequestStatus.negotiating:
        return Colors.blue;
      case StandRequestStatus.accepted:
        return Colors.green;
      case StandRequestStatus.rejected:
        return Colors.red;
      case StandRequestStatus.cancelled:
        return Colors.grey;
      case StandRequestStatus.active:
        return Colors.green;
      case StandRequestStatus.completed:
        return Colors.indigo;
    }
  }

  String _getStatusLabel(StandRequestStatus status) {
    switch (status) {
      case StandRequestStatus.draft:
        return 'BROUILLON';
      case StandRequestStatus.pending:
        return 'EN ATTENTE';
      case StandRequestStatus.negotiating:
        return 'NÉGOCIATION';
      case StandRequestStatus.accepted:
        return 'ACCEPTÉ';
      case StandRequestStatus.rejected:
        return 'REFUSÉ';
      case StandRequestStatus.cancelled:
        return 'ANNULÉ';
      case StandRequestStatus.active:
        return 'ACTIF';
      case StandRequestStatus.completed:
        return 'TERMINÉ';
    }
  }

  Color _getPaymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.purple;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getPaymentLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.processing:
        return 'Traitement';
      case PaymentStatus.paid:
        return 'Payé';
      case PaymentStatus.failed:
        return 'Échec';
      case PaymentStatus.refunded:
        return 'Remboursé';
      case PaymentStatus.cancelled:
        return 'Annulé';
    }
  }

  // Actions
  void _viewNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications conventions - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Historique demandes - À implémenter'),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createNewStandRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nouvelle demande de stand pour convention ${widget.conventionId}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewLocationDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Détails localisation - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _manageLocationChange() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gestion changement localisation - À implémenter'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editRequest(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Édition demande ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendRequest(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Envoi demande ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancelRequest(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Annulation demande ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewRequestDetails(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Détails demande ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewNegotiation(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Négociation ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _respondToNegotiation(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Réponse négociation ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _payStand(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paiement stand ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadInvoice(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Téléchargement facture ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rateConvention(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notation convention ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.amber,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewStandDetails(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Détails stand ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _manageStand(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gestion stand ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _activateLocationChange(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Activation localisation ${request['conventionName']} - À implémenter'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewConventionDetails(Map<String, dynamic> convention) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Détails convention ${convention['name']} - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _requestStand(Map<String, dynamic> convention) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande stand ${convention['name']} - À implémenter'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewStandAnalytics(Map<String, dynamic> stand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Analytics stand ${stand['conventionName']} - À implémenter'),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _manageActiveStand(Map<String, dynamic> stand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gestion stand actif ${stand['conventionName']} - À implémenter'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // DONNÉES DÉMO/TEST UNIQUEMENT - En production, ces données viendront de Firebase
  List<Map<String, dynamic>> _generateStandRequests() {
    // ✅ Filtre pour ne montrer que les demandes liées à cette convention
    return [
      {
        'id': '1',
        'conventionId': widget.conventionId,  // ✅ Lien avec la convention
        'conventionName': _convention?['name'] ?? 'Convention Tattoo Paris 2025',
        'city': 'Paris',
        'date': '15-17 Mars 2025',
        'status': StandRequestStatus.negotiating.index,
        'paymentStatus': PaymentStatus.pending.index,
        'standType': 'Premium',
        'standSize': '3x3m',
        'standNumber': 'A12',
        'price': 850,
        'message': 'Spécialisé en réalisme, 8 ans d\'expérience',
        'address': 'Parc des Expositions, Paris',
        'startDate': '15 Mars 2025',
        'endDate': '17 Mars 2025',
      },
      {
        'id': '2',
        'conventionId': 'other-convention',  // ✅ Autre convention (ne sera pas affiché si filtré)
        'conventionName': 'Lyon Ink Festival',
        'city': 'Lyon',
        'date': '22-24 Mars 2025',
        'status': StandRequestStatus.accepted.index,
        'paymentStatus': PaymentStatus.pending.index,
        'standType': 'Standard',
        'standSize': '2x2m',
        'standNumber': 'B07',
        'price': 450,
        'message': null,
        'address': 'Centre de Congrès, Lyon',
        'startDate': '22 Mars 2025',
        'endDate': '24 Mars 2025',
      },
      {
        'id': '3',
        'conventionId': widget.conventionId,  // ✅ Lien avec la convention
        'conventionName': _convention?['name'] ?? 'Convention actuelle',
        'city': 'Paris',
        'date': '15-17 Mars 2025',
        'status': StandRequestStatus.active.index,
        'paymentStatus': PaymentStatus.paid.index,
        'standType': 'Premium',
        'standSize': '3x4m',
        'standNumber': 'C03',
        'price': 750,
        'message': 'Portfolio japonais traditionnel',
        'address': _convention?['location'] ?? 'Parc des Expositions',
        'startDate': '15 Mars 2025',
        'endDate': '17 Mars 2025',
      },
    ];
  }

  List<Map<String, dynamic>> _generateAvailableConventions() {
    return [
      {
        'id': '1',
        'name': 'Bordeaux Ink Meeting',
        'city': 'Bordeaux',
        'date': '12-14 Avril 2025',
        'standsAvailable': 15,
        'expectedAttendees': 2500,
        'minStandPrice': 400,
        'duration': 3,
        'description': 'Convention intimiste dans le Sud-Ouest',
      },
      {
        'id': '2',
        'name': 'Lille Tattoo Expo',
        'city': 'Lille',
        'date': '26-28 Avril 2025',
        'standsAvailable': 8,
        'expectedAttendees': 3000,
        'minStandPrice': 550,
        'duration': 3,
        'description': 'Grande convention du Nord',
      },
      {
        'id': '3',
        'name': 'Strasbourg Convention',
        'city': 'Strasbourg',
        'date': '10-12 Mai 2025',
        'standsAvailable': 0,
        'expectedAttendees': 1800,
        'minStandPrice': 380,
        'duration': 3,
        'description': 'Convention Est de la France',
      },
    ];
  }

  Map<String, dynamic>? _generateActiveLocationChange() {
    // ✅ Retourne uniquement si c'est lié à cette convention
    return {
      'conventionId': widget.conventionId,
      'conventionName': _convention?['name'] ?? 'Convention actuelle',
      'address': _convention?['location'] ?? 'Parc des Expositions',
      'standNumber': 'C03',
      'startDate': '15 Mars 2025',
      'endDate': '17 Mars 2025',
      'isActive': true,
    };
  }
}