// lib/pages/pro/flashs/flash_minute_create_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';

class FlashMinuteCreatePage extends StatefulWidget {
  const FlashMinuteCreatePage({Key? key}) : super(key: key);

  @override
  State<FlashMinuteCreatePage> createState() => _FlashMinuteCreatePageState();
}

class _FlashMinuteCreatePageState extends State<FlashMinuteCreatePage> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // État de la page
  bool _isLoading = false;
  bool _isCreating = false;
  int _step = 0; // 0: Sélection flashs, 1: Paramètres, 2: Confirmation
  
  // Données
  List<Map<String, dynamic>> _availableFlashs = [];
  List<String> _selectedFlashIds = [];
  
  // Paramètres Flash Minute
  int _selectedDiscount = 20;
  int _selectedDuration = 8; // heures
  bool _notifyClients = true;
  bool _socialMediaPost = true;
  String _customMessage = '';
  
  // Timer pour urgence
  Timer? _urgencyTimer;
  int _urgencySeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvailableFlashs();
    _startUrgencyTimer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _urgencyTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
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
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startUrgencyTimer() {
    _urgencyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _urgencySeconds++;
      });
    });
  }

  Future<void> _loadAvailableFlashs() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Simuler les flashs disponibles
      _availableFlashs = [
        {
          'id': 'flash_001',
          'title': 'Rose Minimaliste',
          'imageUrl': 'assets/images/flash_rose.jpg',
          'originalPrice': 150.0,
          'size': '8x6cm',
          'style': 'Minimaliste',
          'views': 24,
          'likes': 7,
          'isPopular': true,
        },
        {
          'id': 'flash_002',
          'title': 'Lion Géométrique',
          'imageUrl': 'assets/images/flash_lion.jpg',
          'originalPrice': 280.0,
          'size': '12x10cm',
          'style': 'Géométrique',
          'views': 45,
          'likes': 12,
          'isPopular': true,
        },
        {
          'id': 'flash_003',
          'title': 'Mandala Lotus',
          'imageUrl': 'assets/images/flash_mandala.jpg',
          'originalPrice': 200.0,
          'size': '10x10cm',
          'style': 'Mandala',
          'views': 31,
          'likes': 9,
          'isPopular': false,
        },
        {
          'id': 'flash_004',
          'title': 'Papillon Aquarelle',
          'imageUrl': 'assets/images/flash_papillon.jpg',
          'originalPrice': 180.0,
          'size': '9x7cm',
          'style': 'Aquarelle',
          'views': 18,
          'likes': 5,
          'isPopular': false,
        },
      ];
      
    } catch (e) {
      print('❌ Erreur chargement flashs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
      _slideController.forward().then((_) => _slideController.reset());
    }
  }

  void _previousStep() {
    if (_step > 0) {
      setState(() => _step--);
      _slideController.forward().then((_) => _slideController.reset());
    }
  }

  Future<void> _createFlashMinute() async {
    if (_selectedFlashIds.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner au moins un flash');
      return;
    }

    setState(() => _isCreating = true);
    HapticFeedback.mediumImpact();

    try {
      // Simuler la création
      await Future.delayed(const Duration(seconds: 3));
      
      // TODO: Implémenter la logique de création Flash Minute
      // - Mettre à jour les flashs sélectionnés
      // - Envoyer notifications si activées
      // - Poster sur réseaux sociaux si activé
      // - Programmer la fin automatique
      
      HapticFeedback.heavyImpact();
      _showSuccessDialog();
      
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la création: $e');
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Flash Minute',
        subtitle: _getSubtitle(),
        showBackButton: true,
        useProStyle: true,
        actions: [
          // Timer urgence
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatUrgencyTime(),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String _getSubtitle() {
    switch (_step) {
      case 0:
        return 'Sélectionnez vos flashs (${_selectedFlashIds.length} sélectionnés)';
      case 1:
        return 'Configurez votre offre Flash Minute';
      case 2:
        return 'Vérifiez et lancez votre Flash Minute';
      default:
        return 'Création Flash Minute';
    }
  }

  String _formatUrgencyTime() {
    final minutes = _urgencySeconds ~/ 60;
    final seconds = _urgencySeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
              color: Colors.orange,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chargement de vos flashs...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _step;
          final isCompleted = index < _step;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.orange : Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.orange : Colors.grey[700],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getStepLabel(index),
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey,
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getStepLabel(int index) {
    switch (index) {
      case 0:
        return 'Sélection';
      case 1:
        return 'Configuration';
      case 2:
        return 'Confirmation';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildFlashSelectionStep();
      case 1:
        return _buildConfigurationStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return Container();
    }
  }

  Widget _buildFlashSelectionStep() {
    return Column(
      children: [
        // Header avec actions rapides
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Sélectionnez vos flashs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_selectedFlashIds.length}/${_availableFlashs.length}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectAllFlashs,
                      icon: const Icon(Icons.select_all, size: 16),
                      label: const Text('Tout sélectionner'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectPopularFlashs,
                      icon: const Icon(Icons.trending_up, size: 16),
                      label: const Text('Les populaires'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Liste des flashs
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _availableFlashs.length,
            itemBuilder: (context, index) {
              final flash = _availableFlashs[index];
              final isSelected = _selectedFlashIds.contains(flash['id']);
              
              return _buildFlashCard(flash, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlashCard(Map<String, dynamic> flash, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected ? [
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
          onTap: () => _toggleFlashSelection(flash['id']),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[800],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      flash['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              flash['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (flash['isPopular'])
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'POPULAIRE',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${flash['style']} • ${flash['size']}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${flash['originalPrice']}€',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '→ ${_calculateDiscountedPrice(flash['originalPrice'])}€',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.visibility, size: 14, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text('${flash['views']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 8),
                              const Icon(Icons.favorite, size: 14, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text('${flash['likes']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Réduction
          _buildConfigCard(
            'Réduction',
            Icons.local_offer,
            Colors.green,
            Column(
              children: [
                Text(
                  'Réduction actuelle : $_selectedDiscount%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _selectedDiscount.toDouble(),
                  min: 10,
                  max: 50,
                  divisions: 8,
                  activeColor: Colors.green,
                  inactiveColor: Colors.grey[700],
                  onChanged: (value) {
                    setState(() {
                      _selectedDiscount = value.round();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('10%', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text('50%', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Durée
          _buildConfigCard(
            'Durée',
            Icons.timer,
            Colors.blue,
            Column(
              children: [
                Text(
                  'Durée : $_selectedDuration heures',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [8, 12, 24, 48, 72].map((hours) {
                    final isSelected = hours == _selectedDuration;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDuration = hours),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                        ),
                        child: Text(
                          '${hours}h',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Options
          _buildConfigCard(
            'Options',
            Icons.settings,
            Colors.purple,
            Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Notifier les clients',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Envoyer une notification push',
                    style: TextStyle(color: Colors.grey),
                  ),
                  value: _notifyClients,
                  onChanged: (value) => setState(() => _notifyClients = value),
                  activeColor: Colors.purple,
                ),
                SwitchListTile(
                  title: const Text(
                    'Publier sur les réseaux',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Post automatique Instagram/Facebook',
                    style: TextStyle(color: Colors.grey),
                  ),
                  value: _socialMediaPost,
                  onChanged: (value) => setState(() => _socialMediaPost = value),
                  activeColor: Colors.purple,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Message personnalisé
          _buildConfigCard(
            'Message personnalisé',
            Icons.message,
            Colors.orange,
            TextField(
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ajoutez un message personnalisé (optionnel)...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
              ),
              onChanged: (value) => _customMessage = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(String title, IconData icon, Color color, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    final selectedFlashs = _availableFlashs.where((f) => _selectedFlashIds.contains(f['id'])).toList();
    final totalOriginalPrice = selectedFlashs.fold<double>(0, (sum, f) => sum + f['originalPrice']);
    final totalDiscountedPrice = selectedFlashs.fold<double>(0, (sum, f) => sum + _calculateDiscountedPrice(f['originalPrice']));
    final totalSavings = totalOriginalPrice - totalDiscountedPrice;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.withOpacity(0.1), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.orange, size: 32),
                    const SizedBox(width: 12),
                    const Text(
                      'Flash Minute Prêt !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        'Flashs sélectionnés',
                        '${selectedFlashs.length}',
                        Icons.flash_on,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryMetric(
                        'Réduction',
                        '$_selectedDiscount%',
                        Icons.local_offer,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        'Durée',
                        '${_selectedDuration}h',
                        Icons.timer,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryMetric(
                        'Économies clients',
                        '${totalSavings.toStringAsFixed(0)}€',
                        Icons.savings,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Flashs sélectionnés
          const Text(
            'Flashs sélectionnés',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...selectedFlashs.map((flash) => _buildConfirmationFlashCard(flash)),
          
          const SizedBox(height: 24),
          
          // Timeline
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationFlashCard(Map<String, dynamic> flash) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey[800],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                flash['imageUrl'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.image, color: Colors.grey, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flash['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  flash['style'],
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${flash['originalPrice']}€',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Text(
                '${_calculateDiscountedPrice(flash['originalPrice'])}€',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final endTime = DateTime.now().add(Duration(hours: _selectedDuration));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            '🚀',
            'Lancement immédiat',
            'Flash Minute activé sur tous les flashs sélectionnés',
            true,
          ),
          if (_notifyClients)
            _buildTimelineItem(
              '📱',
              '+ 2 minutes',
              'Notification push envoyée aux clients',
              false,
            ),
          if (_socialMediaPost)
            _buildTimelineItem(
              '📢',
              '+ 5 minutes',
              'Publication automatique sur les réseaux sociaux',
              false,
            ),
          _buildTimelineItem(
            '⏰',
            'Dans ${_selectedDuration}h',
            'Fin automatique du Flash Minute (${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')})',
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String emoji, String time, String description, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isActive ? Colors.orange : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Précédent'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 16),
            Expanded(
              flex: _step == 0 ? 1 : 2,
              child: _step == 2
                  ? AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : _createFlashMinute,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isCreating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    '🚀 LANCER FLASH MINUTE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        );
                      },
                    )
                  : ElevatedButton(
                      onPressed: _canProceed() ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _step == 0 ? 'Configurer (${_selectedFlashIds.length})' : 'Confirmer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  bool _canProceed() {
    if (_step == 0) return _selectedFlashIds.isNotEmpty;
    return true;
  }

  void _toggleFlashSelection(String flashId) {
    setState(() {
      if (_selectedFlashIds.contains(flashId)) {
        _selectedFlashIds.remove(flashId);
      } else {
        _selectedFlashIds.add(flashId);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _selectAllFlashs() {
    setState(() {
      _selectedFlashIds = _availableFlashs.map((f) => f['id'] as String).toList();
    });
    HapticFeedback.mediumImpact();
  }

  void _selectPopularFlashs() {
    setState(() {
      _selectedFlashIds = _availableFlashs
          .where((f) => f['isPopular'] == true)
          .map((f) => f['id'] as String)
          .toList();
    });
    HapticFeedback.mediumImpact();
  }

  double _calculateDiscountedPrice(double originalPrice) {
    return originalPrice * (1 - _selectedDiscount / 100);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flash_on,
                color: Colors.orange,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Flash Minute Lancé !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_selectedFlashIds.length} flashs activés avec -$_selectedDiscount% pendant ${_selectedDuration}h',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Parfait !'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}