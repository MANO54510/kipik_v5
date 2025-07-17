// lib/widgets/shared/flash_minute_badge.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../theme/kipik_theme.dart';

/// Badge animé pour les Flash Minute avec countdown et effets visuels
/// Affiche le temps restant avec animations d'urgence
class FlashMinuteBadge extends StatefulWidget {
  final DateTime deadline;
  final FlashMinuteBadgeSize size;
  final FlashMinuteBadgeStyle style;
  final bool showCountdown;
  final bool enablePulseAnimation;
  final Color? backgroundColor;
  final Color? textColor;

  const FlashMinuteBadge({
    Key? key,
    required this.deadline,
    this.size = FlashMinuteBadgeSize.medium,
    this.style = FlashMinuteBadgeStyle.gradient,
    this.showCountdown = true,
    this.enablePulseAnimation = true,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  State<FlashMinuteBadge> createState() => _FlashMinuteBadgeState();
}

class _FlashMinuteBadgeState extends State<FlashMinuteBadge>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _blinkController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _shakeAnimation;

  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  bool _isUrgent = false;
  bool _isCritical = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateTimeRemaining();
    _startCountdownTimer();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    if (widget.enablePulseAnimation) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimeRemaining();
      }
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final remaining = widget.deadline.difference(now);

    setState(() {
      _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
      _isUrgent = _timeRemaining.inMinutes <= 30 && _timeRemaining.inMinutes > 5;
      _isCritical = _timeRemaining.inMinutes <= 5;
    });

    // Démarrer animations selon l'urgence
    if (_isCritical && !_blinkController.isAnimating) {
      _blinkController.repeat(reverse: true);
      _startShakeAnimation();
    } else if (_isUrgent && _blinkController.isAnimating) {
      _blinkController.stop();
      _blinkController.reset();
    }
  }

  void _startShakeAnimation() {
    _shakeController.forward().then((_) {
      if (mounted && _isCritical) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _shakeController.reset();
            _startShakeAnimation();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _blinkController.dispose();
    _shakeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeRemaining.isNegative || _timeRemaining == Duration.zero) {
      return _buildExpiredBadge();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _blinkAnimation,
        _shakeAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _isCritical ? _pulseAnimation.value : 1.0,
          child: Transform.translate(
            offset: _isCritical
                ? Offset(
                    math.sin(_shakeAnimation.value * math.pi * 4) * 2,
                    0,
                  )
                : Offset.zero,
            child: Opacity(
              opacity: _isCritical ? _blinkAnimation.value : 1.0,
              child: _buildBadge(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: _getPadding(),
      decoration: _getBadgeDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône Flash
          Icon(
            Icons.flash_on,
            color: _getIconColor(),
            size: _getIconSize(),
          ),
          
          SizedBox(width: _getSpacing()),
          
          // Texte et countdown
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FLASH MINUTE',
                style: TextStyle(
                  color: _getTextColor(),
                  fontSize: _getTitleFontSize(),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.showCountdown && widget.size != FlashMinuteBadgeSize.small)
                Text(
                  _formatTimeRemaining(),
                  style: TextStyle(
                    color: _getTextColor().withOpacity(0.9),
                    fontSize: _getCountdownFontSize(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredBadge() {
    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        border: Border.all(
          color: Colors.grey.shade600,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_off,
            color: Colors.grey.shade400,
            size: _getIconSize(),
          ),
          SizedBox(width: _getSpacing()),
          Text(
            'EXPIRÉ',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: _getTitleFontSize(),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _getBadgeDecoration() {
    final baseColor = widget.backgroundColor ?? _getUrgencyColor();
    
    switch (widget.style) {
      case FlashMinuteBadgeStyle.solid:
        return BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        );
        
      case FlashMinuteBadgeStyle.gradient:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          boxShadow: [
            BoxShadow(
              color: _getGradientColors().first.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        );
        
      case FlashMinuteBadgeStyle.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          border: Border.all(
            color: baseColor,
            width: 2,
          ),
        );
        
      case FlashMinuteBadgeStyle.neon:
        return BoxDecoration(
          color: baseColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          border: Border.all(
            color: baseColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: baseColor.withOpacity(0.8),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        );
    }
  }

  Color _getUrgencyColor() {
    if (_isCritical) return Colors.red.shade600;
    if (_isUrgent) return Colors.orange.shade600;
    return KipikTheme.rouge;
  }

  List<Color> _getGradientColors() {
    if (_isCritical) {
      return [Colors.red.shade600, Colors.red.shade400];
    }
    if (_isUrgent) {
      return [Colors.orange.shade600, Colors.yellow.shade500];
    }
    return [KipikTheme.rouge, Colors.orange.shade400];
  }

  Color _getTextColor() {
    if (widget.textColor != null) return widget.textColor!;
    if (widget.style == FlashMinuteBadgeStyle.outlined) {
      return _getUrgencyColor();
    }
    return Colors.white;
  }

  Color _getIconColor() {
    return _getTextColor();
  }

  // Dimensions helpers
  EdgeInsets _getPadding() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case FlashMinuteBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case FlashMinuteBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return 8;
      case FlashMinuteBadgeSize.medium:
        return 12;
      case FlashMinuteBadgeSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return 14;
      case FlashMinuteBadgeSize.medium:
        return 18;
      case FlashMinuteBadgeSize.large:
        return 22;
    }
  }

  double _getSpacing() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return 4;
      case FlashMinuteBadgeSize.medium:
        return 6;
      case FlashMinuteBadgeSize.large:
        return 8;
    }
  }

  double _getTitleFontSize() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return 10;
      case FlashMinuteBadgeSize.medium:
        return 12;
      case FlashMinuteBadgeSize.large:
        return 14;
    }
  }

  double _getCountdownFontSize() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return 8;
      case FlashMinuteBadgeSize.medium:
        return 10;
      case FlashMinuteBadgeSize.large:
        return 12;
    }
  }

  String _formatTimeRemaining() {
    if (_timeRemaining.inDays > 0) {
      return '${_timeRemaining.inDays}j ${_timeRemaining.inHours % 24}h';
    } else if (_timeRemaining.inHours > 0) {
      return '${_timeRemaining.inHours}h ${_timeRemaining.inMinutes % 60}min';
    } else if (_timeRemaining.inMinutes > 0) {
      return '${_timeRemaining.inMinutes}min';
    } else {
      return '${_timeRemaining.inSeconds}s';
    }
  }
}

/// Widget simple pour afficher juste l'icône Flash Minute
class FlashMinuteIcon extends StatefulWidget {
  final FlashMinuteBadgeSize size;
  final Color? color;
  final bool enableAnimation;

  const FlashMinuteIcon({
    Key? key,
    this.size = FlashMinuteBadgeSize.medium,
    this.color,
    this.enableAnimation = true,
  }) : super(key: key);

  @override
  State<FlashMinuteIcon> createState() => _FlashMinuteIconState();
}

class _FlashMinuteIconState extends State<FlashMinuteIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.enableAnimation) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enableAnimation ? _animation.value : 1.0,
          child: Icon(
            Icons.flash_on,
            color: widget.color ?? KipikTheme.rouge,
            size: _getIconSize(),
          ),
        );
      },
    );
  }

  double _getIconSize() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return 16;
      case FlashMinuteBadgeSize.medium:
        return 20;
      case FlashMinuteBadgeSize.large:
        return 24;
    }
  }
}

/// Countdown compact pour Flash Minute
class FlashMinuteCountdown extends StatefulWidget {
  final DateTime deadline;
  final TextStyle? textStyle;
  final bool showIcon;

  const FlashMinuteCountdown({
    Key? key,
    required this.deadline,
    this.textStyle,
    this.showIcon = true,
  }) : super(key: key);

  @override
  State<FlashMinuteCountdown> createState() => _FlashMinuteCountdownState();
}

class _FlashMinuteCountdownState extends State<FlashMinuteCountdown> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimeRemaining();
      }
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final remaining = widget.deadline.difference(now);
    
    setState(() {
      _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeRemaining == Duration.zero) {
      return Text(
        'Expiré',
        style: widget.textStyle?.copyWith(color: Colors.grey) ??
               TextStyle(color: Colors.grey.shade400, fontSize: 12),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          FlashMinuteIcon(
            size: FlashMinuteBadgeSize.small,
            color: _getUrgencyColor(),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          _formatCompactTime(),
          style: widget.textStyle?.copyWith(color: _getUrgencyColor()) ??
                 TextStyle(
                   color: _getUrgencyColor(),
                   fontSize: 12,
                   fontWeight: FontWeight.bold,
                 ),
        ),
      ],
    );
  }

  Color _getUrgencyColor() {
    if (_timeRemaining.inMinutes <= 5) return Colors.red;
    if (_timeRemaining.inMinutes <= 30) return Colors.orange;
    return KipikTheme.rouge;
  }

  String _formatCompactTime() {
    if (_timeRemaining.inDays > 0) {
      return '${_timeRemaining.inDays}j';
    } else if (_timeRemaining.inHours > 0) {
      return '${_timeRemaining.inHours}h';
    } else if (_timeRemaining.inMinutes > 0) {
      return '${_timeRemaining.inMinutes}min';
    } else {
      return '${_timeRemaining.inSeconds}s';
    }
  }
}

/// Badge animé avec effet de pulsation pour les promotions
class FlashPromoBadge extends StatefulWidget {
  final String text;
  final String? subtitle;
  final IconData? icon;
  final Color? backgroundColor;
  final FlashMinuteBadgeSize size;

  const FlashPromoBadge({
    Key? key,
    required this.text,
    this.subtitle,
    this.icon,
    this.backgroundColor,
    this.size = FlashMinuteBadgeSize.medium,
  }) : super(key: key);

  @override
  State<FlashPromoBadge> createState() => _FlashPromoBadgeState();
}

class _FlashPromoBadgeState extends State<FlashPromoBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            padding: _getPadding(),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.backgroundColor ?? KipikTheme.rouge,
                  (widget.backgroundColor ?? KipikTheme.rouge).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(_getBorderRadius()),
              boxShadow: [
                BoxShadow(
                  color: (widget.backgroundColor ?? KipikTheme.rouge).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: _getIconSize(),
                  ),
                  SizedBox(width: _getSpacing()),
                ],
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getTitleFontSize(),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (widget.subtitle != null &&
                        widget.size != FlashMinuteBadgeSize.small)
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: _getSubtitleFontSize(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case FlashMinuteBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case FlashMinuteBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return 8;
      case FlashMinuteBadgeSize.medium:
        return 12;
      case FlashMinuteBadgeSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return 14;
      case FlashMinuteBadgeSize.medium:
        return 18;
      case FlashMinuteBadgeSize.large:
        return 22;
    }
  }

  double _getSpacing() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return 4;
      case FlashMinuteBadgeSize.medium:
        return 6;
      case FlashMinuteBadgeSize.large:
        return 8;
    }
  }

  double _getTitleFontSize() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return 10;
      case FlashMinuteBadgeSize.medium:
        return 12;
      case FlashMinuteBadgeSize.large:
        return 14;
    }
  }

  double _getSubtitleFontSize() {
    switch (widget.size) {
      case FlashMinuteBadgeSize.small:
        return 8;
      case FlashMinuteBadgeSize.medium:
        return 10;
      case FlashMinuteBadgeSize.large:
        return 12;
    }
  }
}

/// Enums pour les configurations des badges
enum FlashMinuteBadgeSize {
  small,   // Compact pour listes
  medium,  // Standard pour cartes
  large,   // Extended pour headers
}

enum FlashMinuteBadgeStyle {
  solid,     // Couleur unie
  gradient,  // Dégradé coloré
  outlined,  // Bordure seulement
  neon,      // Effet néon lumineux
}