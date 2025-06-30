import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/kipik_theme.dart';
import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../services/notification/notification_service.dart';
import 'accueil_particulier_page.dart';
import 'profil_particulier_page.dart';
import 'aide_support_page.dart';

class ParametresPage extends StatefulWidget {
  const ParametresPage({Key? key}) : super(key: key);

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  bool _notificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'Français';
  final NotificationService _notificationService = NotificationService();

  // Profil utilisateur
  String _userName = "Votre prénom ici";
  String _userLastName = "Votre nom ici";
  String _userEmail = "exemple@email.com";
  String? _userProfileImage;

  // Fonds aléatoires
  final List<String> _backgroundImages = [
    'assets/background_charbon.png',
    'assets/background_tatoo1.png',
    'assets/background_tatoo2.png',
    'assets/background_tatoo3.png',
  ];
  late String _selectedBackground;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _selectedBackground =
        _backgroundImages[Random().nextInt(_backgroundImages.length)];
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
      _emailNotificationsEnabled =
          prefs.getBool('email_notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _selectedLanguage =
          prefs.getString('selected_language') ?? 'Français';
      _userName =
          prefs.getString('user_first_name') ?? _userName;
      _userLastName =
          prefs.getString('user_last_name') ?? _userLastName;
      _userEmail =
          prefs.getString('user_email') ?? _userEmail;
      _userProfileImage =
          prefs.getString('user_profile_image');
    });
  }

  Future<void> _saveNotificationSetting(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', v);
    setState(() => _notificationsEnabled = v);
  }

  Future<void> _saveEmailNotificationSetting(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_notifications_enabled', v);
    setState(() => _emailNotificationsEnabled = v);
  }

  Future<void> _saveThemeSetting(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode_enabled', v);
    setState(() => _darkModeEnabled = v);
  }

  Future<void> _saveLanguageSetting(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', lang);
    setState(() => _selectedLanguage = lang);
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Vider le cache',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PermanentMarker',
          ),
        ),
        content: const Text(
          'Cette action effacera toutes les données temporaires stockées sur votre appareil. Continuer ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              await Future.delayed(const Duration(seconds: 1));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green[300]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Cache vidé avec succès !',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.grey[850],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: KipikTheme.rouge,
                    onPressed: () {},
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mon QR Code',
              style: TextStyle(
                color: KipikTheme.blanc,
                fontFamily: KipikTheme.fontTitle,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KipikTheme.blanc,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: KipikTheme.rouge.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(Icons.qr_code,
                  size: 150, color: KipikTheme.noir),
            ),
            const SizedBox(height: 20),
            Text(
              'Scannez ce code pour partager votre profil',
              style:
                  TextStyle(color: KipikTheme.blanc.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Fermer',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Choisir une langue',
              style: TextStyle(
                color: KipikTheme.rouge,
                fontFamily: KipikTheme.fontTitle,
                fontSize: 18,
              ),
            ),
          ),
          Divider(color: KipikTheme.blanc.withOpacity(0.2)),
          _buildLanguageOption('Français'),
          _buildLanguageOption('English'),
          _buildLanguageOption('Español'),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String lang) {
    final isSelected = _selectedLanguage == lang;
    return ListTile(
      title: Text(
        lang,
        style: TextStyle(
          color: isSelected ? KipikTheme.rouge : KipikTheme.blanc,
          fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          isSelected ? Icon(Icons.check, color: KipikTheme.rouge) : null,
      onTap: () {
        _saveLanguageSetting(lang);
        Navigator.pop(context);
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Politique de confidentialité',
          style: TextStyle(
            color: KipikTheme.blanc,
            fontFamily: KipikTheme.fontTitle,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPolicySection(
                'Données personnelles',
                'Nous collectons uniquement les données nécessaires '
                'au bon fonctionnement de l\'application.',
              ),
              const SizedBox(height: 10),
              _buildPolicySection(
                'Utilisation des cookies',
                'Nous utilisons des cookies pour améliorer votre expérience '
                'et analyser le trafic.',
              ),
              const SizedBox(height: 10),
              _buildPolicySection(
                'Partage des données',
                'Vos informations ne sont jamais vendues à des tiers sans '
                'votre consentement explicite.',
              ),
              const SizedBox(height: 10),
              _buildPolicySection(
                'Sécurité',
                'Toutes vos données sont cryptées et stockées en toute sécurité.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fermer',
                style: TextStyle(color: KipikTheme.rouge)),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: KipikTheme.rouge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(color: KipikTheme.blanc.withOpacity(0.8)),
        ),
      ],
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'À propos de Kipik',
          style: TextStyle(
            color: KipikTheme.blanc,
            fontFamily: KipikTheme.fontTitle,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.brush,
                      size: 40, color: KipikTheme.rouge),
                  const SizedBox(height: 8),
                  const Text(
                    'KIPIK',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kipik est une application qui vous permet de trouver '
              'facilement des tatoueurs et d\'explorer des '
              'inspirations créatives.',
              style:
                  TextStyle(color: KipikTheme.blanc.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2025 Kipik. Tous droits réservés.',
              style:
                  TextStyle(color: KipikTheme.blanc.withOpacity(0.6)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fermer',
                style: TextStyle(color: KipikTheme.rouge)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Supprimer mon compte',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PermanentMarker',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.amber[300]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cette action est irréversible et toutes vos données '
                      'seront définitivement supprimées.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Veuillez confirmer que vous souhaitez supprimer votre '
              'compte en saisissant "SUPPRIMER" ci-dessous :',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'SUPPRIMER',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => const AccueilParticulierPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KipikTheme.rouge,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnexion',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: 'Paramètres',
        showBackButton: true,
        redirectToHome: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _selectedBackground,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildUserProfileCard(context),
                  const SizedBox(height: 30),
                  _buildAnimatedSectionHeader('Général', Icons.settings),
                  const SizedBox(height: 15),
                  _buildGeneralSettings(),
                  const SizedBox(height: 30),
                  _buildAnimatedSectionHeader('Apparence', Icons.palette),
                  const SizedBox(height: 15),
                  _buildAppearanceSettings(),
                  const SizedBox(height: 30),
                  _buildAnimatedSectionHeader(
                      'Notifications', Icons.notifications_none),
                  const SizedBox(height: 15),
                  _buildNotificationSettings(),
                  const SizedBox(height: 30),
                  _buildAnimatedSectionHeader(
                      'Confidentialité & Sécurité', Icons.shield),
                  const SizedBox(height: 15),
                  _buildPrivacySettings(),
                  const SizedBox(height: 30),
                  Center(
                    child: Container(
                      width: 200,
                      height: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white30),
                        color: Colors.black38,
                      ),
                      child: TextButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(Icons.logout,
                            size: 18, color: Colors.white70),
                        label: const Text(
                          'Déconnexion',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: KipikTheme.blanc.withOpacity(0.6),
                        fontSize: 12,
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

  Widget _buildUserProfileCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfilParticulierPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: KipikTheme.rouge.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: KipikTheme.rouge, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: KipikTheme.rouge.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                image: _userProfileImage != null
                    ? DecorationImage(
                        image: AssetImage(_userProfileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _userProfileImage == null
                  ? Icon(Icons.person,
                      size: 40, color: KipikTheme.blanc)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$_userName $_userLastName",
                    style: const TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: TextStyle(
                        fontSize: 14,
                        color: KipikTheme.blanc.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProfilParticulierPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: KipikTheme.rouge),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Éditer mon profil',
                      style: TextStyle(
                          color: KipikTheme.rouge, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.qr_code, color: KipikTheme.blanc),
              onPressed: _showQRCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSectionHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          Icon(icon, color: KipikTheme.rouge, size: 24),
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

  Widget _buildGeneralSettings() {
    return Column(
      children: [
        _buildSelectTile(
          title: 'Langue',
          value: _selectedLanguage,
          icon: Icons.language,
          onTap: _showLanguagePicker,
        ),
        const SizedBox(height: 10),
        _buildNavigationTile(
          title: 'À propos',
          subtitle: 'Informations légales et licences',
          icon: Icons.info_outline,
          onTap: _showAboutDialog,
        ),
        const SizedBox(height: 10),
        _buildNavigationTile(
          title: 'Aide et support',
          subtitle: 'FAQ et contact',
          icon: Icons.help_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AideSupportPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          title: 'Vider le cache',
          subtitle: '45 MB',
          icon: Icons.cleaning_services_outlined,
          onTap: _showClearCacheDialog,
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return _buildEnhancedSwitchTile(
      'Mode sombre',
      'Économisez votre batterie',
      Icons.dark_mode_outlined,
      _darkModeEnabled,
      _saveThemeSetting,
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      children: [
        _buildEnhancedSwitchTile(
          'Notifications push',
          'Pour nouveaux messages & mises à jour',
          Icons.notifications,
          _notificationsEnabled,
          _saveNotificationSetting,
        ),
        const SizedBox(height: 10),
        _buildEnhancedSwitchTile(
          'Notifications email',
          'Promotions et nouveautés',
          Icons.email,
          _emailNotificationsEnabled,
          _saveEmailNotificationSetting,
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      children: [
        _buildNavigationTile(
          title: 'Politique de confidentialité',
          subtitle: 'Comment nous traitons vos données',
          icon: Icons.privacy_tip_outlined,
          onTap: _showPrivacyPolicy,
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          title: 'Supprimer mon compte',
          subtitle: 'Effacer définitivement toutes les données',
          icon: Icons.delete_outline,
          onTap: _showDeleteAccountDialog,
          textColor: KipikTheme.rouge,
        ),
      ],
    );
  }

  Widget _buildSelectTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Icon(icon,
                    color: KipikTheme.blanc.withOpacity(0.8)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                        color: KipikTheme.blanc, fontSize: 16),
                  ),
                ),
                Text(value,
                    style: TextStyle(
                        color:
                            KipikTheme.blanc.withOpacity(0.6))),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Icon(icon,
                    color: textColor ??
                        KipikTheme.blanc.withOpacity(0.8)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: textColor ??
                                  KipikTheme.blanc,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: KipikTheme.blanc
                                  .withOpacity(0.6),
                              fontSize: 14)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Icon(icon,
                    color: textColor ??
                        KipikTheme.blanc.withOpacity(0.8)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: textColor ??
                                  KipikTheme.blanc,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: KipikTheme.blanc
                                  .withOpacity(0.6),
                              fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? KipikTheme.rouge.withOpacity(0.5)
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
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: value
                    ? KipikTheme.rouge
                    : Colors.white70),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: value
                              ? Colors.white
                              : Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: value
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color:
                              Colors.white.withOpacity(0.7),
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
                  activeTrackColor:
                      KipikTheme.rouge.withOpacity(0.3),
                  inactiveThumbColor:
                      Colors.white.withOpacity(0.7),
                  inactiveTrackColor:
                      Colors.white.withOpacity(0.1),
                ),  
              ],
            ),
          ),
        ),
      ),
    );
  }
}
