// lib/pages/pro/attente_devis_page.dart

import 'package:flutter/material.dart';
import '../../models/quote_request.dart';
import '../../services/quote/enhanced_quote_service.dart'; // ✅ MIGRATION
import '../../theme/kipik_theme.dart';
import '../../core/database_manager.dart'; // ✅ AJOUTÉ pour indicateur mode
import '../common/quote_detail_page.dart';

class AttenteDevisPage extends StatefulWidget {
  const AttenteDevisPage({Key? key}) : super(key: key);

  @override
  State<AttenteDevisPage> createState() => _AttenteDevisPageState();
}

class _AttenteDevisPageState extends State<AttenteDevisPage> {
  final _service = EnhancedQuoteService.instance; // ✅ MIGRATION
  late Future<List<QuoteRequest>> _future;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  /// ✅ CHARGEMENT DES DEVIS AVEC GESTION D'ERREUR
  void _loadQuotes() {
    setState(() {
      _future = _service.fetchRequestsForPro();
    });
  }

  /// ✅ RAFRAÎCHISSEMENT MANUEL
  Future<void> _refreshQuotes() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // UX
      _loadQuotes();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ✅ FORMATER LE TEMPS RESTANT
  String _formatTimeRemaining(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      return 'Expiré';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}j restants';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h restantes';
    } else {
      return '${difference.inMinutes}min restantes';
    }
  }

  /// ✅ COULEUR SELON L'URGENCE
  Color _getUrgencyColor(DateTime deadline) {
    final now = DateTime.now();
    final hoursRemaining = deadline.difference(now).inHours;
    
    if (hoursRemaining < 0) return Colors.red; // Expiré
    if (hoursRemaining < 24) return Colors.orange; // Urgent
    if (hoursRemaining < 72) return Colors.amber; // Attention
    return Colors.green; // OK
  }

  /// ✅ ICÔNE SELON LE STATUT
  IconData _getStatusIcon(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.Pending:
        return Icons.schedule;
      case QuoteStatus.Quoted:
        return Icons.request_quote;
      case QuoteStatus.Accepted:
        return Icons.check_circle;
      case QuoteStatus.Refused:
        return Icons.cancel;
      case QuoteStatus.Expired:
        return Icons.timer_off;
    }
  }

  /// ✅ COULEUR SELON LE STATUT
  Color _getStatusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.Pending:
        return Colors.blue;
      case QuoteStatus.Quoted:
        return Colors.orange;
      case QuoteStatus.Accepted:
        return Colors.green;
      case QuoteStatus.Refused:
        return Colors.red;
      case QuoteStatus.Expired:
        return Colors.grey;
    }
  }

  /// ✅ LABEL DU STATUT EN FRANÇAIS
  String _getStatusLabel(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.Pending:
        return 'En attente';
      case QuoteStatus.Quoted:
        return 'Devis envoyé';
      case QuoteStatus.Accepted:
        return 'Accepté';
      case QuoteStatus.Refused:
        return 'Refusé';
      case QuoteStatus.Expired:
        return 'Expiré';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Demandes de devis',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            // ✅ Indicateur mode démo
            if (DatabaseManager.instance.isDemoMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text(
                  '🎭 ${DatabaseManager.instance.activeDatabaseConfig.name.split(' ').first}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshQuotes,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<QuoteRequest>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }
            
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }
            
            final quotes = snapshot.data!;
            
            // ✅ Trier par priorité (en attente d'abord, puis par deadline)
            quotes.sort((a, b) {
              if (a.status == QuoteStatus.Pending && b.status != QuoteStatus.Pending) {
                return -1;
              }
              if (b.status == QuoteStatus.Pending && a.status != QuoteStatus.Pending) {
                return 1;
              }
              if (a.proRespondBy != null && b.proRespondBy != null) {
                return a.proRespondBy!.compareTo(b.proRespondBy!);
              }
              return b.createdAt.compareTo(a.createdAt);
            });

            return RefreshIndicator(
              onRefresh: _refreshQuotes,
              color: KipikTheme.rouge,
              child: _buildQuotesList(quotes),
            );
          },
        ),
      ),
    );
  }

  /// ✅ ÉTAT DE CHARGEMENT
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            DatabaseManager.instance.isDemoMode 
                ? 'Chargement des devis de démonstration...'
                : 'Chargement de vos demandes de devis...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ ÉTAT D'ERREUR
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DatabaseManager.instance.isDemoMode 
                  ? 'Impossible de charger les devis de démonstration'
                  : 'Impossible de charger vos demandes de devis',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshQuotes,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ ÉTAT VIDE
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.request_quote_outlined,
                color: Colors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune demande de devis',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DatabaseManager.instance.isDemoMode 
                  ? 'Aucune demande de devis en démonstration pour le moment.'
                  : 'Vous n\'avez reçu aucune demande de devis pour le moment.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Roboto',
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshQuotes,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ LISTE DES DEVIS
  Widget _buildQuotesList(List<QuoteRequest> quotes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return _buildQuoteCard(quote);
      },
    );
  }

  /// ✅ CARTE DEVIS MODERNE
  Widget _buildQuoteCard(QuoteRequest quote) {
    final statusColor = _getStatusColor(quote.status);
    final statusLabel = _getStatusLabel(quote.status);
    final statusIcon = _getStatusIcon(quote.status);
    
    final timeRemaining = quote.proRespondBy != null 
        ? _formatTimeRemaining(quote.proRespondBy!)
        : '';
    final urgencyColor = quote.proRespondBy != null 
        ? _getUrgencyColor(quote.proRespondBy!)
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuoteDetailPage(
              requestId: quote.id,
              isPro: true,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ En-tête avec client et statut
            Row(
              children: [
                // Avatar client
                CircleAvatar(
                  backgroundColor: KipikTheme.rouge.withOpacity(0.1),
                  child: Text(
                    quote.clientName.isNotEmpty 
                        ? quote.clientName[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      color: KipikTheme.rouge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Nom et email client
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.clientName,
                        style: const TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 16,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (quote.clientEmail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          quote.clientEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // ✅ Titre du projet
            Text(
              quote.projectTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
                fontFamily: 'Roboto',
              ),
            ),
            
            const SizedBox(height: 8),
            
            // ✅ Style et localisation
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    quote.style,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    quote.location,
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // ✅ Description (tronquée)
            Text(
              quote.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Roboto',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 16),
            
            // ✅ Pied avec budget et deadline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Budget
                if (quote.budget != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.euro,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Budget: ${quote.budget!.toStringAsFixed(0)}€',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Temps restant (seulement si en attente)
                if (quote.status == QuoteStatus.Pending && quote.proRespondBy != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: urgencyColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: urgencyColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeRemaining,
                          style: TextStyle(
                            color: urgencyColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Prix total (si devis envoyé)
                if (quote.totalPrice != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: KipikTheme.rouge,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Devis: ${quote.totalPrice!.toStringAsFixed(0)}€',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: KipikTheme.rouge,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            
            // ✅ Indicateur mode démo sur la carte
            if (DatabaseManager.instance.isDemoMode) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Text(
                  '🎭 Données de démonstration',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}