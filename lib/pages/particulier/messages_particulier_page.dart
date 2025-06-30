// lib/pages/particulier/messages_particulier_page.dart
import 'package:flutter/material.dart';
import 'dart:math'; // Pour la sélection aléatoire de fond
import '../../widgets/common/app_bars/custom_app_bar_particulier.dart';
import '../../theme/kipik_theme.dart';
import 'conversation_page.dart'; // À créer

class MessagesParticulierPage extends StatefulWidget {
  const MessagesParticulierPage({Key? key}) : super(key: key);

  @override
  State<MessagesParticulierPage> createState() => _MessagesParticulierPageState();
}

class _MessagesParticulierPageState extends State<MessagesParticulierPage> {
  // Liste des images de fond disponibles
  final List<String> _backgroundImages = [
    'assets/background_charbon.png',
    'assets/background_tatoo1.png',
    'assets/background_tatoo2.png',
    'assets/background_tatoo3.png',
  ];
  
  // Variable pour stocker l'image de fond sélectionnée aléatoirement
  late String _selectedBackground;
  
  // Conversations fictives pour la démo
  final List<TattooerConversation> _conversations = [
    TattooerConversation(
      tattooerName: 'InkMaster',
      avatarUrl: 'https://i.pravatar.cc/150?img=32',
      lastMessage: 'Voici l\'esquisse pour ton tatouage, qu\'en penses-tu ?',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
      unreadCount: 2,
      projectName: 'Manchette japonaise',
      isOnline: true,
    ),
    TattooerConversation(
      tattooerName: 'BlackNeedle',
      avatarUrl: 'https://i.pravatar.cc/150?img=51',
      lastMessage: 'On peut se voir demain à 14h pour discuter du design ?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      projectName: 'Tatouage minimaliste',
      isOnline: false,
    ),
    TattooerConversation(
      tattooerName: 'ColorCanvas',
      avatarUrl: 'https://i.pravatar.cc/150?img=48',
      lastMessage: 'J\'ai modifié les couleurs comme demandé',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      projectName: 'Fleur aquarelle',
      isOnline: true,
    ),
    TattooerConversation(
      tattooerName: 'TattooLegend',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      lastMessage: 'Tu peux m\'envoyer une photo de l\'emplacement ?',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
      unreadCount: 1,
      projectName: 'Tribal épaule',
      isOnline: false,
    ),
    TattooerConversation(
      tattooerName: 'SkinArtist',
      avatarUrl: 'https://i.pravatar.cc/150?img=22',
      lastMessage: 'La date est confirmée : 15 juin à 10h',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 3)),
      unreadCount: 0,
      projectName: 'Portrait réaliste',
      isOnline: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Sélection aléatoire de l'image de fond
    _selectedBackground = _backgroundImages[Random().nextInt(_backgroundImages.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarParticulier(
        title: 'Messages',
        showBackButton: true,
        redirectToHome: true,
        showNotificationIcon: true,
      ),
      body: SafeArea(
        // Ajout de SafeArea pour éviter les problèmes avec les encoches et barre de navigation
        bottom: true, // Assure que le contenu est sûr en bas de l'écran
        child: Stack(
          children: [
            // Fond aléatoire
            Image.asset(
              _selectedBackground,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            
            // Contenu principal
            _conversations.isEmpty
                ? _buildEmptyState()
                : _buildConversationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: KipikTheme.rouge.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.message,
              size: 64,
              color: KipikTheme.rouge.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune conversation active',
              style: TextStyle(
                fontFamily: 'PermanentMarker',
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par contacter un tatoueur pour échanger sur votre projet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/recherche_tatoueur');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KipikTheme.rouge,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Trouver un tatoueur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _buildConversationCard(conversation);
      },
    );
  }

  Widget _buildConversationCard(TattooerConversation conversation) {
    // Formatage de l'heure du dernier message
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      conversation.lastMessageTime.year,
      conversation.lastMessageTime.month,
      conversation.lastMessageTime.day,
    );
    
    String timeText;
    if (messageDate == today) {
      // Aujourd'hui : afficher l'heure
      timeText = '${conversation.lastMessageTime.hour.toString().padLeft(2, '0')}:${conversation.lastMessageTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Hier
      timeText = 'Hier';
    } else if (now.difference(messageDate).inDays < 7) {
      // Cette semaine : afficher le jour
      final weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      timeText = weekdays[conversation.lastMessageTime.weekday - 1];
    } else {
      // Plus ancien : afficher la date
      timeText = '${conversation.lastMessageTime.day}/${conversation.lastMessageTime.month}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: conversation.unreadCount > 0 
              ? KipikTheme.rouge
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      elevation: conversation.unreadCount > 0 ? 4 : 2,
      color: Colors.white.withOpacity(0.95),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConversationPage(conversation: conversation),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar avec indicateur "en ligne"
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(conversation.avatarUrl),
                  ),
                  if (conversation.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // Informations sur la conversation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du tatoueur et heure
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          conversation.tattooerName,
                          style: TextStyle(
                            fontFamily: 'PermanentMarker',
                            fontSize: 16,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: conversation.unreadCount > 0
                                ? KipikTheme.rouge
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    
                    // Nom du projet
                    const SizedBox(height: 2),
                    Text(
                      conversation.projectName,
                      style: TextStyle(
                        fontSize: 13,
                        color: KipikTheme.rouge,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    // Dernier message
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: KipikTheme.rouge,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              conversation.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modèle pour les conversations
class TattooerConversation {
  final String tattooerName;
  final String avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String projectName;
  final bool isOnline;

  TattooerConversation({
    required this.tattooerName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.projectName,
    required this.isOnline,
  });
}