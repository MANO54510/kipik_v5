import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_particulier.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class ProfilParticulierPage extends StatefulWidget {
  const ProfilParticulierPage({super.key});

  @override
  State<ProfilParticulierPage> createState() => _ProfilParticulierPageState();
}

class _ProfilParticulierPageState extends State<ProfilParticulierPage> {
  final TextEditingController nomController = TextEditingController(text: 'Votre nom ici');
  final TextEditingController prenomController = TextEditingController(text: 'Votre prénom ici');
  final TextEditingController emailController = TextEditingController(text: 'exemple@email.com');
  final TextEditingController telephoneController = TextEditingController(text: '+33 6 12 34 56 78');
  final TextEditingController adresseController = TextEditingController(text: 'Votre adresse complète ici');
  
  // Champs supplémentaires pour plus de professionnalisme
  final TextEditingController anniversaireController = TextEditingController(text: '01/01/1990');
  final TextEditingController urgenceController = TextEditingController(text: '+33 6 00 00 00 00');
  
  String _selectedSexe = 'Non précisé';
  
  File? _avatarImage;
  bool _isSaving = false;
  bool _notificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _hasAllergies = false;
  bool _takesMedication = false;
  
  // Liste des images de fond disponibles
  final List<String> _backgroundImages = [
    'assets/background_charbon.png',
    'assets/background_tatoo1.png',
    'assets/background_tatoo2.png',
    'assets/background_tatoo3.png',
  ];
  
  // Variable pour stocker l'image de fond sélectionnée aléatoirement
  late String _selectedBackground;
  
  @override
  void initState() {
    super.initState();
    // Sélection aléatoire de l'image de fond
    _selectedBackground = _backgroundImages[Random().nextInt(_backgroundImages.length)];
  }

  Future<void> _pickAvatar() async {
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    final XFile? picked = await openFile(acceptedTypeGroups: [typeGroup]);
    if (picked != null) {
      setState(() {
        _avatarImage = File(picked.path);
      });

      // TODO : Upload vers Firebase Storage plus tard
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(seconds: 2)); // Simulation réseau

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[300]),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Profil mis à jour avec succès !',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[850],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: KipikTheme.rouge,
          onPressed: () {},
        ),
      ),
    );

    // TODO: Enregistrement sur Firebase Firestore plus tard
  }

  void _showDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: KipikTheme.rouge,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[800],
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      setState(() {
        anniversaireController.text = '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
      });
    }
  }
  
  void _showAllergiesDialog() {
    final TextEditingController allergiesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Mes allergies',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PermanentMarker',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: allergiesController,
              decoration: InputDecoration(
                hintText: 'Décrivez vos allergies...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Text(
              'Informez toujours votre tatoueur de vos allergies avant une session',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[200],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasAllergies = true;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showMedicationDialog() {
    final TextEditingController medicationController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Mes médicaments',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PermanentMarker',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: medicationController,
              decoration: InputDecoration(
                hintText: 'Listez vos médicaments...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Text(
              'Certains médicaments peuvent affecter le processus de tatouage et la cicatrisation',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[200],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _takesMedication = true;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    // Montrer un dialogue de confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Déconnexion',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PermanentMarker',
          ),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Fermer la boîte de dialogue
              Navigator.pop(context);
              
              // Rediriger vers la page de connexion
              Navigator.of(context).pushReplacementNamed('/connexion');
              
              // TODO: Implémenter la logique de déconnexion réelle
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: 'Mon Profil',
        showBackButton: true,
        redirectToHome: true,
        showNotificationIcon: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond aléatoire avec effet de parallaxe
          Image.asset(
            _selectedBackground, 
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          
          // Overlay dégradé pour meilleure lisibilité
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
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Conteneur d'avatar amélioré avec animation
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Avatar carré avec effet de brillance
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: KipikTheme.rouge, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: KipikTheme.rouge.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            image: _avatarImage == null
                                ? const DecorationImage(
                                    image: AssetImage('assets/avatar_user.png'),
                                    fit: BoxFit.cover,
                                  )
                                : DecorationImage(
                                    image: FileImage(_avatarImage!),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        
                        // Icône pour indiquer qu'on peut modifier
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white70,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    "${prenomController.text} ${nomController.text}",
                    style: const TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 5),
                  
                  Text(
                    emailController.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Section Informations personnelles avec animation
                  _buildAnimatedSectionHeader('Informations personnelles', Icons.person),
                  
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildEditableField('Nom', nomController),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildEditableField('Prénom', prenomController),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  
                  _buildEditableField('Adresse Email', emailController, 
                    prefixIcon: Icons.email),
                  
                  const SizedBox(height: 15),
                  
                  _buildEditableField('Téléphone', telephoneController, 
                    prefixIcon: Icons.phone),
                  
                  const SizedBox(height: 15),
                  
                  _buildEditableField('Adresse', adresseController, 
                    prefixIcon: Icons.home),
                  
                  const SizedBox(height: 15),
                  
                  // Champ de date de naissance avec sélecteur
                  InkWell(
                    onTap: _showDatePicker,
                    child: IgnorePointer(
                      child: _buildEditableField('Date de naissance', anniversaireController, 
                        prefixIcon: Icons.cake, 
                        suffixIcon: Icons.calendar_today),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Menu déroulant pour le sexe
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sexe',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSexe,
                            isExpanded: true,
                            dropdownColor: Colors.grey[900],
                            style: const TextStyle(color: Colors.white),
                            items: ['Masculin', 'Féminin', 'Non précisé'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedSexe = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Section Informations médicales
                  _buildAnimatedSectionHeader('Informations médicales', Icons.medical_services),
                  
                  const SizedBox(height: 15),
                  
                  _buildInfoCard(
                    'Ces informations sont importantes en cas de réaction allergique pendant une séance de tatouage',
                    icon: Icons.info_outline,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  _buildEditableField('Contact d\'urgence', urgenceController, 
                    prefixIcon: Icons.emergency),
                  
                  const SizedBox(height: 15),
                  
                  // Allergies avec action corrigée
                  _buildEnhancedSwitchTile(
                    'J\'ai des allergies',
                    'Additifs, certaines encres, latex...',
                    Icons.healing,
                    _hasAllergies,
                    (value) {
                      setState(() {
                        _hasAllergies = value;
                      });
                      
                      if (value) {
                        _showAllergiesDialog();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Médicaments avec action corrigée
                  _buildEnhancedSwitchTile(
                    'Je prends des médicaments',
                    'Anticoagulants, immunosuppresseurs...',
                    Icons.medication,
                    _takesMedication,
                    (value) {
                      setState(() {
                        _takesMedication = value;
                      });
                      
                      if (value) {
                        _showMedicationDialog();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Section Préférences
                  _buildAnimatedSectionHeader('Préférences', Icons.settings),
                  
                  const SizedBox(height: 15),
                  
                  _buildEnhancedSwitchTile(
                    'Notifications push',
                    'Pour les nouveaux messages et mises à jour',
                    Icons.notifications,
                    _notificationsEnabled,
                    (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 10),
                  
                  _buildEnhancedSwitchTile(
                    'Notifications email',
                    'Promotions et nouveautés',
                    Icons.email,
                    _emailNotificationsEnabled,
                    (value) {
                      setState(() {
                        _emailNotificationsEnabled = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Bouton d'enregistrement amélioré
                  _isSaving
                      ? Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
                          ),
                        )
                      : Container(
                          height: 55,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              colors: [
                                KipikTheme.rouge.withOpacity(0.8),
                                KipikTheme.rouge,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: KipikTheme.rouge.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save, color: Colors.white),
                                const SizedBox(width: 10),
                                const Text(
                                  'Enregistrer les modifications',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'PermanentMarker',
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  
                  const SizedBox(height: 25),
                  
                  // Bouton de déconnexion amélioré
                  Container(
                    width: 200,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white30),
                      color: Colors.black38,
                    ),
                    child: TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 18, color: Colors.white70),
                      label: const Text(
                        'Déconnexion', 
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
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
        border: Border.all(
          color: KipikTheme.rouge.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: KipikTheme.rouge,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'PermanentMarker',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String label, 
    TextEditingController controller, {
    IconData? prefixIcon,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black45,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white10, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: KipikTheme.rouge, width: 1),
              ),
              prefixIcon: prefixIcon != null 
                  ? Icon(prefixIcon, color: Colors.white70, size: 20)
                  : null,
              suffixIcon: suffixIcon != null 
                  ? Icon(suffixIcon, color: Colors.white70, size: 20)
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String text, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.15),
            Colors.amber.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber[300], size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.amber[100],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? KipikTheme.rouge.withOpacity(0.5) : Colors.white10,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onChanged(!value), // Permet de cliquer sur toute la tuile
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: value ? KipikTheme.rouge : Colors.white70),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: value ? Colors.white : Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: value ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: KipikTheme.rouge,
                  activeTrackColor: KipikTheme.rouge.withOpacity(0.3),
                  inactiveThumbColor: Colors.white.withOpacity(0.7),
                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}