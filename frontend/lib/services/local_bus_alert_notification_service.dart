import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalBusAlertNotificationService {
  LocalBusAlertNotificationService._();

  static final LocalBusAlertNotificationService instance =
      LocalBusAlertNotificationService._();

  static const String _channelId = 'bus_alerts';
  static const String _channelName = 'Bus Alerts';
  static const String _channelDescription =
      'Notifications for nearby and arriving buses';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Map<String, DateTime> _lastAlertTimeByBusId = <String, DateTime>{};

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(settings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> maybeNotifyBusApproaching({
    required String busId,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    if (kIsWeb || !_initialized) {
      return;
    }

    if (distanceKm > 1 || etaMinutes >= 5) {
      return;
    }

    // Prevent notification spam when location updates arrive frequently.
    final now = DateTime.now();
    final lastAlert = _lastAlertTimeByBusId[busId];
    if (lastAlert != null && now.difference(lastAlert).inMinutes < 2) {
      return;
    }

    await _plugin.show(
      busId.hashCode & 0x7fffffff,
      'Bus Approaching',
      'Your bus is 1 km away. ETA: $etaMinutes minutes',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    _lastAlertTimeByBusId[busId] = now;
  }
}
