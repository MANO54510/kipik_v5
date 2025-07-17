// lib/screens/subscription/subscription_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_subscription.dart';
import '../../../services/subscription/firebase_subscription_service.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../../screens/subscription/widgets/subscription_card.dart';
import '../../../screens/subscription/widgets/feature_comparison_table.dart';
import '../../../screens/subscription/widgets/break_even_calculator.dart';

class SubscriptionSelectionScreen extends StatefulWidget {
  const SubscriptionSelectionScreen({super.key});

  @override
  State<SubscriptionSelectionScreen> createState() => _SubscriptionSelectionScreenState();
}

class _SubscriptionSelectionScreenState extends State<SubscriptionSelectionScreen>
    with TickerProviderStateMixin {
  
  SubscriptionType _selectedType = SubscriptionType.premium; // Premium par défaut
  bool _isLoading = false;
  String? _errorMessage;
  double _currentRevenue = 5000; // Valeur par défaut optimiste
  
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  final _subscriptionService = FirebaseSubscriptionService.instance;
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _slideController.forward();
    if (_selectedType == SubscriptionType.premium) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: FadeTransition(
        opacity: _slideAnimation,
        child: CustomScrollView(
          slivers: [
            _buildHeroAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildPsychologyHook(),
                    const SizedBox(height: 30),
                    _buildValueProposition(),
                    const SizedBox(height: 30),
                    _buildSubscriptionCards(),
                    const SizedBox(height: 30),
                    _buildSmartCalculator(),
                    const SizedBox(height: 30),
                    _buildFeatureComparison(),
                    const SizedBox(height: 30),
                    _buildSocialProof(),
                    const SizedBox(height: 30),
                    _buildUrgencySection(),
                    const SizedBox(height: 30),
                    _buildCTASection(),
                    const SizedBox(height: 20),
                    _buildTrustSignals(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0B),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Choisissez votre formule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SubscriptionType.premium.subscriptionColor.withOpacity(0.8),
                SubscriptionType.premium.subscriptionColor,
                SubscriptionType.standard.subscriptionColor,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🚀',
                  style: TextStyle(fontSize: 48),
                ),
                SizedBox(height: 8),
                Text(
                  'KIPIK PRO',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPsychologyHook() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SubscriptionType.premium.subscriptionColor.withOpacity(0.1),
              SubscriptionType.premium.subscriptionColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: SubscriptionType.premium.subscriptionColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            const Text(
              '💡 Votre potentiel de croissance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.white),
                children: [
                  const TextSpan(text: 'Les tatoueurs '),
                  TextSpan(
                    text: 'Premium',
                    style: TextStyle(
                      color: SubscriptionType.premium.subscriptionColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' génèrent en moyenne '),
                  TextSpan(
                    text: '+40% de CA',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const TextSpan(text: ' grâce aux conventions et au système guest'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueProposition() {
    return Row(
      children: [
        Expanded(
          child: _buildValueCard(
            '💰',
            'Commission réduite',
            '1% au lieu de 2%',
            'Économisez 50€/mois dès 5000€ CA',
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildValueCard(
            '🎪',
            'Accès exclusif',
            'Conventions & Guest',
            'Nouveaux clients garantis',
            SubscriptionType.premium.subscriptionColor,
          ),
        ),
      ],
    );
  }

  Widget _buildValueCard(String emoji, String title, String subtitle, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nos formules',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Standard Card
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.identity()
            ..scale(_selectedType == SubscriptionType.standard ? 1.02 : 1.0),
          child: SubscriptionCard(
            type: SubscriptionType.standard,
            isSelected: _selectedType == SubscriptionType.standard,
            onTap: () {
              setState(() => _selectedType = SubscriptionType.standard);
              HapticFeedback.selectionClick();
              _pulseController.stop();
            },
            isRecommended: false,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Premium Card (Recommandé avec animation)
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _selectedType == SubscriptionType.premium 
                  ? _pulseAnimation.value 
                  : 1.0,
              child: SubscriptionCard(
                type: SubscriptionType.premium,
                isSelected: _selectedType == SubscriptionType.premium,
                onTap: () {
                  setState(() => _selectedType = SubscriptionType.premium);
                  HapticFeedback.lightImpact();
                  if (!_pulseController.isAnimating) {
                    _pulseController.repeat(reverse: true);
                  }
                },
                isRecommended: true,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSmartCalculator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🧮 Premium sera-t-il rentable pour vous ?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        BreakEvenCalculator(
          currentType: SubscriptionType.standard,
          targetType: SubscriptionType.premium,
          onUpgradeRecommended: () {
            setState(() => _selectedType = SubscriptionType.premium);
            HapticFeedback.mediumImpact();
            _pulseController.repeat(reverse: true);
          },
        ),
      ],
    );
  }

  Widget _buildFeatureComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚖️ Comparaison détaillée',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        FeatureComparisonTable(
          onPremiumSelected: () {
            setState(() => _selectedType = SubscriptionType.premium);
            HapticFeedback.mediumImpact();
            _pulseController.repeat(reverse: true);
          },
        ),
      ],
    );
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            '⭐ Témoignages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildTestimonial(
            '"Premium m\'a permis de doubler mon CA grâce aux conventions"',
            'Sarah, Tattoueuse à Paris',
            '⭐⭐⭐⭐⭐',
          ),
          const SizedBox(height: 12),
          _buildTestimonial(
            '"Le système guest m\'apporte 3-4 nouveaux clients par mois"',
            'Marc, Studio à Lyon',
            '⭐⭐⭐⭐⭐',
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonial(String quote, String author, String stars) {
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
            stars,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            quote,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '- $author',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.8),
            Colors.red.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '🔥 Offre de lancement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '30 jours GRATUITS',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Testez toutes les fonctionnalités Premium sans engagement',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '💳 Aucune carte bancaire requise',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _selectedType == SubscriptionType.premium 
                  ? _pulseAnimation.value 
                  : 1.0,
              child: Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _selectedType == SubscriptionType.premium 
                        ? [SubscriptionType.premium.subscriptionColor, SubscriptionType.premium.subscriptionColor.withOpacity(0.8)]
                        : [SubscriptionType.standard.subscriptionColor, SubscriptionType.standard.subscriptionColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedType.subscriptionColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading ? null : _startFreeTrial,
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '🚀 Essayer ${_selectedType.displayName} GRATUIT',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  '30 jours • Sans engagement • Annulation libre',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTrustSignals() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTrustItem('🔒', 'Paiements\nsécurisés'),
            _buildTrustItem('📞', 'Support\n24/7'),
            _buildTrustItem('✅', 'Satisfait ou\nremboursé'),
            _buildTrustItem('🇫🇷', 'Entreprise\nfrançaise'),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🎭 Mode DÉMO activé - Aucun paiement réel ne sera effectué',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrustItem(String emoji, String text) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _startFreeTrial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = SecureAuthService.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final userId = user['uid'] ?? user['id'];
      if (userId == null) {
        throw Exception('ID utilisateur invalide');
      }

      final sepaDetails = <String, String>{
        'email': user['email']?.toString() ?? 'demo@kipik.com',
        'name': user['name']?.toString() ?? 'Demo User',
        'iban': 'FR7630004000031234567890143',
      };

      final result = await _subscriptionService.startFreeTrial(
        userId: userId,
        targetType: _selectedType,
        sepaDetails: sepaDetails,
      );

      if (result.success) {
        HapticFeedback.mediumImpact();
        _showSuccessDialog(result);
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Erreur inconnue';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(SubscriptionResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🎉 ${_selectedType.displayName} activé !',
          style: const TextStyle(color: Colors.white, fontSize: 22),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _selectedType.subscriptionColor.withOpacity(0.8),
                    _selectedType.subscriptionColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    '30 JOURS GRATUITS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commission ${(_selectedType.commissionRate * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  if (_selectedType == SubscriptionType.premium) ...[
                    const SizedBox(height: 12),
                    const Text(
                      '🎪 Conventions • 🤝 Guest • ⚡ Flash Minute',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Profitez de toutes les fonctionnalités ${_selectedType.displayName} pendant 30 jours !',
              style: TextStyle(color: Colors.grey[300], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedType.subscriptionColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                '🚀 Commencer mon aventure KIPIK Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}