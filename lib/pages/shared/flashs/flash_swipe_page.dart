import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../theme/kipik_theme.dart';
import '../../../models/flash/flash.dart';
import '../../../services/flash/flash_service.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'flash_detail_page.dart';

class FlashSwipePage extends StatefulWidget {
  const FlashSwipePage({Key? key}) : super(key: key);

  @override
  State<FlashSwipePage> createState() => _FlashSwipePageState();
}

class _FlashSwipePageState extends State<FlashSwipePage> 
    with TickerProviderStateMixin {
  
  final FlashService _flashService = FlashService.instance;
  late AnimationController _swipeController;
  late AnimationController _scaleController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _scaleAnimation;
  
  List<Flash> _flashs = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  double _dragProgress = 0.0;
  
  // Filtres
  String? _selectedStyle;
  double? _maxPrice;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFlashs();
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(2, 0),
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadFlashs() async {
    setState(() => _isLoading = true);
    
    try {
      final flashs = await _flashService.getAvailableFlashs(limit: 50);
      
      setState(() {
        _flashs = flashs.where((f) => f.status == FlashStatus.published).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement des flashs');
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStart = details.globalPosition;
    });
    _scaleController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final diff = details.globalPosition - _dragStart;
      _dragProgress = diff.dx / MediaQuery.of(context).size.width;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _scaleController.reverse();
    
    final velocity = details.velocity.pixelsPerSecond.dx;
    final isSwipeRight = velocity > 300 || _dragProgress > 0.4;
    final isSwipeLeft = velocity < -300 || _dragProgress < -0.4;
    
    if (isSwipeRight) {
      _likeFlash();
    } else if (isSwipeLeft) {
      _skipFlash();
    } else {
      setState(() {
        _isDragging = false;
        _dragProgress = 0.0;
      });
    }
  }

  void _likeFlash() {
    if (_currentIndex >= _flashs.length) return;
    
    HapticFeedback.mediumImpact();
    
    // Ajouter aux favoris
    final currentFlash = _flashs[_currentIndex];
    _flashService.toggleFlashFavorite(
      userId: SecureAuthService.instance.currentUser?['uid'] ?? '',
      flashId: currentFlash.id,
    );
    
    _swipeController.forward().then((_) {
      _nextFlash();
      _swipeController.reset();
    });
  }

  void _skipFlash() {
    HapticFeedback.lightImpact();
    _swipeController.reverse().then((_) {
      _nextFlash();
      _swipeController.reset();
    });
  }

  void _nextFlash() {
    setState(() {
      _currentIndex++;
      _isDragging = false;
      _dragProgress = 0.0;
    });
    
    if (_currentIndex >= _flashs.length) {
      _showEndOfFlashsDialog();
    }
  }

  void _showEndOfFlashsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Plus de flashs !',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Vous avez vu tous les flashs disponibles dans votre zone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
            style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
            child: const Text('Recommencer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Flash Swipe',
        subtitle: _flashs.isNotEmpty ? '${_currentIndex + 1}/${_flashs.length}' : '',
        showBackButton: true,
        useProStyle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: KipikTheme.rouge),
          const SizedBox(height: 24),
          const Text(
            'Chargement des flashs...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_flashs.isEmpty) {
      return _buildEmptyState();
    }
    
    if (_currentIndex >= _flashs.length) {
      return _buildEmptyState();
    }
    
    return Stack(
      children: [
        // Cards stack
        ...List.generate(
          math.min(3, _flashs.length - _currentIndex),
          (index) {
            final flashIndex = _currentIndex + index;
            if (flashIndex >= _flashs.length) return const SizedBox.shrink();
            
            final flash = _flashs[flashIndex];
            final isTop = index == 0;
            
            return Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  top: index * 10.0,
                  left: 16 + index * 8.0,
                  right: 16 + index * 8.0,
                  bottom: 100,
                ),
                child: Transform.scale(
                  scale: 1 - (index * 0.05),
                  child: isTop
                      ? GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Transform.translate(
                                  offset: Offset(_dragProgress * 300, 0),
                                  child: Transform.rotate(
                                    angle: _dragProgress * 0.2,
                                    child: _buildFlashCard(flash, isTop: true),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : _buildFlashCard(flash, isTop: false),
                ),
              ),
            );
          },
        ).reversed.toList(),
        
        // Action buttons
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: _buildActionButtons(),
        ),
        
        // Swipe indicators
        if (_isDragging)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: _buildSwipeIndicators(),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_off, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 24),
          const Text(
            'Aucun flash disponible',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Modifiez vos filtres ou revenez plus tard',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashCard(Flash flash, {required bool isTop}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              flash.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
              ),
            ),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            
            // Flash info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and price
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            flash.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: KipikTheme.rouge,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${flash.effectivePrice.toInt()}€',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Artist and studio
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[400], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          flash.tattooArtistName,
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.store, color: Colors.grey[400], size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            flash.studioName,
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag(flash.style),
                        _buildTag(flash.size),
                        if (flash.isMinuteFlash) _buildTag('Flash Minute', isHighlight: true),
                      ],
                    ),
                    
                    // View details button
                    if (isTop) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => _viewFlashDetails(flash),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Voir les détails',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.orange : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSwipeIndicators() {
    final opacity = _dragProgress.abs().clamp(0.0, 1.0);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Skip indicator
        Opacity(
          opacity: _dragProgress < 0 ? opacity : 0,
          child: Container(
            margin: const EdgeInsets.only(left: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 32),
          ),
        ),
        
        // Like indicator
        Opacity(
          opacity: _dragProgress > 0 ? opacity : 0,
          child: Container(
            margin: const EdgeInsets.only(right: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 32),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Skip button
        FloatingActionButton(
          onPressed: _currentIndex < _flashs.length ? _skipFlash : null,
          backgroundColor: Colors.white,
          heroTag: 'skip',
          child: Icon(Icons.close, color: Colors.red, size: 32),
        ),
        
        // Super like button
        FloatingActionButton(
          onPressed: _currentIndex < _flashs.length ? _superLikeFlash : null,
          backgroundColor: Colors.blue,
          heroTag: 'superlike',
          child: const Icon(Icons.star, color: Colors.white, size: 32),
        ),
        
        // Like button
        FloatingActionButton(
          onPressed: _currentIndex < _flashs.length ? _likeFlash : null,
          backgroundColor: Colors.green,
          heroTag: 'like',
          child: const Icon(Icons.favorite, color: Colors.white, size: 32),
        ),
      ],
    );
  }

  void _superLikeFlash() {
    if (_currentIndex >= _flashs.length) return;
    
    HapticFeedback.heavyImpact();
    _showSuccessSnackBar('Super Like ! Le tatoueur sera notifié');
    _likeFlash();
  }

  void _viewFlashDetails(Flash flash) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashDetailPage(flash: flash),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
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
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Filtres',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection('Style', _buildStyleFilter()),
                    const SizedBox(height: 24),
                    _buildFilterSection('Prix maximum', _buildPriceFilter()),
                    const SizedBox(height: 24),
                    _buildFilterSection('Localisation', _buildLocationFilter()),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadFlashs();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KipikTheme.rouge,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Appliquer', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildStyleFilter() {
    final styles = ['Tous', 'Réalisme', 'Japonais', 'Géométrique', 'Minimaliste', 'Traditionnel'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: styles.map((style) {
        final isSelected = _selectedStyle == style || (style == 'Tous' && _selectedStyle == null);
        
        return ChoiceChip(
          label: Text(style),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedStyle = style == 'Tous' ? null : style;
            });
          },
          selectedColor: KipikTheme.rouge,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      children: [
        Text(
          _maxPrice == null ? 'Tous les prix' : 'Max: ${_maxPrice!.toInt()}€',
          style: const TextStyle(color: Colors.white),
        ),
        Slider(
          value: _maxPrice ?? 500,
          min: 50,
          max: 500,
          divisions: 18,
          activeColor: KipikTheme.rouge,
          inactiveColor: Colors.grey[700],
          onChanged: (value) {
            setState(() {
              _maxPrice = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Ville ou code postal',
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
      ),
      onChanged: (value) {
        _selectedCity = value;
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedStyle = null;
      _maxPrice = null;
      _selectedCity = null;
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}