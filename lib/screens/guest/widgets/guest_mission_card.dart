// lib/screens/guest/widgets/guest_mission_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/kipik_theme.dart';
// 🔥 UTILISE TES VRAIS MODELS
import '../../../models/guest_mission.dart';

enum GuestMissionCardType { active, pending, incoming, completed }

class GuestMissionCard extends StatelessWidget {
  final GuestMission mission;
  final GuestMissionCardType type;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onViewContract;

  const GuestMissionCard({
    super.key,
    required this.mission,
    required this.type,
    this.onTap,
    this.onAccept,
    this.onDecline,
    this.onViewContract,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: _getBorder(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildContent(),
            if (_showActions()) _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withOpacity(0.8),
            _getStatusColor().withOpacity(0.6),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              mission.isIncoming ? Icons.person : Icons.store,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.isIncoming ? mission.guestName : mission.shopName,
                  style: const TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  mission.location,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mission.typeLabel.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  mission.statusLabel,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dates
          Row(
            children: [
              Icon(Icons.calendar_today, color: KipikTheme.rouge, size: 16),
              const SizedBox(width: 8),
              Text(
                '${_formatDate(mission.startDate)} - ${_formatDate(mission.endDate)}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (mission.isActive && mission.daysRemaining > 0) ...[
                Icon(Icons.access_time, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${mission.daysRemaining}j restants',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Styles et durée
          Row(
            children: [
              Icon(Icons.brush, color: KipikTheme.rouge, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.styles.join(', '),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '${mission.duration.inDays} jours',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Détails financiers
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Commission',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${(mission.commissionRate * 100).toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hébergement',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Icon(
                      mission.accommodationIncluded ? Icons.check : Icons.close,
                      color: mission.accommodationIncluded ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ],
                ),
                if (mission.totalRevenue != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenus',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${mission.totalRevenue!.toInt()}€',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    switch (type) {
      case GuestMissionCardType.incoming:
        return _buildIncomingActions();
      case GuestMissionCardType.pending:
        return _buildPendingActions();
      case GuestMissionCardType.active:
        return _buildActiveActions();
      case GuestMissionCardType.completed:
        return _buildCompletedActions();
    }
  }

  Widget _buildIncomingActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onDecline?.call();
              },
              icon: const Icon(Icons.close, size: 16),
              label: const Text(
                'Refuser',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onAccept?.call();
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text(
                'Accepter',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => onTap?.call(),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text(
                'Voir détails',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, color: Colors.orange, size: 16),
                SizedBox(width: 6),
                Text(
                  'En attente...',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => onTap?.call(),
              icon: const Icon(Icons.timeline, size: 16),
              label: const Text(
                'Suivi',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onViewContract?.call(),
              icon: const Icon(Icons.description, size: 16),
              label: const Text(
                'Contrat',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => onTap?.call(),
              icon: const Icon(Icons.summarize, size: 16),
              label: const Text(
                'Résumé',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Action noter
              },
              icon: const Icon(Icons.star, size: 16),
              label: const Text(
                'Noter',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods - utilisent TES propriétés du model
  Color _getStatusColor() {
    switch (mission.status) {
      case GuestMissionStatus.pending:
        return Colors.orange;
      case GuestMissionStatus.accepted:
        return Colors.green;
      case GuestMissionStatus.active:
        return Colors.blue;
      case GuestMissionStatus.completed:
        return Colors.purple;
      case GuestMissionStatus.cancelled:
        return Colors.red;
    }
  }

  Border? _getBorder() {
    if (type == GuestMissionCardType.incoming) {
      return Border.all(
        color: Colors.orange.withOpacity(0.4),
        width: 2,
      );
    }
    return null;
  }

  bool _showActions() {
    return onAccept != null || 
           onDecline != null || 
           onViewContract != null ||
           type == GuestMissionCardType.pending ||
           type == GuestMissionCardType.active ||
           type == GuestMissionCardType.completed;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    
    return '${date.day} ${months[date.month - 1]}';
  }
}