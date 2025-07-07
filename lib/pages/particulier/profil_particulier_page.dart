// lib/pages/particulier/profil_particulier_page.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_particulier.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart'; // ✅ AJOUTÉ
import 'package:kipik_v5/core/database_manager.dart'; // ✅ AJOUTÉ
import 'package:kipik_v5/models/user.dart'; // ✅ AJOUTÉ
import 'package:kipik_v5/models/user_role.dart'; // ✅ AJOUTÉ

class ProfilParticulierPage extends StatefulWidget {
  const ProfilParticulierPage({super.key});

  @override
  State<ProfilParticulierPage> createState() => _ProfilParticulierPageState();
}

class _ProfilParticulierPageState extends State<ProfilParticulierPage> {
  // ✅ Controllers avec valeurs par défaut vides
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController adresseController = TextEditingController();
  final TextEditingController anniversaireController = TextEditingController();
  final TextEditingController urgenceController = TextEditingController();
  
  String _selectedSexe = 'Non précisé';
  File? _avatarImage;
  bool _isLoading = true; // ✅ AJOUTÉ
  bool _isSaving = false;
  bool _notificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _hasAllergies = false;
  bool _takesMedication = false;
  
  // ✅ Données utilisateur
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  
  final List<String> _backgroundImages = [
    'assets/background_charbon.png',
    'assets/background_tatoo2.png',
    'assets/background1.png',
    'assets/background2.png',
  ];
  
  late String _selectedBackground;
  
  @override
  void initState() {
    super.initState();
    _selectedBackground = _backgroundImages[Random().nextInt(_backgroundImages.length)];
    _loadUserProfile();
  }

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    adresseController.dispose();
    anniversaireController.dispose();
    urgenceController.dispose();
    super.dispose();
  }

  /// ✅ CHARGER LE PROFIL UTILISATEUR
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      _currentUser = SecureAuthService.instance.currentUser;
      
      if (_currentUser != null) {
        await _fetchUserProfileData();
        _populateFields();
      } else {
        _setDemoData();
      }
      
    } catch (e) {
      print('❌ Erreur chargement profil: $e');
      _setDemoData();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ RÉCUPÉRER LES DONNÉES DEPUIS LA BASE
  Future<void> _fetchUserProfileData() async {
    try {
      final firestore = DatabaseManager.instance.firestore;
      final doc = await firestore.collection('users').doc(_currentUser!.uid).get();
      
      if (doc.exists) {
        _userProfile = doc.data()!;
        print('✅ Profil chargé depuis ${DatabaseManager.instance.activeDatabaseConfig.name}');
      } else {
        // Créer un profil vide
        _userProfile = _createEmptyProfile();
        await _saveProfileToDatabase();
      }
    } catch (e) {
      print('❌ Erreur récupération profil: $e');
      _userProfile = _createEmptyProfile();
    }
  }

  /// ✅ CRÉER UN PROFIL VIDE
  Map<String, dynamic> _createEmptyProfile() {
    return {
      'personalInfo': {
        'firstName': '',
        'lastName': '',
        'email': _currentUser?.email ?? '',
        'phone': '',
        'address': '',
        'birthDate': '',
        'gender': 'Non précisé',
        'emergencyContact': '',
      },
      'medicalInfo': {
        'hasAllergies': false,
        'allergiesDetails': '',
        'takesMedication': false,
        'medicationDetails': '',
      },
      'preferences': {
        'pushNotifications': true,
        'emailNotifications': true,
      },
      'profileImageUrl': '',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// ✅ REMPLIR LES CHAMPS AVEC LES DONNÉES
  void _populateFields() {
    if (_userProfile == null) return;
    
    final personalInfo = _userProfile!['personalInfo'] as Map<String, dynamic>? ?? {};
    final medicalInfo = _userProfile!['medicalInfo'] as Map<String, dynamic>? ?? {};
    final preferences = _userProfile!['preferences'] as Map<String, dynamic>? ?? {};
    
    // Informations personnelles
    nomController.text = personalInfo['lastName'] ?? '';
    prenomController.text = personalInfo['firstName'] ?? '';
    emailController.text = personalInfo['email'] ?? _currentUser?.email ?? '';
    telephoneController.text = personalInfo['phone'] ?? '';
    adresseController.text = personalInfo['address'] ?? '';
    anniversaireController.text = personalInfo['birthDate'] ?? '';
    urgenceController.text = personalInfo['emergencyContact'] ?? '';
    _selectedSexe = personalInfo['gender'] ?? 'Non précisé';
    
    // Informations médicales
    _hasAllergies = medicalInfo['hasAllergies'] ?? false;
    _takesMedication = medicalInfo['takesMedication'] ?? false;
    
    // Préférences
    _notificationsEnabled = preferences['pushNotifications'] ?? true;
    _emailNotificationsEnabled = preferences['emailNotifications'] ?? true;
  }

  /// ✅ DONNÉES DE DÉMONSTRATION
  void _setDemoData() {
    if (DatabaseManager.instance.isDemoMode) {
      final demoProfiles = [
        {
          'firstName': 'Alex',
          'lastName': 'Martin',
          'email': 'alex.martin@demo.kipik.ink',
          'phone': '+33 6 12 34 56 78',
          'address': '15 Rue de la République, 54000 Nancy',
          'birthDate': '15/03/1995',
          'gender': 'Non précisé',
        },
        {
          'firstName': 'Sophie',
          'lastName': 'Dubois',
          'email': 'sophie.dubois@demo.kipik.ink',
          'phone': '+33 6 87 65 43 21',
          'address': '8 Avenue des Vosges, 54000 Nancy',
          'birthDate': '22/11/1988',
          'gender': 'Féminin',
        },
        {
          'firstName': 'Thomas',
          'lastName': 'Leroy',
          'email': 'thomas.leroy@demo.kipik.ink',
          'phone': '+33 6 45 67 89 01',
          'address': '32 Rue Stanislas, 54000 Nancy',
          'birthDate': '08/07/1992',
          'gender': 'Masculin',
        },
      ];
      
      final randomProfile = demoProfiles[Random().nextInt(demoProfiles.length)];
      
      nomController.text = randomProfile['lastName']!;
      prenomController.text = randomProfile['firstName']!;
      emailController.text = randomProfile['email']!;
      telephoneController.text = randomProfile['phone']!;
      adresseController.text = randomProfile['address']!;
      anniversaireController.text = randomProfile['birthDate']!;
      urgenceController.text = '+33 6 00 00 00 00';
      _selectedSexe = randomProfile['gender']!;
      
      print('🎭 Données démo générées pour ${randomProfile['firstName']} ${randomProfile['lastName']}');
    } else {
      // Données par défaut vides pour production
      nomController.text = 'Votre nom';
      prenomController.text = 'Votre prénom';
      emailController.text = _currentUser?.email ?? 'exemple@email.com';
      telephoneController.text = '+33 6 12 34 56 78';
      adresseController.text = 'Votre adresse complète';
      anniversaireController.text = '01/01/1990';
      urgenceController.text = '+33 6 00 00 00 00';
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[300]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Photo de profil mise à jour !',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.grey[850],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// ✅ SAUVEGARDER LE PROFIL
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    
    try {
      if (_currentUser != null) {
        await _saveProfileToDatabase();
        
        if (mounted) {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: KipikTheme.rouge,
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        // Mode démo
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎭 Profil démo mis à jour (simulation)'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
      
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// ✅ SAUVEGARDER DANS LA BASE DE DONNÉES
  Future<void> _saveProfileToDatabase() async {
    final profileData = {
      'personalInfo': {
        'firstName': prenomController.text,
        'lastName': nomController.text,
        'email': emailController.text,
        'phone': telephoneController.text,
        'address': adresseController.text,
        'birthDate': anniversaireController.text,
        'gender': _selectedSexe,
        'emergencyContact': urgenceController.text,
      },
      'medicalInfo': {
        'hasAllergies': _hasAllergies,
        'takesMedication': _takesMedication,
      },
      'preferences': {
        'pushNotifications': _notificationsEnabled,
        'emailNotifications': _emailNotificationsEnabled,
      },
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedBy': _currentUser!.uid,
    };

    final firestore = DatabaseManager.instance.firestore;
    await firestore.collection('users').doc(_currentUser!.uid).update(profileData);
    
    print('✅ Profil sauvegardé dans ${DatabaseManager.instance.activeDatabaseConfig.name}');
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
              'Informez toujours votre tatoueur de vos allergies avant une séance',
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

  /// ✅ DÉCONNEXION AVEC SECUREAU AuthService
  void _logout() {
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
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await SecureAuthService.instance.signOut();
                
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/connexion',
                    (route) => false,
                  );
                }
              } catch (e) {
                print('❌ Erreur déconnexion: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la déconnexion: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: CustomAppBarParticulier(
          title: DatabaseManager.instance.isDemoMode 
              ? 'Mon Profil 🎭'
              : 'Mon Profil',
          showBackButton: true,
          redirectToHome: true,
          showNotificationIcon: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: KipikTheme.rouge),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: DatabaseManager.instance.isDemoMode 
            ? 'Mon Profil 🎭'
            : 'Mon Profil',
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
                  
                  // ✅ Indicateur mode démo
                  if (DatabaseManager.instance.isDemoMode) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: Text(
                        '🎭 Mode ${DatabaseManager.instance.activeDatabaseConfig.name}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Conteneur d'avatar amélioré avec animation
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: DatabaseManager.instance.isDemoMode 
                                  ? Colors.orange 
                                  : KipikTheme.rouge, 
                              width: 2
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (DatabaseManager.instance.isDemoMode 
                                    ? Colors.orange 
                                    : KipikTheme.rouge).withOpacity(0.2),
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
                                    image: AssetImage('assets/avatars/avatar_user_neutre.png'),
                                    fit: BoxFit.cover,
                                  )
                                : DecorationImage(
                                    image: FileImage(_avatarImage!),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        
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
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DatabaseManager.instance.isDemoMode 
                                  ? Colors.orange 
                                  : KipikTheme.rouge
                            ),
                          ),
                        )
                      : Container(
                          height: 55,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              colors: DatabaseManager.instance.isDemoMode 
                                  ? [
                                      Colors.orange.withOpacity(0.8),
                                      Colors.orange,
                                    ]
                                  : [
                                      KipikTheme.rouge.withOpacity(0.8),
                                      KipikTheme.rouge,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (DatabaseManager.instance.isDemoMode 
                                    ? Colors.orange 
                                    : KipikTheme.rouge).withOpacity(0.3),
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
    final isDemo = DatabaseManager.instance.isDemoMode;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDemo 
              ? [
                  Colors.orange.withOpacity(0.3),
                  Colors.orange.withOpacity(0.1),
                ]
              : [
                  KipikTheme.rouge.withOpacity(0.3),
                  KipikTheme.rouge.withOpacity(0.1),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDemo 
              ? Colors.orange.withOpacity(0.5)
              : KipikTheme.rouge.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDemo ? Colors.orange : KipikTheme.rouge,
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
    final isDemo = DatabaseManager.instance.isDemoMode;
    
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
                borderSide: BorderSide(
                  color: isDemo ? Colors.orange : KipikTheme.rouge, 
                  width: 1
                ),
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
    final isDemo = DatabaseManager.instance.isDemoMode;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value 
              ? (isDemo ? Colors.orange.withOpacity(0.5) : KipikTheme.rouge.withOpacity(0.5))
              : Colors.white10,
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
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon, 
                  color: value 
                      ? (isDemo ? Colors.orange : KipikTheme.rouge)
                      : Colors.white70
                ),
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
                  activeColor: isDemo ? Colors.orange : KipikTheme.rouge,
                  activeTrackColor: (isDemo ? Colors.orange : KipikTheme.rouge).withOpacity(0.3),
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