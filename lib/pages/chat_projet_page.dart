// lib/pages/chat_projet_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/models/chat_message.dart';
import 'package:kipik_v5/services/chat/project_chat_service.dart';  // ✅ Service pour chat projet
import 'package:kipik_v5/services/chat/chat_repository.dart';  // ✅ Interface
import 'package:kipik_v5/locator.dart';  // ✅ Pour récupérer le service

/// Page de chat pour un projet donné.
class ChatProjetPage extends StatefulWidget {
  final String projectId;
  final ProjectChatService? chatService;  // ✅ Ou ChatRepository si vous préférez l'interface
  final String? currentUserId;
  final String? projectName;
  final String? clientName;

  const ChatProjetPage({
    Key? key,
    this.projectId = 'stub_project',
    this.chatService,  // ✅ Changé le nom
    this.currentUserId,
    this.projectName,
    this.clientName,
  }) : super(key: key);

  @override
  State<ChatProjetPage> createState() => _ChatProjetPageState();
}

class _ChatProjetPageState extends State<ChatProjetPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _localMessages = [];
  late ChatRepository _chatService;  // ✅ Interface pour plus de flexibilité
  late String _currentUserId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ✅ Récupération via le locator
    _chatService = widget.chatService ?? locator<ProjectChatService>();
    _currentUserId = widget.currentUserId ?? 'user_stub';
    
    _initializeChat();
  }

  void _initializeChat() {
    setState(() => _isLoading = true);
    
    _chatService.messagesStream(widget.projectId).listen(
      (msgs) {
        if (!mounted) return;
        setState(() {
          _localMessages
            ..clear()
            ..addAll(msgs);
          _isLoading = false;
        });
        _scrollToBottom();
      },
      onError: (error) {
        debugPrint('Erreur stream messages: $error');
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Erreur de connexion au chat');
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // ✅ Supprimé la vérification du stub
    super.dispose();
  }

  Future<void> _sendMessage({String? text, XFile? imageFile}) async {
    final content = text?.trim();
    if ((content == null || content.isEmpty) && imageFile == null) return;

    _messageController.clear();

    String? imageUrl;
    if (imageFile != null) {
      // ✅ TODO: Implémenter l'upload d'image via Firebase Storage
      imageUrl = 'assets/images/placeholder_image.jpg';
    }

    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: content,
      imageUrl: imageUrl,
      senderId: _currentUserId,
      timestamp: DateTime.now(),
    );

    try {
      await _chatService.sendMessage(
        projectId: widget.projectId,
        message: msg,
      );
      
      if (mounted) {
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Erreur envoi message: $e');
      _showErrorSnackBar('Échec de l\'envoi, réessayez');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: KipikTheme.rouge,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Chat projet';
    if (widget.projectName != null && widget.clientName != null) {
      title = '${widget.projectName} - ${widget.clientName}';
    } else if (widget.projectName != null) {
      title = widget.projectName!;
    }

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'PermanentMarker',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // En-tête du projet (optionnel)
              if (widget.projectName != null) _buildProjectHeader(),
              
              // Liste des messages
              Expanded(child: _buildMessageList()),
              
              // Champ de saisie
              _buildInputField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KipikTheme.rouge.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  color: KipikTheme.rouge,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.projectName ?? 'Projet',
                  style: const TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 16,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          if (widget.clientName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Client: ${widget.clientName}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Chargement des messages...',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_localMessages.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 32,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pas encore de messages',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontFamily: 'PermanentMarker',
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Commencez la conversation avec votre client !',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _localMessages.length,
      itemBuilder: (ctx, i) => _buildMessageTile(_localMessages[i]),
    );
  }

  Widget _buildMessageTile(ChatMessage msg) {
    final isMe = msg.senderId == _currentUserId;
    final hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;
    final hasText = msg.text != null && msg.text!.isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMe 
                    ? KipikTheme.rouge
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        msg.imageUrl!,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 50,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    if (hasText) const SizedBox(height: 12),
                  ],
                  if (hasText)
                    Text(
                      msg.text!,
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFF111827),
                        fontSize: 15,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _formatTime(msg.timestamp),
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes}min';
    if (diff.inDays < 1) return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton photo
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.photo_camera_outlined,
                color: const Color(0xFF6B7280),
                size: 22,
              ),
              onPressed: () async {
                final picker = XTypeGroup(
                  label: 'images',
                  extensions: ['jpg', 'jpeg', 'png', 'webp'],
                );
                final XFile? file = await openFile(
                  acceptedTypeGroups: [picker],
                );
                if (file != null) {
                  await _sendMessage(imageFile: file);
                }
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Champ de texte
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) => _sendMessage(text: text),
                decoration: InputDecoration(
                  hintText: 'Écrivez votre message...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: KipikTheme.rouge, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Bouton envoyer
          Container(
            decoration: BoxDecoration(
              color: KipikTheme.rouge,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: KipikTheme.rouge.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => _sendMessage(text: _messageController.text),
            ),
          ),
        ],
      ),
    );
  }
}