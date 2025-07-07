import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/kipik_theme.dart';
import '../../services/auth/secure_auth_service.dart';
import '../../services/auth/captcha_manager.dart';
import '../../utils/auth_helper.dart';

class FirstSetupPage extends StatefulWidget {
  const FirstSetupPage({Key? key}) : super(key: key);

  @override
  _FirstSetupPageState createState() => _FirstSetupPageState();
}

class _FirstSetupPageState extends State<FirstSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Use fake captcha for initial admin creation
      final success = await createFirstAdminAccount(
        customEmail: _emailController.text.trim(),
        customPassword: _passwordController.text,
        customDisplayName: null,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('setup.success'.tr())),
        );
        Navigator.pushReplacementNamed(context, '/connexion');
      } else {
        setState(() => _errorMessage = 'setup.error'.tr());
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'setup.validation.emailRequired'.tr();
    final reg = RegExp(r"^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}\$");
    if (!reg.hasMatch(v)) return 'setup.validation.emailInvalid'.tr();
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'setup.validation.passwordRequired'.tr();
    if (v.length < 8) return 'setup.validation.passwordTooShort'.tr();
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(v)) return 'setup.validation.passwordUppercase'.tr();
    if (!RegExp(r'(?=.*\d)').hasMatch(v)) return 'setup.validation.passwordDigit'.tr();
    if (!RegExp(r'(?=.*[!@#\\$&*~])').hasMatch(v)) return 'setup.validation.passwordSpecial'.tr();
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordController.text) return 'setup.validation.passwordMismatch'.tr();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('setup.title'.tr()),
        backgroundColor: KipikTheme.rouge,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'setup.subtitle'.tr(),
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'setup.email'.tr(),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'setup.password'.tr(),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    decoration: InputDecoration(
                      labelText: 'setup.confirmPassword'.tr(),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                    validator: _validateConfirm,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KipikTheme.rouge,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                        : Text('setup.button'.tr(), style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
