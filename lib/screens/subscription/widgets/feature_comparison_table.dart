// lib/screens/subscription/widgets/feature_comparison_table.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_subscription.dart';

class FeatureComparisonTable extends StatefulWidget {
  final VoidCallback? onPremiumSelected;
  final bool showCTA;

  const FeatureComparisonTable({
    super.key,
    this.onPremiumSelected,
    this.showCTA = true,
  });

  @override
  State<FeatureComparisonTable> createState() => _FeatureComparisonTableState();
}

class _FeatureComparisonTableState extends State<FeatureComparisonTable> {
  
  final List<ComparisonFeature> _features = [
    // ✅ FONCTIONNALITÉS COMMUNES (Standard + Premium)
    ComparisonFeature(
      icon: '📅',
      name: 'Agenda professionnel',
      description: 'Synchronisation Google/Apple Calendar',
      standard: true,
      premium: true,
      isCore: true,
    ),
    ComparisonFeature(
      icon: '💳',
      name: 'Paiement fractionné',
      description: 'Clients paient en 2, 3 ou 4 fois',
      standard: true,
      premium: true,
      isCore: true,
    ),
    ComparisonFeature(
      icon: '👥',
      name: 'Gestion clients',
      description: 'CRM complet avec historique',
      standard: true,
      premium: true,
      isCore: true,
    ),
    ComparisonFeature(
      icon: '📊',
      name: 'Analytics de base',
      description: 'Stats essentielles de votre activité',
      standard: true,
      premium: true,
      isCore: true,
    ),
    
    // 💰 COMMISSION (DIFFÉRENCE IMPORTANTE)
    ComparisonFeature(
      icon: '💰',
      name: 'Commission KIPIK',
      description: 'Frais prélevés sur vos paiements',
      standard: '2%',
      premium: '1%',
      isCommission: true,
    ),
    
    // 🚀 EXCLUSIVITÉS PREMIUM (LA VRAIE VALEUR)
    ComparisonFeature(
      icon: '🎪',
      name: 'Conventions & Événements',
      description: 'Accès aux salons tattoo, réservation stands',
      standard: false,
      premium: true,
      isPremiumOnly: true,
    ),
    ComparisonFeature(
      icon: '🤝',
      name: 'Système Guest',
      description: 'Candidatures + invitations entre studios',
      standard: false,
      premium: true,
      isPremiumOnly: true,
    ),
    ComparisonFeature(
      icon: '⚡',
      name: 'Flash Minute',
      description: 'Créneaux libres en dernière minute',
      standard: false,
      premium: true,
      isPremiumOnly: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildFeaturesList(),
          if (widget.showCTA) _buildCTA(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Standard vs Premium',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Même base solide, fonctionnalités exclusives en Premium',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // En-têtes colonnes
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Fonctionnalités',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Standard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: SubscriptionType.standard.subscriptionColor,
                      ),
                    ),
                    const Text(
                      '99€/mois',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Premium',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: SubscriptionType.premium.subscriptionColor,
                      ),
                    ),
                    const Text(
                      '149€/mois',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
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

  Widget _buildFeaturesList() {
    return Column(
      children: [
        // Section: Fonctionnalités communes
        _buildSectionTitle('✅ Inclus dans les deux'),
        ..._features.where((f) => f.isCore).map((feature) => _buildFeatureRow(feature)),
        
        // Section: Commission
        _buildSectionTitle('💰 Commission'),
        ..._features.where((f) => f.isCommission).map((feature) => _buildFeatureRow(feature)),
        
        // Section: Exclusivités Premium
        _buildSectionTitle('🚀 Exclusif Premium', isPremium: true),
        ..._features.where((f) => f.isPremiumOnly).map((feature) => _buildFeatureRow(feature)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool isPremium = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: isPremium 
          ? SubscriptionType.premium.subscriptionColor.withOpacity(0.1)
          : const Color(0xFF0A0A0B),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isPremium 
              ? SubscriptionType.premium.subscriptionColor
              : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(ComparisonFeature feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom + description
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.icon,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Standard
          Expanded(
            child: Center(
              child: _buildStatusCell(
                feature.standard,
                SubscriptionType.standard.subscriptionColor,
              ),
            ),
          ),
          
          // Premium
          Expanded(
            child: Center(
              child: _buildStatusCell(
                feature.premium,
                SubscriptionType.premium.subscriptionColor,
                isPremium: true,
                isExclusive: feature.isPremiumOnly,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCell(dynamic value, Color color, {bool isPremium = false, bool isExclusive = false}) {
    if (value is bool) {
      if (value) {
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: color,
            size: 16,
          ),
        );
      } else {
        return Icon(
          Icons.remove,
          color: Colors.grey[600],
          size: 16,
        );
      }
    } 
    
    if (value is String) {
      // Pour la commission
      final isGood = value == '1%';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isGood ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: isGood ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildCTA() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A2E),
            SubscriptionType.premium.subscriptionColor.withOpacity(0.1),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Message principal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SubscriptionType.premium.subscriptionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SubscriptionType.premium.subscriptionColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: SubscriptionType.premium.subscriptionColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      children: [
                        const TextSpan(text: 'Besoin de '),
                        TextSpan(
                          text: 'Conventions',
                          style: TextStyle(
                            color: SubscriptionType.premium.subscriptionColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ', '),
                        TextSpan(
                          text: 'Guest',
                          style: TextStyle(
                            color: SubscriptionType.premium.subscriptionColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' ou '),
                        TextSpan(
                          text: 'Flash Minute',
                          style: TextStyle(
                            color: SubscriptionType.premium.subscriptionColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' ?'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bouton CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onPremiumSelected?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SubscriptionType.premium.subscriptionColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Choisir Premium',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Vous économiserez aussi 50€/mois dès 5000€ de CA',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ComparisonFeature {
  final String icon;
  final String name;
  final String description;
  final dynamic standard;
  final dynamic premium;
  final bool isCore;
  final bool isPremiumOnly;
  final bool isCommission;

  ComparisonFeature({
    required this.icon,
    required this.name,
    required this.description,
    required this.standard,
    required this.premium,
    this.isCore = false,
    this.isPremiumOnly = false,
    this.isCommission = false,
  });
}