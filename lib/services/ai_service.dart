import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'theme_service.dart';

class AiService {
  final ThemeService _themeService = ThemeService();

  Future<Map<String, dynamic>?> parseDiary(String summary) async {
    if (!_themeService.hasAiConfig) {
      throw Exception('请先配置 AI API');
    }

    final url = _themeService.aiApiUrl;
    final apiKey = _themeService.aiApiKey;

    final prompt = '''
请将以下日记总结解析成结构化数据，以JSON格式返回：

日记总结：$summary

请解析出以下字段（如果总结中没有提到某个字段，该字段返回null）：
- breakfast: 早餐内容
- lunch: 午餐内容  
- dinner: 晚餐内容
- snacks: 零食/其他
- mood: 心情（如：开心、平静、焦虑等）
- weather: 天气（如：晴天、多云、下雨等）
- content: 日记详细内容（将总结扩展成完整日记）

只返回JSON，不要返回其他文字说明。格式示例：
{
  "breakfast": "豆浆、油条",
  "lunch": "红烧肉、米饭",
  "dinner": "蔬菜沙拉",
  "snacks": null,
  "mood": "开心",
  "weather": "晴天",
  "content": "今天天气很好..."
}
''';

    try {
      // 自动补全 URL（如果用户只输入了基础 URL）
      String finalUrl = url;
      if (!url.endsWith('/v1/chat/completions')) {
        if (url.endsWith('/')) {
          finalUrl = '${url}v1/chat/completions';
        } else {
          finalUrl = '$url/v1/chat/completions';
        }
      }

      // 检测是否为 DeepSeek API
      final isDeepSeek = url.contains('deepseek');
      final model = isDeepSeek ? 'deepseek-chat' : 'gpt-3.5-turbo';

      final response = await http.post(
        Uri.parse(finalUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // 解析 JSON 响应
        try {
          final result = jsonDecode(content);
          return result;
        } catch (e) {
          // 如果返回的不是纯 JSON，尝试提取 JSON 部分
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
          if (jsonMatch != null) {
            return jsonDecode(jsonMatch.group(0)!);
          }
          throw Exception('AI 返回格式错误');
        }
      } else {
        throw Exception('API 请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI 解析失败: $e');
    }
  }
}
