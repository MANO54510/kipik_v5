// lib/pages/chat/ai_assistant_page.dart

import 'package:flutter/material.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';
import 'package:kipik_v5/models/chat_message.dart';
import 'package:kipik_v5/services/chat/chat_manager.dart';

class AIAssistantPage extends StatefulWidget {
  final bool allowImageGeneration;
  final String? contextPage;
  final String? initialPrompt;

  const AIAssistantPage({
    Key? key,
    this.allowImageGeneration = false,
    this.contextPage,
    this.initialPrompt,
  }) : super(key: key);

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

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
    final welcomeText = _getWelcomeMessage();
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      text: welcomeText,
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
        return "${baseMessage}Je peux t'aider à créer des devis professionnels et ${widget.allowImageGeneration ? 'générer des images de tatouages pour tes clients' : 'répondre à tes questions'} !";
      case 'agenda':
        return "${baseMessage}Je peux t'expliquer comment optimiser ton agenda et gérer tes rendez-vous !";
      case 'projets':
        return "${baseMessage}Je peux t'aider à mieux gérer tes projets clients et ton workflow !";
      case 'comptabilite':
        return "${baseMessage}Je peux t'assister avec ta comptabilité et tes déclarations !";
      case 'conventions':
        return "${baseMessage}Je peux t'expliquer comment t'inscrire aux conventions et gérer tes participations !";
      default:
        return "${baseMessage}Je peux t'aider avec :\n• Navigation dans l'app\n• Questions tatouage\n• Conseils professionnels\n${widget.allowImageGeneration ? '• Génération d\'images' : ''}\n\nQue puis-je faire pour toi ?";
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

    // Message utilisateur
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
      // Appel ChatManager pour l'IA
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
            CircleAvatar(
              radius: 20,
              backgroundColor: KipikTheme.rouge,
              backgroundImage: const AssetImage('assets/avatars/avatar_assistant_kipik.png'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assistant Kipik',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PermanentMarker',
                  ),
                ),
                Text(
                  widget.allowImageGeneration ? 'Aide + Génération d\'images' : 'Assistant navigation',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Indicateur de loading
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: KipikTheme.rouge,
                    backgroundImage: const AssetImage('assets/avatars/avatar_assistant_kipik.png'),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Assistant en train d\'écrire...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
                    ),
                  ),
                ],
              ),
            ),
          
          // Zone de saisie
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isAssistant = message.isFromAssistant;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssistant) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: KipikTheme.rouge,
              backgroundImage: const AssetImage('assets/avatars/avatar_assistant_kipik.png'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAssistant ? Colors.white : KipikTheme.rouge,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isAssistant ? 8 : 20),
                  topRight: Radius.circular(isAssistant ? 20 : 8),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 50),
                          );
                        },
                      ),
                    ),
                    if (message.hasText) const SizedBox(height: 12),
                  ],
                  if (message.hasText)
                    Text(
                      message.text!,
                      style: TextStyle(
                        color: isAssistant ? Colors.black87 : Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isAssistant) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
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
            blurRadius: 10,
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
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: () => _sendMessage(_messageController.text),
            backgroundColor: KipikTheme.rouge,
            mini: true,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}