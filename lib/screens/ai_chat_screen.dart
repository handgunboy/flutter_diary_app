import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/langchain_service.dart';
import '../services/chat_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui.dart';
import 'settings_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final LangChainService _langChainService = LangChainService();
  final ChatStorageService _chatStorage = ChatStorageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isConfigured = false;
  bool _isLoading = true;

  // 会话 ID（用于 LangChain 记忆）
  final String _sessionId = 'default_session';

  // 用于流式输出的缓冲和节流控制
  final StringBuffer _streamBuffer = StringBuffer();
  Timer? _streamThrottleTimer;
  static const Duration _streamThrottleInterval = Duration(milliseconds: 140); // 降低 UI 刷新频率减少卡顿

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
    // 列表已反转，最新消息在底部，无需滚动
  }

  Future<void> _saveMessages() async {
    await _chatStorage.saveMessages(_messages);
  }

  void _checkConfig() {
    setState(() {
      _isConfigured = _langChainService.isConfigured;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _streamThrottleTimer?.cancel();
    super.dispose();
  }

  /// 刷新流式输出到 UI（带节流）
  void _flushStreamBuffer(ChatMessage aiMessage) {
    _streamThrottleTimer?.cancel();
    if (_streamBuffer.isNotEmpty) {
      setState(() {
        aiMessage.content += _streamBuffer.toString();
        _streamBuffer.clear();
      });
      // 只在刷新 UI 时滚动，且使用 jumpTo 避免动画卡顿
      _scrollToBottomImmediate();
    }
  }

  /// 安排刷新（节流控制）
  void _scheduleFlush(ChatMessage aiMessage) {
    _streamThrottleTimer?.cancel();
    _streamThrottleTimer = Timer(_streamThrottleInterval, () {
      _flushStreamBuffer(aiMessage);
    });
  }

  /// 立即滚动到底部（无动画，避免卡顿）
  void _scrollToBottomImmediate() {
    if (_scrollController.hasClients) {
      // 只有在接近底部时才自动吸附，避免高频滚动抖动
      final nearBottom = _scrollController.position.pixels <= 120;
      if (nearBottom) {
        _scrollController.jumpTo(0);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // 列表已反转，最新消息在底部（position 0）
      _scrollController.animateTo(
        0,
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
      // 使用 LangChain RAG 模式（带记忆和向量检索）
      await for (final chunk in _langChainService.chatWithRAG(
        sessionId: _sessionId,
        message: message,
      )) {
        _streamBuffer.write(chunk);
        _scheduleFlush(aiMessage);
      }
      // 确保最后的内容被刷新
      _flushStreamBuffer(aiMessage);

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

  Future<void> _clearChat() async {
    final colors = AppColors.of(context);
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
            style: TextButton.styleFrom(foregroundColor: colors.danger),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _chatStorage.clearMessages();
      _langChainService.clearMemory(_sessionId);
      setState(() {
        _messages.clear();
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearChat,
              tooltip: '清空聊天记录',
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          reverse: true,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final reversedIndex = _messages.length - 1 - index;
                            return _buildMessageItem(reversedIndex);
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
    final theme = Theme.of(context);

    return Column(
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppUi.subtleSurface(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);

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
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (!_isConfigured)
            Text(
              '请先配置 AI API 才能使用',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final assistantBubbleColor = colors.surfaceSubtle;
    final assistantTextColor = theme.colorScheme.onSurface;

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
                      ? theme.colorScheme.primary
                      : assistantBubbleColor,
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
                    color: isUser ? theme.colorScheme.onPrimary : assistantTextColor,
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
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final areaBg = colors.background;
    final sendBg = _isConfigured
        ? theme.colorScheme.primary
        : colors.outlineStrong;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: areaBg,
        border: Border(
          top: BorderSide(
            color: colors.outline,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowSoft,
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
                  fillColor: AppUi.subtleSurface(context),
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
                color: sendBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: (_isTyping || !_isConfigured) ? null : _sendMessage,
                icon: _isTyping
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Icon(Icons.send, color: theme.colorScheme.onPrimary),
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
