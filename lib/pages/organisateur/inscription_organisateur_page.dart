// lib/pages/organisateur/inscription_organisateur_page.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/auth/auth_service.dart';
import 'package:kipik_v5/locator.dart';

class InscriptionOrganisateurPage extends StatefulWidget {
  const InscriptionOrganisateurPage({Key? key}) : super(key: key);

  @override
  _InscriptionOrganisateurPageState createState() => _InscriptionOrganisateurPageState();
}

class _InscriptionOrganisateurPageState extends State<InscriptionOrganisateurPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  
  bool _isLoading = false;
  bool _acceptTerms = false;
  
  final AuthService _authService = locator<AuthService>();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('signup.acceptTermsError')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Modifier cette ligne pour utiliser registerOrganisateur au lieu de registerOrganiser
      final success = await _authService.registerOrganisateur(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        company: _companyController.text,
        phone: _phoneController.text,
        website: _websiteController.text.isEmpty ? null : _websiteController.text,
      );
      
      // Vérification du succès de l'inscription
      if (success) {
        // Redirection vers une page de succès ou directement vers l'espace organisateur
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/organisateur/dashboard', 
            (route) => false,
          );
        }
      } else {
        // Gestion de l'échec d'inscription
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('signup.registerFailed')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBarKipik(
        title: tr('signup.organisateurTitle'),
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background_charbon.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('signup.organisateurIntro'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Informations de base
                    Text(
                      tr('signup.basicInfo'),
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        color: KipikTheme.rouge,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: tr('signup.email'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation.required');
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return tr('validation.invalidEmail');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: tr('signup.password'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: TextStyle(color: Colors.white),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation.required');
                        }
                        if (value.length < 8) {
                          return tr('validation.passwordTooShort');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: tr('signup.confirmPassword'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: TextStyle(color: Colors.white),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation.required');
                        }
                        if (value != _passwordController.text) {
                          return tr('validation.passwordsDoNotMatch');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    
                    // Informations sur l'organisateur
                    Text(
                      tr('signup.organisateurInfo'),
                      style: TextStyle(
                        fontFamily: 'PermanentMarker',
                        color: KipikTheme.rouge,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: tr('signup.fullName'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation.required');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: tr('signup.companyName'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation.required');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: tr('signup.phoneNumber'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation.required');
                        }
                        // Vous pouvez ajouter une validation pour le format du numéro de téléphone
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _websiteController,
                      decoration: InputDecoration(
                        labelText: tr('signup.website') + ' ' + tr('common.optional'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.url,
                    ),
                    SizedBox(height: 24),
                    
                    // Conditions d'utilisation
                    CheckboxListTile(
                      title: Text(
                        tr('signup.acceptTerms'),
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      checkColor: Colors.black,
                      activeColor: KipikTheme.rouge,
                    ),
                    SizedBox(height: 24),
                    
                    // Bouton d'inscription
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KipikTheme.rouge,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                tr('signup.submit'),
                                style: TextStyle(
                                  fontFamily: 'PermanentMarker',
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
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