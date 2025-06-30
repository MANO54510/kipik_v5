import 'package:flutter/material.dart';
import '../../../models/quote_request.dart';
import '../../services/quote/quote_service.dart';
import '../../../locator.dart';
import '../../services/payment/payment_service.dart';

class QuoteDetailPage extends StatefulWidget {
  final String requestId;
  final bool isPro;
  const QuoteDetailPage({required this.requestId, required this.isPro, Key? key}) : super(key: key);
  @override State<QuoteDetailPage> createState() => _QuoteDetailPageState();
}
class _QuoteDetailPageState extends State<QuoteDetailPage> {
  final _quoteService = locator<QuoteService>();
  final _paymentService = locator<PaymentService>();
  late Future<QuoteRequest> _future;
  @override void initState() {
    super.initState();
    _future = _quoteService.fetchRequestDetail(widget.requestId);
  }
  @override Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isPro ? 'Traiter demande' : 'Détail devis')),
      body: FutureBuilder<QuoteRequest>(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final q = snap.data!;
          // TODO: selon widget.isPro & q.status, afficher UI + boutons
          // Ex. si isPro && status==Pending → boutons Accepter/Refuser
          return Center(child: Text('TODO: UI selon rôle & statut'));
        },
      ),
    );
  }
}
