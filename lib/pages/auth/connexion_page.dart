// lib/pages/auth/connexion_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kipik_v5/pages/admin/admin_dashboard_home.dart'; // ← Corrigé : Pointage direct vers le bon dashboard
import '../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../theme/kipik_theme.dart';
import 'package:kipik_v5/utils/auth_helper.dart';
import '../particulier/accueil_particulier_page.dart';
import '../pro/home_page_pro.dart'; 
import '../organisateur/organisateur_dashboard_page.dart';
import 'inscription_page.dart';
import 'forgot_password_page.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({Key? key}) : super(key: key);

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return tr('login.validation.emailRequired');
    final reg = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!reg.hasMatch(v.trim())) return tr('login.validation.emailInvalid');
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return tr('login.validation.passwordRequired');
    if (v.length < 4) return tr('login.validation.passwordTooShort');
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailC.text.trim();
    final pass = _passC.text.trim();
    final role = await checkUserCredentials(email, pass);

    if (role == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('login.error.signInFailed'))));
      return;
    }

    late final Widget destination;
    switch (role) {
      case UserRole.client:
        destination = AccueilParticulierPage();
        break;
      case UserRole.tatoueur:
        destination = HomePagePro(); 
        break;
      case UserRole.admin:
        // ✅ CORRIGÉ : Redirection directe vers le Dashboard Admin
        destination = const AdminDashboardHome();
        break;
      case UserRole.organisateur:
        destination = OrganisateurDashboardPage();
        break;
    }

    // Navigation avec remplacement pour éviter le retour
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgrounds = [
      'assets/background1.png',
      'assets/background2.png',
      'assets/background3.png',
      'assets/background4.png',
    ];
    final bg = backgrounds[DateTime.now().millisecond % backgrounds.length];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBarKipik(
        title: tr('login.title'),
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bg, fit: BoxFit.cover),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: KipikTheme.rouge,
                      selectionColor: KipikTheme.rouge.withOpacity(0.4),
                      selectionHandleColor: KipikTheme.rouge,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/logo_kipik.png', width: 200),
                        const SizedBox(height: 30),

                        // —– Email —–
                        TextFormField(
                          controller: _emailC,
                          cursorColor: KipikTheme.rouge,
                          validator: _validateEmail,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            labelText: tr('login.emailLabel'),
                            labelStyle: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              color: Colors.black54,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: KipikTheme.rouge,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: KipikTheme.rouge,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // —– Mot de passe —–
                        TextFormField(
                          controller: _passC,
                          obscureText: !_showPassword,
                          cursorColor: KipikTheme.rouge,
                          validator: _validatePassword,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            labelText: tr('login.passwordLabel'),
                            labelStyle: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              color: Colors.black54,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: KipikTheme.rouge,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: KipikTheme.rouge,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: KipikTheme.rouge,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // — Bouton "Se connecter" —
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KipikTheme.rouge,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 18,
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Center(child: Text(tr('login.submit'))),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // — Liens —
                        TextButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InscriptionPage(),
                                ),
                              ),
                          style: TextButton.styleFrom(
                            foregroundColor: KipikTheme.rouge,
                            textStyle: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 16,
                            ),
                          ),
                          child: Text(tr('login.signupPrompt')),
                        ),
                        TextButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage(),
                                ),
                              ),
                          style: TextButton.styleFrom(
                            foregroundColor: KipikTheme.rouge,
                            textStyle: const TextStyle(
                              fontFamily: 'PermanentMarker',
                              fontSize: 16,
                            ),
                          ),
                          child: Text(tr('login.forgotPassword')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}