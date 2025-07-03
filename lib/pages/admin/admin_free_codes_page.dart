// lib/pages/admin/admin_free_codes_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kipik_v5/services/promo/firebase_promo_code_service.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class AdminFreeCodesPage extends StatefulWidget {
  const AdminFreeCodesPage({Key? key}) : super(key: key);

  @override
  State<AdminFreeCodesPage> createState() => _AdminFreeCodesPageState();
}

class _AdminFreeCodesPageState extends State<AdminFreeCodesPage> {
  final _customCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tatoueurNameController = TextEditingController();
  
  int _batchCount = 5;
  int _freeMonths = 12;
  bool _isGenerating = false;
  List<String> _lastGeneratedCodes = [];

  @override
  void dispose() {
    _customCodeController.dispose();
    _descriptionController.dispose();
    _tatoueurNameController.dispose();
    super.dispose();
  }

  Future<void> _generateBatchCodes() async {
    setState(() => _isGenerating = true);
    
    try {
      List<String> codes = [];
      
      // Générer plusieurs codes manuellement
      for (int i = 0; i < _batchCount; i++) {
        final code = 'FREE${DateTime.now().millisecondsSinceEpoch}${i.toString().padLeft(3, '0')}';
        
        // Créer chaque code avec votre service Firebase
        await FirebasePromoCodeService.instance.createPromoCode(
          code: code,
          type: 'percentage', // Type de réduction
          value: 100.0, // 100% de réduction = gratuit
          description: 'Code gratuit pour tatoueur partenaire - Lot généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          expiresAt: DateTime.now().add(Duration(days: _freeMonths * 30)), // Approximation des mois
          maxUses: 1,
        );
        
        codes.add(code);
      }
      
      setState(() {
        _lastGeneratedCodes = codes;
        _isGenerating = false;
      });
      
      if (codes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${codes.length} codes générés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createCustomCode() async {
    final code = _customCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un code')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Utiliser votre service Firebase pour créer le code
      final promoId = await FirebasePromoCodeService.instance.createPromoCode(
        code: code,
        type: 'percentage', // Type de réduction
        value: 100.0, // 100% de réduction = gratuit
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : 'Code personnalisé pour ${_tatoueurNameController.text.isNotEmpty ? _tatoueurNameController.text : "tatoueur"}',
        expiresAt: DateTime.now().add(Duration(days: _freeMonths * 30)), // Approximation des mois
        maxUses: 1,
      );
      
      setState(() => _isGenerating = false);
      
      if (promoId.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code $code créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        _customCodeController.clear();
        _descriptionController.clear();
        _tatoueurNameController.clear();
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      
      // Vérifier si l'erreur est due à un code déjà existant
      String errorMessage = 'Erreur: $e';
      if (e.toString().contains('already exists') || e.toString().contains('déjà')) {
        errorMessage = 'Code déjà existant';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyAllCodes() {
    if (_lastGeneratedCodes.isEmpty) return;
    
    final codesText = _lastGeneratedCodes.join('\n');
    Clipboard.setData(ClipboardData(text: codesText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tous les codes copiés !')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarKipik(
        title: 'Codes gratuits tatoueurs',
        showBackButton: true,
        showBurger: false,
        showNotificationIcon: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section génération en lot
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎯 Génération en lot',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PermanentMarker',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nombre de codes:'),
                              Slider(
                                value: _batchCount.toDouble(),
                                min: 1,
                                max: 50,
                                divisions: 49,
                                label: _batchCount.toString(),
                                activeColor: KipikTheme.rouge,
                                onChanged: (value) {
                                  setState(() => _batchCount = value.round());
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mois gratuits:'),
                              Slider(
                                value: _freeMonths.toDouble(),
                                min: 1,
                                max: 24,
                                divisions: 23,
                                label: _freeMonths.toString(),
                                activeColor: KipikTheme.rouge,
                                onChanged: (value) {
                                  setState(() => _freeMonths = value.round());
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isGenerating ? null : _generateBatchCodes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KipikTheme.rouge,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isGenerating
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Génération en cours...'),
                              ],
                            )
                          : Text(
                              'Générer $_batchCount codes de $_freeMonths mois',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Section code personnalisé
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✏️ Code personnalisé',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PermanentMarker',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tatoueurNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du tatoueur (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Code personnalisé (ex: TATOO2025FREE)',
                        border: OutlineInputBorder(),
                        hintText: 'Lettres et chiffres uniquement',
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnelle)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isGenerating ? null : _createCustomCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Créer le code de $_freeMonths mois',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Affichage des derniers codes générés
            if (_lastGeneratedCodes.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '📋 Derniers codes générés',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PermanentMarker',
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _copyAllCodes,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copier tout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _lastGeneratedCodes.map((code) => 
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      code,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: code));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Code $code copié !')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Informations
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Informations importantes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Les codes gratuits permettent aux tatoueurs de s\'inscrire sans paiement\n'
                      '• Chaque code ne peut être utilisé qu\'une seule fois\n'
                      '• Les codes sont valides indéfiniment jusqu\'à utilisation\n'
                      '• Vous pouvez voir tous les codes dans la page "Gestion des parrainages"',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}