import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat/chat_service.dart';

class ChatPopup extends StatefulWidget {
  final bool allowImageGeneration;
  const ChatPopup({Key? key, required this.allowImageGeneration})
      : super(key: key);

  @override
  State<ChatPopup> createState() => _ChatPopupState();
}

class _ChatPopupState extends State<ChatPopup>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isExpanded = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        imageUrl: null,
        senderId: 'user',
        timestamp: DateTime.now(),
      ));
      _controller.clear();
    });

    final aiMsg = await ChatService.getAIResponse(text, widget.allowImageGeneration);

    setState(() {
      _messages.add(aiMsg);
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    // hauteur occupée par clavier + barre de navigation
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Center(
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Material(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: w * (_isExpanded ? 0.9 : 0.7),
              height: h * (_isExpanded ? 0.9 : 0.4),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isExpanded ? Icons.close_fullscreen : Icons.open_in_full,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            setState(() => _isExpanded = !_isExpanded),
                      ),
                      const Text(
                        'KIPIK ChatBot',
                        style: TextStyle(
                          fontFamily: 'PermanentMarker',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),

                  // ── Messages ──
                  Expanded(
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) {
                        final m = _messages[i];
                        final isUser = m.senderId == 'user';
                        final isImage = m.imageUrl != null;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // avatar
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  isUser
                                      ? 'assets/avatars/avatar_user_neutre.png'
                                      : 'assets/avatars/avatar_assistant_kipik.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // bulle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: isUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(12),
                                    constraints: BoxConstraints(maxWidth: w * 0.5),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? Colors.white10
                                          : Colors.redAccent.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: isImage
                                        ? Image.network(m.imageUrl!, height: 120)
                                        : Text(
                                            m.text ?? '',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // ── Zone de saisie ──
                  SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Écris ta question...',
                              hintStyle: TextStyle(color: Colors.white54),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.redAccent),
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
