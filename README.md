# 日记本 - Flutter Diary App

一款基于 Flutter 开发的个人日记应用，支持 AI 智能辅助、日历视图、图片记录等功能。

## 📱 应用截图

> 待添加

## ✨ 主要功能

### 1. 日记记录
- **富文本编辑**：支持多行文本输入，自动添加时间戳
- **多媒体支持**：可添加多张照片记录生活瞬间
- **饮食记录**：记录早餐、午餐、晚餐和零食
- **心情天气**：标记当天的心情和天气状况

### 2. 日历视图
- **月历展示**：直观的日历界面，快速浏览整月日记
- **日期导航**：点击日期快速定位到对应日记
- **图片预览**：日历中显示当天日记的首张图片
- **年月选择器**：快速跳转到指定年月

### 3. AI 智能助手
- **日记解析**：输入总结，AI 自动提取餐食、心情、天气等信息
- **智能聊天**：与 AI 助手对话，查询历史日记、分析心情趋势
- **流式响应**：AI 回复采用流式输出，体验更流畅
- **隐私控制**：可选择是否允许 AI 访问日记数据

### 4. 数据管理
- **收藏功能**：收藏重要日记，快速查看
- **回收站**：软删除机制，30天内可恢复
- **本地存储**：数据保存在本地，保护隐私
- **自动清理**：自动清理超过30天的已删除日记

### 5. 主题与个性化
- **深色模式**：支持浅色/深色/跟随系统三种主题模式
- **自定义字体**：使用 Google Fonts 字体
- **图标匹配**：心情和天气自动匹配对应图标

## 🛠 技术架构

### 技术栈
- **框架**：Flutter 3.8.1+
- **语言**：Dart
- **状态管理**：StatefulWidget + ChangeNotifier
- **本地存储**：SharedPreferences

### 依赖库
| 库名 | 用途 |
|------|------|
| `shared_preferences` | 本地数据持久化 |
| `table_calendar` | 日历组件 |
| `intl` | 日期国际化格式化 |
| `image_picker` | 图片选择 |
| `photo_view` | 图片查看器 |
| `http` | HTTP 请求 |
| `google_fonts` | Google 字体 |

### 项目结构
```
lib/
├── main.dart                 # 应用入口
├── models/
│   ├── diary_entry.dart      # 日记数据模型
│   └── favorite_item.dart    # 收藏项模型
├── screens/
│   ├── home_screen.dart      # 主页（日历+列表）
│   ├── write_diary_screen.dart # 写日记/编辑
│   ├── ai_chat_screen.dart   # AI 聊天界面
│   ├── favorites_screen.dart # 收藏列表
│   ├── recycle_bin_screen.dart # 回收站
│   └── settings_screen.dart  # 设置页面
├── services/
│   ├── storage_service.dart  # 数据存储服务
│   ├── theme_service.dart    # 主题管理服务
│   ├── ai_service.dart       # AI 服务
│   └── chat_storage_service.dart # 聊天记录存储
└── widgets/
    ├── diary_card.dart       # 日记卡片组件
    └── image_gallery_screen.dart # 图片画廊
```

## 📊 数据模型

### DiaryEntry（日记条目）
```dart
{
  id: String,           // 唯一标识
  date: DateTime,       // 日记日期
  title: String,        // 标题
  content: String,      // 内容
  breakfast: String?,   // 早餐
  lunch: String?,       // 午餐
  dinner: String?,      // 晚餐
  snacks: String?,      // 零食
  mood: String?,        // 心情
  weather: String?,     // 天气
  images: List<String>, // 图片路径列表
  createdAt: DateTime,  // 创建时间
  updatedAt: DateTime,  // 更新时间
  isFavorite: bool,     // 是否收藏
  deletedAt: DateTime?  // 删除时间（软删除）
}
```

## 🤖 AI 功能说明

### 支持的 AI 服务
- **OpenAI GPT**：支持 GPT-3.5-turbo 等模型
- **DeepSeek**：支持 DeepSeek Chat 模型
- **自定义 API**：支持任何兼容 OpenAI API 格式的服务

### AI 数据访问 API
AI 助手可以访问以下日记数据（需用户授权）：
- 本月日记概览
- 按日期范围查询
- 按心情筛选
- 关键词搜索
- 心情统计分析
- 饮食记录统计
- 去年今日日记

## 🚀 运行项目

### 环境要求
- Flutter SDK 3.8.1 或更高版本
- Dart SDK 3.0.0 或更高版本
- Android SDK / Xcode（根据目标平台）

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd diary_app
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
# Android
flutter run

# iOS（需要 macOS 和 Xcode）
flutter run -d ios
```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## ⚙️ 配置说明

### AI 配置
1. 进入设置页面
2. 填写 AI API 地址（如：https://api.openai.com）
3. 填写 API 密钥
4. 可选择开启 AI 数据访问权限

### 主题设置
- 支持三种主题模式：浅色、深色、跟随系统
- 切换后实时生效

## 🔒 隐私说明

- 所有日记数据存储在本地设备
- AI 功能仅在用户配置 API 后启用
- AI 数据访问需要用户明确授权
- 支持隐私模式和数据访问控制

## 📝 更新日志

### v1.0.0
- 初始版本发布
- 日记增删改查功能
- 日历视图
- AI 辅助功能
- 深色模式支持

## 📄 许可证

MIT License

## 👨‍💻 开发者

> 待添加

---

如有问题或建议，欢迎提交 Issue 或 Pull Request。
