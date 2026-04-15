import 'dart:convert';
import 'package:http/http.dart' as http;

class AiClientHelper {
  /// 自动补全 URL（如果用户只输入了基础 URL）
  static String completeUrl(String url) {
    if (!url.endsWith('/v1/chat/completions')) {
      if (url.endsWith('/')) {
        return '${url}v1/chat/completions';
      } else {
        return '$url/v1/chat/completions';
      }
    }
    return url;
  }

  /// 检测是否为 DeepSeek API
  static bool isDeepSeek(String url) {
    return url.contains('deepseek');
  }

  /// 根据 URL 获取模型名称
  static String getModel(String url) {
    return isDeepSeek(url) ? 'deepseek-chat' : 'gpt-3.5-turbo';
  }

  /// 解析 SSE 流式响应
  static Stream<String> parseSseStream(http.StreamedResponse response) async* {
    if (response.statusCode == 200) {
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        // 解析 SSE 格式的数据
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              return;
            }
            try {
              final jsonData = jsonDecode(data);
              final content = jsonData['choices']?[0]?['delta']?['content'];
              if (content != null) {
                yield content;
              }
            } catch (e) {
              // 忽略解析错误
            }
          }
        }
      }
    } else {
      throw Exception('API 请求失败: ${response.statusCode}');
    }
  }

  /// 创建 HTTP 请求
  static http.Request createRequest({
    required String url,
    required String apiKey,
    required Map<String, dynamic> body,
    bool isStream = false,
  }) {
    final request = http.Request('POST', Uri.parse(url));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      if (isStream) 'Accept': 'text/event-stream',
    });
    request.body = jsonEncode(body);
    return request;
  }

  /// 解析工具参数
  static Map<String, dynamic>? tryParseToolArguments(String rawArguments) {
    final trimmed = rawArguments.trim();
    if (trimmed.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    return null;
  }

  /// 将动态值转换为整数
  static int asInt(dynamic value, {int fallback = 7}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}