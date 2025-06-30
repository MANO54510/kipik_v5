// lib/pages/admin/users/admin_user_search_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/pages/admin/users/admin_user_detail_page.dart';

class AdminUserSearchPage extends StatefulWidget {
  const AdminUserSearchPage({Key? key}) : super(key: key);

  @override
  State<AdminUserSearchPage> createState() => _AdminUserSearchPageState();
}

class _AdminUserSearchPageState extends State<AdminUserSearchPage> {
  final _searchController = TextEditingController();
  String _selectedUserType = 'all';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Données simulées d'utilisateurs (à remplacer par API)
  final List<Map<String, dynamic>> _allUsers = [
    {
      'id': 'pro_001',
      'name': 'Marie Dubois',
      'email': 'marie@studioink.com',
      'type': 'pro',
      'shopName': 'Studio Ink Paris',
      'status': 'active',
      'lastLogin': DateTime.now().subtract(const Duration(hours: 2)),
      'totalRevenue': 8420.50,
      'projectsCount': 45,
      'isVerified': true,
    },
    {
      'id': 'pro_002',
      'name': 'Thomas Martin',
      'email': 'thomas@blackneedle.fr',
      'type': 'pro',
      'shopName': 'Black Needle Studio',
      'status': 'active',
      'lastLogin': DateTime.now().subtract(const Duration(days: 1)),
      'totalRevenue': 5240.00,
      'projectsCount': 28,
      'isVerified': true,
    },
    {
      'id': 'client_001',
      'name': 'Lucas Martin',
      'email': 'lucas.martin@gmail.com',
      'type': 'client',
      'status': 'active',
      'lastLogin': DateTime.now().subtract(const Duration(minutes: 30)),
      'totalSpent': 755.50,
      'projectsCount': 3,
      'isVerified': true,
    },
    {
      'id': 'client_002',
      'name': 'Sophie Laurent',
      'email': 'sophie.laurent@gmail.com',
      'type': 'client',
      'status': 'active',
      'lastLogin': DateTime.now().subtract(const Duration(hours: 6)),
      'totalSpent': 1240.00,
      'projectsCount': 5,
      'isVerified': false,
    },
    {
      'id': 'organizer_001',
      'name': 'EventCorp SAS',
      'email': 'contact@eventcorp.fr',
      'type': 'organizer',
      'organizerName': 'Jean-Pierre Moreau',
      'status': 'active',
      'lastLogin': DateTime.now().subtract(const Duration(days: 2)),
      'totalRevenue': 45200.0,
      'eventsCount': 8,
      'isVerified': true,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simuler une recherche avec délai
    await Future.delayed(const Duration(milliseconds: 500));

    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> results = _allUsers.where((user) {
      // Filtrer par type d'utilisateur si spécifié
      if (_selectedUserType != 'all' && user['type'] != _selectedUserType) {
        return false;
      }

      // Recherche dans le nom, email, shopName
      return user['name'].toLowerCase().contains(query) ||
             user['email'].toLowerCase().contains(query) ||
             (user['shopName']?.toLowerCase().contains(query) ?? false) ||
             (user['organizerName']?.toLowerCase().contains(query) ?? false);
    }).toList();

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarKipik(
        title: 'Recherche Utilisateurs',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barre de recherche
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                children: [
                  // Champ de recherche
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(fontFamily: 'Roboto'),
                    decoration: InputDecoration(
                      labelText: 'Rechercher par nom, email, shop...',
                      labelStyle: const TextStyle(fontFamily: 'Roboto'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch();
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      hintText: 'Ex: Marie, studio@email.com, Black Needle...',
                      hintStyle: const TextStyle(fontFamily: 'Roboto'),
                    ),
                    onChanged: (value) => _performSearch(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Filtres par type
                  Row(
                    children: [
                      const Text(
                        'Type d\'utilisateur:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [
                            _buildFilterChip('Tous', 'all'),
                            _buildFilterChip('Tatoueurs', 'pro'),
                            _buildFilterChip('Clients', 'client'),
                            _buildFilterChip('Organisateurs', 'organizer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Résultats de recherche
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _selectedUserType == value;
    Color chipColor = value == 'pro' ? KipikTheme.rouge :
                     value == 'client' ? Colors.blue :
                     value == 'organizer' ? Colors.purple : Colors.grey;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : chipColor,
          fontFamily: 'Roboto',
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedUserType = value;
        });
        _performSearch();
      },
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Commencez à taper pour rechercher un utilisateur',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Recherchez par nom, email, nom de shop...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun utilisateur trouvé',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier votre recherche',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    Color typeColor = user['type'] == 'pro' ? KipikTheme.rouge :
                     user['type'] == 'client' ? Colors.blue : Colors.purple;
    
    IconData typeIcon = user['type'] == 'pro' ? Icons.brush :
                       user['type'] == 'client' ? Icons.person : Icons.business;

    String typeLabel = user['type'] == 'pro' ? 'Tatoueur' :
                      user['type'] == 'client' ? 'Client' : 'Organisateur';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openUserProfile(user),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar avec type
              CircleAvatar(
                radius: 30,
                backgroundColor: typeColor.withOpacity(0.2),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: 30,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations utilisateur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PermanentMarker',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: typeColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      user['email'],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Informations spécifiques par type
                    if (user['type'] == 'pro') ...[
                      Text(
                        user['shopName'] ?? 'Shop non renseigné',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.euro, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${user['totalRevenue']}€',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.work, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${user['projectsCount']} projets',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ] else if (user['type'] == 'client') ...[
                      Row(
                        children: [
                          Icon(Icons.shopping_cart, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${user['totalSpent']}€ dépensés',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.work, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${user['projectsCount']} projets',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ] else if (user['type'] == 'organizer') ...[
                      if (user['organizerName'] != null)
                        Text(
                          'Contact: ${user['organizerName']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.euro, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${user['totalRevenue']}€',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.event, size: 14, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            '${user['eventsCount']} événements',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Status et dernière connexion
                    Row(
                      children: [
                        _buildStatusDot(user['status']),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(user['status']),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getStatusColor(user['status']),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const Spacer(),
                        if (user['isVerified'] == true) ...[
                          Icon(Icons.verified, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          const Text(
                            'Vérifié',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          _formatLastLogin(user['lastLogin']),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Flèche d'accès
              Icon(
                Icons.arrow_forward_ios,
                color: typeColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(String status) {
    Color color = _getStatusColor(status);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.red;
      case 'inactive':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'suspended':
        return 'Suspendu';
      case 'inactive':
        return 'Inactif';
      default:
        return 'Inconnu';
    }
  }

  String _formatLastLogin(DateTime lastLogin) {
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${lastLogin.day}/${lastLogin.month}/${lastLogin.year}';
    }
  }

  void _openUserProfile(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserDetailPage(
          userId: user['id'],
          userType: user['type'],
        ),
      ),
    );
  }
}