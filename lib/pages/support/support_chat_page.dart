// lib/pages/support/support_chat_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/models/support_ticket.dart';
import 'package:kipik_v5/models/chat_message.dart';
import 'package:kipik_v5/services/chat/chat_manager.dart';
import 'package:kipik_v5/pages/support/support_ticket_detail_page.dart';
import 'package:kipik_v5/pages/support/create_support_ticket_page.dart';

class SupportChatPage extends StatefulWidget {
  final String userId;

  const SupportChatPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    setState(() => _isLoading = true);
    
    ChatManager.userSupportTickets(widget.userId).listen(
      (tickets) {
        if (mounted) {
          setState(() {
            _tickets = tickets;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Erreur de chargement des tickets');
        }
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _createNewTicket() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSupportTicketPage(userId: widget.userId),
      ),
    );
  }

  void _openTicket(SupportTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupportTicketDetailPage(ticket: ticket),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Support Client',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'PermanentMarker',
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _tickets.isEmpty
              ? _buildEmptyView()
              : _buildTicketsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTicket,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouveau ticket',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chargement de vos tickets...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.support_agent,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun ticket de support',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'PermanentMarker',
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vous n\'avez pas encore de demande de support.\nCréez un ticket si vous avez besoin d\'aide !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewTicket,
              icon: const Icon(Icons.add),
              label: const Text('Créer un ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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

  Widget _buildTicketsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        return _buildTicketCard(_tickets[index]);
      },
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openTicket(ticket),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec statut et catégorie
              Row(
                children: [
                  // Icône de catégorie
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(ticket.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(ticket.category),
                      color: _getCategoryColor(ticket.category),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.subject,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ticket.categoryDisplay,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.statusDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(ticket.status),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informations du ticket
              Row(
                children: [
                  if (ticket.isHighPriority) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRIORITÉ HAUTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'Créé ${_formatDate(ticket.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'bug':
        return Colors.red;
      case 'question':
        return Colors.blue;
      case 'suggestion':
        return Colors.green;
      case 'payment':
        return Colors.orange;
      case 'account':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'bug':
        return Icons.bug_report;
      case 'question':
        return Icons.help;
      case 'suggestion':
        return Icons.lightbulb;
      case 'payment':
        return Icons.payment;
      case 'account':
        return Icons.account_circle;
      default:
        return Icons.support;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'waiting_customer':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'hier';
    } else if (difference.inDays < 7) {
      return 'il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}