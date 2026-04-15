import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'ai_client_helper.dart';
import 'diary_query_service.dart';

class FunctionCallingService {
  final DiaryQueryService _diaryQueryService;

  FunctionCallingService(this._diaryQueryService);

  /// 定义可用的函数工具
  List<Map<String, dynamic>> get tools => [
    {
      'type': 'function',
      'function': {
        'name': 'getCurrentMonthDiaries',
        'description': '获取当前月份的所有日记记录，用于回答关于本月日记的问题',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'getRecentDiaries',
        'description': '获取最近N天的日记记录',
        'parameters': {
          'type': 'object',
          'properties': {
            'days': {
              'type': 'integer',
              'description': '要获取最近多少天的日记，例如7表示最近7天，30表示最近30天',
            },
          },
          'required': ['days'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'getDiariesByDateRange',
        'description': '获取指定日期范围内的日记记录。当用户询问某个时间段的日记时，必须提供开始日期和结束日期参数',
        'parameters': {
          'type': 'object',
          'properties': {
            'startDate': {
              'type': 'string',
              'description': '开始日期，格式为yyyy-MM-dd，例如2024-03-01。必须根据用户问题计算出具体日期',
            },
            'endDate': {
              'type': 'string',
              'description': '结束日期，格式为yyyy-MM-dd，例如2024-03-15。必须根据用户问题计算出具体日期',
            },
          },
          'required': ['startDate', 'endDate'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'getDiariesByMood',
        'description': '按心情筛选日记记录',
        'parameters': {
          'type': 'object',
          'properties': {
            'mood': {
              'type': 'string',
              'description': '要筛选的心情，例如"开心"、"难过"、"平静"等',
            },
          },
          'required': ['mood'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'searchDiaries',
        'description': '按关键词搜索日记内容',
        'parameters': {
          'type': 'object',
          'properties': {
            'keyword': {
              'type': 'string',
              'description': '要搜索的关键词，例如"旅行"、"工作"、"生日"等',
            },
          },
          'required': ['keyword'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'getMoodStats',
        'description': '统计最近N天的心情分布情况',
        'parameters': {
          'type': 'object',
          'properties': {
            'days': {
              'type': 'integer',
              'description': '要统计最近多少天的心情，例如7表示最近7天',
            },
          },
          'required': ['days'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'getDietStats',
        'description': '统计最近N天的饮食记录情况',
        'parameters': {
          'type': 'object',
          'properties': {
            'days': {
              'type': 'integer',
              'description': '要统计最近多少天的饮食，例如7表示最近7天',
            },
          },
          'required': ['days'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'getDiaryOnSameDayLastYear',
        'description': '获取去年今天的日记记录',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      },
    },
  ];

  /// 执行函数调用
  Future<String> executeFunction(String functionName, Map<String, dynamic> arguments) async {
    developer.log('🎯 [executeFunction] 执行函数: $functionName, 原始参数: $arguments', name: 'FunctionCallingService');
    
    try {
      switch (functionName) {
        case 'getCurrentMonthDiaries':
          developer.log('📅 [executeFunction] 获取本月日记', name: 'FunctionCallingService');
          final result = await _diaryQueryService.getCurrentMonthDiaries();
          developer.log('✅ [executeFunction] 本月日记获取完成, 长度: ${result.length}', name: 'FunctionCallingService');
          return result;
          
        case 'getRecentDiaries':
          final days = AiClientHelper.asInt(arguments['days']);
          developer.log('📅 [executeFunction] 获取最近 $days 天日记', name: 'FunctionCallingService');
          final result = await _diaryQueryService.getRecentDiaries(days);
          developer.log('✅ [executeFunction] 最近 $days 天日记获取完成, 长度: ${result.length}', name: 'FunctionCallingService');
          return result;
          
        case 'getDiariesByDateRange':
          String? startDateStr = arguments['startDate'] as String?;
          String? endDateStr = arguments['endDate'] as String?;
          developer.log('📅 [executeFunction] 获取日期范围日记: $startDateStr 到 $endDateStr', name: 'FunctionCallingService');
          
          // 如果参数为空，使用默认值（最近90天）
          if (startDateStr == null || endDateStr == null || startDateStr.isEmpty || endDateStr.isEmpty) {
            developer.log('⚠️ [executeFunction] 日期参数为空，使用默认值（最近90天）', name: 'FunctionCallingService');
            final now = DateTime.now();
            final ninetyDaysAgo = now.subtract(const Duration(days: 90));
            startDateStr = DateFormat('yyyy-MM-dd').format(ninetyDaysAgo);
            endDateStr = DateFormat('yyyy-MM-dd').format(now);
            developer.log('📅 [executeFunction] 使用默认日期范围: $startDateStr 到 $endDateStr', name: 'FunctionCallingService');
          }
          
          final startDate = DateTime.parse(startDateStr);
          final endDate = DateTime.parse(endDateStr);
          final result = await _diaryQueryService.getDiariesByDateRange(startDate, endDate);
          developer.log('✅ [executeFunction] 日期范围日记获取完成, 长度: ${result.length}', name: 'FunctionCallingService');
          return result;
          
        case 'getDiariesByMood':
          final mood = arguments['mood'] as String? ?? '开心';
          developer.log('😊 [executeFunction] 获取心情为 "$mood" 的日记', name: 'FunctionCallingService');
          final result = await _diaryQueryService.getDiariesByMood(mood);
          developer.log('✅ [executeFunction] 心情日记获取完成, 长度: ${result.length}', name: 'FunctionCallingService');
          return result;
          
        case 'searchDiaries':
          final keyword = arguments['keyword'] as String? ?? '';
          developer.log('🔍 [executeFunction] 搜索关键词: "$keyword"', name: 'FunctionCallingService');
          final result = await _diaryQueryService.searchDiaries(keyword);
          developer.log('✅ [executeFunction] 搜索完成, 长度: ${result.length}', name: 'FunctionCallingService');
          return result;
          
        case 'getMoodStats':
          final days = AiClientHelper.asInt(arguments['days']);
          developer.log('📊 [executeFunction] 获取最近 $days 天心情统计', name: 'FunctionCallingService');
          final result = await _diaryQueryService.getMoodStats(days);
          developer.log('✅ [executeFunction] 心情统计获取完成, 长度: ${result.length}', name: 'FunctionCallingService');
          return result;
          
        case 'getDietStats':
          final days = AiClientHelper.asInt(arguments['days']);
          developer.log('🍽️ [executeFunction] 获取最近 $days 天饮食统计', name: 'FunctionCallingService');
          final result = await _diaryQueryService.getDietStats(days);
          developer.log('✅ [executeFunction] 饮食统计获取完成, 长度: ${result.length}', name: 'FunctionCallingService');
          return result;
          
        case 'getDiaryOnSameDayLastYear':
          developer.log('📅 [executeFunction] 获取去年今天日记', name: 'FunctionCallingService');
          final result = await _diaryQueryService.getDiaryOnSameDayLastYear();
          developer.log('✅ [executeFunction] 去年今天日记获取完成, 长度: ${result.length}', name: 'FunctionCallingService');
          return result;
          
        default:
          developer.log('❌ [executeFunction] 未知的函数: $functionName', name: 'FunctionCallingService');
          throw Exception('未知的函数: $functionName');
      }
    } catch (e, stackTrace) {
      developer.log('❌ [executeFunction] 函数执行失败: $e', name: 'FunctionCallingService', error: e, stackTrace: stackTrace);
      throw Exception('函数 $functionName 执行失败: $e');
    }
  }

  /// 解析函数调用流
  static FunctionCallInfo? parseFunctionCall(
    Map<String, dynamic> jsonData,
    StringBuffer functionArgumentsBuffer,
  ) {
    final delta = jsonData['choices']?[0]?['delta'];
    final toolCalls = delta?['tool_calls'];
    
    if (toolCalls != null && toolCalls is List && toolCalls.isNotEmpty) {
      final toolCall = toolCalls[0];
      if (toolCall['function'] != null) {
        final fn = toolCall['function'];
        String? functionName;
        Map<String, dynamic>? functionArguments;
        
        // 获取函数名
        if (fn['name'] != null) {
          functionName = fn['name'];
          developer.log('📋 [parseFunctionCall] 函数名: $functionName', name: 'FunctionCallingService');
        }
        
        // 累积参数
        if (fn['arguments'] != null) {
          final argsChunk = fn['arguments'] as String;
          if (argsChunk.isNotEmpty) {
            functionArgumentsBuffer.write(argsChunk);
          }

          try {
            final parsed = AiClientHelper.tryParseToolArguments(
              functionArgumentsBuffer.toString(),
            );
            if (parsed != null) {
              functionArguments = parsed;
              developer.log('📊 [parseFunctionCall] 累积参数: $functionArguments', name: 'FunctionCallingService');
            }
          } catch (e) {
            // 参数可能不完整，继续累积
            developer.log(
              '⏳ [parseFunctionCall] 参数不完整，继续累积... 当前args: ${functionArgumentsBuffer.toString()}',
              name: 'FunctionCallingService',
            );
          }
        }
        
        if (functionName != null) {
          return FunctionCallInfo(functionName, functionArguments);
        }
      }
    }
    
    return null;
  }
}

class FunctionCallInfo {
  final String functionName;
  final Map<String, dynamic>? arguments;

  FunctionCallInfo(this.functionName, this.arguments);
}