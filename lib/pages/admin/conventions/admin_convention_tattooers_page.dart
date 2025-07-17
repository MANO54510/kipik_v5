// lib/pages/admin/conventions/admin_convention_tattooers_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';

class AdminConventionTattooersPage extends StatelessWidget {
  final String conventionId;
  const AdminConventionTattooersPage({Key? key, required this.conventionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tattooersColl = FirebaseFirestore.instance
        .collection('conventions')
        .doc(conventionId)
        .collection('tattooers');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Tatoueurs inscrits',
        showBackButton: true,
        useProStyle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: tattooersColl.snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: KipikTheme.loading());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Aucun tatoueur inscrit'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(child: Text(data['name']?.substring(0,1) ?? '?')),
                  title: Text(data['name'] ?? 'Sans nom', style: KipikTheme.cardTitleStyle),
                  subtitle: Text('Stand : ${data['standNumber'] ?? '—'}', style: KipikTheme.bodyTextSecondary),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_red_eye),
                    onPressed: () {
                      // TODO: afficher profil détaillé ou actions (annuler inscription…)
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
