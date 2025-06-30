import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import 'accueil_particulier_page.dart';

class AideSupportPage extends StatefulWidget {
  const AideSupportPage({Key? key}) : super(key: key);

  @override
  State<AideSupportPage> createState() => _AideSupportPageState();
}

class _AideSupportPageState extends State<AideSupportPage> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'Comment prendre rendez-vous avec un tatoueur ?',
      answer:
          'Pour prendre rendez-vous avec un tatoueur, parcourez la liste des artistes disponibles, consultez leur profil et leurs créations. Sélectionnez ensuite "Demander un devis" sur leur profil. Vous pourrez décrire votre projet, envoyer des références et convenir d\'une date pour discuter des détails de votre tatouage.',
    ),
    FAQItem(
      question: 'Comment fonctionne le système de devis ?',
      answer:
          'Le système de devis permet aux tatoueurs d\'évaluer votre projet et de vous proposer un tarif. Après avoir soumis votre demande, le tatoueur vous répond généralement sous 48h avec un prix estimé, une durée de réalisation et des disponibilités. Vous pouvez alors accepter le devis ou continuer à chercher d\'autres artistes.',
    ),
    FAQItem(
      question: 'Puis-je annuler ou modifier mon rendez-vous ?',
      answer:
          'Oui, vous pouvez modifier ou annuler votre rendez-vous jusqu\'à 48h avant la date prévue sans frais. Pour cela, accédez à la section "Mes rendez-vous" dans votre profil et sélectionnez le rendez-vous concerné. Toute annulation moins de 48h avant la session peut entraîner des frais selon la politique du tatoueur.',
    ),
    FAQItem(
      question: 'Comment sont sécurisés mes paiements ?',
      answer:
          'Tous les paiements effectués via Kipik sont sécurisés par un système de cryptage SSL. Nous n\'enregistrons jamais vos informations bancaires. Le paiement d\'arrhes est débité uniquement lorsque le tatoueur accepte votre demande, et le solde n\'est versé à l\'artiste qu\'une fois la prestation terminée et validée par vos soins.',
    ),
    FAQItem(
      question: 'Que faire en cas de souci avec un tatoueur ?',
      answer:
          'Si vous rencontrez un problème avec un tatoueur, nous vous encourageons d\'abord à communiquer directement avec l\'artiste via notre messagerie intégrée. Si le problème persiste, contactez notre service client via l\'option "Signaler un problème" accessible depuis la conversation ou le profil du tatoueur. Notre équipe de modération interviendra sous 24h.',
    ),
    FAQItem(
      question: 'Comment devenir tatoueur sur Kipik ?',
      answer:
          'Pour rejoindre Kipik en tant que tatoueur professionnel, vous devez disposer d\'un numéro SIRET valide, d\'une attestation de formation en hygiène et d\'un book représentatif de votre travail. Rendez-vous sur kipik.com/devenir-tatoueur et soumettez votre candidature. Notre équipe l\'examinera et vous recontactera sous 5 jours ouvrés.',
    ),
    FAQItem(
      question: 'Comment trouver de l\'inspiration pour mon tatouage ?',
      answer:
          'Kipik propose une section "Inspirations" où vous pouvez parcourir des milliers de créations classées par styles, zones du corps et thèmes. Vous pouvez sauvegarder vos designs préférés dans vos "Favoris" et les partager avec les tatoueurs lors de votre demande de devis. Nous organisons également des événements thématiques chaque mois pour découvrir de nouveaux styles.',
    ),
  ];

  final List<String> _backgroundImages = [
    'assets/background_charbon.png',
    'assets/background_tatoo1.png',
    'assets/background_tatoo2.png',
    'assets/background_tatoo3.png',
  ];

  late String _selectedBackground;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _selectedBackground =
        _backgroundImages[Random().nextInt(_backgroundImages.length)];
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@kipik.com',
      queryParameters: {
        'subject': 'Demande d\'assistance Kipik',
      },
    );
    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLiveChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Chat en direct',
          style: TextStyle(
            color: KipikTheme.blanc,
            fontFamily: KipikTheme.fontTitle,
          ),
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat, size: 60, color: KipikTheme.rouge),
              const SizedBox(height: 16),
              Text(
                'Notre service de chat en direct sera disponible début juin 2025. '
                'En attendant, n\'hésitez pas à nous contacter par email.',
                style: TextStyle(color: KipikTheme.blanc.withOpacity(0.9)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: KipikTheme.rouge)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchEmail();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Envoyer un email', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: 'Aide & Support',
        showBackButton: true,
        redirectToHome: true,
        showBurger: false,
        showNotificationIcon: false,
        onBackButtonPressed: () {
          // Navigation directe vers la page d'accueil
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AccueilParticulierPage(),
            ),
            (route) => false,
          );
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond aléatoire
          Image.asset(
            _selectedBackground,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Contenu
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16, right: 16, top: 20, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Besoin d'aide
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: KipikTheme.rouge.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Besoin d\'aide ?',
                          style: TextStyle(
                            fontFamily: KipikTheme.fontTitle,
                            fontSize: 24,
                            color: KipikTheme.blanc,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Notre équipe est disponible 7j/7 pour vous aider dans votre expérience de tatouage.',
                          style: TextStyle(
                            color: KipikTheme.blanc.withOpacity(0.9),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSupportOption(
                                icon: Icons.email_outlined,
                                title: 'Email',
                                subtitle: 'support@kipik.com',
                                onTap: _launchEmail,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSupportOption(
                                icon: Icons.chat_bubble_outline,
                                title: 'Chat',
                                subtitle: 'Disponible 9h-18h',
                                onTap: _showLiveChatDialog,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // FAQ
                  _buildAnimatedSectionHeader('Questions fréquentes', Icons.help_outline),
                  const SizedBox(height: 15),
                  ...List.generate(
                    _faqItems.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildFAQItem(index),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSectionHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KipikTheme.rouge.withOpacity(0.3),
            KipikTheme.rouge.withOpacity(0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KipikTheme.rouge.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: KipikTheme.rouge, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white, fontSize: 18, fontFamily: 'PermanentMarker'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KipikTheme.rouge.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: KipikTheme.rouge, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(int index) {
    final faq = _faqItems[index];
    final isExpanded = _expandedIndex == index;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? KipikTheme.rouge.withOpacity(0.5)
              : Colors.white10,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _expandedIndex = isExpanded ? null : index;
          }),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.remove_circle : Icons.add_circle,
                      color: isExpanded ? KipikTheme.rouge : Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        faq.question,
                        style: TextStyle(
                          color: isExpanded ? KipikTheme.rouge : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 32, right: 8),
                    child: Text(
                      faq.answer,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;
  FAQItem({required this.question, required this.answer});
}