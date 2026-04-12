import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    developer.log('🔔 [NotificationService] 初始化通知服务', name: 'NotificationService');

    // 初始化时区数据
    tz_data.initializeTimeZones();

    // Android 配置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 配置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
    developer.log('✅ [NotificationService] 通知服务初始化完成', name: 'NotificationService');
  }

  /// 请求权限（iOS 需要）
  Future<bool> requestPermission() async {
    developer.log('🔔 [NotificationService] 请求通知权限', name: 'NotificationService');
    
    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    developer.log('✅ [NotificationService] 权限请求结果: $result', name: 'NotificationService');
    return result ?? false;
  }

  /// 显示即时通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    developer.log('🔔 [NotificationService] 显示通知: $title', name: 'NotificationService');

    const androidDetails = AndroidNotificationDetails(
      'diary_channel',
      '日记提醒',
      channelDescription: '日记应用的提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );

    developer.log('✅ [NotificationService] 通知显示完成', name: 'NotificationService');
  }

  /// 显示日记提醒通知
  Future<void> showDiaryReminder() async {
    await showNotification(
      id: 1,
      title: '📝 写日记时间到了',
      body: '今天过得怎么样？来记录一下吧～',
      payload: 'open_write_diary',
    );
  }

  /// 显示去年今天提醒
  Future<void> showOnThisDayReminder(String content) async {
    await showNotification(
      id: 2,
      title: '📅 去年今天',
      body: content.length > 50 ? '${content.substring(0, 50)}...' : content,
      payload: 'open_on_this_day',
    );
  }

  /// 显示连续记录提醒
  Future<void> showStreakReminder(int days) async {
    await showNotification(
      id: 3,
      title: '🔥 连续记录 $days 天',
      body: '继续保持！今天也记得写日记哦～',
      payload: 'open_write_diary',
    );
  }

  /// 取消通知
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    developer.log('🗑️ [NotificationService] 取消通知: $id', name: 'NotificationService');
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    developer.log('🗑️ [NotificationService] 取消所有通知', name: 'NotificationService');
  }

  /// 通知点击回调
  void _onNotificationTap(NotificationResponse response) {
    developer.log('👆 [NotificationService] 通知被点击: ${response.payload}', name: 'NotificationService');
    
    // 这里可以处理通知点击后的跳转逻辑
    // 比如打开写日记页面、查看去年今天等
  }
}
