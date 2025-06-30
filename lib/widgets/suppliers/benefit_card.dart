// benefit_card.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/models/supplier_model.dart';

class BenefitCard extends StatelessWidget {
  final PartnershipBenefit benefit;

  const BenefitCard({
    Key? key,
    required this.benefit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Déterminer l'icône et la couleur selon le type d'avantage
    IconData iconData = Icons.star;
    Color iconColor = Theme.of(context).primaryColor;
    
    switch (benefit.type) {
      case BenefitType.discount:
        iconData = Icons.percent;
        iconColor = Colors.blue;
        break;
      case BenefitType.cashback:
        iconData = Icons.savings;
        iconColor = Colors.orange;
        break;
      case BenefitType.loyalty:
        iconData = Icons.loyalty;
        iconColor = Colors.purple;
        break;
      case BenefitType.freeShipping:
        iconData = Icons.local_shipping;
        iconColor = Colors.green;
        break;
      case BenefitType.exclusiveAccess:
        iconData = Icons.stars;
        iconColor = Colors.amber;
        break;
      case BenefitType.gift: // ✅ MAINTENANT DISPONIBLE
        iconData = Icons.card_giftcard;
        iconColor = Colors.red;
        break;
      // ✅ Cas par défaut amélioré
      default:
        iconData = _getIconData(benefit.iconName);
        iconColor = Theme.of(context).primaryColor;
    }
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    benefit.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (benefit.thresholdDescription != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        benefit.thresholdDescription!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                  // ✅ MAINTENANT FONCTIONNE
                  if (!benefit.isUnlimited && benefit.expiryDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Valable jusqu\'au ${_formatDate(benefit.expiryDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'percent':
        return Icons.percent;
      case 'savings':
        return Icons.savings;
      case 'loyalty':
        return Icons.loyalty;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'stars':
        return Icons.stars;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.star;
    }
  }

  // ✅ NOUVELLE MÉTHODE pour formater la date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}