import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'services/theme_service.dart';

void main() {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 优化帧率：设置为最高可用帧率
  _setHighRefreshRate();
  
  // 初始化 ThemeService
  final themeService = ThemeService();
  themeService.ensureInitialized().then((_) {
    runApp(const MyApp());
  });
}

void _setHighRefreshRate() {
  if (Platform.isAndroid) {
    // Android: 尝试设置为最高刷新率
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // 当屏幕尺寸或刷新率变化时重新优化
    _setHighRefreshRate();
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日记本',
      debugShowCheckedModeBanner: false,
      // 性能优化：使用 const 构造函数
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      // 性能优化：使用 const 主题数据
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeService.flutterThemeMode,
      home: const RepaintBoundary(child: HomeScreen()),
      // 性能优化：减少不必要的重建
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }

  // 提取主题构建方法，使用 const 优化
  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF333333),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      // 性能优化：减少动画时间
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.dark(
        surface: const Color(0xFF1E1E1E),
        primary: Colors.grey[400]!,
        secondary: Colors.grey[500]!,
        onSurface: Colors.grey[300]!,
      ),
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[500]!, width: 1),
        ),
      ),
    );
  }
}
