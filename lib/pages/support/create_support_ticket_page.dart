// lib/pages/support/create_support_ticket_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/services/chat/chat_manager.dart';
import 'package:kipik_v5/pages/support/support_ticket_detail_page.dart';
import 'package:kipik_v5/models/support_ticket.dart';

class CreateSupportTicketPage extends StatefulWidget {
  final String userId;

  const CreateSupportTicketPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CreateSupportTicketPage> createState() => _CreateSupportTicketPageState();
}

class _CreateSupportTicketPageState extends State<CreateSupportTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedCategory = 'question';
  bool _isCreating = false;

  final Map<String, String> _categories = {
    'question': 'Question générale',
    'bug': 'Bug / Problème technique',
    'account': 'Problème de compte',
    'payment': 'Problème de paiement',
    'suggestion': 'Suggestion d\'amélioration',
  };

  final Map<String, IconData> _categoryIcons = {
    'question': Icons.help_outline,
    'bug': Icons.bug_report_outlined,
    'account': Icons.account_circle_outlined,
    'payment': Icons.payment_outlined,
    'suggestion': Icons.lightbulb_outline,
  };

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final ticketId = await ChatManager.createSupportTicket(
        userId: widget.userId,
        subject: _subjectController.text.trim(),
        category: _selectedCategory,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        // Naviguer vers le détail du ticket
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SupportTicketDetailPage(
              ticket: SupportTicket(
                id: ticketId,
                userId: widget.userId,
                subject: _subjectController.text.trim(),
                category: _selectedCategory,
                status: 'open',
                priority: _determinePriority(_selectedCategory),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _determinePriority(String category) {
    switch (category) {
      case 'payment':
      case 'account':
        return 'high';
      case 'bug':
        return 'medium';
      default:
        return 'low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nouveau ticket de support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'PermanentMarker',
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // En-tête explicatif
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Support Kipik',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Notre équipe vous répondra dans les plus brefs délais',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sélection de catégorie
            const Text(
              'Catégorie du problème',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ...(_categories.entries.map((entry) {
              final isSelected = _selectedCategory == entry.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = entry.key),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.blue
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _categoryIcons[entry.key],
                          color: isSelected ? Colors.blue : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isSelected ? Colors.blue : Colors.white,
                              fontSize: 14,
                              fontWeight: isSelected 
                                  ? FontWeight.w600 
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList()),

            const SizedBox(height: 24),

            // Sujet
            const Text(
              'Sujet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subjectController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Résumé de votre problème...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir un sujet';
                }
                if (value.trim().length < 10) {
                  return 'Le sujet doit contenir au moins 10 caractères';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Description
            const Text(
              'Description détaillée',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Décrivez votre problème en détail...\n\nN\'hésitez pas à inclure :\n• Les étapes pour reproduire le problème\n• Ce que vous attendiez\n• Ce qui s\'est passé à la place',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez décrire votre problème';
                }
                if (value.trim().length < 20) {
                  return 'La description doit contenir au moins 20 caractères';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Bouton de création
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Créer le ticket de support',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Info délai de réponse
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Délai de réponse habituel : 24-48h ouvrées',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}