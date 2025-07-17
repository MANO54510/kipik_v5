// lib/pages/admin/conventions/admin_convention_create_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';

class AdminConventionCreatePage extends StatefulWidget {
  const AdminConventionCreatePage({Key? key}) : super(key: key);

  @override
  State<AdminConventionCreatePage> createState() => _AdminConventionCreatePageState();
}

class _AdminConventionCreatePageState extends State<AdminConventionCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _statusOpts = ['draft', 'published', 'active', 'finished', 'cancelled'];
  String _status = 'draft';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBarKipik(
        title: 'Nouvelle Convention',
        showBackButton: true,
        useProStyle: true,
      ),
      body: KipikTheme.pageContent(
        scrollable: true,
        children: [
          Text('Créer une convention', style: KipikTheme.titleStyle),
          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: _statusOpts.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 32),

                KipikTheme.primaryButton(
                  text: 'Créer',
                  onPressed: _create,
                  isLoading: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final id = const Uuid().v4();
    await FirebaseFirestore.instance.collection('conventions').doc(id).set({
      'name': _nameCtrl.text.trim(),
      'status': _status,
      'createdAt': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }
}
