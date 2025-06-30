// lib/widgets/tattoo_assistant_sheet.dart

import 'package:flutter/material.dart';

/// Feuille de chat pour l'Assistant Kipik,
/// avec toggle demi‑écran (50 %) / plein écran (100 %) et SafeArea ajustée.
class TattooAssistantSheet extends StatefulWidget {
  final bool allowImageGeneration;
  const TattooAssistantSheet({
    Key? key,
    this.allowImageGeneration = false,
  }) : super(key: key);

  @override
  _TattooAssistantSheetState createState() => _TattooAssistantSheetState();
}

class _TattooAssistantSheetState extends State<TattooAssistantSheet> {
  final TextEditingController _inputCtrl = TextEditingController();
  final List<_Msg> _msgs = [];
  bool _isFullScreen = false;

  void _sendText() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _msgs.insert(0, _Msg(text: text, isUser: true)));
    _inputCtrl.clear();
    Future.delayed(const Duration(milliseconds: 500), () {
      const response = "Réponse automatique de l'assistant…";
      setState(() => _msgs.insert(0, _Msg(text: response, isUser: false)));
    });
  }

  void _generateImage() {
    setState(() {
      _msgs.insert(
        0,
        const _Msg(text: '[Croquis généré 🖼️]', isUser: false, isImage: true),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hauteur : 50% ou 100% de l'écran
    final heightFactor = _isFullScreen ? 1.0 : 0.5;
    // Taille de police selon mode
    final messageStyle = TextStyle(
      color: Colors.white,
      fontSize: _isFullScreen ? 18 : 14,
    );

    return SafeArea(
      top: true,
      bottom: true,
      child: Padding(
        // décale la feuille 16px sous la SafeArea du haut
        padding: const EdgeInsets.only(top: 16.0),
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Header : toggle plein/partiel + titre + fermeture
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _isFullScreen = !_isFullScreen),
                    ),
                    const Text(
                      "L'assistant Kipik",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Messages
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _msgs.length,
                    itemBuilder: (ctx, i) =>
                        _buildBubble(_msgs[i], messageStyle),
                  ),
                ),

                // Bouton "Générer un croquis"
                if (widget.allowImageGeneration)
                  TextButton.icon(
                    onPressed: _generateImage,
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: const Text(
                      'Générer un croquis',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                // Input
                SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Posez votre question…',
                            hintStyle: TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white12,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          onSubmitted: (_) => _sendText(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(_Msg m, TextStyle style) {
    final avatarAsset = m.isUser
        ? 'assets/avatars/avatar_user_generic.png'
        : 'assets/avatars/avatar_assistant_kipik.png';
    final avatar = ClipOval(
      child: Image.asset(avatarAsset, width: 32, height: 32, fit: BoxFit.cover),
    );

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: m.isUser ? Colors.white24 : Colors.redAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(m.text, style: style),
    );

    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: m.isUser
            ? [bubble, const SizedBox(width: 8), avatar]
            : [avatar, const SizedBox(width: 8), bubble],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isUser;
  final bool isImage;
  const _Msg({
    required this.text,
    required this.isUser,
    this.isImage = false,
  });
}