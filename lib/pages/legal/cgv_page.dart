import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';

class CGVPage extends StatefulWidget {
  const CGVPage({super.key});

  @override
  State<CGVPage> createState() => _CGVPageState();
}

class _CGVPageState extends State<CGVPage> {
  bool hasScrolledToBottom = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent) {
        setState(() => hasScrolledToBottom = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final selectedBackground = backgrounds[Random().nextInt(backgrounds.length)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: "Conditions Générales de Vente",
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(selectedBackground, fit: BoxFit.cover),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24.0),
                    child: const Text(
                      '''
Conditions Générales de Vente (CGV) – Version 1

1. Objet du contrat

L’abonnement donne accès à des fonctionnalités professionnelles telles que la gestion de projets, de devis, de paiements, de l’agenda, des stocks, d’un e-shop intégré, du transfert Instagram, de la comptabilité, etc.

2. Tarifs

Le prix mensuel est de 79 € TTC pour les 100 premiers abonnés, puis 99 € TTC par mois. Les prix sont exprimés en euros toutes taxes comprises (TTC).

3. Formule d’essai

Une seule fois, un tatoueur peut bénéficier d’un test de 3 mois, facturé immédiatement par mandat SEPA à hauteur de 3 × 79 € TTC (ou 3 × 99 € TTC pour les suivants). Si aucune désinscription n’est effectuée au moins 15 jours avant la fin de la période d’essai via le compte ou par écrit, l’abonnement annuel est automatiquement activé.

4. Engagement annuel

En dehors de l’essai, tout abonnement est annuel, avec prélèvement mensuel automatique via SEPA. L’abonnement est reconduit tacitement chaque année.

5. Résiliation

Le professionnel peut résilier son abonnement en envoyant une demande écrite (mail ou courrier) au moins un mois avant la date d’anniversaire de son contrat. À défaut, l’abonnement est reconduit pour une nouvelle période annuelle.

6. Moyens de paiement

Les paiements sont effectués exclusivement via prélèvement SEPA. L’utilisateur est tenu de fournir ses informations bancaires de manière sécurisée à l’inscription.

7. Parrainage

Tout professionnel parrainant un autre tatoueur via son lien personnel bénéficie d’un mois offert sur son prochain abonnement annuel, sous condition que le filleul s’abonne effectivement.

8. Propriété et services

Le logiciel KIPIK reste la propriété exclusive de la société éditrice. L’utilisateur dispose d’un droit d’utilisation personnel, non exclusif et non cessible.

9. Modification des CGV

KIPIK se réserve le droit de modifier les présentes CGV. L’utilisateur en sera informé par voie électronique ou dans l’application.

10. Litiges

Les CGV sont régies par le droit français. En cas de litige, une solution amiable sera privilégiée. À défaut, le tribunal compétent sera celui du ressort du siège de la société éditrice.

Merci d’avoir choisi KIPIK !
                      ''',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: hasScrolledToBottom ? () => Navigator.pop(context, true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasScrolledToBottom ? Colors.redAccent : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "J’ai lu et j’accepte les CGV",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
