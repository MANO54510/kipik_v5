// lib/pages/pro/inscription_pro_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/utils/cgu_cgv_validation_widget.dart';
import 'confirmation_inscription_pro_page.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';
import 'package:kipik_v5/services/promo/firebase_promo_code_service.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class InscriptionProPage extends StatefulWidget {
  InscriptionProPage({
    Key? key, 
    SecureAuthService? authService
  }) : authService = authService ?? SecureAuthService.instance,
       super(key: key);

  final SecureAuthService authService;

  @override
  State<InscriptionProPage> createState() => _InscriptionProPageState();
}

class _InscriptionProPageState extends State<InscriptionProPage> {
  final _formKey = GlobalKey<FormState>();

  // ─── Shop & tatoueur info ───
  final _shopName       = TextEditingController();
  final _shopAddress    = TextEditingController();
  final _tatoueurPrenom = TextEditingController();
  final _tatoueurNom    = TextEditingController();
  DateTime? _birthDate;
  String? _societeForme;
  final _siren          = TextEditingController();

  // ─── Coordonnées pro ───
  final _phonePro       = TextEditingController();
  final _emailPro       = TextEditingController();

  // ─── Authentification ───
  final _email          = TextEditingController();
  final _password       = TextEditingController();
  final _confirm        = TextEditingController();

  // ─── Code promo ───
  final _promoCode      = TextEditingController();
  Map<String, dynamic>? _validatedPromoCode;
  bool _isValidatingPromo = false;

  // ─── Pièces à transmettre ───
  XFile? _idDocument;
  XFile? _hygieneCert;
  XFile? _kbis;
  XFile? _rib;

  // ─── Newsletter & CGU/CGV ───
  bool _newsletter     = false;
  bool _cguAccepted    = false;
  bool _cgvAccepted    = false;
  bool _showPassword   = false;
  bool _showConfirm    = false;

  // ✅ NOUVEAU: Variables pour la vérification d'âge
  bool majoriteConfirmee = false; // ✅ Certification majorité
  String? ageError; // ✅ Erreur d'âge

  // Nombre d'inscrits actuel
  final int _currentSignupCount = 45;
  static const int _promoLimit = 100;

  @override
  void dispose() {
    _shopName.dispose();
    _shopAddress.dispose();
    _tatoueurPrenom.dispose();
    _tatoueurNom.dispose();
    _siren.dispose();
    _phonePro.dispose();
    _emailPro.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _promoCode.dispose();
    super.dispose();
  }

  // ✅ NOUVEAU: Méthode de vérification d'âge
  bool _isOver18(DateTime birthDate) {
    final today = DateTime.now();
    final age = today.year - birthDate.year;
    
    // Vérification précise avec mois et jour
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      return age - 1 >= 18;
    }
    return age >= 18;
  }

  // ✅ MISE À JOUR: Validation avec vérification d'âge
  bool get _canSubmit =>
      _formKey.currentState?.validate() == true &&
      _shopName.text.isNotEmpty &&
      _shopAddress.text.isNotEmpty &&
      _tatoueurPrenom.text.isNotEmpty &&
      _tatoueurNom.text.isNotEmpty &&
      _birthDate     != null &&
      majoriteConfirmee && // ✅ Certification obligatoire
      (_birthDate != null ? _isOver18(_birthDate!) : false) && // ✅ Vérification âge
      _societeForme  != null &&
      _siren.text.isNotEmpty &&
      _phonePro.text.isNotEmpty &&
      _emailPro.text.isNotEmpty &&
      _email.text.isNotEmpty &&
      _password.text.isNotEmpty &&
      _confirm.text.isNotEmpty &&
      _idDocument    != null &&
      _hygieneCert   != null &&
      _kbis          != null &&
      _rib           != null &&
      _cguAccepted   &&
      _cgvAccepted;

  Future<void> _validatePromoCode() async {
    final code = _promoCode.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingPromo = true);

    try {
      final promoData = await FirebasePromoCodeService.instance.validatePromoCode(code);
      
      if (!mounted) return;
      
      setState(() {
        _validatedPromoCode = promoData;
        _isValidatingPromo = false;
      });

      if (promoData != null) {
        String message = 'Code promo valide ! ✅';
        final type = promoData['type'] as String?;
        final value = promoData['value'] as num?;
        
        if (type == 'referral') {
          message += '\nCode de parrainage validé ! Réduction appliquée sur votre futur abonnement.';
        } else if (type == 'percentage' && value != null) {
          message += '\n${value.toInt()}% de réduction appliquée sur votre futur abonnement !';
        } else if (type == 'fixed' && value != null) {
          message += '\n${value.toInt()}€ de réduction appliquée sur votre futur abonnement !';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code promo invalide ou expiré ❌'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isValidatingPromo = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la validation du code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ CORRECTION : Méthode sans recordReferral
  Future<void> _submitForm() async {
    try {
      // Créer l'utilisateur avec Firebase Auth
      final user = await widget.authService.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
        displayName: '${_tatoueurPrenom.text.trim()} ${_tatoueurNom.text.trim()}',
        userRole: 'tatoueur',
      );

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du compte')),
        );
        return;
      }

      // Calcul des dates d'essai
      final now = DateTime.now();
      final trialEndDate = now.add(const Duration(days: 30));

      // Mettre à jour le profil avec essai 30 jours
      await widget.authService.updateUserProfile(
        additionalData: {
          'shopName': _shopName.text.trim(),
          'shopAddress': _shopAddress.text.trim(),
          'birthDate': _birthDate?.toIso8601String(),
          'societeForme': _societeForme,
          'siren': _siren.text.trim(),
          'phonePro': _phonePro.text.trim(),
          'emailPro': _emailPro.text.trim(),
          'newsletter': _newsletter,
          'role': 'tatoueur',
          'majoriteConfirmee': majoriteConfirmee, // ✅ Enregistrement de la certification
          
          // Données d'essai 30 jours
          'subscriptionType': 'trial',
          'trialStartDate': now.toIso8601String(),
          'trialEndDate': trialEndDate.toIso8601String(),
          'trialDaysRemaining': 30,
          'subscriptionStatus': 'trial_active',
          'mustChooseSubscription': false,
          
          // Documents uploadés
          'documents': {
            'idDocument': _idDocument?.name,
            'hygieneCert': _hygieneCert?.name,
            'kbis': _kbis?.name,
            'rib': _rib?.name,
          },
        },
      );

      // ✅ CORRECTION : Gestion simplifiée du code promo
      if (_validatedPromoCode != null) {
        final code = _validatedPromoCode!['code'] as String;
        
        try {
          // Marquer le code comme utilisé
          await FirebasePromoCodeService.instance.usePromoCode(code);
          
          // Sauvegarder le code promo pour application future
          await widget.authService.updateUserProfile(
            additionalData: {
              'pendingPromoCode': {
                'code': code,
                'type': _validatedPromoCode!['type'],
                'value': _validatedPromoCode!['value'],
                'description': _validatedPromoCode!['description'],
                'appliedAt': DateTime.now().toIso8601String(),
                'createdBy': _validatedPromoCode!['createdBy'], // Pour les parrainages
              }
            },
          );
          
          print('✅ Code promo sauvegardé pour application future');
        } catch (e) {
          print('⚠️ Erreur lors de la sauvegarde du code promo: $e');
          // Ne pas bloquer l'inscription pour une erreur de code promo
        }
      }

      // Redirection vers la page de confirmation
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ConfirmationInscriptionProPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email requis';
    final reg = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!reg.hasMatch(v.trim())) return 'Email invalide';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe requis';
    if (v.length < 6) return '6 caractères minimum';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _password.text) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  // ✅ OPTIMISÉ: InputDecoration compact avec PermanentMarker
  InputDecoration _decoration(String label, {Widget? suffixIcon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'PermanentMarker', // ✅ PermanentMarker conservé
          fontSize: 11, // ✅ Taille réduite mais lisible
          color: Colors.black87,
          height: 0.9, // ✅ Interligne serré pour économiser l'espace
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'PermanentMarker', 
          fontSize: 12, // ✅ Taille contrôlée quand il flotte
          color: Colors.black87,
          height: 0.9,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, 
          vertical: 18, // ✅ Juste assez d'espace pour le label flottant
        ),
        isDense: true, // ✅ CRUCIAL: Réduit la hauteur globale du champ
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: KipikTheme.rouge, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: KipikTheme.rouge, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'PermanentMarker',
          fontSize: 10, // ✅ Erreurs compactes
          color: Colors.red,
          height: 1.0,
        ),
        suffixIcon: suffixIcon ?? (label == 'Mot de passe' || label == 'Confirmer mot de passe'
            ? IconButton(
                icon: Icon(
                  label == 'Mot de passe'
                      ? (_showPassword ? Icons.visibility_off : Icons.visibility)
                      : (_showConfirm ? Icons.visibility_off : Icons.visibility),
                  color: KipikTheme.rouge,
                ),
                onPressed: () {
                  setState(() {
                    if (label == 'Mot de passe') _showPassword = !_showPassword;
                    else _showConfirm = !_showConfirm;
                  });
                },
              )
            : null),
      );

  // ✅ NOUVEAU: Widget de certification de majorité
  Widget _buildMajoriteConfirmation() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: majoriteConfirmee ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: majoriteConfirmee ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: majoriteConfirmee,
                onChanged: _birthDate != null && _isOver18(_birthDate!) 
                    ? (value) => setState(() => majoriteConfirmee = value!) 
                    : null, // ✅ Désactivé si pas majeur
                activeColor: KipikTheme.rouge,
              ),
              Expanded(
                child: Text(
                  "Je certifie avoir plus de 18 ans *",
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 14,
                    color: _birthDate != null && _isOver18(_birthDate!) 
                        ? Colors.white 
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                majoriteConfirmee ? Icons.check_circle : Icons.warning,
                color: majoriteConfirmee ? Colors.green : Colors.orange,
              ),
            ],
          ),
          if (ageError != null) // ✅ Affichage de l'erreur d'âge
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ageError!,
                      style: const TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 11,
                        color: Colors.red,
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

  // ✅ Widget titres de sections avec headers tattoo (sans emoji dans le texte)
  Widget _buildSectionTitleWithHeader(String title, IconData icon, {int headerIndex = 1}) {
    final headers = [
      'assets/images/header_tattoo_wallpaper.png',
      'assets/images/header_tattoo_wallpaper2.png', 
      'assets/images/header_tattoo_wallpaper3.png',
    ];
    
    final headerImage = headers[(headerIndex - 1) % headers.length];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(headerImage),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.6),
            BlendMode.lighten,
          ),
        ),
        border: Border.all(color: KipikTheme.rouge, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: KipikTheme.rouge,
            size: 20,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.white,
                  blurRadius: 3,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool get _isReferralCode {
    return _validatedPromoCode?['type'] == 'referral';
  }

  String? get _referrerEmail {
    if (!_isReferralCode) return null;
    final createdBy = _validatedPromoCode?['createdBy'] as String?;
    return _validatedPromoCode?['description']?.toString().split(' pour ').last ?? 'Utilisateur';
  }

  @override
  Widget build(BuildContext context) {
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final bg = backgrounds[Random().nextInt(backgrounds.length)];

    final remaining = max(0, _promoLimit - _currentSignupCount);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Inscription Professionnel',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bg, fit: BoxFit.cover),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bandeau essai gratuit 30 jours
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.celebration,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'ESSAI GRATUIT 30 JOURS',
                            style: TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Profitez de toutes les fonctionnalités pendant 30 jours.\nVous choisirez votre abonnement à la fin de la période.',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // ✅ Section Code promo avec header tattoo
                    _buildSectionTitleWithHeader('Code promo', Icons.card_giftcard, headerIndex: 1),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KipikTheme.rouge, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Bénéficiez d\'une réduction sur votre futur abonnement',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _promoCode,
                                  decoration: _decoration('Code promo (optionnel)'),
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textCapitalization: TextCapitalization.characters,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isValidatingPromo ? null : _validatePromoCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: KipikTheme.rouge,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                child: _isValidatingPromo
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Valider'),
                              ),
                            ],
                          ),
                          if (_validatedPromoCode != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _isReferralCode
                                        ? '✅ Code de parrainage validé !'
                                        : _validatedPromoCode!['type'] == 'percentage'
                                        ? '✅ ${(_validatedPromoCode!['value'] as num).toInt()}% de réduction sur votre futur abonnement !'
                                        : '✅ ${(_validatedPromoCode!['value'] as num).toInt()}€ de réduction sur votre futur abonnement !',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_isReferralCode) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Parrainé par: ${_referrerEmail ?? 'Utilisateur'}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ✅ Section Shop avec header tattoo
                    _buildSectionTitleWithHeader('Informations du shop', Icons.store, headerIndex: 2),

                    TextFormField(
                      controller: _shopName,
                      decoration: _decoration('Nom du shop'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _shopAddress,
                      decoration: _decoration('Adresse du shop'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                      validator: _required,
                    ),

                    const SizedBox(height: 20),
                    
                    // ✅ Section Tatoueur avec header tattoo
                    _buildSectionTitleWithHeader('Informations personnelles', Icons.person, headerIndex: 3),
                    
                    TextFormField(
                      controller: _tatoueurPrenom,
                      decoration: _decoration('Prénom'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tatoueurNom,
                      decoration: _decoration('Nom'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                      validator: _required,
                    ),

                    const SizedBox(height: 12),
                    
                    // ✅ MISE À JOUR: Date de naissance avec validation d'âge
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final pick = await showDatePicker(
                          context: context,
                          initialDate: _birthDate ?? DateTime(now.year - 25),
                          firstDate: DateTime(1900),
                          lastDate: now,
                          locale: const Locale('fr'),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: KipikTheme.rouge,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: KipikTheme.rouge,
                                ),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        
                        if (pick != null) {
                          setState(() {
                            _birthDate = pick;
                            
                            // ✅ VALIDATION AUTOMATIQUE D'ÂGE
                            if (!_isOver18(pick)) {
                              ageError = "Vous devez avoir au moins 18 ans pour vous inscrire";
                              majoriteConfirmee = false;
                            } else {
                              ageError = null;
                              // Ne pas cocher automatiquement, l'utilisateur doit le faire
                            }
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: _decoration('Date de naissance').copyWith(
                          // ✅ Bordure rouge si mineur
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _birthDate != null && !_isOver18(_birthDate!) 
                                  ? Colors.red 
                                  : KipikTheme.rouge, 
                              width: 1.5
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _birthDate == null
                                    ? 'Sélectionner la date'
                                    : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                                style: TextStyle(
                                  fontFamily: 'Roboto', 
                                  color: _birthDate == null ? Colors.grey : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (_birthDate != null)
                              Icon(
                                _isOver18(_birthDate!) ? Icons.check_circle : Icons.error,
                                color: _isOver18(_birthDate!) ? Colors.green : Colors.red,
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // ✅ NOUVEAU: Widget de certification de majorité
                    _buildMajoriteConfirmation(),

                    // Forme juridique
                    DropdownButtonFormField<String>(
                      value: _societeForme,
                      decoration: _decoration('Forme juridique'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Auto‑entreprise',
                            child: Text('Auto‑entreprise')),
                        DropdownMenuItem(
                            value: 'Société', child: Text('Société')),
                      ],
                      onChanged: (v) => setState(() => _societeForme = v),
                      validator: (v) => v == null ? 'Champ obligatoire' : null,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                    ),

                    const SizedBox(height: 12),
                    // SIREN
                    TextFormField(
                      controller: _siren,
                      decoration: _decoration('SIREN'),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                      validator: _required,
                    ),

                    const SizedBox(height: 20),
                    
                    // ✅ Section Coordonnées avec header tattoo
                    _buildSectionTitleWithHeader('Coordonnées professionnelles', Icons.business, headerIndex: 1),
                    
                    TextFormField(
                      controller: _phonePro,
                      decoration: _decoration('Téléphone pro'),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailPro,
                      decoration: _decoration('Email pro'),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                      validator: _validateEmail,
                    ),

                    const SizedBox(height: 20),
                    
                    // ✅ Section Documents avec header tattoo
                    _buildSectionTitleWithHeader('Documents obligatoires', Icons.folder, headerIndex: 2),
                    
                    for (var btn in [
                      ['Joindre pièce d\'identité', () async {
                        final fg = XTypeGroup(
                            label: 'docs', extensions: ['jpg', 'png', 'pdf']);
                        final f = await openFile(acceptedTypeGroups: [fg]);
                        if (f != null) setState(() => _idDocument = f);
                      }, _idDocument != null],
                      ['Joindre certif. d\'hygiène', () async {
                        final fg = XTypeGroup(
                            label: 'docs', extensions: ['jpg', 'png', 'pdf']);
                        final f = await openFile(acceptedTypeGroups: [fg]);
                        if (f != null) setState(() => _hygieneCert = f);
                      }, _hygieneCert != null],
                      ['Joindre KBIS < 3 mois', () async {
                        final fg = XTypeGroup(
                            label: 'docs', extensions: ['jpg', 'png', 'pdf']);
                        final f = await openFile(acceptedTypeGroups: [fg]);
                        if (f != null) setState(() => _kbis = f);
                      }, _kbis != null],
                      ['Joindre RIB (prélèvements SEPA)', () async {
                        final fg = XTypeGroup(
                            label: 'docs', extensions: ['jpg', 'png', 'pdf']);
                        final f = await openFile(acceptedTypeGroups: [fg]);
                        if (f != null) setState(() => _rib = f);
                      }, _rib != null],
                    ]) ...[
                      ElevatedButton(
                        onPressed: btn[1] as VoidCallback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (btn[2] as bool) 
                              ? Colors.green 
                              : KipikTheme.rouge,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              btn[0] as String,
                              style: const TextStyle(
                                  fontFamily: 'PermanentMarker', fontSize: 16),
                            ),
                            if (btn[2] as bool) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle, color: Colors.white),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Info RIB
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Text(
                        '💡 Le RIB est nécessaire pour mettre en place les prélèvements automatiques SEPA après votre période d\'essai, afin de réduire les frais de transaction.',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),
                    
                    // ✅ Section Identifiants avec header tattoo
                    _buildSectionTitleWithHeader('Identifiants de connexion', Icons.lock, headerIndex: 3),
                    
                    TextFormField(
                      controller: _email,
                      decoration: _decoration('Email'),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      decoration: _decoration('Mot de passe'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: !_showConfirm,
                      decoration: _decoration('Confirmer mot de passe'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                      validator: _validateConfirm,
                    ),

                    const SizedBox(height: 20),
                    
                    // ✅ Section Conditions avec header tattoo
                    _buildSectionTitleWithHeader('Conditions d\'utilisation', Icons.gavel, headerIndex: 1),
                    
                    // CGU / CGV
                    CGUCGVValidationWidget(
                      cguAccepted: _cguAccepted,
                      cgvAccepted: _cgvAccepted,
                      onCGURead: () async {
                        final ok = await Navigator.pushNamed(context, '/cgu')
                            as bool?;
                        if (mounted) setState(() => _cguAccepted = ok == true);
                      },
                      onCGVRead: () async {
                        final ok = await Navigator.pushNamed(context, '/cgv')
                            as bool?;
                        if (mounted) setState(() => _cgvAccepted = ok == true);
                      },
                    ),

                    const SizedBox(height: 12),
                    // Newsletter
                    CheckboxListTile(
                      value: _newsletter,
                      onChanged: (v) => setState(() => _newsletter = v!),
                      title: const Text(
                        "Recevoir la newsletter Kipik",
                        style: TextStyle(
                            fontFamily: 'PermanentMarker', color: Colors.white),
                      ),
                      activeColor: KipikTheme.rouge,
                    ),

                    const SizedBox(height: 24),
                    // Validation finale
                    if (_canSubmit)
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KipikTheme.rouge,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Commencer mon essai gratuit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'PermanentMarker',
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.info, color: Colors.orange),
                            SizedBox(height: 8),
                            Text(
                              'Veuillez compléter tous les champs obligatoires pour commencer votre essai gratuit',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}