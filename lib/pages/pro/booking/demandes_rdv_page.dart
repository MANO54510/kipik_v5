// lib/pages/pro/booking/demandes_rdv_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../widgets/common/drawers/custom_drawer_kipik.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';


class DemandesRdvPage extends StatelessWidget {
  const DemandesRdvPage({Key? key}) : super(key: key);

  Stream<QuerySnapshot> get _demandesStream {
    final uid = SecureAuthService.instance.currentUserId;
    return FirebaseFirestore.instance
      .collection('booking_requests')
      .where('proId', isEqualTo: uid)
      .orderBy('requestedAt', descending: true)
      .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarKipik(
        title: 'Demandes de RDV',
        subtitle: 'En attente de validation',
        showBackButton: true,
        useProStyle: true,
      ),
      endDrawer: const CustomDrawerKipik(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _demandesStream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: KipikTheme.loading());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: KipikTheme.emptyState(
              icon: Icons.event_note,
              title: 'Aucune demande',
              message: 'Vous n’avez aucune nouvelle demande.',
            ));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final clientName = data['clientName'] ?? '–';
              final date = (data['requestedAt'] as Timestamp).toDate();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.access_time, color: KipikTheme.rouge),
                  title: Text(clientName, style: KipikTheme.cardTitleStyle),
                  subtitle: Text(
                    KipikTheme.formatDate(date),
                    style: KipikTheme.bodyTextSecondary,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/pro/booking/rdv-validation',
                        arguments: docs[i].id,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
