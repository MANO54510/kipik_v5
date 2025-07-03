// lib/widgets/pro/referral_menu_item.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kipik_v5/services/promo/firebase_promo_code_service.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ AJOUTÉ
import 'package:kipik_v5/theme/kipik_theme.dart';

class ReferralMenuItem extends StatelessWidget {
  // ✅ SIMPLIFIÉ: Plus besoin de paramètres, on utilise SecureAuthService
  const ReferralMenuItem({
    Key? key,
  }) : super(key: key);

  Future<void> _showReferralDialog(BuildContext context) async {
    // ✅ CORRECTION: Vérifier l'authentification
    final authService = SecureAuthService.instance;
    final currentUser = authService.currentUser;
    final currentUserId = authService.currentUserId;
    
    if (currentUserId == null || currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour accéder au parrainage'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // ✅ CORRECTION: Utiliser les méthodes statiques corrigées
      final referralCode = await FirebasePromoCodeService.generateReferralCode();
      
      if (referralCode == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la génération du code de parrainage'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Récupérer les statistiques
      final stats = await FirebasePromoCodeService.getReferralStats();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Row(
              children: [
                Icon(Icons.people, color: KipikTheme.rouge),
                const SizedBox(width: 8),
                const Text(
                  'Mon code de parrainage',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ AMÉLIORÉ: Information utilisateur
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser['displayName'] ?? currentUser['name'] ?? 'Utilisateur',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                currentUser['email'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Parraine un tatoueur et gagne 1 mois gratuit !',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: KipikTheme.rouge),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Votre code :',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          referralCode,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: referralCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Code copié dans le presse-papiers !'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copier le code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KipikTheme.rouge,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // ✅ AMÉLIORÉ: Statistiques avec design moderne
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Vos statistiques',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              label: 'Parrainages',
                              value: '${stats['totalReferrals']}',
                              color: Colors.blue,
                              icon: Icons.people,
                            ),
                            _StatItem(
                              label: 'Validés',
                              value: '${stats['completedReferrals']}',
                              color: Colors.green,
                              icon: Icons.check_circle,
                            ),
                            _StatItem(
                              label: 'Mois gagnés',
                              value: '${stats['totalRewardMonths']}',
                              color: Colors.amber,
                              icon: Icons.card_giftcard,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // ✅ AMÉLIORÉ: Instructions avec design moderne
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.help_outline, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Comment ça marche ?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStepItem('1', 'Partage ton code à un tatoueur'),
                        _buildStepItem('2', 'Il s\'inscrit avec ton code'),
                        _buildStepItem('3', 'Il souscrit un abonnement annuel'),
                        _buildStepItem('4', 'Tu reçois 1 mois gratuit !'),
                      ],
                    ),
                  ),
                  
                  // ✅ NOUVEAU: Actions supplémentaires
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Naviguer vers l'historique des parrainages
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Historique des parrainages - Fonctionnalité en cours de développement'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('Historique', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Partager le code
                            Navigator.of(context).pop();
                            _shareReferralCode(context, referralCode);
                          },
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Partager', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Fermer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur affichage dialog parrainage: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ NOUVEAU: Widget pour les étapes
  Widget _buildStepItem(String step, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NOUVEAU: Partager le code de parrainage
  void _shareReferralCode(BuildContext context, String code) {
    // TODO: Implémenter le partage avec share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage ton code: $code'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'Copier',
          textColor: Colors.white,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ AMÉLIORÉ: Vérification d'authentification
    final authService = SecureAuthService.instance;
    final isAuthenticated = authService.isAuthenticated;
    
    return ListTile(
      leading: Icon(
        Icons.people, 
        color: isAuthenticated ? KipikTheme.rouge : Colors.grey,
      ),
      title: const Text('Programme de parrainage'),
      subtitle: Text(
        isAuthenticated 
            ? 'Gagne 1 mois gratuit' 
            : 'Connectez-vous pour accéder',
        style: TextStyle(
          color: isAuthenticated ? null : Colors.grey,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isAuthenticated ? Colors.green : Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'NOUVEAU',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      enabled: isAuthenticated,
      onTap: isAuthenticated ? () => _showReferralDialog(context) : null,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}