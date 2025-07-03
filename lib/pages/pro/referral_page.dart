// lib/pages/pro/referral_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kipik_v5/services/promo/firebase_promo_code_service.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({Key? key}) : super(key: key);

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  String? _referralCode;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _referrals = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    try {
      // ✅ Vérifier que l'utilisateur est connecté
      if (!SecureAuthService.instance.isAuthenticated) {
        throw Exception('Vous devez être connecté pour accéder au parrainage');
      }

      // ✅ Utiliser les nouvelles méthodes statiques simplifiées
      final futures = await Future.wait([
        FirebasePromoCodeService.generateReferralCode(),
        FirebasePromoCodeService.getReferralStats(),
        FirebasePromoCodeService.instance.getCurrentUserReferrals(),
      ]);
      
      setState(() {
        _referralCode = futures[0] as String?;
        _stats = futures[1] as Map<String, int>;
        _referrals = futures[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });

      // Log pour debug
      print('✅ Données de parrainage chargées:');
      print('  - Code: $_referralCode');
      print('  - Stats: $_stats');
      print('  - Parrainages: ${_referrals.length}');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      
      print('❌ Erreur chargement parrainage: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _loadReferralData,
            ),
          ),
        );
      }
    }
  }

  void _copyCode() {
    if (_referralCode != null) {
      Clipboard.setData(ClipboardData(text: _referralCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Code copié dans le presse-papiers !'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareCode() {
    if (_referralCode != null) {
      // ✅ CORRECTION: Récupérer les infos utilisateur depuis SecureAuthService
      final currentUser = SecureAuthService.instance.currentUser;
      final userName = currentUser?['name'] ?? 
                      currentUser?['displayName'] ?? 
                      currentUser?['email']?.split('@')[0] ?? 
                      'Un tatoueur';
      
      // ✅ UTILISER userName au lieu de $_userName
      final message = '''
🎨 Rejoins-moi sur Kipik !

Salut ! Je suis $userName et j'utilise l'app Kipik pour gérer mon business de tatouage. 

Utilise mon code de parrainage : $_referralCode

✨ Avantages pour toi :
• Gestion complète de tes projets
• Agenda intelligent
• Comptabilité simplifiée
• Portfolio professionnel

🎁 Et si tu prends un abonnement annuel, j'aurai 1 mois gratuit !

Télécharge l'app Kipik dès maintenant !

#Kipik #Tatouage #Parrainage #TattooArtist
      ''';
      
      Share.share(message);
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadReferralData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
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
      body: _hasError
          ? _buildErrorState()
          : _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement de vos données de parrainage...'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReferralData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 48,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '🎉 Parraine un tatoueur et gagne 1 mois gratuit !',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'PermanentMarker',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 12),
                                Text(
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
                                        _referralCode ?? 'Aucun code disponible',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          letterSpacing: 2,
                                          color: _referralCode != null ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_referralCode != null) ...[
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
                                ] else ...[
                                  ElevatedButton.icon(
                                    onPressed: _loadReferralData,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Générer un code'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: KipikTheme.rouge,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
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
                                        value: '${(_stats['totalReferrals'] ?? 0) - (_stats['completedReferrals'] ?? 0)}',
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
                                const _StepTile(
                                  step: '1',
                                  title: 'Partage ton code',
                                  description: 'Envoie ton code de parrainage à un tatoueur ami',
                                  icon: Icons.share,
                                ),
                                const _StepTile(
                                  step: '2',
                                  title: 'Il s\'inscrit',
                                  description: 'Ton ami utilise ton code lors de son inscription',
                                  icon: Icons.person_add,
                                ),
                                const _StepTile(
                                  step: '3',
                                  title: 'Il souscrit 1 an',
                                  description: 'Il choisit un abonnement annuel pour valider le parrainage',
                                  icon: Icons.calendar_today,
                                ),
                                const _StepTile(
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
                                  Row(
                                    children: [
                                      const Text(
                                        'Tes parrainages',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'PermanentMarker',
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${_referrals.length}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
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
                        ] else if (!_isLoading) ...[
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun parrainage pour le moment',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Commence à partager ton code pour inviter d\'autres tatoueurs !',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
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
  final Map<String, dynamic> referral;

  const _ReferralTile({required this.referral});

  @override
  Widget build(BuildContext context) {
    final status = referral['status'] as String? ?? 'pending';
    final createdAt = referral['createdAt'] as DateTime?;
    final completedAt = referral['completedAt'] as DateTime?;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
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
                  'Parrainage ${referral['referralCode'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                if (createdAt != null)
                  Text(
                    'Créé le ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                if (completedAt != null)
                  Text(
                    'Validé le ${completedAt.day}/${completedAt.month}/${completedAt.year}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
              if (status == 'completed')
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