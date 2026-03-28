import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ai_service.dart';
import '../services/chat_storage_service.dart';
import 'settings_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final AiService _aiService = AiService();
  final ChatStorageService _chatStorage = ChatStorageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isConfigured = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConfig();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final messages = await _chatStorage.loadMessages();
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    // 延迟滚动到底部
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _saveMessages() async {
    await _chatStorage.saveMessages(_messages);
  }

  void _checkConfig() {
    setState(() {
      _isConfigured = _aiService.isConfigured;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (!_isConfigured) {
      _showConfigDialog();
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    await _saveMessages();
    _scrollToBottom();

    // 创建 AI 回复消息（初始为空）
    final aiMessage = ChatMessage(
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(aiMessage);
    });

    try {
      // 获取当前月日记数据（如果用户授权）
      String diaryContext = '';
      if (_aiService.canAccessData) {
        diaryContext = await _aiService.getCurrentMonthDiaries();
      }

      // 构建系统提示词
      String systemPrompt = '''你是"小坡"，一款日记应用中的智能 AI 助手。你的主要职责是帮助用户更好地记录和管理他们的日常生活。

## 你的能力：
1. **日记分析**：帮助用户分析日记内容，提取关键信息（如饮食、心情、天气等）
2. **写作建议**：当用户不知道如何记录时，提供写作灵感和建议
3. **心情陪伴**：倾听用户的烦恼，提供情感支持和积极建议
4. **生活助手**：回答日常问题，提供生活小贴士
5. **数据整理**：帮助用户整理和回顾过去的日记内容

## 你可以访问的数据（用户已授权）：
- **本月日记**：当前月份的所有日记记录
- **最近 N 天**：获取最近几天的日记（如"最近7天"、"最近30天"）
- **日期范围**：获取指定日期范围的日记（如"3月1日到3月15日"）
- **心情筛选**：按心情筛选日记（如"开心的日子"、"难过的时候"）
- **关键词搜索**：搜索包含特定关键词的日记（如"旅行"、"工作"）
- **心情统计**：统计一段时间的心情分布（如"最近一周心情如何"）
- **饮食统计**：统计饮食记录情况（如"最近吃了什么"）
- **去年今天**：查看去年今天的日记（"去年今天我在做什么"）

## 你的性格：
- 友好、温暖、有耐心
- 善于倾听，不打断用户
- 回复简洁明了，避免冗长
- 使用 emoji 让对话更生动

## 回复格式：
- 使用中文回复
- 适当使用 emoji 增加亲和力
- 重要信息可以分段列出

## 当前可访问的数据：
${diaryContext.isNotEmpty ? diaryContext : '用户未授权访问日记数据，或本月暂无日记记录'}

现在，请以一个温暖的日记助手的身份，开始帮助用户吧！''';

      // 构建消息历史
      final List<Map<String, String>> messageHistory = [
        {
          'role': 'system',
          'content': systemPrompt
        },
        ..._messages.take(_messages.length - 1).map((msg) => {
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        }),
        {'role': 'user', 'content': message},
      ];

      // 调用真实的 AI 流式 API
      await for (final chunk in _aiService.chatStream(messageHistory)) {
        setState(() {
          aiMessage.content += chunk;
        });
        _scrollToBottom();
      }

      // 保存更新后的消息
      await _saveMessages();
    } catch (e) {
      setState(() {
        aiMessage.content = '抱歉，发生了错误：$e';
      });
      await _saveMessages();
    }

    setState(() {
      _isTyping = false;
    });
  }

  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未配置 AI API'),
        content: const Text('请先前往设置页面配置 AI API 地址和密钥。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ).then((_) => _checkConfig());
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空聊天记录'),
        content: const Text('确定要清空所有聊天记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _chatStorage.clearMessages();
      setState(() {
        _messages.clear();
      });
    }
  }

  // 检查是否需要显示时间分割线
  bool _shouldShowTimeDivider(int index) {
    if (index == 0) return true;
    final current = _messages[index].timestamp;
    final previous = _messages[index - 1].timestamp;
    // 如果两条消息间隔超过 5 分钟，显示时间
    return current.difference(previous).inMinutes > 5;
  }

  // 格式化时间显示
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '今天 ${DateFormat('HH:mm').format(time)}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return '昨天 ${DateFormat('HH:mm').format(time)}';
    } else {
      return DateFormat('MM月dd日 HH:mm').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('小坡'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
        foregroundColor: isDark ? theme.colorScheme.onSurface : theme.colorScheme.onSurface,
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearChat,
              tooltip: '清空聊天记录',
            ),
          if (!_isConfigured)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) => _checkConfig());
              },
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('配置'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageItem(index);
                          },
                        ),
                ),
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildMessageItem(int index) {
    final message = _messages[index];
    final showTime = _shouldShowTimeDivider(index);

    return Column(
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        _buildMessageBubble(message),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/txbb.png',
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 16),
          Text(
            '小坡',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            !_isConfigured
                ? '请先配置 AI API 才能使用\n前往设置页面配置 API 地址和密钥'
                : '和我聊聊吧，我可以帮你：\n• 分析日记内容\n• 提供心情建议\n• 回答各种问题',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (!_isConfigured) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) => _checkConfig());
              },
              icon: const Icon(Icons.settings),
              label: const Text('前往设置'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              ClipOval(
                child: Image.asset(
                  'assets/images/txbb.png',
                  width: 32,
                  height: 32,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: _isConfigured ? '输入消息...' : '请先配置 AI API',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: _isConfigured,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _isConfigured
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: (_isTyping || !_isConfigured) ? null : _sendMessage,
                icon: _isTyping
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}
