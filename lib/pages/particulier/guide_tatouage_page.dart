// lib/pages/particulier/guide_tatouage_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_particulier.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_particulier.dart';

class GuideTatouagePage extends StatefulWidget {
  const GuideTatouagePage({Key? key}) : super(key: key);

  @override
  State<GuideTatouagePage> createState() => _GuideTatouagePageState();
}

class _GuideTatouagePageState extends State<GuideTatouagePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> _backgroundImages = [
    'assets/images/header_tattoo_wallpaper.png',
    'assets/images/header_tattoo_wallpaper2.png',
    'assets/images/header_tattoo_wallpaper3.png',
  ];
  late String _selectedBackground;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedBackground = _backgroundImages[Random().nextInt(_backgroundImages.length)];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: 'Guide du tatouage',
        showBackButton: true,
        redirectToHome: true,
        showBurger: false,
        showNotificationIcon: true,
      ),
      drawer: const CustomDrawerParticulier(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond avec image aléatoire
          Image.asset(
            _selectedBackground,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          
          // Overlay dégradé
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
          
          Column(
            children: [
              // Header avec tabs
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: KipikTheme.rouge.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: KipikTheme.rouge,
                  indicatorWeight: 3,
                  labelColor: KipikTheme.rouge,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.info_outline, size: 20),
                      text: 'Avant',
                    ),
                    Tab(
                      icon: Icon(Icons.healing, size: 20),
                      text: 'Après',
                    ),
                    Tab(
                      icon: Icon(Icons.palette, size: 20),
                      text: 'Styles',
                    ),
                    Tab(
                      icon: Icon(Icons.help_outline, size: 20),
                      text: 'FAQ',
                    ),
                  ],
                ),
              ),
              
              // Contenu des tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvantTab(),
                    _buildApresTab(),
                    _buildStylesTab(),
                    _buildFAQTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvantTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: '🎯 Préparation mentale',
            icon: Icons.psychology,
            content: [
              'Réfléchis bien au design et à l\'emplacement',
              'Un tatouage est permanent, prends ton temps',
              'Évite les décisions impulsives ou sous influence',
              'Pense à l\'évolution de ton corps dans le temps',
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionCard(
            title: '🔍 Choisir son tatoueur',
            icon: Icons.person_search,
            content: [
              'Vérifie le portfolio et les réalisations',
              'Assure-toi que le salon respecte les normes d\'hygiène',
              'Lis les avis clients et demande des recommandations',
              'N\'hésite pas à rencontrer plusieurs tatoueurs',
              'Vérifie les certifications et licences',
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionCard(
            title: '💰 Budget et timing',
            icon: Icons.account_balance_wallet,
            content: [
              'Prévois un budget réaliste (qualité = prix)',
              'Ne néglige pas les pourboires (10-20%)',
              'Planifie selon la saison (évite l\'été pour certaines zones)',
              'Réserve à l\'avance, les bons tatoueurs sont demandés',
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionCard(
            title: '🚫 Contre-indications',
            icon: Icons.warning,
            content: [
              'Évite l\'alcool 24h avant',
              'Ne prends pas d\'aspirine ou anticoagulants',
              'Évite si tu es malade ou fatigué',
              'Attention aux allergies (encres, latex)',
              'Femmes enceintes : attendre après l\'accouchement',
            ],
            isWarning: true,
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionCard(
            title: '🥗 Préparation physique',
            icon: Icons.fitness_center,
            content: [
              'Mange bien avant la séance',
              'Hydrate-toi correctement',
              'Dors suffisamment la nuit précédente',
              'Porte des vêtements confortables et adaptés',
              'Prépare de quoi t\'occuper (musique, livre)',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApresTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: '🧼 Nettoyage et soins',
            icon: Icons.clean_hands,
            content: [
              'Retire le film plastique après 2-3h',
              'Lave délicatement à l\'eau tiède et savon neutre',
              'Sèche en tamponnant (pas de frottement)',
              'Applique une crème cicatrisante fine',
              'Répète 2-3 fois par jour pendant 2 semaines',
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionCard(
            title: '🚿 Hygiène quotidienne',
            icon: Icons.shower,
            content: [
              'Douches courtes à l\'eau tiède',
              'Évite les bains, piscines, jacuzzis (2 semaines)',
              'Ne gratte jamais, même si ça démange',
              'Porte des vêtements propres et amples',
              'Change régulièrement tes draps',
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionCard(
            title: '☀️ Protection solaire',
            icon: Icons.wb_sunny,
            content: [
              'Évite totalement le soleil les premiers jours',
              'Utilise un écran total (SPF 50+) après cicatrisation',
              'Protège avec des vêtements si possible',
              'Le soleil fait pâlir les couleurs',
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionCard(
            title: '🚨 Signes d\'alerte',
            icon: Icons.emergency,
            content: [
              'Rougeur excessive qui s\'étend',
              'Chaleur anormale de la zone',
              'Pus ou écoulement suspect',
              'Fièvre ou malaise général',
              'Douleur qui s\'aggrave après 48h',
            ],
            isWarning: true,
          ),
          
          const SizedBox(height: 16),
          
          _buildTimelineCard(),
        ],
      ),
    );
  }

  Widget _buildStylesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStyleCard(
            title: 'Réalisme',
            description: 'Portraits, paysages ultra-détaillés',
            features: ['Noir et gris', 'Couleurs réalistes', 'Très détaillé'],
            difficulty: 'Expert',
            duration: '4-8h par séance',
          ),
          
          const SizedBox(height: 16),
          
          _buildStyleCard(
            title: 'Traditionnel',
            description: 'Style old school classique',
            features: ['Traits épais', 'Couleurs vives', 'Motifs iconiques'],
            difficulty: 'Intermédiaire',
            duration: '2-4h par séance',
          ),
          
          const SizedBox(height: 16),
          
          _buildStyleCard(
            title: 'Géométrique',
            description: 'Formes et motifs géométriques',
            features: ['Lignes précises', 'Symétrie', 'Moderne'],
            difficulty: 'Intermédiaire',
            duration: '3-6h par séance',
          ),
          
          const SizedBox(height: 16),
          
          _buildStyleCard(
            title: 'Minimaliste',
            description: 'Designs simples et épurés',
            features: ['Traits fins', 'Peu de couleurs', 'Symbolique'],
            difficulty: 'Débutant',
            duration: '1-2h par séance',
          ),
          
          const SizedBox(height: 16),
          
          _buildStyleCard(
            title: 'Japonais',
            description: 'Art traditionnel du Japon',
            features: ['Grandes pièces', 'Couleurs vives', 'Symbolisme fort'],
            difficulty: 'Expert',
            duration: '6-10h par séance',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFAQCard(
            question: 'Est-ce que ça fait mal ?',
            answer: 'La douleur varie selon la zone et votre seuil de tolérance. '
                   'Les zones osseuses (côtes, chevilles) sont plus sensibles. '
                   'C\'est supportable pour la plupart des gens.',
          ),
          
          const SizedBox(height: 12),
          
          _buildFAQCard(
            question: 'Combien ça coûte ?',
            answer: 'Les prix varient de 80€ à 200€/heure selon le tatoueur. '
                   'Un petit tatouage : 80-150€. Un tatouage moyen : 200-500€. '
                   'Une grande pièce : 800€ et plus.',
          ),
          
          const SizedBox(height: 12),
          
          _buildFAQCard(
            question: 'Combien de temps ça cicatrise ?',
            answer: 'La cicatrisation superficielle prend 2-3 semaines. '
                   'La cicatrisation complète prend 3-6 mois. '
                   'Respecte les soins pour éviter les complications.',
          ),
          
          const SizedBox(height: 12),
          
          _buildFAQCard(
            question: 'Peut-on faire du sport après ?',
            answer: 'Évite le sport intense pendant 1-2 semaines. '
                   'La transpiration et les frottements retardent la cicatrisation. '
                   'Reprends progressivement.',
          ),
          
          const SizedBox(height: 12),
          
          _buildFAQCard(
            question: 'Et si je regrette ?',
            answer: 'Le détatouage au laser est possible mais coûteux et long. '
                   'Plusieurs séances nécessaires (6-15). '
                   'Mieux vaut bien réfléchir avant !',
          ),
          
          const SizedBox(height: 12),
          
          _buildFAQCard(
            question: 'Âge minimum pour un tatouage ?',
            answer: 'En France : 18 ans. Entre 16-18 ans avec autorisation parentale. '
                   'Beaucoup de tatoueurs préfèrent attendre 18 ans pour '
                   'des questions de maturité.',
          ),
          
          const SizedBox(height: 12),
          
          _buildFAQCard(
            question: 'Tatouage et don du sang ?',
            answer: 'Délai de 4 mois après un tatouage en France. '
                   'Vérifie que ton tatoueur respecte les normes d\'hygiène. '
                   'Garde tes certificats de tatouage.',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<String> content,
    bool isWarning = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning 
              ? Colors.orange.withOpacity(0.5)
              : KipikTheme.rouge.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWarning 
                        ? Colors.orange.withOpacity(0.2)
                        : KipikTheme.rouge.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isWarning ? Colors.orange : KipikTheme.rouge,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isWarning ? Colors.orange : KipikTheme.rouge,
                      fontSize: 18,
                      fontFamily: 'PermanentMarker',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Content
            ...content.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: 12),
                    decoration: BoxDecoration(
                      color: isWarning ? Colors.orange : KipikTheme.rouge,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    final steps = [
      {'time': 'Jour 1-3', 'desc': 'Suintement normal, rougeur', 'color': Colors.red},
      {'time': 'Jour 4-7', 'desc': 'Formation de croûtes', 'color': Colors.orange},
      {'time': 'Jour 8-14', 'desc': 'Desquamation, démangeaisons', 'color': Colors.yellow},
      {'time': 'Jour 15-30', 'desc': 'Peau encore sensible', 'color': Colors.blue},
      {'time': '1-3 mois', 'desc': 'Cicatrisation complète', 'color': Colors.green},
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KipikTheme.rouge.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: KipikTheme.rouge, size: 24),
                const SizedBox(width: 12),
                const Text(
                  '📅 Timeline de cicatrisation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: step['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['time'] as String,
                            style: TextStyle(
                              color: step['color'] as Color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['desc'] as String,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleCard({
    required String title,
    required String description,
    required List<String> features,
    required String difficulty,
    required String duration,
  }) {
    Color difficultyColor = difficulty == 'Débutant' ? Colors.green :
                            difficulty == 'Intermédiaire' ? Colors.orange :
                            Colors.red;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KipikTheme.rouge.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: KipikTheme.rouge,
                      fontSize: 20,
                      fontFamily: 'PermanentMarker',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: difficultyColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    difficulty,
                    style: TextStyle(
                      color: difficultyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Features
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map((feature) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: KipikTheme.rouge.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KipikTheme.rouge.withOpacity(0.3)),
                ),
                child: Text(
                  feature,
                  style: TextStyle(
                    color: KipikTheme.rouge,
                    fontSize: 12,
                  ),
                ),
              )).toList(),
            ),
            
            const SizedBox(height: 12),
            
            // Duration
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  duration,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard({
    required String question,
    required String answer,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KipikTheme.rouge.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconColor: KipikTheme.rouge,
        collapsedIconColor: Colors.white70,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}