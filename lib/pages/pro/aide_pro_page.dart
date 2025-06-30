import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// Import des services et modèles pour Kipik
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/services/help_center_service.dart';
import 'package:kipik_v5/models/faq_item.dart';
import 'package:kipik_v5/models/tutorial.dart';
import 'package:kipik_v5/models/pro_user.dart';

// Import de vos widgets personnalisés existants
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_kipik.dart';
import 'package:kipik_v5/utils/constants.dart';
import 'package:kipik_v5/utils/styles.dart';

class AideProPage extends StatefulWidget {
  static const String routeName = '/aide-pro';

  const AideProPage({Key? key}) : super(key: key);

  @override
  _AideProPageState createState() => _AideProPageState();
}

class _AideProPageState extends State<AideProPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<FAQItem> _faqItems = [];
  List<FAQItem> _filteredFaqItems = [];
  List<Tutorial> _tutorials = [];
  List<Tutorial> _filteredTutorials = [];
  ProUser? _currentUser;
  final ScrollController _scrollController = ScrollController();

  // Liste des catégories d'aide
  final List<String> _categories = [
    'Tous',
    'Abonnement',
    'Facturation',
    'Fonctionnalités',
    'Sécurité',
    'Profil',
    'Technique',
    'Légal',
  ];

  String _selectedCategory = 'Tous';
  bool _showContactForm = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _sujetController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    _sujetController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    // Réinitialiser la recherche et le défilement lors du changement d'onglet
    if (_tabController.indexIsChanging) {
      _searchController.clear();
      _scrollController.jumpTo(0);
      _applyFilters('');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final helpCenterService = Provider.of<HelpCenterService>(
        context,
        listen: false,
      );
      final authService = Provider.of<AuthService>(context, listen: false);

      // Charger les données de la FAQ et des tutoriels
      final faqItems = await helpCenterService.getFAQItems(userType: 'pro');
      final tutorials = await helpCenterService.getTutorials(userType: 'pro');
      final currentUser = await authService.getCurrentProUser();

      setState(() {
        _faqItems = faqItems;
        _filteredFaqItems = faqItems;
        _tutorials = tutorials;
        _filteredTutorials = tutorials;
        _currentUser = currentUser;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données d\'aide: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du chargement des données. Veuillez réessayer.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyFilters(String searchTerm) {
    setState(() {
      // Filtrer la FAQ
      _filteredFaqItems = _faqItems.where((item) {
        final matchesSearch =
            searchTerm.isEmpty ||
            item.question.toLowerCase().contains(
                  searchTerm.toLowerCase(),
                ) ||
            item.answer.toLowerCase().contains(searchTerm.toLowerCase());

        final matchesCategory =
            _selectedCategory == 'Tous' || item.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();

      // Filtrer les tutoriels
      _filteredTutorials = _tutorials.where((tutorial) {
        final matchesSearch =
            searchTerm.isEmpty ||
            tutorial.title.toLowerCase().contains(
                  searchTerm.toLowerCase(),
                ) ||
            tutorial.description.toLowerCase().contains(
                  searchTerm.toLowerCase(),
                );

        final matchesCategory =
            _selectedCategory == 'Tous' || tutorial.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _showTutorialDetails(Tutorial tutorial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tutorial.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Catégorie: ${tutorial.category}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    tutorial.description,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Divider(),
            Expanded(
              child: tutorial.videoUrl != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 80,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(height: 16),
                          Text('Cliquez pour lancer la vidéo'),
                          SizedBox(height: 24),
                          // Utiliser un ElevatedButton standard au lieu de TattooAssistantButton
                          ElevatedButton.icon(
                            onPressed: () => _launchUrl(tutorial.videoUrl!),
                            icon: Icon(Icons.play_arrow),
                            label: Text('Regarder le tutoriel'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.all(16),
                      child: Text(
                        tutorial.content ?? 'Contenu non disponible.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () => _shareTutorial(tutorial),
                    tooltip: 'Partager',
                  ),
                  IconButton(
                    icon: Icon(Icons.bookmark_border),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tutoriel sauvegardé')),
                      );
                    },
                    tooltip: 'Sauvegarder',
                  ),
                  IconButton(
                    icon: Icon(Icons.print),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Impression du tutoriel...'),
                        ),
                      );
                    },
                    tooltip: 'Imprimer',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir: $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareTutorial(Tutorial tutorial) {
    Share.share(
      'Découvrez ce tutoriel Kipik Pro: "${tutorial.title}"\n\n${tutorial.description}\n\nVoir plus sur notre application Kipik Pro.',
      subject: 'Tutoriel Kipik Pro: ${tutorial.title}',
    );
  }

  Future<void> _submitContactForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final helpCenterService = Provider.of<HelpCenterService>(
          context,
          listen: false,
        );

        await helpCenterService.submitSupportRequest(
          userId: _currentUser?.id ?? '',
          userEmail: _currentUser?.email ?? '',
          subject: _sujetController.text,
          message: _messageController.text,
          userType: 'pro',
        );

        setState(() {
          _isLoading = false;
          _showContactForm = false;
        });

        _sujetController.clear();
        _messageController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Votre demande a été envoyée avec succès. Notre équipe vous répondra sous 24h.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Erreur lors de l\'envoi du formulaire: $e');
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'envoi du formulaire. Veuillez réessayer.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarKipik(
        title: 'Centre d\'Aide Pro',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(Icons.support_agent),
            onPressed: () {
              setState(() {
                _showContactForm = !_showContactForm;
              });
            },
            tooltip: 'Contacter le support',
          ),
        ],
      ),
      drawer: CustomDrawerKipik(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSearchBar(),
                ),

                // Filtres par catégorie
                Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                              _applyFilters(_searchController.text);
                            }
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.black,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Onglets
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'FAQ'),
                    Tab(text: 'Tutoriels'),
                    Tab(text: 'Contact'),
                  ],
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                ),

                // Corps des onglets
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Onglet FAQ
                      _buildFAQTab(),

                      // Onglet Tutoriels
                      _buildTutorialsTab(),

                      // Onglet Contact
                      _buildContactTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Création d'une barre de recherche personnalisée
  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _applyFilters(value);
        },
        decoration: InputDecoration(
          hintText: 'Rechercher dans l\'aide...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kDefaultBorderRadius),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFAQTab() {
    if (_filteredFaqItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/no_results.svg',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _filteredFaqItems.length,
      itemBuilder: (context, index) {
        final item = _filteredFaqItems[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ExpansionTile(
            title: Text(
              item.question,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Catégorie: ${item.category}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            leading: Icon(
              Icons.question_answer,
              color: Theme.of(context).primaryColor,
            ),
            childrenPadding: EdgeInsets.all(16),
            children: [
              Text(item.answer, style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              if (item.relatedLinks.isNotEmpty) ...[
                Divider(),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liens utiles:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...item.relatedLinks
                          .map(
                            (link) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: InkWell(
                                onTap: () => _launchUrl(link.url),
                                child: Text(
                                  link.label,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ],
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.thumb_up_alt_outlined),
                    label: Text('Utile'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Merci pour votre retour!')),
                      );
                    },
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.thumb_down_alt_outlined),
                    label: Text('Pas utile'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Désolé que cette réponse ne vous ait pas aidé',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTutorialsTab() {
    if (_filteredTutorials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/no_results.svg',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun tutoriel trouvé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredTutorials.length,
      itemBuilder: (context, index) {
        final tutorial = _filteredTutorials[index];
        return InkWell(
          onTap: () => _showTutorialDetails(tutorial),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: tutorial.thumbnailUrl != null
                        ? Image.network(
                            tutorial.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey[500],
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              tutorial.videoUrl != null
                                  ? Icons.play_circle_filled
                                  : Icons.article,
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        tutorial.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      // Catégorie
                      Text(
                        tutorial.category,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      // Description
                      Text(
                        tutorial.description,
                        style: TextStyle(fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Spacer(),
                // Badge de type
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tutorial.videoUrl != null
                              ? Colors.red.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tutorial.videoUrl != null
                                  ? Icons.videocam
                                  : Icons.article,
                              size: 12,
                              color: tutorial.videoUrl != null
                                  ? Colors.red
                                  : Colors.blue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              tutorial.videoUrl != null ? 'Vidéo' : 'Article',
                              style: TextStyle(
                                fontSize: 10,
                                color: tutorial.videoUrl != null
                                    ? Colors.red
                                    : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      },
    );
  }

  Widget _buildContactTab() {
    if (_showContactForm) {
      return SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contactez notre équipe de support',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Complétez le formulaire ci-dessous et notre équipe vous répondra sous 24h.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24),

              // Informations de contact
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations de contact',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.business),
                        title: Text('Entreprise'),
                        subtitle: Text(
                          _currentUser?.nomEntreprise ?? 'Non disponible',
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: Icon(Icons.email),
                        title: Text('Adresse e-mail'),
                        subtitle: Text(_currentUser?.email ?? 'Non disponible'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: Icon(Icons.card_membership),
                        title: Text('Type d\'abonnement'),
                        subtitle: Text(
                          _currentUser?.abonnementType ?? 'Standard',
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Formulaire de contact
              TextFormField(
                controller: _sujetController,
                decoration: InputDecoration(
                  labelText: 'Sujet *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un sujet';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre message';
                  }
                  if (value.length < 10) {
                    return 'Le message doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              CheckboxListTile(
                title: Text(
                  'Joindre les informations de diagnostic (recommandé)',
                ),
                subtitle: Text(
                  'Nos équipes pourront mieux vous aider avec ces informations.',
                ),
                value: true,
                onChanged: (value) {},
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 24),
              // Remplacé TattooAssistantButton par un ElevatedButton standard
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitContactForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.0,
                          ),
                        )
                      : Text(
                          'Envoyer ma demande',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 32),

              // Autres moyens de contact
              Text(
                'Autres moyens de nous contacter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[50],
                        child: Icon(Icons.phone, color: Colors.blue),
                      ),
                      title: Text('Téléphone'),
                      subtitle: Text('+33 1 23 45 67 89'),
                      trailing: IconButton(
                        icon: Icon(Icons.call),
                        onPressed: () => _launchUrl('tel:+33123456789'),
                      ),
                    ),
                    Divider(),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[50],
                        child: Icon(Icons.message, color: Colors.green), // Utilisé 'message' au lieu de 'whatsapp'
                      ),
                      title: Text('WhatsApp'),
                      subtitle: Text('Chat avec notre équipe'),
                      trailing: IconButton(
                        icon: Icon(Icons.launch), // Utilisé 'launch' au lieu de 'open_in_new'
                        onPressed: () => _launchUrl('https://wa.me/33123456789'),
                      ),
                    ),
                    Divider(),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple[50],
                        child: Icon(Icons.forum, color: Colors.purple),
                      ),
                      title: Text('Communauté Kipik'),
                      subtitle: Text('Discutez avec d\'autres utilisateurs'),
                      trailing: IconButton(
                        icon: Icon(Icons.launch), // Utilisé 'launch' au lieu de 'open_in_new'
                        onPressed: () => _launchUrl('https://communaute.kipik.fr'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/support.svg',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 24),
            Text(
              'Comment pouvons-nous vous aider?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Notre équipe de support est disponible pour répondre à vos questions',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            // Remplacé TattooAssistantButton par un ElevatedButton.icon standard
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showContactForm = true;
                });
              },
              icon: Icon(Icons.support_agent),
              label: Text('Contacter le support'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              icon: Icon(Icons.schedule),
              label: Text('Programmer un appel'),
              onPressed: () {
                Navigator.of(context).pushNamed('/schedule-call');
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSupportOption(
                  icon: Icons.public,
                  label: 'Site Web',
                  onTap: () => _launchUrl('https://www.kipik.fr'),
                ),
                _buildSupportOption(
                  icon: Icons.email,
                  label: 'Email',
                  onTap: () => _launchUrl('mailto:support@kipik.fr'),
                ),
                _buildSupportOption(
                  icon: Icons.forum,
                  label: 'Forum',
                  onTap: () => _launchUrl('https://forum.kipik.fr'),
                ),
                _buildSupportOption(
                  icon: Icons.chat,
                  label: 'Chat',
                  onTap: () {
                    // Ouvrir le chat en direct
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ouverture du chat en direct...')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 24),
              SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}