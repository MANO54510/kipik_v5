// lib/pages/particulier/conversation_page.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../../theme/kipik_theme.dart';
import 'messages_particulier_page.dart';

class ConversationPage extends StatefulWidget {
  final TattooerConversation conversation;

  const ConversationPage({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Exemple de messages pour la démonstration
  late List<ChatMessage> _messages;
  
  // Liste des images de fond disponibles
  final List<String> _backgroundImages = [
    'assets/background_charbon.png',
    'assets/background_tatoo1.png',
    'assets/background_tatoo2.png',
    'assets/background_tatoo3.png',
  ];
  
  // Variable pour stocker l'image de fond sélectionnée aléatoirement
  late String _selectedBackground;

  @override
  void initState() {
    super.initState();
    
    // Sélection aléatoire de l'image de fond
    _selectedBackground = _backgroundImages[Random().nextInt(_backgroundImages.length)];
    
    // Initialiser les messages de démo
    _loadDemoMessages();
  }
  
  void _loadDemoMessages() {
    final now = DateTime.now();
    
    // Images génériques URL (pas besoin d'assets)
    final String tattoExampleUrl = 'https://images.unsplash.com/photo-1586074911330-9a772f19e722';
    final String sketchUrl = 'https://images.unsplash.com/photo-1550537687-c91072c4792d';
    
    // Créer quelques messages fictifs pour la démo
    _messages = [
      ChatMessage(
        senderId: 'tattooer',
        content: 'Bonjour ! Comment puis-je t\'aider pour ton projet de ${widget.conversation.projectName} ?',
        timestamp: now.subtract(const Duration(days: 3, hours: 2)),
        messageType: MessageType.text,
      ),
      ChatMessage(
        senderId: 'user',
        content: 'Salut ! Je cherche un design dans un style plutôt minimaliste.',
        timestamp: now.subtract(const Duration(days: 3, hours: 1, minutes: 45)),
        messageType: MessageType.text,
      ),
      ChatMessage(
        senderId: 'tattooer',
        content: 'Je peux te proposer quelques designs. As-tu des références ou des exemples de ce que tu aimes ?',
        timestamp: now.subtract(const Duration(days: 3, hours: 1, minutes: 30)),
        messageType: MessageType.text,
      ),
      ChatMessage(
        senderId: 'user',
        content: tattoExampleUrl,
        timestamp: now.subtract(const Duration(days: 3, hours: 1)),
        messageType: MessageType.image,
      ),
      ChatMessage(
        senderId: 'user',
        content: 'Quelque chose dans ce style, mais peut-être avec des lignes plus fines.',
        timestamp: now.subtract(const Duration(days: 3, hours: 1)),
        messageType: MessageType.text,
      ),
      ChatMessage(
        senderId: 'tattooer',
        content: 'C\'est noté ! Je vais te préparer une esquisse. Pour l\'emplacement, tu penses à quelle partie du corps ?',
        timestamp: now.subtract(const Duration(days: 2, hours: 5)),
        messageType: MessageType.text,
      ),
      ChatMessage(
        senderId: 'user',
        content: 'Je pensais à l\'avant-bras, côté intérieur.',
        timestamp: now.subtract(const Duration(days: 2, hours: 4)),
        messageType: MessageType.text,
      ),
      ChatMessage(
        senderId: 'tattooer',
        content: sketchUrl,
        timestamp: now.subtract(const Duration(hours: 3)),
        messageType: MessageType.image,
      ),
      ChatMessage(
        senderId: 'tattooer',
        content: 'Voici l\'esquisse pour ton tatouage, qu\'en penses-tu ? On peut ajuster si nécessaire.',
        timestamp: now.subtract(const Duration(hours: 3)),
        messageType: MessageType.text,
      ),
    ];
    
    // Si la conversation a des messages non lus, ajouter les derniers messages du tatoueur
    if (widget.conversation.unreadCount > 0) {
      _messages.add(
        ChatMessage(
          senderId: 'tattooer',
          content: 'J\'ai aussi pensé à cette variante, peut-être plus adaptée à l\'emplacement.',
          timestamp: now.subtract(const Duration(minutes: 15)),
          messageType: MessageType.text,
        ),
      );
      
      _messages.add(
        ChatMessage(
          senderId: 'tattooer',
          content: 'https://images.unsplash.com/photo-1598587741472-cb57904efbc1',
          timestamp: now.subtract(const Duration(minutes: 15)),
          messageType: MessageType.image,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          senderId: 'user',
          content: _messageController.text,
          timestamp: DateTime.now(),
          messageType: MessageType.text,
        ),
      );
      _messageController.clear();
    });

    // Faire défiler vers le dernier message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Envoyer',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Galerie',
                  onTap: () {
                    Navigator.pop(context);
                    // Logique pour sélectionner une image
                    _simulateImageUpload();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Appareil photo',
                  onTap: () {
                    Navigator.pop(context);
                    // Logique pour prendre une photo
                    _simulateImageUpload();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  onTap: () {
                    Navigator.pop(context);
                    // Logique pour sélectionner un document
                    _simulateDocumentUpload();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: KipikTheme.rouge.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: KipikTheme.rouge, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Simule l'envoi d'une image (pour la démo)
  void _simulateImageUpload() {
    setState(() {
      _messages.add(
        ChatMessage(
          senderId: 'user',
          content: 'https://images.unsplash.com/photo-1571816119553-df62a2eedf56', // Image générique
          timestamp: DateTime.now(),
          messageType: MessageType.image,
        ),
      );
    });

    // Faire défiler vers le dernier message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Simule l'envoi d'un document (pour la démo)
  void _simulateDocumentUpload() {
    setState(() {
      _messages.add(
        ChatMessage(
          senderId: 'user',
          content: 'emplacement_tatouage.pdf',
          timestamp: DateTime.now(),
          messageType: MessageType.document,
        ),
      );
    });

    // Faire défiler vers le dernier message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showProjectInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Informations du projet',
          style: TextStyle(
            fontFamily: 'PermanentMarker',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.format_paint, color: KipikTheme.rouge),
              title: const Text('Projet'),
              subtitle: Text(widget.conversation.projectName),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person, color: KipikTheme.rouge),
              title: const Text('Tatoueur'),
              subtitle: Text(widget.conversation.tattooerName),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_today, color: KipikTheme.rouge),
              title: const Text('Dernière activité'),
              subtitle: Text('${widget.conversation.lastMessageTime.day}/${widget.conversation.lastMessageTime.month}/${widget.conversation.lastMessageTime.year}'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline, color: KipikTheme.rouge),
              title: const Text('Statut'),
              subtitle: const Text('En discussion'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: KipikTheme.rouge),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Bouton retour ajouté
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.conversation.avatarUrl),
              radius: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.tattooerName,
                  style: const TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.conversation.projectName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Bouton d'appel vidéo
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appel vidéo non disponible pour le moment'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          // Bouton d'info projet avec tooltip explicatif
          Tooltip(
            message: 'Informations du projet',
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: _showProjectInfo,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fond aléatoire
          Image.asset(
            _selectedBackground,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          
          // Contenu principal
          Column(
            children: [
              // Liste des messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageItem(message);
                  },
                ),
              ),
              
              // Barre de saisie
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    // Bouton pour les pièces jointes
                    IconButton(
                      icon: Icon(Icons.attach_file, color: KipikTheme.rouge),
                      onPressed: _showAttachmentOptions,
                    ),
                    // Champ de saisie du message
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Votre message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bouton d'envoi
                    Container(
                      decoration: BoxDecoration(
                        color: KipikTheme.rouge,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isUser = message.senderId == 'user';
    
    // Formatage de l'heure du message
    final timeString = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';
    
    // Widget pour afficher la bulle de message
    Widget messageContent;
    
    switch (message.messageType) {
      case MessageType.text:
        messageContent = Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        );
        break;
        
      case MessageType.image:
        messageContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                message.content, // URL de l'image
                width: 200,
                height: 150,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Image',
              style: TextStyle(
                color: isUser ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
        );
        break;
        
      case MessageType.document:
        messageContent = Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file,
                color: isUser ? Colors.white : KipikTheme.rouge,
                size: 24,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Document PDF',
                      style: TextStyle(
                        color: isUser ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar pour le tatoueur
          if (!isUser) ...[
            CircleAvatar(
              backgroundImage: NetworkImage(widget.conversation.avatarUrl),
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          
          // Bulle de message
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? KipikTheme.rouge : Colors.white,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                messageContent,
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    timeString,
                    style: TextStyle(
                      color: isUser 
                          ? Colors.white.withOpacity(0.7) 
                          : Colors.black.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Types de messages
enum MessageType {
  text,
  image,
  document,
}

// Modèle pour les messages
class ChatMessage {
  final String senderId; // 'user' ou 'tattooer'
  final String content;
  final DateTime timestamp;
  final MessageType messageType;

  ChatMessage({
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.messageType,
  });
}