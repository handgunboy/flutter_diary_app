import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_ui.dart';

class SettingsAiSection extends StatelessWidget {
  final TextEditingController apiUrlController;
  final TextEditingController apiKeyController;
  final bool obscureApiKey;
  final VoidCallback onToggleObscureApiKey;
  final VoidCallback onSaveApiConfig;
  final bool hasAiConfig;
  final bool aiDataAccess;
  final ValueChanged<bool> onAiDataAccessChanged;

  const SettingsAiSection({
    super.key,
    required this.apiUrlController,
    required this.apiKeyController,
    required this.obscureApiKey,
    required this.onToggleObscureApiKey,
    required this.onSaveApiConfig,
    required this.hasAiConfig,
    required this.aiDataAccess,
    required this.onAiDataAccessChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Card(
      child: Padding(
        padding: AppUi.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.api,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI API 配置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (hasAiConfig)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: colors.success),
                        const SizedBox(width: 4),
                        Text(
                          '已配置',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '配置 AI 服务的 API 地址和密钥，用于心情分析等功能',
              style: TextStyle(
                fontSize: 12,
                color: AppUi.mutedText(context),
              ),
            ),
            const SizedBox(height: AppUi.itemGap),
            TextField(
              controller: apiUrlController,
              decoration: InputDecoration(
                labelText: 'API 地址',
                hintText: '例如：https://api.openai.com/v1/chat/completions',
                border: OutlineInputBorder(
                  borderRadius: AppUi.smallRadius,
                ),
              ),
            ),
            const SizedBox(height: AppUi.itemGap),
            TextField(
              controller: apiKeyController,
              obscureText: obscureApiKey,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: '输入你的 API 密钥',
                border: OutlineInputBorder(
                  borderRadius: AppUi.smallRadius,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureApiKey ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onToggleObscureApiKey,
                ),
              ),
            ),
            const SizedBox(height: AppUi.itemGap),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSaveApiConfig,
                icon: const Icon(Icons.save),
                label: const Text('保存 API 配置'),
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '允许 AI 访问日记数据',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '开启后，AI 可以读取您的日记内容，提供更个性化的建议',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppUi.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: aiDataAccess,
                  onChanged: onAiDataAccessChanged,
                ),
              ],
            ),
            if (aiDataAccess) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI 已获准访问日记数据',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
