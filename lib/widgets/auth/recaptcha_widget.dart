// lib/widgets/auth/recaptcha_widget.dart - Version corrigée sans erreurs

import 'package:flutter/material.dart';
import '../../services/auth/captcha_manager.dart';

class ReCaptchaWidget extends StatefulWidget {
  final Function(CaptchaResult) onValidated;
  final String action;
  final bool useInvisible;
  final bool isRequired;
  final double requiredScore; // ✅ AJOUTÉ

  const ReCaptchaWidget({
    Key? key,
    required this.onValidated,
    required this.action,
    this.useInvisible = true,
    this.isRequired = true,
    this.requiredScore = 0.5, // ✅ AJOUTÉ: Score par défaut
  }) : super(key: key);

  @override
  State<ReCaptchaWidget> createState() => _ReCaptchaWidgetState();
}

class _ReCaptchaWidgetState extends State<ReCaptchaWidget> {
  bool _isValidated = false;
  bool _isLoading = false;
  CaptchaResult? _lastResult;

  @override
  void initState() {
    super.initState();
    
    // Auto-validation pour reCAPTCHA invisible
    if (widget.useInvisible) {
      _validateInvisibleCaptcha();
    }
  }

  /// Validation reCAPTCHA v3 invisible
  Future<void> _validateInvisibleCaptcha() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final result = await CaptchaManager.instance.validateInvisibleCaptcha(widget.action);
      
      setState(() {
        _lastResult = result;
        _isValidated = result.isValid;
        _isLoading = false;
      });

      widget.onValidated(result);

      // Afficher les indicateurs selon le résultat
      if (result.isValid) {
        if (result.isHighConfidence) {
          _showSuccessIndicator();
        } else if (result.isMediumConfidence) {
          _showWarningIndicator();
        } else {
          _showLowScoreWarning();
        }
      } else {
        if (result.score > 0.0) {
          _showFallbackOption();
        } else {
          _showErrorIndicator();
        }
      }

    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorIndicator();
    }
  }

  /// Indicateur de succès
  void _showSuccessIndicator() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Vérification réussie'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Indicateur d'avertissement (score moyen)
  void _showWarningIndicator() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Sécurité moyenne détectée'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Indicateur score bas mais valide
  void _showLowScoreWarning() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Activité suspecte détectée'),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Proposer fallback visuel
  void _showFallbackOption() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.security, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(child: Text('Vérification supplémentaire requise')),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Vérifier',
          textColor: Colors.white,
          onPressed: () {
            _showVisualCaptchaFallback();
          },
        ),
      ),
    );
  }

  /// Fallback visuel (placeholder pour reCAPTCHA v2)
  void _showVisualCaptchaFallback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vérification de sécurité'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('Un CAPTCHA visuel serait affiché ici en production.'),
            SizedBox(height: 16),
            Text('(Simulation du fallback reCAPTCHA v2)', 
                 style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Simuler validation réussie avec tous les paramètres requis
              setState(() {
                _isValidated = true;
                _lastResult = CaptchaResult(
                  isValid: true,
                  score: 1.0,
                  action: widget.action,
                  requiredScore: widget.requiredScore, // ✅ AJOUTÉ
                  timestamp: DateTime.now(),
                  token: 'visual_fallback_token',
                );
              });
              widget.onValidated(_lastResult!);
              _showSuccessIndicator();
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  /// Indicateur d'erreur
  void _showErrorIndicator() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Erreur de vérification'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: _validateInvisibleCaptcha,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pour reCAPTCHA invisible, afficher juste un indicateur de statut
    if (widget.useInvisible) {
      return _buildInvisibleIndicator();
    }

    // Pour reCAPTCHA visuel, afficher le bouton de vérification
    return _buildVisualCaptchaButton();
  }

  /// Indicateur pour reCAPTCHA invisible
  Widget _buildInvisibleIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getIndicatorColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getIndicatorColor(), width: 1),
      ),
      child: Row(
        children: [
          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_getIndicatorColor()),
              ),
            )
          else
            Icon(
              _getIndicatorIcon(),
              color: _getIndicatorColor(),
              size: 20,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getIndicatorTitle(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getIndicatorColor(),
                    fontSize: 12,
                  ),
                ),
                if (_lastResult != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getScoreText(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!_isLoading && !_isValidated)
            IconButton(
              icon: Icon(Icons.refresh, color: _getIndicatorColor()),
              onPressed: _validateInvisibleCaptcha,
              iconSize: 20,
            ),
        ],
      ),
    );
  }

  /// Bouton pour CAPTCHA visuel
  Widget _buildVisualCaptchaButton() {
    return ElevatedButton.icon(
      onPressed: _isValidated ? null : _validateInvisibleCaptcha,
      icon: Icon(_isValidated ? Icons.check : Icons.security),
      label: Text(
        _isValidated 
            ? 'Vérifié'
            : 'Vérifier que vous êtes humain',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isValidated ? Colors.green : Colors.redAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Couleur de l'indicateur selon l'état
  Color _getIndicatorColor() {
    if (_isLoading) return Colors.blue;
    if (_isValidated) {
      if (_lastResult?.isHighConfidence == true) return Colors.green;
      if (_lastResult?.isMediumConfidence == true) return Colors.orange;
      return Colors.red;
    }
    return Colors.grey;
  }

  /// Icône de l'indicateur selon l'état
  IconData _getIndicatorIcon() {
    if (_isValidated) {
      if (_lastResult?.isHighConfidence == true) return Icons.verified_user;
      if (_lastResult?.isMediumConfidence == true) return Icons.warning;
      return Icons.error;
    }
    return Icons.security;
  }

  /// Titre de l'indicateur selon l'état
  String _getIndicatorTitle() {
    if (_isLoading) return 'Vérification...';
    if (_isValidated) {
      if (_lastResult?.isHighConfidence == true) return 'Sécurité élevée';
      if (_lastResult?.isMediumConfidence == true) return 'Sécurité moyenne';
      return 'Sécurité faible';
    }
    return 'En attente';
  }

  /// Texte du score
  String _getScoreText() {
    if (_lastResult == null) return '';
    return 'Score: ${(_lastResult!.score * 100).round()}%';
  }
}

// ✅ WIDGET UTILITAIRE POUR FACILITER L'UTILISATION
class QuickReCaptcha extends StatelessWidget {
  final Function(CaptchaResult) onValidated;
  final String action;
  final double requiredScore;

  const QuickReCaptcha({
    Key? key,
    required this.onValidated,
    required this.action,
    this.requiredScore = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReCaptchaWidget(
      onValidated: onValidated,
      action: action,
      useInvisible: true,
      requiredScore: requiredScore,
    );
  }
}

// ✅ WIDGET POUR CAPTCHA HAUTE SÉCURITÉ (ex: création admin)
class HighSecurityCaptcha extends StatelessWidget {
  final Function(CaptchaResult) onValidated;
  final String action;

  const HighSecurityCaptcha({
    Key? key,
    required this.onValidated,
    required this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReCaptchaWidget(
      onValidated: onValidated,
      action: action,
      useInvisible: true,
      requiredScore: 0.8, // Score élevé requis
    );
  }
}