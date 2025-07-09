// lib/pages/shared/booking/booking_chat_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../../../theme/kipik_theme.dart';
import '../../../models/flash/flash_booking.dart';
import '../../../models/flash/flash_booking_status.dart';
import '../../../models/flash/flash.dart';
import '../../../services/flash/flash_service.dart';
import '../../../services/auth/secure_auth_service.dart';
import '../../../widgets/common/app_bars/custom_app_bar_kipik.dart';

/// Page de chat sophistiquée dédiée pour un booking de flash
class BookingChatPage extends StatefulWidget {
  final FlashBooking booking;

  const BookingChatPage({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<BookingChatPage> createState() => _BookingChatPageState();
}

class _BookingChatPageState extends State<BookingChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingAnimationController;
  late AnimationController _statusAnimationController;
  
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  Flash? _flash;
  List<ChatMessage> _messages = [];
  Timer? _typingTimer;
  
  late String _currentUserId;
  late bool _isClient;
  late String _otherUserName;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
  }

  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _statusAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _statusAnimationController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) return;

      _currentUserId = currentUser['uid'] ?? '';
      _isClient = _currentUserId == widget.booking.clientId;

      // Charger les détails du flash
      _flash = await FlashService.instance.getFlashById(widget.booking.flashId);
      
      // Déterminer le nom de l'autre utilisateur
      _otherUserName = _isClient 
          ? (_flash?.tattooArtistName ?? 'Tatoueur')
          : 'Client';
      
      // Charger les messages (simulés pour la démo)
      _messages = _generateEnhancedMessages();
      
      setState(() => _isLoading = false);
      
      // Auto-scroll vers le bas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Simuler activité de frappe occasionnelle
      _startTypingSimulation();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur: ${e.toString()}');
    }
  }

  void _startTypingSimulation() {
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && Random().nextBool()) {
        _simulateOtherUserTyping();
      }
    });
  }

  void _simulateOtherUserTyping() {
    setState(() => _isTyping = true);
    
    Timer(Duration(seconds: 2 + Random().nextInt(3)), () {
      if (mounted) {
        setState(() => _isTyping = false);
        
        // Parfois ajouter un message automatique
        if (Random().nextDouble() < 0.3) {
          _addAutomaticMessage();
        }
      }
    });
  }

  void _addAutomaticMessage() {
    final autoMessages = _isClient ? [
      "J'ai regardé votre profil, votre style me plaît beaucoup !",
      "Pouvez-vous me dire si vous avez des créneaux plus tôt ?",
      "Ce flash sera parfait pour l'emplacement choisi 👌",
    ] : [
      "Parfait ! J'ai hâte de réaliser ce flash avec vous",
      "N'hésitez pas si vous avez des questions",
      "Pensez à bien hydrater votre peau avant le RDV 💧",
    ];

    final randomMessage = autoMessages[Random().nextInt(autoMessages.length)];
    
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _isClient ? widget.booking.tattooArtistId : widget.booking.clientId,
      senderName: _otherUserName,
      message: randomMessage,
      timestamp: DateTime.now(),
      messageType: MessageType.text,
    );

    setState(() {
      _messages.add(newMessage);
    });
    
    _scrollToBottom();
  }

  List<ChatMessage> _generateEnhancedMessages() {
    final now = DateTime.now();
    final messages = <ChatMessage>[
      ChatMessage(
        id: '1',
        senderId: 'system',
        senderName: 'Système',
        message: 'Chat ouvert pour votre réservation de flash "${_flash?.title ?? 'Flash'}"',
        timestamp: now.subtract(const Duration(hours: 2)),
        messageType: MessageType.system,
      ),
    ];

    if (_isClient) {
      messages.addAll([
        ChatMessage(
          id: '2',
          senderId: widget.booking.tattooArtistId,
          senderName: _flash?.tattooArtistName ?? 'Tatoueur',
          message: 'Salut ! J\'ai bien reçu votre demande pour le ${widget.booking.requestedDate.day}/${widget.booking.requestedDate.month} à ${widget.booking.timeSlot}. Je confirme votre créneau ! 🎨',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
          messageType: MessageType.text,
        ),
        ChatMessage(
          id: '3',
          senderId: widget.booking.clientId,
          senderName: 'Vous',
          message: 'Parfait ! J\'ai hâte de faire ce tatouage. Y a-t-il des préparations spéciales à prévoir ?',
          timestamp: now.subtract(const Duration(hours: 1)),
          messageType: MessageType.text,
        ),
        ChatMessage(
          id: '4',
          senderId: widget.booking.tattooArtistId,
          senderName: _flash?.tattooArtistName ?? 'Tatoueur',
          message: 'Pensez à bien vous hydrater la peau les jours précédents et évitez l\'alcool 24h avant. On se voit bientôt ! 🎨',
          timestamp: now.subtract(const Duration(minutes: 30)),
          messageType: MessageType.text,
        ),
        if (widget.booking.status == FlashBookingStatus.confirmed)
          ChatMessage(
            id: '5',
            senderId: 'system',
            senderName: 'Système',
            message: 'RDV confirmé pour le ${widget.booking.requestedDate.day}/${widget.booking.requestedDate.month} à ${widget.booking.timeSlot} ✅',
            timestamp: now.subtract(const Duration(minutes: 15)),
            messageType: MessageType.confirmation,
          ),
      ]);
    } else {
      messages.addAll([
        ChatMessage(
          id: '2',
          senderId: widget.booking.clientId,
          senderName: 'Client',
          message: 'Bonjour ! Je suis très intéressé par votre flash. Serait-il possible d\'avoir plus de détails ?',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
          messageType: MessageType.text,
        ),
        ChatMessage(
          id: '3',
          senderId: widget.booking.tattooArtistId,
          senderName: 'Vous',
          message: 'Bien sûr ! Ce flash fait environ ${_flash?.size ?? '8x6cm'} et serait parfait pour l\'emplacement que vous avez choisi. Le style ${_flash?.style ?? 'minimaliste'} se marie bien avec ce design.',
          timestamp: now.subtract(const Duration(hours: 1)),
          messageType: MessageType.text,
        ),
      ]);
    }

    return messages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: CustomAppBarKipik(
        title: 'Chat RDV',
        subtitle: '${_otherUserName} • ${widget.booking.status.displayText}',
        showBackButton: true,
        showNotificationIcon: false,
        useProStyle: true,
        actions: [
          IconButton(
            onPressed: _showBookingDetails,
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share_location',
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Partager position', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'send_image',
                child: Row(
                  children: [
                    Icon(Icons.photo_camera, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Envoyer photo', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'call',
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Appeler', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            onSelected: _handleMenuAction,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildChatContent(),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share_location':
        _shareLocation();
        break;
      case 'send_image':
        _sendImage();
        break;
      case 'call':
        _makeCall();
        break;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: KipikTheme.rouge,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chargement du chat...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent() {
    return Column(
      children: [
        _buildBookingHeader(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF0A0A0A).withOpacity(0.95),
                ],
              ),
            ),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _buildEnhancedMessageBubble(message);
              },
            ),
          ),
        ),
        _buildEnhancedMessageInput(),
      ],
    );
  }

  Widget _buildBookingHeader() {
    if (_flash == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF1A1A1A),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KipikTheme.rouge.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _flash!.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.booking.status),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(widget.booking.status),
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _flash!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(widget.booking.status),
                          color: _getStatusColor(widget.booking.status),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(widget.booking.status),
                          style: TextStyle(
                            color: _getStatusColor(widget.booking.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.booking.requestedDate.day}/${widget.booking.requestedDate.month} à ${widget.booking.timeSlot}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.booking.totalPrice.toInt()}€',
                    style: TextStyle(
                      color: KipikTheme.rouge,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.booking.depositAmount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.booking.depositAmount.toInt()}€ versé',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A2A2A),
            const Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image,
        color: Colors.grey.shade600,
        size: 24,
      ),
    );
  }

  Widget _buildEnhancedMessageBubble(ChatMessage message) {
    final isMe = message.senderId == _currentUserId;
    final isSystem = message.messageType == MessageType.system;
    final isConfirmation = message.messageType == MessageType.confirmation;

    if (isSystem || isConfirmation) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isConfirmation 
                  ? Colors.green.withOpacity(0.2) 
                  : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              border: isConfirmation 
                  ? Border.all(color: Colors.green.withOpacity(0.3)) 
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isConfirmation) ...[
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: isConfirmation ? Colors.green : Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: isConfirmation ? FontWeight.bold : FontWeight.normal,
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildMessageAvatar(message),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                    boxShadow: [
                      BoxShadow(
                        color: (isMe ? KipikTheme.rouge : Colors.black).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(message.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        color: Colors.grey.shade500,
                        size: 12,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildMessageAvatar(message),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageAvatar(ChatMessage message) {
    final isMe = message.senderId == _currentUserId;
    
    return CircleAvatar(
      radius: 16,
      backgroundColor: isMe ? Colors.blue : KipikTheme.rouge,
      child: Text(
        message.senderName[0].toUpperCase(),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: KipikTheme.rouge,
            child: Text(
              _otherUserName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
                  '$_otherUserName est en train d\'écrire',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _typingAnimationController,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final delay = index * 0.3;
                        final animationValue = (_typingAnimationController.value + delay) % 1.0;
                        final opacity = animationValue < 0.5 ? animationValue * 2 : (1 - animationValue) * 2;
                        
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

  Widget _buildEnhancedMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: const Border(top: BorderSide(color: Color(0xFF2A2A2A))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildAttachmentButton(),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Écrivez votre message...',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                        onChanged: _onMessageChanged,
                      ),
                    ),
                    _buildEmojiButton(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: _showAttachmentOptions,
        icon: const Icon(Icons.add, color: Colors.white),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  Widget _buildEmojiButton() {
    return IconButton(
      onPressed: _showEmojiPicker,
      icon: Icon(
        Icons.emoji_emotions_outlined,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildSendButton() {
    final hasText = _messageController.text.trim().isNotEmpty;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: hasText 
            ? LinearGradient(
                colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
              )
            : null,
        color: hasText ? null : const Color(0xFF2A2A2A),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: hasText && !_isSending ? _sendMessage : null,
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
                hasText ? Icons.send : Icons.mic,
                color: Colors.white,
              ),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  void _onMessageChanged(String text) {
    // Simuler notification de frappe (throttled)
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 500), () {
      // Ici on enverrait une notification de frappe en vrai
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final currentUser = SecureAuthService.instance.currentUser;
      if (currentUser == null) return;

      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        senderName: 'Vous',
        message: messageText,
        timestamp: DateTime.now(),
        messageType: MessageType.text,
      );

      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
      });

      _scrollToBottom();

      // Simuler envoi avec délai réaliste
      await Future.delayed(const Duration(milliseconds: 800));

      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isSending = false);
    }
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
                _buildAttachmentOption(Icons.photo_camera, 'Photo', _sendImage),
                _buildAttachmentOption(Icons.location_on, 'Position', _shareLocation),
                _buildAttachmentOption(Icons.description, 'Document', _sendDocument),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
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

  void _showEmojiPicker() {
    _showInfoSnackBar('Picker emoji - Bientôt disponible');
  }

  void _showBookingDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildBookingDetailsSheet(),
    );
  }

  Widget _buildBookingDetailsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'Détails de la réservation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (_flash != null) _buildFlashCard(),
                      const SizedBox(height: 20),
                      _buildBookingInfoCard(),
                      const SizedBox(height: 20),
                      _buildContactInfoCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlashCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _flash!.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _flash!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _flash!.tattooArtistName,
                  style: TextStyle(
                    color: KipikTheme.rouge,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.booking.totalPrice.toInt()}€',
                  style: TextStyle(
                    color: KipikTheme.rouge,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations RDV',
            style: TextStyle(
              color: KipikTheme.rouge,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Date', '${widget.booking.requestedDate.day}/${widget.booking.requestedDate.month}/${widget.booking.requestedDate.year}'),
          _buildInfoRow('Heure', widget.booking.timeSlot),
          _buildInfoRow('Statut', _getStatusText(widget.booking.status)),
          _buildInfoRow('Acompte versé', '${widget.booking.depositAmount.toInt()}€'),
          _buildInfoRow('Reste à payer', '${(widget.booking.totalPrice - widget.booking.depositAmount).toInt()}€'),
          if (widget.booking.clientNotes.isNotEmpty)
            _buildInfoRow('Notes', widget.booking.clientNotes),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact',
            style: TextStyle(
              color: KipikTheme.rouge,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.booking.clientPhone.isNotEmpty)
            _buildInfoRow('Téléphone', widget.booking.clientPhone),
          _buildInfoRow('Chat', 'Disponible 24h/24'),
          _buildInfoRow('Réponse moyenne', '< 2h'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Helper methods CORRIGÉS avec tous les statuts
  Color _getStatusColor(FlashBookingStatus status) {
    switch (status) {
      case FlashBookingStatus.pending:
        return Colors.orange;
      case FlashBookingStatus.quoteSent: // ✅ Ajouté
        return Colors.blue;
      case FlashBookingStatus.depositPaid: // ✅ Ajouté
        return Colors.purple;
      case FlashBookingStatus.confirmed:
        return Colors.green;
      case FlashBookingStatus.completed:
        return Colors.blue;
      case FlashBookingStatus.cancelled:
      case FlashBookingStatus.rejected:
        return Colors.red;
      case FlashBookingStatus.expired: // ✅ Ajouté
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(FlashBookingStatus status) {
    switch (status) {
      case FlashBookingStatus.pending:
        return Icons.schedule;
      case FlashBookingStatus.quoteSent: // ✅ Ajouté
        return Icons.description;
      case FlashBookingStatus.depositPaid: // ✅ Ajouté
        return Icons.payment;
      case FlashBookingStatus.confirmed:
        return Icons.check_circle;
      case FlashBookingStatus.completed:
        return Icons.done_all;
      case FlashBookingStatus.cancelled:
      case FlashBookingStatus.rejected:
        return Icons.cancel;
      case FlashBookingStatus.expired: // ✅ Ajouté
        return Icons.timer_off;
    }
  }

  String _getStatusText(FlashBookingStatus status) {
    return status.displayText;
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return 'Il y a ${difference.inMinutes}min';
    }
  }

  // Action methods
  void _shareLocation() {
    _showInfoSnackBar('Partage de position - Bientôt disponible');
  }

  void _sendImage() {
    _showInfoSnackBar('Envoi d\'image - Bientôt disponible');
  }

  void _sendDocument() {
    _showInfoSnackBar('Envoi de document - Bientôt disponible');
  }

  void _makeCall() {
    _showInfoSnackBar('Appel - Bientôt disponible');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KipikTheme.rouge,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Modèle pour les messages de chat amélioré
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final MessageType messageType;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.messageType = MessageType.text,
  });
}

enum MessageType {
  text,
  system,
  confirmation,
  image,
  location,
  document,
}