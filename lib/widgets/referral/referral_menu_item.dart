// lib/widgets/pro/referral_menu_item.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kipik_v5/services/promo/promo_code_service.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class ReferralMenuItem extends StatelessWidget {
  final String userId;
  final String userEmail;

  const ReferralMenuItem({
    Key? key,
    required this.userId,
    required this.userEmail,
  }) : super(key: key);

  Future<void> _showReferralDialog(BuildContext context) async {
    // Générer ou récupérer le code de parrainage
    final referralCode = await PromoCodeService.generateReferralCode(userId, userEmail);
    
    if (referralCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la génération du code de parrainage'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Récupérer les statistiques
    final stats = await PromoCodeService.getReferralStats(userId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people, color: KipikTheme.rouge),
            const SizedBox(width: 8),
            const Text('Mon code de parrainage'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Parraine un tatoueur et gagne 1 mois gratuit !',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: KipikTheme.rouge),
              ),
              child: Column(
                children: [
                  Text(
                    referralCode,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copié !')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KipikTheme.rouge,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Parrainages',
                  value: '${stats['totalReferrals']}',
                  color: Colors.blue,
                ),
                _StatItem(
                  label: 'Validés',
                  value: '${stats['completedReferrals']}',
                  color: Colors.green,
                ),
                _StatItem(
                  label: 'Mois gagnés',
                  value: '${stats['totalRewardMonths']}',
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Comment ça marche ?\n\n'
              '1. Partage ton code à un tatoueur\n'
              '2. Il s\'inscrit avec ton code\n'
              '3. Il souscrit un abonnement annuel\n'
              '4. Tu reçois 1 mois gratuit !',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.left,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.people, color: KipikTheme.rouge),
      title: const Text('Programme de parrainage'),
      subtitle: const Text('Gagne 1 mois gratuit'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
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
      onTap: () => _showReferralDialog(context),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        ),
      ],
    );
  }
}