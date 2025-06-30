import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';

class CGUPage extends StatefulWidget {
  const CGUPage({super.key});

  @override
  State<CGUPage> createState() => _CGUPageState();
}

class _CGUPageState extends State<CGUPage> {
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
        title: "Conditions Générales d'Utilisation",
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
Bienvenue sur KIPIK !

Les présentes Conditions Générales d’Utilisation (ci-après "CGU") encadrent juridiquement l’utilisation de l'application KIPIK. Elles s’appliquent à tout utilisateur, qu’il soit professionnel ou particulier.

1. Acceptation des conditions
En utilisant KIPIK, vous acceptez sans réserve les présentes CGU. Si vous êtes en désaccord avec l’un de leurs termes, vous êtes libre de ne pas utiliser nos services.

2. Objet de l'application
KIPIK est une plateforme facilitant la mise en relation entre tatoueurs professionnels et particuliers. Elle permet la création de projets de tatouage, la gestion de rendez-vous, de devis, de paiements, d’e-shop et de communication entre les parties.

3. Accès au service
L’accès à l’application est possible 24h/24 et 7j/7 sauf interruption pour maintenance ou cas de force majeure. Les utilisateurs sont responsables de la sécurité de leurs identifiants.

4. Obligations de l’utilisateur
L’utilisateur s’engage à fournir des informations exactes lors de son inscription. Il est seul responsable du contenu qu’il diffuse, notamment les images, descriptions et messages échangés.

5. Données personnelles
KIPIK collecte des données personnelles pour permettre le fonctionnement optimal de la plateforme. Ces données sont traitées conformément au RGPD. L’utilisateur dispose d’un droit d’accès, de rectification et de suppression de ses données.

6. Propriété intellectuelle
L’ensemble des éléments (textes, images, logos, design, code, etc.) présents sur KIPIK sont protégés par les lois en vigueur sur la propriété intellectuelle. Toute reproduction, modification ou diffusion sans autorisation est strictement interdite.

7. Responsabilité
KIPIK ne peut être tenu responsable des dommages directs ou indirects liés à l’utilisation de l’application. Les utilisateurs restent seuls responsables des engagements contractuels ou financiers qu’ils prennent entre eux via la plateforme.

8. Modifications des CGU
KIPIK se réserve le droit de modifier à tout moment les présentes CGU. L’utilisateur sera informé de toute modification majeure via l’application.

9. Droit applicable
Les présentes CGU sont soumises au droit français. En cas de litige, une solution amiable sera recherchée. À défaut, les tribunaux compétents seront ceux du ressort de la société éditrice.

Merci d’utiliser KIPIK.
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
                      "J’ai lu et j’accepte les CGU",
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
