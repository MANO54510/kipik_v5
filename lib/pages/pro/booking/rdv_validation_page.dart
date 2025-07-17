// lib/pages/pro/booking/rdv_validation_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/kipik_theme.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';
import '../../../widgets/common/drawers/custom_drawer_kipik.dart';
import 'package:kipik_v5/services/auth/secure_auth_service.dart';

class RdvValidationPage extends StatefulWidget {
  final String requestId;
  const RdvValidationPage({Key? key, required this.requestId}) : super(key: key);

  @override
  _RdvValidationPageState createState() => _RdvValidationPageState();
}

class _RdvValidationPageState extends State<RdvValidationPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _data;

  Future<void> _loadRequest() async {
    final doc = await FirebaseFirestore.instance
      .collection('booking_requests')
      .doc(widget.requestId)
      .get();
    if (doc.exists) {
      setState(() => _data = doc.data());
    }
  }

  Future<void> _handleDecision(bool accept) async {
    setState(() => _isLoading = true);
    final proId = SecureAuthService.instance.currentUserId;
    final ref = FirebaseFirestore.instance.collection('booking_requests').doc(widget.requestId);
    await ref.update({
      'status': accept ? 'confirmed' : 'rejected',
      'handledBy': proId,
      'handledAt': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context, accept);
  }

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: const CustomAppBarKipik(
        title: 'Validation RDV',
        showBackButton: true,
        useProStyle: true,
      ),
      endDrawer: const CustomDrawerKipik(),
      body: data == null
        ? Center(child: KipikTheme.loading())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Client : ${data['clientName']}', style: KipikTheme.titleStyle),
                const SizedBox(height: 8),
                Text('Email : ${data['clientEmail']}', style: KipikTheme.bodyTextStyle),
                const SizedBox(height: 8),
                Text('Téléphone : ${data['clientPhone']}', style: KipikTheme.bodyTextStyle),
                const SizedBox(height: 16),
                Text('Date proposée :', style: KipikTheme.subtitleStyle),
                const SizedBox(height: 4),
                Text(KipikTheme.formatDate((data['requestedAt'] as Timestamp).toDate()), style: KipikTheme.bodyTextStyle),
                const Spacer(),
                if (_isLoading)
                  Center(child: KipikTheme.loading())
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleDecision(false),
                          child: const Text('Rejeter'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: KipikTheme.rouge),
                          onPressed: () => _handleDecision(true),
                          child: const Text('Accepter'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
    );
  }
}
