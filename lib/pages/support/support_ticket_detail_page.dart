// lib/pages/support/support_ticket_detail_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/models/support_ticket.dart';
import 'package:kipik_v5/models/chat_message.dart';
import 'package:kipik_v5/services/chat/chat_manager.dart';

class SupportTicketDetailPage extends StatefulWidget {
  final SupportTicket ticket;

  const SupportTicketDetailPage({
    Key? key,
    required this.ticket,
  }) : super(key: key);

  @override
  State<SupportTicketDetailPage> createState() => _SupportTicketDetailPageState();
}

class _SupportTicketDetailPageState extends State<SupportTicketDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    setState(() => _isLoading = true);
    
    ChatManager.supportMessages(widget.ticket.id).listen(
      (messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _isLoading = false;
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Erreur de chargement des messages');
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: widget.ticket.userId,
      timestamp: DateTime.now(),
    );

    try {
      await ChatManager.sendSupportMessage(widget.ticket.id, message);
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackBar('Erreur d\'envoi du message');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _closeTicket() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fermer le ticket'),
        content: const Text(
          'Êtes-vous sûr de vouloir fermer ce ticket ?\n\nVous ne pourrez plus ajouter de messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ChatManager.closeSupportTicket(widget.ticket.id);
                Navigator.pop(context); // Retour à la liste
              } catch (e) {
                _showErrorSnackBar('Erreur lors de la fermeture');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Fermer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSendMessages = !widget.ticket.isClosed;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ticket.subject,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Ticket #${widget.ticket.id.substring(0, 8)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (canSendMessages)
            IconButton(
              onPressed: _closeTicket,
              icon: const Icon(Icons.close, color: Colors.white70),
              tooltip: 'Fermer le ticket',
            ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec infos du ticket
          _buildTicketHeader(),
          
          // Messages
          Expanded(
            child: _isLoading
                ? _buildLoadingView()
                : _buildMessagesList(),
          ),
          
          // Zone de saisie
          if (canSendMessages) _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTicketHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icône de catégorie
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.ticket.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(widget.ticket.category),
                  color: _getCategoryColor(widget.ticket.category),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.ticket.categoryDisplay,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              // Badge de statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.ticket.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.ticket.statusDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(widget.ticket.status),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              if (widget.ticket.isHighPriority) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
                'Créé le ${_formatDate(widget.ticket.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              if (widget.ticket.assignedToAgent != null) ...[
                const SizedBox(width: 16),
                const Icon(
                  Icons.person,
                  size: 12,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 4),
                Text(
                  'Assigné à ${widget.ticket.assignedToAgent}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: const Text(
            'Aucun message dans ce ticket',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isAgent = message.senderId.startsWith('agent_');
    final isUser = message.senderId == widget.ticket.userId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAgent) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.support_agent, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAgent
                    ? Colors.blue.withOpacity(0.1)
                    : isUser
                        ? KipikTheme.rouge
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isAgent ? 8 : 20),
                  topRight: Radius.circular(isAgent ? 20 : 8),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                border: isAgent
                    ? Border.all(color: Colors.blue.withOpacity(0.2))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasText)
                    Text(
                      message.text!,
                      style: TextStyle(
                        color: isAgent
                            ? Colors.blue[800]
                            : isUser
                                ? Colors.white
                                : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    message.timeDisplay,
                    style: TextStyle(
                      color: isAgent
                          ? Colors.blue.withOpacity(0.7)
                          : isUser
                              ? Colors.white70
                              : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: KipikTheme.rouge,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Écrivez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: _isSending ? null : _sendMessage,
            backgroundColor: Colors.blue,
            mini: true,
            child: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ],
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
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}