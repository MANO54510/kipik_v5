// partner_supplier_card.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/models/supplier_model.dart';

class PartnerSupplierCard extends StatelessWidget {
  final SupplierModel supplier;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const PartnerSupplierCard({
    Key? key,
    required this.supplier,
    required this.onTap,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bandeau partenaire
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Partenaire officiel Kipik',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (supplier.cashbackPercentage != null) ...[
                    Text(
                      '${supplier.cashbackPercentage!.toStringAsFixed(0)}% Cashback', // ✅ ! ajouté
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo du fournisseur
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      // ✅ Gestion d'image améliorée
                      image: supplier.logoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(supplier.logoUrl!),
                              fit: BoxFit.cover,
                              onError: (error, stackTrace) {
                                // En cas d'erreur, afficher une icône par défaut
                              },
                            )
                          : null,
                    ),
                    child: supplier.logoUrl == null
                        ? Icon(
                            Icons.business,
                            size: 32,
                            color: Colors.grey[400],
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Informations du fournisseur
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // ✅ Gestion du String nullable
                        if (supplier.description != null && supplier.description!.isNotEmpty)
                          Text(
                            supplier.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),
                        // Categories
                        if (supplier.categories.isNotEmpty) // ✅ Vérification ajoutée
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: supplier.categories.map((category) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  // Bouton favori
                  IconButton(
                    icon: Icon(
                      supplier.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: supplier.isFavorite ? Colors.red : Colors.grey[600], // ✅ Couleur par défaut ajoutée
                    ),
                    onPressed: onFavoriteToggle,
                  ),
                ],
              ),
            ),
            
            // Avantages partenaires
            if (supplier.benefits != null && supplier.benefits!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vos avantages',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ✅ Gestion améliorée des avantages
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Afficher max 3 avantages en ligne
                          for (int i = 0; i < supplier.benefits!.length && i < 3; i++)
                            _buildBenefitBadge(supplier.benefits![i], context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitBadge(PartnershipBenefit benefit, BuildContext context) {
    // Déterminer l'icône selon le type d'avantage
    IconData iconData = Icons.star;
    
    switch (benefit.type) {
      case BenefitType.discount:
        iconData = Icons.percent;
        break;
      case BenefitType.cashback:
        iconData = Icons.savings;
        break;
      case BenefitType.loyalty:
        iconData = Icons.loyalty;
        break;
      case BenefitType.freeShipping:
        iconData = Icons.local_shipping;
        break;
      case BenefitType.exclusiveAccess:
        iconData = Icons.stars;
        break;
      case BenefitType.gift:
        iconData = Icons.card_giftcard;
        break;
      default:
        iconData = Icons.star;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // ✅ Padding ajusté
      margin: const EdgeInsets.only(right: 8),
      constraints: const BoxConstraints(minWidth: 80), // ✅ Largeur minimum
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, // ✅ Centrage ajouté
        children: [
          Icon(
            iconData,
            size: 14,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Flexible( // ✅ Expanded changé en Flexible
            child: Text(
              _getBenefitShortText(benefit),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center, // ✅ Centrage du texte
            ),
          ),
        ],
      ),
    );
  }
  
  String _getBenefitShortText(PartnershipBenefit benefit) {
    switch (benefit.type) {
      case BenefitType.discount:
        return '${benefit.value.toStringAsFixed(0)}% Remise';
      case BenefitType.cashback:
        return '${benefit.value.toStringAsFixed(0)}% Cashback';
      case BenefitType.loyalty:
        return 'Programme Fidélité';
      case BenefitType.freeShipping:
        return 'Livraison Gratuite';
      case BenefitType.exclusiveAccess:
        return 'Accès Exclusif';
      case BenefitType.gift:
        return 'Cadeau Offert';
      default:
        return benefit.title;
    }
  }
}