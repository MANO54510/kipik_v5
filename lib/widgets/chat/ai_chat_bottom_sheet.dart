// lib/widgets/chat/ai_chat_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/models/chat_message.dart';
import 'package:kipik_v5/services/chat/chat_manager.dart';

class AIChatBottomSheet extends StatefulWidget {
  final bool allowImageGeneration;
  final String? contextPage;
  final String? initialPrompt;

  const AIChatBottomSheet({
    Key? key,
    this.allowImageGeneration = false,
    this.contextPage,
    this.initialPrompt,
  }) : super(key: key);

  @override
  State<AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends State<AIChatBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = []; // Session temporaire uniquement
  bool _isLoading = false;
  bool _isExpanded = false;
  double _currentHeight = 400;
  
  static const double _minHeight = 400;
  static const double _maxHeight = 700;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    
    // Envoyer le prompt initial si fourni
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialPrompt!);
      });
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      text: _getWelcomeMessage(),
      senderId: 'assistant',
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  String _getWelcomeMessage() {
    String baseMessage = "👋 Salut ! Je suis l'Assistant Kipik.\n\n";
    
    switch (widget.contextPage) {
      case 'devis':
        return "${baseMessage}Je peux t'aider à créer des devis et ${widget.allowImageGeneration ? 'générer des images de tatouages' : 'répondre à tes questions'} !";
      case 'agenda':
        return "${baseMessage}Je peux t'expliquer comment optimiser ton agenda !";
      case 'projets':
        return "${baseMessage}Je peux t'aider à gérer tes projets clients !";
      case 'comptabilite':
        return "${baseMessage}Je peux t'assister avec ta comptabilité !";
      case 'conventions':
        return "${baseMessage}Je peux t'expliquer comment t'inscrire aux conventions !";
      default:
        return "${baseMessage}Que puis-je faire pour toi aujourd'hui ?";
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmedText,
      senderId: 'user',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final aiResponse = await ChatManager.askAI(
        trimmedText, 
        allowImages: widget.allowImageGeneration,
      );

      setState(() {
        _messages.add(aiResponse);
        _isLoading = false;
      });
    } catch (e) {
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        text: "Désolé, je ne peux pas répondre maintenant. Réessaye dans quelques instants.",
        senderId: 'assistant',
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
    }

    _scrollToBottom();
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

  void _clearConversation() {
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _currentHeight = _isExpanded ? _maxHeight : _minHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _currentHeight / MediaQuery.of(context).size.height,
      minChildSize: 300 / MediaQuery.of(context).size.height,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle et header
              _buildHeader(),
              
              // Messages
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
                ),
              ),
              
              // Indicateur de loading
              if (_isLoading) _buildLoadingIndicator(),
              
              // Zone de saisie
              _buildInputArea(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle de glissement
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          
          // Header avec titre et actions
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: KipikTheme.rouge,
                backgroundImage: const AssetImage('assets/avatars/avatar_assistant_kipik.png'),
                onBackgroundImageError: (_, __) {},
                child: const Icon(Icons.smart_toy, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assistant Kipik',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'PermanentMarker',
                      ),
                    ),
                    Text(
                      widget.allowImageGeneration ? 'Aide + Images' : 'Assistant navigation',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions simples
              IconButton(
                onPressed: _toggleExpanded,
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
                tooltip: _isExpanded ? 'Réduire' : 'Agrandir',
              ),
              if (_messages.length > 1) // Afficher seulement s'il y a des messages
                IconButton(
                  onPressed: _clearConversation,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Nouvelle conversation',
                ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white70),
                tooltip: 'Fermer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isAssistant = message.isFromAssistant;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssistant) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: KipikTheme.rouge,
              backgroundImage: const AssetImage('assets/avatars/avatar_assistant_kipik.png'),
              onBackgroundImageError: (_, __) {},
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAssistant ? Colors.white : KipikTheme.rouge,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isAssistant ? 4 : 16),
                  topRight: Radius.circular(isAssistant ? 16 : 4),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 40),
                          );
                        },
                      ),
                    ),
                    if (message.hasText) const SizedBox(height: 8),
                  ],
                  if (message.hasText)
                    Text(
                      message.text!,
                      style: TextStyle(
                        color: isAssistant ? Colors.black87 : Colors.white,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isAssistant) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.person, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: KipikTheme.rouge,
            backgroundImage: const AssetImage('assets/avatars/avatar_assistant_kipik.png'),
            onBackgroundImageError: (_, __) {},
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          const Text(
            'Assistant en train d\'écrire...',
            style: TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
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
                hintText: 'Pose ta question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () => _sendMessage(_messageController.text),
            backgroundColor: KipikTheme.rouge,
            mini: true,
            child: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}