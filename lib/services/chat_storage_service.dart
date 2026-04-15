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

  // 加载聊天记录，限制最多加载100条（避免性能问题）
  Future<List<ChatMessage>> loadMessages({int limit = 100}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_chatKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> messagesJson = jsonDecode(jsonString);
      // 只加载最近的消息
      final startIndex = messagesJson.length > limit ? messagesJson.length - limit : 0;
      final recentMessages = messagesJson.sublist(startIndex);

      final messages = <ChatMessage>[];
      for (final json in recentMessages) {
        try {
          messages.add(ChatMessage(
            content: json['content'] as String? ?? '',
            isUser: json['isUser'] as bool? ?? false,
            timestamp: DateTime.parse(json['timestamp'] as String),
          ));
        } catch (_) {
          // 跳过损坏的记录
        }
      }
      return messages;
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
