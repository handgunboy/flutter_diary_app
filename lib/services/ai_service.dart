import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import 'theme_service.dart';
import 'storage_service.dart';
import 'ai_client_helper.dart';
import 'diary_query_service.dart';
import 'function_calling_service.dart';

class AiService {
  final ThemeService _themeService = ThemeService();
  final FunctionCallingService _functionCallingService;

  AiService()
      : _functionCallingService = FunctionCallingService(DiaryQueryService(StorageService()));

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
- weight: 体重（如：60.5，数字即可）
- content: 日记详细内容（将总结扩展成完整日记）

只返回JSON，不要返回其他文字说明。格式示例：
{
  "breakfast": "豆浆、油条",
  "lunch": "红烧肉、米饭",
  "dinner": "蔬菜沙拉",
  "snacks": null,
  "mood": "开心",
  "weather": "晴天",
  "weight": "60.5",
  "content": "今天天气很好..."
}
''';

    try {
      final finalUrl = AiClientHelper.completeUrl(url);
      final model = AiClientHelper.getModel(url);

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

  // 流式聊天方法
  Stream<String> chatStream(List<Map<String, String>> messages) async* {
    if (!_themeService.hasAiConfig) {
      throw Exception('请先配置 AI API');
    }

    final url = _themeService.aiApiUrl;
    final apiKey = _themeService.aiApiKey;

    try {
      final finalUrl = AiClientHelper.completeUrl(url);
      final model = AiClientHelper.getModel(url);

      final request = AiClientHelper.createRequest(
        url: finalUrl,
        apiKey: apiKey,
        body: {
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'stream': true,
        },
        isStream: true,
      );

      final response = await http.Client().send(request);
      yield* AiClientHelper.parseSseStream(response);
    } catch (e) {
      throw Exception('AI 聊天失败: $e');
    }
  }

  // 检查是否已配置 AI
  bool get isConfigured => _themeService.hasAiConfig;

  // 检查是否允许 AI 访问数据
  bool get canAccessData => _themeService.aiDataAccess;

  /// 带 Function Calling 的聊天方法
  Stream<String> chatStreamWithFunctions(
    List<Map<String, String>> messages, {
    String? systemPrompt,
  }) async* {
    developer.log('🤖 [Function Calling] 开始聊天', name: 'AiService');
    
    if (!_themeService.hasAiConfig) {
      developer.log('❌ [Function Calling] 未配置 AI API', name: 'AiService');
      throw Exception('请先配置 AI API');
    }

    final url = _themeService.aiApiUrl;
    final apiKey = _themeService.aiApiKey;
    developer.log('🔗 [Function Calling] API URL: $url', name: 'AiService');

    try {
      final finalUrl = AiClientHelper.completeUrl(url);
      final model = AiClientHelper.getModel(url);
      developer.log('📝 [Function Calling] 使用模型: $model', name: 'AiService');

      // 构建请求体
      final requestBody = <String, dynamic>{
        'model': model,
        'messages': [
          if (systemPrompt != null)
            {'role': 'system', 'content': systemPrompt},
          ...messages,
        ],
        'temperature': 0.7,
        'stream': true,
        'tools': _functionCallingService.tools,
        'tool_choice': 'auto',
      };
      
      developer.log('📦 [Function Calling] 请求体包含 ${requestBody['tools']?.length ?? 0} 个工具', name: 'AiService');

      final request = AiClientHelper.createRequest(
        url: finalUrl,
        apiKey: apiKey,
        body: requestBody,
        isStream: true,
      );
      developer.log('📤 [Function Calling] 发送请求...', name: 'AiService');

      final response = await http.Client().send(request);
      developer.log('📥 [Function Calling] 收到响应: ${response.statusCode}', name: 'AiService');

      if (response.statusCode == 200) {
        StringBuffer buffer = StringBuffer();
        String? functionName;
        Map<String, dynamic>? functionArguments;
        final StringBuffer functionArgumentsBuffer = StringBuffer();
        bool hasDetectedFunction = false;

        await for (final chunk in response.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') {
                developer.log('✅ [Function Calling] 流结束', name: 'AiService');

                if (functionName != null && functionArguments == null) {
                  try {
                    functionArguments = AiClientHelper.tryParseToolArguments(
                      functionArgumentsBuffer.toString(),
                    );
                  } catch (e) {
                    developer.log(
                      '❌ [Function Calling] 工具参数解析失败: $e, raw=${functionArgumentsBuffer.toString()}',
                      name: 'AiService',
                    );
                    yield '\n查询数据时出错: 工具参数解析失败';
                    return;
                  }
                }

                // 如果收集到了函数调用信息，执行函数
                if (functionName != null && functionArguments != null) {
                  developer.log('🔧 [Function Calling] 准备执行函数: $functionName, 参数: $functionArguments', name: 'AiService');
                  yield '\n\n[正在查询数据...]\n';
                  
                  try {
                    developer.log('⚙️ [Function Calling] 开始执行函数...', name: 'AiService');
                    final result = await _functionCallingService.executeFunction(functionName, functionArguments);
                    developer.log('✅ [Function Calling] 函数执行成功, 结果长度: ${result.length}', name: 'AiService');
                    
                    // 将函数结果发送给 AI 生成最终回复
                    final toolCallId = 'call_${DateTime.now().millisecondsSinceEpoch}';
                    final List<Map<String, dynamic>> functionMessages = [
                      ...messages,
                      {
                        'role': 'assistant',
                        'content': null,
                        'tool_calls': [
                          {
                            'id': toolCallId,
                            'type': 'function',
                            'function': {
                              'name': functionName,
                              'arguments': jsonEncode(functionArguments),
                            },
                          },
                        ],
                      },
                      {
                        'role': 'tool',
                        'tool_call_id': toolCallId,
                        'content': result,
                      },
                    ];
                    
                    developer.log('🔄 [Function Calling] 发送函数结果给 AI 生成回复...', name: 'AiService');
                    yield* _continueChatWithResult(functionMessages, systemPrompt);
                    return;
                  } catch (e, stackTrace) {
                    developer.log('❌ [Function Calling] 执行函数出错: $e', name: 'AiService', error: e, stackTrace: stackTrace);
                    yield '\n查询数据时出错: $e';
                    return;
                  }
                }
                return;
              }
              try {
                final jsonData = jsonDecode(data);
                developer.log('📨 [Function Calling] 收到数据: ${jsonData.toString().substring(0, jsonData.toString().length > 200 ? 200 : jsonData.toString().length)}...', name: 'AiService');
                
                // 检查是否有函数调用
                final functionCall = FunctionCallingService.parseFunctionCall(
                  jsonData,
                  functionArgumentsBuffer,
                );
                
                if (functionCall != null) {
                  if (!hasDetectedFunction) {
                    hasDetectedFunction = true;
                    developer.log('🔍 [Function Calling] 检测到函数调用!', name: 'AiService');
                  }
                  functionName = functionCall.functionName;
                  functionArguments = functionCall.arguments;
                }
                
                // 普通文本内容
                final delta = jsonData['choices']?[0]?['delta'];
                final content = delta?['content'];
                if (content != null) {
                  buffer.write(content);
                  yield content;
                }
              } catch (e) {
                // 忽略解析错误
              }
            }
          }
        }
      } else {
        developer.log('❌ [Function Calling] API 请求失败: ${response.statusCode}', name: 'AiService');
        throw Exception('API 请求失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log('❌ [Function Calling] AI 聊天失败: $e', name: 'AiService', error: e, stackTrace: stackTrace);
      throw Exception('AI 聊天失败: $e');
    }
  }

  /// 继续聊天（带函数执行结果）
  Stream<String> _continueChatWithResult(
    List<Map<String, dynamic>> messages,
    String? systemPrompt,
  ) async* {
    final url = _themeService.aiApiUrl;
    final apiKey = _themeService.aiApiKey;

    try {
      final finalUrl = AiClientHelper.completeUrl(url);
      final model = AiClientHelper.getModel(url);

      final requestBody = <String, dynamic>{
        'model': model,
        'messages': [
          if (systemPrompt != null)
            {'role': 'system', 'content': systemPrompt},
          ...messages,
        ],
        'temperature': 0.7,
        'stream': true,
      };

      final request = AiClientHelper.createRequest(
        url: finalUrl,
        apiKey: apiKey,
        body: requestBody,
        isStream: true,
      );

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        yield* AiClientHelper.parseSseStream(response);
      }
    } catch (e) {
      yield '\n生成回复时出错: $e';
    }
  }
}