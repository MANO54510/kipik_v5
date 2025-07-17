// lib/widgets/shared/flash_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/kipik_theme.dart';
import '../../models/flash/flash.dart';
import '../../models/user_profile.dart';
import '../../services/recommendation/recommendation_engine.dart';
import '../../services/auth/secure_auth_service.dart';

import 'flash_minute_badge.dart';
/// Supporte différentes tailles et styles d'affichage
class FlashCard extends StatefulWidget {
  final Flash flash;
  final FlashCardSize size;
  final FlashCardStyle style;
  final bool showArtistInfo;
  final bool showPrice;
  final bool showLocation;
  final bool showActions;
  final bool isInteractive;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onBook;
  final VoidCallback? onShare;
  final VoidCallback? onArtistTap;
  final bool isLiked;
  final bool isSaved;
  final double? compatibilityScore;

  const FlashCard({
    Key? key,
    required this.flash,
    this.size = FlashCardSize.medium,
    this.style = FlashCardStyle.elevated,
    this.showArtistInfo = true,
    this.showPrice = true,
    this.showLocation = false,
    this.showActions = true,
    this.isInteractive = true,
    this.onTap,
    this.onLike,
    this.onSave,
    this.onBook,
    this.onShare,
    this.onArtistTap,
    this.isLiked = false,
    this.isSaved = false,
    this.compatibilityScore,
  }) : super(key: key);

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> with TickerProviderStateMixin {
  late AnimationController _likeController;
  late AnimationController _saveController;
  late AnimationController _pulseController;
  late Animation<double> _likeAnimation;
  late Animation<double> _saveAnimation;
  late Animation<double> _pulseAnimation;

  bool _isLiked = false;
  bool _isSaved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _isSaved = widget.isSaved;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _saveController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.elasticOut),
    );
    _saveAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _saveController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.flash.isMinuteFlash) {
      _pulseController.repeat(reverse: true);
    }

    if (_isLiked) _likeController.forward();
    if (_isSaved) _saveController.forward();
  }

  @override
  void dispose() {
    _likeController.dispose();
    _saveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.flash.isMinuteFlash ? _pulseAnimation.value : 1.0,
          child: _buildCard(),
        );
      },
    );
  }

  Widget _buildCard() {
    final cardWidth = _getCardWidth();
    final cardHeight = _getCardHeight();

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: _getCardMargin(),
      child: GestureDetector(
        onTap: widget.isInteractive ? _handleCardTap : null,
        child: Card(
          elevation: widget.style == FlashCardStyle.elevated ? 12 : 0,
          color: widget.style == FlashCardStyle.outlined ? Colors.transparent : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
            side: widget.style == FlashCardStyle.outlined
                ? BorderSide(color: Colors.grey.shade700, width: 1)
                : BorderSide.none,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_getBorderRadius()),
              gradient: widget.style == FlashCardStyle.gradient
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A1A1A),
                        const Color(0xFF0A0A0A),
                      ],
                    )
                  : null,
              color: widget.style != FlashCardStyle.gradient
                  ? const Color(0xFF1A1A1A)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(),
                if (widget.size != FlashCardSize.small)
                  Expanded(child: _buildContentSection()),
                if (widget.showActions && widget.size != FlashCardSize.small)
                  _buildActionSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final imageHeight = _getImageHeight();
    
    return Container(
      height: imageHeight,
      child: Stack(
        children: [
          // Image principale
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_getBorderRadius()),
              topRight: Radius.circular(_getBorderRadius()),
            ),
            child: widget.flash.imageUrl.isNotEmpty
                ? Image.network(
                    widget.flash.imageUrl,
                    width: double.infinity,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildImagePlaceholder();
                    },
                    errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),

          // Overlay gradient
          Container(
            height: imageHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_getBorderRadius()),
                topRight: Radius.circular(_getBorderRadius()),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),

          // Badges et overlays
          Positioned.fill(child: _buildImageOverlays()),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: _getImageHeight(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A2A2A),
            const Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_getBorderRadius()),
          topRight: Radius.circular(_getBorderRadius()),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            color: Colors.grey.shade600,
            size: widget.size == FlashCardSize.small ? 30 : 50,
          ),
          if (widget.size != FlashCardSize.small) ...[
            const SizedBox(height: 8),
            Text(
              'Image en cours de chargement...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageOverlays() {
    return Stack(
      children: [
        // Badge Flash Minute
        if (widget.flash.isMinuteFlash)
          Positioned(
            top: 8,
            left: 8,
            child: FlashMinuteBadge(
              deadline: widget.flash.minuteFlashDeadline!,
              size: widget.size == FlashCardSize.small 
                  ? FlashMinuteBadgeSize.small 
                  : FlashMinuteBadgeSize.medium,
            ),
          ),

        // Badge de compatibilité IA
        if (widget.compatibilityScore != null && widget.compatibilityScore! > 0.7)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [KipikTheme.rouge, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: KipikTheme.rouge.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Pour vous',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Actions rapides sur l'image
        if (widget.showActions && widget.size != FlashCardSize.small)
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQuickAction(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                  onTap: _handleLike,
                  animation: _likeAnimation,
                ),
                const SizedBox(width: 8),
                _buildQuickAction(
                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? KipikTheme.rouge : Colors.white,
                  onTap: _handleSave,
                  animation: _saveAnimation,
                ),
              ],
            ),
          ),

        // Indicateur de qualité
        if (widget.flash.qualityScore > 4.5)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    widget.flash.qualityScore.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Animation<double> animation,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.all(widget.size == FlashCardSize.large ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et prix
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.flash.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size == FlashCardSize.large ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.showPrice) ...[
                const SizedBox(width: 8),
                _buildPriceSection(),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Artiste
          if (widget.showArtistInfo)
            GestureDetector(
              onTap: widget.onArtistTap,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: KipikTheme.rouge,
                    child: Text(
                      widget.flash.tattooArtistName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.flash.tattooArtistName,
                      style: TextStyle(
                        color: KipikTheme.rouge,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Détails flash
          Row(
            children: [
              _buildDetailChip(
                icon: Icons.straighten,
                text: widget.flash.size,
              ),
              const SizedBox(width: 8),
              _buildDetailChip(
                icon: Icons.palette,
                text: widget.flash.style,
              ),
            ],
          ),

          if (widget.showLocation && widget.flash.city.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.grey.shade400,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.flash.city,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          // Engagement stats
          if (widget.size == FlashCardSize.large) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(Icons.favorite, widget.flash.likes),
                const SizedBox(width: 16),
                _buildStatItem(Icons.bookmark, widget.flash.saves),
                const SizedBox(width: 16),
                _buildStatItem(Icons.visibility, widget.flash.views),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    final hasDiscount = widget.flash.discountedPrice != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hasDiscount) ...[
          Text(
            '${widget.flash.price.toInt()}€',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          '${widget.flash.effectivePrice.toInt()}€',
          style: TextStyle(
            color: hasDiscount ? KipikTheme.rouge : Colors.white,
            fontSize: widget.size == FlashCardSize.large ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: KipikTheme.rouge,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-${widget.flash.discountPercentage?.toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.grey.shade400,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.grey.shade500,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_getBorderRadius()),
          bottomRight: Radius.circular(_getBorderRadius()),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.flash_on,
              label: 'Réserver',
              color: KipikTheme.rouge,
              onTap: _handleBook,
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.share,
            label: '',
            color: Colors.grey.shade600,
            onTap: _handleShare,
            isIconOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isIconOnly = false,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(
          horizontal: isIconOnly ? 12 : 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size(isIconOnly ? 40 : 0, 36),
      ),
      child: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : isIconOnly
              ? Icon(icon, color: Colors.white, size: 18)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 16),
                    if (label.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  // Dimensions helpers
  double _getCardWidth() {
    switch (widget.size) {
      case FlashCardSize.small:
        return 150;
      case FlashCardSize.medium:
        return 200;
      case FlashCardSize.large:
        return 300;
      case FlashCardSize.fullWidth:
        return double.infinity;
    }
  }

  double _getCardHeight() {
    switch (widget.size) {
      case FlashCardSize.small:
        return 200;
      case FlashCardSize.medium:
        return 320;
      case FlashCardSize.large:
        return 420;
      case FlashCardSize.fullWidth:
        return 350;
    }
  }

  double _getImageHeight() {
    switch (widget.size) {
      case FlashCardSize.small:
        return 120;
      case FlashCardSize.medium:
        return 160;
      case FlashCardSize.large:
        return 200;
      case FlashCardSize.fullWidth:
        return 200;
    }
  }

  EdgeInsets _getCardMargin() {
    switch (widget.size) {
      case FlashCardSize.small:
        return const EdgeInsets.all(4);
      case FlashCardSize.medium:
        return const EdgeInsets.all(8);
      case FlashCardSize.large:
        return const EdgeInsets.all(12);
      case FlashCardSize.fullWidth:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getBorderRadius() {
    return widget.size == FlashCardSize.small ? 12 : 16;
  }

  // Event handlers
  void _handleCardTap() {
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      _trackUserAction(UserActionType.view);
      widget.onTap!();
    }
  }

  void _handleLike() async {
    if (_isLoading) return;
    
    setState(() {
      _isLiked = !_isLiked;
      _isLoading = true;
    });

    try {
      if (_isLiked) {
        _likeController.forward();
        HapticFeedback.lightImpact();
      } else {
        _likeController.reverse();
      }

      _trackUserAction(_isLiked ? UserActionType.like : UserActionType.view);
      widget.onLike?.call();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSave() async {
    if (_isLoading) return;
    
    setState(() {
      _isSaved = !_isSaved;
      _isLoading = true;
    });

    try {
      if (_isSaved) {
        _saveController.forward();
        HapticFeedback.mediumImpact();
      } else {
        _saveController.reverse();
      }

      _trackUserAction(_isSaved ? UserActionType.save : UserActionType.view);
      widget.onSave?.call();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleBook() {
    if (widget.onBook != null) {
      HapticFeedback.heavyImpact();
      _trackUserAction(UserActionType.book);
      widget.onBook!();
    }
  }

  void _handleShare() {
    if (widget.onShare != null) {
      HapticFeedback.selectionClick();
      _trackUserAction(UserActionType.share);
      widget.onShare!();
    }
  }

  // Analytics
  void _trackUserAction(UserActionType actionType) async {
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) return;

      final action = UserAction(
        type: actionType,
        flashId: widget.flash.id,
        artistId: widget.flash.tattooArtistId,
        metadata: {
          'style': widget.flash.style,
          'price': widget.flash.effectivePrice,
          'city': widget.flash.city,
          'cardSize': widget.size.name,
          'cardStyle': widget.style.name,
        },
      );

      await RecommendationEngine.instance.updateUserPreferences(
        currentUser['uid'],
        action,
      );
    } catch (e) {
      print('❌ Erreur tracking action: $e');
    }
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

/// Tailles disponibles pour FlashCard
enum FlashCardSize {
  small,      // 150x200 - grilles compactes
  medium,     // 200x320 - listes standard  
  large,      // 300x420 - détails étendus
  fullWidth,  // largeur complète - listes verticales
}

/// Styles visuels pour FlashCard
enum FlashCardStyle {
  elevated,   // Ombre et élévation
  outlined,   // Bordure simple
  gradient,   // Fond dégradé
}