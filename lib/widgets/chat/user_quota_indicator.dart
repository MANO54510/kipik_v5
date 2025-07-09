// lib/widgets/chat/user_quota_indicator.dart

import 'package:flutter/material.dart';
import '../../services/chat/chat_manager.dart';
import '../../services/auth/secure_auth_service.dart';
import '../../theme/kipik_theme.dart';

class UserQuotaIndicator extends StatefulWidget {
  final bool showInHeader; // Pour afficher dans le header du chat
  
  const UserQuotaIndicator({
    Key? key,
    this.showInHeader = false,
  }) : super(key: key);

  @override
  State<UserQuotaIndicator> createState() => _UserQuotaIndicatorState();
}

class _UserQuotaIndicatorState extends State<UserQuotaIndicator> {
  Map<String, int>? _quotas;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotas();
  }

  Future<void> _loadQuotas() async {
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) return;
      
      // ✅ SIMPLIFIÉ: Utilise les stats budget existantes
      final budgetStats = await ChatManager.getAIBudgetStats();
      
      // Calcule des quotas approximatifs basés sur le budget
      final percentage = budgetStats['percentage'] as int? ?? 0;
      final configured = budgetStats['configured'] as bool? ?? false;
      
      // Estimation des quotas restants
      final dailyRemaining = configured ? (percentage < 100 ? 8 : 0) : 8;
      final imagesRemaining = configured ? (percentage < 100 ? 3 : 0) : 3;
      
      if (mounted) {
        setState(() {
          _quotas = {
            'dailyRequestsRemaining': dailyRemaining,
            'monthlyImagesRemaining': imagesRemaining,
            'dailyRequestsUsed': 8 - dailyRemaining,
            'monthlyImagesUsed': 3 - imagesRemaining,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // ✅ Valeurs par défaut en cas d'erreur
          _quotas = {
            'dailyRequestsRemaining': 8,
            'monthlyImagesRemaining': 3,
            'dailyRequestsUsed': 0,
            'monthlyImagesUsed': 0,
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.showInHeader 
          ? const SizedBox.shrink()
          : const CircularProgressIndicator(strokeWidth: 2);
    }

    if (_quotas == null) return const SizedBox.shrink();

    final dailyRemaining = _quotas!['dailyRequestsRemaining'] ?? 0;
    final imagesRemaining = _quotas!['monthlyImagesRemaining'] ?? 0;

    if (widget.showInHeader) {
      return _buildHeaderIndicator(dailyRemaining, imagesRemaining);
    } else {
      return _buildDetailedIndicator(dailyRemaining, imagesRemaining);
    }
  }

  Widget _buildHeaderIndicator(int dailyRemaining, int imagesRemaining) {
    Color statusColor = dailyRemaining > 2 ? Colors.green : 
                       dailyRemaining > 0 ? Colors.orange : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            '$dailyRemaining',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          if (imagesRemaining > 0) ...[
            const SizedBox(width: 6),
            Icon(Icons.image, size: 12, color: statusColor),
            const SizedBox(width: 2),
            Text(
              '$imagesRemaining',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedIndicator(int dailyRemaining, int imagesRemaining) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: KipikTheme.rouge, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Quotas d\'utilisation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'PermanentMarker',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuotaItem(
                icon: Icons.chat_bubble,
                label: 'Questions restantes',
                value: '$dailyRemaining/8',
                isLow: dailyRemaining <= 2,
              ),
              _buildQuotaItem(
                icon: Icons.image,
                label: 'Images ce mois',
                value: '$imagesRemaining/3',
                isLow: imagesRemaining == 0,
              ),
            ],
          ),
          if (dailyRemaining <= 2 || imagesRemaining == 0) ...[
            const SizedBox(height: 8),
            Text(
              dailyRemaining == 0 
                  ? 'Revenez demain pour plus de questions !'
                  : imagesRemaining == 0
                      ? 'Limite d\'images atteinte ce mois'
                      : 'Attention : quotas bientôt épuisés',
              style: TextStyle(
                color: dailyRemaining == 0 ? Colors.red : Colors.orange,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotaItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isLow,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: isLow ? Colors.red : Colors.white70,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isLow ? Colors.red : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}