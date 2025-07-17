// lib/pages/admin/conventions/admin_convention_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'admin_convention_tattooers_page.dart';

class AdminConventionDetailPage extends StatelessWidget {
  final String conventionId;
  const AdminConventionDetailPage({Key? key, required this.conventionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Détails Convention',
        showBackButton: true,
        useProStyle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('conventions').doc(conventionId).snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Convention introuvable'));
          }
          final data = snap.data!.data() as Map<String, dynamic>;

          return KipikTheme.pageContent(
            scrollable: true,
            children: [
              Text(data['name'] ?? 'Sans nom', style: KipikTheme.titleStyle),
              const SizedBox(height: 12),
              Text('Statut : ${data['status']}', style: KipikTheme.subtitleStyle),
              const SizedBox(height: 24),

              KipikTheme.primaryButton(
                text: 'Gérer les tatoueurs',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminConventionTattooersPage(conventionId: conventionId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              KipikTheme.secondaryButton(
                text: 'Modifier détails',
                onPressed: () {
                  // TODO: ouvrir un modal ou page d’édition inline
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
