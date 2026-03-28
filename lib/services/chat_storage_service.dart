import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/ai_chat_screen.dart';

class ChatStorageService {
  static const String _chatKey = 'ai_chat_history';

  // 保存聊天记录
  Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = messages.map((msg) => {
      'content': msg.content,
      'isUser': msg.isUser,
      'timestamp': msg.timestamp.toIso8601String(),
    }).toList();
    await prefs.setString(_chatKey, jsonEncode(messagesJson));
  }

  // 加载聊天记录
  Future<List<ChatMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_chatKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> messagesJson = jsonDecode(jsonString);
      return messagesJson.map((json) => ChatMessage(
        content: json['content'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // 清空聊天记录
  Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatKey);
  }
}
