// lib/widgets/safe_layout_builder.dart
// Widget helper pour éviter les erreurs de layout

import 'package:flutter/material.dart';

class SafeLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;
  final Widget? fallback;
  
  const SafeLayoutBuilder({
    Key? key,
    required this.builder,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          // Vérifier que les contraintes sont valides
          if (constraints.maxWidth.isInfinite || constraints.maxHeight.isInfinite) {
            print('⚠️ Contraintes infinies détectées: $constraints');
            return fallback ?? const SizedBox.shrink();
          }
          
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            print('⚠️ Contraintes invalides détectées: $constraints');
            return fallback ?? const SizedBox.shrink();
          }
          
          return builder(context, constraints);
        } catch (e) {
          print('❌ Erreur dans SafeLayoutBuilder: $e');
          return fallback ?? Container(
            width: 100,
            height: 100,
            color: Colors.red.withOpacity(0.3),
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          );
        }
      },
    );
  }
}

// Widget pour Flex sécurisé
class SafeFlex extends StatelessWidget {
  final List<Widget> children;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  
  const SafeFlex({
    Key? key,
    required this.children,
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeLayoutBuilder(
      builder: (context, constraints) {
        // Vérifier si on a des contraintes boundées
        final hasFiniteWidth = constraints.maxWidth.isFinite;
        final hasFiniteHeight = constraints.maxHeight.isFinite;
        
        if (direction == Axis.horizontal && !hasFiniteWidth) {
          // Pour un Row avec largeur infinie, utiliser Wrap ou Container
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          );
        }
        
        if (direction == Axis.vertical && !hasFiniteHeight) {
          // Pour une Column avec hauteur infinie, utiliser SingleChildScrollView
          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          );
        }
        
        return Flex(
          direction: direction,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children,
        );
      },
      fallback: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// Extension pour debugging
extension ConstraintsDebug on BoxConstraints {
  void debugPrint(String context) {
    print('📐 Contraintes dans $context: '
          'W: ${minWidth.toStringAsFixed(1)}-${maxWidth.toStringAsFixed(1)}, '
          'H: ${minHeight.toStringAsFixed(1)}-${maxHeight.toStringAsFixed(1)}');
  }
}