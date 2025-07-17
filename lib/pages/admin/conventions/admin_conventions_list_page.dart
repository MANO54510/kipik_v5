// lib/pages/admin/conventions/admin_conventions_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/custom_drawer_admin.dart';
import 'admin_convention_create_page.dart';
import 'admin_convention_detail_page.dart';

class AdminConventionsListPage extends StatelessWidget {
  const AdminConventionsListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Conventions',
        subtitle: 'Administration',
        showBackButton: true,
        useProStyle: true,
      ),
      endDrawer: const CustomDrawerAdmin(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KipikTheme.rouge,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminConventionCreatePage()),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conventions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: KipikTheme.loading());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: KipikTheme.emptyState(
              icon: Icons.event_busy,
              title: 'Aucune convention',
              message: 'Créez-en une nouvelle.',
              action: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Créer'),
                style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminConventionCreatePage()),
                  );
                },
              ),
            ));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final status = data['status'] ?? '—';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['name'] ?? 'Sans nom', style: KipikTheme.cardTitleStyle),
                  subtitle: Text('Statut : $status', style: KipikTheme.bodyTextSecondary),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminConventionDetailPage(conventionId: docs[i].id)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
