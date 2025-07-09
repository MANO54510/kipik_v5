// lib/widgets/admin/ai_budget_monitor.dart

import 'package:flutter/material.dart';
import '../../services/chat/chat_manager.dart';
import '../../theme/kipik_theme.dart';

class AIBudgetMonitor extends StatefulWidget {
  const AIBudgetMonitor({Key? key}) : super(key: key);

  @override
  State<AIBudgetMonitor> createState() => _AIBudgetMonitorState();
}

class _AIBudgetMonitorState extends State<AIBudgetMonitor> {
  Map<String, dynamic>? _budgetStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgetStats();
  }

  Future<void> _loadBudgetStats() async {
    try {
      final stats = await ChatManager.getAIBudgetStats(); // ✅ CORRIGÉ
      setState(() {
        _budgetStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_budgetStats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Erreur de chargement des statistiques'),
        ),
      );
    }

    final spent = _budgetStats!['spent'] as double;
    final budget = _budgetStats!['monthlyBudget'] as double;
    final remaining = _budgetStats!['remaining'] as double;
    final percentage = _budgetStats!['percentage'] as int;

    Color statusColor;
    String statusText;
    if (percentage < 50) {
      statusColor = Colors.green;
      statusText = 'Budget sain';
    } else if (percentage < 80) {
      statusColor = Colors.orange;
      statusText = 'Attention budget';
    } else {
      statusColor = Colors.red;
      statusText = 'Budget critique';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: KipikTheme.rouge),
                const SizedBox(width: 8),
                const Text(
                  'Budget IA mensuel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Barre de progression
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage% utilisé',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Détails
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Dépensé', '${spent.toStringAsFixed(2)}€', Colors.red),
                _buildStatItem('Restant', '${remaining.toStringAsFixed(2)}€', Colors.green),
                _buildStatItem('Budget', '${budget.toStringAsFixed(0)}€', Colors.blue),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _loadBudgetStats,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Actualiser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KipikTheme.rouge,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                if (percentage > 90)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Ici tu peux ajouter une action d'urgence
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Budget critique'),
                          content: const Text('Le budget IA est presque épuisé. Voulez-vous augmenter la limite ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // Implémenter l'augmentation du budget
                              },
                              child: const Text('Augmenter'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.warning, size: 16),
                    label: const Text('Action requise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'PermanentMarker',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}