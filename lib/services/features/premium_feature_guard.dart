// lib/widgets/premium_feature_guard.dart

import 'package:flutter/material.dart';
import '../../models/user_subscription.dart';
import '../../services/subscription/firebase_subscription_service.dart';
import '../../screens/subscription/subscription_selection_screen.dart';

/// Widget qui protège l'accès aux fonctionnalités premium
/// Affiche un popup d'upgrade si l'utilisateur n'a pas accès
class PremiumFeatureGuard extends StatelessWidget {
  final PremiumFeature requiredFeature;
  final Widget child;
  final String? featureName;
  final String? featureDescription;
  final bool showLockIcon;
  final Color? lockColor;
  final VoidCallback? onUpgradePressed;

  const PremiumFeatureGuard({
    super.key,
    required this.requiredFeature,
    required this.child,
    this.featureName,
    this.featureDescription,
    this.showLockIcon = true,
    this.lockColor,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAccess(),
      builder: (context, snapshot) {
        // En attente de vérification
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        
        final hasAccess = snapshot.data ?? false;
        
        if (hasAccess) {
          // Accès autorisé - afficher le contenu
          return child;
        } else {
          // Accès refusé - afficher la version bloquée
          return _buildLockedState(context);
        }
      },
    );
  }

  Future<bool> _checkAccess() async {
    final subscriptionService = FirebaseSubscriptionService.instance;
    return subscriptionService.hasAccess(requiredFeature);
  }

  Widget _buildLoadingState() {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  Widget _buildLockedState(BuildContext context) {
    return Stack(
      children: [
        // Contenu désactivé (grisé)
        IgnorePointer(
          child: Opacity(
            opacity: 0.3,
            child: child,
          ),
        ),
        
        // Overlay de verrouillage
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showUpgradeDialog(context),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showLockIcon) ...[
                        Icon(
                          Icons.lock,
                          color: lockColor ?? Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        requiredFeature.minimumRequired.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Requis',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    final requiredType = requiredFeature.minimumRequired;
    
    showDialog(
      context: context,
      builder: (context) => UpgradeDialog(
        requiredFeature: requiredFeature,
        featureName: featureName ?? requiredFeature.displayName,
        featureDescription: featureDescription ?? requiredFeature.description,
        requiredSubscription: requiredType,
        onUpgradePressed: onUpgradePressed ?? () => _navigateToSubscription(context),
      ),
    );
  }

  void _navigateToSubscription(BuildContext context) {
    Navigator.of(context).pop(); // Fermer le dialogue
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SubscriptionSelectionScreen(),
      ),
    );
  }
}

/// Dialog d'upgrade premium personnalisé
class UpgradeDialog extends StatelessWidget {
  final PremiumFeature requiredFeature;
  final String featureName;
  final String featureDescription;
  final SubscriptionType requiredSubscription;
  final VoidCallback onUpgradePressed;

  const UpgradeDialog({
    super.key,
    required this.requiredFeature,
    required this.featureName,
    required this.featureDescription,
    required this.requiredSubscription,
    required this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: requiredSubscription.subscriptionColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildFeatureInfo(),
            const SizedBox(height: 20),
            _buildSubscriptionInfo(),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: requiredSubscription.subscriptionColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            requiredFeature.icon,
            color: requiredSubscription.subscriptionColor,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '🔒 Fonctionnalité Premium',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            featureName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            featureDescription,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: requiredSubscription.subscriptionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: requiredSubscription.subscriptionColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getSubscriptionIcon(),
            color: requiredSubscription.subscriptionColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abonnement ${requiredSubscription.displayName} requis',
                  style: TextStyle(
                    color: requiredSubscription.subscriptionColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${requiredSubscription.monthlyPrice.toStringAsFixed(0)}€/mois',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: requiredSubscription.subscriptionColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${((1 - requiredSubscription.commissionRate / 0.025) * 100).toStringAsFixed(0)}% moins cher',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: requiredSubscription.subscriptionColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: onUpgradePressed,
            child: Text(
              '🚀 Upgrader vers ${requiredSubscription.displayName}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Plus tard',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getSubscriptionIcon() {
    switch (requiredSubscription) {
      case SubscriptionType.standard:
        return Icons.business;
      case SubscriptionType.premium:
        return Icons.diamond;
      case SubscriptionType.enterprise:
        return Icons.corporate_fare;
      default:
        return Icons.star;
    }
  }
}

/// Version simplifiée pour les boutons/widgets simples
class PremiumButton extends StatelessWidget {
  final PremiumFeature requiredFeature;
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;

  const PremiumButton({
    super.key,
    required this.requiredFeature,
    required this.child,
    this.onPressed,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAccess(),
      builder: (context, snapshot) {
        final hasAccess = snapshot.data ?? false;
        
        return ElevatedButton(
          style: style,
          onPressed: hasAccess 
              ? onPressed 
              : () => _showUpgradeDialog(context),
          child: hasAccess 
              ? child 
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 16),
                    const SizedBox(width: 4),
                    child,
                  ],
                ),
        );
      },
    );
  }

  Future<bool> _checkAccess() async {
    final subscriptionService = FirebaseSubscriptionService.instance;
    return subscriptionService.hasAccess(requiredFeature);
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UpgradeDialog(
        requiredFeature: requiredFeature,
        featureName: requiredFeature.displayName,
        featureDescription: requiredFeature.description,
        requiredSubscription: requiredFeature.minimumRequired,
        onUpgradePressed: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SubscriptionSelectionScreen(),
            ),
          );
        },
      ),
    );
  }
}

/// Extensions pour les couleurs et icônes


/// Widget de quick check pour développement/debug
class QuickAccessChecker extends StatelessWidget {
  final List<PremiumFeature> features;
  final Widget Function(Map<PremiumFeature, bool>) builder;

  const QuickAccessChecker({
    super.key,
    required this.features,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<PremiumFeature, bool>>(
      future: _checkAllFeatures(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final accessMap = snapshot.data ?? {};
        return builder(accessMap);
      },
    );
  }

  Future<Map<PremiumFeature, bool>> _checkAllFeatures() async {
    final subscriptionService = FirebaseSubscriptionService.instance;
    final Map<PremiumFeature, bool> result = {};
    
    for (final feature in features) {
      result[feature] = subscriptionService.hasAccess(feature);
    }
    
    return result;
  }
}