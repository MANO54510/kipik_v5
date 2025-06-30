import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../models/chat_message.dart';

class ChatService {
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  static final String _chatEndpoint  = 'https://api.openai.com/v1/chat/completions';
  static final String _imageEndpoint = 'https://api.openai.com/v1/images/generations';

  /// Renvoie un ChatMessage dont senderId est 'assistant'
  static Future<ChatMessage> getAIResponse(
    String prompt,
    bool allowImageGeneration,
  ) async {
    if (prompt.toLowerCase().contains('tatouage') && allowImageGeneration) {
      return await _generateImage(prompt);
    } else {
      return await _generateText(prompt);
    }
  }

  static Future<ChatMessage> _generateText(String prompt) async {
    final resp = await http.post(
      Uri.parse(_chatEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'Tu es l’assistant tatouage Kipik. Réponds sobrement et professionnellement.'
          },
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    String content;
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      content = data['choices'][0]['message']['content'] as String;
    } else {
      content = "Désolé, je n'arrive pas à répondre pour le moment.";
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: content,
      imageUrl: null,
      senderId: 'assistant',
      timestamp: DateTime.now(),
    );
  }

  static Future<ChatMessage> _generateImage(String prompt) async {
    final resp = await http.post(
      Uri.parse(_imageEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'prompt': prompt,
        'n': 1,
        'size': '512x512',
      }),
    );

    String? imageUrl;
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      imageUrl = data['data'][0]['url'] as String;
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: null,
      imageUrl: imageUrl,
      senderId: 'assistant',
      timestamp: DateTime.now(),
    );
  }
}
