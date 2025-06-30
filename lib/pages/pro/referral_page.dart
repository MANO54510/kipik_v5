// lib/pages/pro/referral_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/promo/promo_code_service.dart';
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../theme/kipik_theme.dart';

class ReferralPage extends StatefulWidget {
  final String userId;
  final String userEmail;

  const ReferralPage({
    Key? key,
    required this.userId,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  String? _referralCode;
  bool _isLoading = true;
  List<Referral> _referrals = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() => _isLoading = true);
    
    try {
      // Générer ou récupérer le code de parrainage
      final code = await PromoCodeService.generateReferralCode(
        widget.userId,
        widget.userEmail,
      );
      
      // Charger les parrainages existants
      final referrals = await PromoCodeService.getUserReferrals(widget.userId);
      
      // Charger les statistiques
      final stats = await PromoCodeService.getReferralStats(widget.userId);
      
      setState(() {
        _referralCode = code;
        _referrals = referrals;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _copyCode() {
    if (_referralCode != null) {
      Clipboard.setData(ClipboardData(text: _referralCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copié dans le presse-papiers !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _shareCode() {
    if (_referralCode != null) {
      final message = '''
🎨 Rejoins-moi sur Kipik !

Salut ! Je suis tatoueur et j'utilise l'app Kipik pour gérer mon business. 

Utilise mon code de parrainage : $_referralCode

Tu pourras t'inscrire et si tu prends un abonnement annuel, j'aurai 1 mois gratuit ! 

Télécharge l'app : [Lien vers l'app store]

#Kipik #Tatouage #Parrainage
      ''';
      
      Share.share(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarKipik(
        title: 'Programme de parrainage',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header avec explication
                  Card(
                    elevation: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.7)],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '🎉 Parraine un tatoueur et gagne 1 mois gratuit !',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'PermanentMarker',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Quand ton filleul souscrit un abonnement annuel, tu reçois automatiquement 1 mois gratuit !',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Code de parrainage
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Ton code de parrainage',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PermanentMarker',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: KipikTheme.rouge, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _referralCode ?? 'Chargement...',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _copyCode,
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copier'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: KipikTheme.rouge,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _shareCode,
                                  icon: const Icon(Icons.share),
                                  label: const Text('Partager'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Statistiques
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Tes statistiques',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PermanentMarker',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Parrainages',
                                  value: '${_stats['totalReferrals'] ?? 0}',
                                  icon: Icons.person_add,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Validés',
                                  value: '${_stats['completedReferrals'] ?? 0}',
                                  icon: Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'En attente',
                                  value: '${_stats['pendingReferrals'] ?? 0}',
                                  icon: Icons.hourglass_empty,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Mois gagnés',
                                  value: '${_stats['totalRewardMonths'] ?? 0}',
                                  icon: Icons.emoji_events,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Comment ça marche
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comment ça marche ?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PermanentMarker',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _StepTile(
                            step: '1',
                            title: 'Partage ton code',
                            description: 'Envoie ton code de parrainage à un tatoueur ami',
                            icon: Icons.share,
                          ),
                          _StepTile(
                            step: '2',
                            title: 'Il s\'inscrit',
                            description: 'Ton ami utilise ton code lors de son inscription',
                            icon: Icons.person_add,
                          ),
                          _StepTile(
                            step: '3',
                            title: 'Il souscrit 1 an',
                            description: 'Il choisit un abonnement annuel pour valider le parrainage',
                            icon: Icons.calendar_today,
                          ),
                          _StepTile(
                            step: '4',
                            title: 'Tu gagnes !',
                            description: 'Tu reçois automatiquement 1 mois gratuit',
                            icon: Icons.emoji_events,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Historique des parrainages
                  if (_referrals.isNotEmpty) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tes parrainages',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PermanentMarker',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...List.generate(_referrals.length, (index) {
                              final referral = _referrals[index];
                              return _ReferralTile(referral: referral);
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final IconData icon;
  final bool isLast;

  const _StepTile({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: KipikTheme.rouge,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: KipikTheme.rouge),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (!isLast) const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferralTile extends StatelessWidget {
  final Referral referral;

  const _ReferralTile({required this.referral});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (referral.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Validé';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'En attente';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Inconnu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.referredEmail,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Parrainé le ${referral.referralDate.day}/${referral.referralDate.month}/${referral.referralDate.year}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (referral.subscriptionType != null)
                  Text(
                    'Abonnement: ${referral.subscriptionType}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (referral.rewardGranted)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '🎉 +1 mois',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}