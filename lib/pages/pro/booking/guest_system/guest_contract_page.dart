// lib/pages/pro/booking/guest_system/guest_contract_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/kipik_theme.dart';
import '../../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../../widgets/common/drawers/custom_drawer_kipik.dart';
import '../../../../widgets/common/buttons/tattoo_assistant_button.dart';

enum ContractStatus { pending, negotiating, accepted, declined, active, completed }
enum ContractFilter { all, pending, active, completed }

class GuestContractPage extends StatefulWidget {
  const GuestContractPage({Key? key}) : super(key: key);

  @override
  State<GuestContractPage> createState() => _GuestContractPageState();
}

class _GuestContractPageState extends State<GuestContractPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _cardController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;

  ContractFilter _selectedFilter = ContractFilter.all;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _contracts = [];
  List<Map<String, dynamic>> _filteredContracts = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadContracts();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardController.dispose();
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
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardController.forward();
    });
  }

  void _loadContracts() {
    setState(() => _isLoading = true);
    
    // Simulation de chargement des contrats
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _contracts = _generateSampleContracts();
        _filteredContracts = _contracts;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawerKipik(),
      appBar: CustomAppBarKipik(
        title: 'Contrats Guest',
        subtitle: 'Gérer vos collaborations',
        showBackButton: true,
        useProStyle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
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
          _buildFilterTabs(),
          const SizedBox(height: 16),
          _buildStatsHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildContractsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
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
        children: ContractFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                  _filterContracts();
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? LinearGradient(
                    colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
                  ) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getFilterIcon(filter),
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFilterLabel(filter),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
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
        }).toList(),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalContracts = _contracts.length;
    final activeContracts = _contracts.where((c) => c['status'] == ContractStatus.active).length;
    final pendingContracts = _contracts.where((c) => c['status'] == ContractStatus.pending).length;

    return FadeTransition(
      opacity: _cardAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.8),
              Colors.blue.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', '$totalContracts', Icons.description),
            _buildStatItem('En cours', '$activeContracts', Icons.play_circle),
            _buildStatItem('En attente', '$pendingContracts', Icons.pending),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
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
            'Chargement des contrats...',
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

  Widget _buildContractsList() {
    if (_filteredContracts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _filteredContracts.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _cardAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _cardAnimation.value,
              child: _buildContractCard(_filteredContracts[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun contrat trouvé',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos contrats Guest apparaîtront ici',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final status = contract['status'] as ContractStatus;
    final statusColor = _getStatusColor(status);
    final isOutgoing = contract['type'] == 'outgoing';

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
      child: Column(
        children: [
          // En-tête avec statut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withOpacity(0.8), statusColor.withOpacity(0.6)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: contract['partnerAvatar'] != null
                      ? AssetImage(contract['partnerAvatar'])
                      : null,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: contract['partnerAvatar'] == null
                      ? Icon(
                          isOutgoing ? Icons.store : Icons.person,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contract['partnerName'],
                              style: const TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOutgoing ? 'GUEST' : 'HÔTE',
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
                      const SizedBox(height: 4),
                      Text(
                        contract['location'],
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusLabel(status),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
          
          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Période
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: KipikTheme.rouge, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Période: ${contract['startDate']} - ${contract['endDate']}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Durée et styles
                Row(
                  children: [
                    Icon(Icons.schedule, color: KipikTheme.rouge, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${contract['duration']} • ${contract['styles'].join(', ')}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Conditions financières
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Commission',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${contract['commission']}%',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hébergement',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Icon(
                            contract['accommodation'] ? Icons.check : Icons.close,
                            color: contract['accommodation'] ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ],
                      ),
                      if (status == ContractStatus.active) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Revenus',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${contract['currentRevenue'] ?? 0}€',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Actions selon le statut
                _buildContractActions(contract),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractActions(Map<String, dynamic> contract) {
    final status = contract['status'] as ContractStatus;
    
    switch (status) {
      case ContractStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _declineContract(contract),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Refuser'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptContract(contract),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Accepter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case ContractStatus.negotiating:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewNegotiation(contract),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Négocier'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _finalizeContract(contract),
                icon: const Icon(Icons.handshake, size: 16),
                label: const Text('Finaliser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case ContractStatus.accepted:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _addToCalendar(contract),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('Ajouter à l\'agenda'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        );
        
      case ContractStatus.active:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewProgress(contract),
                icon: const Icon(Icons.timeline, size: 16),
                label: const Text('Suivi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _manageContract(contract),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('Gérer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KipikTheme.rouge,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case ContractStatus.completed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewSummary(contract),
                icon: const Icon(Icons.summarize, size: 16),
                label: const Text('Résumé'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _leaveReview(contract),
                icon: const Icon(Icons.star, size: 16),
                label: const Text('Noter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
        
      case ContractStatus.declined:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _removeContract(contract),
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Supprimer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        );
    }
  }

  // Actions sur les contrats
  void _acceptContract(Map<String, dynamic> contract) async {
    final confirmed = await _showConfirmDialog(
      'Accepter le contrat',
      'Êtes-vous sûr de vouloir accepter cette collaboration ?',
      confirmText: 'Accepter',
      confirmColor: Colors.green,
    );
    
    if (confirmed) {
      setState(() {
        contract['status'] = ContractStatus.accepted;
      });
      
      _showSuccessSnackBar('Contrat accepté ! Il sera ajouté à votre agenda.');
    }
  }

  void _declineContract(Map<String, dynamic> contract) async {
    final confirmed = await _showConfirmDialog(
      'Refuser le contrat',
      'Êtes-vous sûr de vouloir refuser cette collaboration ?',
      confirmText: 'Refuser',
      confirmColor: Colors.red,
    );
    
    if (confirmed) {
      setState(() {
        contract['status'] = ContractStatus.declined;
      });
      
      _showInfoSnackBar('Contrat refusé. Le partenaire sera notifié.');
    }
  }

  void _addToCalendar(Map<String, dynamic> contract) {
    // Logique d'ajout automatique à l'agenda
    setState(() {
      contract['status'] = ContractStatus.active;
      contract['addedToCalendar'] = true;
    });
    
    _showSuccessSnackBar('Guest ajouté à votre agenda avec succès !');
  }

  void _viewNegotiation(Map<String, dynamic> contract) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture de la négociation - À implémenter'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _finalizeContract(Map<String, dynamic> contract) {
    setState(() {
      contract['status'] = ContractStatus.accepted;
    });
    
    _showSuccessSnackBar('Contrat finalisé ! Prêt pour l\'agenda.');
  }

  void _viewProgress(Map<String, dynamic> contract) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture du suivi - À implémenter'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _manageContract(Map<String, dynamic> contract) {
    _showContractDetailsBottomSheet(contract);
  }

  void _viewSummary(Map<String, dynamic> contract) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture du résumé - À implémenter'),
        backgroundColor: Colors.grey,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _leaveReview(Map<String, dynamic> contract) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Système de notation - À implémenter'),
        backgroundColor: Colors.amber,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeContract(Map<String, dynamic> contract) async {
    final confirmed = await _showConfirmDialog(
      'Supprimer le contrat',
      'Cette action est irréversible. Continuer ?',
      confirmText: 'Supprimer',
      confirmColor: Colors.red,
    );
    
    if (confirmed) {
      setState(() {
        _contracts.remove(contract);
        _filterContracts();
      });
      
      _showInfoSnackBar('Contrat supprimé.');
    }
  }

  void _showContractDetailsBottomSheet(Map<String, dynamic> contract) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
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
                  
                  Text(
                    'Gestion du contrat',
                    style: const TextStyle(
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
                        children: [
                          _buildDetailTile('Partenaire', contract['partnerName']),
                          _buildDetailTile('Localisation', contract['location']),
                          _buildDetailTile('Période', '${contract['startDate']} - ${contract['endDate']}'),
                          _buildDetailTile('Commission', '${contract['commission']}%'),
                          _buildDetailTile('Hébergement', contract['accommodation'] ? 'Inclus' : 'Non inclus'),
                          if (contract['currentRevenue'] != null)
                            _buildDetailTile('Revenus actuels', '${contract['currentRevenue']}€'),
                          
                          const SizedBox(height: 20),
                          
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

  Widget _buildDetailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Filtrer les contrats',
          style: TextStyle(fontFamily: 'PermanentMarker'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ContractFilter.values.map((filter) {
            return RadioListTile<ContractFilter>(
              title: Text(_getFilterLabel(filter)),
              value: filter,
              groupValue: _selectedFilter,
              activeColor: KipikTheme.rouge,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
                _filterContracts();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _filterContracts() {
    setState(() {
      switch (_selectedFilter) {
        case ContractFilter.all:
          _filteredContracts = _contracts;
          break;
        case ContractFilter.pending:
          _filteredContracts = _contracts.where((c) => 
              c['status'] == ContractStatus.pending || 
              c['status'] == ContractStatus.negotiating).toList();
          break;
        case ContractFilter.active:
          _filteredContracts = _contracts.where((c) => 
              c['status'] == ContractStatus.active || 
              c['status'] == ContractStatus.accepted).toList();
          break;
        case ContractFilter.completed:
          _filteredContracts = _contracts.where((c) => 
              c['status'] == ContractStatus.completed || 
              c['status'] == ContractStatus.declined).toList();
          break;
      }
    });
  }

  Future<bool> _showConfirmDialog(String title, String content, {
    String confirmText = 'Confirmer',
    Color confirmColor = Colors.blue,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'PermanentMarker'),
        ),
        content: Text(
          content,
          style: const TextStyle(fontFamily: 'Roboto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ) ?? false;
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Helper methods
  String _getFilterLabel(ContractFilter filter) {
    switch (filter) {
      case ContractFilter.all:
        return 'Tous';
      case ContractFilter.pending:
        return 'En attente';
      case ContractFilter.active:
        return 'Actifs';
      case ContractFilter.completed:
        return 'Terminés';
    }
  }

  IconData _getFilterIcon(ContractFilter filter) {
    switch (filter) {
      case ContractFilter.all:
        return Icons.assignment;
      case ContractFilter.pending:
        return Icons.pending;
      case ContractFilter.active:
        return Icons.play_circle;
      case ContractFilter.completed:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.pending:
        return Colors.orange;
      case ContractStatus.negotiating:
        return Colors.blue;
      case ContractStatus.accepted:
        return Colors.green;
      case ContractStatus.declined:
        return Colors.red;
      case ContractStatus.active:
        return Colors.purple;
      case ContractStatus.completed:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ContractStatus status) {
    switch (status) {
      case ContractStatus.pending:
        return Icons.pending;
      case ContractStatus.negotiating:
        return Icons.chat_bubble;
      case ContractStatus.accepted:
        return Icons.check_circle;
      case ContractStatus.declined:
        return Icons.cancel;
      case ContractStatus.active:
        return Icons.play_circle;
      case ContractStatus.completed:
        return Icons.check_circle_outline;
    }
  }

  String _getStatusLabel(ContractStatus status) {
    switch (status) {
      case ContractStatus.pending:
        return 'En attente';
      case ContractStatus.negotiating:
        return 'Négociation';
      case ContractStatus.accepted:
        return 'Accepté';
      case ContractStatus.declined:
        return 'Refusé';
      case ContractStatus.active:
        return 'En cours';
      case ContractStatus.completed:
        return 'Terminé';
    }
  }

  List<Map<String, dynamic>> _generateSampleContracts() {
    return [
      {
        'id': '1',
        'type': 'outgoing', // Je vais en guest
        'partnerName': 'Ink Studio Paris',
        'partnerAvatar': 'assets/shops/shop1.png',
        'location': 'Paris 9ème, France',
        'startDate': '15 Juin 2025',
        'endDate': '25 Juin 2025',
        'duration': '10 jours',
        'styles': ['Réalisme', 'Portrait'],
        'commission': 20,
        'accommodation': true,
        'status': ContractStatus.pending,
      },
      {
        'id': '2',
        'type': 'incoming', // Je reçois un guest
        'partnerName': 'Emma Chen',
        'partnerAvatar': 'assets/avatars/guest2.png',
        'location': 'Mon studio',
        'startDate': '1 Juillet 2025',
        'endDate': '15 Juillet 2025',
        'duration': '2 semaines',
        'styles': ['Japonais', 'Traditionnel'],
        'commission': 25,
        'accommodation': false,
        'status': ContractStatus.active,
        'currentRevenue': 1250,
      },
      {
        'id': '3',
        'type': 'outgoing',
        'partnerName': 'Black Art Lyon',
        'partnerAvatar': 'assets/shops/shop2.png',
        'location': 'Lyon, France',
        'startDate': '20 Août 2025',
        'endDate': '30 Août 2025',
        'duration': '10 jours',
        'styles': ['Black & Grey'],
        'commission': 30,
        'accommodation': false,
        'status': ContractStatus.negotiating,
      },
      {
        'id': '4',
        'type': 'incoming',
        'partnerName': 'Lucas Dubois',
        'partnerAvatar': 'assets/avatars/guest3.png',
        'location': 'Mon studio',
        'startDate': '10 Mai 2025',
        'endDate': '20 Mai 2025',
        'duration': '10 jours',
        'styles': ['Géométrique', 'Dotwork'],
        'commission': 20,
        'accommodation': true,
        'status': ContractStatus.completed,
        'totalRevenue': 2100,
      },
    ];
  }
}