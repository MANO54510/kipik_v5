// lib/widgets/shared/booking_chat_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../theme/kipik_theme.dart';
import '../../models/flash/flash_booking.dart';
import '../../models/flash/flash_booking_status.dart';
import '../../services/auth/secure_auth_service.dart';

/// Widget de chat intégré pour les réservations
/// Peut être utilisé dans les pages ou comme bottom sheet
class BookingChatWidget extends StatefulWidget {
  final FlashBooking booking;
  final bool isEmbedded;
  final double? height;
  final Function(String message)? onMessageSent;
  final VoidCallback? onClose;

  const BookingChatWidget({
    Key? key,
    required this.booking,
    this.isEmbedded = true,
    this.height,
    this.onMessageSent,
    this.onClose,
  }) : super(key: key);

  @override
  State<BookingChatWidget> createState() => _BookingChatWidgetState();
}

class _BookingChatWidgetState extends State<BookingChatWidget>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingController;
  
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isSending = false;
  Timer? _typingTimer;
  late String _currentUserId;
  late bool _isClient;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _setupTypingAnimation();
  }

  void _setupTypingAnimation() {
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  void _initializeChat() {
    final currentUser = SecureAuthService.instance.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser['uid'] ?? '';
      _isClient = _currentUserId == widget.booking.clientId;
      _loadMessages();
    }
  }

  void _loadMessages() {
    // Générer des messages de démo basés sur le statut de la réservation
    _messages = _generateMessagesForBooking();
    setState(() {});
    
    // Auto-scroll vers le bas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  List<ChatMessage> _generateMessagesForBooking() {
    final messages = <ChatMessage>[];
    final now = DateTime.now();
    
    // Message système d'ouverture
    messages.add(ChatMessage(
      id: 'sys_1',
      senderId: 'system',
      senderName: 'Système',
      message: 'Chat ouvert pour votre réservation',
      timestamp: now.subtract(const Duration(hours: 1)),
      type: ChatMessageType.system,
    ));

    // Messages selon le statut
    switch (widget.booking.status) {
      case FlashBookingStatus.pending:
        _addPendingMessages(messages, now);
        break;
      case FlashBookingStatus.quoteSent:
        _addQuoteSentMessages(messages, now);
        break;
      case FlashBookingStatus.depositPaid:
        _addDepositPaidMessages(messages, now);
        break;
      case FlashBookingStatus.confirmed:
        _addConfirmedMessages(messages, now);
        break;
      case FlashBookingStatus.completed:
        _addCompletedMessages(messages, now);
        break;
      default:
        _addDefaultMessages(messages, now);
    }

    return messages;
  }

  void _addPendingMessages(List<ChatMessage> messages, DateTime now) {
    if (_isClient) {
      messages.add(ChatMessage(
        id: 'msg_1',
        senderId: widget.booking.clientId,
        senderName: 'Vous',
        message: 'Bonjour ! Je suis très intéressé par votre flash. Pouvez-vous me confirmer la disponibilité ?',
        timestamp: now.subtract(const Duration(minutes: 45)),
        type: ChatMessageType.text,
      ));
      
      messages.add(ChatMessage(
        id: 'msg_2',
        senderId: widget.booking.tattooArtistId,
        senderName: 'Tatoueur',
        message: 'Salut ! Merci pour votre intérêt. Je regarde votre demande et vous envoie un devis personnalisé très bientôt 🎨',
        timestamp: now.subtract(const Duration(minutes: 30)),
        type: ChatMessageType.text,
      ));
    } else {
      messages.add(ChatMessage(
        id: 'msg_1',
        senderId: widget.booking.clientId,
        senderName: 'Client',
        message: 'Bonjour ! J\'aimerais réserver ce flash pour le ${_formatDate(widget.booking.requestedDate)}',
        timestamp: now.subtract(const Duration(minutes: 45)),
        type: ChatMessageType.text,
      ));
    }
  }

  void _addQuoteSentMessages(List<ChatMessage> messages, DateTime now) {
    messages.add(ChatMessage(
      id: 'msg_quote',
      senderId: widget.booking.tattooArtistId,
      senderName: 'Tatoueur',
      message: 'Parfait ! Je vous ai envoyé un devis personnalisé. Le prix est de ${widget.booking.totalPrice.toInt()}€ avec un acompte de ${widget.booking.depositAmount.toInt()}€.',
      timestamp: now.subtract(const Duration(minutes: 20)),
      type: ChatMessageType.quote,
    ));

    if (_isClient) {
      messages.add(ChatMessage(
        id: 'msg_client_resp',
        senderId: widget.booking.clientId,
        senderName: 'Vous',
        message: 'Merci ! Le prix me convient, je procède au paiement de l\'acompte.',
        timestamp: now.subtract(const Duration(minutes: 15)),
        type: ChatMessageType.text,
      ));
    }
  }

  void _addDepositPaidMessages(List<ChatMessage> messages, DateTime now) {
    messages.add(ChatMessage(
      id: 'msg_payment',
      senderId: 'system',
      senderName: 'Système',
      message: 'Acompte de ${widget.booking.depositAmount.toInt()}€ reçu avec succès ✅',
      timestamp: now.subtract(const Duration(minutes: 10)),
      type: ChatMessageType.payment,
    ));

    messages.add(ChatMessage(
      id: 'msg_waiting',
      senderId: widget.booking.tattooArtistId,
      senderName: 'Tatoueur',
      message: 'Acompte bien reçu ! Je confirme votre créneau dans les plus brefs délais.',
      timestamp: now.subtract(const Duration(minutes: 5)),
      type: ChatMessageType.text,
    ));
  }

  void _addConfirmedMessages(List<ChatMessage> messages, DateTime now) {
    messages.add(ChatMessage(
      id: 'msg_confirmed',
      senderId: 'system',
      senderName: 'Système',
      message: 'RDV confirmé pour le ${_formatDate(widget.booking.requestedDate)} à ${widget.booking.timeSlot} 🎉',
      timestamp: now.subtract(const Duration(minutes: 5)),
      type: ChatMessageType.confirmation,
    ));

    messages.add(ChatMessage(
      id: 'msg_prep',
      senderId: widget.booking.tattooArtistId,
      senderName: 'Tatoueur',
      message: 'Super ! Pensez à bien hydrater votre peau et évitez l\'alcool 24h avant le RDV 💧',
      timestamp: now.subtract(const Duration(minutes: 2)),
      type: ChatMessageType.text,
    ));
  }

  void _addCompletedMessages(List<ChatMessage> messages, DateTime now) {
    messages.add(ChatMessage(
      id: 'msg_completed',
      senderId: 'system',
      senderName: 'Système',
      message: 'Session terminée avec succès ! 🎨✨',
      timestamp: now.subtract(const Duration(hours: 2)),
      type: ChatMessageType.completion,
    ));

    messages.add(ChatMessage(
      id: 'msg_thanks',
      senderId: widget.booking.tattooArtistId,
      senderName: 'Tatoueur',
      message: 'Merci pour votre confiance ! N\'hésitez pas à partager une photo une fois cicatrisé 📸',
      timestamp: now.subtract(const Duration(hours: 1)),
      type: ChatMessageType.text,
    ));
  }

  void _addDefaultMessages(List<ChatMessage> messages, DateTime now) {
    messages.add(ChatMessage(
      id: 'msg_default',
      senderId: widget.booking.tattooArtistId,
      senderName: 'Tatoueur',
      message: 'N\'hésitez pas si vous avez des questions !',
      timestamp: now.subtract(const Duration(minutes: 30)),
      type: ChatMessageType.text,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: widget.isEmbedded 
            ? BorderRadius.circular(16)
            : const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
      ),
      child: Column(
        children: [
          if (!widget.isEmbedded) _buildHeader(),
          _buildBookingStatusBar(),
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Chat RDV',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (widget.onClose != null)
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingStatusBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _getStatusColor().withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            widget.booking.status.displayText,
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'RDV ${_formatDate(widget.booking.requestedDate)}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId == _currentUserId;
    final isSystem = message.type != ChatMessageType.text;
    
    if (isSystem) {
      return _buildSystemMessage(message);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(message.senderName),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isMe 
                        ? LinearGradient(
                            colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
                          )
                        : null,
                    color: isMe ? null : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(message.senderName),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    Color messageColor;
    IconData messageIcon;
    
    switch (message.type) {
      case ChatMessageType.system:
        messageColor = Colors.grey.shade400;
        messageIcon = Icons.info_outline;
        break;
      case ChatMessageType.quote:
        messageColor = Colors.blue;
        messageIcon = Icons.description;
        break;
      case ChatMessageType.payment:
        messageColor = Colors.green;
        messageIcon = Icons.payment;
        break;
      case ChatMessageType.confirmation:
        messageColor = Colors.green;
        messageIcon = Icons.check_circle;
        break;
      case ChatMessageType.completion:
        messageColor = KipikTheme.rouge;
        messageIcon = Icons.celebration;
        break;
      default:
        messageColor = Colors.grey.shade400;
        messageIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: messageColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: messageColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(messageIcon, color: messageColor, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.message,
                  style: TextStyle(
                    color: messageColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: KipikTheme.rouge,
      child: Text(
        name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildAvatar('Tatoueur'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'En train d\'écrire',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _typingController,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final delay = index * 0.3;
                        final animationValue = (_typingController.value + delay) % 1.0;
                        final opacity = animationValue < 0.5 
                            ? animationValue * 2 
                            : (1 - animationValue) * 2;
                        
                        return Container(
                          margin: const EdgeInsets.only(right: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: KipikTheme.rouge.withOpacity(opacity),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _showAttachmentOptions,
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.grey.shade600,
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Écrivez votre message...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: _onMessageChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: _messageController.text.trim().isNotEmpty
                    ? LinearGradient(
                        colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
                      )
                    : null,
                color: _messageController.text.trim().isEmpty
                    ? Colors.grey.shade700
                    : null,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _messageController.text.trim().isNotEmpty && !_isSending
                    ? _sendMessage
                    : null,
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _messageController.text.trim().isNotEmpty
                            ? Icons.send
                            : Icons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _onMessageChanged(String text) {
    setState(() {});
    
    // Simuler notification de frappe
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 500), () {
      // Ici on enverrait une notification de frappe en vrai
    });
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        senderName: 'Vous',
        message: messageText,
        timestamp: DateTime.now(),
        type: ChatMessageType.text,
      );

      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
      });

      _scrollToBottom();
      HapticFeedback.lightImpact();

      // Callback externe
      widget.onMessageSent?.call(messageText);

      // Simuler réponse automatique occasionnelle
      if (_messages.length % 3 == 0) {
        _simulateResponse();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _simulateResponse() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      setState(() => _isTyping = true);
      
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        
        final responses = [
          'Parfait ! Merci pour ces précisions.',
          'J\'ai bien noté, pas de problème.',
          'Super ! On se voit bientôt alors 😊',
          'Excellente question ! Voici ma réponse...',
          'Tout à fait, c\'est exactement ça !',
        ];
        
        final randomResponse = responses[DateTime.now().millisecond % responses.length];
        
        final responseMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: _isClient ? widget.booking.tattooArtistId : widget.booking.clientId,
          senderName: _isClient ? 'Tatoueur' : 'Client',
          message: randomResponse,
          timestamp: DateTime.now(),
          type: ChatMessageType.text,
        );

        setState(() {
          _isTyping = false;
          _messages.add(responseMessage);
        });
        
        _scrollToBottom();
      });
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Envoyer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildAttachmentOption(Icons.photo_camera, 'Photo'),
                _buildAttachmentOption(Icons.location_on, 'Position'),
                _buildAttachmentOption(Icons.description, 'Document'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label - Bientôt disponible'),
            backgroundColor: KipikTheme.rouge,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: KipikTheme.rouge, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Helper methods
  Color _getStatusColor() {
    switch (widget.booking.status) {
      case FlashBookingStatus.pending:
        return Colors.orange;
      case FlashBookingStatus.quoteSent:
        return Colors.blue;
      case FlashBookingStatus.depositPaid:
        return Colors.purple;
      case FlashBookingStatus.confirmed:
        return Colors.green;
      case FlashBookingStatus.completed:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.booking.status) {
      case FlashBookingStatus.pending:
        return Icons.schedule;
      case FlashBookingStatus.quoteSent:
        return Icons.description;
      case FlashBookingStatus.depositPaid:
        return Icons.payment;
      case FlashBookingStatus.confirmed:
        return Icons.check_circle;
      case FlashBookingStatus.completed:
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Modèle pour les messages de chat
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final ChatMessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.type = ChatMessageType.text,
  });
}

/// Types de messages de chat
enum ChatMessageType {
  text,          // Message normal
  system,        // Message système
  quote,         // Devis envoyé
  payment,       // Paiement effectué
  confirmation,  // RDV confirmé
  completion,    // Session terminée
}