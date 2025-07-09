// lib/pages/shared/flashs/flash_detail_page.dart

import 'package:flutter/material.dart';
import '../../../theme/kipik_theme.dart';
import '../../../models/flash/flash.dart';
import '../../../services/flash/flash_service.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../../models/user_role.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart'; // ✅ Import correct
import '../booking/booking_flow_page.dart'; // ✅ Import pour la réservation

class FlashDetailPage extends StatefulWidget {
  final String? flashId;
  final Flash? flash;

  const FlashDetailPage({
    Key? key,
    this.flashId,
    this.flash,
  }) : super(key: key);

  @override
  State<FlashDetailPage> createState() => _FlashDetailPageState();
}

class _FlashDetailPageState extends State<FlashDetailPage> {
  final FlashService _flashService = FlashService.instance;
  final PageController _imagePageController = PageController();
  
  Flash? _flash;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isProcessing = false;
  UserRole? _currentUserRole;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    _getCurrentUserRole();
    
    if (widget.flash != null) {
      _flash = widget.flash;
      _isLoading = false;
      await _checkIfFavorite();
    } else if (widget.flashId != null) {
      await _loadFlash();
    }
    
    setState(() {});
  }

  void _getCurrentUserRole() {
    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser != null && currentUser.containsKey('role')) {
      final roleString = currentUser['role'] as String?;
      if (roleString == 'tatoueur') {
        _currentUserRole = UserRole.tatoueur;
      } else {
        _currentUserRole = UserRole.particulier;
      }
    }
  }

  Future<void> _loadFlash() async {
    try {
      final flash = await _flashService.getFlashById(widget.flashId!);
      setState(() {
        _flash = flash;
        _isLoading = false;
      });
      
      await _checkIfFavorite();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement du flash');
    }
  }

  Future<void> _checkIfFavorite() async {
    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser == null || _flash == null) return;

    try {
      // ✅ Simulation - remplacez par votre logique de favoris
      setState(() {
        _isFavorite = false; // Valeur par défaut
      });
    } catch (e) {
      // Ignore les erreurs de vérification favori
    }
  }

  Future<void> _toggleFavorite() async {
    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser == null || _flash == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // ✅ Simulation - remplacez par votre logique de favoris
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _isFavorite = !_isFavorite;
        _isProcessing = false;
      });

      _showSuccessSnackBar(
        _isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorSnackBar('Erreur lors de la mise à jour');
    }
  }

  void _handleBooking() {
    if (_flash == null) return;

    if (_currentUserRole == UserRole.tatoueur) {
      _showContactDialog();
    } else {
      _startBookingFlow();
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Contacter l\'artiste',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Voulez-vous contacter ${_flash!.tattooArtistName} pour une collaboration ?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showInfoSnackBar('Contact artiste - Bientôt disponible');
            },
            style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
            child: const Text('Contacter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startBookingFlow() {
    if (!_isFlashBookable()) {
      _showErrorSnackBar('Ce flash n\'est plus disponible pour réservation');
      return;
    }

    // ✅ Navigation vers le flux de réservation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingFlowPage(flash: _flash!),
      ),
    );
  }

  bool _isFlashBookable() {
    if (_flash == null) return false;
    return _flash!.status == FlashStatus.published;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KipikTheme.rouge,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: CustomAppBarKipik(
          title: 'Flash',
          showBackButton: true,
          useProStyle: false,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: KipikTheme.rouge,
          ),
        ),
      );
    }

    if (_flash == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: CustomAppBarKipik(
          title: 'Flash',
          showBackButton: true,
          useProStyle: false,
        ),
        body: const Center(
          child: Text(
            'Flash introuvable',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: _flash!.title,
        showBackButton: true,
        useProStyle: false,
        actions: [
          // Bouton favori dans l'AppBar
          IconButton(
            onPressed: _isProcessing ? null : _toggleFavorite,
            icon: _isProcessing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KipikTheme.rouge,
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? KipikTheme.rouge : Colors.white,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            _buildImageSection(),
            
            // Informations principales
            _buildMainInfoSection(),
            
            // Détails du flash
            _buildDetailsSection(),
            
            // Actions selon le rôle
            _buildActionsSection(),
            
            const SizedBox(height: 100), // Espace pour FAB
          ],
        ),
      ),
      
      // Bouton d'action flottant
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildImageSection() {
    final allImages = [_flash!.imageUrl];
    // ✅ Ajout sécurisé des images additionnelles si elles existent
    if (_flash!.imageUrl.isNotEmpty) {
      // Simuler des images additionnelles pour la démo
      allImages.addAll([
        _flash!.imageUrl, // Dupliquer pour la démo
      ]);
    }
    
    return Container(
      height: 400,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imagePageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: allImages.length,
            itemBuilder: (context, index) {
              return Image.network(
                allImages[index],
                width: double.infinity,
                height: 400,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 400,
                  color: const Color(0xFF2A2A2A),
                  child: Icon(
                    Icons.image,
                    color: Colors.grey.shade600,
                    size: 80,
                  ),
                ),
              );
            },
          ),
          
          // Indicateurs de page
          if (allImages.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  allImages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentImageIndex 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec prix
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _flash!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _flash!.tattooArtistName,
                      style: TextStyle(
                        fontSize: 16,
                        color: KipikTheme.rouge,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_flash!.price.toInt()}€', // ✅ Prix simplifié
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: KipikTheme.rouge,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Badges de statut
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              // Badge statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getStatusColor().withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(),
                      size: 14,
                      color: _getStatusColor(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Badge taille
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  _flash!.size,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Badge style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Text(
                  _flash!.style,
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Description
          if (_flash!.description.isNotEmpty)
            Text(
              _flash!.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_flash!.status) {
      case FlashStatus.published:
        return Colors.green;
      case FlashStatus.reserved:
        return Colors.orange;
      case FlashStatus.booked:
        return Colors.blue;
      case FlashStatus.completed:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_flash!.status) {
      case FlashStatus.published:
        return Icons.check_circle;
      case FlashStatus.reserved:
        return Icons.schedule;
      case FlashStatus.booked:
        return Icons.event_busy;
      case FlashStatus.completed:
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  String _getStatusText() {
    switch (_flash!.status) {
      case FlashStatus.published:
        return 'Disponible';
      case FlashStatus.reserved:
        return 'Réservé';
      case FlashStatus.booked:
        return 'Réservé';
      case FlashStatus.completed:
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails du flash',
            style: TextStyle(
              color: KipikTheme.rouge,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Taille
          _buildDetailRow(Icons.straighten, 'Taille', _flash!.size),
          
          // Style
          _buildDetailRow(Icons.style, 'Style', _flash!.style),
          
          // Studio
          _buildDetailRow(Icons.store, 'Studio', _flash!.studioName),
          
          // Localisation
          _buildDetailRow(Icons.location_on, 'Ville', _flash!.city),
          
          // Artiste
          _buildDetailRow(Icons.person, 'Artiste', _flash!.tattooArtistName),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  Widget _buildActionsSection() {
    final currentUser = SecureAuthService.instance.currentUser;
    final isOwner = currentUser != null && 
                   _flash!.tattooArtistId == currentUser['uid'];
    
    if (_currentUserRole == UserRole.tatoueur && isOwner) {
      // Actions pour le propriétaire du flash
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre flash',
              style: TextStyle(
                color: KipikTheme.rouge,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Flash créé avec succès. Les statistiques de vues et réservations apparaîtront ici.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildFloatingActionButton() {
    final currentUser = SecureAuthService.instance.currentUser;
    final isOwner = currentUser != null && 
                   _flash!.tattooArtistId == currentUser['uid'];
    
    if (_currentUserRole == UserRole.tatoueur && isOwner) {
      // Bouton pour le propriétaire
      return FloatingActionButton.extended(
        onPressed: () => _showInfoSnackBar('Gestion flash - Bientôt disponible'),
        backgroundColor: KipikTheme.rouge,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'Gérer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      // Bouton pour les autres utilisateurs
      final isBookable = _isFlashBookable();
      
      return FloatingActionButton.extended(
        onPressed: isBookable ? _handleBooking : null,
        backgroundColor: isBookable ? KipikTheme.rouge : Colors.grey,
        icon: Icon(
          _currentUserRole == UserRole.tatoueur ? Icons.message : Icons.calendar_today,
          color: Colors.white,
        ),
        label: Text(
          _currentUserRole == UserRole.tatoueur ? 'Contacter' : 'Réserver',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }
  }
}