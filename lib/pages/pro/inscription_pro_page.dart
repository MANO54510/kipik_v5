import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kipik_v5/utils/constants.dart'; // Pour UserRole

import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../widgets/utils/cgu_cgv_validation_widget.dart';
import 'confirmation_inscription_pro_page.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/services/promo/promo_code_service.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import '../pro/home_page_pro.dart';

class InscriptionProPage extends StatefulWidget {
  InscriptionProPage({Key? key, AuthService? authService})
      : authService = authService ?? AuthService.instance,
        super(key: key);

  final AuthService authService;

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
  String? _societeForme; // Auto‑entreprise ou Société
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
  PromoCode? _validatedPromoCode;
  bool _isValidatingPromo = false;

  // ─── Pièces à transmettre ───
  XFile? _idDocument;
  XFile? _hygieneCert;
  XFile? _kbis;
  XFile? _rib; // Nouveau : RIB obligatoire

  // ─── Newsletter & CGU/CGV ───
  bool _newsletter     = false;
  bool _cguAccepted    = false;
  bool _cgvAccepted    = false;
  bool _showPassword   = false;
  bool _showConfirm    = false;

  // ─── Abonnement & paiement ───
  String _selectedPlan   = 'essai';
  bool   _paymentDone    = false;
  final String _stripeTrialUrl  = 'https://buy.stripe.com/test_trial_link';
  final String _stripeAnnualUrl = 'https://buy.stripe.com/test_annual_link';

  // Nombre d'inscrits actuel (à récupérer depuis Firebase)
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

  bool get _needsPayment => _validatedPromoCode?.type != 'free' && _validatedPromoCode?.type != 'referral';

  bool get _canSubmit =>
      _formKey.currentState?.validate() == true &&
      _shopName.text.isNotEmpty &&
      _shopAddress.text.isNotEmpty &&
      _tatoueurPrenom.text.isNotEmpty &&
      _tatoueurNom.text.isNotEmpty &&
      _birthDate     != null &&
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
      _rib           != null && // RIB obligatoire
      _cguAccepted   &&
      _cgvAccepted   &&
      // ✅ Logique de validation du paiement corrigée
      (_paymentDone || !_needsPayment); // Pas besoin de paiement si code gratuit OU de parrainage

  Future<void> _validatePromoCode() async {
    final code = _promoCode.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingPromo = true);

    try {
      final promoCode = await PromoCodeService.validatePromoCode(code);
      
      if (!mounted) return; // Vérification avant setState
      
      setState(() {
        _validatedPromoCode = promoCode;
        _isValidatingPromo = false;
      });

      if (promoCode != null) {
        String message = 'Code promo valide ! ✅';
        if (promoCode.type == 'free') {
          message += '\nVous bénéficiez de ${promoCode.freeMonths} mois gratuits !';
          // Reset payment status since it's not needed
          _paymentDone = false;
        } else if (promoCode.type == 'referral') {
          message += '\nCode de parrainage validé ! Vous pouvez vous inscrire gratuitement.';
          // Reset payment status since it's not needed for referral codes
          _paymentDone = false;
        } else if (promoCode.discountPercent != null) {
          message += '\n${promoCode.discountPercent}% de réduction appliquée !';
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
      if (!mounted) return; // Vérification avant setState
      
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

  Future<void> _launchStripe(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir Stripe')),
      );
    } else {
      setState(() => _paymentDone = true);
    }
  }

  Future<void> _submitForm() async {
    try {
      // Créer l'utilisateur avec Firebase Auth
      final success = await widget.authService.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
        name: '${_tatoueurPrenom.text.trim()} ${_tatoueurNom.text.trim()}',
        role: UserRole.tatoueur,
        extraData: {
          'shopName': _shopName.text.trim(),
          'shopAddress': _shopAddress.text.trim(),
          'birthDate': _birthDate?.toIso8601String(),
          'societeForme': _societeForme,
          'siren': _siren.text.trim(),
          'phonePro': _phonePro.text.trim(),
          'emailPro': _emailPro.text.trim(),
          'selectedPlan': _selectedPlan,
          'newsletter': _newsletter,
        },
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du compte')),
        );
        return;
      }

      // Si un code promo valide est utilisé, l'enregistrer
      if (_validatedPromoCode != null) {
        await PromoCodeService.usePromoCode(
          _validatedPromoCode!.code, 
          _email.text.trim(),
          _email.text.trim(),
          subscriptionType: _selectedPlan,
        );
      }

      // Redirection vers la page d'accueil pro
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePagePro()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
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

  InputDecoration _decoration(String label, {Widget? suffixIcon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'PermanentMarker',
          color: Colors.black87,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: KipikTheme.rouge, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: KipikTheme.rouge, width: 3),
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
                    // 1) Code promo (en premier)
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
                            '🎁 Avez-vous un code promo ?',
                            style: TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 16,
                              color: Colors.black87,
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
                                    _validatedPromoCode!.type == 'free'
                                        ? '✅ ${_validatedPromoCode!.freeMonths} mois gratuits appliqués !'
                                        : _validatedPromoCode!.type == 'referral'
                                        ? '✅ Code de parrainage validé !'
                                        : '✅ ${_validatedPromoCode!.discountPercent}% de réduction appliquée !',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_validatedPromoCode!.isReferralCode) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Parrainé par: ${_validatedPromoCode!.referrerEmail}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'En souscrivant un abonnement annuel, votre parrain recevra 1 mois gratuit !',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
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

                    // 2) Shop
                    TextFormField(
                      controller: _shopName,
                      decoration: _decoration('Nom du shop'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _shopAddress,
                      decoration: _decoration('Adresse du shop'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87),
                      validator: _required,
                    ),

                    const SizedBox(height: 20),
                    // 3) Tatoueur
                    TextFormField(
                      controller: _tatoueurPrenom,
                      decoration: _decoration('Prénom'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tatoueurNom,
                      decoration: _decoration('Nom'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87),
                      validator: _required,
                    ),

                    const SizedBox(height: 12),
                    // Date de naissance
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
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.white,
                                onPrimary: Colors.black,
                                surface: Colors.black,
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: Colors.black,
                            ),
                            child: child!,
                          ),
                        );
                        if (pick != null) setState(() => _birthDate = pick);
                      },
                      child: InputDecorator(
                        decoration: _decoration('Date de naissance'),
                        child: Text(
                          _birthDate == null
                              ? 'Sélectionner la date'
                              : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                          style: const TextStyle(
                              fontFamily: 'Roboto', color: Colors.black87),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
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
                          fontFamily: 'Roboto', color: Colors.black87),
                    ),

                    const SizedBox(height: 12),
                    // SIREN
                    TextFormField(
                      controller: _siren,
                      decoration: _decoration('SIREN'),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87),
                      validator: _required,
                    ),

                    const SizedBox(height: 20),
                    // 4) Coordonnées pro
                    TextFormField(
                      controller: _phonePro,
                      decoration: _decoration('Téléphone pro'),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailPro,
                      decoration: _decoration('Email pro'),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87),
                      validator: _validateEmail,
                    ),

                    const SizedBox(height: 20),
                    // 5) Pièces obligatoires (avec RIB ajouté)
                    const Text(
                      '📄 Documents obligatoires',
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
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
                      ['🏦 Joindre RIB (prélèvements SEPA)', () async {
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
                        '💡 Le RIB est nécessaire pour mettre en place les prélèvements automatiques SEPA après le premier paiement Stripe, afin de réduire les frais de transaction.',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // 6) Bandeau promo (si pas de code gratuit)
                    if (remaining > 0 && _validatedPromoCode?.type != 'free') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Offre promo : plus que $remaining places à 79 €/mois',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'PermanentMarker',
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],

                    // 7) Choix de l'abonnement (si paiement nécessaire)
                    if (_needsPayment) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Choix de l\'abonnement',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      // Bonus de parrainage pour l'abonnement annuel
                      if (_validatedPromoCode?.isReferralCode == true) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: const Text(
                            '🎁 Bonus : En choisissant l\'abonnement annuel, votre parrain recevra 1 mois gratuit !',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PlanCard(
                              label: 'Essai de 3 mois\n79 € TTC mensuel',
                              selected: _selectedPlan == 'essai',
                              onTap: () {
                                setState(() {
                                  _selectedPlan = 'essai';
                                  _paymentDone = false;
                                });
                                _launchStripe(_stripeTrialUrl);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PlanCard(
                              label: _validatedPromoCode?.isReferralCode == true 
                                  ? 'Engagement 12 mois\n79 € TTC mensuel\ndont 1 mois offert\n+ 1 mois pour votre parrain 🎁'
                                  : 'Engagement 12 mois\n79 € TTC mensuel\ndont 1 mois offert',
                              selected: _selectedPlan == 'annuel',
                              onTap: () {
                                setState(() {
                                  _selectedPlan = 'annuel';
                                  _paymentDone = false;
                                });
                                _launchStripe(_stripeAnnualUrl);
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else if (_validatedPromoCode?.type == 'free') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.celebration,
                              color: Colors.green,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Félicitations ! 🎉',
                              style: TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 20,
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vous bénéficiez de ${_validatedPromoCode!.freeMonths} mois gratuits !',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else if (_validatedPromoCode?.type == 'referral') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.people,
                              color: Colors.blue,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Code de parrainage validé ! 🤝',
                              style: TextStyle(
                                fontFamily: 'PermanentMarker',
                                fontSize: 20,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Parrainé par: ${_validatedPromoCode!.referrerEmail}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Vous pouvez vous inscrire gratuitement !\nSi vous choisissez un abonnement payant plus tard, votre parrain recevra une récompense.',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    // 8) Identifiants
                    TextFormField(
                      controller: _email,
                      decoration: _decoration('Email'),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      decoration: _decoration('Mot de passe'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: !_showConfirm,
                      decoration: _decoration('Confirmer mot de passe'),
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: Colors.black87),
                      validator: _validateConfirm,
                    ),

                    const SizedBox(height: 20),
                    // 9) CGU / CGV
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
                    // 10) Newsletter
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
                    // 11) Validation finale
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
                          'Valider mon inscription',
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
                        child: Column(
                          children: [
                            const Icon(Icons.info, color: Colors.orange),
                            const SizedBox(height: 8),
                            Text(
                              'Veuillez compléter tous les champs obligatoires${_needsPayment ? ' et effectuer le paiement' : ''}',
                              style: const TextStyle(
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

/// Carte de sélection de formule
class _PlanCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PlanCard({
    required this.label,
    required this.selected,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: selected ? KipikTheme.rouge : Colors.white,
          border: Border.all(color: KipikTheme.rouge, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 16,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}