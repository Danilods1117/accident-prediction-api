import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  Future<void> showAccidentAlert({
    required String barangay,
    required String message,
    required String riskLevel,
  }) async {
    // Determine notification priority and sound based on risk level
    Priority priority;
    Importance importance;
    String channelId;
    String channelName;

    if (riskLevel == 'CRITICAL') {
      priority = Priority.max;
      importance = Importance.max;
      channelId = 'critical_alerts';
      channelName = 'Critical Accident Alerts';
    } else if (riskLevel == 'HIGH') {
      priority = Priority.high;
      importance = Importance.high;
      channelId = 'high_alerts';
      channelName = 'High Risk Alerts';
    } else {
      priority = Priority.defaultPriority;
      importance = Importance.defaultImportance;
      channelId = 'general_alerts';
      channelName = 'General Alerts';
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Alerts for accident-prone areas',
      importance: importance,
      priority: priority,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: _getRiskColor(riskLevel),
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: '⚠️ ACCIDENT-PRONE AREA ALERT',
        summaryText: barangay.toUpperCase(),
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '⚠️ ACCIDENT-PRONE AREA',
      message,
      notificationDetails,
      payload: 'accident_alert:$barangay',
    );
  }

  Future<void> showSafetyTip(String tip) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'safety_tips',
      'Safety Tips',
      channelDescription: 'Driving safety tips',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '💡 Safety Tip',
      tip,
      notificationDetails,
    );
  }

  Future<void> showRouteAlert(String routeName, String message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'route_alerts',
      'Route Suggestions',
      channelDescription: 'Alternative route suggestions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '🗺️ Alternative Route Available',
      message,
      notificationDetails,
      payload: 'route:$routeName',
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'CRITICAL':
        return const Color(0xFFD32F2F);
      case 'HIGH':
        return const Color(0xFFFF5722);
      case 'MEDIUM':
        return const Color(0xFFFF9800);
      case 'LOW':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF757575);
    }
  }
}