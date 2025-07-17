// lib/widgets/shared/swipe_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../theme/kipik_theme.dart';
import '../../models/flash/flash.dart';
import 'flash_card.dart';

/// Widget de carte swipeable style Tinder pour la découverte de flashs
/// Supporte les gestes de glissement avec animations et overlays
class SwipeCard extends StatefulWidget {
  final Flash flash;
  final Function(Flash flash, SwipeDirection direction)? onSwipe;
  final VoidCallback? onTap;
  final bool isInteractive;
  final double? compatibilityScore;
  final bool showCompatibilityOverlay;

  const SwipeCard({
    Key? key,
    required this.flash,
    this.onSwipe,
    this.onTap,
    this.isInteractive = true,
    this.compatibilityScore,
    this.showCompatibilityOverlay = true,
  }) : super(key: key);

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _overlayController;
  late AnimationController _entryController;
  late Animation<double> _animation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _overlayAnimation;
  late Animation<double> _entryAnimation;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  SwipeDirection? _currentDirection;
  double _dragDistance = 0.0;

  // Configuration du swipe
  static const double _swipeThreshold = 100.0;
  static const double _rotationFactor = 0.3;
  static const double _maxRotation = 0.4;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _playEntryAnimation();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _overlayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeInOut),
    );

    _entryAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );
  }

  void _playEntryAnimation() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _entryController.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animation, _overlayAnimation, _entryAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _entryAnimation.value * (0.95 + (_dragDistance / 1000) * 0.05),
          child: Transform.translate(
            offset: _dragOffset * _animation.value,
            child: Transform.rotate(
              angle: _getRotationAngle(),
              child: GestureDetector(
                onPanStart: widget.isInteractive ? _onPanStart : null,
                onPanUpdate: widget.isInteractive ? _onPanUpdate : null,
                onPanEnd: widget.isInteractive ? _onPanEnd : null,
                onTap: widget.onTap,
                child: Stack(
                  children: [
                    // Carte principale
                    _buildMainCard(),
                    
                    // Overlays de direction
                    if (_isDragging && widget.showCompatibilityOverlay)
                      _buildSwipeOverlays(),
                    
                    // Indicateur de compatibilité IA
                    if (widget.compatibilityScore != null && 
                        widget.showCompatibilityOverlay && 
                        !_isDragging)
                      _buildCompatibilityIndicator(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: _isDragging ? 5 : 0,
          ),
        ],
      ),
      child: FlashCard(
        flash: widget.flash,
        size: FlashCardSize.fullWidth,
        style: FlashCardStyle.elevated,
        showActions: false,
        isInteractive: false,
        compatibilityScore: widget.compatibilityScore,
      ),
    );
  }

  Widget _buildSwipeOverlays() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _getOverlayColor().withOpacity(_overlayAnimation.value * 0.8),
        ),
        child: Center(
          child: _buildSwipeIcon(),
        ),
      ),
    );
  }

  Widget _buildSwipeIcon() {
    final icon = _getSwipeIcon();
    final color = _getSwipeIconColor();
    
    return Transform.scale(
      scale: 1.0 + (_overlayAnimation.value * 0.5),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
        ),
        child: Icon(
          icon,
          color: color,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildCompatibilityIndicator() {
    if (widget.compatibilityScore == null || widget.compatibilityScore! < 0.5) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              KipikTheme.rouge,
              Colors.orange,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: KipikTheme.rouge.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${(widget.compatibilityScore! * 100).toInt()}% compatible',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gestionnaires de gestes
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _controller.stop();
    _overlayController.forward();
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    setState(() {
      _dragOffset += details.delta;
      _dragDistance = _dragOffset.distance;
      
      // Déterminer la direction
      if (_dragOffset.dx.abs() > _dragOffset.dy.abs()) {
        _currentDirection = _dragOffset.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
      } else {
        _currentDirection = _dragOffset.dy > 0 ? SwipeDirection.down : SwipeDirection.up;
      }
    });

    // Feedback haptique selon la distance
    if (_dragDistance > _swipeThreshold && _dragDistance < _swipeThreshold + 20) {
      HapticFeedback.mediumImpact();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final isSwipeFast = velocity.distance > 1000;
    final isSwipeFar = _dragDistance > _swipeThreshold;

    if (isSwipeFast || isSwipeFar) {
      _performSwipe(_currentDirection ?? SwipeDirection.right);
    } else {
      _resetCard();
    }
  }

  void _performSwipe(SwipeDirection direction) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    late Offset targetOffset;
    
    switch (direction) {
      case SwipeDirection.left:
        targetOffset = Offset(-screenWidth * 2, _dragOffset.dy);
        break;
      case SwipeDirection.right:
        targetOffset = Offset(screenWidth * 2, _dragOffset.dy);
        break;
      case SwipeDirection.up:
        targetOffset = Offset(_dragOffset.dx, -screenHeight * 2);
        break;
      case SwipeDirection.down:
        targetOffset = Offset(_dragOffset.dx, screenHeight * 2);
        break;
    }

    // Animation de sortie
    _dragOffset = targetOffset;
    _controller.forward().then((_) {
      widget.onSwipe?.call(widget.flash, direction);
    });

    // Feedback haptique selon la direction
    switch (direction) {
      case SwipeDirection.right:
        HapticFeedback.heavyImpact(); // Like
        break;
      case SwipeDirection.left:
        HapticFeedback.lightImpact(); // Pass
        break;
      case SwipeDirection.up:
        HapticFeedback.mediumImpact(); // Super like
        break;
      case SwipeDirection.down:
        HapticFeedback.selectionClick(); // Détails
        break;
    }
  }

  void _resetCard() {
    setState(() {
      _isDragging = false;
      _currentDirection = null;
    });
    
    // Animation de retour
    _controller.reverse();
    _overlayController.reverse();
    
    setState(() {
      _dragOffset = Offset.zero;
      _dragDistance = 0.0;
    });
  }

  // Animations helpers
  double _getRotationAngle() {
    if (!_isDragging) return 0.0;
    
    final rotation = (_dragOffset.dx / MediaQuery.of(context).size.width) * _rotationFactor;
    return math.max(-_maxRotation, math.min(_maxRotation, rotation));
  }

  Color _getOverlayColor() {
    if (_currentDirection == null) return Colors.transparent;
    
    switch (_currentDirection!) {
      case SwipeDirection.right:
        return Colors.green;
      case SwipeDirection.left:
        return Colors.red;
      case SwipeDirection.up:
        return KipikTheme.rouge;
      case SwipeDirection.down:
        return Colors.blue;
    }
  }

  IconData _getSwipeIcon() {
    if (_currentDirection == null) return Icons.help;
    
    switch (_currentDirection!) {
      case SwipeDirection.right:
        return Icons.favorite;
      case SwipeDirection.left:
        return Icons.close;
      case SwipeDirection.up:
        return Icons.star;
      case SwipeDirection.down:
        return Icons.info;
    }
  }

  Color _getSwipeIconColor() {
    if (_currentDirection == null) return Colors.white;
    
    switch (_currentDirection!) {
      case SwipeDirection.right:
        return Colors.green;
      case SwipeDirection.left:
        return Colors.red;
      case SwipeDirection.up:
        return KipikTheme.rouge;
      case SwipeDirection.down:
        return Colors.blue;
    }
  }

  /// Méthodes publiques pour contrôle programmatique
  void swipeLeft() {
    _performSwipe(SwipeDirection.left);
  }

  void swipeRight() {
    _performSwipe(SwipeDirection.right);
  }

  void swipeUp() {
    _performSwipe(SwipeDirection.up);
  }

  void swipeDown() {
    _performSwipe(SwipeDirection.down);
  }
}

/// Stack de cartes swipeables avec gestion automatique
class SwipeCardStack extends StatefulWidget {
  final List<Flash> flashs;
  final Function(Flash flash, SwipeDirection direction)? onSwipe;
  final VoidCallback? onTap;
  final VoidCallback? onStackEmpty;
  final bool showCompatibilityScores;
  final Map<String, double>? compatibilityScores;
  final int visibleCards;

  const SwipeCardStack({
    Key? key,
    required this.flashs,
    this.onSwipe,
    this.onTap,
    this.onStackEmpty,
    this.showCompatibilityScores = true,
    this.compatibilityScores,
    this.visibleCards = 3,
  }) : super(key: key);

  @override
  State<SwipeCardStack> createState() => _SwipeCardStackState();
}

class _SwipeCardStackState extends State<SwipeCardStack> with TickerProviderStateMixin {
  late List<Flash> _currentFlashs;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentFlashs = List.from(widget.flashs);
  }

  @override
  void didUpdateWidget(SwipeCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashs != oldWidget.flashs) {
      setState(() {
        _currentFlashs = List.from(widget.flashs);
        _currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentFlashs.isEmpty || _currentIndex >= _currentFlashs.length) {
      return _buildEmptyState();
    }

    return Stack(
      children: _buildCardStack(),
    );
  }

  List<Widget> _buildCardStack() {
    final widgets = <Widget>[];
    final cardsToShow = math.min(widget.visibleCards, _currentFlashs.length - _currentIndex);

    for (int i = cardsToShow - 1; i >= 0; i--) {
      final cardIndex = _currentIndex + i;
      if (cardIndex >= _currentFlashs.length) continue;

      final flash = _currentFlashs[cardIndex];
      final isTopCard = i == 0;
      final scale = 1.0 - (i * 0.05);
      final offset = i * 8.0;

      widgets.add(
        Positioned.fill(
          top: offset,
          child: Transform.scale(
            scale: scale,
            child: SwipeCard(
              key: ValueKey('${flash.id}_$cardIndex'),
              flash: flash,
              onSwipe: isTopCard ? _handleSwipe : null,
              onTap: isTopCard ? widget.onTap : null,
              isInteractive: isTopCard,
              compatibilityScore: widget.compatibilityScores?[flash.id],
              showCompatibilityOverlay: widget.showCompatibilityScores,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  KipikTheme.rouge.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 60,
              color: KipikTheme.rouge.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Plus de flashs à découvrir !',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nous préparons de nouvelles recommandations pour vous...',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleSwipe(Flash flash, SwipeDirection direction) {
    setState(() {
      _currentIndex++;
    });

    widget.onSwipe?.call(flash, direction);

    // Vérifier si la pile est vide
    if (_currentIndex >= _currentFlashs.length) {
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onStackEmpty?.call();
      });
    }
  }

  // Méthodes publiques pour contrôle externe
  void addFlashs(List<Flash> newFlashs) {
    setState(() {
      _currentFlashs.addAll(newFlashs);
    });
  }

  void reset() {
    setState(() {
      _currentIndex = 0;
    });
  }

  int get remainingCards => math.max(0, _currentFlashs.length - _currentIndex);
  Flash? get currentFlash => _currentIndex < _currentFlashs.length ? _currentFlashs[_currentIndex] : null;
}

/// Directions de swipe possibles
enum SwipeDirection {
  left,   // Pass / Skip
  right,  // Like / Intéressé
  up,     // Super like / Favori
  down,   // Voir détails / Info
}