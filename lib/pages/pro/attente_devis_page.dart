import 'package:flutter/material.dart';
import '../../models/quote_request.dart';
import '../../services/quote/quote_service.dart';
import '../../locator.dart';
import '../common/quote_detail_page.dart';

class AttenteDevisPage extends StatefulWidget {
  const AttenteDevisPage({Key? key}) : super(key: key);
  @override State<AttenteDevisPage> createState() => _AttenteDevisPageState();
}
class _AttenteDevisPageState extends State<AttenteDevisPage> {
  final _service = locator<QuoteService>();
  late Future<List<QuoteRequest>> _future;
  @override void initState() {
    super.initState();
    _future = _service.fetchRequestsForPro();
  }
  @override Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes de devis')),
      body: FutureBuilder<List<QuoteRequest>>(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final q = list[i];
              final remaining = q.proRespondBy!
                .difference(DateTime.now()).inHours;
              return ListTile(
                title: Text(q.clientName),
                subtitle: Text('Statut: ${q.status} – $remaining h restantes'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuoteDetailPage(
                    requestId: q.id, isPro: true)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
