// lib/screens/guest/widgets/quick_stats_widget.dart

import 'package:flutter/material.dart';
import '../../../theme/kipik_theme.dart';

// Model simple pour les stats
class GuestStats {
  final int totalMissions;
  final int activeMissions;
  final int completedMissions;
  final int pendingRequests;
  final int incomingRequests;
  final double totalRevenue;
  final double monthlyRevenue;
  final double averageRating;
  final int totalReviews;

  const GuestStats({
    required this.totalMissions,
    required this.activeMissions,
    required this.completedMissions,
    required this.pendingRequests,
    required this.incomingRequests,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.averageRating,
    required this.totalReviews,
  });

  static GuestStats empty() => const GuestStats(
    totalMissions: 0,
    activeMissions: 0,
    completedMissions: 0,
    pendingRequests: 0,
    incomingRequests: 0,
    totalRevenue: 0.0,
    monthlyRevenue: 0.0,
    averageRating: 0.0,
    totalReviews: 0,
  );
}

class QuickStatsWidget extends StatelessWidget {
  final GuestStats stats;

  const QuickStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KipikTheme.rouge.withOpacity(0.8),
            Colors.purple.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Aperçu Guest',
                style: TextStyle(
                  fontFamily: 'PermanentMarker',
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Missions',
                '${stats.activeMissions}',
                Icons.handshake,
                'actives',
              ),
              _buildStatItem(
                'Revenus',
                '${stats.monthlyRevenue.toInt()}€',
                Icons.euro,
                'ce mois',
              ),
              _buildStatItem(
                'Note',
                '${stats.averageRating.toStringAsFixed(1)}',
                Icons.star,
                '${stats.totalReviews} avis',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'PermanentMarker',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}